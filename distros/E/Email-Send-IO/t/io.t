use Test::More;
use strict;
$^W = 1;

use lib 't/lib';

use Email::Send;

plan skip_all => "these tests require IO::All"
  unless Email::Send->new->mailer_available('IO');

plan skip_all => "these tests require File::Temp"
  unless eval { require File::Temp; File::Temp->import(qw(tempfile)); 1 };

plan tests => 3;

my $message = <<"END_MESSAGE";
To: put-up
From: shut-up
Subject: jfdi

This is a test (message).
END_MESSAGE

my (undef, $filename) = tempfile(DIR => 't', UNLINK => 1);

{ my @no_warning_please = @Email::Send::IO::IO; }
@Email::Send::IO::IO = ($filename);

my $sender = Email::Send->new({ mailer => 'IO' });

ok($sender->send($message), 'send the first message');
ok($sender->send($message), 'and send it again');

open TEMPFILE, "<$filename" or die "couldn't open temp file: $!";

my @lines = <TEMPFILE>;

is(@lines, 10, "message delivered twice: nine lines in file");
