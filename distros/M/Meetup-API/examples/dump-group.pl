#!perl -w
use strict;
use Meetup::API;
use Data::Dumper;

my $meetup = Meetup::API->new();

# Frankfurt am Main
#my ($lat,$lon) = (50.110924, 8.682127);

$meetup->read_credentials;

print Dumper $meetup->group('Perl-User-Groups-Rhein-Main')->get;
print Dumper $meetup->group_events('Perl-User-Groups-Rhein-Main')->get;