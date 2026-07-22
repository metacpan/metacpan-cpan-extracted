use 5.006;
use strict;
use warnings;

use Test::More;
use YAML::PP::Perl;
use Test::MockModule;
use Devel::Cover::DB;
use Devel::Cover::Report::Codecovbash;

use FindBin '$Bin';
my $datadir = "$Bin/data/cover_db";
$ENV{DEVEL_COVER_DB_FORMAT} = 'JSON';

my $db = Devel::Cover::DB->new(db => $datadir);
my $file = 't/dummy';

subtest 'any statement' => sub {
    my ($path, $coverage) = Devel::Cover::Report::Codecovbash::_get_file_coverage($file, $db);
    my $expected = [
        undef,1,1,1,undef,1,
        undef,1,undef,undef,1,
        0,undef,undef,1,undef,
        1,1,undef,1,
    ];
    is_deeply $coverage, $expected;
};

subtest default => sub {
    my $data_file = "$Bin/data/report1-cover.yaml";
    my $data = YAML::PP::Perl::LoadFile($data_file);
    my $mock_cover = Test::MockModule->new('Devel::Cover::DB::Cover', no_auto => 1);
    $mock_cover->redefine(file => $data);
    my $mock_ccb = Test::MockModule->new('Devel::Cover::Report::Codecovbash');
    $mock_ccb->redefine(_get_file_lines => sub { 1 + scalar keys %{ $data->{statement} } });

    my ($path, $coverage) = Devel::Cover::Report::Codecovbash::_get_file_coverage($file, $db);
    is_deeply $coverage, [undef, 1, 0, 1, 1, undef], 'line coverage correct';
};

subtest 'all statements per line' => sub {
    my $data_file = "$Bin/data/report1-cover.yaml";
    my $data = YAML::PP::Perl::LoadFile($data_file);
    my $mock_cover = Test::MockModule->new('Devel::Cover::DB::Cover', no_auto => 1);
    $mock_cover->redefine(file => $data);
    my $mock_ccb = Test::MockModule->new('Devel::Cover::Report::Codecovbash');
    $mock_ccb->redefine(_get_file_lines => sub { 1 + scalar keys %{ $data->{statement} } });

    local $ENV{DEVEL_COVER_CODECOVBASH_COVER_ALL_STATEMENTS} = 1;
    my ($path, $coverage) = Devel::Cover::Report::Codecovbash::_get_file_coverage($file, $db);
    is_deeply $coverage, [undef, 1, 0, 0, 0, undef], 'line coverage correct';
};

done_testing;
