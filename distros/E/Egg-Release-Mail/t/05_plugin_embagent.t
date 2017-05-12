use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

test();

sub test {

plan tests=> 7;

my $tool= Egg::Helper->helper_tools;

my $project= 'Vtest';
my $path   = $tool->helper_tempdir. "/$project";

$tool->helper_create_file(
  $tool->helper_yaml_load( join('', <DATA>)),
  { path => $path },
  );

$ENV{HTTP_USER_AGENT}= 'tester';
$ENV{REMOTE_ADDR}= '255.255.255.255';

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { VIEW=> ['Mail'] },
  });

ok my $m= $e->view('mail_test'), q{my $m= $e->view('mail_test')};

isa_ok $m, 'Egg::View::Mail::Plugin::EmbAgent';

ok my $data= $m->create_mail_data( body=> 'test' ),
   q{my $data= $m->create_mail_data( body=> 'test' )};

ok my $body= $data->{body}, q{my $body= $data->{body}};
isa_ok $body, 'SCALAR';

like $$body, qr{\bREMOTE_ADDR\s+\:\s+\d+\.\d+\.\d+\.\d+},
   q{qr{\bREMOTE_ADDR\s+\:\s+\d+\.\d+\.\d+\.\d+}};

like $$body, qr{\bUSER_AGENT\s+\:\s+tester},
   q{qr{\bUSER_AGENT\s+\:\s+tester}};


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
    );
  
  __PACKAGE__->setup_plugin('EmbAgent');
  
  __PACKAGE__->setup_mailer('CMD');
  
  1;
