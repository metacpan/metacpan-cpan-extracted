package HTML::Display::Debian;
use strict;
use parent 'HTML::Display::TempFile';
use vars qw($VERSION);
$VERSION='0.40';

=head1 NAME

HTML::Display::Debian - display HTML using the Debian default

=head1 SYNOPSIS

=for example begin

  my $browser = HTML::Display->new();
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");

=for example end

This module implements displaying HTML through the Debian default web browser
referenced as the program C<x-www-browser>.

=cut

sub browsercmd { "x-www-browser %s" };

=head1 AUTHOR

Copyright (c) 2004-2013 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;
