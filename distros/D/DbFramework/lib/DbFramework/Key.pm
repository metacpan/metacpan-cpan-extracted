=head1 NAME

DbFramework::Key - Key class

=head1 SYNOPSIS

  use DbFramework::Key;
  $k     = new DbFramework::Key($name,\@attributes);
  $name  = $k->name($name);
  @a     = @{$k->incorporates_l(\@attributes)};
  @names = $k->attribute_names;
  $sql   = $k->as_sql;
  $table = $k->belongs_to($table);
  $html  = $k->as_html_heading;

=head1 DESCRIPTION

The B<DbFramework::Key> class implements keys (indexes) for a table.

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::Key;
use strict;
use base qw(DbFramework::Util);
use Alias;
use vars qw( $NAME @INCORPORATES_L $BELONGS_TO $BGCOLOR );

my %fields = (
	      NAME           => undef,
	      # Key 0:N Incorporates 0:N Attribute
	      INCORPORATES_L => undef,
	      # Key 1:1 BelongsTo 1:1 Table
	      BELONGS_TO     => undef,
	      BGCOLOR        => '#ffffff',
	     );

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($name,\@attributes)

Create a new B<DbFramework::Key> object.  I<$name> is the name of the
key. I<@attributes> is a list of B<DbFramework::Attribute> objects
from a single B<DbFramework::Table> object which make up the key.

=cut

sub new {
  my $DEBUG = 0;
  my $proto = shift;
  my $class = ref($proto) || $proto;
  print STDERR "=>$class::new(@_)\n" if $DEBUG;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->incorporates_l(shift);
  print STDERR "<=$class::new()\n" if $DEBUG;
  return $self;
}

##----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

A key incorporates 0 or more attributes.  These attributes can be
accessed using the attribute I<INCORPORATES_L>.  See
L<DbFramework::Util/AUTOLOAD()> for the accessor methods for this
attribute.

=head2 name($name)

If I<$name> is supplied sets the data model name.  Returns the data
model name.

=head2 belongs_to($table)

I<$table> is a B<DbFramework::Table> object.  If supplied sets the
table to which this key refers to I<$table>.  Returns a
B<DbFramework::Table>.

=head2 bgcolor($bgcolor)

If I<$color> is supplied sets the background colour for HTML table
cells.  Returns the current background colour.

=head2 attribute_names()

Returns a list of the names of the attributes which make up the key.

=cut

sub attribute_names {
  my $self = attr shift;
  my @names;
  for ( @INCORPORATES_L ) { push(@names,$_->name) }
  return @names;
}

#-----------------------------------------------------------------------------

=head2 as_sql()

Returns a string which can be used in an SQL 'CREATE TABLE' statement
to create the key.

=cut

sub as_sql {
  my $self = attr shift;
  return "KEY $NAME (" . join(',',$self->attribute_names) . ")";
}

#-----------------------------------------------------------------------------

sub _input_template {
  my $self   = attr shift;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  my $in;
  my $bgcolor = $self->bgcolor;
  for ( @INCORPORATES_L ) {
    my $a_name = $_->name;
    $in .= qq{<TD><DbField ${t_name}.${a_name}></TD>};
  }
  $in;
}

#-----------------------------------------------------------------------------

sub _output_template {
  my $self   = attr shift;
  my $t_name = $BELONGS_TO ? $BELONGS_TO->name : 'UNKNOWN_TABLE';
  my $out;
  for ( @INCORPORATES_L ) {
    my $a_name = $_->name;
    $out .= qq{<TD BGCOLOR='$BGCOLOR'><DbValue ${t_name}.${a_name}></TD>};
  }
  $out;
}

#-----------------------------------------------------------------------------

=head2 as_html_heading()

Returns a string for use as a column heading cell in an HTML table;

=cut

sub as_html_heading {
  my $self = attr shift;
  my $html = "<TD BGCOLOR='$BGCOLOR' COLSPAN=".scalar(@INCORPORATES_L).">";
  for ( @INCORPORATES_L ) { $html .= $_->name . ',' }
  chop($html);
  "$html</TD>";
}

1;

=head1 SEE ALSO

L<DbFramework::ForeignKey>, L<DbFramework::PrimaryKey> and
L<DbFramework::Catalog>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
