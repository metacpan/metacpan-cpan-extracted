package Lego::Part::Action;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Load design id to Lego::Part object.
sub load_design_id {
	my ($self, $part_transfer_class, $part) = @_;
	$self->_check_part_transfer_class($part_transfer_class);
	eval {
		$part_transfer_class->element2design($part);
	};
	if ($EVAL_ERROR) {
		err 'Cannot load design ID.',
			'Error', $EVAL_ERROR;
	}
	return;
}

# Load element id to Lego::Part object.
sub load_element_id {
	my ($self, $part_transfer_class, $part) = @_;
	$self->_check_part_transfer_class($part_transfer_class);
	eval {
		$part_transfer_class->design2element($part);
	};
	if ($EVAL_ERROR) {
		err 'Cannot load element ID.',
			'Error', $EVAL_ERROR;
	}
	return;
}

# Check transfer class.
sub _check_part_transfer_class {
	my ($self, $part_transfer_class) = @_;
	if (! blessed($part_transfer_class)
		|| ! $part_transfer_class->isa('Lego::Part::Transfer')) {

		err "Bad transfer class. Must be 'Lego::Part::Transfer' ".
			'class.';
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Lego::Part::Action - Lego part action object.

=head1 SYNOPSIS

 use Lego::Part::Action;

 my $obj = Lego::Part::Action->new;
 $obj->load_design_id($part_transfer_class, $part);
 $obj->load_element_id($part_transfer_class, $part);

=head1 METHODS

=over 8

=item * C<new()>

 Constructor.
 Returns object.

=item * C<load_design_id($part_transfer_class, $part)>

 Load design id to Lego::Part object.
 Returns undef.

=item * C<load_element_id($part_transfer_class, $part)>

 Load element id to Lego::Part object.
 Returns undef.

=back

=head1 ERRORS

 load_design_id():
         Bad transfer class. Must be 'Lego::Part::Transfer' class.
         Cannot load design ID.
                 Error: %s
 load_element_id():
         Bad transfer class. Must be 'Lego::Part::Transfer' class.
         Cannot load element ID.
                 Error: %s

=head1 EXAMPLE

=for comment filename=design_to_element_and_print.pl

 package Lego::Part::Transfer::Example;

 use base qw(Lego::Part::Transfer);
 use strict;
 use warnings;

 # Convert design to element.
 sub design2element {
         my ($self, $part) = @_;
         $self->_check_part($part);
         if ($part->color eq 'red' && $part->design_id eq '3002') {
                 $part->element_id('300221');
         }
         return;
 }

 package main;

 use strict;
 use warnings;

 use Lego::Part;
 use Lego::Part::Action;

 # Lego part.
 my $part = Lego::Part->new(
         'color' => 'red',
         'design_id' => '3002',
 );

 #  Lego part action.
 my $act = Lego::Part::Action->new;

 # Transfer class.
 my $trans = Lego::Part::Transfer::Example->new;

 # Load element id.
 $act->load_element_id($trans, $part);

 # Print color and design ID.
 print 'Color: '.$part->color."\n";
 print 'Design ID: '.$part->design_id."\n";
 print 'Element ID: '.$part->element_id."\n";

 # Output:
 # Color: red
 # Design ID: 3002
 # Element ID: 300221

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Scalar::Util>.

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
