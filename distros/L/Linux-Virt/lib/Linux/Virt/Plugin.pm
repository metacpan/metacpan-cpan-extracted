package Linux::Virt::Plugin;
{
  $Linux::Virt::Plugin::VERSION = '0.15';
}
BEGIN {
  $Linux::Virt::Plugin::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: baseclass for an Linux::Virt plugin

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

use Sys::FS;
use Sys::Run;

# extends ...
# has ...
has 'sys' => (
    'is'      => 'rw',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

has 'fs' => (
    'is'      => 'rw',
    'isa'     => 'Sys::FS',
    'lazy'    => 1,
    'builder' => '_init_fs',
);

has 'priority' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'lazy'  => 1,
    'builder' => '_init_priority',
);
# with ...
with qw(Config::Yak::RequiredConfig Log::Tree::RequiredLogger);
# initializers ...
sub _init_priority { return 0; }

sub _init_sys {
    my $self = shift;

    my $Sys = Sys::Run::->new( { 'logger' => $self->logger(), } );

    return $Sys;
} ## end sub _init_sys

sub _init_fs {
    my $self = shift;

    my $FS = Sys::FS::->new(
        {
            'logger' => $self->logger(),
            'sys'    => $self->sys(),
        }
    );

    return $FS;
} ## end sub _init_fs

# your code here ...
sub is_host {
    my $self = shift;

    return;
}

sub is_vm {
    my $self = shift;

    return;
}

sub is_running {
    my $self = shift;

    return;
}

sub create {
    my $self = shift;

    warn "This method is not implemented in this baseclass.\n";

    return;
} ## end sub create

## no critic (ProhibitBuiltinHomonyms)
sub delete {
## use critic
    my $self = shift;

    warn "This method is not implemented in this baseclcass.\n";

    return;
} ## end sub delete

sub vms {
    my $self = shift;

    warn "This method is not implemented in this baseclcass.\n";

    return;
} ## end sub vms

sub start {
    my $self = shift;

    warn "This method is not implemented in this baseclcass.\n";

    return;
} ## end sub start

sub stop {
    my $self = shift;

    warn "This method is not implemented in this baseclcass.\n";

    return;
} ## end sub stop

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::Virt::Plugin - baseclass for an Linux::Virt plugin

=head1 DESCRIPTION

This module is a base class for all Linux::Virt plugins.

=head1 METHODS

=head2 create

Create a new VM. Subclasses should implement this method.

=head2 delete

Delete an existing VM. Subclasses should implement this method.

=head2 is_host

Returns a true value is this system is a (physical) host and able to run
VMs of this type. Subclasses should implement this method.

=head2 is_running

Returns true if the given VM is currently running.

=head2 is_vm

Returns true if this method is called within an VM. Subclasses should implement this method.

=head2 start

Start an existing VM. Subclasses should implement this method.

=head2 stop

Shutdown an existing VM. Subclasses should implement this method.

=head2 vms

List all available VMs. Subclasses should implement this method.

=head1 NAME

Linux::Virt::Plugin - Base class for all Linux::Virt plugins.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
