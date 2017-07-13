package Geo::GNS::Parser;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/parse_file @fields/;
use Carp;
our $VERSION = '0.02';

our $data_dir = '/home/ben/data/gns';

# See L<http://geonames.nga.mil/gns/html/gis_countryfiles.html> for
# explanations.

our @fields = qw/RC UFI UNI LAT LONG DMS_LAT DMS_LONG MGRS JOG FC DSG
PC CC1 ADM1 POP ELEV CC2 NT LC SHORT_FORM GENERIC SORT_NAME_RO
FULL_NAME_RO FULL_NAME_ND_RO SORT_NAME_RG FULL_NAME_RG FULL_NAME_ND_RG
NOTE MODIFY_DATE/;

sub parse_file
{
    my (%options) = @_;
    my $file = $options{file};
    my $data = $options{data};
    my $callback = $options{callback};
    my $callback_data = $options{callback_data};
    if (! $file) {
        croak "Specify a file with 'file =>'";
    }
    if ($file !~ m!/!) {
        $file = "$data_dir/$file";
    }
    open my $input, "<:encoding(utf8)", $file or die $!;
    while (<$input>) {
        my @parts = split /\t/;
        if (@parts != 29) {
            die "$file:$.: bad line containing " . scalar (@parts) . " parts.\n";
        }
        my %line;
        @line{@fields} = @parts;
        my $ufi = $line{UFI};
        if ($callback) {
            &{$callback} ($callback_data, \%line);
        }
        if ($data) {
            push @$data, \%line;
        }
    }
    close $input or die $!;
}

1;
