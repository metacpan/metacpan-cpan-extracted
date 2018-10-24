package File::Slurp;

use strict;
use warnings ;

our $VERSION = '9999.23';
$VERSION = eval $VERSION;

use Carp ;
use Exporter qw(import);
use Fcntl qw( :DEFAULT ) ;
use File::Spec;
use POSIX qw( :fcntl_h ) ;
use Errno ;

my @std_export = qw(
	read_file
	write_file
	overwrite_file
	append_file
	read_dir
) ;

my @edit_export = qw(
	edit_file
	edit_file_lines
) ;

my @abbrev_export = qw(
	rf
	wf
	ef
	efl
) ;

our @EXPORT_OK = (
	@edit_export,
	@abbrev_export,
	qw(
		slurp
		prepend_file
	),
) ;

our %EXPORT_TAGS = (
	'all'	=> [ @std_export, @edit_export, @abbrev_export, @EXPORT_OK ],
	'edit'	=> [ @edit_export ],
	'std'	=> [ @std_export ],
	'abr'	=> [ @abbrev_export ],
) ;

our @EXPORT = @std_export ;

my $max_fast_slurp_size = 1024 * 100 ;

my $is_win32 = $^O =~ /win32/i ;

*slurp = \&read_file ;
*rf = \&read_file ;

sub read_file {

	my $file_name = shift ;
	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : { @_ } ;

# this is the optimized read_file for shorter files.
# the test for -s > 0 is to allow pseudo files to be read with the
# regular loop since they return a size of 0.

	if ( !ref $file_name && -e $file_name && -s _ > 0 &&
	     -s _ < $max_fast_slurp_size && !%{$opts} && !wantarray ) {


		my $fh ;
		unless( sysopen( $fh, $file_name, O_RDONLY ) ) {

			@_ = ( $opts, "read_file '$file_name' - sysopen: $!");
			goto &_error ;
		}

		my $read_cnt = sysread( $fh, my $buf, -s _ ) ;

		unless ( defined $read_cnt ) {

			@_ = ( $opts,
				"read_file '$file_name' - small sysread: $!");
			goto &_error ;
		}

		$buf =~ s/\015\012/\n/g if $is_win32 ;
		return $buf ;
	}

# set the buffer to either the passed in one or ours and init it to the null
# string

	my $buf ;
	my $buf_ref = $opts->{'buf_ref'} || \$buf ;
	${$buf_ref} = '' ;

	my( $read_fh, $size_left, $blk_size ) ;

# deal with ref for a file name
# it could be an open handle or an overloaded object

	if ( ref $file_name ) {

		my $ref_result = _check_ref( $file_name ) ;

		if ( ref $ref_result ) {

# we got an error, deal with it

			@_ = ( $opts, $ref_result ) ;
			goto &_error ;
		}

		if ( $ref_result ) {

# we got an overloaded object and the result is the stringified value
# use it as the file name

			$file_name = $ref_result ;
		}
		else {

# here we have just an open handle. set $read_fh so we don't do a sysopen

			$read_fh = $file_name ;
			$blk_size = $opts->{'blk_size'} || 1024 * 1024 ;
			$size_left = $blk_size ;
		}
	}

# see if we have a path we need to open

	unless ( $read_fh ) {

# a regular file. set the sysopen mode

		my $mode = O_RDONLY ;

#printf "RD: BINARY %x MODE %x\n", O_BINARY, $mode ;

		$read_fh = local( *FH ) ;
#		$read_fh = gensym ;
		unless ( sysopen( $read_fh, $file_name, $mode ) ) {
			@_ = ( $opts, "read_file '$file_name' - sysopen: $!");
			goto &_error ;
		}

		if ( my $binmode = $opts->{'binmode'} ) {
			binmode( $read_fh, $binmode ) ;
		}

# get the size of the file for use in the read loop

		$size_left = -s $read_fh ;

#print "SIZE $size_left\n" ;

# we need a blk_size if the size is 0 so we can handle pseudofiles like in
# /proc. these show as 0 size but have data to be slurped.

		unless( $size_left ) {

			$blk_size = $opts->{'blk_size'} || 1024 * 1024 ;
			$size_left = $blk_size ;
		}
	}

# infinite read loop. we exit when we are done slurping

	while( 1 ) {

# do the read and see how much we got

		my $read_cnt = sysread( $read_fh, ${$buf_ref},
				$size_left, length ${$buf_ref} ) ;

# since we're using sysread Perl won't automatically restart the call
# when interrupted by a signal.

		next if $!{EINTR};

		unless ( defined $read_cnt ) {

			@_ = ( $opts, "read_file '$file_name' - loop sysread: $!");
			goto &_error ;
		}

# good read. see if we hit EOF (nothing left to read)

		last if $read_cnt == 0 ;

# loop if we are slurping a handle. we don't track $size_left then.

		next if $blk_size ;

# count down how much we read and loop if we have more to read.

		$size_left -= $read_cnt ;
		last if $size_left <= 0 ;
	}

# fix up cr/lf to be a newline if this is a windows text file

	${$buf_ref} =~ s/\015\012/\n/g if $is_win32 && !$opts->{'binmode'} ;

	my $sep = $/ ;
	$sep = '\n\n+' if defined $sep && $sep eq '' ;

# see if caller wants lines

	if( wantarray || $opts->{'array_ref'} ) {

		use re 'taint' ;

		my @lines = length(${$buf_ref}) ?
			${$buf_ref} =~ /(.*?$sep|.+)/sg : () ;

		chomp @lines if $opts->{'chomp'} ;

# caller wants an array ref

		return \@lines if $opts->{'array_ref'} ;

# caller wants list of lines

		return @lines ;
	}

# caller wants a scalar ref to the slurped text

	return $buf_ref if $opts->{'scalar_ref'} ;

# caller wants a scalar with the slurped text (normal scalar context)

	return ${$buf_ref} if defined wantarray ;

# caller passed in an i/o buffer by reference (normal void context)

	return ;
}

