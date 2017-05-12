package File::Misc;
use strict;
use Carp 'croak';
use FileHandle;
use Exporter;
use File::Find;
use File::Path;
use String::Util ':all';
use File::chdir;
use Fcntl ':mode', ':flock';

# version
our $VERSION = '0.10';

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;


#------------------------------------------------------------------------------
# opening POD
#

=head1 NAME

File::Misc -- handy file tools

=head1 Description

File::Misc provides a variety of utilities for working with files.  These
utilities provides tools for reading in, writing out to, and getting
information about files.

=head1 SYNOPSIS

 # slurp in the contents of a file
 $var = slurp('myfile.txt');

 # spit content into a file
 spit 'myfile.txt', $var;

 # get the lines in a file as an array
 @arr = file_lines('myfile.txt');

 # get a list of all the files in a directory
 @arr = files('/my/dir');

 # ensure a file is deleted - if it is already deleted return success
 ensure_unlink('myfile.txt');

 # ensure a file exists, update its date to now
 touch('myfile.txt');

 # many others

=head1 INSTALLATION

File::Misc can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 FUNCTIONS

=cut

#
# opening POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# import/export
#
use vars qw[@EXPORT_OK %EXPORT_TAGS @ISA];
@ISA = 'Exporter';
@EXPORT_OK = qw[
	slurp
	spit
	file_lines
	files
	touch
	
	ensure_dir
	dir_ensure
	
	size
	mod_date mod_time
	mode
	age
	search_inc
	search_isa
	ensure_unlink unlink_ensure
	script_dir
	print_file_contents
	
	file_type
	
	eq_files eq_file ne_files ne_file
	
	build_tree
	mirror_tree
	tree_hash
	lock_file
	
	stat_hash
	
	tmp_path
	tmp_dir
];

%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# import/export
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# slurp
#

=head2 slurp

Returns the contents of the given file

 $var = slurp('myfile.txt');

B<option:> max

Sets the maximum amount in bytes to slurp in.  By default the maximums is 100k.

 # set maximum to 1k
 $var = slurp('myfile.txt', max=>1024);

Set max to 0 to set no maximum.

B<option:> firstline

If true, only slurp in the first line.

 $line = slurp('myfile.txt', firstline=>1);

B<options:> stdout, stderr

If the C<stdout> option is true, then the contents of the file are sent to
STDOUT and are not saved as a scalar at all.  C<slurp> returns true.

 slurp('myfile.txt', stdout=>1);

The C<stderr> option works the same way except that contents are sent to STDERR.
Both options can be set to true, and contents will be sent to both STDOUT and
STDERR.

=cut

sub slurp {
	my ($path, %opts)=@_;
	my ($chunk, $fh, @rv, $max, $stdout, $stderr, $out, $total);
	$total = 0;
	
	# TESTING
	# println subname(); ##i
	
	# don't slurp in more than this amount
	# default is 100K
	if (defined $opts{'max'})
		{ $max = $opts{'max'} }
	else
		{ $max = 102400 }
	
	# send to stdout or stderr
	$stdout = $opts{'stdout'};
	$stderr = $opts{'stderr'};
	$out = $opts{'stdout'} || $opts{'stderr'};
	
	# attempt to open
	unless ($fh = FileHandle->new($path)){
		$opts{'quiet'} and return undef;
		croak "slurp: could not open file [$path] for reading: $!";
	}
	
	$fh->binmode($fh) if $opts{'bin'};
	
	# if first line only
	if ($opts{'firstline'}) {
		$chunk = <$fh>;
		$chunk =~ s|[\r\n]+$||s;
		
		# output to stdout and|or stderr
		if ($stdout)
			{ print STDOUT $chunk }
		if ($stderr)
			{ print STDERR $chunk }
		if ($out)
			{ return 1 }
		
		# return
		return $chunk;
	}
	
	# slurp in everything
	CHUNKLOOP:
	while (read $fh, $chunk, 1024) {
		push @rv, $chunk;
		$total += length($chunk);
		
		# output to stdout and|or stderr
		if ($stdout)
			{ print STDOUT $chunk }
		if ($stderr)
			{ print STDERR $chunk }
		
		if ( $max && ($total > $max) ) {
			if ($out)
				{ return 1 }
			
			# we're done reading in
			last CHUNKLOOP;
		}
	}
	
	# return
	return join('', @rv);
}
#
# slurp
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# spit
#

=head2 spit

The opposite of slurp(), spit() outputs the given string(s) to the given file
in a single command. In its simplest form, C<spit> takes a file path, then one
or more strings. Those strings are concatenated together and output the given
path. So, the following code outputs "hello world" to /tmp/myfile.txt.

 spit('/tmp/myfile.txt', 'hello world');

If you want to append to the file (if it exists) then the first param should be
a hashref, with 'path' set to the path to the file and 'append' set to true,
like as follows.

 spit(
   {path=>'/tmp/myfile.txt', append=>1},
   'hello world'
 );

=cut

