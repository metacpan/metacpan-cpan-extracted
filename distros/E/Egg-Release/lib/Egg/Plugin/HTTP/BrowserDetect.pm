package Egg::Plugin::HTTP::BrowserDetect;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: BrowserDetect.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use HTTP::BrowserDetect;

our $VERSION = '3.00';

sub browser { shift->{plugin_browser} ||= HTTP::BrowserDetect->new(@_) }

1;

__END__

=head1 NAME

Egg::Plugin::HTTP::BrowserDetect - Plugin for HTTP::BrowserDetect.

=head1 SYNOPSIS

  use Egg qw/ HTTP::BrowserDetect /;
  
  if ($e->browser->windows) {
     # OS is Windows.
  } elsif ($e->browser->mac) {
     # OS is Macintosh.
  } elsif ($e->browser->unix) {
     # OS is Unix.
  } else {
     # Other OS.
  }

=head1 DESCRIPTION

Information on a browser etc. that the client uses is examined.

see L<HTTP::BrowserDetect>.

=head1 METHODS

=head2 browser ([USER_AGENT])

The object of L<HTTP::BrowserDetect> is returned.

It is not necessary usually though USER_AGENT can be passed to the argument.

  my $browser= $e->browser;

=head1 SEE ALSO

L<HTTP::BrowserDetect>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

