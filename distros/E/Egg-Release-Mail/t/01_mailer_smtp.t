use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

#
#  $ENV{EGG_EMAIL_ADDR}= 'myname@mydomain';
#

eval{ require Net::SMTP };
if ($@) {
	plan skip_all=> "Net::SMTP is not installed."
} else {
	if ($ENV{EGG_EMAIL_ADDR}) {
		test();
	} else {
		plan skip_all=> "I want setup of environment variable.";
	}
}

sub test {

plan tests=> 7;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_file(
  $tool->helper_yaml_load( join('', <DATA>)),
  { path => $path },
  );

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { VIEW=> ['Mail'] },
  });

ok $e->is_view('mail_test'), q{$e->is_view('mail_test')};
ok my $m= $e->view('mail_test'), q{my $m= $e->view('mail_test')};

isa_ok $m, 'Vtest::View::Mail::Test';
isa_ok $m, 'Egg::View::Mail::Mailer::SMTP';
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
    );
  
  __PACKAGE__->setup_mailer('SMTP');
  
  1;
