use 5.012;
use warnings;
use Test::More;

#plan skip_all => "set TEST_FULL=1 to enable synopsises tests" unless $ENV{TEST_FULL};

plan skip_all => 'Test::Synopsis::Expectation and File::Find::Rule required to test synopsises' unless eval {
    require Test::Synopsis::Expectation;
    Test::Synopsis::Expectation->import();
    require File::Find::Rule;
    1;
};

my @files = File::Find::Rule->file->name('*.pm', '*.pod')->in('./lib');
synopsis_ok(\@files);

done_testing;