sub spit {
	my ($path, @data) = @_;
	my ($out, $opentype);
	
	if (ref $path) {
		my $opts = $path;
		$path = $opts->{'path'};
		
		if ($opts->{'append'})
			{ $opentype = '>>' }
		else
			{ $opentype = '>' }
	}
	
	else {
		$opentype = '>';
	}
	
	#$out = FileHandle->new("$opentype $path")
	#	or croak "cannot open output file handle to $path: $!";
	
	open($out, $opentype , $path) or die $!;
	
	# print out data
	print $out @data;
}
#
# spit
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# file_lines
#

=head2 file_lines

Cfile_lines> returns the contents of one or more files as an array. Newlines
are stripped off the end of each line. So, for example, the following code
would the lines from buffer.txt:

 @lines = file_lines('buffer.txt');

If the first param is an arrayref, then every file in the array is read. So,
the following code returns lines from buffer.txt and data.txt.

 @lines = file_lines(['buffer.txt', 'data.txt']);

B<option: max>

C<max> sets the maximum number of lines to return. So, the following code
indicates to send no more than 100 lines.

 @lines = file_lines('buffer.txt', max=>100);

B<option: quiet>

If the C<quiet> option is true, then C<file_lines> does not croak on error.
For example:

 @lines = file_lines('buffer.txt', quiet=>1);

B<option: skip_empty>

If C<skip_empty> is true, then empty lines are not returned. Note that a line
with just spaces or tabs is considered empty.

 @lines = file_lines('buffer.txt', skip_empty=>1);

=cut

sub file_lines {
	my ($paths, %opts)=@_;
	my ($total, $max, @rv, $skipempty);
	
	# initialize total to zero
	$total = 0;
	
	# ensure paths is an array ref
	ref($paths) or $paths = [$paths];
	
	# default options
	%opts = (max=>0, %opts);
	
	# maximum number of lines
	$max = $opts{'max'};
	
	# if we should skip empty lines
	$skipempty = $opts{'skipempty'} || $opts{'skip_empty'};
	
	# loop through paths
	FILELOOP:
	foreach my $path (@$paths) {
		my ($fh);
		
		# open file
		unless ($fh = FileHandle->new($path)){
			$opts{'quiet'} and next FILELOOP;
			croak "could not open $path for reading: $!";
		}
		
		# ensure bonary mode
		$fh->binmode($fh) if $opts{'bin'};
		
		# loop through lines
		LINELOOP:
		while (my $line = <$fh>) {
			# remove trailing newline
			$line =~ s|[\r\n]+$||s;
			
			# skip empty lines if options indicate to do so
			if ($skipempty) {
				unless ($line =~ m|\S|s)
					{ next LINELOOP }
			}
			
			# add to return array
			push @rv, $line;
			
			# add to total number of lines
			$total++;
			
			# finished looping if max is reached
			if ( defined($max) && ($max > 0) && ($total > $max) )
				{ last FILELOOP }
		}
	}
	
	# return
	return @rv;
}
#
# file_lines
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# size
#

=head2 size

Returns the size of the given file. If the file doesn't exist, returns undef.

=cut

sub size {
	my ($path) = @_;
	my (@stats);
	
	# if file doesn't exist, return undef
	if (! -e $path)
		{ return undef }
	
	# get file stats
	@stats = stat($path);
	
	# return size
	return $stats[7];
}
#
# size
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# mod_date
#

=head2 mod_time

Returns the modification time (in epoch seconds) of the given file. If the file
doesn't exist, returns undef.

 print 'modification time: ', mod_time('myfile.txt'), "\n";

If you are familiar with the stat() function, then it may clarify to know that
C<mod_time> simply returns the ninth element of stat().

=head2 mod_date

C<mod_date> does exactly the same thing as C<mod_time>.

=cut

sub mod_time {
	my ($path) = @_;
	my (@stats);
	
	@stats = stat($path);
	return $stats[9];
}

sub mod_date {
	return mod_time(@_);
}
#
# mod_date
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# age
#

=head2 age

C<age()> returns the number of seconds since the given file has been modifed.

 print 'file age: ', age('myfile.txt'), "\n";

C<age()> simply returns the current time minus the value of C<mod_time>.

=cut

sub age {
	my ($path) = @_;
	my ($mod_time);
	
	$mod_time = mod_time($path);
	
	return(time() - $mod_time);
}
#
# age
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# files
#

=head2 files

C<files> returns an array of file paths starting at the given directory. In its
simplest use, C<files> is called with just a directory path.

 @myfiles = files('./tmp');

That command will return all files within ./tmp, including recursing into
nested directories.  By default, all paths will be relative to the current
directory, so the file list mught look something like this:

 ./tmp/buffer.txt
 ./tmp/build
 ./tmp/build/myfile.txt

You can get just the file names with the full_path option, described below.

Note that the 

C<files> has several options, explained below.

B<option: recurse>

By default, C<files> recurses directory structures.

B<option: dirs>

B<option: files>

B<option: full_path>

B<option: extensions>

B<option: follow_links>

=cut

