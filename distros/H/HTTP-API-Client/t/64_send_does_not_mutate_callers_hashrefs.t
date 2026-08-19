=head1 NAME

64_send_does_not_mutate_callers_hashrefs.t - HAC-083: send() merged
pre_defined_data/pre_defined_headers/pre_defined_events directly into
the caller's own \%data/\%headers/\%events hashrefs instead of copying
them first, and new_request()/kvp2json()/kvp2str() autovivified
before_header/after_header/not_include keys into the caller's actual
%events hashref even when never set. A caller reusing a hashref across
multiple calls (a natural pattern) got silently corrupted state back.
send() now shallow-copies all three before doing anything with them, so
the caller's original hashrefs are left exactly as they passed them in.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new(
    pre_defined_data    => { pd => 1 },
    pre_defined_headers => { ph => 1 },
    pre_defined_events  => {},
);

my %my_data    = ( a => 1 );
my %my_headers = ( h => 1 );
my %my_events  = ( test_request_object => 1 );

$api->get( "http://example.com", \%my_data, \%my_headers, \%my_events );

is_deeply \%my_data, { a => 1 },
    "the caller's \%data hashref is untouched - pre_defined_data merged into a copy, not the original";
is_deeply \%my_headers, { h => 1 },
    "the caller's \%headers hashref is untouched - pre_defined_headers merged into a copy, not the original";
is_deeply \%my_events, { test_request_object => 1 },
    "the caller's \%events hashref is untouched - no autovivified before_header/after_header/not_include keys";

done_testing;
