use strict;
use warnings;

use lib 't/lib';

use File::Basename;
use File::Spec;
use HTTP::Response;
use Test::More tests => 3;

BEGIN { use_ok('Footprintless::Plugin::Atlassian::Confluence::ResponseParser') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $test_dir = dirname( File::Spec->rel2abs($0) );

my $response_parser = Footprintless::Plugin::Atlassian::Confluence::ResponseParser->new();

my $http_response = HTTP::Response->new();
$http_response->code(200);
$http_response->message('Success');
$http_response->content('{"foo":"bar"}');
is_deeply(
    $response_parser->get_content($http_response),
    { code => 200, message => 'Success', success => 1, content => { foo => 'bar' } },
    'get_content 200'
);

$http_response = HTTP::Response->new();
$http_response->code(404);
$http_response->message('Not Found');
is_deeply(
    $response_parser->get_content($http_response),
    { code => 404, message => 'Not Found', success => 0, content => '' },
    'get_content 404'
);