sub files {
	my ($base, %opts) = @_;
	my (
		@rv,
		%extensions,
		@alldirs,
		$dirs,
		$files,
		$fullpath,
		$recurse,
		$hidden,
		$prune_file,
		$dir_slash,
		$path_rx,
		$follow_links,
	);
	
	# TESTING
	# println subname(); ##i
	
	# $base must be defined
	if (! defined $base)
		{ croak '$base must be defined' }
	
	$base =~ s|\\|/|sg;
	$base =~ s|/$||sg;
	@alldirs = $base;
	
	# default options
	%opts = (dirs=>1, files=>1, recurse=>1, %opts);
	
	# options
	$dirs = $opts{'dirs'};
	$files = $opts{'files'};
	$recurse = $opts{'recurse'};
	$hidden = $opts{'hidden'};
	$prune_file = $opts{'prune_file'};
	defined($opts{'extension'}) and $opts{'extensions'} = $opts{'extension'};
	$dir_slash = $opts{'dir_slash'} ? '/' : '';
	$follow_links = $opts{'follow_links'};
	
	# full path
	if (defined $opts{'full_path'})
		{ $fullpath = $opts{'full_path'} }
	elsif (defined $opts{'fullpath'})
		{ $fullpath = $opts{'fullpath'} }
	else
		{ $fullpath = 1 }
	
	# hold on to path rx
	$path_rx = $opts{'rx'};
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# build hash of extensions
	#
	do {
		my ($ext_opt);
		
		# get extensions option if it exists
		EXT_LOOP:
		foreach my $key (qw{extensions extension ext exts}) {
			if ( hascontent ($ext_opt = $opts{$key}) ) {
				# enforce as array
				ref($ext_opt) or $ext_opt = [$ext_opt];
				
				# normalize extensions
				grep {s|.*\.||s; $_ = lc($_);} @$ext_opt;
				
				# build %extensions
				@extensions{@$ext_opt} = ();
			}
		}
	};
	#
	# build hash of extensions
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# loop through files in directory and sub-directories
	#
	DIRLOOP:
	while(my $dir = pop @alldirs) {
		# if $dir is actually a normal file and normal files are
		# allowed as root
		if ( $opts{'allow_file_root'} && (! -d $dir) ) {
			push @rv, $dir;
		}
		
		# else loop through files in directory
		else {
			my ($dh);
			opendir($dh, $dir) or croak "opendir($dir): $!";
			
			# read in files in this directory
			READLOOP:
			foreach my $f (readdir $dh) {
				next READLOOP if $f eq '.' or $f eq '..';
				
				# skip hidden files unless directed to show them
				if ( ($f =~ m|^\.|s) && (! $hidden) )
					{ next READLOOP }
				
				$f = "$dir/$f";
				
				# if it's a directory, and it's not a link OR we should follow links,
				# then add to the list of directories to recurse
				if ( -d($f) && ( (! -l($f)) || $follow_links ) ){
					# if there's a prune file
					if (defined($prune_file) && -e("$f/$prune_file"))
						{ next READLOOP }
					
					# add to return array if necessary
					# add / to end of directory name if options indicate to do so
					if ( $dirs && allowed_ext($f, \%extensions) && allowed_rx($f, $path_rx) )
						{ push @rv, $f . $dir_slash }
					
					# add new directory to @alldirs
					$recurse and push @alldirs, $f;
				}
				
				# else it's enough of a "normal" file to add to the return array
				elsif ( $files && allowed_ext($f, \%extensions) && allowed_rx($f, $path_rx) ) {
					push @rv, $f;
				}
			}
		}
	}
	#
	# loop through files in directory and sub-directories
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	
	if (! $fullpath)
		{ grep { s|.*/||s } @rv }
	
	
	# return 
	return @rv;
}


# private sub
sub allowed_rx {
	my ($path, $rx) = @_;
	defined($rx) or return 1;
	
	# return if the path matches the rx
	return $path =~ m|$rx|s;
}


# private sub
sub allowed_ext {
	my ($path, $exts) = @_; 
	%$exts or return 1;
	$path =~ s|.*\.||s;
	$path = lc($path);
	return exists $exts->{$path};
}

#
# files
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# earliest_mod_date
#
#sub earliest_mod_date {
#	my ($roots, %opts) = @_;
#	my ($earliest);
#	
#	# coerce $roots into array
#	if (! ref $roots)
#		{ $roots = [$roots] }
#	
#	# loop through root directories
#	foreach my $root (@$roots) {
#		# if root doesn't exist, throw error
#		if (! -e $root) {
#			croak "no file or directory at $root";
#		}
#		
#		# loop through files
#		foreach my $file (files $root, %opts, allow_file_root=>1) {
#			my $mod_date = mod_date $file;
#			
#			if ( (! defined $earliest) || ($mod_date < $earliest) )
#				{ $earliest = $mod_date }
#		}
#	}
#	
#	# return
#	return $earliest;
#}
#
# earliest_mod_date
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# latest_mod_date
#
#sub latest_mod_date {
#	my ($roots, %opts) = @_;
#	my ($latest);
#	
#	# coerce $roots into array
#	if (! ref $roots)
#		{ $roots = [$roots] }
#	
#	# loop through root directories
#	foreach my $root (@$roots) {
#		# loop through files
#		foreach my $file (files $root, %opts, allow_file_root=>1) {
#			my $mod_date = mod_date $file;
#			
#			if ( (! defined $latest) || ($mod_date > $latest) )
#				{ $latest = $mod_date }
#		}
#	}
#	
#	# return
#	return $latest;
#}
#
# latest_mod_date
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# search_inc
#

