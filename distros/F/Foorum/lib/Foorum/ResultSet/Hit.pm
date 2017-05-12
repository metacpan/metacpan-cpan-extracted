package Foorum::ResultSet::Hit;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub register {
    my ( $self, $object_type, $object_id, $object_hit ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

   # we update table 'hit' then use Foorum::TheSchwartz::Worker::Hit to update
   # the real table every 5 minutes
   # the status field is time(), after update in real, that will be 0

    my $hit = $self->search(
        {   object_type => $object_type,
            object_id   => $object_id,
        }
    )->first;
    my $return_hit;
    if ($hit) {
        $return_hit = $hit->hit_all + 1;
        $hit->update(
            {   hit_new          => \'hit_new + 1',
                hit_all          => \'hit_all + 1',
                last_update_time => time(),
            }
        );
    } else {
        $return_hit = $object_hit || 0;
        $return_hit++;
        $self->create(
            {   object_type      => $object_type,
                object_id        => $object_id,
                hit_new          => 1,
                hit_all          => $return_hit,
                hit_today        => 0,
                hit_yesterday    => 0,
                hit_weekly       => 0,
                hit_monthly      => 0,
                last_update_time => time(),
            }
        );
    }

    return $return_hit;
}

1;
