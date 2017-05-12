use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Egg::Model::FsaveDate };
if ($@) {
	plan skip_all=> "Egg::Model::FsaveDate is not installed.";
} else {
	test();
}

sub test {

plan tests=> 5;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_file(
  $tool->helper_yaml_load( join('', <DATA>)), { path => $path },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => {
    MODEL=> ['FsaveDate'],
    VIEW => ['Mail'],
    },
  });

ok my $m= $e->view('mail_test'), q{my $m= $e->view('mail_test')};

isa_ok $m, 'Egg::View::Mail::Plugin::SaveBody';

ok $m->send( body=> 'test' ), q{$m->send( body=> 'test' )};

can_ok $m, 'is_savebody';
  ok -e $m->is_savebody, q{-e $m->is_savebody};

}

__DATA__
filename: <e.path>/lib/Vtest/View/Mail/Test.pm
value: |
  package Vtest::View::Mail::Test;
  use strict;
  use warnings;
  use base qw/ Egg::View::Mail::Base /;
  
  __PACKAGE__->config(
    label_name => 'mail_test',
    cmd_path   => '/usr/sbin/sendmail',
    debug      => 1,
    to         => 'mynam1@my.domainname',
    );
  
  __PACKAGE__->setup_plugin('SaveBody');
  
  __PACKAGE__->setup_mailer('CMD');
  
  1;
