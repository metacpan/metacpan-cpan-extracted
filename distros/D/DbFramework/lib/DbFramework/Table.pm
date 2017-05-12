=head1 NAME

DbFramework::Table - Table class

=head1 SYNOPSIS

  use DbFramework::Table;

  $t    = new DbFramework::Table new($name,\@attributes,$pk,$dbh,$dm);
  $t->init_db_metadata($catalog);
  $dbh  = $t->dbh($dbh);
  $pk   = $t->is_identified_by($pk);
  @fks  = @{$t->has_foreign_keys_l};
  %fks  = %{$t->has_foreign_keys_h};
  @keys = @{$t->is_accessed_using_l};
  @a    = $t->get_attributes(@names);
  @n    = $t->attribute_names;
  $html = $t->as_html_form;
  $s    = $t->as_string;
  $sql  = $t->as_sql;
  $rows = $t->delete($conditions);
  $pk   = $t->insert(\%values);
  $rows = $t->update(\%values,$conditions);
  @lol  = $t->select(\@columns,$conditions,$order);
  @loh  = $t->select_loh(\@columns,$conditions,$order);
  @a    = $t->non_key_attributes;
  $dm   = $t->belongs_to;
  @fks  = $t->in_foreign_key($attribute);
  do_something if $t->in_key($attribute);
  do_something if $t->in_primary_key($attribute);
  do_something if $t->in_any_key($attribute);

=head1 DESCRIPTION

A B<DbFramework::Table> object represents a database table (entity).

=head1 SUPERCLASSES

B<DbFramework::DefinitionObject>

B<DbFramework::DataModelObject>

=cut

package DbFramework::Table;
use strict;
use vars qw( $NAME @CONTAINS_L $IS_IDENTIFIED_BY $_DEBUG @IS_ACCESSED_USING_L
	     @HAS_FOREIGN_KEYS_L $DBH %TEMPLATE_H @CGI_PK %FORM_H
	     $BELONGS_TO );
use base qw(DbFramework::DefinitionObject DbFramework::DataModelObject);
use DbFramework::PrimaryKey;
use DbFramework::DataType::ANSII;
use DbFramework::DataType::Mysql;
use DbFramework::Attribute;
use DbFramework::Catalog;
use Alias;
use Carp;
use CGI;

# CLASS DATA

my %fields = (
	      # Entity 1:1 IsIdentifiedBy 1:1 PrimaryKey
	      IS_IDENTIFIED_BY    => undef,
	      # Entity 1:1 HasForeignKeys 0:N ForeignKey
	      HAS_FOREIGN_KEYS_L  => undef,
	      HAS_FOREIGN_KEYS_H  => undef,
	      # Table 1:1 IsAccessedUsing 0:N Key
	      IS_ACCESSED_USING_L => undef,
	      # Table 1:1 BelongsTo 1:1 DataModel
	      BELONGS_TO          => undef,
	      DBH                 => undef,
	      TEMPLATE_H          => undef,
	      FORM_H              => undef,
	     );
my $formsdir = '/usr/local/etc/dbframework/forms';

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($name,\@attributes,$pk,$dbh,$dm)

