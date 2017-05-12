use strict;
use warnings;

use Test::More;
plan skip_all => 'Convert the test to use Plack::Test';
exit;


use t::lib::Dwimmer::Test qw(start $admin_mail @users);

use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use JSON qw(from_json);

my $password = 'dwimmer';

my $run = start($password);

eval "use Test::More";
eval "use Test::Deep";
require Test::WWW::Mechanize;
plan( skip_all => 'Unsupported OS' ) if not $run;

my $url = "http://localhost:$ENV{DWIMMER_PORT}";
my $URL = "$url/";

plan( tests => 6 );

my $w = Test::WWW::Mechanize->new;
$w->get_ok($URL);
$w->content_like( qr{Welcome to your Dwimmer installation}, 'content ok' );

$w->get_ok("$url/DSP_v1");
#diag($w->content);
$w->content_like( qr{Page does not exist.}, 'content ok' );

{
  local $ENV{dwimmer_user_name} = 'admin';
  local $ENV{dwimmer_user_pw}   = $password;
  local $ENV{dwimmer_url}       = $url;
  system "$^X eg/update_wiki 1 eg/update_wiki";
}
$w->get_ok("$url/DSP_v1");
$w->content_like( qr{# Sample script to create or update a page from a file}, 'content ok' );
#diag($w->content);
