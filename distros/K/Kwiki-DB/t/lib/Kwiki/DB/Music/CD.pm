package Kwiki::DB::Music::CD;
use base 'Kwiki::DB::Music';
use CLASS;

CLASS->table("cd");
CLASS->columns(All => qw/cdid artist title year/);
CLASS->has_a(artist => 'Kwiki::DB::Music::Artist');

1;

