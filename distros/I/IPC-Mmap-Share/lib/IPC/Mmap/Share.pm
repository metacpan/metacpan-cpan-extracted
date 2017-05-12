package IPC::Mmap::Share;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use IPC::Mmap;
use Storable qw(freeze thaw);

use base qw(Exporter);

BEGIN {
	our $VERSION     = 0.03;
}

my $DEBUG = 0;

sub new {
	my $self =  shift(@_) or croak "Error!..I do not even know who I am!..";
	my $class = ref($self) || $self;
	my $size = shift(@_) or croak "Incorrect call to new";
	open(my $FILE,"<","/dev/zero") || die $!;
	my $mmap = create_mmap($size);
	return bless { mmap => $mmap , size => $size },$class;
}

sub create_mmap {
	my $size = shift(@_) or die "Internal error!..Size was not passed to create_mmap";
	open(my $FILE,"<","/dev/zero") || croak $!;
	my $mmap = IPC::Mmap->new($FILE, $size, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS) or croak $!;
	return $mmap;
}

sub set_mmap {
	my $self = shift(@_) or croak "Error...set_mmap is a method call";
	my $mmap = shift(@_) or croak "Error...incorrect call to set_mmap...expected an argument";
	$self->{mmap} = $mmap;
}
	
sub get_mmap {
	my $self = shift(@_) or croak "Error...get_mmap is a method call";
	return $self->{mmap};
}	

sub get_size {
	my $self = shift(@_) or croak "Error...get_size is a method call";
	return $self->{size};
}

sub set {
	my $self = shift(@_);
	my $var =  shift(@_) or croak "Error...You passed no argument or undef to set method";

	my $var_ref = \$var; #saying $var=\$var would create a circular reference, caution!!

	my $serialized = freeze($var_ref) or croak "Internal error...freeze failed...";

	#check that the structure fits the mmaped area...
	croak "Error...you cannot store a structure that is bigger than the size you have allocated in new. Please go back and try an allocation size of at least ".length($serialized)."\n" if (length($serialized) > $self->get_size); 
	
	$DEBUG&&print STDERR "Size is ",length($serialized),"\n";
	my $mmap = $self->get_mmap(); 
	my $size = $self->get_size();
	$mmap->lock() || croak "Internal error...lock failed";
	$mmap->write($serialized,0,$size) || croak "Internal error...write failed";
	$mmap->unlock() || croak "Internal error...unlock failed";
}


sub get {
	my $self = shift(@_);
	my $mmap = $self->get_mmap();
	my $size = $self->get_size();
	my $unserialized;
	$mmap->lock() || croak "Internal error...lock failed";
	$mmap->read($unserialized,0,$size) ||  croak "Internal error...read failed";
	$mmap->unlock() || croak "Internal error...unlock failed";
	my $var_ref = thaw($unserialized) or croak "Error...Unfreezing returned an undefined value...";
	return ${$var_ref};
}

sub lock {
	my $self = shift(@_) or croak "I could not shift the reference to my self";
	my $mmap = $self->get_mmap() or croak "Failed to retrieve mmap object";
	$mmap->lock() || croak "Internal error...lock failed";
	$self->{locked} = 1;
}


sub unlock {
	my $self = shift(@_) or croak "I could not shift the reference to my self";
	my $mmap = $self->get_mmap() or croak "Failed to retrieve mmap object";
	$mmap->unlock() || croak "Internal error...lock failed";
	$self->{locked} = 0;
}

sub is_locked {
	my $self = shift(@_) or croak "I could not shift the reference to my self";
	return 1 if ($self->{locked} == 1);
	return;
}

sub DESTROY {
	my $self = shift(@_) or croak "I could not shift the reference to my self";
	my $mmap = $self->get_mmap() or croak "Failed to retrieve mmap object";
	if ($self->is_locked) { 
		$mmap->unlock() || croak "Internal error...unlock failed";
	}
	return;
}

1;
	
__END__

=head1 NAME

IPC::Mmap::Share - Safely share structures among processes using anonymous mmap.

=head1 SYNOPSIS

	use IPC::Mmap::Share;

	#create an area 10000 bytes big
	my $ref = IPC::Mmap::Share->new(10000);

	#program possibly forks later...
	
	#store the $data (can be either scalar or reference). 
	$ref->set($data);

	#get the data
	my $data = $ref->get;

=head1 DESCRIPTION


=head2 Overview

The IPC::Mmap::Share was born out of the need to share structures among processes that come from the same ancestor. It tries to do so in a very simple and straightforward manner. Just create an IPC::Mmap::Share object, and use set to store your data and get to get it back. 

=head2 Internals

This module uses the IPC::Mmap module internally to carry out its mmap tasks. When a new object is initialized, the module uses anonymous mmap (eg. it does not correspond to any real file, just some internal OS buffers) to create the area where it will be storing its data. Get and set are implemented using Storable, by freezing the variable and later thawing it from its storage. Locks are used to protect both reads from and writes to the mmaped area. 

=head2 Motivation

There are many excellent modules on CPAN which will happily handle all the details of interprocess communication even for complex cases. Some of these modules use shared memory and others use mmap. I needed something that uses b<anonymous> mmap and has a very simple way of operation. For many simple tasks, you may find it useful. For more complex jobs, you may want to take a look at other modules.

=head1 METHODS

=over 8

=item new(SIZE)

Just pick a size for the storage area and initialize the object. Remember that any variable or structure you are going to share must be able to fit in the size you specified. 

=item set(VAR)

This method will store VAR inside the mmaped area. VAR can be a reference to any structure or a simple scalar. 

=item get()

This method will retrieve the stored structure or scalar from the mmaped area and return it. 

=item lock(),unlock()

In case you want to explicitly lock or unlock the structure, you can use these methods.


=head1 WARNING

If the module fails during any of its tasks, it will try to croak. 

Don't try to store an undef value.

Don't try to pass more than one argument to set. All other arguments will be ignored. Likewise, if you try to store an array, only the first element will get through. Instead, store a reference to the array and it will go fine.

Also, please make sure that you do not try to store something bigger than the size you have initialized your object with. The module will croak if something like that occurs. If you do not know what is the serialization length of your structure, try to make a guess. The module unfortunately cannot change the size of the mmaped area after object creation.

If what you are trying to do requires something more complicated than that, there are excellent CPAN modules out there which will probably suit your needs. Also, if your program is going to do LOTS of gets and sets in a short time, you may need a smarter locking mechanism. Again, take a look at these other CPAN modules.

=head1 SEE ALSO

You may find these excellent modules useful: B<IPC::SharedCache>, B<IPC::ShareLite>, B<IPC::Shareable>

=head1 BUGS

Surely there are quite a few. If you see them, report them to the proper authorities!..

=head1 FUTURE WORK

Perhaps IPC::Mmap::Share could conveniently subclass IPC::Mmap instead of being standalone. 

=head1 AUTHOR

IPC::Mmap::Share was written by Athanasios Douitsis  F<E<lt>aduitsis@cpan.orgE<gt>>

=head1 COPYRIGHT

Copyright (c) 2006. Athanasios Douitsis. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See <http://www.perl.com/perl/misc/Artistic.html>

=cut



	
