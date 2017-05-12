package FileSlurp_12;

use strict;

use Carp ;
use Fcntl qw( :DEFAULT ) ;
use POSIX qw( :fcntl_h ) ;
use Symbol ;

use base 'Exporter' ;
use vars qw( %EXPORT_TAGS @EXPORT_OK $VERSION @EXPORT ) ;

%EXPORT_TAGS = ( 'all' => [
	qw( read_file write_file overwrite_file append_file read_dir ) ] ) ;

@EXPORT = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT_OK = qw( slurp ) ;

$VERSION = '9999.13';

my $is_win32 = $^O =~ /win32/i ;

# Install subs for various constants that aren't set in older perls
# (< 5.005).  Fcntl on old perls uses Exporter to define subs without a
# () prototype These can't be overridden with the constant pragma or
# we get a prototype mismatch.  Hence this less than aesthetically
# appealing BEGIN block:

BEGIN {
	unless( eval { defined SEEK_SET() } ) {
		*SEEK_SET = sub { 0 };
		*SEEK_CUR = sub { 1 };
		*SEEK_END = sub { 2 };
	}

	unless( eval { defined O_BINARY() } ) {
		*O_BINARY = sub { 0 };
		*O_RDONLY = sub { 0 };
		*O_WRONLY = sub { 1 };
	}

	unless ( eval { defined O_APPEND() } ) {

		if ( $^O =~ /olaris/ ) {
			*O_APPEND = sub { 8 };
			*O_CREAT = sub { 256 };
			*O_EXCL = sub { 1024 };
		}
		elsif ( $^O =~ /inux/ ) {
			*O_APPEND = sub { 1024 };
			*O_CREAT = sub { 64 };
			*O_EXCL = sub { 128 };
		}
		elsif ( $^O =~ /BSD/i ) {
			*O_APPEND = sub { 8 };
			*O_CREAT = sub { 512 };
			*O_EXCL = sub { 2048 };
		}
	}
}

# print "OS [$^O]\n" ;

# print "O_BINARY = ", O_BINARY(), "\n" ;
# print "O_RDONLY = ", O_RDONLY(), "\n" ;
# print "O_WRONLY = ", O_WRONLY(), "\n" ;
# print "O_APPEND = ", O_APPEND(), "\n" ;
# print "O_CREAT   ", O_CREAT(), "\n" ;
# print "O_EXCL   ", O_EXCL(), "\n" ;


*slurp = \&read_file ;

sub read_file {

	my( $file_name, %args ) = @_ ;

# set the buffer to either the passed in one or ours and init it to the null
# string

	my $buf ;
	my $buf_ref = $args{'buf_ref'} || \$buf ;
	${$buf_ref} = '' ;

	my( $read_fh, $size_left, $blk_size ) ;

# check if we are reading from a handle (glob ref or IO:: object)

	if ( ref $file_name ) {

# slurping a handle so use it and don't open anything.
# set the block size so we know it is a handle and read that amount

		$read_fh = $file_name ;
		$blk_size = $args{'blk_size'} || 1024 * 1024 ;
		$size_left = $blk_size ;

# DEEP DARK MAGIC. this checks the UNTAINT IO flag of a
# glob/handle. only the DATA handle is untainted (since it is from
# trusted data in the source file). this allows us to test if this is
# the DATA handle and then to do a sysseek to make sure it gets
# slurped correctly. on some systems, the buffered i/o pointer is not
# left at the same place as the fd pointer. this sysseek makes them
# the same so slurping with sysread will work.

		eval{ require B } ;

		if ( $@ ) {

			@_ = ( \%args, <<ERR ) ;
Can't find B.pm with this Perl: $!.
That module is needed to slurp the DATA handle.
ERR
			goto &_error ;
		}

		if ( B::svref_2object( $read_fh )->IO->IoFLAGS & 16 ) {

# set the seek position to the current tell.

			sysseek( $read_fh, tell( $read_fh ), SEEK_SET ) ||
				croak "sysseek $!" ;
		}
	}
	else {

# a regular file. set the sysopen mode

		my $mode = O_RDONLY ;
		$mode |= O_BINARY if $args{'binmode'} ;

#printf "RD: BINARY %x MODE %x\n", O_BINARY, $mode ;

# open the file and handle any error

		$read_fh = gensym ;
		unless ( sysopen( $read_fh, $file_name, $mode ) ) {
			@_ = ( \%args, "read_file '$file_name' - sysopen: $!");
			goto &_error ;
		}

# get the size of the file for use in the read loop

		$size_left = -s $read_fh ;

		unless( $size_left ) {

			$blk_size = $args{'blk_size'} || 1024 * 1024 ;
			$size_left = $blk_size ;
		}
	}

# infinite read loop. we exit when we are done slurping

	while( 1 ) {

# do the read and see how much we got

		my $read_cnt = sysread( $read_fh, ${$buf_ref},
				$size_left, length ${$buf_ref} ) ;

		if ( defined $read_cnt ) {

# good read. see if we hit EOF (nothing left to read)

			last if $read_cnt == 0 ;

# loop if we are slurping a handle. we don't track $size_left then.

			next if $blk_size ;

# count down how much we read and loop if we have more to read.
			$size_left -= $read_cnt ;
			last if $size_left <= 0 ;
			next ;
		}

# handle the read error

		@_ = ( \%args, "read_file '$file_name' - sysread: $!");
		goto &_error ;
	}

# fix up cr/lf to be a newline if this is a windows text file

	${$buf_ref} =~ s/\015\012/\n/g if $is_win32 && !$args{'binmode'} ;

# this is the 5 returns in a row. each handles one possible
# combination of caller context and requested return type

	my $sep = $/ ;
	$sep = '\n\n+' if defined $sep && $sep eq '' ;

# caller wants to get an array ref of lines

# this split doesn't work since it tries to use variable length lookbehind
# the m// line works.
#	return [ split( m|(?<=$sep)|, ${$buf_ref} ) ] if $args{'array_ref'}  ;
	return [ length(${$buf_ref}) ? ${$buf_ref} =~ /(.*?$sep|.+)/sg : () ]
		if $args{'array_ref'}  ;

# caller wants a list of lines (normal list context)

# same problem with this split as before.
#	return split( m|(?<=$sep)|, ${$buf_ref} ) if wantarray ;
	return length(${$buf_ref}) ? ${$buf_ref} =~ /(.*?$sep|.+)/sg : ()
		if wantarray ;

# caller wants a scalar ref to the slurped text

	return $buf_ref if $args{'scalar_ref'} ;

# caller wants a scalar with the slurped text (normal scalar context)

	return ${$buf_ref} if defined wantarray ;

# caller passed in an i/o buffer by reference (normal void context)

	return ;
}


# error handling section
#
# all the error handling uses magic goto so the caller will get the
# error message as if from their code and not this module. if we just
# did a call on the error code, the carp/croak would report it from
# this module since the error sub is one level down on the call stack
# from read_file/write_file/read_dir.


my %err_func = (
	'carp'	=> \&carp,
	'croak'	=> \&croak,
) ;

sub _error {

	my( $args, $err_msg ) = @_ ;

# get the error function to use

 	my $func = $err_func{ $args->{'err_mode'} || 'croak' } ;

# if we didn't find it in our error function hash, they must have set
# it to quiet and we don't do anything.

	return unless $func ;

# call the carp/croak function

	$func->($err_msg) ;

# return a hard undef (in list context this will be a single value of
# undef which is not a legal in-band value)

	return undef ;
}

1;
