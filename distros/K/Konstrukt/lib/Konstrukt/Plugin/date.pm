=head1 NAME

Konstrukt::Plugin::date - Displays the current date

=head1 SYNOPSIS
	
B<Usage:>

	<& date / &>

B<Result:>

	April 23, 2006 - 10:45:16

=head1 DESCRIPTION

This plugin will display the current date.

=cut

package Konstrukt::Plugin::date;

use strict;
use warnings;

use base 'Konstrukt::SimplePlugin';

=head1 ACTIONS

=head2 default

Put out the date.

=cut
sub default : Action {
	my ($self, $tag, $content, $params) = @_;
	
	#Return Date and Time
	my @months = qw/January February March April May June July August September October November December/;
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
	$year += 1900;
	my $date = sprintf("$months[$mon] %02d, %04d - %02d:%02d:%02d", $mday, $year, $hour, $min, $sec);
	print $date;
}
#= /default

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::SimplePlugin>, L<Konstrukt>

=cut
