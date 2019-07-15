use Test::More;
use Test::Exception;
use File::Spec;
use strict;
use lib '../lib';
use JSON::ize; # import jsonize

my $tdir = (-d 't') ? 't/sample' : 'sample';
my $dta;
my %tf = (
 gjf => File::Spec->catfile($tdir,"good.json"),
 gyf =>  File::Spec->catfile($tdir,"good.yaml"),
 bjf => File::Spec->catfile($tdir,"bad.json"),
 byf => File::Spec->catfile($tdir,"bad.yaml"),
 njy => File::Spec->catfile($tdir,'..',"001_simple.t"),
);

open my $gyf, $tf{gyf};
open my $gjf, $tf{gjf};
my ($y,$j);
{
  local $/;
  $y = <$gyf>;
  $j = <$gjf>;
}
close $gyf;
close $gjf;

ok JSON::ize::looks_like_yaml($y);
ok !JSON::ize::looks_like_yaml($j);
  

lives_ok {
  jsonize $tf{gjf}
} "good json";
is_deeply J()->{and}, [1,2,3,4], "read it";
lives_ok {
  $dta = jsonize $tf{gyf}
} "good yaml";
is_deeply J()->{but}, [qw/it could be better/], "read it";

dies_ok {
  jsonize $tf{bjf} 
} "bad json" ;

like $@, qr/^JSON decode barfed/, "interpreted as JSON";

dies_ok {
  jsonize $tf{byf} 
} "bad yaml" ; 

like $@, qr/^YAML decode barfed/, "interpreted as YAML";

dies_ok {
  jsonize $tf{njy}
} "just plain bad";

like $@, qr/^Both JSON and YAML/, "towel thrown in";

ok JSON::ize::looks_like_yaml( Y $dta ), "Y emits YAML";
ok JSON::ize::looks_like_yaml( yamlize $dta ), "yamlize emits YAML";
ok JSON::ize::looks_like_yaml( yamlise $dta ), "yamlise emits YAML";

ok JSON::ize::looks_like_yaml( yamlize jsonize $tf{gjf} ), "JSON to YAML";
ok  JSON::ize::looks_like_json( jsonize yamlize $tf{gyf} ), "YAML to JSON";

done_testing;
