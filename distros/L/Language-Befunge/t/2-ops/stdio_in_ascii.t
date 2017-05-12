#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Language::Befunge::Ops;

use strict;
use warnings;

use Language::Befunge::Interpreter;
use Language::Befunge::IP;
use Language::Befunge::Ops;
use Language::Befunge::Vector;
use Test::More tests => 7;
use IO::Pipe;
use IO::Select;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
$lbi->set_curip( $ip );
my $pid = fork_input("3\n");
Language::Befunge::Ops::stdio_in_ascii( $lbi );
is( $ip->get_position, '(0,0)', 'stdio_in_ascii does not move ip' );
is( $ip->get_delta, '(1,0)', 'stdio_in_ascii does not reflect (yet)' );
is( $ip->spop, ord('3'), 'stdio_in_ascii pushes value on ip' );
is( $ip->spop, 0, 'stdio_in_ascii only read one character' );

Language::Befunge::Ops::stdio_in_ascii( $lbi );
is( $ip->spop, ord("\n"), 'stdio_in_ascii pushes value on ip' );
waitpid($pid, 0);

Language::Befunge::Ops::stdio_in_ascii( $lbi );
is( $ip->spop, 0, 'stdio_in_ascii only read one character' );
is( $ip->get_delta, '(-1,0)', 'stdio_in_ascii reflects on eof' );

sub fork_input {
    my $data = shift;
    my $pipe = IO::Pipe->new();
    my $pid = fork();
    if($pid) {
        $pipe->reader();
        *STDIN = *$pipe;
        return $pid;
    }
    alarm(5); # timeout on failure
    $pipe->writer();
    $pipe->print($data);
    exit(0);
}
