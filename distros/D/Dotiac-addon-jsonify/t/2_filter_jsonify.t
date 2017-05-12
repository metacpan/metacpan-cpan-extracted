use Test::More tests=>6;
chdir "t";
no warnings;

require Dtest;
use warnings;
use strict;
use JSON qw/to_json/;

my $data={List=>[1,2,3],Value=>"Foo\x{34fc}"};

my $ja=to_json($data,{ascii=>1});

dtest("filter_jsonify.html","A$ja"."A\n",{data=>$data});
