use Test::More tests => 7;
BEGIN { use_ok( 'Math::DyckWords' ) };

my @words = Math::DyckWords::dyck_words_by_lex( 5 );

# there shold be 42 Dyck Words of length 5
ok( scalar @words == 42, "dyck-words-by-lex" );

@words = Math::DyckWords::dyck_words_by_position( 5 );
ok( scalar @words == 42, "dyck-words-by-position" );

@words = Math::DyckWords::dyck_words_by_swap( 5 );
ok( scalar @words == 42, "dyck-words-by-swap" );

my $rank = Math::DyckWords::ranking( '0011000111' );
ok( $rank == 19, "ranking" );

my $word = Math::DyckWords::unranking( 5, 19 );
ok( $word eq '0011000111', "unranking" );

my $catalan_number = Math::DyckWords::catalan_number( 300 );
ok( $catalan_number eq '448863594671741755862042783981742625904431712455792292112842929523169934910317996551330498997589600726489482164006103817421596314821101633539230654646302151568026806610883615856' );