Create a new B<DbFramework::Table> object.  I<$dbh> is a DBI database
handle which refers to a database containing a table named I<$name>.
I<@attribues> is a list of B<DbFramework::Attribute> objects.
I<$primary> is a B<DbFramework::PrimaryKey> object.  I<@attributes>
and I<$primary> can be omitted if you plan to use the
B<init_db_metadata()> object method (see below).  I<$dm> is a
B<DbFramework::DataModel> object to which this table belongs.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new(shift,shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->is_identified_by(shift);
  $self->dbh(shift);
  $self->belongs_to(shift);
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

Foreign keys in a table can be accessed using the
I<HAS_FOREIGN_KEYS_L> and I<HAS_FOREIGN_KEYS_H> attributes.  B<Note>
that foreign key objects will not be created automatically by calling
init_db_metadata() on a table object.  If you want to automatically
create foreign key objects for your tables you should use call
init_db_metadata() on a B<DbFramework::DataModel> object (see
L<DbFramework::Datamodel/init_db_metadata()>).  Other keys (indexes)
defined for a table can be accessed using the I<IS_ACCESSED_USING_L>
attribute.  See L<DbFramework::Util/AUTOLOAD()> for the accessor
methods for these attributes.

=head2 is_identified_by($primary)

I<$primary> is a B<DbFramework::PrimaryKey> object.  If supplied sets
the table's primary key to I<$primary>.  Returns a
B<DbFramework::PrimaryKey> object with is the table's primary key.

=head2 dbh($dbh)

I<$dbh> is a DBI database handle.  If supplied sets the database
handle associated with the table.  Returns the database handle
associated with the table.

=head2 belongs_to($dm)

I<$dm> is a B<DbFramework::DataModel> object.  If supplied sets the
data model to which the table belongs.  Returns the data model to
which the table belongs.

=head2 get_attributes(@names)

Returns a list of B<DbFramework::Attribute> objects.  I<@names> is a
list of attribute names to return.  If I<@names> is undefined all
attributes associated with the table are returned.

=cut

sub get_attributes {
  my $self = attr shift;
  print STDERR "getting attributes for (",join(',',@_),")\n" if $_DEBUG;
  return @_ ? $self->contains_h_byname(@_) # specific attributes
            : @{$self->contains_l};	   # all attributes
}

##-----------------------------------------------------------------------------

=head2 attribute_names()

Returns a list of attribute names for the table.

=cut

sub attribute_names {
  my $self = attr shift;
  my @names;
  for ( @CONTAINS_L ) { push(@names,$_->name) }
  @names;
}

#------------------------------------------------------------------------------

=head2 as_html_form()

Returns HTML form fields for all attributes in the table.

=cut

sub as_html_form {
  my $self = attr shift;
  my $form;
  for ( @CONTAINS_L ) { $form .= "<tr><td>" . $_->as_html_form_field . "</td></tr>\n" }
  $form;
}

#------------------------------------------------------------------------------

=head2 in_foreign_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns a list
of B<DbFramework::ForeignKey> objects which contain I<$attribute>.


=cut

sub in_foreign_key {
  my($self,$attribute) = (attr shift,shift);
  my $name = $attribute->name;
  my @in = ();
  print STDERR "foreign keys: @HAS_FOREIGN_KEYS_L\n" if $_DEBUG;
  for ( @HAS_FOREIGN_KEYS_L ) {
    my @fk_names = $_->attribute_names;
    push @in,$_ if grep(/^$name$/,@fk_names);
  }
  return @in;
}

#------------------------------------------------------------------------------

=head2 in_primary_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns true if
I<$attribute> is a part of the primary key in the table.

=cut

sub in_primary_key {
  my($self,$attribute) = (attr shift,shift);
  my $name     = $attribute->name;
  my @pk_names = $self->is_identified_by->attribute_names;
  print STDERR "Looking for $name in @pk_names\n" if $_DEBUG;
  return grep(/^$name$/,@pk_names) ? 1 : 0;
}

#------------------------------------------------------------------------------

=head2 in_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns true if
I<$attribute> is a part of a key (index) in the table.

=cut

sub in_key {
  my($self,$attribute) = (attr shift,shift);
  my @k_names = ();
  my $name    = $attribute->name;
  for ( @IS_ACCESSED_USING_L ) { push(@k_names,$_->attribute_names) }
  print STDERR "Looking for $name in @k_names\n" if $_DEBUG;
  return grep(/^$name$/,@k_names) ? 1 : 0;
}

#------------------------------------------------------------------------------

=head2 in_any_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns true if
I<$attribute> is a part of a key (index), a primary key or a foreign
key in the table.

=cut

sub in_any_key {
  my($self,$attribute) = (attr shift,shift);
  print STDERR "$self->in_any_key($attribute)\n" if $_DEBUG;
  return ($self->in_key($attribute)         ||
	  $self->in_primary_key($attribute) ||
	  $self->in_foreign_key($attribute)) ? 1 : 0;
}

#------------------------------------------------------------------------------

=head2 non_key_attributes()

Returns a list of B<DbFramework::Attribute> objects which are not
members of any key, primary key or foreign key.

=cut

sub non_key_attributes {
  my $self = attr shift;
  my @non_key;
  for ( @CONTAINS_L ) { push(@non_key,$_) unless $self->in_any_key($_) }
  @non_key;
}

#------------------------------------------------------------------------------

#=head2 html_hidden_pk_list()

#Returns a 'hidden' HTML form field whose key consists of the primary
#key column names separated by '+' characters and whose value is the
#current list of @CGI_PK

#=cut

#sub html_hidden_pk_list {
#  my $self   = attr shift;
#  my $cgi    = new CGI('');
#  return $cgi->hidden(join('+',@{$PRIMARY->column_names}),@CGI_PK) . "\n";
#}

#------------------------------------------------------------------------------

=head2 as_string()

Returns table details as a string.

=cut

sub as_string {
  my $self = attr shift;
  my $s    = "Table: $NAME\n";
  for ( @{$self->contains_l} ) { $s .= $_->as_string }
  return $s;
}

##-----------------------------------------------------------------------------

=head2 init_db_metadata($catalog)

Returns an initialised B<DbFramework::Table> object for the table
matching this object's name() in the database referenced by dbh().
I<$catalog> is a B<DbFramework::Catalog> object.

=cut

sub init_db_metadata {
  my $self  = attr shift;
  my $catalog = shift;

  my $driver = $self->belongs_to->driver;
  my($sql,$sth,$rows,$rv);
  # query to get typeinfo
  if ( ! defined($self->belongs_to) || $driver eq 'mSQL' ) {
    $sql   = qq{SELECT * FROM $NAME};
  } else {
    # more efficient query for getting typeinfo but not supported by mSQL
    $sql   = qq{SELECT * FROM $NAME WHERE 1 = 0};
  }
  $sth = DbFramework::Util::do_sql($DBH,$sql);
  
  my %datatypes = ( mysql => 'Mysql' ); # driver-specific datatype classes
  my @columns;
  for ( my $i = 0; $i < $sth->{NUM_OF_FIELDS}; $i++ ) {
    my $class = ( defined($self->belongs_to) && 
		  exists($datatypes{$driver}) 
		)
      ? $datatypes{$driver}
      : 'ANSII';
    my $name = $sth->{NAME}->[$i];
  # if driver-specific class exists, get the driver-specific type
    my($type,$ansii_type,$default,$extra);
  SWITCH: for ( $class ) {
    /Mysql/ && do {
      print STDERR "mysql_type = ",join(',',@{$sth->{mysql_type}}),"\n"
	if $_DEBUG;
      $type = $sth->{mysql_type}->[$i];
      $ansii_type = $sth->{TYPE}->[$i];
      my $sth = DbFramework::Util::do_sql($DBH,"DESCRIBE $NAME $name");
      my $metadata = $sth->fetchrow_hashref;
      ($default,$extra) = ($metadata->{Default},uc($metadata->{Extra}));
      $sth->finish;
      last SWITCH;
    };
    /ANSII/ && do {
      $ansii_type = $type = $sth->{TYPE}->[$i];
      last SWITCH;
    };
  }
    $class = "DbFramework::DataType::$class";
    my $precision = $sth->{PRECISION}->[$i];

    my $d = $class->new($self->belongs_to,
			$type,
			$ansii_type,
			$precision,
			$extra,
		       );
    my $a = new DbFramework::Attribute($sth->{NAME}->[$i],
                                       $default,
                                       $sth->{NULLABLE}->[$i],
                                       $d
                                      );
    push(@columns,$a);
  }
  $self->_init(\@columns);

  ## add keys
  $catalog->set_primary_key($self);
  $catalog->set_keys($self);

  #$self->_templates;  # set default templates

  return $self;
}

#------------------------------------------------------------------------------

=head2 as_sql()

Returns a string which can be used to create a table in an SQL 'CREATE
TABLE' statement.

=cut

sub as_sql {
  my $self = attr shift;
  my $sql = "CREATE TABLE $NAME (\n";
  for ( @{$self->contains_l} ) { $sql .= "\t" . $_->as_sql($DBH) . ",\n"; }
  $sql .= "\t" . $IS_IDENTIFIED_BY->as_sql;
  for ( @IS_ACCESSED_USING_L ) { $sql .= ",\n\t" . $_->as_sql }
  for ( @HAS_FOREIGN_KEYS_L )  { $sql .= ",\n\t" . $_->as_sql }
  return "$sql\n)";
}

#------------------------------------------------------------------------------

#=head2 validate_foreign_keys()

#Ensure that foreign key definitions match related primary key
#definitions.

#=cut

sub validate_foreign_keys {
  my $self = shift;
  attr $self;

  for my $fk ( @HAS_FOREIGN_KEYS_L ) {
    my $fk_name       = $fk->name;
    my @fk_attributes = @{$fk->incorporates_l};
    my @pk_attributes = @{$fk->references->incorporates_l};
    @fk_attributes == @pk_attributes ||
      die "Number of attributes in foreign key $NAME:$fk_name(",scalar(@fk_attributes),") doesn't match that of related primary key (",scalar(@pk_attributes),")";
    for ( my $i = 0; $i <= $#fk_attributes; $i++) {
      my($fk_aname,$pk_aname) =
        ($fk_attributes[$i]->name,$pk_attributes[$i]->name);
      print STDERR "$fk_aname eq $pk_aname\n" if $_DEBUG;
      #$fk_aname eq $pk_aname ||
      #  die "foreign key component $NAME:$fk_aname ne primary key component $pk_aname\n";
    }
  }
}

#------------------------------------------------------------------------------

=head2 delete($conditions)

DELETE rows FROM the table associated with this object WHERE the
conditions in I<$conditions> are met.  Returns the number of rows
deleted if supplied by the DBI driver.

=cut

sub delete {
  my($self,$conditions) = (attr shift,shift);

  my $sql  = "DELETE FROM $NAME";
     $sql .= " WHERE $conditions" if $conditions;
  print STDERR "$sql\n" if $_DEBUG;
  return $DBH->do($sql) || die($DBH->errstr);
}
#------------------------------------------------------------------------------

=head2 insert(\%values)

INSERT INTO the table columns corresponding to the keys of I<%values>
the VALUES corresponding to the values of I<%values>.  Returns the
primary key of the inserted row if it is a Mysql 'AUTO_INCREMENT'
column or -1.

=cut

sub insert {
  my $self   = attr shift;
  my %values = %{$_[0]};

  my(@columns,$values);
  for ( keys(%values) ) {
    next unless defined($values{$_});
    push(@columns,$_);
    my $type = $self->get_attributes($_)->references->ansii_type;
    print STDERR "value = $values{$_}, type = $type\n" if $_DEBUG;
    $values .= $self->_quote($values{$_},$type) . ',';
  }
  chop $values;
  my $columns = '(' . join(',',@columns). ')';

  my $sql = "INSERT INTO $NAME $columns VALUES ($values)";
  print STDERR "$sql\n" if $_DEBUG;

  my $sth = $DBH->prepare($sql) || die $DBH->errstr;
  my $rv  = $sth->execute       || die "$sql\n" . $sth->errstr . "\n";
  my $rc  = $sth->finish;

  if ( $self->belongs_to->driver eq 'mysql' ) {
    # id of auto_increment field
    return $sth->{mysql_insertid};
  } else {
    return -1;
  }
}
#------------------------------------------------------------------------------

=head2 update(\%values,$conditions)

UPDATE the table SETting the columns matching the keys in %values to
the values in %values WHERE I<$conditions> are met.  Returns the
number of rows updated if supplied by the DBI driver.

=cut

sub update {
  my $self = attr shift;
  my %values     = %{$_[0]};
  my $conditions = $_[1];

  my $values;
  for ( keys %values ) {
    next unless $values{$_};
    my $dt   = $self->get_attributes($_)->references;
    my $type = $dt->ansii_type;
    print STDERR "\$type = ",$dt->name,"($type)\n" if $_DEBUG;
    $values .= "$_ = " . $self->_quote($values{$_},$type) . ',';
  }
  chop $values;
  
  my $sql  = "UPDATE $NAME SET $values";
     $sql .= " WHERE $conditions" if $conditions;
  print STDERR "$sql\n" if $_DEBUG;
  return $DBH->do($sql) || die($DBH->errstr);
}

#------------------------------------------------------------------------------

=head2 select(\@columns,$conditions,$order)

Returns a list of lists of values by SELECTing values FROM I<@columns>
WHERE rows meet I<$conditions> ORDERed BY the list of columns in
I<$order>.  Strings in I<@columns> can refer to functions supported by
the database in a SELECT clause e.g.

C<@columns = q/sin(foo),cos(bar),tan(baz)/;>

=cut

sub select {
  my $self = attr shift;
  my $sth  = $self->_do_select(@_);
  my @things;
  # WARNING!
  # Can't use fetchrow_arrayref here as it returns the *same* ref (man DBI)
  while ( my @attributes = $sth->fetchrow_array ) {
    print "@attributes\n" if $_DEBUG;
    push(@things,\@attributes);
  }
  if ( $_DEBUG ) {
    print "@things\n";
    for ( @things ) { print "@{$_}\n" }
  }
  return @things;
}

#------------------------------------------------------------------------------

=head2 select_loh(\@columns,$conditions,$order)

Returns a list of hashrefs containing B<(column_name,value)> pairs by
SELECTing values FROM I<@columns> WHERE rows meet I<$conditions>
ORDERed BY the list of columns in I<$order>.  Strings in I<@columns>
can refer to functions supported by the database in a SELECT clause
e.g.

C<@columns = q/sin(foo),cos(bar),tan(baz)/;>

The keys in the hashrefs will match the name of the function applied
to the column i.e.

C<@loh = $foo-E<gt>select(\@columns);>

C<print "sin(foo) = $loh[0]-E<gt>{sin(foo)}\n";>

=cut

sub select_loh {
  my $self = attr shift;
  my $sth  = $self->_do_select(@_);
  my @things;
  while ( $_ = $sth->fetchrow_hashref ) {
    # fetchrow_hashref may not return a fresh hashref in future (man DBI)
    my %hash = %{$_};
    push(@things,\%hash);
  }
  return @things;
}

#------------------------------------------------------------------------------

# select(\@columns,$conditions,$order)
# returns a statement handle for a SELECT

sub _do_select {
  my $self = attr shift;
  my($columns_ref,$conditions,$order,$function_ref) = @_;
  my @columns = defined($columns_ref) ? @$columns_ref : $self->attribute_names;
  my $sql        = "SELECT " . join(',',@columns) . " FROM $NAME";
     $sql       .= " WHERE $conditions" if $conditions;
     $sql       .= " ORDER BY $order"   if $order;
  print STDERR "$sql\n" if $_DEBUG;
  my $sth = $DBH->prepare($sql) || die($DBH->errstr);
  my $rv  = $sth->execute       || die "$sql\n" . $sth->errstr . "\n";
  return $sth;
}

#------------------------------------------------------------------------------

#=head2 fill_template($name,\%values)

#Return the filled HTML template named I<$name>.  A template can
#contain special placeholders representing columns in a database table.
#Placeholders in I<$template> can take the following forms:

#=over 4

#=item B<E<lt>DbField table.column [value=value] [type=type]E<gt>>

#If the table's name() matches I<table> in a B<DbField> placeholder,
#the placeholder will be replaced with the corresponding HTML form
#field for the column named I<column> with arguments I<value> and
#I<type> (see L<DbFramework::Attribute/html_form_field()>).  If
#I<%values> is supplied placeholders will have the values in I<%values>
#added where a key in I<%values> matches a column name in the table.

#=item B<E<lt>DbFKey table.fk_name[,column...]E<gt>>

#If the table's name() matches I<table> in a B<DbFKey> placeholder, the
#placeholder will be replaced with the a selection box containing
#values and labels from the primary key columns in the related table.
#Primary key attribute values in I<%values> will be used to select the
#default item in the selection box.

#=item B<E<lt>DbValue table.column[,column...]E<gt>>

#If the table's name() matches I<table> in a B<DbValue> placeholder,
#the placeholder will be replaced with the values in I<%values> where a
#key in I<%values> matches a column name in the table.

#=item B<E<lt>DbJoin table.column.template[.order][.column_name[;column_name...]]E<gt>>

#A B<DbJoin> placeholder will cause a join to be performed between this
#table and the table specified in I<table> over the column I<column>
#where the value equals I<%values{column}> orderd by I<order>.  Values
#will be selected from columns specified with I<column_name>.
#I<column_name> may refer to functions supported by the database in a
#B<SELECT> clause.  If no I<column_name>s are specified, the values
#from all columns from I<table> will be selected.  The placeholder will
#be replaced by the concatenation of I<template> filled with the values
#from each row returned by the join.  B<DbJoin> placeholders may be
#chained.

#=back

#The easiest way to pass the values required to fill a template is by
#calling fill_template() with the name of the template and the hashrefs
#returned by select_loh() e.g.

#  for ( $foo->select_loh(\@columns) ) {
#    $html .= $foo->fill_template($template,$_)
#  }

#=cut

sub fill_template {
  my($self,$name,$values) = (attr shift,shift,shift);
  print STDERR "filling template '$name' for table '$NAME'\n" if $_DEBUG;
  return '' unless exists $TEMPLATE_H{$name};

  my $template = $TEMPLATE_H{$name};
#  if ( $_DEBUG ) {
#    print STDERR "\$template = $template\n";
#    print STDERR "\$values = ", defined($values) ? %$values : 'undef',"\n" ;
#  }
#  my $error;
#  my $rc = Parse::ePerl::Expand({
#			  Script => $template,
#			  Result => \$template,
#			  Error  => \$error,
#			 });
#  die "Error parsing ePerl in template $name: $error" unless $rc;
#  if ( $_DEBUG ) {
#    print STDERR "\$rc = $rc\n";
#    print STDERR "\$template = ",defined($template) ? $template : 'undef',"\n";
#  }

  my %fk = %{$self->has_foreign_keys_h};

  # insert values into template
  if ( defined($values) ) {
    # only works for single column foreign keys
    $template =~ s/<DbJoin\s+(\w+)\.(\w+)\.(\w+)(\.(\w*))?(\.(.*))?\s*>/$self->_join_fill_template($1,$2,$3,$5,$values->{$2},$7)/eg;

    $template =~ s/(<DbField\s+$NAME\.)(\w+)(\s+value=)(.*?\s*)>/$1$2 value=$values->{$2}>/g;
    $template =~ s/(<DbField $NAME\.)(\w+)>/$1$2 value=$values->{$2}>/g;
    # handle multiple attributes here for foreign key values
    $template =~ s/<DbValue\s+$NAME\.([\w,]+)\s*>/join(',',@{$values}{split(m{,},$1)})/eg;
    # values which are the result of applying functions to a column
    $template =~ s/<DbValue\s+$NAME\.(.+)\s*>/$values->{$1}/g;
  }

  #print STDERR "template = \n$TEMPLATE_H{$name}\n\$values = ",%$values,"\n" if $_DEBUG;

  # foreign key placeholders
  $template =~ s/<DbFKey\s+$NAME\.(\w+)\s*>/$fk{$1}->as_html_form_field($values)/eg;

  # form field placeholders
  $template =~ s/<DbField\s+$NAME\.(\w+)\s+value=(.*?)\s+type=(.*?)>/$self->_as_html_form_field($1,$2,$3)/eg;
  $template =~ s/<DbField\s+$NAME\.(\w+)\s+value=(.*?)>/$self->_as_html_form_field($1,$2)/eg;
  $template =~ s/<DbField $NAME\.(\w+)>/$self->_as_html_form_field($1)/eg;

  $template;
}

#------------------------------------------------------------------------------

sub _as_html_form_field {
  my($self,$attribute) = (shift,shift);
  my @attributes = $self->get_attributes($attribute);
  $attributes[0]->as_html_form_field(@_);
}

#------------------------------------------------------------------------------

#=head2 set_templates(%templates)

#Adds the contents of the files which are the values in I<%templates>
#as templates named by the keys in I<%templates>.  Returns a reference
#to a hash of all templates.

#=cut

sub set_templates {
  my $self = attr shift;
  if ( @_ ) {
    my %templates = @_;
    my @templates;
    for ( keys %templates ) {
      open(T,"<$templates{$_}") || die "Couldn't open template $templates{$_}";
      my @t = <T>;
      close T;
      push(@templates,$_,"@t");
    }
    $self->template_h(\@templates);
  }
  \%TEMPLATE_H;
}

#------------------------------------------------------------------------------

sub _templates {
  my $self = attr shift;
  $self->_template('input','_input_template');
  $self->_template('output','_output_template');
}

#------------------------------------------------------------------------------

sub _template {
  my($self,$method) = (attr shift,shift);
  my @fk_attributes;
  for ( @HAS_FOREIGN_KEYS_L ) { push(@fk_attributes,$_->attribute_names) }
  my $t = $IS_IDENTIFIED_BY->$method(@fk_attributes) || '';
  for ( $self->non_key_attributes ) { $t .= $_->$method($NAME) }
  for ( @IS_ACCESSED_USING_L )      { $t .= $_->$method() }
  for ( @HAS_FOREIGN_KEYS_L )       { $t .= $_->$method() }
  $t;
}

#------------------------------------------------------------------------------

#=head2 read_form($name,$path)

#Assigns the contents of a file to a template.  I<$name> is the name of
#the template and I<$path> is the path to the file.  If I<$path> is
#undefined, tries to read
#F</usr/local/etc/dbframework/$db/$table/$name.form>, where I<$db> is
#the name of the database containing the table and I<$table> is the
#name of the table.  See L<Forms and Templates>.

#=cut

sub read_form {
  my $self = attr shift;
  my $name = shift;
  my $db = $self->belongs_to ? $self->belongs_to->db : 'UNKNOWN_DB';
  my $path = shift || "$formsdir/$db/$NAME/$name.form";
  $TEMPLATE_H{$name} = _readfile_no_comments($path,"Couldn't open form");
}

#------------------------------------------------------------------------------

sub _readfile_no_comments {
  my($file,$error) = @_;
  open FH,"<$file" or die "$error: $file: $!";
  my $lines;
  while (<FH>) {
    next if /^\s*#/;
    $lines .= $_;
  }
  close FH;
  $lines;
}

#------------------------------------------------------------------------------

=head2 as_html_heading()

Returns a string for use as a table heading row in an HTML table.

=cut

sub as_html_heading {
  my $self = attr shift;
  my $method = 'as_html_heading';
  my @fk_attributes;
  for ( @HAS_FOREIGN_KEYS_L ) { push(@fk_attributes,$_->attribute_names) }
  my $html = $IS_IDENTIFIED_BY->$method(@fk_attributes);
  for ( $self->non_key_attributes ) { $html .= $_->$method() }
  my @key_attributes = (@fk_attributes, $IS_IDENTIFIED_BY->attribute_names);
  my(%key_attributes,$bgcolor);
  for my $key ( @IS_ACCESSED_USING_L ) {
    # get unique hash of key attributes
    for ( @{$key->incorporates_l} ) {
      my $name = $_->name;
      $key_attributes{$_->name} = $_ unless grep(/^$name$/,@key_attributes);
    }
    $bgcolor = $key->bgcolor;
  }
  for ( values(%key_attributes) )   { $html .= $_->$method($bgcolor) }
  for ( @HAS_FOREIGN_KEYS_L )       { $html .= $_->$method() }
  "<TR>$html</TR>";
}

#------------------------------------------------------------------------------

# Returns an HTML string by filling I<$template> in I<table> with the
# values SELECTed WHERE the values in the I<$column_name> match $value.

sub _join_fill_template {
  my $self = attr shift;
  my($table_name,$column_name,$template,$order,$value,$columns) = @_;
  print STDERR "\@_ = @_\n\$columns = $columns\n" if $_DEBUG;
  my($table) = $BELONGS_TO->collects_table_h_byname($table_name)
    or die("Can't find table $table_name in data model ".$BELONGS_TO->name);
  my @columns = $columns ? split(';',$columns) : $table->attribute_names;
  my $html;
  $table->read_form($template);
  for my $hashref ( $table->select_loh(\@columns,"$column_name = $value",$order) ) {
    print STDERR "\$template = $template, \$hashref = ",%$hashref,"\n" if $_DEBUG;
    $html .= $table->fill_template($template,$hashref);
  }
  $html;
}

#------------------------------------------------------------------------------

# workaround for lack of quoting in dates
# Jochen says it will be fixed in later releases of DBD::mysql
sub _quote {
  my($self,$value,$type) = @_;
  $type = 12 if $type == 9;
  return $self->dbh->quote($value,$type);
}

=head1 SEE ALSO

L<DbFramework::DefinitionObject>, L<DbFramework::Attribute>,
L<DbFramework::DataModelObject> and L<DbFramework::DataModel>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998,1999 Paul Sharpe. England.  All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
