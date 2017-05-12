package Getopt::Flex::Spec;
BEGIN {
  $Getopt::Flex::Spec::VERSION = '1.07';
}

# ABSTRACT: Getopt::Flex's way of handling an option spec

use strict; #shut up cpants
use warnings; #shut up cpants
use Moose;
use Getopt::Flex::Spec::Argument;
use MooseX::StrictConstructor;

#the raw specification            
has 'spec' => (
    is => 'ro',
    isa => 'HashRef[HashRef[Str|CodeRef|ScalarRef|ArrayRef|HashRef]]',
    required => 1,
);

#maps the various argument aliases onto their argument object
has '_argmap' => (
    is => 'rw',
    isa => 'HashRef[Getopt::Flex::Spec::Argument]',
    default => sub { {} },
    init_arg => undef,
);

has '_config' => (
    is => 'ro',
    isa => 'Getopt::Flex::Config',
    required => 1,
    init_arg => 'config',
);
                
                
sub BUILD {
    my ($self) = @_;
    
    my $spec = $self->spec();
    
    my $argmap = $self->_argmap();

	my $help = 0;
	if($self->_config()->auto_help()) {
		if(defined($spec->{'help|h'}) || defined($spec->{'help'}) || defined($spec->{'h'})) {
			Carp::croak "auto_help set, but a switch matching 'help|h' already exists, exiting.";
		}

		$spec->{'help|h'} = {
			'var' => \$help,
			'type' => 'Bool',
		};
	}

    #create each argument in turn
    foreach my $switch_spec (keys %{$spec}) {
        $spec->{$switch_spec}->{'switchspec'} = $switch_spec;
        
        my $argument = Getopt::Flex::Spec::Argument->new($spec->{$switch_spec});
        
        my @aliases = @{$argument->aliases()};
        
        $argmap->{$switch_spec} = $argument;
        
        #map each argument onto its aliases
        foreach my $alias (@aliases) {
            if($self->_config()->case_mode() eq 'INSENSITIVE') {
                $alias = lc($alias);
            }

			next if $switch_spec eq $alias;
            
            #no duplicate aliases (or primary names) allowed
            if(defined($argmap->{$alias})) {
                my $sp = $argmap->{$alias}->switchspec();
                Carp::confess "alias $alias given by spec $switch_spec already exists and belongs to spec $sp\n";
            }
            $argmap->{$alias} = $argument;
        }
    }
    $self->_argmap($argmap);
}


sub check_switch {
    my ($self, $switch) = @_;

    if($self->_config()->case_mode() eq 'INSENSITIVE') {
        $switch = lc($switch);
    }
    
    return defined($self->_argmap()->{$switch});
}


sub set_switch {
    my ($self, $switch, $val) = @_;
    
    Carp::confess "No such switch $switch\n" if !$self->check_switch($switch);
    
    if($self->_config()->case_mode() eq 'INSENSITIVE') {
        $switch = lc($switch);
    }
    
    return $self->_argmap()->{$switch}->set_value($val);
}


sub switch_requires_val {
    my ($self, $switch) = @_;
    
    Carp::confess "No such switch $switch\n" if !$self->check_switch($switch);
    
    if($self->_config()->case_mode() eq 'INSENSITIVE') {
        $switch = lc($switch);
    }
    
    return $self->_argmap()->{$switch}->requires_val();
}


sub get_switch_error {
    my ($self, $switch) = @_;
    
    Carp::confess "No such switch $switch\n" if !$self->check_switch($switch);
    
    if($self->_config()->case_mode() eq 'INSENSITIVE') {
        $switch = lc($switch);
    }
    
    return $self->_argmap()->{$switch}->error();
}


sub get_switch {
    my ($self, $switch) = @_;
    
    return undef if !$self->check_switch($switch);
    
    if($self->_config()->case_mode() eq 'INSENSITIVE') {
        $switch = lc($switch);
    }
    
    my $arg = $self->_argmap()->{$switch};
    
    if($arg->get_type() =~ /^ArrayRef/) {
        return $arg->var();
    } elsif($arg->get_type() =~ /^HashRef/) {
        return $arg->var();
    } else {
        return ${$arg->var()};
    }
}


no Moose;

1;

__END__
=pod

=head1 NAME

Getopt::Flex::Spec - Getopt::Flex's way of handling an option spec

=head1 VERSION

version 1.07

=head1 DESCRIPTION

This class is only meant to be used by Getopt::Flex
and should not be used directly.

=head1 NAME

Getopt::Flex::Spec - Specification class for Getopt::Flex

=head1 METHODS

=head2 check_switch

Check whether or a not a switch belongs to this specification

=head2 set_switch

Set a switch to the supplied value

=head2 switch_requires_val

Check whether or not a switch requires a value

=head2 get_switch_error

Given a switch return any associated error message.

=head2 get_switch

Passing this function the name of a switch (or the switch spec) will
cause it to return the value of a ScalarRef, a HashRef, or an ArrayRef
(based on the type given), or undef if the given switch does not
correspond to any defined switch.

=for Pod::Coverage   BUILD

=head1 AUTHOR

Ryan P. Kelly <rpkelly@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Ryan P. Kelly.

This is free software, licensed under:

  The MIT (X11) License

=cut

