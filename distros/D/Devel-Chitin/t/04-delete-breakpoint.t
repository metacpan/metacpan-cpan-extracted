#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    4,
    sub {
        $DB::single=1;
        13;
        for(my $i = 0; $i < 10; $i++) {
            15;
        }
        17;
    },
    \&create_breakpoint,
    'continue',
    loc(line => 15),
    \&delete_breakpoint,
    'continue',
    'at_end',
    'done',
);

my $break;
sub create_breakpoint {
    my($db, $loc) = @_;
    
    $break = Devel::Chitin::Breakpoint->new(
                    file => $loc->filename,
                    line => 15,
                );
    Test::More::ok($break, 'Set unconditional breakpoint on line 15');
}

sub delete_breakpoint {
    my($db, $loc) = @_;
    Test::More::ok($break->delete, 'Delete breakpoint');
}

