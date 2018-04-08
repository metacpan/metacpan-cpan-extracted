package Memorator::Backend::Mojo::SQLite;
use strict;
use warnings;
{ our $VERSION = '0.006'; }

use Mojo::Base 'Memorator::Backend';

sub migration {
   my $self = shift;
   my $table = $self->table_name;
   return <<"END";
-- 1 up
CREATE TABLE IF NOT EXISTS $table (
   id     INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   eid    TEXT    NOT NULL,
   jid    INTEGER NOT NULL,
   active INTEGER NOT NULL DEFAULT 1
);
-- 1 down
DROP TABLE $table;
END
}

1;
