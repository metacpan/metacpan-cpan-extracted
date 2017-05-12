package Kwiki::DB::Music::Artist;
use base 'Kwiki::DB::Music';
use CLASS;

CLASS->table("artist");
CLASS->columns(All => qw/artistid name/);
CLASS->has_many(cds => "Kwiki::DB::Music::CD");

1;

