package HTML::Display::Win32;
use strict;
use vars qw($VERSION);
$VERSION='0.40';

=head1 NAME

HTML::Display::Win32 - display an URL through the default application for HTML

=head1 SYNOPSIS

=for example begin

  my $browser = HTML::Display->new();
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");

=for example end

=head1 BUGS

Currently does not work.

Making it work will need either munging the tempfilename to
become ".html", or looking through the registry whether we find
a suitable application there.

=cut

use parent 'HTML::Display::TempFile';

sub browsercmd { 
  # cmd.exe needs two arguments, command.com needs one
  ($ENV{COMSPEC} =~ /cmd.exe$/i) ? 'start "HTML::Display" "%s"' : 'start "%s"'
};

=head1 AUTHOR

Copyright (c) 2004-2013 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;
