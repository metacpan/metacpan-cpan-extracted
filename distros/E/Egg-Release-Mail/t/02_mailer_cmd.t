use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

#
#  $ENV{EGG_EMAIL_ADDR}    = 'myname@mydomain';
#  $ENV{EGG_SENDMAIL_PATH} = '/usr/sbin/sendmail';
#

my $sendmail= $ENV{EGG_SENDMAIL_PATH} || do {
	  -e '/usr/sbin/sendmail'       ? '/usr/sbin/sendmail'
	: -e '/usr/local/sbin/sendmail' ? '/usr/local/sbin/sendmail'
	: -e '/usr/bin/sendmail'        ? '/usr/bin/sendmail'
	: 0;
  };

if ($sendmail) {
	if ($ENV{EGG_EMAIL_ADDR}) {
		test($sendmail);
	} else {
		plan skip_all=> "I want setup of environment variable.";
	}
} else {
	plan skip_all=> "'Sendmail' command is not found.";
}

sub test {

plan tests=> 7;

my($cmd_path)= @_;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_file(
  $tool->helper_yaml_load( join('', <DATA>)),
  { path => $path, cmd_path => $cmd_path },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { VIEW=> ['Mail'] },
  });


ok $e->is_view('mail_test'), q{$e->is_view('mail_test')};
ok my $m= $e->view('mail_test'), q{my $m= $e->view('mail_test')};

isa_ok $m, 'Vtest::View::Mail::Test';
isa_ok $m, 'Egg::View::Mail::Mailer::CMD';
isa_ok $m, 'Egg::View::Mail::Base';
isa_ok $m, 'Egg::Component::Base';

ok $m->send( to=> $ENV{EGG_EMAIL_ADDR}, body=> "test" ),
   q{$m->send( to=> $ENV{EGG_EMAIL_ADDR}, body=> "test" )};

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
    cmd_path   => '<e.cmd_path>',
    );
  
  __PACKAGE__->setup_mailer('CMD');
  
  1;
