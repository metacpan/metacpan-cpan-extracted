#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

# -- flow control

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;
use Test::Output;

use Language::Befunge;
use Language::Befunge::IP;
use Language::Befunge::Vector;
my $bef = Language::Befunge->new;


# space is a no-op
$bef->store_code( 'f   f  +     7       +  ,   q' );
stdout_is { $bef->run_code } '%', 'space is a no-op';


# z is a true no-op
$bef->store_code( 'zzzfzzzfzz+zzzzz7zzzzzzz+zz,zzzq' );
stdout_is { $bef->run_code } '%', 'z is a true no-op';


# trampoline
$bef->store_code( '1#2.q' );
stdout_is { $bef->run_code } '1 ', 'trampoline';


# stop
$bef->store_code( '1.@' );
stdout_is { $bef->run_code } '1 ', 'stop';


# comments / jump over
$bef->store_code( '2;this is a comment;1+.@' );
stdout_is { $bef->run_code } '3 ', 'comments are jumped over';


# jump to
$bef->store_code( '2j123..q' );
stdout_is { $bef->run_code } '3 0 ', 'jump to, positive';
$bef->store_code( '0j1.q' );
stdout_is { $bef->run_code } '1 ', 'jump to, null';
$bef->store_code( <<'END_OF_CODE' );
v   q.1 <>06-j2.q
>        ^
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'jump to, negative';


# quit instruction
$bef->store_code( 'aq' );
my $rv = $bef->run_code;
is( $rv, 10, 'exit return value' );


# repeat instruction (glurps)
$bef->store_code( '3572k.q' );
stdout_is { $bef->run_code } '7 5 3 ', 'repeat, normal';
$bef->store_code( '0k.q' );
stdout_is { $bef->run_code } '', 'repeat, null';
$bef->store_code( <<'END_OF_CODE' );
5kv
 > 1.q
  >2.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'repeat, useless';
$bef->store_code( '5-k43.q' );
stdout_is { $bef->run_code } '3 ', 'repeat, negative';
$bef->store_code( '5k;q' );
stdout_is { $bef->run_code } '', 'repeat, forbidden char';
$bef->store_code( '5kkq' );
stdout_is { $bef->run_code } '', 'repeat, repeat instruction';

# short circuit
$bef->store_code( '' );
$bef->set_curip( Language::Befunge::IP->new );
$bef->get_curip->set_position( Language::Befunge::Vector->new_zeroes(2) );
throws_ok { $bef->move_ip( $bef->get_curip, qr/ / ) } qr/infinite loop/,
    'move_ip() short circuit on a dead end';
$bef->store_code( ' ;' );
$bef->set_curip( Language::Befunge::IP->new );
$bef->get_curip->set_position( Language::Befunge::Vector->new_zeroes(2) );
throws_ok { $bef->move_ip( $bef->get_curip, qr/ / ) } qr/infinite loop/,
    'move_ip() short circuit on non closed comment';


