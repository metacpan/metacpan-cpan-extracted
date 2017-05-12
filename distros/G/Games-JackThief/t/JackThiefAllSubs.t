  use Test::Simple tests => 11;
  use Games::JackThief;
  
  ok (my $JackThief = Games::JackThief->new(), 'new called');
  ok( defined($JackThief) && ref $JackThief eq 'Games::JackThief',     'Constructor new() works' );
  ok( $JackThief->{no_of_Decks}  =~ m/\d+/,     'Default no_of_Decks fine'    );
  ok( $JackThief->{no_of_Players}  =~ m/\d+/,     'Default no_of_Players fine'    );
  
  ok (my $JackThief = Games::JackThief->new({no_of_Decks => 5, no_of_Players => 10}), 'new alled with param');
  ok( $JackThief->{no_of_Decks}  =~ m/\d+/,     'Parameterized  no_of_Decks fine'    );
  ok( $JackThief->{no_of_Decks}  =~ m/\d+/,     'Parameterized no_of_Decks fine'    ); 
  
  
  ok ($JackThief->JackThief_Hand, 'JackThief_Hand works');
  ok ($JackThief->CreateFetchSeq, 'CreateFetchSeq works');
  ok ($JackThief->JackThief_RunFetchRound, 'JackThief_RunFetchRound works');
  ok ($JackThief->LooserFound, 'LooserFound works');
