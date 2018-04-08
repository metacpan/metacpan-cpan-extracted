package Memorator::Backend::Mojo::Pg;
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
   id     bigserial NOT NULL PRIMARY KEY,
   eid    text      NOT NULL,
   jid    bigint    NOT NULL,
   active int       NOT NULL DEFAULT 1
);
-- 1 down
DROP TABLE $table;
END
}

1;
