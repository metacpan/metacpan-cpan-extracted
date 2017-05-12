use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

our $email= $ENV{EGG_EMAIL_ADDR} || 'myname@mydomain';

eval{ require MIME::Entity };
if ($@) {
	plan skip_all=> "MIME::Entity is not installed."
} else {
	test();
}

sub test {

plan tests=> 15;

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

isa_ok $m, 'Egg::View::Mail::MIME::Entity';

ok my $data= $m->create_mail_data(
  to          => $email,
  from        => $email,
  cc          => $email,
  bcc         => $email,
  replay_to   => $email,
  return_path => $email,
  x_mailer    => 'tester',
  subject     => 'mime test.',
  body        => "test ok !!",
  headers     => {
    'X-Test' => '1',
    },
  ), q{my $body= $m->create_mail_data( ...... };

ok my $body= $data->{body}, q{my $body= $data->{body}};
isa_ok $body, 'SCALAR';

my $mailreg= quotemeta($email);

like $$body, qr{\bContent\-Type\:\s+text\/plain},
   q{qr{\bContent\-Type\:\s+text\/plain}};

like $$body, qr{\bMIME\-Version\:\s+\d+\.\d+},
  q{qr{\bMIME\-Version\:\s+\d+\.\d+}};

like $$body, qr{\bTo\:\s+$mailreg},   q{qr{\bTo\:\s+$mailreg}};

like $$body, qr{\bFrom\:\s+$mailreg}, q{qr{\bFrom\:\s+$mailreg}};

like $$body, qr{\bCC\:\s+$mailreg},   q{qr{\bCC\:\s+$mailreg}};

like $$body, qr{\bBCC\:\s+$mailreg},  q{qr{\bBcc\:\s+$mailreg}};

like $$body, qr{\bReply\-To\:\s+$mailreg},  q{qr{\bReply\-To\:\s+$mailreg}};

like $$body, qr{\bReturn\-Path\:\s+$mailreg},  q{qr{\bReturn\-Path\:\s+$mailreg}};

like $$body, qr{\bX\-Mailer\:\s+tester},  q{qr{\bX\-Mailer\:\s+tester}};

like $$body, qr{\bX\-Test\:\s+1},  q{qr{\bX\-Test\:\s+1}};

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
  
  __PACKAGE__->setup_mailer( SMTP => qw/ MIME::Entity /);
  
  1;
