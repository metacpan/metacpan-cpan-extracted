package Grimlock::Schema::Result::Entry;
{
  $Grimlock::Schema::Result::Entry::VERSION = '0.11';
}

use Grimlock::Schema::Candy -components => [
  qw(
      TimeStamp
      Helper::Row::ToJSON
      +DBICx::MaterializedPath
      )
];

use HTML::Scrubber;

resultset_class 'Grimlock::Schema::ResultSet::Entry';

primary_column entryid => {
  data_type => 'int',
  is_nullable => 0,
  is_auto_increment => 1,
  extra => { unsigned => 1 },
};

unique_column title => {
  data_type => 'varchar',
  size => 200,
  is_nullable => 0,
};

unique_column display_title => {
  data_type => 'varchar',
  size => 200,
  is_nullable => 0,
};

column path => {
  data_type => 'varchar',
  size      => 255,
  is_nullable => 1
};

column parent => {
  data_type => 'bigint',
  is_nullable => 1,
  extra => { unsigned => 1 },
  is_foreign_key => 1
};

column body => {
  data_type => 'text',
  is_nullable => 0,
};

column author => {
  data_type => 'int',
  is_nullable => 0,
  extra => { unsigned => 1 },
};

column created_at => {
  data_type => 'datetime',
  is_nullable => 0,
  set_on_create => 1,
  accessor => '_created_at'
};

column updated_at => {
  data_type => 'datetime',
  is_nullable => 1,
  set_on_create => 1,
  set_on_update => 1
};

column published => {
  data_type => 'tinyint',
  is_nullable => 0,
  default_value => 0
};

belongs_to 'author' => 'Grimlock::Schema::Result::User', {
  'foreign.userid' => 'self.author',
};

belongs_to 'parent' => __PACKAGE__, {
  'foreign.entryid' => 'self.parent',
},
{
  join_type => 'LEFT',
};

has_many 'children' => __PACKAGE__, {
  'foreign.parent' => 'self.entryid'
};

__PACKAGE__->mk_classdata( path_column => "path" );
__PACKAGE__->mk_classdata( path_separator => "." );

sub insert {
  my ( $self, @args ) = @_;

  # move me to a filter class
  my $guard = $self->result_source->schema->txn_scope_guard;
  
  $self->clean_params([qw( title body )]);

  # move me to a filter class
  my $title = $self->title;
  $title =~ s{(\W+|\s+|\_)}{-}g;
  chomp $title if $title =~ m/\W$/;
  $self->display_title($title);
  $self->next::method(@args);
  
  $guard->commit;
  return $self;
}


sub scrubber { 
  my $self = shift;
  return HTML::Scrubber->new(allow => [ qw[ p b i u hr br ] ] ); 
}

sub clean_params {
  my ( $self, $params ) = @_;
  # need to add a filter to deal with this
  my $scrubber = $self->scrubber;
  for my $column ( @{ $params } ) {
    warn "CLEANING $column";
    my $scrubbed = $scrubber->scrub($self->$column);
    $self->$column($scrubbed);
  }
  return $self
}


sub sqlt_deploy_hook {
  my ($self, $sqlt_table) = @_;
 
  $sqlt_table->add_index(name => 'tree_data', fields => ['parent']);
}

sub reply_count {
  my $self = shift;
  return $self->children->count;
}

sub created_at {
  my $self = shift;
  my $created_at = $self->_created_at;
  my $date_time = $created_at->month_name . " "  . 
                  $created_at->day        . ", " . 
                  $created_at->year       . " at " .   
                  $created_at->hms        . " "  .
                  $created_at->time_zone->name;
  return $date_time;
}


sub TO_JSON {
  my $self = shift;
  return {
    reply_count => $self->reply_count,
    children => $self->children_TO_JSON,
    parent   => $self->parent,
    body     => $self->body,
    %{ $self->next::method },
  }
}

sub children_TO_JSON {
  my $self = shift;
  my $children_rs = $self->children;
  my @child_collection;
  push @child_collection, {
    entryid => $_->entryid,
    title   => $_->title,
    display_title => $_->display_title,
    path    => $_->path,
    parent  => $_->parent,
    body    => $_->body,
    author  => $_->author,
    created_at => $_->created_at . "",
    updated_at => $_->updated_at . "",
    published => $_->published,
    reply_count => $_->reply_count,
    children => $_->children_TO_JSON,
    parent   => $_->parent,
  } for $children_rs->all;
  
  return \@child_collection;
}

1;
