package IO::Tokenized;

use strict;
use warnings;

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS/;
use constant BUFFER_SIZE => 30 * 1024;
use constant TOKEN_SEPARATOR => qr/\s/;

use Carp;
use Symbol;
use Exporter;

$VERSION = '0.04';

@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(initialize_parsing buffer_space token_separator flushbuffer
                skip resynch getline getlines gettoken gettokens setparser);

%EXPORT_TAGS = (all => [@EXPORT_OK],
		parse => [qw(initialize_parsing gettoken gettokens)],
		buffer => [qw(bufferspace flushbuffer resynch)]
	       );

sub new {
  my $class = shift;
  my ($self,@tokens) = @_;
  $self = gensym unless defined $self;
  bless $self,$class;
  initialize_parsing($self,@tokens);
}

sub initialize_parsing {
  my $self = shift;
  my @tokens = @_;
  @{${*$self}{__PACKAGE__}{definition}} = ();
  flushbuffer($self) && 
    carp __PACKAGE__ ."(re)initializing parser with not empty buffer";
  token_separator($self,TOKEN_SEPARATOR);
  buffer_space($self,BUFFER_SIZE);
  setparser($self,@tokens) if @tokens;
  return $self;
}

sub buffer_space {
  my $self = shift;

  ${*$self}{__PACKAGE__}{bufsize} = BUFFER_SIZE 
    unless defined${*$self}{__PACKAGE__}{bufsize};

  my $oldvalue = ${*$self}{__PACKAGE__}{bufsize};
  ${*$self}{__PACKAGE__}{bufsize} = shift if @_;
  return $oldvalue;
}

sub token_separator {
  my $self = shift;
  my $oldvalue = ${*$self}{__PACKAGE__}{token_separator};
  ${*$self}{__PACKAGE__}{token_separator} = shift if @_;
  return $oldvalue;
}

sub flushbuffer {
  my $self = shift;
  my $oldvalue = ${*$self}{__PACKAGE__}{buffer};
  ${*$self}{__PACKAGE__}{buffer} = "";
  return $oldvalue;
}

# tries to read from self until repetedly removing skip prefix until 
# one of the following is verified:
# 1. the buffer is not empty and doesn't start with a skip prefix
# 2. the end of file is reached without 1. beeing fulfilled.
#
# The function returns true in the first case, false in the second

sub skip {
  my $self = shift;
  my $re = token_separator($self);
  my $buffer = \${*$self}{__PACKAGE__}{buffer};
  while (1) {
    $$buffer = scalar <$self> unless length($$buffer);
    return unless defined $$buffer; #end of file
    $$buffer =~ s/^$re+//;
    return 1 if length($$buffer);
  }
}

# flushes buffer till the first token, if possible
sub resynch {
  my $self = shift;
  my $resyncher = ${*$self}{__PACKAGE__}{resyncher};
  &$resyncher($self);
}

sub getline {
  my $self = shift;
  my $buffer = \${*$self}{__PACKAGE__}{buffer};
  if ($$buffer =~ s!^(.*?$/)!!) {
    return $1;
  }
  else {
    $$buffer .= scalar <$self>;
    flusbuffer($self);
  }
}

sub getlines {
  my $self = shift;
  my @lines = (getline($self));
  push @lines,<$self> unless eof $self;
  return @lines;
}
  

sub gettoken {
  my $self = shift;
  my $parser = ${*$self}{__PACKAGE__}{parser};
  
  skip($self) || return;
  my ($token,$value) = &$parser($self);
  if ($token eq '<eof>') {
    return;
  }
  elsif ($token eq '<overflow>') {
    croak "Overflowed buffer with no token found";    
  }
  else {
    return ($token => $value);
  }
}

sub gettokens {
  my $self = shift;
  my @result;
  while (my $t = gettoken($self)) {
    push @result,$t;
  }
  return @result;
}

