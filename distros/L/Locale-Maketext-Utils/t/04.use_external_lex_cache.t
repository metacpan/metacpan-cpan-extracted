use Test::More tests => 9;

BEGIN {
    chdir 't';
    unshift @INC, qw(lib ../lib);
    use_ok('Locale::Maketext::Utils');
    use_ok('MyTestLocale');
}

my $lh = MyTestLocale->get_handle('fr');
$lh->{'use_external_lex_cache'} = 1;
ok( exists $MyTestLocale::fr::Lexicon{'Hello World'} && !ref $MyTestLocale::fr::Lexicon{'Hello World'}, 'lex value not a ref' );

ok( $lh->maketext('Hello World') eq 'Bonjour Monde', 'renders correctly first time' );
ok( exists $lh->{'_external_lex_cache'}{'Hello World'} && ref $lh->{'_external_lex_cache'}{'Hello World'}, 'compiled into lex_cache' );
ok( exists $MyTestLocale::fr::Lexicon{'Hello World'}   && !ref $MyTestLocale::fr::Lexicon{'Hello World'},  'lex value still not a ref' );

ok( $lh->maketext('Hello World') eq 'Bonjour Monde', 'renders correctly second time time' );
ok( exists $lh->{'_external_lex_cache'}{'Hello World'} && ref $lh->{'_external_lex_cache'}{'Hello World'}, 'still compiled into lex_cache' );
ok( exists $MyTestLocale::fr::Lexicon{'Hello World'}   && !ref $MyTestLocale::fr::Lexicon{'Hello World'},  'lex value still not a ref' );