=head2 search_inc

search_inc() searches the @INC directories for a given file and returns the
full path to that file. For example, this command:

 search_inc('JSON/Tiny.pm')

might return somethng like this:

 /usr/local/share/perl/5.18.2/JSON/Tiny.pm

The given path must be the full path within the @INC directory. So, for
example, this command would not return the path to JSON/Tiny.pm:

 search_inc('Tiny.pm')

That feature might be added later.

If you prefer, you can give the path in Perl module format:

 search_inc('JSON::Tiny')

=cut

sub search_inc {
	my ($str) = @_;
	my ($lib, $addpm);
	
	# TESTING
	# println subname(); ##i
	
	# if module is given in format Module::Name then change :: to /
	# also add .pm to end
	if ($str =~ s|::|/|g) {
		my $file = $str;
		$file =~ s|.*/||s;
		
		# if there isn't already an extension
		if ( $file !~ m|\.| )
			{ $str .= '.pm' }
	}
	
	# search through library directories
	foreach $lib (reverse @INC) {
		if (-e "$lib/$str") {
			my $rv = "$lib/$str";
			$rv =~ s|//+|/|gs;
			return $rv;
		}
	}
	
	# if we get this far then the file wasn't found, so return undef
	return undef;
}
#
# search_inc
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# search_isa
#
sub search_isa {
	my ($object, $file_name, %opts) = @_;
	my ($verbose, $indent, @isas, @paths, $object_class);
	
	# TESTING
	# println subname(); ##i
	
	# must have params
	defined($object) or croak 'must have $object';
	defined($file_name) or croak 'must have $file_name';
	
	# load necessarey class
	require Class::ISA;
	
	# verbosify
	if ($opts{'verbose'}) {
		print 'searching @ISA for file : ', $file_name, "\n";
		$indent = indent();
	}
	
	# get class of object
	if (ref $object)
		{ $object_class = ref $object }
	else
		{ $object_class = $object }
	
	# clean up file name
	$file_name =~ s|^/||s;

	# get list of directories in which to look for message file
	@isas = Class::ISA::self_and_super_path($object_class);
	
	# output list of potential directories
	foreach my $isa (@isas) {
		my ($path);
		$isa =~ s|::|/|gs;
		$path = $isa . '/' . $file_name;
		push @paths, $path;
	}
	
	# loop through directories in @INC
	foreach my $dir (@INC) {
		my $dir_use = $dir;
		$dir_use =~ s|/$||s;
		
		# loop through paths
		foreach my $path (@paths) {
			my $full = $dir_use . '/' . $path;
			
			# return if we found the file
			if (-e $full)
				{ return $full }
		}
	}
	
	# didn't find file
	$verbose and print 'did not find file ', $file_name, "\n";
	return undef;
}
#
# search_isa
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# touch
#
sub touch {
	my ($path, %opts) = @_;
	my ($rv);
	
	# if file exists, use utime to update
	if (-e $path) {
		$rv = utime(undef, undef, $path);
	}
	
	# else create file
	else {
		my ($hold_umask);
		
		# hold on to umask if a temporary umask was sent
		if ( defined $opts{'umask'} ) {
			$hold_umask = umask;
			umask($opts{'umask'});
		}
		
		# create file
		$rv = FileHandle->new("> $path") ? 1 : 0;
		
		# set umask back
		if ( defined $opts{'umask'} ) {
			umask($hold_umask);
		}
	}
	
	# return success|failure
	return $rv;
}
#
# touch
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# dirhandle
# private sub
#
sub dirhandle {
	return File::Misc::DirHandle->new(@_);
}
#
# dirhandle
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# ensure_dir
#
sub ensure_dir {
	my ($dir, %opts) = @_;
	
	# create the directory if it doesn't already exist
	if (! -e $dir) {
		my ($rv, $hold_umask);
		
		# hold on to umask if a temporary umask was sent
		if ( defined $opts{'umask'} ) {
			$hold_umask = umask;
			umask($opts{'umask'});
		}
		
		# create directory
		$rv = mkpath($dir);
		
		# set umask back
		if ( defined $opts{'umask'} ) {
			umask($hold_umask);
		}
		
		# return
		return $rv;
	}
	
	# return success
	return 1;
}

# alias dir_ensure to ensure_dir
*dir_ensure = \&ensure_dir;

#
# ensure_dir
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ensure_unlink
#
sub unlink_ensure {
	return ensure_unlink(@_);
}

sub ensure_unlink {
	my ($path) = @_;
	
	if (-e $path) {
		# if it's a directory
		if (-d $path)
			{ return rmtree($path) }
		
		# else file
		return unlink($path);
	}
	
	return 1;
}
#
# ensure_unlink
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# script_dir
#

=head2 script_dir

Returns the directory of the script.  The directory is relative the current
directory when the script was called. Call this command before altering $0.

=cut

sub script_dir {
	my $dir = $0;
	
	# special case: no /
	unless ($dir =~ m|/|s)
		{ return './' }
	
	# remove everything after last /
	$dir =~ s|^(.*)/[^/]*$|$1|s;
	
	# return
	return $dir;
}
#
# script_dir
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# mode
#

=head2 mode

mode() returns the file mode (i.e. type and permissions) of the given path.

