use strict;
use warnings;
use utf8;
use Test::More;
use Email::Forward::Dispatch;
use Test::Output;

my $fname = "./t/sample_mail.txt";
open my $fh, '<', $fname or die "$fname: $!";
my $mail = do {local $/; <$fh>; };

subtest 'callback interface' => sub {
    
    my $dispatcher = Email::Forward::Dispatch->new(
            mail          => $mail,
            is_forward_cb => sub { ($_[1]->header('To') =~ /hirobanex\@gmail\.com/) ? 1 : 0 },
            forward_cb    => sub { print $_[1]->header('To') },
    );

    stdout_like {$dispatcher->run} qr/gmail/,;
};

subtest 'hook class name diff' => sub {
    
    my $default_hooks1 = Email::Forward::Dispatch->new(
            mail          => $mail,
            is_forward_cb => sub { 0 },
            forward_cb    => sub { 0 },
    )->default_hook;
    
    my $default_hooks2 = Email::Forward::Dispatch->new(
            mail          => $mail,
            is_forward_cb => sub { 1 },
            forward_cb    => sub { 1 },
    )->default_hook;

    isnt $default_hooks1, $default_hooks2;
};

done_testing;

