#!perl

use strict;
use warnings;

use HTTP::Response;
use Interchange::Search::Solr::Response;
use WebService::Solr::Response;
use Test::More;
use Data::Dumper;
use Scalar::Util qw/blessed/;

my $http_res = HTTP::Response->new(404);
ok (blessed($http_res), "empty response is blessed");
diag Dumper($http_res);
ok ($http_res->code);
my $res_parent = WebService::Solr::Response->new($http_res);

ok ($res_parent, "Parent works");

my $res = Interchange::Search::Solr::Response->new($http_res);

ok ($res);

ok ($res->can('error'));
ok $res->raw_response->code;


done_testing;