=cut

sub mode {
	my ($path) = @_;
	my $mode = (stat($path))[2];
	return S_IMODE($mode);
}
#
# mode
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# build_tree
#
sub build_tree {
	my ($root, @paths) = @_;
	
	# remove trailing / from root
	$root =~ s|/$||s;
	
	# ensure root exists
	if (! -e $root) {
		mkpath($root) or die $!;
	}
	
	# loop through files
	foreach my $path (@paths) {
		my ($full);
		$path =~ s|^/||s;
		$full = "$root/$path";
		
		# if dir
		if ($path =~ m|/$|s) {
			if (! -e $full) {
				mkpath($full) or die $!;
			}
		}
		
		# else create file
		else {
			my ($dir, $rv, $arrows);
			
			
			# create directory
			$dir = $full;
			
			if ($dir =~ s|/[^/]+$||s) {
				if (! -e $dir)
					{ mkpath($dir) or die $! }
			}
			
			if (-e $full)
				{ $arrows = '>>' }
			else
				{ $arrows = '>' }
			
			# $rv = FileHandle->new("$arrows$full") or die $!;
			touch($full) or die $!;
		}
	}
	
	# return success
	return 1;
}
#
# build_tree
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# mirror_tree
#
our %mirror_tree_results;

sub mirror_tree {
	my ($src, $tgt, %opts) = @_;
	my ($verbose, $change_count);
	%mirror_tree_results = ();
	$verbose = $opts{'verbose'};
	
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# if tgt exists, copy as needed
	#
	if (-e $tgt) {
		my ($tgt_files, $src_files);
		$tgt_files = tree_hash($tgt);
		$src_files = tree_hash($src);
		
		# initialize results
		$mirror_tree_results{'dirs_copied'} = 0;
		$mirror_tree_results{'dirs_deleted'} = 0;
		$mirror_tree_results{'files_copied'} = 0;
		$mirror_tree_results{'files_deleted'} = 0;
		$mirror_tree_results{'files_replaced'} = 0;
		
		
		# delete new files in target
		foreach my $tgt_path (sort keys %$tgt_files) {
			my $src_full_path = qq|$src/$tgt_path|;
			
			# if it doesn't exist in src, delete it
			if (! -e $src_full_path) {
				my $tgt_full_path = qq|$tgt/$tgt_path|;
				
				# If it still exists in target (it might
				# have been deleted with a ancestor tree
				# in a previous loop) then delete it.
				if (-e $tgt_full_path) {
					# if it's a directory, rmtree it
					if (-d $tgt_full_path) {
						rmtree($tgt_full_path) or croak $!;
						change_message_during(\%opts);
						$mirror_tree_results{'dirs_deleted'}++;
					}
					
					# else delete the file
					else {
						unlink($tgt_full_path) or croak $!;
						change_message_during(\%opts);
						$mirror_tree_results{'files_deleted'}++;
					}
				}
			}
		}
		
		# add files as needed
		foreach my $src_path (keys %$src_files) {
			my ($tgt_full_path, $src_full_path, $copy);
			$tgt_full_path = qq|$tgt/$src_path|;
			$src_full_path = qq|$src/$src_path|;
			
			# handle situation where src is a dir and target is not
			# by deleting target
			if (
				(-e $tgt_full_path)   &&
				(  -d $src_full_path) &&
				(! -d $tgt_full_path)
				) {
				unlink($tgt_full_path) or die $!;
			}
			
			# if it doesn't exist in tgt, add it
			if (! -e $tgt_full_path) {
				# if dir
				# if ($src_full_path =~ m|/$|s) {
				if (-d $src_full_path) {
					mkpath($tgt_full_path) or die $!;
					change_message_during(\%opts);
					$mirror_tree_results{'dirs_copied'}++;
				}
				
				# else create file
				else {
					my ($dir);
					
					# create directory
					$dir = $tgt_full_path;
					
					if ($dir =~ s|/[^/]+$||s) {
						if (! -e $dir) {
							mkpath($dir) or die $!;
							change_message_during(\%opts);
							$mirror_tree_results{'dirs_copied'}++;
						}
					}
					
					# copy file
					change_message_during(\%opts);
					$mirror_tree_results{'files_copied'}++;
					$copy = 1;
				}
			}
			
			# if file, check if different
			elsif (! -d $src_full_path) {
				require File::Compare;
				
				if (File::Compare::compare($src_full_path, $tgt_full_path)) {
					$copy = 1;
					change_message_during(\%opts);
					$mirror_tree_results{'files_replaced'}++;
				}
			}
			
			# copy file if necessary
			if($copy) {
				my ($result, $dir);
				require File::Copy;
				
				# test for strange problem in which
				$dir = $tgt_full_path;
				$dir =~ s|/[^/]+$||s;
				
				$result = File::Copy::copy($src_full_path, $tgt_full_path);
				
				if (! $result) {
					die $!;
				}
			}
		}
	}
	#
	# if tgt exists, copy as needed
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# else tgt doesn't exist, so just copy entire tree
	#
	else {
		require File::Copy::Recursive;
		File::Copy::Recursive::dircopy($src, $tgt) or die $!;
		
		# set results as full copy
		$mirror_tree_results{'full_copy'} = 1;
	}
	#
	# else tgt doesn't exist, so just copy entire tree
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	
	# initialize change count to 0
	$change_count = 0;
	
	
	# count changes and return
	# use 0E0 for "zero but true"
	foreach my $count (values %mirror_tree_results) {
		$change_count += $count;
	}
	
	if ($change_count && $opts{'change_message_after'})
		{ print $opts{'change_message_after'}, "\n" }
	
	# set to "zero but true" if necessary
	unless ($opts{'return_count'}) {
		$change_count ||= '0E0';
	}
	
	# return success
	return $change_count;
}

