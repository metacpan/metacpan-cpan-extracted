package t::User;
use Mad::Mapper -base;

table 'mad_mapper_simple_users';

pk 'id';
col email => '';
col name  => '';

has_many groups => 't::Group' => 'user_id';
has_many groups_sorted => 't::Group';

sub _has_many_groups_sorted_sql {
  my ($self, $related_class, $by) = @_;

  die 'hacking, ey?' unless $by =~ /^[\w\s]+$/;
  $self->{by} = $by;
  $related_class->expand_sql("SELECT %pc FROM %t WHERE user_id=? order by $by", $self->id);
}

sub _find_sql {
  my $self = shift;
  my $pk   = $self->_pk_or_first_column;

  if ($self->{$pk}) {
    return $self->expand_sql("SELECT %pc FROM %t WHERE $pk=?"), $self->$pk;
  }
  elsif ($self->{group}) {
    return $self->expand_sql(
      "SELECT %pc.x FROM mad_mapper_has_many_groups g LEFT JOIN %t.x ON g.user_id = x.id WHERE g.name=? LIMIT 1"),
      $self->{group};
  }
  else {
    return $self->expand_sql("SELECT %pc.x FROM %t.x WHERE x.email=?"), $self->email;
  }
}

1;
