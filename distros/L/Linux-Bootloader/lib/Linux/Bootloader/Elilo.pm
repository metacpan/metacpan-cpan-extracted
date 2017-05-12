package Linux::Bootloader::Elilo;

=head1 NAME

Linux::Bootloader::Elilo - Parse and modify ELILO configuration files.

=head1 SYNOPSIS

	use Linux::Bootloader;
	use Linux::Bootloader::Elilo;
	
	my $bootloader = Linux::Bootloader::Elilo->new();
	my $config_file='/etc/elilo.conf';

	$bootloader->read($config_file)

	# add a kernel	
	$bootloader->add(%hash)

	# remove a kernel
	$bootloader->remove(2)

	# set new default
	$bootloader->set_default(1)

	$bootloader->write($config_file)


=head1 DESCRIPTION

This module provides functions for working with ELILO configuration files.

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

	Creates a new Linux::Bootloader::Elilo object.

=head2 install()

        Attempts to install bootloader.
        Takes: nothing.
        Returns: undef on error.

=cut


use strict;
use warnings;
use Linux::Bootloader

@Linux::Bootloader::Elilo::ISA = qw(Linux::Bootloader);
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
    $self->{'config_file'}='/etc/elilo.conf';
}


### ELILO functions ###


# Run command to install bootloader

sub install {
  my $self=shift;

  system("/usr/sbin/elilo");
  if ($? != 0) { 
    warn ("ERROR:  Failed to run elilo.\n") && return undef; 
  }
  return 1;
}

# Set kernel to be booted once

sub boot_once {
    my $self=shift;
    my $label = shift;

    return undef unless defined $label;

    $self->read( '/etc/elilo.conf' );
    my @config=@{$self->{config}};

    if ( ! grep( /^checkalt/i, @config ) ) {
        warn("ERROR:  Failed to set boot-once.\n");
        warn("Please add 'checkalt' to global config.\n");
        return undef;
    }

    my @sections = $self->_info();
    my $position = $self->_lookup($label);
    $position++;
    my $efiroot = `grep ^EFIROOT /usr/sbin/elilo | cut -d '=' -f 2`;
    chomp($efiroot);

    my $kernel = $efiroot . $sections[$position]{kernel};
    my $root = $sections[$position]{root};
    my $args = $sections[$position]{args};

    #system( "/usr/sbin/eliloalt", "-d" );
    if ( system( "/usr/sbin/eliloalt", "-s", "$kernel root=$root $args" ) ) {
        warn("ERROR:  Failed to set boot-once.\n");
        warn("1) Check that EFI var support is compiled into kernel.\n");
        warn("2) Verify eliloalt works.  You may need to patch it to support sysfs EFI vars.\n");
        return undef;
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

