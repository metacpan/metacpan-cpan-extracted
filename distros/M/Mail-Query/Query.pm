package Mail::Query;

require 5.005_62;
use strict;
use warnings;
use base 'Mail::Audit';
use Parse::RecDescent;
our $VERSION = '0.01';

sub new {
  my $package = shift;
  
  my $self = $package->SUPER::new(@_);
  $self->{parser} = new Parse::RecDescent($self->grammar);
  return $self;
}

sub query {
  my ($self, $query) = @_;
  local $self->{parser}{local}{mq} = $self;  # Circular ref, but local.  No sweat.
  return $self->{parser}->where_clause($query);
}

sub compare {
  my ($self, $field, $op, $string) = @_;
  
  # We handle =, <, and >
  return !$self->compare($field, '=', $string) if $op eq '!=';
  return !$self->compare($field, '<', $string) if $op eq '>=';
  return !$self->compare($field, '>', $string) if $op eq '<=';


  # This should be date-aware, at the least.  So far we punt.
  my $val = $self->get($field);
  #warn "comparing: '$val' $op '$string'";
  return $val eq $string if $op eq '=';
  return $val lt $string if $op eq '<';
  return $val gt $string if $op eq '>';
  
  die "Unknown operator '$op'";
}

sub between {
  my ($self, $field, $one, $two) = @_;
  
  # This should be date-aware, at the least.  So far we punt.
  ($one, $two) = ($two, $one) if $one gt $two;
  return 0 unless $one lt $field;
  return 0 unless $field lt $two;
  return 1;
}

sub like {
  my ($self, $field, $pattern) = @_;
  
  if ($pattern->[1] eq 'regex') {
    (my $pat = $pattern->[0]) =~ s/([\@\$])/\\$1/g;  # A limited quotemeta (is this a good idea?)
    #warn "$field =~ $pat";
    my $result = eval "\$self->get(\$field) =~ $pat";  # eval to maintain 5.004 compat
    warn "Error in pattern $pat" unless defined $result;
    return $result;
  }
  
  # $pattern->[1] eq 'string'
  # A string like 'boo%hoo' maps to /^boo.*hoo$/
  my $string = quotemeta($pattern->[0]);
  $string =~ s/%/.*/;
  return $self->get($field) =~ /^$string$/;
}

sub exists {
  my ($self, $field) = @_;
  #my $val = $self->get($field); warn "checking for defined($field): ", defined($val);

  return defined $self->get($field);
}

# We implement a 'Recipient' field, which is any of To, Cc, or Bcc
# We also make 'body' a header-like field, for queries like "body LIKE /blah/"
sub get {
  my ($self, $field) = @_;
  return join '', @{$self->body}                              if lc($field) eq 'body';
  return join ', ', map {$self->SUPER::get($_)} qw(To Cc Bcc) if lc($field) eq 'recipient';
  return $self->SUPER::get($field);
}

