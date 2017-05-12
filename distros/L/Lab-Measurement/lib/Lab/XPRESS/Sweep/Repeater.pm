package Lab::XPRESS::Sweep::Repeater;

our $VERSION = '3.542';

use Lab::XPRESS::Sweep::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep::Sweep');

sub new {
    my $proto                  = shift;
    my @args                   = @_;
    my $class                  = ref($proto) || $proto;
    my $self->{default_config} = {
        id                  => 'Repeater',
        filename_extension  => '#',
        repetitions         => 1,
        stepwidth           => 1,
        points              => [1],
        rate                => [1],
        mode                => 'list',
        allowed_sweep_modes => ['list'],
        backsweep           => 0,
        values              => undef,
    };

    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );
    $self->{config}->{points}   = [1];
    $self->{config}->{duration} = [1];

    if ( ref( $self->{config}->{repetitions} ) eq 'ARRAY' ) {
        $self->{config}->{values} = $self->{config}->{repetitions};
        $self->{config}->{repetitions}
            = scalar @{ $self->{config}->{repetitions} };
    }

    $self->{config}->{mode}   = 'list';
    $self->{loop}->{interval} = $self->{config}->{interval};

    $self->{DataFile_counter} = 0;

    $self->{DataFiles} = ();

    return $self;
}

sub get_value {
    my $self = shift;

    if ( defined $self->{config}->{values} ) {
        return @{ $self->{config}->{values} }[ $self->{repetition} - 1 ];
    }
    else {
        return $self->{repetition};
    }
}

1;

=encoding utf8

=head1 NAME

	Lab::XPRESS::Sweep::Repeater - simple repeater

.

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();
	
	
	
	my $repeater = $hub->Sweep('Repeater',
		{
		repetitions => 5
		});

.

=head1 DESCRIPTION

Parent: Lab::XPRESS::Sweep::Sweep

The Lab::XPRESS::Sweep::Repeater class implements a simple repeater module in the Lab::XPRESS::Sweep framework.

.

=head1 CONSTRUCTOR
	

	my $repeater = $hub->Sweep('Repeater',
		{
		repetitions => 5
		});

Instantiates a new repeater with 5 repetitions. Alternatively 
	
	my $repeater_array = $hub->Sweep('Repeater',
		{
		repetitions => [10, 20, 30, 40, 50]
		});

Instantiates also a repeater with 5 repetitions. However, the function

	$repeater->get_value(); # <-- returns 1,2,3,4,5 depending on the repetition,
	$repeater->get_array(); # <-- returns 10,20,30,40,50 depending on the repetition.  
.

=head1 PARAMETERS



=head2 repetitions [int / array] (default = 1)
	
number of repetitions. default value is 1, negative values indicate a infinit number of repetitions.
When an array is given, the number of reetitions corresponds to the length of the array.

.


=head2 id [string] (default = 'Repeater')

Just an ID.

.

=head2 filename_extention [string] (default = '#=')

Defines a postfix, that will be appended to the filenames if necessary.

.

=head2 delay_before_loop [float] (default = 0)

defines the time in seconds to wait after the starting point has been reached.

.

=head2 delay_in_loop [float] (default = 0)

This parameter is relevant only if mode = 'step' or 'list' has been selected. 
Defines the time in seconds to wait after the value for the next step has been reached.

.

=head2 delay_after_loop [float] (default = 0)

Defines the time in seconds to wait after the sweep has been finished. This delay will be executed before an optional backsweep or optional repetitions of the sweep.

.

=head1 METHODS

=head2 get_value()

Returns an integer number n corresponding to the nth repetition or if an array @a was given for the parameter 'repetitions' it returns @a[n].  

.

=head1 CAVEATS/BUGS

probably none

.

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS::Sweep>

=back

.

=head1 AUTHOR/COPYRIGHT

Christian Butschkow and Stefan Geißler

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

.

=cut

