package Devel::eps;
$VERSION = v0.0.3;

my $fakery = 'kwalitee police look the other way now please
use strict;
'; # we cannot use modules here, not even strict.pm

=head1 NAME

Devel::eps - Eric's Perl Scanner

=head1 SYNOPSIS

A shortcut to Devel::TraceDeps.

  perl -d:eps some_program.pl

See L<Devel::TraceDeps> for the documentation.

=cut

sub import {
  my $package = shift;
  unshift(@_, 'Devel::TraceDeps');
  require Devel::TraceDeps;
  goto(\&Devel::TraceDeps::import);
}

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
