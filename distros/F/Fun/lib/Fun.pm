package Fun;
BEGIN {
  $Fun::AUTHORITY = 'cpan:DOY';
}
{
  $Fun::VERSION = '0.05';
}
use strict;
use warnings;
# ABSTRACT: simple function signatures

use Devel::CallParser;
use XSLoader;

XSLoader::load(
    __PACKAGE__,
    exists $Fun::{VERSION} ? ${ $Fun::{VERSION} } : (),
);

use Exporter 'import';
our @EXPORT = our @EXPORT_OK = ('fun');



sub fun {
    my ($code) = @_;
    return $code;
}


1;

__END__
=pod

=head1 NAME

Fun - simple function signatures

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Fun;

  fun float_eq ($a, $b, $e = 0.0001) {
      return abs($a - $b) < $e;
  }

=head1 DESCRIPTION

This module provides C<fun>, a new keyword which defines functions the same way
that C<sub> does, except allowing for function signatures. These signatures
support defaults and slurpy arguments, but no other advanced features. The
behavior should be equivalent to taking the signature, stripping out the
defaults, and injecting C<< my <sig> = @_ >> at the start of the function, and
then applying defaults as appropriate, except that the arguments are made
readonly.

=head1 EXPORTS

=head2 fun

Behaves identically to C<sub>, except that it does not support prototypes or
attributes, but it does support a simple function signature. This signature
consists of a comma separated list of variables, each variable optionally
followed by C<=> and an expression to use for a default. For instance:

  fun foo ($x, $y = 5) {
      ...
  }

Defaults are evaluated every time the function is called, so global variable
access and things of that sort should work correctly.

C<fun> supports creating both named and anonymous functions, just as C<sub>
does.

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-fun at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Fun>.

=head1 SEE ALSO

L<signatures>, etc...

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Fun

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Fun>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Fun>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Fun>

=item * Search CPAN

L<http://search.cpan.org/dist/Fun>

=back

=head1 AUTHOR

Jesse Luehrs <doy at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

