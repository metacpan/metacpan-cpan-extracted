#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Pty::Easy;

my $pty = IO::Pty::Easy->new;
eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 5;
    $pty->spawn("missing_program_io_pty_easy");
    alarm 0;
};
like($@, qr/Cannot exec\(missing_program_io_pty_easy\)/);
ok(!$pty->is_active, "pty isn't active if program doesn't exist");

done_testing;
