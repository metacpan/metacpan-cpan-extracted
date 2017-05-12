use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

#
#  $ENV{EGG_SCAN_HOST}  = 'localhost';
#  $ENV{EGG_SCAN_PORT}  = 25;
#  $ENV{EGG_EMAIL_ADDR} = 'myname@mydomain';
#

eval{ require Egg::Plugin::Net::Scan };
if ($@) {
	plan skip_all=> "Egg::Plugin::Net::Scan is not installed."
} else {
	if ($ENV{EGG_EMAIL_ADDR} and $ENV{EGG_SCAN_HOST}) {
		test();
	} else {
		plan skip_all=> "I want setup of environment variable.";
	}
}

sub test {

plan tests=> 6;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_file(
  $tool->helper_yaml_load( join('', <DATA>)), {
    path => $path,
    scan_host => $ENV{EGG_SCAN_HOST},
    scan_port => ($ENV{EGG_SCAN_PORT} || 25 ),
    },
  );

my $e= Egg::Helper->run( Vtest => {
  vtest_plugins=> [qw/ Net::Scan/],
  vtest_root   => $path,
  vtest_config => { VIEW=> ['Mail'] },
  });

ok my $m= $e->view('mail_test'), q{my $m= $e->view('mail_test')};

isa_ok $m, 'Egg::View::Mail::Plugin::PortCheck';

ok $m->send( to=> $ENV{EGG_EMAIL_ADDR}, body=> 'test' ),
   q{$m->send( to=> $ENV{EGG_EMAIL_ADDR}, body=> 'test' )};

can_ok $m, 'scan';
  isa_ok $m->scan, 'Egg::Plugin::Net::Scan::Result';
  ok $m->scan->is_success, q{$m->scan->is_success};

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
    scan_host  => '<e.scan_host>',
    scan_port  => '<e.scan_port>',
    debug      => 1,
    );
  
  __PACKAGE__->setup_plugin('PortCheck');
  
  __PACKAGE__->setup_mailer('CMD');
  
  1;
