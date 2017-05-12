use Test::More tests => 40;

BEGIN {
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');
}

my $nss = '';
eval 'require Tie::Hash::ReadonlyStack';
$nss = 'Tie::Hash::ReadonlyStack' if $@;
eval 'require Tie::Hash';
if ($@) {
    $nss = $nss ? " and Tie::Hash" : "Tie::Hash";
}

SKIP: {
    skip "$nss required for testing Tie::Hash::ReadonlyStack compat methods", 38 if $nss;

    package MyTie;
    require Tie::Hash;
    @MyTie::ISA = qw(Tie::StdHash);
    sub TIEHASH { return bless {}, shift }
    sub STORE { $_[0]{ $_[1] } = $_[2] }

    package MyTestLocale::it;

    use MyTestLocale;
    @MyTestLocale::it::ISA = qw(MyTestLocale);
    tie %MyTestLocale::it::Lexicon, 'MyTie';
    $MyTestLocale::it::Lexicon{'a'} = 1;

    package MyTestLocale::ja;

    use MyTestLocale;
    @MyTestLocale::ja::ISA = qw(MyTestLocale);
    tie %MyTestLocale::ja::Lexicon, 'Tie::Hash::ReadonlyStack', { 'a' => 1 };
    $MyTestLocale::ja::Lexicon{'a'} = 2;

    package main;

    my $lh = MyTestLocale->get_handle('it');
    my $ro = MyTestLocale->get_handle('ja');

    #### tied but not Tie::Hash::ReadonlyStack w/ ns ####

    my $has_sub_todo = eval { require Sub::Todo } ? 1 : 0;
    $! = 0;    # just to be sure

    ok( !$lh->add_lexicon_override_hash( 'en', 'before', { 'a' => 1 } ), "add_lexicon_override_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );
  SKIP: {
        skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
        ok( $! > 0, 'add_lexicon_override_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }
  SKIP: {
        skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
        ok( $! == 0, 'add_lexicon_override_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }

    ok( !$lh->add_lexicon_fallback_hash( 'en', 'after', { 'b' => 1 } ), "add_lexicon_fallback_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );
  SKIP: {
        skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
        ok( $! > 0, 'add_lexicon_fallback_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }
  SKIP: {
        skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
        ok( $! == 0, 'add_lexicon_fallback_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }

    ok( !$lh->del_lexicon_hash( 'en', 'before' ), "del_lexicon_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );
  SKIP: {
        skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
        ok( $! > 0, 'del_lexicon_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }
  SKIP: {
        skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
        ok( $! == 0, 'del_lexicon_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }

    ok( !$lh->del_lexicon_hash( '*', 'before' ), "del_lexicon_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );
  SKIP: {
        skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
        ok( $! > 0, 'del_lexicon_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }
  SKIP: {
        skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
        ok( $! == 0, 'del_lexicon_hash() + * w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }

    #### tied but not Tie::Hash::ReadonlyStack w/ out ns ####

    ok( !$lh->add_lexicon_override_hash( 'before', { 'a' => 1 } ), "add_lexicon_override_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );
  SKIP: {
        skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
        ok( $! > 0, 'add_lexicon_override_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }
  SKIP: {
        skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
        ok( $! == 0, 'add_lexicon_override_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }

    ok( !$lh->add_lexicon_fallback_hash( 'after', { 'b' => 1 } ), "add_lexicon_fallback_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );
  SKIP: {
        skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
        ok( $! > 0, 'add_lexicon_fallback_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }
  SKIP: {
        skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
        ok( $! == 0, 'add_lexicon_fallback_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }

    ok( !$lh->del_lexicon_hash('before'), "del_lexicon_hash() returns false with non Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );
  SKIP: {
        skip "Sub::Todo required to test for 'not implemented' status", 1 if !$has_sub_todo;
        ok( $! > 0, 'del_lexicon_hash() + Sub::Todo sets $! with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }
  SKIP: {
        skip "Sub::Todo must not be installed to test for 'no Sub::Todo not implemented' status", 1 if $has_sub_todo;
        ok( $! == 0, 'add_lexicon_override_hash() w/ out Sub::Todo does not get $! set with non Tie::Hash::ReadonlyStack compat Lexicon' );
        $! = 0;
    }

    ok( !$lh->del_lexicon_hash('*'), "del_lexicon_hash() returns false with star only non Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );

    #### tied Tie::Hash::ReadonlyStack w/ ns ####
    ok( $ro->add_lexicon_override_hash( 'ja', 'before', { 'a' => 42 } ), "add_lexicon_override_hash() returns true with Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );
    ok( $ro->add_lexicon_fallback_hash( 'ja', 'after', { 'b' => 1 } ), "add_lexicon_fallback_hash() returns true with Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );

    # add_lex_hash_silent_if_already_added
    ok( !$ro->add_lexicon_override_hash( 'ja', 'before', { 'a' => 42 } ), 'add override w/ already existing name returns false w/ ns' );
    ok( !$ro->add_lexicon_fallback_hash( 'ja', 'before', { 'a' => 42 } ), 'add fallback w/ already existing name returns false w/ ns' );

    {
        local $ro->{'add_lex_hash_silent_if_already_added'} = 1;
        ok( $ro->add_lexicon_override_hash( 'ja', 'before', { 'a' => 42 } ), 'add override w/ already existing name returns true w/ ns' );
        ok( $ro->add_lexicon_fallback_hash( 'ja', 'before', { 'a' => 42 } ), 'add fallback w/ already existing name returns true w/ ns' );
    }

    ok( $ro->del_lexicon_hash( 'ja', 'before' ), "del_lexicon_hash() returns true with Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );
    ok( $ro->del_lexicon_hash( '*',  'after' ),  "del_lexicon_hash() returns true with Tie::Hash::ReadonlyStack compat Lexicon w/ ns" );

    #### tied Tie::Hash::ReadonlyStack w/ out ns ####

    ok( $ro->add_lexicon_override_hash( 'before', { 'a' => 1 } ), "add_lexicon_override_hash() returns true with Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );
    ok( $ro->add_lexicon_fallback_hash( 'after', { 'b' => 1 } ), "add_lexicon_fallback_hash() returns true with Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );

    # add_lex_hash_silent_if_already_added
    ok( !$ro->add_lexicon_override_hash( 'before', { 'a' => 42 } ), 'add override w/ already existing name returns false w/ out ns' );
    ok( !$ro->add_lexicon_fallback_hash( 'before', { 'a' => 42 } ), 'add fallback w/ already existing name returns false w/ out ns' );

    {
        local $ro->{'add_lex_hash_silent_if_already_added'} = 1;
        ok( $ro->add_lexicon_override_hash( 'before', { 'a' => 42 } ), 'add override w/ already existing name returns true w/ out ns' );
        ok( $ro->add_lexicon_fallback_hash( 'before', { 'a' => 42 } ), 'add fallback w/ already existing name returns true w/ out ns' );
    }

    ok( $ro->del_lexicon_hash('before'), "del_lexicon_hash() true with Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );
    ok( !$ro->del_lexicon_hash('*'),     "del_lexicon_hash() returns false with star only non Tie::Hash::ReadonlyStack compat Lexicon w/ out ns" );

}
