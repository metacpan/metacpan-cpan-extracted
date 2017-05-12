package English::Reference;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     ARRAY CODE GLOB HASH SCALAR
	     );
@EXPORT_OK = qw(
	     deref
	     );

$VERSION = '0.01';

#bootstrap English::Reference $VERSION;

sub ARRAY($) {
    return @{ shift() };
}
sub CODE($) {
    return &{ shift() };
}
sub GLOB($) {
    return *{ shift() };
}
sub HASH($) {
    return %{ shift() };
}
sub SCALAR($) {
    return ${ shift() };
}

sub deref($) {
    no strict qw(refs);
    return &{ref($_[0])}($_[0]);
}

1;
__END__

=head1 NAME

English::Reference - use words to dereference things

=head1 SYNOPSIS

  use English::Reference;
  or
  use English::Reference qw(deref);
  ...
  print SCALAR \"Hello World";

=head1 DESCRIPTION

Provides the ability to use:

=over 4

  ARRAY  $arrayref
  CODE   $coderef
  GLOB   $globref
  HASH   $hashref
  SCALAR $scalaref

=back

en lieu of

=over 4

  @$arrayref
  &$coderef
  *$globref
  %$hashref
  $$scalaref

=back

or

=over 4

  @{$arrayref}
  &{$coderef}
  *{$globref}
  %{$hashref}
  ${$scalaref}

=back

As an added bonus, there is a function C<deref>; not exported by default;
which you can use to dereference a reference of any type.

=head1 CAVEATS

You cannot do ARRAY{$arrayref} etc. This is not too bad seeing
as the whole point of this module is to reduce the amount of
punctuation you use.

=head1 AUTHORS

Jerrad Pierce <belg4mit@mit.edu, the_lorax@usa.net>,
Jeff Pinyan <japhy@pobox.com>, Casey R. Tweten <crt@kiski.net>

=head1 SEE ALSO

English(3).

=cut
