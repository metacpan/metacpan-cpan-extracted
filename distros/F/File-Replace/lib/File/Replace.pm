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
use File::stat;
use Fcntl qw/S_IMODE/;
use Exporter 'import';
use File::Replace::SingleHandle ();
use File::Replace::DualHandle ();
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

our $VERSION = '0.04';

our @EXPORT_OK = qw/ replace replace2 /;
our @CARP_NOT = qw/ File::Replace::SingleHandle File::Replace::DualHandle /;

our $DISABLE_CHMOD;

my %NEW_KNOWN_OPTS = map {$_=>1} qw/ debug layers devnull create chmod
	perms autocancel autofinish /;
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
	my $self = bless { devnull=>1, chmod=>!$DISABLE_CHMOD, %opts, is_open=>0 }, $class;
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
	my $openmode = defined $self->{layers} ? '<'.$self->{layers} : '<';
	if ( not open $self->{ifh}, $openmode, $filename ) {
		if ( $!{ENOENT} && ($self->{create} || $self->{devnull}) ) { # No such file or directory
			$self->{create} and $openmode = defined $self->{layers} ? '+>'.$self->{layers} : '+>';
			# note we call &devnull() like this because otherwise it would
			# be inlined and we want to be able to mock it for testing
			if ( open $self->{ifh}, $openmode, $self->{create} ? $filename : &devnull() )
				{ $self->{setperms}=oct('666')&~umask unless defined $self->{setperms} }
			else { $self->{ifh}=undef }
		} else { $self->{ifh}=undef }
	}
	else { $self->{setperms} = S_IMODE(stat($self->{ifh})->mode)
			unless defined $self->{setperms} }
	if ( !defined $self->{ifh} ) {
		my $e=$!;
		close  $self->{ofh}; $self->{ofh} = undef;
		unlink $self->{ofn}; $self->{ofn} = undef;
		$!=$e;  ## no critic (RequireLocalizedPunctuationVars)
		croak "$class->new: failed to open '$filename': $!" }
	$self->{ifn} = $filename;
	# finish init
	$self->{is_open} = 1;
	$self->{debug} and print STDERR "$class->new: input '".$self->{ifn}
		."', output '".$self->{ofn}."', layers "
		.(defined $self->{layers} ? "'".$self->{layers}."'" : 'undef')."\n";
	return $self;
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
	$self->{debug} and print STDERR ref($self)."->finish:"
		." renamed '$ofn' to '$ifn', perms ".sprintf('%05o',$self->{setperms})."\n";
	return 1;
}

