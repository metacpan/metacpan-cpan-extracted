#!perl
package File::Replace;
use warnings;
use strict;
use Carp;
use warnings::register;
use IO::Handle; # allow method calls on filehandles on older Perls
use File::Temp qw/tempfile/;
use File::Basename qw/fileparse/;
use File::Spec::Functions qw/devnull/;
use File::Copy ();
use Fcntl qw/S_IMODE/;
use Exporter ();
use File::Replace::SingleHandle ();
use File::Replace::DualHandle ();
use File::Replace::Inplace ();
BEGIN {
	require Hash::Util;
	# apparently this wasn't available until 0.06 / Perl 5.8.9
	# since this is just for internal typo prevention,
	# we can fake it when it's not available
	# uncoverable branch false
	# uncoverable condition right
	# uncoverable condition false
	if ($] ge '5.010' || defined &Hash::Util::lock_ref_keys)
		{ Hash::Util->import('lock_ref_keys') }
	else { *lock_ref_keys = sub {} }  # uncoverable statement
}

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

## no critic (RequireArgUnpacking)

our $VERSION = '0.14';

our @EXPORT_OK = qw/ replace replace2 replace3 inplace /;
our @CARP_NOT = qw/ File::Replace::SingleHandle File::Replace::DualHandle File::Replace::Inplace /;

