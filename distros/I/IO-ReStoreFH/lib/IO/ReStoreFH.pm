# --8<--8<--8<--8<--
#
# Copyright (C) 2012 Smithsonian Astrophysical Observatory
#
# This file is part of IO::ReStoreFH
#
# IO::ReStoreFH is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package IO::ReStoreFH;

use 5.10.0;

use strict;
use warnings;

use version 0.77; our $VERSION = '0.05';

# In Perl 5.10.1 a use or require of FileHandle or something in the
# FileHandle hierarchy (like FileHandle::Fmode, below) will cause the
# compiler to creat a stash for FileHandle.  Then, there's some
# code in Perl_newio which checks if FileHandle has been loaded (just
# by checking for the stash) and aliases it to IO::Handle.
#
#  This it mucks up method calls on filehandles if FileHandle isn't
#  actually loaded, resulting in errors such as
#
#   Can't locate object method "getline" via package "FileHandle"
#
# see http://perlmonks.org/?node_id=1073753, and tobyink's reply

# So, we explicitly load FileHandle on 5.10.x to avoid these action
# at a distance problems.
use if $^V ge v5.10.0 && $^V lt v5.11.0, 'FileHandle';
use FileHandle::Fmode ':all';

use POSIX qw[ dup dup2 ceil floor ];
use Symbol;
use Carp;

use IO::Handle;
use Scalar::Util qw[ looks_like_number ];
use Try::Tiny;


sub new {

	my $class = shift;

	my $obj = bless { dups => [] }, $class;

	$obj->store( $_ ) for @_;

	return $obj;

}

sub store {

	my ( $self, $fh ) = @_;

	# if $fh is a reference, or a GLOB, it's probably
	# a filehandle object of somesort

	if ( ref( $fh ) || 'GLOB' eq ref( \$fh ) ) {

		# need a glob
		my $glob = 'GLOB' eq ref( $fh ) ? ${$fh} : undef;

		# now that we are sure that everything is loaded,
		# check if it is an open filehandle; this doesn't disambiguate
		# between objects that aren't filehandles or closed filehandles.
		croak( "\$fh is not an open filehandle\n" )
		  unless is_FH( $fh );

		# get access mode; open documentation says mode must
		# match that of original filehandle; do the best we can
		my $mode
		  = is_RO( $fh )                ? '<'
		  : is_WO( $fh )                ? '>'
		  : is_W( $fh ) && is_R( $fh )  ? '+<'
		  :                                undef;


		# give up
		croak(
			"inexplicable error: unable to determine mode for \$fh;\n"
		) if !defined $mode;

		$mode .= '>' if is_A( $fh );

		# dup the filehandle
		open my $dup, $mode . '&', $fh
		  or croak( "error fdopening \$fh: $!\n" );

		push @{ $self->{dups} }, { fh => $fh, mode => $mode, dup => $dup };

	}

	elsif ( looks_like_number( $fh ) && ceil( $fh ) == floor( $fh ) ) {

		# as the caller specifically used an fd, don't go through Perl's
		# IO system
		my $dup = dup( $fh )
		  or croak( "error dup'ing file descriptor $fh: $!\n" );

		push @{ $self->{dups} }, { fd => $fh, dup => $dup };
	}

	else {

		croak(
			"\$fh must be opened Perl filehandle or object or integer file descriptor\n"
		  )

	}

	return;
}

sub restore {

	my $self = shift;

	my $dups = $self->{dups};
	## no critic (ProhibitAccessOfPrivateData)
	while ( my $dup = pop @{$dups} ) {

		if ( exists $dup->{fd} ) {

			dup2( $dup->{dup}, $dup->{fd} )
			  or croak( "error restoring file descriptor $dup->{fd}: $!\n" );

			POSIX::close( $dup->{dup} );

		}

		else {

			open( $dup->{fh}, $dup->{mode} . '&', $dup->{dup} )
			  or croak( "error restoring file handle $dup->{fh}: $!\n" );

			close( $dup->{dup} );

		}

	}

	return;
}



