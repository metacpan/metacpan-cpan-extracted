
#################################################################
# Drupal::Admin::ModuleCheckbox Package
#################################################################

package Drupal::Admin::ModuleCheckbox;

use Moose;

has 'group' => (
		is => 'ro',
		isa => 'Str',
		required => 1
	       );

# 'status' or 'throttle'
has 'type' => (
	       is => 'ro',
	       isa => 'Str',
	       required => 1
	      );

has 'name' => (
	       is => 'ro',
	       isa => 'Str',
	       required => 1
	      );

has 'id' => (
	     is => 'ro',
	     isa => 'Str',
	     required => 1
	    );

has 'value' => (
	     is => 'ro',
	     isa => 'Str',
	     required => 1
	    );


has 'checked' => (
		  is => 'rw',
		  isa => 'Bool',
		  required => 1
		 );

# Disabled attribute
has 'disabled'  => (
		  is => 'rw',
		  isa => 'Bool',
		  required => 1
		 );

# Index of the checkbox on the page, in case there are multiples with the same name
has 'index' => (
		is => 'ro',
		isa => 'Int',
		required => 1
	       );



# Return a human readable string describing module state
sub readable {
  my $self = shift;

  my $group = $self->group;
  $group =~ s/\s+/_/g;

  my $str =  join('.',
		  $group,
		  $self->type,
		  $self->name . '[' . $self->index . ']',
		  $self->checked
		 );

  return($str);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME 

Drupal::Admin::Checkbox - simple object representing module checkbox

=head1 METHODS

=over 4

=item B<group>

The group to which the checkbox belongs, e.g. C<Core - optional>

=item B<type>

Type can be C<status> (to turn a module on or off) or C<throttle>.

=item B<name>

The C<name> attribute stripped of type information; e.g. if the actual
checkbox name attribute is C<status[aggregator]>, our name attribute
is C<aggregator>

=item B<id>

The C<id> attribute of the checkbox (not currently used for anything)

=item B<value>

The C<value> attribute of the checkbox; i.e. the user visible label

=item B<checked>

Boolean, whether or not the checkbox is checked

=item B<disabled>

Boolean, whether or not the checkbox is disabled

=item B<index>

Index of the checkbox on the page, in case there are multiples with
the same name (starts from 0)

=item B<readable>

Return a human readable string describing module state

=back
