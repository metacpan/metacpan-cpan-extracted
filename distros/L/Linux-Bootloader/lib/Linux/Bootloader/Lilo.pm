package Linux::Bootloader::Lilo;

=head1 NAME

Linux::Bootloader::Lilo - Parse and modify LILO configuration files.

=head1 SYNOPSIS

	use Linux::Bootloader;
	use Linux::Bootloader::Lilo;
	
	my $bootloader = Linux::Bootloader::Lilo->new();
	my $config_file='/etc/lilo.conf';

	$bootloader->read($config_file)

	# add a kernel	
	$bootloader->add(%hash)

	# remove a kernel
	$bootloader->remove(2)

	# set new default
	$bootloader->set_default(1)

	$bootloader->write($config_file)


=head1 DESCRIPTION

This module provides functions for working with LILO configuration files.

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

	Creates a new Linux::Bootloader::Lilo object.

=head2 install()

        Attempts to install bootloader.
        Takes: nothing.
        Returns: undef on error.

=head2 boot-once()

        Attempts to set a kernel as default for one boot only.
        Takes: string.
        Returns: undef on error.

=cut


use strict;
use warnings;
use Linux::Bootloader

@Linux::Bootloader::Lilo::ISA = qw(Linux::Bootloader);
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
    $self->{'config_file'}='/etc/lilo.conf';
}



### LILO functions ###


# Run command to install bootloader

sub install {
  my $self=shift;

  system("/sbin/lilo");
  if ($? != 0) { 
    warn ("ERROR:  Failed to run lilo.\n") && return undef; 
  }
  return 1;
}


# Set kernel to be booted once

sub boot_once {
  my $self=shift;
  my $label=shift;

  return undef unless defined $label;
  
  if (system("/sbin/lilo","-R","$label")) {
    warn ("ERROR:  Failed to set boot-once.\n") && return undef; 
  }
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

