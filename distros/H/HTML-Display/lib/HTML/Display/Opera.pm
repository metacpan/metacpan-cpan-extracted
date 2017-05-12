package HTML::Display::Opera;
use strict;
use parent 'HTML::Display::TempFile';
use vars qw($VERSION);
$VERSION='0.40';

=head1 NAME

HTML::Display::Galeon - display HTML through Galeon

=head1 SYNOPSIS

=for example begin

  my $browser = HTML::Display->new();
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");

=for example end

=head1 ACKNOWLEDGEMENTS

Tina Mueller provided the browser command line

=cut

sub browsercmd { "opera %s" };

=head1 AUTHOR

Copyright (c) 2004-2013 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;