sub grammar {
  return <<'EOF';
    # Excised from http://www.contrib.andrew.cmu.edu/~shadow/sql/sql2bnf.aug92.txt
    
    where_clause: search_condition /^\z/                     {$return = $item{search_condition}}
                | <error>
    
    search_condition: <leftop: bool_term /OR/i bool_term>
                      {$return = grep {$_} @{$item[1]}}
    
    bool_term: <leftop: bool_factor /AND/i bool_factor>
               {$return = !grep {!$_} @{$item[1]}}
    
    bool_factor: not(?) bool_primary                {$return = @{$item[1]} ? !$item[2] : $item[2]}
    # Don't support IS TRUE and IS NOT UNKNOWN and all that crap
    
    bool_primary: '(' <commit> search_condition ')' {$return = $item[3]}
                | predicate
    
    predicate: comparison_predicate
             | between_predicate
             | like_predicate
             | null_predicate
              # There's more here, but I'm skipping for now.
    
    # These only accept header field names as the LHS, and don't allow functions yet.
    comparison_predicate: header comp_op string        {$return = $thisparser->{local}{mq}->compare(@item[1,2,3])}
    
    between_predicate: header not(?) between string /AND/i string
                                                         {my $x = $thisparser->{local}{mq}->between(@item[1,4,6]);
							  $return = @{$item[2]} ? !$x : $x}
    
    like_predicate: header not(?) like rhs               {my $x = $thisparser->{local}{mq}->like(@item[1,4]);
							  $return = @{$item[2]} ? !$x : $x}
    
    null_predicate: header is not(?) null                {my $x = $thisparser->{local}{mq}->exists($item[1]);
						          $return = @{$item[3]} ? $x : !$x}
    
    rhs: string {$return = [$item[1], 'string']}
       | regex  {$return = [$item[1], 'regex' ]}
    
    # With a true $arg[0], returns a two-element listref.  
    string: {my @x = extract_quotelike($text);
             if ($x[0] and ($x[3] =~ m/^q+$/ or $x[4] =~ m/^['"]$/) ) { # Strings only, not regexes & so on
               substr($text,0,pos($text)) = '';
               $return = $x[5];
             } else {
               $return = undef;
             }
            }
    
    regex:  {local $_ = extract_quotelike($text);
	     $return = (m/^m/ or m/^\//) ? $_ : undef}
    
    comp_op: '=' | '!=' | '<=' | '>=' | '<' | '>'
    
    header: /[\w-]+/  # dashes are allowed, very common in headers.
    
    not:  /NOT/i
    is:   /IS/i
    like: /LIKE/i
    null: /NULL/i
    between: /BETWEEN/i

EOF
}

1;
__END__


=head1 NAME

Mail::Query - Write Mail::Audit criteria in SQL-like syntax

=head1 SYNOPSIS

  use Mail::Query;
  my $mail = new Mail::Query;
  if ($mail->query('To LIKE /modperl/i')) {
    $mail->accept('lists/modperl');
  } elsif ($mail->query('Recipient LIKE /ken@mathforum/i')) {
    $mail->accept('forum-mail');
  } elsif ($mail->query("Precedence LIKE 'bulk%'")) {
    $mail->accept('lists/unknown');
  }
  
  # Or put rules in a data structure:
  my @rules = (
               'lists/modperl' => 'To LIKE /modperl/i',
               'forum-mail'    => 'Recipient LIKE /ken@mathforum/i',
               'lists/unknown' => "Precedence LIKE 'bulk%'",
              );
  while (my ($mbox, $criteria) = splice @rules, 0, 2) {
    $mail->accept($mbox) if $mail->query($criteria);
  }


=head1 DESCRIPTION

The Mail::Query module adds a criteria-specifying language to the
Mail::Audit class.  Rather than inventing a new (probably
ill-considered) language and making you learn it, Mail::Query uses SQL
(Structured Query Language) as its starting point, because SQL is
perfectly suited for writing arbitrarily complex boolean criteria in a
fairly readable format.

Mail::Query is a subclass of Mail::Audit, so any of Mail::Audit's
methods are available on a Mail::Query object too.

The full syntax of C<WHERE> clauses is available when writing
criteria, so you may join criteria with C<AND> or C<OR>, using
parentheses when necessary to specify precedence.  You may negate
criteria with C<NOT>.  See L<SPECIFICS> for details on what various
bits of SQL will mean about the email message you're examining.

Currently, the left side of a comparison must be the name of a header
field.  This name can contain letters, numbers, the underscore
character, and the hyphen character.  The header name is analogous to
a database column name.  Two special pseudo-headers are defined - a
C<Recipient> pesudo-header contains the contents of the C<To>, C<Cc>,
and C<Bcc> headers, joined by commas, and a C<Body> pseudo-header
contains the body of the message.  All other header names are passed
through to C<Mail::Audit>'s C<get()> method.

=head1 SPECIFICS

Here is what various SQL operators/identifiers mean.

=over 4

=item * <header> LIKE /regex/

Checks to see whether the given header matches the given regular
expression.  You may also use trailing regex modifiers like C</i>.

Currently any C<@> or C<$> characters in the regular expression are
escaped, which means you may write C<To LIKE /ken@mathforum/> instead
of C<To LIKE /ken\@mathforum/>.  If this doesn't suit your needs, let
me know.

=item * <header> LIKE 'spec'

This is similar to the regular-expression form of C<LIKE>, but
C<'spec'> is a normal SQL C<LIKE> string, not a full-blown regular
expression.  The C<%> character is a wildcard matching zero or more
unspecified characters, and all other characters just match
themselves.

=item * <header> = 'string'

=item * <header> < 'string'

=item * <header> > 'string'

=item * <header> != 'string'

=item * <header> <= 'string'

=item * <header> >= 'string'

Does a string-based comparison (using C<eq>, C<lt>, and so on) of the
given header with the given string.  Note that currently
C<Mail::Audit> doesn't trim whitespace off the end of a header value,
so the value will usually contain a newline at the end.  Keep this in
mind when using the C<=> operator (and consider using a C<LIKE> clause
instead).

You may use any of Perl's string-quoting constructs for the
C<'string'>, including C<"string">, C<'string'>, C<qq{string}>, or
C<q{string}>.

=item * <header> BETWEEN "string1" AND "string2"

This does what you would expect, if you expect something sane.

=item * <header> IS NULL / <header> IS NOT NULL

Indicates the absence/presence of a certain header.

=item 

=back

=head1 MOTIVATION

I was using Mail::Audit to filter my incoming mail, and I found that
as I added more filtering rules, my filtering script got uglier and
uglier.  Lots of Perl C<if> statements proliferated, and I found that
the bulk of my code looked quite overwrought - I was supposedly using
"the power of Perl" to write my criteria, but it was all C<if>s,
C<and>s, and C<or>s.  I tend not to like Perl code that uses lots of
C<if>s, C<and>s, and C<or>s.

Therefore, I decided to take all the filtering rules out of the code,
and put them into a data structure that my main code could simply
iterate over.  However, the criteria didn't fit very easily into a
data structure - I didn't relish the thought of translating
arbitrarily complicated boolean criteria into some sort of nested data
structure, nor did I look forward to looking at the structure later
and trying to figure out what they meant.

So I decided that we already had this perfectly adequate SQL language
for specifying boolean criteria, which would let me flatten my
criteria specifications into nice easily readable strings.

=head1 CAVEATS

I get a lot of mail (yes, we all do), but not so much that my mail
filtering program needs to be particularly fast.  Accordingly, I care
much more about ease-of-use than execution speed.  C<Mail::Query>
isn't very fast - it uses a full C<Parse::RecDescent> grammar to parse
the criteria statements and figure out whether the message matches.
Even C<Mail::Audit> isn't particularly fast when compared with
something like procmail (though I haven't benchmarked it, since I
don't really care very much), and C<Mail::Query> is about one order
slower yet.  So don't expect it to handle several pieces of mail per
second or anything.

=head1 TO DO

It would be nice to add some functions for use in criteria, like

 format_date(Date) < '2000-02-02'

Once this is done, it would be trivial to let users define their own
functions too.

C<Parse::RecDescent> has a way to pre-compile a grammar so that it
doesn't have to be compiled every time the program is run.  I'll
probably do that in a future release so that the user doesn't have to
install C<Parse::RecDescent> either.  It's fairly easy to do, but for
(my) simplicity's sake I haven't done it yet.

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 SEE ALSO

perl(1), Mail::Audit(3)

=cut