# errors in this sub are returned as scalar refs
# a normal IO/GLOB handle is an empty return
# an overloaded object returns its stringified as a scalarfilename

sub _check_ref {

	my( $handle ) = @_ ;

# check if we are reading from a handle (GLOB or IO object)

	if ( eval { $handle->isa( 'GLOB' ) || $handle->isa( 'IO' ) } ) {

# we have a handle. deal with seeking to it if it is DATA

		my $err = _seek_data_handle( $handle ) ;

# return the error string if any

		return \$err if $err ;

# we have good handle
		return ;
	}

	eval { require overload } ;

# return an error if we can't load the overload pragma
# or if the object isn't overloaded

	return \"Bad handle '$handle' is not a GLOB or IO object or overloaded"
		 if $@ || !overload::Overloaded( $handle ) ;

# must be overloaded so return its stringified value

	return "$handle" ;
}

sub _seek_data_handle {

	my( $handle ) = @_ ;

# DEEP DARK MAGIC. this checks the UNTAINT IO flag of a
# glob/handle. only the DATA handle is untainted (since it is from
# trusted data in the source file). this allows us to test if this is
# the DATA handle and then to do a sysseek to make sure it gets
# slurped correctly. on some systems, the buffered i/o pointer is not
# left at the same place as the fd pointer. this sysseek makes them
# the same so slurping with sysread will work.

	eval{ require B } ;

	if ( $@ ) {

		return <<ERR ;
Can't find B.pm with this Perl: $!.
That module is needed to properly slurp the DATA handle.
ERR
	}

	if ( B::svref_2object( $handle )->IO->IoFLAGS & 16 ) {

# set the seek position to the current tell.

		unless( sysseek( $handle, tell( $handle ), SEEK_SET ) ) {
			return "read_file '$handle' - sysseek: $!" ;
		}
	}

# seek was successful, return no error string

	return ;
}


*wf = \&write_file ;

