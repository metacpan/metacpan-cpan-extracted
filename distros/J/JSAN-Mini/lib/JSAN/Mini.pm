package JSAN::Mini;

=pod

=head1 NAME

JSAN::Mini - Creates a minimal local mirror of JSAN for offline installation

=head1 SYNOPSIS

  # Update your local minijsan using default settings
  JSAN::Mini->update_mirror;
  
  # ... and for now that's about it :)

=head1 DESCRIPTION

L<minijsan> is an application which scans the JSAN index and ensures that
the release tarballs for all of the libraries in the index are stored in
the local mirror provided by L<JSAN::Transport>.

This allows for the installation of JSAN packages without the need to
connect to the internet. For example, it can be very useful for installing
packaging while on international flights for example :)

C<JSAN::Mini> provides the primary API for implementing the functionality
for L<minijsan>, and also provides something that you can sub-class, and
thus add your own additional functionality.

If you're a normal user, or you are ot going to do anything weird, you might
want to look at L<minijsan> instead.

=head1 METHODS

=cut

use 5.006;
use strict;
use Params::Util '_INSTANCE';
use JSAN::Transport;
use JSAN::Index;

our $VERSION = '1.04';





#####################################################################
# Static Methods

=pod

=head2 update_mirror

The C<update_mirror> static method creates and executes a new L<JSAN::Mini>
object using the default params, normally pretty much Doing What You Mean.

=cut

sub update_mirror {
	my $class = shift;
	my $self  = $class->new(@_);
	$self->run;
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new value => 'param'

The C<new> constructor creates a new minijsan process.

It takes as argument a set of key/value pairs controlling it.

=over 4

=item verbose

The verbose flag controls the level of debugging output that the
object will produce.

When set to true, it causes process information to be printed to
C<STDOUT>. When set to false (the default) it prints nothing.

=back

Returns a C<JSAN::Mini> object.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	# Create the basic object
	my $self = bless {
		added => 0,
		}, $class;

	$self;
}

=pod

=head2 added

Once the C<JSAN::Mini> object has been C<run>, the C<added> method returns
the number of new releases that were added to the local mirror.

=cut

sub added { $_[0]->{added} }





#####################################################################
# JSAN::Mini Methods

=pod

=head2 run

The C<run> method initiates the minicpan process to syncronize the files
in the local mirror with those on the remote mirror.

Returns the number of new files added to the L<minijsan> mirror.

=cut

sub run {
	my $self = shift;
	$self->{added} = 0;
	$self->_verbose("JSAN::Mini starting...");

	# Add each of the releases
	my @releases = $self->_releases;
	foreach my $release ( @releases ) {
		next if $release->file_mirrored;
		$self->_verbose('Adding ' . $release->source . ' to minijsan');
		$self->add_release( $release );
	}

	# If there is a dist processing step, do that.
	# We use a seperate loop in case there are processing
	# operations that need to run across several files.
	foreach my $release ( @releases ) {
		$self->process_release( $release );
	}

	$self->_verbose('JSAN::Mini run completed.');
	$self->{added};
}

# Find the list of releases
sub _releases {
	my $self = shift;

	$self->_verbose("Generating JSAN::Index::Release list...");
	my @libs     = JSAN::Index::Library->select;
	my @releases = map { $_->release } @libs;
	my %seen     = ();
	@releases    = sort { $a->source cmp $b->source }
	               grep { $seen{$_->id}++ } @releases;
	$self->_verbose('Found ' . scalar(@releases) . ' releases to check');

	@releases;
}

=pod

=head2 add_release $release

The C<add_release> method is called when a release is to be added to the
local mirror.

The method is passed a L<JSAN::Index::Release> object and, by default,
mirrors it from the remote repository.

This is the method that you would typically subclass to add additional
functionality to the module (where such functionality does not on
information contained) in other releases in the repository.

=cut

sub add_release {
	my $self    = shift;
	my $release = _INSTANCE($_[0], 'JSAN::Index::Release') ? shift
		: Carp::croak("JSAN::Mini::add_release was not passed a JSAN::Index::Release object");
	$release->mirror;
	1;
}

=pod

=head2 process_release $release

The optional C<process_release> method can be defined by a C<JSAN::Mini>
sub-class, and can be used as a place to implement extended functionality,
where this functionality requires that all new releases by downloaded
before processing starts.

The method is passed a L<JSAN::Index::Release> object and simply shortcuts
by default.

=cut

sub process_release {
	1;
}

# When in verbose mode (which is all the time for now) print a message
# to STDOUT
sub _verbose {
	my $self = shift;
	if ( $self->{verbose} ) {
		my $msg  = shift;
		$msg =~ s/\n?$/\n/s;
		print $msg;
	}
	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSAN-Mini>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005, 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
