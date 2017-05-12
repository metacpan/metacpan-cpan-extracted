#!perl -T
use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockModule;

use Email::Postman;

use Net::DNS;

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
  $mock_smtp->set_always('message' , 'Some mocked failure message');
  $mock_smtp->set_true('mail' , 'recipient', 'data', 'dataend' , 'quit');

  ## Mock the dns resolution.
  $net_dns = new Test::MockModule('Net::DNS');
  $net_dns->mock('mx', sub{ return ( Net::DNS::RR->new('fakedomain MX 10 fakemx.example.com') ); });
}

my $postman = Email::Postman->new({ debug => 1 });

{
  my $email = $parser->parse_open($MAIL_DIR.'simple.email');
  ok( my @reports = $postman->deliver($email) , "Ok can deliver the email");
  ok( $reports[0]->success() , "Sending this was a success");
  ok( $reports[0]->timestamp() , "Ok got a timestamp");
  ok( ! $reports[0]->failed_at() , "No failure date");
}

{
  $mock_smtp->set_false('recipient') if ( $mock_smtp );
  my $email = $parser->parse_open($MAIL_DIR.'wrongrecpt.email');
  ok( my @reports = $postman->deliver($email) , "Ok can deliver the email");
  ok( ! $reports[0]->success() , "Sending this was NOT a success");
  diag($reports[0]->message());
  ok( $reports[0]->message() , "And we have a message in this report");
  ok( $reports[0]->failed_at() , "Ok got a failure date");

}

ok(1);
done_testing();