sub replace {
	unless (defined wantarray) { warnings::warnif("Useless use of "
		.__PACKAGE__."::replace in void context"); return }
	my $repl = __PACKAGE__->new(@_);
	return File::Replace::DualHandle->new($repl);
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

sub _cancel {
	my $self = shift;
	my $from = shift;
	if ($from eq 'destroy')
		{ $self->{is_open} and warnings::warnif(ref($self)
			.": unclosed file '".$self->{ifn}."' not replaced!") }
	elsif ($from eq 'cancel')
		{ $self->{is_open} or warnings::warnif(ref($self)."->cancel: already closed") }
	if ($self->{debug} && !($from eq 'destroy' && !$self->{is_open}))
		{ print STDERR ref($self)."->cancel: not replacing input file ",
			(defined $self->{ifn} ? "'$self->{ifn}'" : "(unknown)"),
			(defined $self->{ofn} ? ", will attempt to unlink '$self->{ofn}'" : ""), "\n" }
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
	   if ($self->{autocancel}) { $self->cancel }
	elsif ($self->{autofinish}) { $self->finish }
	$self->_cancel('destroy');
	return;
}

1;
__END__

=head1 Name

File::Replace - Perl extension for replacing files by renaming a temp file over
the original

=head1 Synopsis

=for comment
REMEMBER to keep these examples in sync with 91_author_pod.t

This module provides three interfaces:

 use File::Replace 'replace2';
 
 my ($infh,$outfh) = replace2($filename);
 while (<$infh>) {
     # write whatever you like to $outfh here
     print $outfh "X: $_";
 }
 close $infh;   # closing both handles will
 close $outfh;  # trigger the replace

Or the more magical single filehandle, in which C<print>, C<printf>, and
C<syswrite> go to the output file; C<binmode> to both; C<fileno> only reports
open/closed status; and the other I/O functions go to the input file:

 use File::Replace 'replace';
 
 my $fh = replace($filename);
 while (<$fh>) {
     # can read _and_ write from/to $fh
     print $fh "Y: $_";
 }
 close $fh;

Or the object oriented:

 use File::Replace;
 
 my $repl = File::Replace->new($filename);
 my $infh = $repl->in_fh;
 while (<$infh>) {
     print {$repl->out_fh} "Z: $_";
 }
 $repl->finish;

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

* Unfortunately, whether or not a rename will actually be atomic in your
specific circumstances is not always an easy question to answer, as it depends
on exact details of the operating system and file system. Consult your system's
documentation and search the Internet for "atomic rename" for more details.

=head2 Version

This documentation describes version 0.04 of this module.

B<This is an alpha version.> While the module works and has a full test suite,
I may still decide to change the API as I gain experience with it. I will try
to make such changes compatible, but can't guarantee that just yet.

=head1 Constructors and Overview

The functions C<< File::Replace->new() >>, C<replace()>, and C<replace2()> take
exactly the same arguments, and differ only in their return values. Note that
C<replace()> and C<replace2()> are normal functions and not methods, don't
attempt to call them as such. If you don't want to import them you can always
call them as, for example, C<File::Replace::replace()>.

 File::Replace->new( $filename );
 File::Replace->new( $filename, $layers );
 File::Replace->new( $filename, option => 'value', ... );
 File::Replace->new( $filename, $layers, option => 'value', ... );
 # replace(...) and replace2(...) take the same arguments

The options are described in L</Options>. The constructors will C<die> in case
of errors. It is strongly recommended that you C<use warnings;>, as then this
module will issue warnings which may be of interest to you.

=head2 C<< File::Replace->new >>

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
has been C<finish>ed or C<cancel>ed, or a true value if it is still active.
The method C<< ->filename >> returns the filename passed to the constructor.
The method C<< ->options >> in list context returns the options this object has
set (including defaults) as a list of key/value pairs, in scalar context it
returns a hashref of these options.

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
performed when you C<close> the handle.

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

=head2 C<replace2>

 use File::Replace 'replace2';
 my ($input_handle, $output_handle) = replace2($filename, ...);
 my $output_handle = replace2($filename, ...);

In list context, returns a two-element list of two tied filehandles, the first
being the input filehandle, and the second the output filehandle, and the
replace operation (C<finish>) is performed when both handles are closed. In
scalar context, it returns only the output filehandle, and the replace
operation is performed when this handle is closed.

You cannot re-C<open> these tied filehandles.

You can access the underlying C<File::Replace> object via
C<< tied(*$handle)->replace >> on both the input and output handle. You can
also access the original, untied filehandles via C<< tied(*$handle)->in_fh >>
and C<< tied(*$handle)->out_fh >>, but please don't C<close> or re-C<open>
these handles as this may lead to confusion.

=head1 Options

=head2 Filename

A filename. The temporary output file will be created in the same directory as
this file, its name will be based on the original filename, but prefixed with a
dot (C<.>) and suffixed with a random string and an extension of C<.tmp>.

If the input file does not exist (C<ENOENT>), then the behavior will depend on
the options L</devnull> (enabled by default) and L</create>. If either of these
options are set, the input file will be created (just at different times), if
neither are enabled, then attempting to open a nonexistent file will fail.

=head2 C<layers>

This option can either be specified as the second argument to the constructors,
or as the C<< layers => '...' >> option in the options hash, but not both. It
is a list of PerlIO layers such as C<":utf8">, C<":raw:crlf">, or
C<":encoding(UTF-16)">. Note that the default layers differ based on operating
system, see L<perlfunc/open>.

=head2 C<devnull>

This option, which is enabled by default, causes the case of nonexistent input
files to be handled by opening F</dev/null> or its equivalent instead of the
input file. This means that while the output file is being written, the input
file name will not exist, and only come into existence when the rename
operation is performed. If you disable this option, and attempt to open a
nonexistent file, then the constructor will C<die>.

The option L</create> being set overrides this option.

=head2 C<create>

Enabling this option causes the case of nonexistent input files to be handled
by opening the input file name with a mode of C<< +> >>, meaning that it is
created and opened in read-write mode. However, it is strongly recommended that
you don't take advantage of the read-write mode by writing to the input file,
as that contradicts the purpose of this module - instead, the input file will
exist and remain empty until the replace operation.

Setting this option overrides L</devnull>. If this option is disabled (the
default), L</devnull> takes precedence.

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

Enables some debug output for C<new>, C<finish>, and C<cancel>.

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

