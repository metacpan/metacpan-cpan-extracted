use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Base;
use Carp qw/croak/;
use Devel::GlobalDestruction;
use namespace::clean; # to avoid having an "in_global_destruction" method

# ABSTRACT: ESLIF base

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '6.0.20'; # VERSION


#
# We keep two internal hashes:
# - MULTITONS is holding multiton constants
#   key is the engine (an IV) and value is the object instance
#
# - MULTITONS_FOR_GLOBAL_DESTRUCTION is used for global destruction
#   key is the engine (an IV) and value is the object destructor code
#
# This is because at global destruction we cannot afford to use something
# that still constain object instances. At this stage, only pure perl constants
# do survive.
#
# DESTROY() is using:
# - MULTITONS when not in global destruction
# - MULTITONS_FOR_GLOBAL_DESTRUCTION when in global destruction
#
# CLONE() is completely reaffecting the keys of both hashes.
# - 
#
my %MULTITONS;
my %MULTITONS_FOR_GLOBAL_DESTRUCTION;

sub _find {
    my ($class, $eq, @arguments) = @_;

    foreach (grep { $_->{class} eq $class } values %MULTITONS) {
	return $_ if $_->$eq($_->{arguments}, @arguments)
    }

    return
}


sub new {
    my $proto = shift;

    my $class = ref($proto) || $proto;                # Because of MarpaX::ESLIF::Recognizer::newFrom that is an instance method
    #
    # Some class variables MUST be provided. This will croak natively
    # if that is not the case.
    #
    my $clonable = $proto->_CLONABLE();
    my $eq       = $proto->_EQ();
    my $allocate = $proto->_ALLOCATE() // croak "$class allocate callback is not defined";
    my $dispose  = $proto->_DISPOSE() // croak "$class dispose callback is not defined";

    #
    # eq, allocate and dispose must be CODE references when defined
    #
    croak "$class eq callback must be a CODE reference" if (defined($eq) && ((ref($eq) // '') ne 'CODE'));
    croak "$class allocate callback must be a CODE reference" if ((ref($allocate) // '') ne 'CODE');
    croak "$class dispose callback must be a CODE reference" if ((ref($dispose) // '') ne 'CODE');

    my $multiton = defined($eq);
    my $self = $multiton ? $class->_find($eq, @_) : undef;
    return $self if defined($self);

    my $engine = $proto->$allocate(@_);
    #
    # For debugging
    #
    # printf STDERR "NEW %s engine %d\n", $class, $engine;
    #
    $self = bless { engine    => $engine,
                    allocate  => $allocate,
                    dispose   => $dispose,
                    multiton  => $multiton,
                    clonable  => $clonable,
                    class     => $class,
                    shallow   => 0,
                    arguments => \@_}, $class;

    if ($multiton) {
        #
        # Look to _global_destroy(), you will understand why MULTITONS_FOR_GLOBAL_DESTRUCTION must constain three elements
        #
        $MULTITONS{$engine} = $self, $MULTITONS_FOR_GLOBAL_DESTRUCTION{$engine} = { engine => $engine, class => $class, dispose => $dispose }
    }

    return $self
}


sub _destroy {
    my $self = shift;

    #
    # No op if it is a shallow'ed instance
    #
    return if $self->{shallow};

    #
    # Here it should never happen that engine is not set
    #
    #
    # For debugging
    #
    # {
    #     my $class = $self->{class};
    #     my $engine = $self->{engine};
    #     printf STDERR "DISPOSE %s engine %d\n", $class, $engine;
    # }
    my $engine = $self->{engine};
    if (! $engine) {
        warn "$self has no engine"
    } else {
        my $dispose = $self->{dispose};
        #
        # We voluntarily do not say $self->$dispose() because of
        # global destruction mode, where instances are not used
        #
        $dispose->($self)
    }

    #
    # Delete from constants
    #
    if ($self->{multiton}) {
        delete $MULTITONS{$engine}, delete $MULTITONS_FOR_GLOBAL_DESTRUCTION{$engine}
    }
}

sub _global_destroy {
    my %COPY = %MULTITONS_FOR_GLOBAL_DESTRUCTION;
    %MULTITONS_FOR_GLOBAL_DESTRUCTION = ();

    my @engines = keys %COPY;
    #
    # We always look at MarpaX::ESLIF children first, then the MarpaX::ESLIF instances.
    # Take care, we do not have instances anymore.
    #
    map { _destroy($COPY{$_}) } grep { $COPY{$_}->{class} ne 'MarpaX::ESLIF' } @engines;
    map { _destroy($COPY{$_}) } grep { $COPY{$_}->{class} eq 'MarpaX::ESLIF' } @engines;
}

#
# Note that we rely on at least one object to be referenced to have global destruction working.
# This is in theory always happening as soon as a multiton is created, and there is always at
# least one multiton: a MarpaX::ESLIF instance.
#
sub DESTROY {
    if (in_global_destruction) {
        goto \&_global_destroy
    } else {
        goto \&_destroy
    }
}


sub _clone {
    my $self = shift;

    my $engine;
    if ($self->{clonable}) {
        #
        # For debugging
        #
        # {
        #     my $class = $self->{class};
        #     my $engine = $self->{engine};
        #     printf STDERR "CLONE %s engine %d", $class, $engine;
        # }
        my $allocate = $self->{allocate};
        my $arguments = $self->{arguments};
        $engine = $self->{engine} = $self->$allocate(@{$arguments});
        #
        # For debugging
        #
        # {
        #     my $engine = $self->{engine};
        #     printf STDERR " ==> engine %d\n", $engine;
        # }
    } else {
        $engine = $self->{engine} = 0;
    }

    if ($self->{multiton}) {
        $MULTITONS{$engine} = $self, $MULTITONS_FOR_GLOBAL_DESTRUCTION{$engine} = { engine => $engine, class => $self->{class}, dispose => $self->{dispose} }
    }
}

#
# Note that it is very important to execute the CLONE method once. This is why
# we test on $class eq __PACKAGE__, because all MarpaX::ESLIF objects inherit
# from it.
# Another way to prevent this is to have a CLONE_SKIP in all sub-classes. Still
# the test remains, because it is safe.
#
sub CLONE {
    my $class = shift;
    return unless $class eq __PACKAGE__;

    my @multitons = values %MULTITONS;
    %MULTITONS = ();
    %MULTITONS_FOR_GLOBAL_DESTRUCTION = ();

    #
    # For debugging
    #
    # print STDERR "CLONE @_ on @multitons\n";

    #
    # We always look at MarpaX::ESLIF multitons first, then the others.
    #
    map { $_->_clone() } grep { $_->{class} eq 'MarpaX::ESLIF' } @multitons;
    map { $_->_clone() } grep { $_->{class} ne 'MarpaX::ESLIF' } @multitons;
}


sub SHALLOW {
    my $proto = shift;

    my $class = ref($proto) || $proto;                # Because of MarpaX::ESLIF::Recognizer::newFrom that is an instance method

    my $engine = shift // croak "\$engine is not defined";

    return bless { engine    => $engine,
                   allocate  => undef,
                   dispose   => undef,
                   multiton  => 0,
                   clonable  => 0,
                   class     => $class,
                   shallow   => 1,
                   arguments => undef}, $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Base - ESLIF base

=head1 VERSION

version 6.0.20

=head1 DESCRIPTION

All L<MarpaX::ESLIF> object inherits from this class, that takes care of clone and proper order destruction.

=head1 METHODS

=head2 $class->new($clonable, $eq, $allocate, $dispose, @arguments)

Generic constructor using C<$allocate->(@args)>. If C<$eq> is set, the instance is implicitly a multiton. If C<$clonable> is a true value, the instance is clonable.

=head2 $self->DESTROY()

Generic destructor. It always calls C<$self>'s C<dispose> method.

=head2 CLONE()

Manages clonable instances.

=head2 $class->SHALLOW($engine)

Create a shallow instance of C<$class> based on C<$engine>, that is required. This instance cannot be cloned and, when being destroyed, will have no effect on the engine.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
