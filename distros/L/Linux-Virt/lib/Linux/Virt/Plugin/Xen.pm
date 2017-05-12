package Linux::Virt::Plugin::Xen;
{
  $Linux::Virt::Plugin::Xen::VERSION = '0.15';
}
BEGIN {
  $Linux::Virt::Plugin::Xen::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Xen plugin for Linux::Virt

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

extends 'Linux::Virt::Plugin::Libvirt';

sub _init_priority { return 10; }

sub _init_type {
    return 'xen';
}

sub is_host {    # dom0
    my $self     = shift;
    my $xen_caps = "/proc/xen/capabilities";
    if ( -f $xen_caps ) {
        if ( open( my $FH, "<", $xen_caps ) ) {
            while ( my $line = <$FH> ) {
                if ( $line =~ m/control_d/i ) {
                    close($FH);
                    return 1;
                }
            } ## end while ( my $line = <$FH> )
            close($FH);
        } ## end if ( open( my $FH, "<"...))
    } ## end if ( -f $xen_caps )
    return;
} ## end sub is_host

sub is_vm {    # domu
    my $self     = shift;
    my $xen_caps = "/proc/xen/capabilities";

    # xen_caps must be present and NOT contain control_d
    if ( -f $xen_caps ) {
        if ( open( my $FH, "<", $xen_caps ) ) {
            while ( my $line = <$FH> ) {
                if ( $line =~ m/control_d/i ) {
                    close($FH);
                    return;
                }
            } ## end while ( my $line = <$FH> )
            close($FH);
        } ## end if ( open( my $FH, "<"...))
        return 1;
    } ## end if ( -f $xen_caps )
    return;
} ## end sub is_vm

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::Virt::Plugin::Xen - Xen plugin for Linux::Virt

=head1 METHODS

=head2 is_host

This method will return a true value if invoked in an xen (capeable) host (dom0).

=head2 is_vm

This method will return a true value if invoked in a xen vm (domU)

=head1 NAME

Linux::Virt::Xen - Xen plugin for Linux::Virt

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