sub change_message_during {
	my ($opts) = @_;
	
	if (
		$opts->{'change_message_during'} &&
		(! $opts->{'change_message_during_done'})
		) {
		# print $opts->{'change_message_during'}, "\n";
		$opts->{'change_message_during_done'} = 1;
	}
}
#
# mirror_tree
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tree_hash
#
sub tree_hash {
	my ($root_node) = @_;
	my (@files, %rv);
	
	# change to root
	local $CWD = $root_node;
	
	# get list of files
	@files = files('./');
	grep {$_ =~ s|^\./||s} @files;
	
	# build hash of files
	@rv{@files} = ();
	
	# return
	return \%rv;
}
#
# tree_hash
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# eq_files, ne_files, and aliases
#
sub eq_files {
	my ($path_a, $path_b) = @_;
	require File::Compare;
	return ! File::Compare::compare($path_a, $path_b);
}

sub eq_file { return eq_files(@_) }
sub ne_files { return ! eq_files(@_) }
sub ne_file { return ! eq_files(@_) }
#
# eq_files, ne_files, and aliases
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# file_type
#
#
# default path to file program
#my $file_program_path = '/usr/bin/file';
#
#sub file_type {
#	my ($path, %opts) = @_;
#	my ($bin, $fh, $type);
#	
#	# load Taint::Misc
#	require Taint::Misc;
#	
#	# get path to binary
#	$bin = $opts{'bin_path'} || $file_program_path;
#	
#	# get type from file program
#	$fh = Taint::Misc::pipefrom($bin, '--mime', '--brief', $path);
#	$type = <$fh>;
#	undef $fh;
#	
#	# parse out mime type
#	$type =~ s|;.*||s;
#	$type = lc($type);
#	$type = nospace($type);
#
#	# return
#	return $type;
#}
#
# file_type
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# lock_file
#

# LockFile::Simple provides similar functionality

sub lock_file {
	my ($path, $exclusive, %opts) = @_;
	my ($lock, $mode, $wait);
	
	# determine wait
	if (defined $opts{'wait'})
		{ $wait = $opts{'wait'} }
	else
		{ $wait = 1 }
	
	# must have defined $exclusive
	unless (defined $exclusive)
		{ croak 'must have defined $exclusive' }
	
	# open file handle
	$lock = FileHandle->new(">> $path");
	
	# fail if not able to get filehandle
	if (! $lock) {
		print STDERR "cannot get lock file $path: $!\n";
		return 0;
	}
	
	# get lock mode
	if ($exclusive)
		{ $mode = LOCK_EX }
	else
		{ $mode = LOCK_SH }
	
	# if waiting, get lock, fail if we don't
	if ($wait) {
		flock($lock, $mode) or
			die "unable to lock file: $!";
	}
	
	# if not waiting, add LOCK_NB, don't wait
	else {
		$mode = $mode | LOCK_NB;
		flock($lock, $mode) or return undef;
	}
	
	# return
	return $lock;
}
#
# lock_file
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# stat_hash
#

# field names
my @stat_fields = qw{
	dev
	ino
	mode
	nlink
	uid
	gid
	rdev
	size
	atime
	mtime
	ctime
	blksize
	blocks
};

sub stat_hash {
	my ($path) = @_;
	my (@vals, %rv);
	
	# get values
	@vals = stat($path);
	
	# if no value, return defined false
	@vals or return 0;
	
	# populate hash
	@rv{@stat_fields} = @vals;
	
	# return
	return \%rv;
}
#
# stat_hash
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tmp_path
#

=head2 tmp_path

tmp_path() is for the situation where you want to create a temporary file, then
have that file automatically deleted at the end of your code or code block.

tmp_path() returns a C<File::Misc::Tmp::Path> object. That object stringifies
to a random path. When the object goes out of scope, the file, if it exists, is
deleted. tmp_path() does B<not> create the file, it just deletes the file if
the file exists.

tmp_path() takes one required param: the directory in which the file will go.
Here's a simple example:

 # variables
 my ($tmp, $fh);

 # get temporary path: file is NOT created
 $tmp = tmp_path('./');

 # open a file handle, write stuff to the file, close the handle
 $fh = FileHandle->new("> $tmp") or die $!;
 print $fh "stuff\n";
 undef $fh;

 # do something that might cause a crash
 # if there is a crash, $tmp goes out of scope and deletes the file
 if ( it_could_happen() ) {
   die 'crash!';
 }

 # move the file somewhere else
 rename($tmp, './permanent') or die $!;

 # the file doesn't exist anymore, so when $tmp object
 # goes out of scope, nothing happens

