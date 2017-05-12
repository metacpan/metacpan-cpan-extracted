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

my $e= Egg::Helper->run( Vtest => {
#  vtest_plugins=> [qw/ -Debug /],
  vtest_root   => $path,
  vtest_config => { VIEW=> ['Mail'] },
  });

ok my $m= $e->view('mail_test'), q{my $m= $e->view('mail_test')};

isa_ok $m, 'Egg::View::Mail::Plugin::Signature';

ok my $data= $m->create_mail_data( body=> "test\n" );

ok my $body= $data->{body}, q{my $body= $data->{body}};

like $$body, qr{<body_header>}s, q{$$body, qr{<body_header>}};

like $$body, qr{<body_footer>}s, q{$$body, qr{<body_footer>}};

like $$body, qr{<signature>}s,   q{$$body, qr{<signature>}};

}

__DATA__
filename: <e.path>/lib/Vtest/View/Mail/Test.pm
value: |
  package Vtest::View::Mail::Test;
  use strict;
  use warnings;
  use base qw/ Egg::View::Mail::Base /;
  
  __PACKAGE__->config(
    label_name  => 'mail_test',
    cmd_path    => '/usr/sbin/sendmail',
    body_header => "<body_header>\n",
    body_footer => "<body_footer>\n",
    signature   => "<signature>\n",
    );
  
  __PACKAGE__->setup_plugin('Signature');
  
  __PACKAGE__->setup_mailer('CMD');
  
  1;
