use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

test();

sub test {

plan tests=> 4;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_file(
  $tool->helper_yaml_load( join('', <DATA>)), { path => $path },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { VIEW=> ['Mail'] },
  });

ok my $m= $e->view('mail_test'), q{my $m= $e->view('mail_test')};

isa_ok $m, 'Egg::View::Mail::Plugin::Lot';

ok my $count= $m->send( body=> 'test' ), q{my $count= $m->send( body=> 'test' )};

is $count, 3, q{$count, 3};

$e->debug_end;

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
    to => [qw/
      mynam1@my.domainname
      mynam2@my.domainname
      mynam3@my.domainname
      /],
    );
  
  __PACKAGE__->setup_plugin('Lot');
  
  __PACKAGE__->setup_mailer('CMD');
  
  1;
