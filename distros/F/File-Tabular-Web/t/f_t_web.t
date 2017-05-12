#!perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Copy;
use HTTP::Request::Common;
use Plack::Test;
use File::Tabular::Web;
use Test::More tests => 11;

my $base_app = File::Tabular::Web->new->to_app;
my $url = "html/entities.ftw";

test_psgi
  app => sub {
    my $env = shift;
    $env->{REMOTE_USER}   = "tst_file_tabular_web";
    $env->{DOCUMENT_ROOT} = "$Bin/htdocs";
    $base_app->($env);
  },
  client => sub {
    my $cb = shift;

    my $res = $cb->(GET $url);
    like $res->content, qr[Welcome], 'homepage';

    $res = $cb->(GET $url . "?S=*");
    like $res->content, qr[<b>67</b> results found],     'search all';
    like $res->content, qr[max 200],                     'fixed config param';
    like $res->content, qr[<b>1</b>\s*to\s*<b>20</b>],   'default config param';

    $res = $cb->(GET $url . "?S=grave");
    like $res->content, qr[<b>10</b> results found],     'search grave';

    $res = $cb->(GET $url . "?L=221"); 
    like $res->content, qr[Entity named <b>Yacute</b>],  'long';

    $res = $cb->(GET $url . "?M=221"); 
    like $res->content, qr[<input name="Name" value="Yacute">], 'modify';

    SKIP : {
      # get a fresh copy of the data file
      copy("$Bin/htdocs/html/entities_src.txt",
           "$Bin/htdocs/html/entities.txt")
        or skip "cannot copy data file", 4;

      $res = $cb->(POST $url, {M => 221});
      like $res->content, qr[Updated.*221],              'update';


      $res = $cb->(GET $url . "?D=221");
      like $res->content, qr[Deleted.*221],              'delete';

      $res = $cb->(GET $url . "?S=221");
      like $res->content, qr[<b>0</b> results found],    'check deleted';

      $res = $cb->(GET $url . "?A=1");
      like $res->content, qr[input name="Num" value="#"],'add';

      # restore to initial state for next run of tests
      copy("$Bin/htdocs/html/entities_src.txt",
           "$Bin/htdocs/html/entities.txt");
    }
    };