sub write_file {

	my $file_name = shift ;

# get the optional argument hash ref from @_ or an empty hash ref.

	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

	my( $buf_ref, $write_fh, $no_truncate, $orig_file_name, $data_is_ref ) ;

# get the buffer ref - it depends on how the data is passed into write_file
# after this if/else $buf_ref will have a scalar ref to the data.

	if ( ref $opts->{'buf_ref'} eq 'SCALAR' ) {

# a scalar ref passed in %opts has the data
# note that the data was passed by ref

		$buf_ref = $opts->{'buf_ref'} ;
		$data_is_ref = 1 ;
	}
	elsif ( ref $_[0] eq 'SCALAR' ) {

# the first value in @_ is the scalar ref to the data
# note that the data was passed by ref

		$buf_ref = shift ;
		$data_is_ref = 1 ;
	}
	elsif ( ref $_[0] eq 'ARRAY' ) {

# the first value in @_ is the array ref to the data so join it.

		${$buf_ref} = join '', @{$_[0]} ;
	}
	else {

# good old @_ has all the data so join it.

		${$buf_ref} = join '', @_ ;
	}

# deal with ref for a file name

	if ( ref $file_name ) {

		my $ref_result = _check_ref( $file_name ) ;

		if ( ref $ref_result ) {

# we got an error, deal with it

			@_ = ( $opts, $ref_result ) ;
			goto &_error ;
		}

		if ( $ref_result ) {

# we got an overloaded object and the result is the stringified value
# use it as the file name

			$file_name = $ref_result ;
		}
		else {

# we now have a proper handle ref.
# make sure we don't call truncate on it.

			$write_fh = $file_name ;
			$no_truncate = 1 ;
		}
	}

# see if we have a path we need to open

	unless( $write_fh ) {

# spew to regular file.

		if ( $opts->{'atomic'} ) {

# in atomic mode, we spew to a temp file so make one and save the original
# file name.
			$orig_file_name = $file_name ;
			$file_name .= ".$$" ;
		}

# set the mode for the sysopen

		my $mode = O_WRONLY | O_CREAT ;
		$mode |= O_APPEND if $opts->{'append'} ;
		$mode |= O_EXCL if $opts->{'no_clobber'} ;

		my $perms = $opts->{perms} ;
		$perms = 0666 unless defined $perms ;

#printf "WR: BINARY %x MODE %x\n", O_BINARY, $mode ;

# open the file and handle any error.

		$write_fh = local( *FH ) ;
#		$write_fh = gensym ;
		unless ( sysopen( $write_fh, $file_name, $mode, $perms ) ) {

			@_ = ( $opts, "write_file '$file_name' - sysopen: $!");
			goto &_error ;
		}
	}

	if ( my $binmode = $opts->{'binmode'} ) {
		binmode( $write_fh, $binmode ) ;
	}

	sysseek( $write_fh, 0, SEEK_END ) if $opts->{'append'} ;

#print 'WR before data ', unpack( 'H*', ${$buf_ref}), "\n" ;

# fix up newline to write cr/lf if this is a windows text file

	if ( $is_win32 && !$opts->{'binmode'} ) {

# copy the write data if it was passed by ref so we don't clobber the
# caller's data
		$buf_ref = \do{ my $copy = ${$buf_ref}; } if $data_is_ref ;
		${$buf_ref} =~ s/\n/\015\012/g ;
	}

#print 'after data ', unpack( 'H*', ${$buf_ref}), "\n" ;

# get the size of how much we are writing and init the offset into that buffer

	my $size_left = length( ${$buf_ref} ) ;
	my $offset = 0 ;

# loop until we have no more data left to write

	do {

# do the write and track how much we just wrote

		my $write_cnt = syswrite( $write_fh, ${$buf_ref},
				$size_left, $offset ) ;

# since we're using syswrite Perl won't automatically restart the call
# when interrupted by a signal.

		next if $!{EINTR};

		unless ( defined $write_cnt ) {

			@_ = ( $opts, "write_file '$file_name' - syswrite: $!");
			goto &_error ;
		}

# track how much left to write and where to write from in the buffer

		$size_left -= $write_cnt ;
		$offset += $write_cnt ;

	} while( $size_left > 0 ) ;

# we truncate regular files in case we overwrite a long file with a shorter file
# so seek to the current position to get it (same as tell()).

	truncate( $write_fh,
		  sysseek( $write_fh, 0, SEEK_CUR ) ) unless $no_truncate ;

	close( $write_fh ) ;

# handle the atomic mode - move the temp file to the original filename.

	if ( $opts->{'atomic'} && !rename( $file_name, $orig_file_name ) ) {

		@_ = ( $opts, "write_file '$file_name' - rename: $!" ) ;
		goto &_error ;
	}

	return 1 ;
}

