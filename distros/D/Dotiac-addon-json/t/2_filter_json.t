use Test::More tests=>24;
chdir "t";
no warnings;

require Dtest;
use warnings;
use strict;
use JSON qw/to_json/;

my $data={List=>[1,2,3],Value=>"Foo\x{34fc}"};

my $ja=to_json($data,{ascii=>1});
my $j=to_json($data,{utf8=>1});
my $jp=to_json($data,{utf8=>1,pretty=>1});
my $jap=to_json($data,{ascii=>1,pretty=>1});

dtest("filter_json.html","A$j"."A\n",{data=>$data});
dtest("filter_json_pretty.html","A$jp"."A\n",{data=>$data});
dtest("filter_json_ascii.html","A$ja"."A\n",{data=>$data});
dtest("filter_json_ascii_pretty.html","A$jap"."A\n",{data=>$data});