sub setparser {
  my $self = shift;
  my @oldvalue = @{${*$self}{__PACKAGE__}{definition}};
  @{${*$self}{__PACKAGE__}{definition}} = @_;
  my %regexp = ();
  my %functions = ();
  my @order = ();

  foreach my $definition (@{${*$self}{__PACKAGE__}{definition}}) {
    my ($tok,$re,$func) = @$definition;
    if ($tok eq "") {
      token_separator($self,$re);
      next;
    }
    if (exists $regexp{$tok}) {
      carp "token '$tok' redefined!";
      next;
    }
    push @order,$tok;
    $regexp{$tok} = $re;
    $functions{$tok} = $func if defined $func;
  }
  ${*$self}{__PACKAGE__}{parser} = eval {
    my @checkers = ();
    foreach my $tok (@order) {
      my $sub = eval {
	my $func = exists $functions{$tok} ? $functions{$tok} : sub {shift @_};
	my $re = qr/^($regexp{$tok})(.*)/s;
	my $token = $tok;

	sub {
	  my $self = shift;
	  my $buffer = \${*$self}{__PACKAGE__}{buffer};
	  my @items = ($$buffer =~ $re);
	  return (undef,undef) unless @items;
	  my $tmp = pop @items;
	  my $value = &$func(@items);
	  return unless defined $value;
	  $$buffer = $tmp;
	  return ($token => $value);
	}
      };
      croak $@ if $@;
      push @checkers,$sub;
    }
    # now define the parser
    sub {
      my $self = shift;
      my $buffer = \${*$self}{__PACKAGE__}{buffer};
      while (1) {
	foreach my $checker (@checkers) {
	  my ($token,$value) = &$checker($self);
	  return ($token,$value) if defined $token;
	}
	# no token matched... we try to extend the buffer by reading
	# another line but first we check that there is no overflow
	return ('<overflow>' => undef) unless 
	  length($$buffer) < buffer_space($self);
	my $line = scalar <$self>;
	return ('<unparsable>' => undef) unless defined $line;
	$$buffer .= $line;
      }
    };
  };
  croak $@ if $@;
  my $resynch = "(?=" . join("|",
			     map("(?:$regexp{$_})",@order)) . ")";
  ${*$self}{__PACKAGE__}{resyncher} = eval {
    my $resynch_re = qr/$resynch/os;
    #the resyncher
    sub {
      my $self = shift;
      my $buffer = \${*$self}{__PACKAGE__}{buffer};
      while (1) {
	return 1 if $$buffer =~ s/^.*?(?=$resynch_re)//;
	$$buffer = scalar <$self>;
	return unless defined $$buffer;
      }
    }
  };
  croak $@ if $@;
  return @oldvalue;
}

1;
__END__


=head1 NAME

IO::Tokenized - Extension of Perl for tokenized input

=head1 SYNOPSIS

  #Functional interface

  use IO::Tokenized qw/:parse/;
  
  open FOO,"<","some/input/file" or die "Can't open 'some/input/file': $!";
  setparser(\*FOO,[num => qr/\d+/],
                  [ident => qr/[a-z_][a-z0-9_]],
                  [op => qr![+*/-]!,\&opname]);
  
  while (my ($tok,$val) = gettoken(\*FOO)) {
    ... do something smart...
  }

  close(FOO);



=head1 ABSTRACT

Defines an extension to perl filehandles allowing spliting the input
stream according to regular expressions.


=head1 DESCRIPTION

I<IO::Tokenized> defines a bunch of functions allowing tokenized input from 
perl filehandles. In this alpha version tokens are specified by passing to the 
C<initialize_parsing> function a list of I<token specifications>. Each token 
specification is (a reference to) an array containing: the token name 
(a string), a regular expression defining the token and, optionally, an action
function which calculates the value to be returned when a token matching the
regexp is found. 

Once the tokens are been specified, each invocation the C<gettoken> function 
return a pair consisting of a token name and a token value or C<undef> at 
end of file.

I<IO::Tokenized> can also be used as a base class to add tokenized input
methods to the object modules in the I<IO::*> namespace. As an example, see
the I<IO::Tokenized::File> module, which is included in  this distrution.


=head1 RATIONALE

Lexical analysis, which is a fundamental step in all parsing, mainly consists in 
decomposing an input stream into smal chunks called tokens. The tokens are in
turn defined by regular expressions.

As Perl is good at handling regular expressions, one should expects that writing
lexical analyser in Perl should be easy. In truth it is not, and tools like lex or
flex are even been ported to Perl. There are also a whole lot of ad-hoc lexers for
different parsing modules/programmes. 

Now, approaches to lexical analysis like those underlying Parse::Lex and Parse::Flex
are general but fairly complexes to use, while ad-hoc solutions are obviously, 
well... ad-hoc.

What I'd always sought was a way to tell to a file handle: "well, that is how
the chunks I'm interested are. Please, found them in your input stream".  It 
seems a simple thingh enough, but I could not found a module doing it.

Obviously, impatience pushed me to implement such a module, but until little
time ago I had no real need for it, so lazines spoke against it. Recently I 
started to write a compiler for a scripting language and I started using the
Parse::RecDescent module. There, in the documentation Damian Conway says

=over

=item  *
There's no support for parsing directly from an input stream.  If
and when the Perl Gods give us regular expressions on streams, this
should be trivial (ahem!) to implement.



=back

Why, regular expression on streams was exactly what I had in mind, so hubris 
kicked in and I wrote this module and its compagnon I<IO::Tokenized::File>.


=head1 FUNCTIONS

The following functions are defined by the I<IO::tokenized> module.

=over

=item * C<initialize_parser($handle[,@tokens])>

Initialize the filehandle C<$handle> for tokenized input.The C<@token> optional 
parameter, if present, is passed to C<settparser>.

=item * C<setparser($handle,@tokens)>

Defines or redefines the tokens used by C<gettoken>. If C<@tokens> contains a token
whose name is the empty string, then the regexp defining it is passed to 
C<token_separator>

=item * C<gettoken($handle)>

