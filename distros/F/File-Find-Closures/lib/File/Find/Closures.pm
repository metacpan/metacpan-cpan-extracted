package File::Find::Closures;
use strict;

use warnings;
no warnings;

use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS );

use Carp qw(carp croak);
use Exporter qw(import);
use File::Basename qw(dirname);
use File::Spec::Functions qw(canonpath no_upwards);
use UNIVERSAL;

$VERSION = '1.11';

@EXPORT_OK   = qw(
	find_regular_files
	find_by_min_size
	find_by_max_size
	find_by_zero_size
	find_by_directory_contains
	find_by_name
	find_by_regex
	find_by_owner
	find_by_group
	find_by_executable
	find_by_writeable
	find_by_umask
	find_by_modified_before
	find_by_modified_after
	find_by_created_before
	find_by_created_after
	);
	
%EXPORT_TAGS = (
	all => \@EXPORT_OK
	);

sub _unimplemented { croak "Unimplemented function!" }

=head1 NAME

File::Find::Closures - functions you can use with File::Find

=head1 SYNOPSIS

	use File::Find;
	use File::Find::Closures qw(:all);

	my( $wanted, $list_reporter ) = find_by_name( qw(README) );

	File::Find::find( $wanted, @directories );
	File::Find::find( { wanted => $wanted, ... }, @directories );

	my @readmes = $list_reporter->();

=head1 DESCRIPTION

I wrote this module as an example of both using closures and using
File::Find. Students are always asking me what closures are good
for, and here's some examples. The functions mostly stand alone (i.e.
they don't need the rest of the module), so rather than creating a 
dependency in your code, just lift the parts you want).

When I use File::Find, I have two headaches---coming up with the
\&wanted function to pass to find(), and acculumating the files.

This module provides the \&wanted functions as a closures that I can
pass directly to find().  Actually, for each pre-made closure, I
provide a closure to access the list of files too, so I don't have to
create a new array to hold the results.

The filenames are the full path to the file as reported by File::Find.

Unless otherwise noted, the reporter closure returns a list of the
filenames in list context and an anonymous array that is a copy (not a
reference) of the original list.  The filenames have been normalized
by File::Spec::canonfile unless otherwise noted.  The list of files
has been processed by File::Spec::no_upwards so that "." and ".." (or
their equivalents) do not show up in the list.


=head2 The closure factories

Each factory returns two closures.  The first one is for find(),
and the second one is the reporter.

=over 4

=item find_regular_files();

Find all regular files.

=cut

sub find_regular_files {	
	my @files = ();
	
	sub { push @files, canonpath( $File::Find::name ) if -f $_ },
	sub { @files = no_upwards( @files ); wantarray ? @files : [ @files ] }
	}

=item find_by_min_size( SIZE );

Find files whose size is equal to or greater than SIZE bytes.

=cut

sub find_by_min_size {
	my $min   = shift;
	
	my @files = ();
	
	sub { push @files, canonpath( $File::Find::name ) if -s $_ >= $min },
	sub { @files = no_upwards( @files ); wantarray ? @files : [ @files ] }
	}

=item find_by_max_size( SIZE );

Find files whose size is equal to or less than SIZE bytes.

=cut

sub find_by_max_size {
	my $min   = shift;
	
	my @files = ();
	
	sub { push @files, canonpath( $File::Find::name ) if -s $_ <= $min },
	sub { @files = no_upwards( @files ); wantarray ? @files : [ @files ] }
	}

=item find_by_zero_size();

Find files whose size is equal to 0 bytes.

=cut

sub find_by_zero_size {
	my $min   = shift;
	
	my @files = ();
	
	sub { push @files, canonpath( $File::Find::name ) if -s $_ == 0 },
	sub { @files = no_upwards( @files ); wantarray ? @files : [ @files ] }
	}

=item find_by_directory_contains( @names );

Find directories which contain files with the same name
as any of the values in @names.

=cut

sub find_by_directory_contains {
	my @contains = @_;
	my %contains = map { $_, 1 } @contains;
	
	my %files = ();

	sub { 
		return unless exists $contains{$_};
		my $dir = dirname( canonpath( $File::Find::name ) );
			
		$files{ $dir }++;
		},


	sub { wantarray ? ( keys %files ) : [ keys %files ] }
	}

=item find_by_name( @names );

Find files with the names in @names.  The result is the name returned
by $File::Find::name normalized by File::Spec::canonfile().

In list context, it returns the list of files.  In scalar context,,
it returns an anonymous array.

This function does not use no_updirs, so if you ask for "." or "..",
that's what you get.

=cut

sub find_by_name {
	my %hash  = map { $_, 1 } @_;
	my @files = ();
	
	sub { push @files, canonpath( $File::Find::name ) if exists $hash{$_} },
	sub { wantarray ? @files : [ @files ] }
	}

=item find_by_regex( REGEX );

Find files whose name match REGEX.

This function does not use no_updirs, so if you ask for "." or "..",
that's what you get.

=cut

