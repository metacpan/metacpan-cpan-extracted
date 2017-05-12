package Linux::Bootloader::Yaboot;

=head1 NAME

Linux::Bootloader::Yaboot - Parse and modify YABOOT configuration files.

=head1 SYNOPSIS

	use Linux::Bootloader;
	use Linux::Bootloader::Yaboot;
	
	my $bootloader = Linux::Bootloader::Yaboot->new();
	my $config_file='/etc/yaboot.conf';

	$bootloader->read($config_file)

	# add a kernel	
	$bootloader->add(%hash)

	# remove a kernel
	$bootloader->remove(2)

	# set new default
	$bootloader->set_default(1)

	$bootloader->write($config_file)


=head1 DESCRIPTION

This module provides functions for working with YABOOT configuration files.

	Adding a kernel:
	- add kernel at start, end, or any index position.
	- kernel path and title are required.
	- root, kernel args, initrd are optional.
	- any options not specified are copied from default.
	- remove any conflicting kernels if force is specified.
	
	Removing a kernel:
	- remove by index position
	- or by title/label


=head1 FUNCTIONS

Also see L<Linux::Bootloader> for functions available from the base class.

=head2 new()

	Creates a new Linux::Bootloader::Yaboot object.

=head2 install()

        Attempts to install bootloader.
        Takes: nothing.
        Returns: undef on error.

=cut


use strict;
use warnings;
use Linux::Bootloader

@Linux::Bootloader::Yaboot::ISA = qw(Linux::Bootloader);
use base 'Linux::Bootloader';


use vars qw( $VERSION );
our $VERSION = '1.2';


sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless({}, $class);

    $self->SUPER::new();

    return $self;
}


sub _set_config_file {
    my $self=shift;
    $self->{'config_file'}='/etc/yaboot.conf';
}

### YABOOT functions ###


# Run command to install bootloader

sub install {
    my $self=shift;

    #system("/usr/sbin/ybin");
    #if ( $? != 0 ) {
    #    warn("ERROR:  Failed to run ybin.\n") && return undef;
    #}

    print("Not installing bootloader.\n");
    print("Depending on your arch you may need to run ybin.\n");
    return 1;
}


1;


=head1 AUTHOR

Open Source Development Labs, Engineering Department <eng@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2006 Open Source Development Labs
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Linux::Bootloader>

=cut