# this is for backwards compatibility with the previous File::Slurp module.
# write_file always overwrites an existing file

*overwrite_file = \&write_file ;

# the current write_file has an append mode so we use that. this
# supports the same API with an optional second argument which is a
# hash ref of options.

sub append_file {

# get the optional opts hash ref
	my $opts = $_[1] ;
	if ( ref $opts eq 'HASH' ) {

# we were passed an opts ref so just mark the append mode

		$opts->{append} = 1 ;
	}
	else {

# no opts hash so insert one with the append mode

		splice( @_, 1, 0, { append => 1 } ) ;
	}

# magic goto the main write_file sub. this overlays the sub without touching
# the stack or @_

	goto &write_file
}

# prepend data to the beginning of a file

sub prepend_file {

	my $file_name = shift ;

#print "FILE $file_name\n" ;

	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

# delete unsupported options

	my @bad_opts =
		grep $_ ne 'err_mode' && $_ ne 'binmode', keys %{$opts} ;

	delete @{$opts}{@bad_opts} ;

	my $prepend_data = shift ;
	$prepend_data = '' unless defined $prepend_data ;
	$prepend_data = ${$prepend_data} if ref $prepend_data eq 'SCALAR' ;

#print "PRE [$prepend_data]\n" ;

	my $err_mode = delete $opts->{err_mode} ;
	$opts->{ err_mode } = 'croak' ;
	$opts->{ scalar_ref } = 1 ;

	my $existing_data = eval { read_file( $file_name, $opts ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"prepend_file '$file_name' - read_file: $!" ) ;
		goto &_error ;
	}

#print "EXIST [$$existing_data]\n" ;

	$opts->{atomic} = 1 ;
	my $write_result =
		eval { write_file( $file_name, $opts,
		       $prepend_data, $$existing_data ) ;
	} ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"prepend_file '$file_name' - write_file: $!" ) ;
		goto &_error ;
	}

	return $write_result ;
}

# edit a file as a scalar in $_

*ef = \&edit_file ;

