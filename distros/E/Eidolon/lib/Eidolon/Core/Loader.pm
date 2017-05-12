package Eidolon::Core::Loader;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Core/Loader.pm - driver loader
#
# ==============================================================================

use Eidolon::Driver::Exceptions;
use warnings;
use strict;

our $VERSION  = "0.02"; # 2009-05-13 22:32:29

# ------------------------------------------------------------------------------
# \% new()
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $self);

    $class = shift;

    # class attributes
    $self = { "type_cache" => {} };

    bless $self, $class;
    
    return $self;
}

# ------------------------------------------------------------------------------
# load($class, @params)
# load a driver
# ------------------------------------------------------------------------------
sub load
{
    my ($self, $class, @params, $r);

    ($self, $class, @params) = @_;
    $r    = Eidolon::Core::Registry->get_instance;
    
    # loading driver
    eval "require $class";
    throw CoreError::Compile($@) if $@;
    
    throw CoreError::Loader::InvalidDriver($class) if !$class->isa("Eidolon::Driver");
    throw CoreError::Loader::AlreadyLoaded($class) if exists $self->{"type_cache"}->{$class};

    $self->{"type_cache"}->{$class} = $class->new( @params );
}

# ------------------------------------------------------------------------------
# \% get_object($class)
# get driver object
# ------------------------------------------------------------------------------
sub get_object
{
    my ($self, $class) = @_;

    # find object by class
    return $self->{"type_cache"}->{$class} if (exists $self->{"type_cache"}->{$class});

    # find driver by parent class
    foreach (keys %{ $self->{"type_cache"} })
    {
        return $self->{"type_cache"}->{$_} if ($_->isa($class));
    }

    return undef;
}

1;

__END__

=head1 NAME

Eidolon::Core::Loader - Eidolon driver loader.

=head1 SYNOPSIS

This code must be placed in one of your application controllers. For example,
in C<lib/Example/Controller/Default.pm>:

    sub default : Default
    {
        my ($r, $tpl);

        $r   = Eidolon::Core::Registry->get_instance;
        $tpl = $r->loader->get_object("Eidolon::Driver::Template");

        if ($tpl) 
        {
            $tpl->parse("index.tpl");
            $tpl->render;
        }
    }

=head1 DESCRIPTION

The I<Eidolon::Core::Loader> package is the central part of I<Eidolon> 
abstraction layer. It provides the unified interface for manipulations with
vital application objects (drivers). You can load a new driver and gain access
to loaded drivers with this package.

The driver being loaded must be inherited from L<Eidolon::Driver> class to pass
driver validation procedure. 

The object of I<Eidolon::Core::Loader> is mounted in application registry
as C<$r-E<gt>loader>, so it can be used later by any application component. 

=head1 METHODS

=head2 new()

Class constructor.

=head2 load($class, @params)

Loads a C<$class> driver and initializes it with given C<@params> (if any).

=head2 get_object($class)

Returns an object of the loaded driver. If driver with given C<$class> isn't
loaded C<undef> will be returned.

=head1 SEE ALSO

L<Eidolon>,
L<Eidolon::Application>,
L<Eidolon::Driver>,
L<Eidolon::Core::Exceptions>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
