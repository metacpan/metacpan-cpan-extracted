=head1 NAME

DbFramework::ForeignKey - Foreign Key class

=head1 SYNOPSIS

  use DbFramework::ForeignKey;
  $fk   = new DbFramework::ForeignKey($name,\@attributes,$primary);
  $pk   = $fk->references($primary);
  $sql  = $fk->as_sql;
  $html = $fk->as_html_form_field(\%values);
  $s    = $fk->sql_where;

=head1 DESCRIPTION

The B<DbFramework::ForeignKey> class implements foreign keys for a
table.

=head1 SUPERCLASSES

B<DbFramework::Key>

=cut

package DbFramework::ForeignKey;
use strict;
use base qw(DbFramework::Key);
use Alias;
use vars qw( $NAME $BELONGS_TO @INCORPORATES_L $BGCOLOR $_DEBUG );

# CLASS DATA

my %fields = (
	      # ForeignKey 0:N References 1:1 PrimaryKey
	      REFERENCES => undef,
);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($name,\@attributes,$primary)

Returns a new B<DbFramework::ForeignKey> object.

I<$name> is the name of the foreign key.  I<@attributes> is a list of
B<DbFramework::Attribute> objects from a single B<DbFramework::Table>
object which make up the key.  I<$primary> is the
B<DbFramework::Primary> object which the foreign key references.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new(shift,shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->references(shift);
  $self->bgcolor('#777777');
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 references($primary)

I<$primary> should be a B<DbFramework::PrimaryKey> object.  If
supplied it sets the primary key referenced by this foreign key.
Returns the B<DbFramework::PrimaryKey> object referenced by this
foreign key.

=cut

#-----------------------------------------------------------------------------

sub _input_template {
  my $self   = attr shift;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  return qq{<TD><DbFKey ${t_name}.$NAME></TD>};
}

#-----------------------------------------------------------------------------

sub _output_template {
  my $self = attr shift;
  # output template consists of attributes from related pk table
  my $pk_table   = $self->references->belongs_to;
  my $name       = $pk_table->name;
  my $attributes = join(',',$pk_table->attribute_names);
  my $out = qq{<TD BGCOLOR='$BGCOLOR'><DbValue ${name}.$attributes></TD>};
  print STDERR "\$out = $out\n" if $_DEBUG;
  $out;
}

#------------------------------------------------------------------------------

=head2 as_html_form_field(\%values)

Returns an HTML selection box containing values and labels from the
primary key columns in the related table. I<%values> is a hash whose
keys are the attribute names of the foreign key and whose values
indicate the item in the selection box which should be selected by
default.  See L<DbFramework::PrimaryKey/html_select_field()>.

=cut

sub as_html_form_field {
  my $self      = attr shift;
  my %values    = $_[0] ? %{$_[0]} : ();
  my $pk        = $self->references;
  my $name      = join(',',$self->attribute_names);
  # only handles single attribute foreign keys
  my $t_name    = $BELONGS_TO->name;
  my @fk_value;
  $fk_value[0] = $values{"${t_name}.${name}"};
  if ( $_DEBUG ) {
    print STDERR "\$t_name = $t_name, \$name = $name, \@fk_value = @fk_value\n";
    print STDERR "pk table = ",$pk->belongs_to->name,"\n";
  }
  $pk->html_select_field(undef,undef,\@fk_value,$name);
}
#------------------------------------------------------------------------------

=head2 sql_where()

Returns a string containing SQL 'WHERE' condition(s) to join the
foreign key against the primary key of the related table.

=cut

sub sql_where {
  my $self = shift;
  my $fk_table   = $self->belongs_to->name;
  my @fk_columns = $self->attribute_names;
  my $pk_table   = $self->references->belongs_to->name;
  my @pk_columns = $self->references->attribute_names;
  my $where;
  for ( my $i = 0; $i <= $#fk_columns; $i++ ) {
    $where .= ' AND ' if $where;
    $where .= "$fk_table.$fk_columns[$i] = $pk_table.$pk_columns[$i]";
  }
  $where;
}

1;

=head1 SEE ALSO

L<DbFramework::Key>, L<DbFramework::PrimaryKey> and
L<DbFramework::Catalog>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998,1999 Paul Sharpe. England.  All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
