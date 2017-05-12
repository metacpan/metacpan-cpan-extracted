package DbFramework::Relationship;
use strict;
use base qw(DbFramework::DefinitionObject DbFramework::DataModelObject);
use DbFramework::ForeignKey;
use Alias;
use vars qw( $NAME $SRC $DEST @COLUMNS );
use Carp;

# CLASS DATA

my %relationships;
my %fields = (SRC   => undef,
	      DEST  => undef,
	      ROLES => [],    # DbFramework::Role
);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

sub new {
  my $DEBUG = 0;
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new(shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;

  attr $self;
  ($SRC,$DEST) = (shift,shift);
  $self->{COLUMNS} = shift || [];
  $relationships{$NAME} = [ $SRC,$DEST ];

  if ( $DEBUG ) {
    carp "relationship name: $NAME";
    for ( @{$self->{COLUMNS}} ) {
      carp "column: " . $_->name;
    }
  }

#  if ( ( $_[2] !~ /(1|N)/ && $_[3] !~ /(1|N)/ ) ||
#       ( $_[6] !~ /(1|N)/ && $_[7] !~ /(1|N)/ ) ) {
#    print STDERR $_[0]->name, "($_[2],$_[3]) ", $_[4]->name, "($_[6],$_[7])\n";
#    die "invalid cardinality";
#  }

  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

sub create_ddl {
  my $self    = attr shift;
  my $t       = shift;
  my %values  = ('rel_id'       => 0,
                 'rel_name'     => $NAME,
	         'rel_srctbl'   => $SRC->table->name,
		 'rel_srcrole'  => $SRC->role,
		 'rel_srcmin'   => $SRC->min,
		 'rel_srcmax'   => $SRC->max,
		 'rel_desttbl'  => $DEST->table->name,
		 'rel_destrole' => $DEST->role,
		 'rel_destmin'  => $DEST->min,
		 'rel_destmax'  => $DEST->max );
  $t->insert_ddl(\%values);
}

##-----------------------------------------------------------------------------

# requires (DbFramework::*::Table,DbFramework::*::Table)
sub many_to_many {
  my $class = shift;
  my($table1,$table2) = @_;

  for ( values(%relationships) ) {
    if ( ($_->[0][0] == $table1 && $_[1][0] == $table2) ||
         ($_->[0][0] == $table2 && $_[1][0] == $table1) ) {
      return 1 if ( $_->[0]->max eq 'N' && $_->[1]->max eq 'N' ); # M:N
      return 0;
    }
  }
}

##-----------------------------------------------------------------------------

# See Fundamentals of Database Systems by Elmasri/Navathe, 1989 p 329ff
# for relationship mapping rules
# requires: $DbFramework::*::Schema
sub set_foreign_key {
  my $DEBUG  = 0;
  my $self   = attr shift;
  my $schema = shift;

  if ( $DEBUG ) {
    carp "in DbFramework::Relationship::set_foreign_key";
    carp "(src)", $SRC->table->name, " ", $SRC->role, " ", $SRC->min, ",", $SRC->max, "\n";
    carp "(dest)", $DEST->table->name, " ", $DEST->role, " ", $DEST->min, ",", $DEST->max, "\n";
  }

  my $s; # role player to add relationship attributes to

  if ( ($SRC->max == 1) && ($DEST->max == 1) ) {	# 1:1
    # add fk in relation with highest min cardinality
    my @roles = sort _by_min ($DEST,$SRC);
    my $null  = ($roles[0]->min == 0) ? 1 : 0;
    $self->_pk_as_fk($null,@roles);
    $s = $roles[0]->table;
  }

  if ( ($SRC->max == 1)   && ($DEST->max eq 'N') ||
       ($SRC->max eq 'N') && ($DEST->max == 1) ) {	# 1:N
    # add fk in relation with N cardinality
    my @roles = sort _by_max ($DEST,$SRC);
    if ( $DEBUG ) {
      carp $roles[0]->min, ",", $roles[1]->min;
    }
    my $null = ($roles[0]->min == 0) ? 1 : 0;
    $self->_pk_as_fk($null,@roles);
    $s = $roles[0]->table;
  }

  if ( ($SRC->max eq'N') && ($DEST->max eq 'N') ) {     # M:N
    carp "M:N ", $SRC->table->name, ",", $DEST->table->name if ( $DEBUG );
    # an M:N can be re-defined as two 1:N relationships with a new table
    # we don't store these conceptual relationships atm

    my $table_name = $SRC->table->name . '_' . $DEST->table->name;
    # primary key consists of pk from each table in the M:N (NOT NULL)
    my(@src_pk,@dest_pk);
    foreach ( @{$SRC->table->primary_key->columns} ) {
      push(@src_pk,$_->new($_->name,$_->type,$_->length,0,undef));
    }
    foreach ( @{$DEST->table->primary_key->columns} ) {
      push(@dest_pk,$_->new($_->name,$_->type,$_->length,0,undef));
    }
    my $pk     = DbFramework::PrimaryKey->new([@src_pk,@dest_pk]);
    my $n_side = $SRC->table->new($table_name,[@src_pk,@dest_pk],$pk,undef);
    $n_side->foreign_key(DbFramework::ForeignKey->new($SRC->table,\@src_pk));
    $n_side->foreign_key(DbFramework::ForeignKey->new($DEST->table,\@dest_pk));
    $schema->tables( [ $n_side ] );
    $s = $n_side;
  }

  # add attributes of relationship to appropriate table
  if ( @COLUMNS ) {
    print STDERR "adding columns from relationship $NAME to ",$s->name,"\n"
      if $DEBUG;
    $s->add_columns(\@COLUMNS);
  }
}

##-----------------------------------------------------------------------------

# ascending sort by max cardinality
sub _by_max {
  my $DEBUG = 0;
  if ( $DEBUG ) {
    carp "in DbFramework::Relationship::_sort_relationship";
    carp $a->max, ",", $b->max;
  }
  if ( $b->max == 1 ) {
    return 0  if ( $a->max == 1 );
    return -1 if ( $a->max eq 'N' );
  }
  if ( $b->max eq 'N' ) {
    return 0 if ( $a->max == 'N' );
    return 1 if ( $a->max == 1 );
  }
}

##-----------------------------------------------------------------------------

# ascending sort by min cardinality
sub _by_min {
  return ( $a->min <=> $b->min );
}

##-----------------------------------------------------------------------------

# add primary key from table as a foreign key in related table
# require: ($DbFramework::RolePlayer,$DbFramework::RolePlayer)
sub _pk_as_fk {
  my $DEBUG = 0;
  carp "in DbFramework::Relationship::_pk_as_fk" if ( $DEBUG );
  my $self = attr shift;
  my($null,$pk_side,$fk_side) = @_;

  if ( $DEBUG ) {
    carp "pk side: ", $pk_side->table->name, " fk side: ", $fk_side->table->name;
  }
  my $column_name_suffix;
  if ( $pk_side->table->name eq $fk_side->table->name ) { # recursive
    $column_name_suffix = '_' . $NAME;
  }

  my @columns;
  foreach ( @{$pk_side->table->primary_key->columns} ) {
    # be sure to create new columns from the same (sub)class by calling
    # new() on an object
    push(@columns,$_->new($_->name .  $column_name_suffix,$_->type,$_->length,$null,undef));
  }

  $fk_side->table->add_columns(\@columns);
  $fk_side->table->foreign_key(DbFramework::ForeignKey->new($pk_side->table,\@columns));
}

1;