sub DESTROY {

	my $self = shift;

	try {
		$self->restore;
	}
	catch { croak $_ };

	return;
}

__END__

=head1 NAME

IO::ReStoreFH - store/restore file handles


=head1 SYNOPSIS

	use IO::ReStoreFH;

	{
	   my $fhstore = IO::ReStoreFH->new( *STDOUT );

	   open( STDOUT, '>', 'file' );
	} # STDOUT will be restored when $fhstore is destroyed

	# or, one at-a-time
	{
	   my $fhstore = IO::ReStoreFH->new;
	   $store->store( *STDOUT );
	   $store->store( $myfh );

	   open( STDOUT, '>', 'file' );
	   open( $myfh, '>', 'another file' );
	} # STDOUT and $myfh will be restored when $fhstore is destroyed



=head1 DESCRIPTION

Redirecting and restoring I/O streams is straightforward but a chore,
and can lead to strangely silent errors if you forget to restore
STDOUT or STDERR.

B<IO::ReStoreFH> helps keep track of the present state of filehandles and
low-level file descriptors and restores them either explicitly or when
the B<IO::ReStoreFH> object goes out of scope.

It uses the standard Perl filehandle duplication methods (via B<open>)
for filehandles, and uses B<POSIX::dup> and B<POSIX::dup2> for file
descriptors.

File handles and descriptors are restored in the reverse order that
they are stored.

=head1 INTERFACE

=over

=item new

	my $fhstore = IO::ReStoreFH->new;
	my $fhstore = IO::ReStoreFH->new( $fh1, $fh2, $fd, ... );

Create a new object and an optional list of Perl filehandles or
integer file descriptors.

The passed handles and descriptors will be duplicated to be restored
when the object is destroyed or the B<restore> method is called.

=item store

	$fhstore->store( $fh );

	$fhstore->store( $fd );

The passed handles and descriptors will be duplicated to be restored
when the object is destroyed or the B<restore> method is called.

=item restore

   $fhstore->restore;

Restore the stored file handles and descriptors, in the reverse order
that they were stored.  This is automatically called when the object
is destroyed.

=back



=head1 DIAGNOSTICS

=for author to fill in:
	List every single error and warning message that the module can
	generate (even the ones that will "never happen"), with a full
	explanation of each problem, one or more likely causes, and any
	suggested remedies.

=over

=item C<< $fh is not an open filehandle >>

The passed filehandle failed a check to ensure that it was an open
filehandle.  Make sure it's a) a real filehandle; b) it's open.

=item C<< inexplicable error: unable to determine mode for $fh >>

B<IO::ReStoreFH> was unable to get the access mode for the passed file
handle.  Are you sure that it's really a filehandle object?

=item C<< error fdopening %s: %s >>

Perl B<open()> was unable to duplicate the passed filehandle for the
specified reason.

=item C<< error dup'ing file descriptor %s: %s >>

B<POSIX::dup()> was unable to duplicate the passed file descriptor for the
specified reason.

=item C<< $fh must be opened Perl filehandle or object or integer file descriptor >>

The passed C<$fh> argument wasn't recognized as a Perl filehandle or a
file descriptor.  Please try again.

=item C<< error restoring file descriptor %d: %s >>

Attempting to restore the file descriptor failed for the specified reason.

=item C<< error restoring file handle %s: %s >>

Attempting to restore the Perl file handle failed for the specified reason.

=back

=head1 CONFIGURATION AND ENVIRONMENT

B<IO::ReStoreFH> requires no configuration files or environment variables.


=head1 DEPENDENCIES

B<L<Try::Tiny>>, B<L<FileHandle::Fmode>>.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-restorefh@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=IO-ReStoreFH>.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 The Smithsonian Astrophysical Observatory

IO::ReStoreFH is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>
