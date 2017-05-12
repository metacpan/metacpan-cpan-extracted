package Linux::Virt::Plugin::Libvirt;
{
  $Linux::Virt::Plugin::Libvirt::VERSION = '0.15';
}
BEGIN {
  $Linux::Virt::Plugin::Libvirt::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: generic libvirt plugin for Linux::Virt

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use XML::Simple;

extends 'Linux::Virt::Plugin';

has 'type' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'lazy'    => 1,
    'builder' => '_init_type',
);

sub _init_priority { return 10; }

sub _init_type {
    return 'libvirt';
}

sub is_host {
    my $self = shift;
    return 1 if -x '/usr/bin/virsh';
    return;
}

sub is_vm {
    return;
}

sub vms {
    my $self        = shift;
    my $vserver_ref = shift;
    my $opts        = shift || {};

    return unless -x '/usr/bin/virsh';

    local $ENV{LANG} = "C";
    my $VIRSH;
    my $cmd = "/usr/bin/virsh -c qemu:///system list --all";
    if ( !open( $VIRSH, '-|', $cmd ) ) {
        my $msg = "Could not execute /usr/bin/virsh! Is libvirt-bin installed?: $!";
        $self->logger()->log( message => $msg, level => 'warning', );
        return;
    }
    my %vms = ();
    while ( my $line = <$VIRSH> ) {
        next if $line =~ m/^\s*Id\s+Name\s+State/i;
        next if $line =~ m/^-----/;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my ( $id, $name, $state ) = split( /\s+/, $line );
        next unless $name;
        $vms{$name}{'id'}    = $id;
        $vms{$name}{'name'}  = $name;
        $vms{$name}{'state'} = $state;
    } ## end while ( my $line = <$VIRSH>)
    close($VIRSH);
    $cmd = "/usr/bin/virsh -c qemu:///system dumpxml ";
    foreach my $vm ( keys %vms ) {
        next unless $vms{$vm}{'name'};
        $cmd = $cmd . $vms{$vm}{'name'};
        if ( open( $VIRSH, '-|', $cmd ) ) {
            my @xml = <$VIRSH>;
            close($VIRSH);
            my $xml_ref;
            eval { $xml_ref = XMLin( join( "", @xml ) ); };
            next if $@;
            $vms{$vm}{'type'}      = $xml_ref->{'type'};
            $vms{$vm}{'memmax'}    = $xml_ref->{'memory'};
            $vms{$vm}{'memcur'}    = $xml_ref->{'currentMemory'};
            $vms{$vm}{'vcpu'}      = $xml_ref->{'vcpu'};
            $vms{$vm}{'virt_arch'} = $xml_ref->{'os'}->{'type'}->{'arch'};
        } ## end if ( open( $VIRSH, '-|'...))
        my $name = $vms{$vm}{'name'};
        if ( $self->type() ne 'libvirt' && $self->type() ne lc( $vms{$vm}{'type'} ) ) {

            # Print skip this vm if the type doesn't match the requested one
            next;
        }
        $vserver_ref->{$name}{'id'}                       = $vms{$name}{'id'};
        $vserver_ref->{$name}{'virt'}{'type'}             = $vms{$vm}{'type'};
        $vserver_ref->{$name}{'virt'}{'arch'}             = $vms{$vm}{'virt_arch'};
        $vserver_ref->{$name}{'limits'}{'mem'}{'current'} = $vms{$vm}{'memcur'};
        $vserver_ref->{$name}{'limits'}{'mem'}{'min'}     = $vms{$vm}{'memcur'};
        $vserver_ref->{$name}{'limits'}{'mem'}{'max'}     = $vms{$vm}{'memmax'};
        $vserver_ref->{$name}{'limits'}{'mem'}{'soft'}    = $vms{$vm}{'memmax'};
        $vserver_ref->{$name}{'limits'}{'mem'}{'hard'}    = $vms{$vm}{'memmax'};
        $vserver_ref->{$name}{'limits'}{'mem'}{'hits'}    = 0;
    } ## end foreach my $vm ( keys %vms )
    return 1;
} ## end sub vms

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::Virt::Plugin::Libvirt - generic libvirt plugin for Linux::Virt

=head1 METHODS

=head2 is_host

Returns a true value if this is run on a Libvirt equipped host.

=head2 is_vm

Always returns false. Subclasses should override this with an apt implementation.

=head2 vms

List al running VMs.

=head1 NAME

Linux::Virt::Plugin::Libvirt - Libvirt Plugin for Linux::Virt.

=head1 virsh vs. Sys::Virt

Why not use Sys::Virt here?

As of the time of this writing Sys::Virt is broken. Virsh is much more stable
and easier to use.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