sub find_by_regex {
	require File::Spec::Functions;
	require Carp;
	require UNIVERSAL;
	
	my $regex = shift;
	
	unless( UNIVERSAL::isa( $regex, ref qr// ) ) {
		croak "Argument must be a regular expression";
		}
		
	my @files = ();
	
	sub { push @files, 
		File::Spec::Functions::canonpath( $File::Find::name ) if m/$regex/ },
	sub { wantarray ? @files : [ @files ] }
	}

=item find_by_owner( OWNER_NAME | OWNER_UID );

Find files that are owned by the owner with the name OWNER_NAME.
You can also use the owner's UID.

=cut

sub find_by_owner {
	my $id = getpwnam($_[0]);
	   $id = $_ unless defined($id);

	unless( $id =~ /\d+/ ) {
		carp "Uid must be numeric of a valid system user name";
		}

	return _find_by_stat_part_equal( $id, 4 );
	}

=item find_by_group( GROUP_NAME | GROUP_GID );

Find files that are owned by the owner with the name GROUP_NAME.
You can also use the group's GID.

=cut

sub find_by_group {
	my $id = getgrnam( $_[0] );
	   $id = $_ unless defined( $id );

	unless( $id =~ /\d+/ ) {
		carp "Gid must be numeric or a valid system user name";
		}

	return _find_by_stat_part_equal( $id, 5 );
	}

=item find_by_executable();

Find files that are executable.  This may not work on some operating
systems (like Windows) unless someone can provide me with an
alternate version.

=cut

sub find_by_executable {
	my @files = ();
	sub { push @files, canonpath( $File::Find::name )
			if -x },
	sub { wantarray ? @files : [ @files ] }
	}

=item find_by_writeable();

Find files that are writable.  This may not work on some operating
systems (like Windows) unless someone can provide me with an
alternate version.

=cut

sub find_by_writeable {
	my @files = ();
	sub { push @files, canonpath( $File::Find::name )
			if -w },
	sub { wantarray ? @files : [ @files ] }
	}

=item find_by_umask( UMASK );

Find files that fit the umask UMASK.  The files will not have those
permissions.

=cut

sub find_by_umask {
	my ($mask) = @_;

	my @files;

	sub { push @files, canonpath( $File::Find::name )
	       	if ((stat($_))[2] & $mask) == 0},
	sub { wantarray ? @files : [ @files ] }
	}

=item find_by_modified_before( EPOCH_TIME );

Find files modified before EPOCH_TIME, which is in seconds since
the local epoch (I may need to adjust this for some operating
systems).

=cut

sub find_by_modified_before {
	return _find_by_stat_part_lessthan( $_[0], 9 );
	}

=item find_by_modified_after( EPOCH_TIME );

Find files modified after EPOCH_TIME, which is in seconds since
the local epoch (I may need to adjust this for some operating
systems).

=cut

sub find_by_modified_after {
	return _find_by_stat_part_greaterthan( $_[0], 9 );
	}

=item find_by_created_before( EPOCH_TIME );

Find files created before EPOCH_TIME, which is in seconds since
the local epoch (I may need to adjust this for some operating
systems).

=cut

sub find_by_created_before {
	return _find_by_stat_part_lessthan( $_[0], 10 );
	}

=item find_by_created_after( EPOCH_TIME );

Find files created after EPOCH_TIME, which is in seconds since
the local epoch (I may need to adjust this for some operating
systems).

=cut

sub find_by_created_after {
	return _find_by_stat_part_greaterthan( $_[0], 10 );
	}

sub _find_by_stat_part_equal {
	my ($value, $stat_part) = @_;

	my @files;

	sub { push @files, canonpath( $File::Find::name )
	       	if (stat($_))[$stat_part] == $value },
	sub { wantarray ? @files : [ @files ] }
	}

sub _find_by_stat_part_lessthan {
	my ($value, $stat_part) = @_;

	my @files;

	sub { push @files, canonpath( $File::Find::name )
	       	if (stat($_))[$stat_part] < $value },
	sub { wantarray ? @files : [ @files ] }
	}

sub _find_by_stat_part_greaterthan {
	my ($value, $stat_part) = @_;

	my @files;

	sub { push @files, canonpath( $File::Find::name )
	       	if (stat($_))[$stat_part] > $value },
	sub { wantarray ? @files : [ @files ] }
	}


=back

=head1 ADD A CLOSURE

I want to add as many of these little functions as I can, so please
send me ones that you create!

You can follow the examples in the source code, but here is how you
should write your closures.

You need to provide both closures.  Start of with the basic subroutine
stub to do this.  Create a lexical array in the scope of the subroutine.
The two closures will share this variable.  Create two closures: one
of give to C<find()> and one to access the lexical array.

	sub find_by_foo
		{
		my @args = @_;

		my @found = ();

		my $finder   = sub { push @found, $File::Find::name if ... };
		my $reporter = sub { @found };

		return( $finder, $reporter );
		}

The filename should be the full path to the file that you get
from C<$File::Find::name>, unless you are doing something wierd,
like C<find_by_directory_contains()>.

Once you have something, send it to me at C<< <bdfoy@cpan.org> >>. You
must release your code under the Perl Artistic License.

=head1 TO DO

* more functions!

* need input on how things like mod times work on other operating
systems

=head1 SEE ALSO

L<File::Find>

Randal Schwartz's C<File::Finder>, which does the same task but
differently.

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/file-find-closures.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

Some functions implemented by Nathan Wagner, C<< <nw@hydaspes.if.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

"Kanga and Baby Roo Come to the Forest";
