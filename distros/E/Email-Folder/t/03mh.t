#!perl -w
use strict;
use Test::More tests => 4;

use_ok("Email::Folder");

my $folder;
ok($folder = Email::Folder->new('t/testmh/.'));


my @messages = $folder->messages;
is(@messages, 4, "grabbed 4 messages");

my @subjects = sort map { $_->header('Subject') }  @messages;

my @known = (
             'Alfa bravo charlie delta',
             'Echo foxtrot gulf hotel',
             'India juliet kilo lima',
             'Mike november oscar popa'
            );

is_deeply(\@subjects, \@known, "they're the messages we expected");
