###############################################################################
# Purpose : Pick the most appropriate resolver
# Author  : John Alden
# Created : Aug 2006
###############################################################################

package Email::MIME::CreateHTML::Resolver;

use strict;
use Carp;
use Scalar::Util ();

our $VERSION = '1.042';

use vars qw($HaveCache $HaveLWP $HaveFilesystem);

$HaveCache = 0;
eval {
	require Email::MIME::CreateHTML::Resolver::Cached;
	$HaveCache = 1;
};

$HaveLWP = 0;
eval {
	require Email::MIME::CreateHTML::Resolver::LWP;
	$HaveLWP = 1;
};

$HaveFilesystem = 0;
eval {
	require Email::MIME::CreateHTML::Resolver::Filesystem;
	$HaveFilesystem = 1;
};


#
# API
#

sub new {
	my ($class, $args) = @_;
	$args ||= {};

	#Do some sanity checking of inputs
	my $resolver = $args->{resolver};
	if(defined $resolver) {
		confess "resolver must be an object" unless Scalar::Util::blessed($resolver);
		confess "resolver does not seem to use the expected interface (get_resource)" unless ($resolver->can('get_resource'));
	}

	my $object_cache = $args->{'object_cache'};
	if(defined $object_cache ) {
		confess "object_cache must be an object" unless Scalar::Util::blessed($object_cache);
		confess "object_cache does not seem to use the expected cache interface (get and set methods)" 
			unless ($object_cache->can('get') && $object_cache->can('set'));
		warn("Caching support is not available - object_cache will not be used") unless($HaveCache);
	}

	#Construct object
	my $self = bless ({
		%$args
	}, $class);	
	return $self;
}

sub get_resource {
	my ($self, $uri) = @_;
	croak("get_resource without a URI") unless(defined $uri && length($uri));
	my $resolver = $self->_select_resolver($uri);
	return $resolver->get_resource($uri);	
}

#
# Private methods
#

sub _select_resolver {
	my ($self, $uri) = @_;	

	#Look at the start of the URI 
	my $start = (defined $self->{base} && length($self->{base}))? $self->{base} : $uri;
	
	#Pick an appropriate resolver...
	my $resolver;
	if($self->{resolver}) {
		#If we've been told to use a specific resolver we'll respect that
		$resolver = $self->{resolver};
	} else {
		#Decide on the best resolver to use - does URL start with protocol://		
		TRACE("Start is $start");
		if($HaveFilesystem && $start =~ /^file:\/\//){
			#Push file URLs through filesystem resolver if available (so File::Policy gets applied)
			$resolver = new Email::MIME::CreateHTML::Resolver::Filesystem($self);
		} elsif($start =~ /^\w+:\/\//) {
			die("External URLs in emails cannot be resolved without the LWP resolver (which is currently not installed)\n") unless($HaveLWP);
			$resolver = new Email::MIME::CreateHTML::Resolver::LWP($self);
		} else {		
			die("Local URLs in emails cannot be resolved without the Filesystem resolver (which is currently not installed)\n") unless($HaveFilesystem);
			$resolver = new Email::MIME::CreateHTML::Resolver::Filesystem($self);
		}
	}

	#Optionally wrap it with caching
	if($HaveCache && defined $self->{'object_cache'} ) {
		$resolver = new Email::MIME::CreateHTML::Resolver::Cached({resolver => $resolver, object_cache => $self->{'object_cache'}});
	}
	
	return $resolver;
}

sub TRACE {}
sub DUMP {}

1;


=head1 NAME

Email::MIME::CreateHTML::Resolver - provides the appropriate resource resolver

=head1 SYNOPSIS

	my $o = new Email::MIME::CreateHTML::Resolver(\%args)
	my ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=head1 DESCRIPTION

This is used by Email::MIME::CreateHTML to load resources.

=head1 METHODS

=over 4

=item $o = new Email::MIME::CreateHTML::Resolver(\%args)

=item ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=back

=head1 AUTHOR

Tony Hennessy, Simon Flack and John Alden with additional contributions by
Ricardo Signes <rjbs@cpan.org> and Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT

(c) BBC 2005,2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
