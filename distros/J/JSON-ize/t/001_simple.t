use Test::More;
use Test::Exception;
use File::Spec;
use strict;
use lib '../lib';
use JSON::ize; # import jsonize

my $tdir = (-d 't') ? 't/sample' : 'sample';


is ref jsonize('{ "this":"hash"}'), 'HASH';
is ref jsonise('["is","array"]'), 'ARRAY';
is ref J(File::Spec->catfile($tdir,"good.json.gz")), 'HASH';
is ref J(File::Spec->catfile($tdir,"good.json")), 'HASH';


open my $f, File::Spec->catfile($tdir,"good.json");
my $j;
while (<$f>) {
  $j = parsej;
}
is ref $j, 'HASH';
is $j->{good},'json';
is ref jsonize(), 'HASH';
is jsonize()->{good},'json';
is jsonize("{\"this\":\"also\",\"works\":[1,2,3]}")->{"this"}, 'also';
dies_ok { jsonize('{ "whoa":}') };
dies_ok { jsonize('this does not work') };
dies_ok { jsonize(File::Spec->catfile($tdir,"bad.json")) };
if ($^O =~ /darwin|linux/){
  my $cmd = "cat ".
    File::Spec->catfile($tdir,"good.json") .
      " | $^X -Ilib -I../lib -MJSON::ize -ne 'parsej;' -e 'END{ print J->{good} }'";
  my ($try) = `$cmd`;
  is $try, "json";
}
done_testing();