By default, the path consists of the given directory followed by a random
string of four characters. So in the example above, the path would look
something like this:

 ./fZ96

No effort is made to ensure that there isn't already a file with that name. It
is simply assumed that four characters is enough to assure a microscopic (but
non-zero) chance of a name conflict.

Note that L<File::Temp> provides a similar functionality, but there is an
important difference. File::Temp creates the temporay file and returns a
file handle for that file. This is useful for situations where you want to
cache data for use in the current scope. It gets a little trickier, however,
if you want to close the file handle and move the temporary file to a permanent
location. tmp_path simply gives you a path that will be deleted if the file
exists, allowing you manipulate and move the file as you like. File::Temp also
goes to some effort to ensure that there are no name conflicts. What you use is
a matter of needs and taste.

B<option: rand_length>

By default the random string is 4 characters long. rand_length gives a
different length to the string. So, for example, the following code indicates
a random string length of 8:

 $tmp = tmp_path('./', rand_length=>8);

That produces a string like this:

 ./JQd4P6W7

B<option: auto_delete>

If the C<auto_delete> option is sent and is false, then the file is not
actually deleted when the tmp object goes out of scope. For example:

 $tmp = tmp_path('./', auto_delete=>0);

This option might seem to defeat the purpose of tmp_path, but it's useful for
debugging your code.  By setting the object so that it doesn't automatically
delete the file you can look at the contents of the file later to see if it
actually contains what you thought it should.

B<option: extension>

extension allows you to give the path a file extension. For example, the
following code creates a path that ends with '.txt'.

 $tmp = tmp_path('./', extension=>'txt');

B<option: prefix>

prefix indicates a string that should be put after the directory name but
before the random string. So, for example, the following code puts the prefix
"build-" in the file name:

 $tmp = tmp_path('./', prefix=>'build-');

giving us something like

 ./build-J3v1

=cut

sub tmp_path {
	return File::Misc::Tmp::Path->new(@_);
}
#
# tmp_path
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# tmp_dir
#

=head2 tmp_dir

tmp_dir() creates a temporary directory and returns a File::Misc::Tmp::Dir
object.  When the object goes out of scope, the directory is deleted.

=cut

sub tmp_dir {
	return File::Misc::Tmp::Dir->new(@_);
}
#
# tmp_dir
#------------------------------------------------------------------------------



###############################################################################
# File::Misc::DirHandle
#
package File::Misc::DirHandle;
use strict;
use Carp;
use DirHandle;

# debug tools
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class, $path, %opts) = @_;
	my $self = bless {}, $class;
	
	$self->{'dh'} = DirHandle->new($path);
	$self->{'path'} = $path;
	$self->{'untaint'} = $opts{'untaint'};
	$self->{'fullpath'} = $opts{'fullpath'} || $opts{'full_path'};
	
	return $self;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# read
#
sub read {
	my ($self) = @_;
	my ($rv, $untaint);
	
	GETLOOP:
	while (1) {
		$rv = $self->{'dh'}->read;
		
		if (! defined $rv)
			{ return $rv }
		
		if ( $rv !~ m|^\.+$|s ){
			if ($self->{'untaint'}) {
				# Double check that we've got a real file
				# Yeah, I know this is redundant, but I can't
				# help myself.  I just can't untaint without
				# some kind of check.
				if (-e qq|$self->{'path'}/$rv|) {
					unless ($rv =~ m|^(.+)$|s)
						{ die "no-match-for-path:$rv doesn't match m|^(.+)\$|s" }
					$rv = $1;
				}
			}
			
			if ($self->{'fullpath'})
				{ $rv = qq|$self->{'path'}/$rv| }
			
			# return
			return $rv;
		}
	}

	# should never get to this point
	die 'error: should never get to this point';
}
#
# read
#------------------------------------------------------------------------------


#
# File::Misc::DirHandle
###############################################################################


###############################################################################
# File::Misc::Tmp::Path
#
package File::Misc::Tmp::Path;
use strict;
use Carp 'croak';
use String::Util ':all';
use overload '""'=>\&path, fallback=>1;

# debug tools
# use Debug::ShowStuff ':all';

# Objects of this class create a file path (but not the file itself), then
# delete the file upon destruction.

# object overloading
use overload
	'""'     => sub{$_[0]->{'path'}},  # stringification
	fallback => 1;                     # operations not defined here


