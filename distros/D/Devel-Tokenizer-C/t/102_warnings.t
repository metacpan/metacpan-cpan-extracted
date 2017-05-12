################################################################################
#
# $Project: /Devel-Tokenizer-C $
# $Author: mhx $
# $Date: 2008/04/13 13:30:59 +0200 $
# $Revision: 3 $
# $Source: /t/102_warnings.t $
#
################################################################################
# 
# Copyright (c) 2002-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

use Test;
use Devel::Tokenizer::C;
use strict;

do 't/common.sub';

$^W = 1;

BEGIN { plan tests => 20 }

my @warn;
$SIG{__WARN__} = sub { push @warn, $_[0] };

# case sensitive checks
my $o = new Devel::Tokenizer::C;

@warn = ();
$o->add_tokens( 'foo' );
ok( scalar @warn, 0, "unexpected warnings" );

@warn = ();
$o->add_tokens( 'bar' );
ok( scalar @warn, 0, "unexpected warnings" );

@warn = ();
$o->add_tokens( 'Foo' );
ok( scalar @warn, 0, "unexpected warnings" );

@warn = ();
$o->add_tokens( 'baR' );
ok( scalar @warn, 0, "unexpected warnings" );

@warn = ();
$o->add_tokens( 'foo' );
ok( scalar @warn, 1, "no/too many warnings" );
ok( $warn[0], qr/^Multiple definition of token 'foo' at \Q$0\E/, "wrong warning" );

@warn = ();
$o->add_tokens( 'baR' );
ok( scalar @warn, 1, "no/too many warnings" );
ok( $warn[0], qr/^Multiple definition of token 'baR' at \Q$0\E/, "wrong warning" );

@warn = ();
$o->add_tokens( [qw( foo bar )], 'defined XXX' );
ok( scalar @warn, 2, "no/too many warnings" );
ok( $warn[0], qr/^Redefinition of token 'foo' at \Q$0\E/, "wrong warning" );
ok( $warn[1], qr/^Redefinition of token 'bar' at \Q$0\E/, "wrong warning" );

# case insensitive checks
$o = new Devel::Tokenizer::C CaseSensitive => 0;

@warn = ();
$o->add_tokens( 'FOO' );
ok( scalar @warn, 0, "unexpected warnings" );

@warn = ();
$o->add_tokens( 'BAR' );
ok( scalar @warn, 0, "unexpected warnings" );

@warn = ();
$o->add_tokens( 'Foo' );
ok( scalar @warn, 1, "no/too many warnings" );
ok( $warn[0], qr/^Multiple definition of token 'Foo' at \Q$0\E/, "wrong warning" );

@warn = ();
$o->add_tokens( 'baR' );
ok( scalar @warn, 1, "no/too many warnings" );
ok( $warn[0], qr/^Multiple definition of token 'baR' at \Q$0\E/, "wrong warning" );

@warn = ();
$o->add_tokens( [qw( foo bar )], 'defined XXX' );
ok( scalar @warn, 2, "no/too many warnings" );
ok( $warn[0], qr/^Redefinition of token 'foo' at \Q$0\E/, "wrong warning" );
ok( $warn[1], qr/^Redefinition of token 'bar' at \Q$0\E/, "wrong warning" );


