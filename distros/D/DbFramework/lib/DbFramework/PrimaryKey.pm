=head1 NAME

DbFramework::PrimaryKey - Primary key class

=head1 SYNOPSIS

  use DbFramework::PrimaryKey;
  $pk   = new DbFramework::Primary(\@attributes,$table,\@labels);
  $sql  = $pk->as_sql;
  $html = $pk->html_select_field(\@column_names,$multiple,\@default);
  $html = $pk->as_html_heading;
  $html = $pk->as_hidden_html(\%values);
  $qw   = $pk->as_query_string(\%values);

=head1 DESCRIPTION

The B<DbFramework::PrimaryKey> class implements primary keys for a
table.

=head1 SUPERCLASSES

B<DbFramework::Key>

=cut

package DbFramework::PrimaryKey;
use strict;
use base qw(DbFramework::Key);
use Alias;
use vars qw( $NAME $BELONGS_TO @INCORPORATES_L $BGCOLOR $_DEBUG );
use CGI;
use URI::Escape;

# CLASS DATA

my %fields = (
              # PrimaryKey 0:N Incorporates 0:N ForeignKey
              INCORPORATES => undef,
	      LABELS_L     => undef,
);

#-----------------------------------------------------------------------------
## CLASS METHODS
#-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new(\@attributes,$table,\@labels)

Create a new B<DbFramework::PrimaryKey> object.  I<@attributes> is a
list of B<DbFramework::Attribute> objects from a single
B<DbFramework::Table> object which make up the key.  I<$table> is the
B<DbFramework::Table> to which the primary key belongs.  I<@labels> is
a list of column names which should be used as labels when calling
html_select_field().  I<@labels> will default to all columns in
I<$table>.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new('PRIMARY',shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  my $table = shift;
  $self->belongs_to($table);

  my(@bad,@labels);
  if ( defined($_[0]) ) {
    my @columns = $table->attribute_names;
    @labels  = @{$_[0]};
    for my $label ( @labels ) {
      push(@bad,$label) unless grep(/^$label$/,@columns);
    }
    die "label column(s) '@bad' do not exist in '",$table->name,"'" if @bad;
  } else {
    @labels = $table->attribute_names;
  }
  $self->labels_l(\@labels);
  $self->bgcolor('#00ff00');
  return $self;
}

#-----------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 as_sql()

Returns a string which can be used in an SQL 'CREATE TABLE' statement
to create the primary key.

=cut

sub as_sql {
  my $self = attr shift;
  return "PRIMARY KEY (" . join(',',$self->attribute_names) . ")";
}

##----------------------------------------------------------------------------

=head2 html_select_field(\@column_names,$multiple,\@default,$name)

Returns an HTML form select field where the value consists of the
values from the columns which make up the primary key and the labels
consist of the corresponding values from I<@column_names>.  If
I<@column_names> is undefined the labels consist of the values from
all column names.  If I<$multiple> is defined the field will allow
multiple selections.  I<@default> is a list of values in the select
field which should be selected by default.  For fields which allow
only a single selection the first value in I<@default> will be used as
the default.  If I<$name> is defined it will be used as the name of
the select field, otherwise the name will consist of the attribute
names of the primary key joined by ',' (comma) and the values will
consist of the corresponding attribute values joined by ',' (comma).

=cut

