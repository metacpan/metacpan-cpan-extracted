package File::Size;

use 5.006;
use warnings;
use strict;
use File::Find;
use Cwd;
use Number::Bytes::Human qw( format_bytes );
no warnings 'File::Find';
our $VERSION = '0.06';

=pod

=head1 NAME

File::Size - Get the size of files and directories

=head1 SYNOPSIS

Get the size for directory /etc/ with the block size of 1024 while following symbolic links:

 my $obj = File::Size->new(
    dir            => '/etc/',
    blocksize      => 1024,
    followsymlinks => 1,
    humanreadable  => 1
 );
 print $obj->getsize(), "\n";

=head1 DESCRIPTION

File::Size is used to get the size of files and directories.

There are 6 methods you can use:

=over 6

=item B<new>

 There are 4 optional hash values for the new() method:

=over 4

=item C<dir>

The directory you want the module to get the size for it. Default is current working directory.

=item C<blocksize>

The blocksize for the output of getsize() method. default is 1 (output in bytes).

=item C<followsymlinks>

If you want to follow symlinks for directories and files, use this option. The default is not to follow symlinks.

=item C<humanreadable>

If you want output size in human readable format (e.g. 2048 -> 2.0K), set this option to 1.

=back

 You don't have to specify any of those options, which means this is okay:
     print File::Size->new()->getsize(), " bytes\n";
 This is okay too:
     print File::Size->new()->setdir( '/etc/' )->setblocksize( 1024**2 )->getsize(), " MB\n";

=item B<setdir>

Used to set (or get - if called without parameters) the directory.
 Example:
     $obj->setdir( '/etc/' );

=item B<setblocksize>

Used to set (or get - if called without parameters) the block size.
 Example:
     $obj->setblocksize( 1024 );

=item B<setfollowsymlinks>

Used to set if you want to follow symbolic links or not. If called without parmeters, returns the current state.
 Example:
     $obj->setfollowsymlinks( 1 );

=item B<sethumanreadable>

Used to set (or get - if called without parameters) if you want human-readable output sizes.
 Example:
     $obj->sethumanreadable( 1 );

=item B<getsize>

Used to calculate the total size of the directory. Prints output according to the block size you did or didn't specify.

=back

=cut

my $followsymlinks = 0;
my $blocksize = 0;
my $size = 0;

sub new {
	my $class = shift;	
	my %options = @_;
	my $self = \%options;
	bless( $self, $class );
	return $self;
}

sub DESTROY {
	my $self = shift;
	undef( $self );
}

sub setdir {
	my $self = shift;
	$$self{ 'dir' } = shift || return $$self{ 'dir' };
	return $self;
}

sub setblocksize {
	my $self = shift;
	$$self{ 'blocksize' } = shift || return $$self{ 'blocksize' };
	return $self;
}

sub setfollowsymlinks {
	my $self = shift;
	$$self{ 'followsymlinks' } = shift || return $$self{ 'followsymlinks' };
	return $self;
}

sub sethumanreadable {
	my $self = shift;
	$$self{ 'humanreadable' } = shift || return $$self{ 'humanreadable' };
	return $self;
}

sub getsize {
	my $self = shift;
	my %options;
	if ( $$self{ 'followsymlinks' } ) {
		%options = (
			wanted		=> \&_findcb,
			follow		=> 1,	# follow symlinks
			follow_skip => 2	# skip duplicate links, but don't die doing it
		);
	} else {
		%options = (
			wanted		=> \&_findcb
		);
	}
	my $dir = $$self{ 'dir' } || getcwd();
	my $blocksize = $$self{ 'blocksize' } || 1;
	$size = 0; # reset the size counter
	find( \%options, $dir );
	return $$self{ 'humanreadable' } ? format_bytes( $size ) : sprintf( '%d', $size / $blocksize );
}

sub _findcb {
	$size += -s $File::Find::name || 0;
}

1;
