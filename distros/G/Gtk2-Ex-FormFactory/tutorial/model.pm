# $Id: model.pm,v 1.2 2005/07/04 15:35:30 joern Exp $

package Music::DBI;
use base 'Class::DBI';
Music::DBI->connection($Music::Config::instance->get_connection_data);
sub accessor_name { "get_$_[1]" }
sub mutator_name  { "set_$_[1]" }
sub autoupdate	  { 1 }

package Music::Artist;
use base 'Music::DBI';
Music::Artist->table('artist');
Music::Artist->columns(All => qw/id name notes/);
Music::Artist->has_many(albums => 'Music::Album', { order_by => 'title' } );

package Music::Genre;
use base 'Music::DBI';
Music::Genre->table('genre');
Music::Genre->columns(All => qw/id name/);

package Music::Album;
use base 'Music::DBI';
Music::Album->table('album');
Music::Album->columns(All => qw/id artist genre title year notes/);
Music::Album->has_a(artist => 'Music::Artist');
Music::Album->has_a(genre  => 'Music::Genre');
Music::Album->has_many(songs => 'Music::Song', { order_by => 'nr' } );

package Music::Song;
use base 'Music::DBI';
Music::Song->table('song');
Music::Song->columns(All => qw/id album title nr/);
Music::Song->has_a(album => 'Music::Album');

1;