#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class, $parent_dir, %opts) = @_;
	my $self = bless {}, $class;
	
	# TESTING
	# println subname(); ##i
	# showvar %opts;
	
	# error checking: make sure we got a parent directory
	unless (defined $parent_dir)
		{ croak 'did not get defined parent directory' }
	
	# default options
	%opts = (rand_length=>4, auto_delete => 1, %opts);
	
	# automatically delete upon destruction
	$self->{'auto_delete'} = $opts{'auto_delete'};
	
	# clean up $parent_dir
	$parent_dir =~ s|/+$||s;
	
	# if exact fil name was sent
	if ($opts{'exact_path'} || $opts{'full_path'}) {
		$self->{'path'} = $self->{'file_name'} = $parent_dir;
		$self->{'file_name'} =~ s|^.*/||s;
	}
	
	# else generate file name
	else {
		# error checking: make sure parent directory exists
		unless (-e $parent_dir)
			{ croak qq|directory $parent_dir does not exist| }
		
		# error checking: make sure parent directory is a directory
		unless (-d $parent_dir)
			{ croak qq|$parent_dir is not a directory| }
		
		if (defined $opts{'file_name'}) {
			$self->{'file_name'} = $opts{'file_name'};
			
			# build full path
			$self->{'path'} = $parent_dir . '/' . $self->{'file_name'};
		}
		else {
			while (
				(! defined $self->{'path'}) ||
				(-e $self->{'path'})
				) {
				
				# add random string
				$self->{'file_name'} = randword($opts{'rand_length'});
				
				# untaint file name
				unless ($self->{'file_name'} =~ m|^([a-z0-9]+)$|si)
					{ die 'unable to untaint' }
				$self->{'file_name'} = $1;
				
				# add extension
				if (defined $opts{'extension'})
					{ $self->{'file_name'} .= '.' . $opts{'extension'} }
				
				# begin with prefix if sent
				if (defined $opts{'prefix'})
					{ $self->{'file_name'} = "$opts{'prefix'}$self->{'file_name'}" }
				
				# build full path
				$self->{'path'} = $parent_dir . '/' . $self->{'file_name'};
			}
		}
	}
	
	# return
	return $self;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# path
#
sub path {
	return $_[0]->{'path'};
}
#
# path
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# file_name
#
sub file_name {
	return $_[0]->{'file_name'};
}
#
# file_name
#------------------------------------------------------------------------------


#-----------------------------------------------------------------------
# DESTROY
#
DESTROY {
	my ($self) = @_;
	
	if ( $self->{'auto_delete'} && -e($self->{'path'}) ) {
		unlink($self->{'path'}) or
			die "unable to remove $self->{'path'}: $!";
	}
}
#
# DESTROY
#-----------------------------------------------------------------------


#
# File::Misc::Tmp::Path
###############################################################################



###############################################################################
# File::Misc::Tmp::Dir
#
package File::Misc::Tmp::Dir;
use strict;
use Carp 'croak';
use String::Util ':all';
use File::Path;
use overload '""'=>\&path, fallback=>1;

# debug tools
# use Debug::ShowStuff ':all';

# Objects of this class create a directory, then
# delete the entire temporary directory (including all
# of its contents) upon destruction.


#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class, $parent_dir, %opts) = @_;
	my $self = bless {}, $class;
	
	# default options
	%opts = (auto_delete => 1, %opts);
	
	# automatically rmtree upon destruction
	$self->{'auto_delete'} = $opts{'auto_delete'};
	
	# error checking: make sure we got a parent directory
	unless (defined $parent_dir)
		{ croak 'did not get defined parent directory for Joyis::DirRemover object' }
	
	# error checking: make sure parent directory exists
	unless (-e $parent_dir)
		{ croak qq|directory $parent_dir does not exist| }
	
	# error checking: make sure parent directory is a directory
	unless (-d $parent_dir)
		{ croak qq|$parent_dir is not a directory| }
	
	# normalize path to parent directory
	$parent_dir =~ s|/$||;
	
	# if explicit name of temp directory sent, use that, else generate new
	if (defined $opts{'tmp_name'}) {
		$self->{'path'} = $parent_dir . '/' . $opts{'tmp_name'};
	}

	# else generate own
	else {
		while (
			(! defined $self->{'path'}) ||
			(-e $self->{'path'})
			) {
			$self->{'dir'} = randword(4);
			$self->{'path'} = $parent_dir . '/' . $self->{'dir'};
		}
	}
	
	# create temp directory
	mkdir($self->{'path'}) or
		die "unable to create directory $self->{'path'}: $!";
	
	# return
	return $self;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# path
#
sub path {
	return $_[0]->{'path'};
}
#
# path
#------------------------------------------------------------------------------


#-----------------------------------------------------------------------
# DESTROY
#
DESTROY {
	my ($self) = @_;
	
	if (
		-e($self->{'path'}) &&
		$self->{'auto_delete'}
		) {
		rmtree($self->{'path'}) or
			die "unable to remove $self->{'path'}: $!";
	}
}
#
# DESTROY
#-----------------------------------------------------------------------


#
# File::Misc::Tmp::Dir
###############################################################################



# return true
1;

__END__


#-----------------------------------------------------------------------
# closing pod
#

=head1 TERMS AND CONDITIONS

Copyright (c) 2012-2016 by Miko O'Sullivan.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

Version 0.10.

=head1 HISTORY

=over

=item Version 0.10, Sep 7, 2016

Initial release


=back


=cut

#
# closing pod
#-----------------------------------------------------------------------


#------------------------------------------------------------------------------
# module info
# This info is used by a home-grown CPAN module builder. This info has no use
# in the wild.
#
{
	# include in CPAN distribution
	include : 1,
	
	# allow modules
	allow_modules : {
	},
	
	# test scripts
	test_scripts : {
		'Misc/tests/test.pl' : 1,
		'Misc/tests/my_tmp_file.txt' : 0,
		'Misc/tests/test.txt' : 0,
		'Misc/tests/example.pl' : 0,
	},
}
#
# module info
#------------------------------------------------------------------------------
