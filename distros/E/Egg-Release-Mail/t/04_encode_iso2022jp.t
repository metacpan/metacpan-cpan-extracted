use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

our $email= $ENV{EGG_EMAIL_ADDR} || 'myname@mydomain';

eval{ require MIME::Entity };
if ($@) {
	plan skip_all=> "MIME::Entity is not installed."
} else {
	eval{ require Jcode };
	if ($@) {
		plan skip_all=> "Jcode is not installed."
	} else {
		test();
	}
}

sub test {

plan tests=> 10;

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

ok my $data= $m->create_mail_data
   ( to=> $email, subject=> 'こんにちは', body=> <<END_BODY );
あいうえおかきくけこさしすせそ
END_BODY

ok my $body= $data->{body}, q{my $body= $data->{body}};
isa_ok $body, 'SCALAR';

is Jcode::getcode($body), 'jis', q{Jcode::getcode($body), 'jis'};

like $data->{subject}, qr{^\=\?ISO\-2022\-JP\?.+\=\=\?\=$},
   q{$data->{subject}, qr{^\=\?ISO\-2022\-JP\?.+\=\=\?\=$}};

like $$body, qr{\bContent\-Type\:\s+text\/plain},
   q{qr{\bContent\-Type\:\s+text\/plain}};

like $$body, qr{\bContent\-Transfer\-Encoding\:\s+7bit},
   q{qr{\bContent\-Transfer\-Encoding\:\s+7bit}};

like $$body, qr{\bContent\-Type\:\s+text\/plain\;\s+charset\=\"ISO\-2022\-JP\"},
   q{qr{\bContent\-Type\:\s+text\/plain\;\s+charset\=\"ISO\-2022\-JP\"}};

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
  
  __PACKAGE__->setup_mailer( CMD => qw/
     Encode::ISO2022JP
     MIME::Entity
     /);
  
  1;
