package Lego::Part;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Color.
	$self->{'color'} = undef;

	# Lego design id.
	$self->{'design_id'} = undef;

	# Lego element id.
	$self->{'element_id'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Check design id or element id.
	if (! defined $self->{'element_id'}
		&& ! defined $self->{'design_id'}) {

		err "Parameter 'element_id' or 'design_id' is required.";
	}

	# Object.
	return $self;
}

# Get or set color.
sub color {
	my ($self, $color) = @_;
	if ($color) {
		$self->{'color'} = $color;
	}
	return $self->{'color'};
}

# Get or set lego design id.
sub design_id {
	my ($self, $design_id) = @_;
	if ($design_id) {
		$self->{'design_id'} = $design_id;
	}
	return $self->{'design_id'};
}

# Get or set lego element id.
sub element_id {
	my ($self, $element_id) = @_;
	if ($element_id) {
		$self->{'element_id'} = $element_id;
	}
	return $self->{'element_id'};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lego::Part - Lego part object.

=head1 SYNOPSIS

 use Lego::Part;

 my $obj = Lego::Part->new;
 my $color = $obj->color($color);
 my $design_id = $obj->design_id($design_id);
 my $element_id = $obj->element_id($element_id);

=head1 METHODS

=over 8

=item * C<new()>

 Constructor.
 Returns object.

=item * C<color([$color])>

 Get or set color.
 Returns string with color.

=item * C<design_id([$design_id])>

 Get or set lego design id.
 Returns string with design ID.

=item * C<element_id([$element_id])>

 Get or set lego element id.
 Returns string with element ID.

=back

=head1 EXAMPLE1

=for comment filename=create_part_and_print1.pl

 use strict;
 use warnings;

 use Lego::Part;

 # Object.
 my $part = Lego::Part->new(
         'color' => 'red',
         'design_id' => '3002',
 );

 # Print color and design ID.
 print 'Color: '.$part->color."\n";
 print 'Design ID: '.$part->design_id."\n";

 # Output:
 # Color: red
 # Design ID: 3002

=head1 EXAMPLE2

=for comment filename=create_part_and_print2.pl

 use strict;
 use warnings;

 use Lego::Part;

 # Object.
 my $part = Lego::Part->new(
         'element_id' => '300221',
 );

 # Print color and design ID.
 print 'Element ID: '.$part->element_id."\n";

 # Output:
 # Element ID: 300221

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Task::Lego>

Install the Lego modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Lego-Part>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