sub edit_file(&$;$) {

	my( $edit_code, $file_name, $opts ) = @_ ;
	$opts = {} unless ref $opts eq 'HASH' ;

# 	my $edit_code = shift ;
# 	my $file_name = shift ;
# 	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

#print "FILE $file_name\n" ;

# delete unsupported options

	my @bad_opts =
		grep $_ ne 'err_mode' && $_ ne 'binmode', keys %{$opts} ;

	delete @{$opts}{@bad_opts} ;

# keep the user err_mode and force croaking on internal errors

	my $err_mode = delete $opts->{err_mode} ;
	$opts->{ err_mode } = 'croak' ;

# get a scalar ref for speed and slurp the file into a scalar

	$opts->{ scalar_ref } = 1 ;
	my $existing_data = eval { read_file( $file_name, $opts ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file '$file_name' - read_file: $!" ) ;
		goto &_error ;
	}

#print "EXIST [$$existing_data]\n" ;

	my( $edited_data ) = map { $edit_code->(); $_ } $$existing_data ;

	$opts->{atomic} = 1 ;
	my $write_result =
		eval { write_file( $file_name, $opts, $edited_data ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file '$file_name' - write_file: $!" ) ;
		goto &_error ;
	}

	return $write_result ;
}

*efl = \&edit_file_lines ;

sub edit_file_lines(&$;$) {

	my( $edit_code, $file_name, $opts ) = @_ ;
	$opts = {} unless ref $opts eq 'HASH' ;

# 	my $edit_code = shift ;
# 	my $file_name = shift ;
# 	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;

#print "FILE $file_name\n" ;

# delete unsupported options

	my @bad_opts =
		grep $_ ne 'err_mode' && $_ ne 'binmode', keys %{$opts} ;

	delete @{$opts}{@bad_opts} ;

# keep the user err_mode and force croaking on internal errors

	my $err_mode = delete $opts->{err_mode} ;
	$opts->{ err_mode } = 'croak' ;

# get an array ref for speed and slurp the file into lines

	$opts->{ array_ref } = 1 ;
	my $existing_data = eval { read_file( $file_name, $opts ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file_lines '$file_name' - read_file: $!" ) ;
		goto &_error ;
	}

#print "EXIST [$$existing_data]\n" ;

	my @edited_data = map { $edit_code->(); $_ } @$existing_data ;

	$opts->{atomic} = 1 ;
	my $write_result =
		eval { write_file( $file_name, $opts, @edited_data ) } ;

	if ( $@ ) {

		@_ = ( { err_mode => $err_mode },
			"edit_file_lines '$file_name' - write_file: $!" ) ;
		goto &_error ;
	}

	return $write_result ;
}

# basic wrapper around opendir/readdir

sub read_dir {

	my $dir = shift ;
	my $opts = ( ref $_[0] eq 'HASH' ) ? shift : { @_ } ;

# this handle will be destroyed upon return

	local(*DIRH);

# open the dir and handle any errors

	unless ( opendir( DIRH, $dir ) ) {

		@_ = ( $opts, "read_dir '$dir' - opendir: $!" ) ;
		goto &_error ;
	}

	my @dir_entries = readdir(DIRH) ;

	@dir_entries = grep( $_ ne "." && $_ ne "..", @dir_entries )
		unless $opts->{'keep_dot_dot'} ;

	if ( $opts->{'prefix'} ) {

		$_ = File::Spec->catfile($dir, $_) for @dir_entries;
	}

	return @dir_entries if wantarray ;
	return \@dir_entries ;
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

	my( $opts, $err_msg ) = @_ ;

# get the error function to use

 	my $func = $err_func{ $opts->{'err_mode'} || 'croak' } ;

# if we didn't find it in our error function hash, they must have set
# it to quiet and we don't do anything.

	return unless $func ;

# call the carp/croak function

	$func->($err_msg) if $func ;

# return a hard undef (in list context this will be a single value of
# undef which is not a legal in-band value)

	return undef ;
}

1;
__END__

=head1 NAME

File::Slurp - Simple and Efficient Reading/Writing/Modifying of Complete Files

=head1 SYNOPSIS

  use File::Slurp;

  # read in a whole file into a scalar
  my $text = read_file( 'filename' ) ;

  # read in a whole file into an array of lines
  my @lines = read_file( 'filename' ) ;

  # write out a whole file from a scalar
  write_file( 'filename', $text ) ;

  # write out a whole file from an array of lines
  write_file( 'filename', @lines ) ;

  # Here is a simple and fast way to load and save a simple config file
  # made of key=value lines.
  my %conf = read_file( $file_name ) =~ /^(\w+)=(.*)$/mg ;
  write_file( $file_name, {atomic => 1}, map "$_=$conf{$_}\n", keys %conf ) ;

  # insert text at the beginning of a file
  prepend_file( 'filename', $text ) ;

  # in-place edit to replace all 'foo' with 'bar' in file
  edit_file { s/foo/bar/g } 'filename' ;

  # in-place edit to delete all lines with 'foo' from file
  edit_file_lines sub { $_ = '' if /foo/ }, 'filename' ;

  # read in a whole directory of file names (skipping . and ..)
  my @files = read_dir( '/path/to/dir' ) ;

=head1 DESCRIPTION

This module provides subs that allow you to read or write entire files
with one simple call. They are designed to be simple to use, have
flexible ways to pass in or get the file contents and to be very
efficient.  There is also a sub to read in all the files in a
directory.

These slurp/spew subs work for files, pipes and sockets, stdio,
pseudo-files, and the C<DATA> handle.

=head1 FUNCTIONS

L<File::Slurp> implements the following functions.

=head2 append_file

	use File::Spec qw(append_file write_file);
	my $res = append_file('/path/to/file', "Some text");
	# same as
	my $res = write_file('/path/to/file', {append => 1}, "Some text");

The C<append_file> function is simply a synonym for the
L<File::Slurp/"write_file"> function, but ensures that the C<append> option is
set.

=head2 edit_file

	use File::Slurp qw(edit_file);
	# perl -0777 -pi -e 's/foo/bar/g' filename
	edit_file { s/foo/bar/g } 'filename';
	edit_file sub { s/foo/bar/g }, 'filename';
	sub replace_foo { s/foo/bar/g }
	edit_file \&replace_foo, 'filename';

The C<edit_file> function reads in a file into C<$_>, executes a code block that
should modify C<$_>, and then writes C<$_> back to the file. The C<edit_file>
function reads in the entire file and calls the code block one time. It is
equivalent to the C<-pi> command line options of Perl but you can call it from
inside your program and not have to fork out a process.

The first argument to C<edit_file> is a code block or a code reference. The
code block is not followed by a comma (as with C<grep> and C<map>) but a code
reference is followed by a comma.

The next argument is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The options are passed through to the
L<File::Slurp/"write_file"> function. All options are described there.
Only the C<binmode> and C<err_mode> options are supported. The call to
L<File::Slurp/"write_file"> has the C<atomic> option set so you will always
have a consistent file.

=head2 edit_file_lines

	use File::Slurp qw(edit_file_lines);
	# perl -pi -e '$_ = "" if /foo/' filename
	edit_file_lines { $_ = '' if /foo/ } 'filename';
	edit_file_lines sub { $_ = '' if /foo/ }, 'filename';
	sub delete_foo { $_ = '' if /foo/ }
	edit_file \&delete_foo, 'filename';

The C<edit_file_lines> function reads each line of a file into C<$_>, and
executes a code block that should modify C<$_>. It will then write C<$_> back
to the file. It is equivalent to the C<-pi> command line options of Perl but
you can call it from inside your program and not have to fork out a process.

The first argument to C<edit_file_lines> is a code block or a code reference.
The code block is not followed by a comma (as with C<grep> and C<map>) but a
code reference is followed by a comma.

The next argument is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The options are passed through to the
L<File::Slurp/"write_file"> function. All options are described there.
Only the C<binmode> and C<err_mode> options are supported. The call to
L<File::Slurp/"write_file"> has the C<atomic> option set so you will always
have a consistent file.

=head2 ef

	use File::Slurp qw(ef);
	# perl -0777 -pi -e 's/foo/bar/g' filename
	ef { s/foo/bar/g } 'filename';
	ef sub { s/foo/bar/g }, 'filename';
	sub replace_foo { s/foo/bar/g }
	ef \&replace_foo, 'filename';

The C<ef> function is simply a synonym for the L<File::Slurp/"edit_file">
function.

=head2 efl

	use File::Slurp qw(efl);
	# perl -pi -e '$_ = "" if /foo/' filename
	efl { $_ = '' if /foo/ } 'filename';
	efl sub { $_ = '' if /foo/ }, 'filename';
	sub delete_foo { $_ = '' if /foo/ }
	efl \&delete_foo, 'filename';

The C<efl> function is simply a synonym for the L<File::Slurp/"edit_file_lines">
function.

=head2 overwrite_file

	use File::Spec qw(overwrite_file);
	my $res = overwrite_file('/path/to/file', "Some text");

The C<overwrite_file> function is simply a synonym for the
L<File::Slurp/"write_file"> function.

=head2 prepend_file

	use File::Slurp qw(prepend_file);
	prepend_file($file, $header);
	prepend_file($file, \@lines);
	prepend_file($file, { binmode => 'raw:'}, $bin_data);

	# equivalent to:
	use File::Slurp qw(read_file write_file);
	my $content = read_file('file_name');
	my $new_content = "hahahaha";
	write_file('file_name', $new_content . $content);

The C<prepend_file> function is the opposite of L<File::Slurp/"append_file"> as
it writes new contents to the beginning of the file instead of the end. It is a
combination of L<File::Slurp/"read_file"> and L<File::Slurp/"write_file">. It
works by first using C<read_file> to slurp in the file and then calling
C<write_file> with the new data and the existing file data.

The first argument to C<prepend_file> is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The options are passed through to the
L<File::Slurp/"write_file"> function. All options are described there.

Only the C<binmode> and C<err_mode> options are supported. The
C<write_file> call has the C<atomic> option set so you will always have
a consistent file.

=head2 read_dir

	use File::Spec qw(read_dir);
	my @files = read_dir('/path/to/dir');
	# all files, even the dots
	my @files = read_dir('/path/to/dir', keep_dot_dot => 1);
	# keep the full file path
	my @paths = read_dir('/path/to/dir', prefix => 1);
	# scalar context
	my $files_ref = read_dir('/path/to/dir');

This function returns a list of the filenames in the supplied directory. In
list context, an array is returned, in scalar context, an array reference is
returned.

The first argument is the path to the directory to read.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The following options are available:

=over

=item

err_mode

The C<err_mode> option has three possible values: C<quiet>, C<carp>, or the
default, C<croak>. In C<quiet> mode, all errors will be silent. In C<carp> mode,
all errors will be emitted as warnings. And, in C<croak> mode, all errors will
be emitted as exceptions. Take a look at L<Try::Tiny> or
L<Syntax::Keyword::Try> to see how to catch exceptions.

=item

keep_dot_dot

The C<keep_dot_dot> option is a boolean option, defaulted to false (C<0>).
Setting this option to true (C<1>) will also return the C<.> and C<..> files
that are removed from the file list by default.

=item

prefix

The C<prefix> option is a boolean option, defaulted to false (C<0>).
Setting this option to true (C<1>) add the directory as a prefix to the file.
The directory and the filename are joined using C<< File::Spec->catfile() >> to
ensure the proper directory separator is used for your OS. See L<File::Spec>.

=back

=head2 read_file

	use File::Slurp qw(read_file);
	my $text = read_file('filename');
	my $bin = read_file('filename', { binmode => ':raw' });
	my @lines = read_file('filename');
	my $lines_ref = read_file('file_name', array_ref => 1);
	my $lines_ref = [ read_file('file_name') ];

	# or we can read into a buffer:
	my $buffer;
	read_file('file_name', buf_ref => \$buffer);

	# or we can set the block size for the read
	my $text_ref = read_file(\*STDIN, blk_size => 10_000_000, array_ref => 1);

	# or we can get a scalar reference
	my $text_ref = read_file('file_name', scalar_ref => 1);

This function reads in an entire file and returns its contents to the
caller. In scalar context it returns the entire file as a single
scalar. In list context it will return a list of lines (using the
current value of C<$/> as the separator, including support for paragraph
mode when it is set to C<''>).

The first argument is the file to be slurped in. It can be a path to a file, an
open file handle (C<\*DATA>, C<\*STDIN>). Overloaded objects use the stringified
file path.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The following options are available:

=over

=item

array_ref

The C<array_ref> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will only have relevance if the C<read_file> function
is called in scalar context. When true, the C<read_file> function will return
a reference to an array of the lines in the file.

=item

binmode

The C<binmode> option is a string option, defaulted to empty (C<''>). If you
set the C<binmode> option, then its value is passed to a call to C<binmode> on
the opened handle. You can use this to set the file to be read in binary mode,
utf8, etc. See C<perldoc -f binmode> for more.

=item

blk_size

You can use this option to set the block size used when slurping from
an already open handle (like C<\*STDIN>). It defaults to 1MB.

=item

buf_ref

The C<buf_ref> option can be used in conjunction with any of the other options.
You can use this option to pass in a scalar reference and the slurped
file contents will be stored in the scalar. This saves an extra copy of
the slurped file and can lower RAM usage vs returning the file. It is
usually the fastest way to read a file into a scalar.

=item

chomp

The C<chomp> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will cause each line to have its contents C<chomp>ed.
This option works in list context or in scalar context with the C<array_ref>
option.

=item

err_mode

The C<err_mode> option has three possible values: C<quiet>, C<carp>, or the
default, C<croak>. In C<quiet> mode, all errors will be silent. In C<carp> mode,
all errors will be emitted as warnings. And, in C<croak> mode, all errors will
be emitted as exceptions. Take a look at L<Try::Tiny> or
L<Syntax::Keyword::Try> to see how to catch exceptions.

=item

scalar_ref

The C<scalar_ref> option is a boolean option, defaulted to false (C<0>). It only
has meaning in scalar context. The return value will be a scalar reference to a
string which is the contents of the slurped file. This will usually be faster
than returning the plain scalar. It will also save memory as it will not make a
copy of the file to return.

=back

=head2 rf

	use File::Spec qw(rf);
	my $text = rf('/path/to/file');

The C<rf> function is simply a synonym for the L<File::Slurp/"read_file">
function.

=head2 slurp

	use File::Spec qw(slurp);
	my $text = slurp('/path/to/file');

The C<slurp> function is simply a synonym for the L<File::Slurp/"read_file">
function.

=head2 wf

	use File::Spec qw(wf);
	my $res = wf('/path/to/file', "Some text");


The C<wf> function is simply a synonym for the
L<File::Slurp/"write_file"> function.

=head2 write_file

	use File::Slurp qw(write_file);
	write_file('filename', @data);
	write_file('filename', {append => 1}, @data);
	write_file('filename', {binmode => ':raw'}, $buffer);
	write_file('filename', \$buffer);
	write_file('filename', $buffer);
	write_file('filename', \@lines);
	write_file('filename', @lines);

	# binmode
	write_file($bin_file, {binmode => ':raw'}, @data);
	write_file($bin_file, {binmode => ':utf8'}, $utf_text);

	# buffered
	write_file($bin_file, {buf_ref => \$buffer});
	write_file($bin_file, \$buffer);
	write_file($bin_file, $buffer);

	# append
	write_file($file, {append => 1}, @data);

	# no clobbering
	write_file($file, {no_clobber => 1}, @data);

This function writes out an entire file in one call. By default C<write_file>
returns C<1> upon successfully writing the file or C<undef> if it encountered
an error. You can change how errors are handled with the C<err_mode> option.

The first argument to C<write_file> is the filename.

The next argument(s) is either a hash reference or a flattened hash,
C<< key => value >> pairs. The following options are available:

=over

=item

append

The C<append> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will cause the data to be be written at the end of
the current file. Internally this sets the C<sysopen> mode flag C<O_APPEND>.

The L<File::Slurp/"append_file"> function sets this option by default.

=item

atomic

The C<atomic> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will cause the file to be be written to in an
atomic fashion. A temporary file name is created by appending the pid
(C<$$>) to the file name argument and that file is spewed to. After the
file is closed it is renamed to the original file name (and C<rename> is
an atomic operation on most OSes). If the program using this were to
crash in the middle of this, then the file with the pid suffix could
be left behind.

=item

binmode

The C<binmode> option is a string option, defaulted to empty (C<''>). If you
set the C<binmode> option, then its value is passed to a call to C<binmode> on
the opened handle. You can use this to set the file to be read in binary mode,
utf8, etc. See C<perldoc -f binmode> for more.

=item

buf_ref

The C<buf_ref> option is used to pass in a scalar reference which has the
data to be written. If this is set then any data arguments (including
the scalar reference shortcut) in C<@_> will be ignored.

=item

err_mode

The C<err_mode> option has three possible values: C<quiet>, C<carp>, or the
default, C<croak>. In C<quiet> mode, all errors will be silent. In C<carp> mode,
all errors will be emitted as warnings. And, in C<croak> mode, all errors will
be emitted as exceptions. Take a look at L<Try::Tiny> or
L<Syntax::Keyword::Try> to see how to catch exceptions.


=item

no_clobber

The C<no_clobber> option is a boolean option, defaulted to false (C<0>). Setting
this option to true (C<1>) will ensure an that existing file will not be
overwritten.

=item

perms

The C<perms> option sets the permissions of newly-created files. This value
is modified by your process's C<umask> and defaults to C<0666> (same as
C<sysopen>).

NOTE: this option is new as of File::Slurp version 9999.14;

=back

=head1 EXPORT

These are exported by default or with

	use File::Slurp qw(:std);
	# read_file write_file overwrite_file append_file read_dir

These are exported with

	use File::Slurp qw(:edit);
	# edit_file edit_file_lines

You can get all subs in the module exported with

	use File::Slurp qw(:all);

=head1 AUTHOR

Uri Guttman, <F<uri@stemsystems.com>>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2003 Uri Guttman. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
