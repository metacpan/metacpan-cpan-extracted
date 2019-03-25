package Music_Translate_Fields;
require Music_Normalize_Fields;

for my $elt ( qw( title track artist album comment year genre
		  title_track artist_collection person ) ) {
  *{"normalize_$elt"} = \&{"Music_Normalize_Fields::normalize_$elt"} if defined &{"Music_Normalize_Fields::normalize_$elt"};
  *{"translate_$elt"} = \&{"normalize_$elt"} if defined &{"normalize_$elt"};
}
for my $elt ( qw( short_person ) ) {
  *{"$elt"} = \&{"Music_Normalize_Fields::$elt"} if defined &{"Music_Normalize_Fields::$elt"};
}

1;
