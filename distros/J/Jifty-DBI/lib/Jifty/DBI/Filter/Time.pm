package Jifty::DBI::Filter::Time;

use warnings;
use strict;

use base qw|Jifty::DBI::Filter::DateTime|;

use constant _time_zone => 'floating';
use constant _strptime  => '%H:%M:%S';

=head1 NAME

Jifty::DBI::Filter::Date - DateTime object wrapper around date columns

=head1 DESCRIPTION

This filter allow you to work with DateTime objects that represent "Dates",
store everything in the database in GMT and not hurt yourself badly
when you pull them out and put them in repeatedly.

=head2 encode

If value is a DateTime object then move it into a "floating" timezone
and expand it into ISO 8601 format C<HH-MM-SS>.  By storing it in 
the database as a floating timezone, it doesn't matter if the user's 
desired timezone changes between lookups

Does nothing if value is not defined or is a string.

=cut

=head2 decode

If we're loading something from a column that doesn't specify times, then
it's loaded into a floating timezone.

If value is defined then converts it into DateTime object otherwise do
nothing.

=cut


=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<DateTime>

=cut

1;
