package HTML::Display::Mozilla;
use strict;
use parent 'HTML::Display::TempFile';
use vars qw($VERSION);
$VERSION='0.40';

=head1 NAME

HTML::Display::Mozilla - display HTML through Mozilla

=head1 SYNOPSIS

=for example begin

  my $browser = HTML::Display->new();
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");

=for example end

=cut

sub browsercmd { 'mozilla -remote "openURL(%s)"' };

=head1 AUTHOR

Copyright (c) 2004-2013 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;
