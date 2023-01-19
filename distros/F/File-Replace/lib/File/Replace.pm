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

our $VERSION = '0.16';

our @EXPORT_OK = qw/ replace replace2 replace3 inplace /;
our @CARP_NOT = qw/ File::Replace::SingleHandle File::Replace::DualHandle File::Replace::Inplace /;

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
		require File::Replace::Inplace;
		$File::Replace::Inplace::GlobalInplace = File::Replace::Inplace->new(backup=>$ext, debug=>$debug);  ## no critic (ProhibitPackageVars)
	}
	goto &Exporter::import;
}

sub inplace {
	require File::Replace::Inplace;
	return File::Replace::Inplace->new(@_);
}

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
	# Possible To-Do for Later: A "noopen" option where the input file just isn't opened?
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
		# Possible To-Do for Later: Maybe a backup_link option that uses hard links instead of copy?
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
	require File::Replace::SingleHandle;
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
	require File::Replace::DualHandle;
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
