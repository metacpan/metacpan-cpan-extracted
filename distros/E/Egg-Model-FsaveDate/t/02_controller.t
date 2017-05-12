use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

test();

sub test {

plan tests=> 6;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_file(
  $tool->helper_yaml_load( join('', <DATA>)),
  { path => $path, start=> $tool->helper_current_dir },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { MODEL=> ['FsaveDate'] },
  });

ok $e->is_model('fsavedate'), q{$e->is_model('fsavedate')};

ok my $m= $e->model('fsavedate'), q{my $m= $e->model('fsavedate')};

isa_ok $m, 'Vtest::Model::FsaveDate::handler';
isa_ok $m, 'Egg::Model::FsaveDate::Base';

ok my $output= $e->model('fsavedate')->save(<<END_TEST);
????????????????????
????????????????????
????????????????????
????????????????????
????????????????????
END_TEST

ok -e $output, q{-e $output };

}

__DATA__
filename: <e.path>/lib/Vtest/Model/FsaveDate.pm
value: |
  package Vtest::Model::FsaveDate;
  use strict;
  use warnings;
  
  our $VERSION= '0.01';
  
  package Vtest::Model::FsaveDate::handler;
  use strict;
  use base qw/ Egg::Model::FsaveDate::Base /;
  
  __PACKAGE__->config(
    label_name=> 'test',
    );
  
  1;
