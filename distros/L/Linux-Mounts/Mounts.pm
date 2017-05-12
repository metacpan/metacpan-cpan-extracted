#!/usr/bin/perl -w

package Linux::Mounts;

use strict;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our $VERSION = 0.2;

sub new {
	my($proto, $file) = shift;
	my $class = ref($proto) || $proto;
	my $self  = { };

	$file ||= '/proc/mounts';

	if (-e $file || -f $file) {
		if (open (MOUNTS, $file)) {
			$self->{_private}->{num_mounts} = 0;
			while (<MOUNTS>) {
				chomp;
				my $cpt = $self->{_private}->{num_mounts};
				push(@{ $self->{_mountinfo}->[$cpt] }, split(/\s/));
				$self->{_private}->{num_mounts}++;
			}
		}
		close(MOUNTS);
	}

	bless $self, $class;
	
	return $self;
}

sub num_mounts {
	my($self) = @_;

	return $self->{_private}->{num_mounts};
}

sub list_mounts {
	my($self) = @_;

	return $self->{_mountinfo};
}

sub show_mount {
	my($self) = @_;
	my(@lst_f);

	for (my $i = 0; $i < $self->{_private}->{num_mounts}; $i++) {
        	for (my $j = 0; $j < $#{ $self->{_mountinfo} }; $j++) {
			push(@lst_f, $self->{_mountinfo}->[$i][$j]);
        	}
		write;
		undef(@lst_f);
	}

	format STDOUT =
@<<<<<<<<<<<@<<<<<<<<<<<<<<<<<@<<<<<<<<<<<@<<<<<<@<<@<<<
$lst_f[0], $lst_f[1], $lst_f[2], $lst_f[3], $lst_f[4], $lst_f[5]
.

}

sub stat_mount {}

1;

__END__

=head1 NAME 

Linux::Mounts - perl module providing object oriented interface to /proc/mounts

=head1 SYNOPSIS

	use Linux::Mounts;

	my $mtd  = Linux::Mounts->new();
	my $list = $mtd->list_mounts();

	print "Number of mounted file systems : ", $mtd->num_mounts(), "\n\n";

	print "List of mounted file systems :\n";
	for (my $i = 0; $i < $mtd->num_mounts(); $i++) {
		for (my $j = 0; $j < $#{ $list }; $j++) {
			printf("%-15s", $list->[$i][$j]);
		}
		print "\n";
	}

	### or simplier ...

	print "\nList of mounted file systems :\n";
	$mtd->show_mount();

=head1 DESCRIPTION

This module provides an interface to the file /proc/mounts. The implementation 
attempts to resemble to the "mount" linux command.

=head2 METHODS

=item num_mounts

Display the number of mounted file systems.

=item list_mounts 

Provide a double array of the /proc/mounts parameters.

=item show_mounts

Show all the mounted file systems.

=head1 AUTHOR

Stephane Chmielewski 	<snck@free.fr>

=head1 COPYRIGHT

Copyright (C) 2004 Stephane Chmielewski. All rights reserved. 
This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself. 

=cut
