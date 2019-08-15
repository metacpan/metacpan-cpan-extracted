use 5.012;
use strict;
use warnings;

use Test::More;
use Test::Warnings;
use File::Find::Rule;

plan skip_all => 'Test::Synopsis::Expectation required to test synopsises' unless eval {
    require Test::Synopsis::Expectation;
    Test::Synopsis::Expectation->import();
    1;
};

my @files = File::Find::Rule->file->name('*.pm', '*.pod')->in('./lib');
synopsis_ok(\@files);

done_testing;
