#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Test::MockObject;
use Test::MockModule;

use Email::Postman;

use MIME::Parser;

my $MAIL_DIR = __FILE__;
$MAIL_DIR =~ s/\/[^\/]+$//;
$MAIL_DIR .= '/emails/';

my $parser = MIME::Parser->new();
## Avoid parser output going to disk
$parser->output_to_core(1);


my $mock_smtp;
my $net_dns;

unless( $ENV{LIVE_TEST} ){
  ## Mock the SMTP class.
  $mock_smtp = Test::MockObject->new();
  $mock_smtp->fake_module('Net::SMTP' , new => sub{ $mock_smtp });
  $mock_smtp->set_true('recipient', 'data', 'dataend' , 'quit');
  $mock_smtp->set_always('message' , "A mocked failure message");
  ## The fourth mail should not work.
  my $mail_i = 0;
  $mock_smtp->mock('mail' , sub{ return !( $mail_i++ == 3 ); });

  ## Mock the dns resolution.
  $net_dns = new Test::MockModule('Net::DNS');
  $net_dns->mock('mx', sub{ return ( Net::DNS::RR->new('fakedomain MX 10 fakemx.example.com') ); });
}

my $postman = Email::Postman->new({ debug => 1 });

{
  my $email = $parser->parse_open($MAIL_DIR.'multiple.email');
  ok( my @reports = $postman->deliver($email) , "Ok can deliver the email");
  ok( $reports[0]->success() , "Ok success on one");
  ok( $reports[1]->success() , "Ok success on two");
  ok( $reports[2]->success() , "Ok success on three");
  ok( $reports[3]->failure() , "Ok failure on four");

  ## Check the right about_headers are there.
  is( $reports[0]->about_header() , 'To' , "Ok good header for 1");
  is( $reports[1]->about_header() , 'To' , "Ok good header for 2");
  is( $reports[2]->about_header() , 'To' , "Ok good header for 3");
  is( $reports[3]->about_header() , 'To' , "Ok good header for 4");
}


ok(1);
done_testing();