sub html_select_field {
  my $self = attr shift;

  my @labels     = $_[0] || @{$self->labels_l};
  my $multiple   = $_[1];
  # this is hard-coded for single-attribute primary keys
  my $default    = $multiple ? $_[2] : $_[2]->[0];
  my $name       = $_[3];
  my @pk_columns = $self->attribute_names;
  my $pk         = join(',',@pk_columns);
  my @columns    = (@pk_columns,@labels);

  # build SELECT statement
  my(%tables,%where);
  my $table_name = $self->BELONGS_TO->name;
  @{$tables{$table_name}} = @pk_columns;
  my $order = 'ORDER BY ';
  for my $label ( @labels ) {
    my($table_name,@labels);
    my($attribute) = $BELONGS_TO->get_attributes($label);
    # handle foreign keys with > 1 attribute here!
    if ( my($fk) = $BELONGS_TO->in_foreign_key($attribute) ) {
      # get label columns from related table
      $table_name = $fk->references->belongs_to->name;
      @labels     = @{$fk->references->labels_l};
      $where{$table_name} = $fk->sql_where;
    } else {
      $table_name = $BELONGS_TO->name;
      @labels     = ($label);
    }
    push @{$tables{$table_name}},@labels;
    for ( @labels ) { $order .= "$table_name.$_," }
  }
  chop $order;

  my $from  = 'FROM ' . join(',',keys(%tables));
  my $select = 'SELECT ';
  # do this table first so that pk columns are returned at the front
  for ( @{$tables{$table_name}} ) { $select .= "$table_name.$_," }
  delete $tables{$table_name};
  while ( my($table,$col_ref) = each %tables ) {
    for ( @$col_ref ) { $select .= "$table.$_," }
  }
  chop $select;
  my @where = values(%where);
  my $where = @where ? 'WHERE ' : '';
  for ( my $i = 0; $i <= $#where; $i++ ) {
    $where .= ' AND ' if $i;
    $where .= $where[$i];
  }
  my $sql = "$select\n$from\n$where\n$order\n";
  print STDERR $sql if $_DEBUG;
  my $sth = DbFramework::Util::do_sql($BELONGS_TO->dbh,$sql);

  # prepare arguments for CGI methods
  my (@pk_values,%labels,@row);
  my $i = 0;
  $pk_values[$i++] = ''; $labels{''} = '** Any Value **';
  $pk_values[$i++] = 'NULL'; $labels{'NULL'} = 'NULL';
  while ( my $row_ref = $sth->fetchrow_arrayref ) {
    @row = @{$row_ref};
    my $pk = join(',',@row[0..$#pk_columns]); # pk fields
    $pk_values[$i++] = $pk;

    # label fields
    for ( @row[$#pk_columns+1..$#row] ) {
      $labels{$pk} .= ' ' if defined($labels{$pk});
      $labels{$pk} .= defined($_) ? $_ : 'NULL';
    }
  }

  $name = $pk unless $name;

  my $html;
  my $cgi = new CGI('');  # we just want this object for its methods
  if ( $multiple ) {
    $html = $cgi->scrolling_list(-name=>$name,
				 -values=>\@pk_values,
				 -labels=>\%labels,
				 -multiple=>'true',
				 -default=>$default,
				);
  } else {
    $html = $cgi->popup_menu(-name=>$name,
			     -values=>\@pk_values,
			     -labels=>\%labels,
			     -default=>$default,
			    );
  }

  return $html;
}

#-----------------------------------------------------------------------------

sub _input_template {
  my($self,@fk_attributes) = @_;
  attr $self;
  print STDERR "$self: _input_template(@fk_attributes)\n" if $_DEBUG;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  my $in;
  for my $attribute ( @INCORPORATES_L ) {
    my $a_name = $attribute->name;
    unless ( grep(/^$a_name$/,@fk_attributes) ) { # part of foreign key
      print STDERR "Adding $a_name to input template for pk in $t_name\n" if $_DEBUG;
      $in .= qq{<TD><DbField ${t_name}.${a_name}></TD>
};
    }
  }
  $in;
}

#-----------------------------------------------------------------------------

sub _output_template {
  my($self,@fk_attributes) = @_;
  attr $self;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  my $out;
  for ( @INCORPORATES_L ) {
    my $a_name = $_->name;
    unless ( grep(/^$a_name$/,@fk_attributes) ) { # part of foreign key
      $out .= qq{<TD BGCOLOR='$BGCOLOR'><DbValue ${t_name}.${a_name}></TD>};
    }
  }
  $out;
}

#-----------------------------------------------------------------------------

=head2 as_html_heading()

Returns a string for use as a column heading cell in an HTML table;

=cut

sub as_html_heading {
  my $self = attr shift;
  my @fk_attributes = @_;
  my @attributes;
  for ( @INCORPORATES_L ) {
    my $a_name = $_->name;
    push(@attributes,$_)
      unless grep(/^$a_name$/,@fk_attributes); # part of foreign key
  }
  return '' unless @attributes;
  my $html = "<TD BGCOLOR='$BGCOLOR' COLSPAN=".scalar(@attributes).">";
  for ( @attributes ) {
    my $a_name = $_->name;
    my $extra  = $_->references->extra
      ? ' ('.$_->references->extra.')'
      : '';
    $html .= "$a_name$extra,";
  }
  chop($html);
  "$html</TD>";
}

#-----------------------------------------------------------------------------

=head2 as_query_string(\%values)

Returns a CGI query string consisting of attribute names from the
primary key and their corresponding values from I<%values>.

=cut

sub as_query_string {
  my $self = attr shift;
  my %values = $_[0] ? %{$_[0]} : ();
  my $qs;
  for ( $self->attribute_names ) {
    my $value = $values{$_} ? $values{$_} : '';
    $qs .= "$_=$value&";
  }
  chop($qs);
  uri_escape($qs);
}

#-----------------------------------------------------------------------------

=head2 as_hidden_html(\%values)

Returns hidden HTML form fields for each primary key attribute.  The
field name is B<pk_$attribute_name>.  The field value is the value in
I<%values> whose key is I<$attribute_name>.  This method is useful for
tracking the previous value of a primary key when you need to update a
primary key.

=cut

sub as_hidden_html {
  my $self       = attr shift;
  my %values     = $_[0] ? %{$_[0]} : ();
  my $table_name = $self->BELONGS_TO->name;
  my $html;
  for ( $self->attribute_names ) {
    my $value = defined($values{$_}) ? $values{$_} : '';
    $html    .= qq{<input type="hidden" name="pk_$_" value="$value">\n};
  }
  $html;
}

1;

=head1 SEE ALSO

L<DbFramework::Key>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998,1999 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
