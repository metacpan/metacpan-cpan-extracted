#!perl
use strict;
use warnings;

use HTTP::Request::FromWget;
use LWP::UserAgent;
use Getopt::Long ':config','pass_through';

our $VERSION = '0.51';

# parse output options from @ARGV
GetOptions(
    'output-file|O=s' => \my $outfilename,
);

my @output_options;
if( $outfilename ) {
    push @output_options, $outfilename;
};

# now execute all requests
my @requests = HTTP::Request::FromWget->new(
    argv => \@ARGV,
    read_files => 1,
);

my $ua = LWP::UserAgent->new();

for my $request (@requests) {
    print
        $ua->request( $request->as_request, @output_options )->decoded_content;
};
