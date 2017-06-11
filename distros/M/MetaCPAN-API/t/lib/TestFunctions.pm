package TestFunctions;
use strict;
use warnings;
use MetaCPAN::API;
use Exporter (); BEGIN { *import = \&Exporter::import }

our @EXPORT = qw(mcpan);

my $version = $MetaCPAN::API::VERSION || 'xx';

sub mcpan {
    return MetaCPAN::API->new(
        ua_args => [ agent => "MetaCPAN::API-testing/$version" ],
    );
}

1;
