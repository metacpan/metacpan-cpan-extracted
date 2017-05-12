=head1 NAME

DbFramework::Template - Fill template with database values

=head1 SYNOPSIS

  use DbFramework::Template;
  $t = new DbFramework::Template($template,\@tables);
  print $t->fill;
  $t->default($table);
  $t->template->set_text($template);

=head1 DESCRIPTION

B<DbFramework::Template> is a class for filling templates with values
from a database.

=head2 Template placeholders

The following list describes the placeholders allowed in a template.
In each case I<%values> relates to the hash passed to the fill()
method.

=over 4

=item I<(:&db_value(table.column):)>

Replaced with the value from I<%values> whose key is I<table.column>.
See L<DbFramework::Persistent/table_qualified_attribute_hashref()> for
a useful method for generating a hash to fill this type of
placeholder.

=item I<(:&db_html_form_field(table.column[ value=value][ type=type]):)>

Replaced with an HTML form field appropriate for the column I<column>
in the table I<table>.  I<value> is the inital value which will be
applied to the field.  The type of field generated is determined by
the data type of I<column>.  This can be overridden by setting
I<type>.  See L<DbFramework::Attribute/as_html_form_field()> for more
details.

=item I<(:&db_fk_html_form_field(table.fk):)>

Replaced with an HTML form field appropriate for the foreign key I<fk>
in the table I<table>.  See
L<DbFramework::ForeignKey/as_html_form_field()> for more details.

=back

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::Template;
use strict;
use base 'DbFramework::Util';
use Text::FillIn;
use Alias;
use vars qw($_DEBUG $TEMPLATE %TABLE_H %VALUES);

# set delimiters
Text::FillIn->Ldelim('(:');
Text::FillIn->Rdelim(':)');

my %fields = (
	      TEMPLATE => {},
	      TABLE_H  => {},
	      VALUES   => {},
	     );

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($template,\@tables)

Create a new B<DbFramework::Template> object.  I<$template> is the
template to be filled.  I<@tables> are the B<DbFramework::Table>
objects required for filling the template.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;

  my $template = $self->template(new Text::FillIn());
  $template->text(shift);
  $template->object($self);
  $template->hook('&','do_method');

  my @tables;
  for ( @{$_[0]} ) { push(@tables,($_->name,$_)) }
  $self->table_h(\@tables);

  return $self;
}

##----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 template()

Returns the B<Text::FillIn> object associated with the template.

=head2 fill(\%values)

Returns a filled template.  The values in I<%values> are used to fill
certain placeholders in the template (see L<"Template placeholders">.)

=cut

sub fill {
  my $self = attr shift;
  %VALUES  = $_[0] ? %{$_[0]} : ();
  $TEMPLATE->interpret;
}

#------------------------------------------------------------------------------

sub do_method {
  my $self = shift;
  my($method,$arg) = $_[0] =~ /(\w+)\((.*)\)/ or die ("Bad slot: $_[0]");
  #no strict('refs');
  return $self->$method($arg);
}

#------------------------------------------------------------------------------

sub db_value {
  my($self,$arg) = (attr shift,shift);
  # (:&db_value(table.column):)
  $arg =~ /(\w+\.\w+)/ && return $VALUES{$1};
}

#------------------------------------------------------------------------------

sub db_html_form_field {
  my($self,$arg) = (attr shift,shift);
  my $html;

  # (:&db_html_form_field(table.column[ value=value][ type=type]):)
  if ( $arg =~ /^((\w+)\.(\w+))(,(.*?))?(,(.*?))?$/i ) {
    my $table = $TABLE_H{$2} or die "Can't find table in $arg";
    my $value = $5 ? $5 : $VALUES{$1};
    my $type  = $7 ? $7 : undef;
    my $attribute_name = $3;
    my($attribute) = $table->get_attributes($attribute_name);

    print STDERR "\$arg = $arg, \$value = $value, \$type = $type, \$attribute_name = $attribute_name, \$attribute = $attribute" if $_DEBUG;

    $html = $attribute->as_html_form_field($value,$type);
  }
  $html;
}

#------------------------------------------------------------------------------

sub db_fk_html_form_field {
  my($self,$arg) = (attr shift,shift);

  # (:&db_fk_html_form_field(table.fk):)
  if ( my($t_name,$fk_name) = $arg =~ /^(\w+)\.(\w+)$/ ) {
    my $table = $TABLE_H{$t_name} or die "Can't find table in $arg";
    my($fk) = $table->has_foreign_keys_h_byname($fk_name)
      or die "Can't find foreign key $2 in table " . $table->name;

    print STDERR "\$fk_name = $fk_name, \$fk = $fk\n" if $_DEBUG;

    $fk->as_html_form_field(\%VALUES);
  }
}

#------------------------------------------------------------------------------

sub db_pk_html_hidden {
  my($self,$arg) = (attr shift,shift);

  # (:&db_pk_html_hidden(table):)
  if ( my($t_name) = $arg =~ /^(\w+)$/ ) {
    my $table = $TABLE_H{$t_name} or die "Can't find table in $arg";
    $table->is_identified_by->as_hidden_html(\%VALUES);
  }
}

#------------------------------------------------------------------------------

=head2 default($table)

I<$table> is a B<DbFramework::Table> object.  Sets up a default
template consisting of all fields in I<$table>.

=cut

sub default {
  my($self,$table) = (attr shift,shift);

  $table = $TABLE_H{$table} or die "Can't find table '$table'";
  my $t_name = $table->name;
  my($l,$r)  = ($TEMPLATE->Ldelim,$TEMPLATE->Rdelim);
  my $t;

  # primary key
  for ( @{$table->is_identified_by->incorporates_l} ) {
    unless ( $table->in_foreign_key($_) ) {
      my $a_name = $_->name;
      $t .= qq{<TD>${l}&db_html_form_field(${t_name}.${a_name})${r}</TD>};
    }
  }

  # ordinary attributes
  for ( $table->non_key_attributes ) {
    my $a_name = $_->name;
    $t .= qq{<TD>${l}&db_html_form_field(${t_name}.${a_name})${r}</TD>};
  }

  # keys
  my(%key_attributes,@fk_attributes,@key_attributes);
  for ( @{$table->has_foreign_keys_l} ) {
    push(@fk_attributes,$_->attribute_names)
  }
  @key_attributes = (@fk_attributes,$table->is_identified_by->attribute_names);

  for my $key ( @{$table->is_accessed_using_l} ) {
    # get unique hash of key attributes not in primary or foreign keys
    for ( @{$key->incorporates_l} ) {
      my $name = $_->name;
      $key_attributes{$name} = $_ unless grep(/^$name$/,@key_attributes);
    }
  }
  for ( keys(%key_attributes) ) {
    $t .= qq{<TD>${l}&db_html_form_field(${t_name}.$_)${r}</TD>};
  }

  # foreign keys
  for ( @{$table->has_foreign_keys_l} ) {
    my $fk_name = $_->name;
    $t .= qq{<TD>${l}&db_fk_html_form_field(${t_name}.${fk_name})${r}</TD>};
  }
 
  $TEMPLATE->text($t);
}

1;

=head1 SEE ALSO

L<Text::FillIn> and L<DbFramework::Util>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
