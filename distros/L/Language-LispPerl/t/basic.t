#! perl

use strict;
use warnings;

use Test::More;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;

ok( my $lisp = Language::LispPerl::Evaler->new() );
ok( my $var = $lisp->new_var( 'foo', 123 ) );
is( $var->value() , 123 );
is ( $lisp->eval()->type() , 'nil' );
is( !! $lisp->word_is_reserved('eval') , 1 );

ok( Language::LispPerl->true() );
ok( Language::LispPerl->false() );
ok( Language::LispPerl->nil() );
ok( Language::LispPerl->empty_list() );

done_testing();