Returns the next token in the input stream identified by
C<$handle>. Each token is returned as a pair C<(token_name => $value)>
where C<$value> is either the initial portion of the input stream
amtching the token regular expression (if no action was defined for
token C<token_name>) or the result of the action function evaluation
if such a function was defined for token C<token_name>.

On end of file, C<gettoken($handle)> returns C<undef>. If the
end of file is hitten, or the internal buffer overflows, without a
token beeing found, the functions croaks.

=item * C<gettokens($handle>>

It returns the list of tokens contained in the input stream C<$handle> until 
the end of file.

=item * C<buffer_space($handle [,Number])>

Retrives or sets the size of the internal buffer used by
I<IO::Tokenized>.  By default the buffer size is of 30720 characters
(30 Kb). If used for setting, by providing a new value, it returns the
old value.

=item * C<token_separator($handle[,regex]>

Retrives or set the regular expression used as a fill-up between tokens. 
The default value is C</\s/>.


=item * C<flushbuffer($handle)>

Flushes the internal buffer, returning the characters contained in it.


=item * C<skip($handle)>

Repetedly removes from the start of the file pattern matching the token separator
setted by C<token_:separator> until either the end of file is reached or
the start of the file does not match the regex.

=item * C<resynch($handle)>

Try to remove as little characters as possible from the beginning of the file
as it is necessary to get a substring matching a token in the front of the 
input stream.

=item C<getline($handle)> and C<getlines($handle)>

These functions work as the function of the same name in I<IO::Handle>, they are
redefined to take into account the presence of an internal buffer.


=back

=head1 EXPORTS

I<IO::Tokenized> does not export any function by default but all the above 
mentioned functions are exportable. There are, beside the classical I<:all>,
two more export tags: I<:parse>, which exports C<initialize_parsing>,
C<gettoken> and C<gettokens>, and I<:buffer>, which exports C<bufferspace>,
C<flushbuffer> and C<resynch>.


=head1 OBJECT ORIENTED

All the functions described above can be called in an object oriented way.
For contructing I<IO::Tokenized> objects a C<new> method is provided which 
is basicaly a wrapper around C<initialize_parsing>.

=head1 SEE ALSO

L<IO::Tokenized::File>.


=head1 TOKENS SPECIFICATION

Tokens are specified, either to the C<new> creator or to the C<settparser>
mutator, by a list of I<token definitions>. Each token definition is 
(a reference to) an array with two or three elements. The first element 
represents the token name, the second one is the regexp defining the token
itself while the third, if present, is the I<action> function.


=head1 ACTION FUNCTIONS

As stated above, the user can associate a function to each token, called the
I<action> of the token. The I<action> serves to purposes: it calculates the
value of the token and completes the verification of the match. The action
function specified in C<[token => $re,\&foo()]> will be called with the result
of C<@item = $buffer =~ /($re)/s>. The default action is simpli to C<pop> 
C<@_>, so giving the text that matched C<$re>.

=head1 MATCHING STRATEGY

The C<gettoken> function uses the following method to find the token to be 
returned.

=over

=item 1.
it removes from the beginning of the internal buffer strings matching the 
skip regular expression as set by the C<token_separator> function. In doing so,
it can read more lines from the file into the buffer.

=item 2.
consider the token definitions I<in the order they where passed to> 
C<settparser>. If token C<token> is defined by regexp C<$re>, check that
the buffer matches C</^($re)/>. If it is not so, then pass to the following
token if any, to step 4. below if none.

=item 3.
if there is a user defined action for the token, apply it. If it returns 
C<undef> then  pass to the following token if any, to step 4. below if none.
If the return value is defined, return a pair formed by the token name and the 
value itself. If there is no user defined action, then return a pair consisting
of the token name and the matched string. Before returning, the buffer is 
updated removing the matched string.

=item 4.
if no match could be found, try reading one more line into the buffer and go
back to step 2. If in entering step 4 the internal buffer holds more 
characters that was fixed by C<buffer_space> then C<gettoken> croacks.

=back



=head1 CAVEATS

=over

=item *
The selected token is the first matching token, not the longest one. I'm 
wondering what would be best: 1) let this alone, 2) change it to 'the longest match',
3) add an option, 4) write another module, 5) some other thing.

=item *
No token can span more than one line unless it has a well defined end marker. 
This does not appear to be a real problem. The only tokens spanning more than one
line I ever seen are multiline strings and block comments, both of which have
end markers: closed quote and I<end of comment> respectively.




=back

=head1 BUGS

Please remember that this is an alpha version of the module, and will stay so
until the version number gets to 1.00. This means that there surely are plenty
of bugs which aren't be discovered yet, more so because testing is all but
complete.

Bugs reports are welcome and are to be addressed directly to the author at
the address below.


=head1 TODO

There is still lot of work to do on this module, both at the programming level
and at the conceptual level. Feature requests as well as insights are welcome.

=head1 AUTHOR

Leo "TheHobbit" Cacciari, E<lt>hobbit@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Leo Cacciari

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
