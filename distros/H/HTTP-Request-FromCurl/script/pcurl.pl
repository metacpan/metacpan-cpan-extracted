#!perl
use strict;
use warnings;

use HTTP::Request::FromCurl;
use LWP::UserAgent;
use Getopt::Long ':config','pass_through';
use Pod::Usage;

our $VERSION = '0.55';

# parse output options from @ARGV
GetOptions(
    'output|o=s' => \my $outfilename,
    'help|h'         => \my $show_help,
) or pod2usage(2);

pod2usage(1) if $show_help;

my @output_options;
if( $outfilename ) {
    push @output_options, $outfilename;
};

# now execute all requests
my @requests = HTTP::Request::FromCurl->new(
    argv => \@ARGV,
    read_files => 1,
);

my $ua = LWP::UserAgent->new();

for my $request (@requests) {
    print
        $ua->request( $request->as_request, @output_options )->decoded_content;
};