our $GlobalInplace;  ## no critic (ProhibitPackageVars)
sub import {
	my @mine;
	for my $i (reverse 1..$#_)
		{ unshift @mine, splice @_, $i, 1 if $_[$i]=~/^-i|^-D$/ }
	if ( @mine and my @i = grep {/^-i/} @mine ) {
		croak "$_[0]: can't specify more than one -i switch" if @i>1;
		# the following double-check is currently just paranoia, so ignore it in code coverage:
		# uncoverable branch true
		my ($ext) = $i[0]=~/^-i(.*)$/ or croak "failed to parse '$i[0]'";
		my $debug = grep {/^-D$/} @mine;
		$GlobalInplace = File::Replace::Inplace->new(backup=>$ext, debug=>$debug);
	}
	goto &Exporter::import;
}

sub inplace { return File::Replace::Inplace->new(@_) }

our $DISABLE_CHMOD;

my %NEW_KNOWN_OPTS = map {$_=>1} qw/ debug layers create chmod
	perms autocancel autofinish in_fh backup /;
sub new {  ## no critic (ProhibitExcessComplexity)
	my $class = shift;
	@_ or croak "$class->new: not enough arguments";
	# set up the object
	my $filename = shift;
	my $_layers = @_%2 ? shift : undef;
	my %opts = @_;
	for (keys %opts) { croak "$class->new: unknown option '$_'"
		unless $NEW_KNOWN_OPTS{$_} }
	croak "$class->new: can't use autocancel and autofinish at once"
		if $opts{autocancel} && $opts{autofinish};
	unless (defined wantarray) { warnings::warnif("Useless use of $class->new in void context"); return }
	if (defined $opts{create}) { # normalize 'create' values
		   if ( $opts{create} eq 'off' || $opts{create} eq 'no' )
			 { $opts{create} = 'off' }
		elsif ( $opts{create} eq 'now' || $opts{create} eq 'later' )
			 { } # nothing needed
		else { croak "bad value for 'create' option, must be one of off/no/later/now" }
	}
	else { $opts{create} = 'later' } # default
	# create the object
	my $self = bless { chmod=>!$DISABLE_CHMOD, %opts, is_open=>0 }, $class;
	$self->{debug} = \*STDERR if $self->{debug} && !ref($self->{debug});
	if (defined $_layers) {
		exists $self->{layers} and croak "$class->new: layers specified twice";
		$self->{layers} = $_layers }
	lock_ref_keys $self, keys %NEW_KNOWN_OPTS, qw/ ifn ifh ofn ofh is_open setperms /;
	# note: "perms" is the option the user explicitly sets and that options()
	# needs to return, "setperms" is what finish() will actually set
	$self->{setperms} = $self->{perms} if defined $self->{perms};
	# temporary output file
	my ($basename,$path) = fileparse($filename);
	($self->{ofh}, $self->{ofn}) = tempfile( # croaks on error
		".${basename}_XXXXXXXXXX", DIR=>$path, SUFFIX=>'.tmp', UNLINK=>1 );
	binmode $self->{ofh}, $self->{layers} if defined $self->{layers};
	# input file
	#TODO Later: A "noopen" option where the input file just isn't opened?
	my $openmode = defined $self->{layers} ? '<'.$self->{layers} : '<';
	if ( defined $self->{in_fh} ) {
		croak "in_fh appears to be closed" unless defined fileno($self->{in_fh});
		$self->{ifh} = delete $self->{in_fh};
	}
	elsif ( not open $self->{ifh}, $openmode, $filename ) {
		# No such file or directory:
		if ( $!{ENOENT} && ($self->{create} eq 'now' || $self->{create} eq 'later') ) {
			$self->{create} eq 'now' and $openmode = defined $self->{layers} ? '+>'.$self->{layers} : '+>';
			# note we call &devnull() like this because otherwise it would
			# be inlined and we want to be able to mock it for testing
			if ( open $self->{ifh}, $openmode, $self->{create} eq 'now' ? $filename : &devnull() )
				{ $self->{setperms}=oct('666')&~umask unless defined $self->{setperms} }
			else { $self->{ifh}=undef }
		} else { $self->{ifh}=undef }
	}
	if ( !defined $self->{ifh} ) {
		my $e=$!;
		close  $self->{ofh}; $self->{ofh} = undef;
		unlink $self->{ofn}; $self->{ofn} = undef;
		$!=$e;  ## no critic (RequireLocalizedPunctuationVars)
		croak "$class->new: failed to open '$filename': $!" }
	else {
		if (!defined $self->{setperms}) {
			if ($self->{chmod}) {
				# we're providing our own error, don't need the extra warning
				no warnings 'unopened';  ## no critic (ProhibitNoWarnings)
				my (undef,undef,$mode) = stat($self->{ifh})
					or croak "stat failed: $!";
				$self->{setperms} = S_IMODE($mode);
			}
			else { $self->{setperms}=0 }
		}
	}
	$self->{ifn} = $filename;
	# backup
	my $debug_backup='';
	if (defined($self->{backup}) && length($self->{backup})) {
		my $bakfile = $filename . $self->{backup};
		if ( $self->{backup}=~/\*/ ) {
			($bakfile = $self->{backup}) =~ s/\*/$basename/;
			$bakfile = $path.$bakfile;
		}
		croak "backup failed: file '$bakfile' exists" if -e $bakfile;
		#TODO Later: Maybe a backup_link option that uses hard links instead of copy?
		File::Copy::syscopy($filename, $bakfile)
			or croak "backup failed: couldn't copy '$filename' to '$bakfile': $!";
		$debug_backup = ', backup to \''.$bakfile."'";
	}
	# finish init
	$self->{is_open} = 1;
	$self->_debug("$class->new: input '", $self->{ifn},
		"', output '", $self->{ofn}, "', layers ",
		(defined $self->{layers} ? "'".$self->{layers}."'" : 'undef'),
		$debug_backup, "\n");
	return $self;
}

sub replace3 {
	unless (defined wantarray) { warnings::warnif("Useless use of "
		.__PACKAGE__."::replace3 in void context"); return }
	my $repl = __PACKAGE__->new(@_);
	return ($repl->in_fh, $repl->out_fh, $repl);
}

sub replace2 {
	unless (defined wantarray) { warnings::warnif("Useless use of "
		.__PACKAGE__."::replace2 in void context"); return }
	my $repl = __PACKAGE__->new(@_);
	if (wantarray) {
		return (
			File::Replace::SingleHandle->new($repl, 'in'),
			File::Replace::SingleHandle->new($repl, 'out') );
	}
	else {
		return File::Replace::SingleHandle->new($repl, 'onlyout');
	}
}

sub replace {
	unless (defined wantarray) { warnings::warnif("Useless use of "
		.__PACKAGE__."::replace in void context"); return }
	my $repl = __PACKAGE__->new(@_);
	return File::Replace::DualHandle->new($repl);
}

sub is_open  { return !!shift->{is_open} }
sub filename { return   shift->{ifn}     }
sub in_fh    { return   shift->{ifh}     }
sub out_fh   { return   shift->{ofh}     }

sub options {
	my $self = shift;
	my %opts;
	for my $o (keys %NEW_KNOWN_OPTS)
		{ exists $self->{$o} and $opts{$o} = $self->{$o} }
	return wantarray ? %opts : \%opts;
}

our $COPY_DEFAULT_BUFSIZE = 4096;
my %COPY_KNOWN_OPTS = map {$_=>1} qw/ count bufsize less /;
sub copy {  ## no critic (ProhibitExcessComplexity)
	my $self = shift;
	croak ref($self)."->copy: already closed" unless $self->{is_open};
	my $_count = @_%2 ? shift : undef;
	my %opts = @_;
	if (defined $_count) {
		exists $opts{count} and croak ref($self)."->copy: count specified twice";
		$opts{count} = $_count }
	for (keys %opts) { croak ref($self)."->copy: unknown option '$_'"
		unless $COPY_KNOWN_OPTS{$_} }
	$opts{bufsize} = $COPY_DEFAULT_BUFSIZE unless defined $opts{bufsize};
	croak ref($self)."->copy: bad count" unless $opts{count} && $opts{count}=~/\A\d+\z/;
	croak ref($self)."->copy: bad bufsize" unless $opts{bufsize} && $opts{bufsize}=~/\A\d+\z/;
	croak ref($self)."->copy: bad less option" if defined $opts{less}
		&& $opts{less}!~/\A(?:ok|ignore)\z/;
	my $remain = $opts{count};
	while ( $remain>0 && !eof($self->{ifh}) ) {
		my $in = read $self->{ifh}, my $buf,
			$remain > $opts{bufsize} ? $opts{bufsize} : $remain;
		defined $in or croak ref($self)."->copy: read failed: $!";
		print {$self->{ofh}} $buf or croak ref($self)."->copy: write failed: $!";
		$remain -= $in;
	}
	warnings::warnif(ref($self)."->copy: read $remain less characters than requested")
		if $remain && !$opts{less};
	return $opts{count}-$remain;
}

sub finish {
	my $self = shift;
	@_ and warnings::warnif(ref($self)."->finish: too many arguments");
	if (!$self->{is_open}) {
		warnings::warnif(ref($self)."->finish: already closed");
		return }
	my ($ifn,$ifh,$ofn,$ofh) = @{$self}{qw/ifn ifh ofn ofh/};
	@{$self}{qw/ifh ofh ofn ifn is_open/} = (undef) x 5;
	# Note we're being conservative here because if any of the steps fail,
	# then it's fairly safe to assume the following steps will fail too.
	my $fail;
	if ( defined(fileno($ifh)) && !close($ifh) )  ## no critic (ProhibitCascadingIfElse)
		{ $fail = "couldn't close input handle" }
	elsif ( defined(fileno($ofh)) && !close($ofh) )
		{ $fail = "couldn't close output handle" }
	elsif ( $self->{chmod} && !chmod($self->{setperms}, $ofn) )
		{ $fail = "couldn't chmod '$ofn'" }
	elsif ( not rename($ofn, $ifn) )
		{ $fail = "couldn't rename '$ofn' to '$ifn'" }
	if ( defined $fail ) {
		my $e=$!; unlink($ofn); $!=$e;  ## no critic (RequireLocalizedPunctuationVars)
		croak ref($self)."->finish: $fail: $!";
	}
	$self->_debug(ref($self),"->finish: renamed '$ofn' to '$ifn', perms ",
		sprintf('%05o',$self->{setperms}), "\n");
	return 1;
}

sub _cancel {
	my $self = shift;
	my $from = shift;
	if ($from eq 'destroy')
		{ $self->{is_open} and warnings::warnif(ref($self)
			.": unclosed file '".$self->{ifn}."' not replaced!") }
	elsif ($from eq 'cancel')
		{ $self->{is_open} or warnings::warnif(ref($self)."->cancel: already closed") }
	if (!($from eq 'destroy' && !$self->{is_open}))
		{ $self->_debug(ref($self), "->cancel: not replacing input file ",
			(defined $self->{ifn} ? "'$self->{ifn}'" : "(unknown)"),
			(defined $self->{ofn} ? ", will attempt to unlink '$self->{ofn}'" : ""), "\n") }
	my ($ifh,$ofh,$ofn) = @{$self}{qw/ifh ofh ofn/};
	@{$self}{qw/ifh ofh ofn ifn is_open/} = (undef) x 5;
	my $success = 1;
	defined($ifh) and defined(fileno($ifh)) and close($ifh) or $success=0;
	defined($ofh) and defined(fileno($ofh)) and close($ofh) or $success=0;
	defined($ofn) and unlink($ofn);
	if ($success) { return 1 } else { return }
}

sub cancel { return shift->_cancel('cancel') }

sub DESTROY {
	my $self = shift;
	if ($self->{is_open}) {
		   if ($self->{autocancel}) { $self->cancel }
		elsif ($self->{autofinish}) { $self->finish }
	}
	$self->_cancel('destroy');
	return;
}

sub _debug {  ## no critic (RequireArgUnpacking)
	my $self = shift;
	return 1 unless $self->{debug};
	confess "not enough arguments to _debug" unless @_;
	local ($",$,,$\) = (' ');
	return print {$self->{debug}} @_;
}

1;
__END__

=head1 Name

File::Replace - Perl extension for replacing files by renaming a temp file over
the original

=head1 Synopsis

=for comment
REMEMBER to keep these examples in sync with 91_author_pod.t

Next to the normal OO constructor, L<C<new>|/new>, this module provides three
interfaces:

 use File::Replace 'replace3';
 
 my ($infh,$outfh,$repl) = replace3($filename);
 while (<$infh>) {
     # write whatever you like to $outfh here
     print $outfh "X: $_";
 }
 $repl->finish;

The following two provide a bit more magic via tied filehandles:

 use File::Replace 'replace2';
 
 my ($infh,$outfh) = replace2($filename);
 while (<$infh>) {
     print $outfh "Y: $_";
 }
 close $infh;   # closing both handles will
 close $outfh;  # trigger the replace

Or the even more magical single filehandle, in which C<print>, C<printf>, and
C<syswrite> go to the output file; C<binmode> to both; C<fileno> only reports
open/closed status; and the other I/O functions go to the input file:

 use File::Replace 'replace';
 
 my $fh = replace($filename);
 while (<$fh>) {
     # can read _and_ write from/to $fh
     print $fh "Z: $_";
 }
 close $fh;

=head1 Description

This module implements and hides the following pattern for you:

=over

=item 1.

Open a temporary file for output

=item 2.

While reading from the original file, write output to the temporary file

=item 3.

C<rename> the temporary file over the original file

=back

In many cases, in particular on many UNIX filesystems, the C<rename> operation
is atomic*. This means that in such cases, the original filename will always
exist, and will always point to either the new or the old version of the file,
so a user attempting to open and read the file will always be able to do so,
and never see an unfinished version of the file while it is being written.

* B<Warning:> Unfortunately, whether or not a rename will actually be atomic in
your specific circumstances is not always an easy question to answer, as it
depends on exact details of the operating system and file system. Consult your
system's documentation and search the Internet for "atomic rename" for more
details. This module's job is to perform the C<rename>, and it can make
B<no guarantees> as to whether it will be atomic or not.

=head2 Version

This documentation describes version 0.14 of this module.

=head1 Constructors and Overview

The constructors C<< File::Replace->new() >>, C<replace3()>, C<replace2()>, and
C<replace()> take exactly the same arguments, and differ only in their return
values - C<replace2> and C<replace> wrap the functionality of C<File::Replace>
inside C<tie>d filehandles. Note that C<replace3()>, C<replace2()>, and
C<replace()> are normal functions and not methods, don't attempt to call them
as such. If you don't want to import them you can always call them as, for
example, C<File::Replace::replace()>.

 File::Replace->new( $filename );
 File::Replace->new( $filename, $layers );
 File::Replace->new( $filename, option => 'value', ... );
 File::Replace->new( $filename, $layers, option => 'value', ... );
 # replace3(...), replace2(...), and replace(...) take the same arguments

The constructors will open the input file and the temporary output file (the
latter via L<File::Temp|File::Temp>), and will C<die> in case of errors. The
options are described in L</Constructor Options>. It is strongly recommended
that you C<use warnings;>, as then this module will issue warnings which may be
of interest to you.

=head2 C<new>

 use File::Replace;
 my $replace_object = File::Replace->new($filename, ...);

Returns a new C<File::Replace> object. The central methods provided are
C<< ->in_fh >> and C<< ->out_fh >>, which return the input resp. output
filehandle which you can read resp. write, and C<< ->finish >>, which causes
the files to be closed and the replace operation to be performed. There is also
C<< ->cancel >>, which just discards the temporary output file without touching
the input file. Additional helper methods are mentioned below.

C<finish> will C<die> on errors, while C<cancel> will only return a false value
on errors. This module will try to clean up after itself (remove temporary
files) as best it can, even when things go wrong.

Please don't re-C<open> the C<in_fh> and C<out_fh> handles, as this may lead to
confusion.

The method C<< ->is_open >> will return a false value if the replace operation
has been C<finish>ed or C<cancel>ed, or a true value if it is still active
(note that this method does I<not> check the state of the underlying
filehandles). The method C<< ->filename >> returns the filename passed to the
constructor. The method C<< ->options >> in list context returns the options
this object has set (including defaults) as a list of key/value pairs, in
scalar context it returns a hashref of these options.

=head2 C<replace3>

This is a convenience function for shorter code:

 use File::Replace 'replace3';
 my ($in_fh,$out_fh,$repl_obj) = replace3($filename, ...);

is the same as

 use File::Replace;
 my $repl_obj = File::Replace->new($filename, ...);
 my $in_fh    = $repl_obj->in_fh;
 my $out_fh   = $repl_obj->out_fh;

=head2 C<replace2>

 use File::Replace 'replace2';
 my ($input_handle, $output_handle) = replace2($filename, ...);
 my $output_handle = replace2($filename, ...);

In list context, returns a two-element list of two tied filehandles, the first
being the input filehandle, and the second the output filehandle, and the
replace operation (C<finish>) is performed when both handles are C<close>d. In
scalar context, it returns only the output filehandle, and the replace
operation is performed when this handle is C<close>d. This means that C<close>
may C<die> instead of just returning a false value.

You cannot re-C<open> these tied filehandles.

You can access the underlying C<File::Replace> object via
C<< tied(*$handle)->replace >> on both the input and output handle. You can
also access the original, untied filehandles via C<< tied(*$handle)->in_fh >>
and C<< tied(*$handle)->out_fh >>, but please don't C<close> or re-C<open>
these handles as this may lead to confusion.

=head2 C<replace>

 use File::Replace 'replace';
 my $magic_handle = replace($filename, ...);

Returns a single, "magical" tied filehandle. The operations C<print>,
C<printf>, and C<syswrite> are passed through to the output filehandle,
C<binmode> operates on both the input and output handle, and C<fileno> only
reports C<-1> if the C<File::Replace> object is still active or C<undef> if the
replace operation has C<finish>ed or been C<cancel>ed. All other I/O functions,
such as C<< <$handle> >>, C<readline>, C<sysread>, C<seek>, C<tell>, C<eof>,
etc. are passed through to the input handle. You can still access these
operations on the output handle via e.g. C<< eof( tied(*$handle)->out_fh ) >>
or C<< tied(*$handle)->out_fh->tell() >>. The replace operation (C<finish>) is
performed when you C<close> the handle, which means that C<close> may C<die>
instead of just returning a false value.

Re-C<open>ing the handle causes a new underlying C<File::Replace> object to be
created. You should explicitly C<close> the filehandle first so that the
previous replace operation is performed (or C<cancel> that operation). The
"mode" argument (or filename in the case of a two-argument C<open>) may not
contain a read/write indicator (C<< < >>, C<< > >>, etc.), only PerlIO layers.

You can access the underlying C<File::Replace> object via
C<< tied(*$handle)->replace >>. You can also access the original, untied
filehandles via C<< tied(*$handle)->in_fh >> and C<< tied(*$handle)->out_fh >>,
but please don't C<close> or re-C<open> these handles as this may lead to
confusion.

=head2 C<inplace>

This is a shorthand for the constructor of
L<File::Replace::Inplace|File::Replace::Inplace>. That is:

 use File::Replace qw/inplace/;
 my $inplace = inplace(...);

is the same as

 use File::Replace::Inplace;
 my $inplace = File::Replace::Inplace->new(...);

As a special feature, if the import list contains a string beginning with
C<-i>, then a global L<File::Replace::Inplace|File::Replace::Inplace>
object will be set up, so C<ARGV> will be tied from the beginning of the
script. Anything following the C<-i> will be used for the L</backup> option.
The purpose of this feature is to provide a replacement for Perl's C<-i>
command-line switch in oneliners. For example, you can say:

 perl -MFile::Replace=-i.bak -pe 's/foo/bar/g' file1.txt file2.txt

and those files will be edited in-place using this module. In addition,
you may specify a C<-D> "switch" in the import list to enable debugging
output, as in:

 perl -MFile::Replace=-i,-D -pe 's/x/y/g' foo.txt bar.txt

The C<-D> switch currently only affects the "inplace" operations described here,
but this may be expanded upon in the future to enable debugging everywhere.

=head1 Constructor Options

=head2 Filename

A filename. The temporary output file will be created in the same directory as
this file, its name will be based on the original filename, but prefixed with a
dot (C<.>) and suffixed with a random string and an extension of C<.tmp>. If
the input file does not exist (C<ENOENT>), then the behavior will depend on the
L</create> option.

=head2 C<layers>

This option can either be specified as the second argument to the constructors,
or as the C<< layers => '...' >> option in the options hash, but not both. It
is a list of PerlIO layers such as C<":utf8">, C<":raw:crlf">, or
C<":encoding(UTF-16)">. Note that the default layers differ based on operating
system, see L<perlfunc/open>.

=head2 C<create>

This option configures the behavior of the module when the input file does not
exist (C<ENOENT>). There are three modes, which you specify as one of the
following strings. If you need more precise control of the input file, see the
L</in_fh> option - note that C<create> is ignored when you use that option.

=over

=item C<"later"> (default when C<create> omitted or C<undef>)

Instead of the input file, F</dev/null> or its equivalent is opened. This means
that while the output file is being written, the input file name will not
exist, and only come into existence when the rename operation is performed.

=item C<"now">

If the input file does not exist, it is immediately created and opened. There
is currently a potential race condition: if the file is created by another
process before this module can create it, then the behavior is undefined - the
file may be emptied of its contents, or you may be able to read its contents.
This behavior may be fixed and specified in a future version. The race
condition is discussed some more in L</Concurrency and File Locking>.

Currently, this option is implemented by opening the file with a mode of
C<< +> >>, meaning that it is created (clobbered) and opened in read-write
mode. I<However>, that should be considered an implementation detail that is
subject to change. Do not attempt to take advantage of the read-write mode by
writing to the input file - that contradicts the purpose of this module anyway.
Instead, the input file will exist and remain empty until the replace
operation.

=item C<"off"> (or C<"no">)

Attempting to open a nonexistent input file will cause the constructor to
C<die>.

=back

Previous versions of this module included support for other values of the
C<create> option, as well as the C<devnull> option. These were replaced by the
above C<create> options and deprecated in 0.06, and removed as of 0.08. Using
unrecognized options will result in a fatal error. Note that in 0.06,
specifying C<undef> for the C<create> option resulted in a deprecation warning,
that behavior has now been changed so that C<undef> is equivalent to the
C<create> option not being set.

=head2 C<backup>

If you set this option to a non-empty string, then immediately after successfully
opening the input file, it is copied to a file with the same name and the
extension specified by this option (unless you use C<*> characters in the string,
see below). For example, C<< File::Replace->new("test.txt", backup=>".bak") >>
results in a copy of F<test.txt> being made to F<test.txt.bak>. If that file
already exists or something goes wrong with the copy operation, then the
constructor will C<die>.

As with Perl's C<-i> option, if the string contains C<*> characters, then
instead of the string being appended to the filename, each C<*> character is
replaced with the original filename. So for example, if you specify
C<< backup=>'orig_*' >>, then the backup of F<test.txt> will be
F<orig_test.txt> in the same path - I<unlike> Perl's C<-i> option, this
feature cannot be used to move files into a different directory.

B<Warning:> If there is another process writing to the input file or creating files
in the same directory as the input file, there is a potential for race conditions
when using this option!

This option was introduced in version 0.10.

=head2 C<in_fh>

This option allows you to pass an existing input filehandle to this module,
instead of having the constructors open the input file for you. Use this option
if you need more precise control over how the input file is opened, e.g. if you
want to use C<sysopen> to open it. The handle must be open, which will be
checked by calling C<fileno> on the handle. The module makes no attempt to
check that the filename you pass to the module matches the filehandle. The
module will attempt to C<stat> the handle to get its permissions, except when
you have specified the L</perms> option or disabled the L</chmod> option. The
L</create> option is ignored when you use this option.

=head2 C<perms>

 perms => 0640       # ok
 perms => oct("640") # ok
 perms => "0640"     # WRONG!

Normally, just before the C<rename> is performed, C<File::Replace> will
C<chmod> the temporary file to those permissions that the original file had
when it was opened, or, if the original file did not yet exist, default
permissions based on the current C<umask>. Setting this option to an octal
value (a number, not a string!) will override those permissions. See also
L</chmod>, which can be used to disable the C<chmod> operation.

=head2 C<chmod>

This option is enabled by default, unless you set
C<$File::Replace::DISABLE_CHMOD> to a true value. When you disable this option,
the C<chmod> operation that is normally performed just before the C<rename>
will not be attempted. This is mostly intended for systems where you know the
C<chmod> will fail. See also L</perms>, which allows you to define what
permissions will be used.

Note that the temporary files created with L<File::Temp|File::Temp> will have
0600 permissions if left unchanged (except of course on systems that don't
support these kind of restrictive permissions).

=head2 C<autocancel>

If the C<File::Replace> object is destroyed (e.g. when it goes out of scope),
and the replace operation has not been performed yet, normally it will
C<cancel> the replace operation and issue a warning. Enabling this option makes
that implicit canceling explicit, silencing the warning.

This option cannot be used together with C<autofinish>.

=head2 C<autofinish>

When set, causes the C<finish> operation to be attempted when the object is
destroyed (e.g. when it goes out of scope).

However, using this option is actually B<not recommended> unless you know what
you are doing. This is because the replace operation will also be attempted
when your script is C<die>ing, in which case the output file may be incomplete,
and you may not want the original file to be replaced. A second reason is that
the replace operation may be attempted during global destruction, and it is not
a good idea to rely on this always going well. In general it is better to
C<finish> the replace operation explicitly.

This option cannot be used together with C<autocancel>.

=head2 C<debug>

If set to a true value, this option enables some debug output for C<new>,
C<finish>, and C<cancel>. You may also set this to a filehandle, and debug
output will be sent there.

=head1 Additional Methods

=head2 C<copy>

This method copies a certain number of "characters" from the input handle to
the output handle, that is, the temporary file. Depending on the status of the
filehandle, either (8-bit) bytes or characters are read, see L<perlfunc/read>.
The option C<bufsize> lets you adjust the read buffer size, and the option
C<< less=>'ignore' >> or C<< less=>'ok' >> suppresses the warning that less
characters than you requested could be read. The method returns the number of
characters copied and dies on errors.

 use File::Replace;
 my $repl = File::Replace->new($filename, ...);
 $repl->copy(8);                   # copy eight characters
 $repl->copy(1024, bufsize=>256);  # copy 1024 chars, 256 at a time
 $repl->copy(2048, less=>'ok');    # copy 2048, but don't warn if less
 $repl->finish;

This method was added in version 0.08.

=head1 Notes and Caveats

=head2 Concurrency and File Locking

This module is very well suited for situations where a file has one writer and
one or more readers.

Among other things, this is reflected in the case of a nonexistent file, where
the L</create> settings C<now> and C<later> (the default) are currently
implemented as a two-step process, meaning there is the potential of the input
file being created in the short period of time between the first and second
C<open> attempts, which this module currently will not notice.

Having multiple writers is possible, but care must be taken to ensure proper
coordination of the writers!

For example, a simple L<flock|perlfunc/flock> of the input file is B<not>
enough: if there are multiple processes, remember that each process will
I<replace> the original input file by a new and different file! One possible
solution would be a separate lock file that does not change and is only used
for C<flock>ing. There are other possible methods, but that is currently beyond
the scope of this documentation.

(For the sake of completeness, note that you cannot C<flock> the C<tie>d
handles, only the underlying filehandles.)

=head1 Author, Copyright, and License

Copyright (c) 2017 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

