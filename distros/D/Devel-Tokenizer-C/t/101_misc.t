################################################################################
#
# $Project: /Devel-Tokenizer-C $
# $Author: mhx $
# $Date: 2008/04/13 13:30:59 +0200 $
# $Revision: 3 $
# $Source: /t/101_misc.t $
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

BEGIN { plan tests => 7 }

my($o,$c);

eval {
  $o = new Devel::Tokenizer::C CaseSensitive => 0
                             , TokenString   => 'foo'
                             , UnknownLabel  => 'unk'
                             , TokenEnd      => 'TEND'
                             , TokenFunc     => sub { "return \"$_[0]\"\n"; }
                             ;
};
ok( $@, '', "failed to construct object" );

eval {
  $o = new Devel::Tokenizer::C tokenFunc => [];
};
ok( $@, qr/Invalid option 'tokenFunc' at \Q$0\E/, "wrong error" );

eval {
  $o = new Devel::Tokenizer::C TokenFunc => [];
};
ok( $@, qr/Option TokenFunc needs a code reference at \Q$0\E/, "wrong error" );

eval {
  $c = $o->generate;
};
ok( $@, '', "unexpected error" );
ok( $c, '', "unexpected output" );

eval {
  $c = $o->add_tokens( 'foo' )->generate;
};
ok( $@, '', "unexpected error" );
ok( $c ne '' );

