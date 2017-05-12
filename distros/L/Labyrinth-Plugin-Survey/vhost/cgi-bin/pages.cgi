#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '1.00';

=head1 NAME

pages.cgi - CGI API into a YAPC survey website

=head1 DESCRIPTION

The basic access script into the Labyrinth core and plugin modules that
generate a YAPC survey website.

=head1 ABSTRACT

The basic access script into the Labyrinth core and plugin modules that
generate a YAPC survey website.

=cut

#----------------------------------------------------------
# Additional Modules

use lib qw|. ./lib ./plugins|;

#use CGI::Carp          qw(fatalsToBrowser);

use Labyrinth;

#----------------------------------------------------------

my $app = Labyrinth->new();
$app->run('/var/www/eventcode/cgi-bin/config/settings.ini');

1;

__END__

=head1 AUTHOR

  Barbie, E<lt>barbie@cpan.orgE<gt>
  Miss Barbell Productions, L<http://www.missbarbell.co.uk/>
  Birmingham Perl Mongers, L<http://birmingham.pm.org/>

=head1 COPYRIGHT

  Copyright (C) 2002-2011 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
