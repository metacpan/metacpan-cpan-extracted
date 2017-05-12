use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Jcode };
if ($@) {
	plan skip_all=> "Jcode is not installed."
} else {
	test();
}

sub test {

plan tests=> 5;

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

isa_ok $m, 'Egg::View::Mail::Plugin::Jfold';

ok my $data= $m->create_mail_data( body=> <<END_BODY );
あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもよゆよらりるれろわをん１２３４５６７８９０ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ
END_BODY

ok my $body= $data->{body}, q{my $body= $data->{body}};

$$body=~s{\s+$} []s;
$$body=~s{^.+\n\n+\s*} []s;

my @lines= split /\n/, $$body;
is scalar(@lines), 3, q{scalar(@lines), 3};

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
  
  __PACKAGE__->setup_plugin('Jfold');
  
  __PACKAGE__->setup_mailer('CMD');
  
  1;
