package t::Group;
use Mad::Mapper -base;

table 'mad_mapper_has_many_groups';

pk 'id';
col user_id => sub {die};
col name => '';

1;
