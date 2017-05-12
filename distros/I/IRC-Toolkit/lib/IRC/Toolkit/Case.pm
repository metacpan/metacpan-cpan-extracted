package IRC::Toolkit::Case;
$IRC::Toolkit::Case::VERSION = '0.092002';
use strictures 2;
no warnings 'once';
use Carp 'carp';

use parent 'Exporter::Tiny';
our @EXPORT = qw/
  lc_irc
  uc_irc
  eq_irc

  rfc1459

  irc_str
/;


use Sub::Infix;
*rfc1459 = &infix(sub { eq_irc( $_[0], $_[1], 'rfc1459' ) });


## The prototypes are unfortunate, but I pulled these out of an old
## and very large bot project ... and was too scared to remove them.

sub lc_irc ($;$) {
  my ($string, $casemap) = @_;
  $casemap = lc( $casemap || 'rfc1459' );

  CASE: {
    if ($casemap eq 'rfc1459') {
      $string =~ tr/A-Z[]\\~/a-z{}|^/;
      last CASE
    }

    if ($casemap eq 'strict-rfc1459' || $casemap eq 'strict') {
      $string =~ tr/A-Z[]\\/a-z{}|/;
      last CASE
    }

    if ($casemap eq 'ascii') {
      $string =~ tr/A-Z/a-z/;
      last CASE
    }

    carp "Unknown CASEMAP $casemap, defaulted to rfc1459";
    $casemap = 'rfc1459';
    redo CASE
  }

  $string
}

sub uc_irc ($;$) {
  my ($string, $casemap) = @_;
  $casemap = lc( $casemap || 'rfc1459' );

  CASE: {
    if ($casemap eq 'rfc1459') {
      $string =~ tr/a-z{}|^/A-Z[]\\~/;
      last CASE
    }

    if ($casemap eq 'strict-rfc1459' || $casemap eq 'strict') {
      $string =~ tr/a-z{}|/A-Z[]\\/;
      last CASE
    }

    if ($casemap eq 'ascii') {
      $string =~ tr/a-z/A-Z/;
      last CASE
    }

    carp "Unknown CASEMAP $casemap, defaulted to rfc1459";
    $casemap = 'rfc1459';
    redo CASE
  }

  $string
}

sub eq_irc ($$;$) {
  my ($first, $second, $casemap) = @_;
  uc_irc($first, $casemap) eq uc_irc($second, $casemap);
}

sub irc_str {
  require IRC::Toolkit::Case::MappedString;
  IRC::Toolkit::Case::MappedString->new(@_)
}

print
  qq[<Gilded> Also, every now and then I talk about a game I've enjoyed],
  qq[ and rofer doesn't have time for it, Capn v1.02 doesn't understand],
  qq[ the human concept of fun/entertainment, c[_] only plays retro-games],
  qq[ made in his native homeland of Moria and avenj would rather shoot],
  qq[ rifles while vaping\n]
unless caller; 1;

=pod

=head1 NAME

IRC::Toolkit::Case - IRC case-folding utilities

=head1 SYNOPSIS

  use IRC::Toolkit::Case;

  my $lower = lc_irc( $string, 'rfc1459' );

  my $upper = uc_irc( $string, 'ascii' );

  if (eq_irc($first, $second, 'strict-rfc1459')) {
    ...
  }

  # Or use the '|rfc1459|' operator if using RFC1459 rules:
  if ($first |rfc1459| $second) {

  }

=head1 DESCRIPTION

IRC case-folding utilities.

IRC daemons typically announce their casemap in B<ISUPPORT> (via the
B<CASEMAPPING> directive). This should be one of C<rfc1459>,
C<strict-rfc1459>, or C<ascii>:

  'ascii'           a-z      -->  A-Z
  'rfc1459'         a-z{}|^  -->  A-Z[]\~   (default)
  'strict-rfc1459'  a-z{}|   -->  A-Z[]\

If told to convert/compare an unknown casemap, these functions will warn and
default to RFC1459 rules.

If you're building a class that tracks an IRC casemapping and manipulates
strings accordingly, you may also want to see L<IRC::Toolkit::Role::CaseMap>.

=head2 rfc1459 operator

The infix operator C<|rfc1459|> is provided as a convenience for string
comparison (using RFC1459 rules):

  if ($first |rfc1459| $second) { ... }
  # Same as:
  if (eq_irc($first, $second)) { ... }

=head2 lc_irc

Takes a string and an optional casemap.

Returns the lowercased string.

=head2 uc_irc

Takes a string and an optional casemap.

Returns the uppercased string.

=head2 eq_irc

Takes a pair of strings and an optional casemap.

Returns boolean true if the strings are equal 
(per the rules specified by the given casemap).

=head2 irc_str

  my $str = irc_str( strict => 'Nick^[Abc]' );
  if ( $str eq 'nick^{abc}' ) {
    # true
  }

Takes a casemap and string; if only one argument is provided, it is taken to
be the string and a C<rfc1459> casemap is assumed.

Produces overloaded objects (see L<IRC::Toolkit::Case::MappedString>) that can
be stringified or compared; string comparison operators use the specified
casemap.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Inspired by L<IRC::Utils>, copyright Chris Williams, Hinrik et al

Licensed under the same terms as Perl.

=cut
