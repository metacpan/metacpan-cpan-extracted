#
# Forks::Super::Job::Ipc -- manage temporary files, sockets, pipes
#   that facilitate communication between
#   parent and child processes
# implementation of
#     fork { child_fh => ... }
#     fork { stdin =>   $input | \$input | \@input }
#     fork { stdout => \$output }
#     fork { stderr => \$error }
#
#

package Forks::Super::Job::Ipc;
use Forks::Super::Config;
use Forks::Super::Debug qw(:all);
use Forks::Super::Util qw(IS_WIN32 is_socket);
use Forks::Super::Tie::IPCFileHandle;
use Forks::Super::Tie::IPCSocketHandle;
use Forks::Super::Tie::IPCPipeHandle;

use Forks::Super::Tie::IPCDupSTDIN;

use Signals::XSIG;
use IO::Handle;
use File::Path;
use Cwd;
use Carp;
use Data::Dumper;
use Exporter;
use strict;
use warnings;

$| = 1;

our @ISA = qw(Exporter);
our @EXPORT = qw(close_fh);
our $VERSION = '0.95';
our $NO_README = 0;

our (%FILENO, %SIG_OLD, $IPC_COUNT, $IPC_DIR_DEDICATED,
     @IPC_FILES, %IPC_FILES);
our $_CLEANUP = 0;
our $MAIN_PID = $$;
our $__OPEN_FH = 0; # for debugging, monitoring file handle usage. Not ready.
our $__MAX_OPEN_FH = do {
    no warnings 'once';
    $Forks::Super::SysInfo::MAX_OPEN_FH;
};
our %__OPEN_FH;
our $_FILEHANDLES_PER_STRESSED_JOB = 100;   # for t/33

our @SAFEOPENED = ();
our $USE_TIE_FH = $] >= 5.008;
our $USE_TIE_SH = $] >= 5.008;
our $USE_TIE_PH = $] >= 5.008;

if ($ENV{NO_TIES}) {
    $USE_TIE_SH = $USE_TIE_FH = $USE_TIE_PH = 0;
}

our $TIE_FH_CLASS = 'Forks::Super::Tie::IPCFileHandle';

our $_IPC_DIR;
my $cleanse_mode = 0;

{
# package Forks::Super::Job::Ipc::Tie;

    # special behavior for $Forks::Super::IPC_DIR ==>
    # when this value is set, we should call set_ipc_dir.

    sub Forks::Super::Job::Ipc::Tie::TIESCALAR {
	return bless {}, 'Forks::Super::Job::Ipc::Tie';
    }
    sub Forks::Super::Job::Ipc::Tie::FETCH {
	my $self = shift;
	return $_IPC_DIR;
    }
    sub Forks::Super::Job::Ipc::Tie::STORE {
	my ($self, $value) = @_;
	my $old = $_IPC_DIR;
	Forks::Super::Job::Ipc::set_ipc_dir($value, 1);
	return $old;
    }
    sub Forks::Super::Job::Ipc::Tie::DEFINED {
	my $self = shift;
	return defined $_IPC_DIR;
    }
}

{
    # independent implementation of Symbol::gensym --

    # IO handles from this package will follow certain conventions
    #   1. created with _safeopen, _create_socket_pair, or _create_pipe
    #   2. attributes are set in the handle's namespace (glob, is_socket,
    #      opened, etc.)
    #   3. fileno() stored in %Forks::Super::Job::Ipc::FILENO
    #
    # Another one of these conventions will be that all such handles will
    # be registered in the same namespace, so we can tell whether
    # an arbitrary handle was created by this module.

    my $pkg = 'Forks::Super::IOHandles::';
    my $seq = 1000;     # an arbitrary starting point

    sub _gensym () {
	my $name = join '_', @_, "IO$$", $seq++;
	no strict 'refs';
	my $ref = \*{$pkg . $name};
	delete $$pkg{$name};
	return $ref;
    }
}

my $approached_openfh_limit;

# open a file handle with (a little) protection
# against "Too many open files" error.
# If supported, new file handles are tied to
# F::S::Tie::IPCFileHandle, which (potentially)
# logs and debugs activity on that handle.
sub _safeopen ($*$$;%) {
    my ($job, $fh, $mode, $expr, %options) = @_;
    my ($open2, $open3) = _parse_safeopen_mode($mode, $expr);

    my $result;
    if (!defined $fh || $options{tie_fh}) {
	if (!defined $fh) {
	    $fh = _gensym();
	}
	if ($options{tie_fh} && $options{tie_fh} ne '1') {
	    $fh = $options{tie_fh};
	}
	if ($USE_TIE_FH) {
	    my $gh = $fh;
	    tie *{$fh}, $TIE_FH_CLASS, parent => $fh; #, job => $job;
	    if (!$options{no_delegator}) {
		eval { bless $fh, 'Forks::Super::Tie::Delegator'; 1 }
		or carp "_safeopen: failed to bless *$fh as delegator ...\n";
	    }
	    $$fh->{parent} ||= $gh;
	}
    }

    my @io_layers = _get_iolayers_for_safeopen($job, $open2, %options);

    if ($open2 !~ /&/ && $] >= 5.007) {
	$open2 .= join'', @io_layers;
	@io_layers = ();
	if ($job->{debug}) {
	    debug('open mode for ',$open3||'file descriptor'," is $open2");
	}
    }

    if ($__OPEN_FH > 0.95 * $__MAX_OPEN_FH) {
        no warnings 'once';
        my $rescue = 'rescue' eq $Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES;
	$Forks::Super::Job::Ipc::TOO_MANY_OPEN_FH_WARNINGS++;
        if ($job->{debug}) {
            debug("This program now using $__OPEN_FH of ~$__MAX_OPEN_FH " .
                  "open file handles. Consider closing unused file " .
                  "handles");
        } elsif (!$approached_openfh_limit++) {

            if (!$rescue && $$ == $Forks::Super::MAIN_PID) {
                carp("***********************************************\n",
                     "Forks::Super has determined that this program is\n",
                     "approaching a system limit on open file handles\n",
                     "($__OPEN_FH of ~$__MAX_OPEN_FH available).\n",
                     "Consider closing unused file handles or calling\n",
                     "Forks::Super::try_to_close_some_open_file handles()\n",
                     "to let Forks::Super choose which file handles to close.",
                     "\n\nSee the \"Socket and file handle gotchas\" section\n",
                     "of the Forks::Super docs for more information.\n",
                     "***********************************************\n");
            } else {
                carp("This program now using $__OPEN_FH of ~$__MAX_OPEN_FH " .
                     "open file handles. Consider closing unused file " .
                     "handles");
            }
        }
        return if !$Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES ||
            'rescue' ne $Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES;

	Forks::Super::try_to_close_some_open_filehandles();
    }


    for my $try (1 .. 10) {
	if ($try == 10) {
	    carp 'Forks::Super: ',
	        "Failed to open $mode $expr after 10 tries. Giving up.\n";
	    return 0;
	}
	$result = _safeopen_open($fh, $open2, $open3);
	$_[1] = $fh;

	if ($result) {
	    _apply_safeopen_layers_for_older_perls(
		$job, [$fh,$expr,$mode], "$open2 ".($open3||''), @io_layers);

	    push @SAFEOPENED, $fh;
	    $__OPEN_FH++;

	    # dereferenced file handles are just symbol tables, and we
	    # can store arbitrary data in them
	    # -- there are a lot of ways we can make good use of this data.

	    my ($pkg,$file,$line) = caller;
	    $$fh->{opened} = Time::HiRes::time();
	    $$fh->{caller} = "$pkg;$file:$line";
	    $$fh->{is_regular} = 1;
	    $$fh->{is_socket} = 0;
	    $$fh->{is_pipe} = 0;
	    $$fh->{mode} = $mode;
	    $$fh->{expr} = $expr;
	    $$fh->{glob} = '' . *$fh;
	    $$fh->{job} = $job;
	    my $fileno = $$fh->{fileno} = CORE::fileno($_[1]);
	    $FILENO{$_[1]} = $fileno;
	    $__OPEN_FH{$fileno} = {%$job};
	    if ($mode =~ />/) {
		$_[1]->autoflush(1);
	    }

	    if ($mode =~ /&/) {
		$$fh->{dup_glob} = '' . *$expr;
		$$fh->{dup} = $$expr;
		$$expr->{duped_by} .= ' ' . *$fh;
		$$fh->{is_regular} = $$expr->{is_regular};
		$$fh->{is_socket} = $$expr->{is_socket};
		$$fh->{is_pipe} = $$expr->{is_pipe};
	    }
	    return 1;
	} else {
	    _handle_safeopen_failure($try, $options{robust},
				     $DEBUG || $job->{debug},
				     "$open2 " . $expr||'');
	}
    }
    return $result;
}

sub _parse_safeopen_mode {
    my ($mode, $expr) = @_;
    my ($open2, $open3);
    if ($mode =~ /&/) {
	my $fileno = CORE::fileno($expr);
	if (!defined $fileno) {
	    carp "_safeopen: no fileno available for $expr!\n";
	    return;
	} elsif ($fileno >= 0) {
	    return ($mode . $fileno, undef);
	}
    }
    return ($mode, $expr);
}

sub _get_iolayers_for_safeopen {
    my ($job, $open2, %options) = @_;
    return if $options{no_layers};

    my @layers = @{ $job->{fh_config}{layers} || [] };
    return $open2 =~ /</ ? reverse @layers : @layers;
}

sub _apply_safeopen_layers_for_older_perls {
    my ($job, $handle, $open, @layers) = @_;
    my ($fh, $expr, $mode) = @$handle;
    foreach my $layer (@layers) {
	local $! = 0;
	if ($] < 5.008 && $mode =~ /&/) {
	    my $binmode_result2 = eval { binmode $expr,$layer } or 0;
	    if ($job->{debug}) {
		debug("applied $layer to $expr, result=$binmode_result2");
	    }
	}

	for my $redo (1..10) {
	    if (eval { binmode $fh, $layer }) {
		if ($job->{debug}) {
		    debug("applying I/O layer $layer to $open");
		}
		last;
	    } elsif ($redo == 10) {
		carp 'Forks::Super::_safeopen: ',
	        	"Failed to apply I/O layer $layer ",
	        	"to IPC file $open: $!";
	    }
	    Forks::Super::Util::pause(0.01 * $redo);
	}
    }
    return;
}

sub _safeopen_open {
    my ($fh, $open2, $open3) = @_;
    my $result;
    if (defined $open3) {
	$result = CORE::open($fh, $open2, $open3);      ## no critic (BriefOpen)
	$_[0] = $fh;
    } else {
	$result = CORE::open($fh, $open2);              ## no critic (BriefOpen)
	$_[0] = $fh;
    }
    return $result;
}

sub _handle_safeopen_failure {
    my ($try, $robust, $debug, $description) = @_;
    # called when _safeopen (_safeopen_open) returns false.

    if ($! =~ /too many open file/i ||
	$! == $Forks::Super::SysInfo::TOO_MANY_FH_ERRNO) {

	carp "$! while opening $description. ",
		"[openfh=$__OPEN_FH/$__MAX_OPEN_FH] Retrying ...\n";
	Forks::Super::pause(1.0);
    } elsif ($robust && ($! =~ /no such file or directory/i ||
			 $! == $Forks::Super::SysInfo::FILE_NOT_FOUND_ERRNO)) {
	if ($debug) {
	    debug("$! while opening $description in $$. Retrying ...");
	}
	Forks::Super::pause(0.05);
    } else {
	if ($try > 5) {
	    carp_once [$!], "$! while opening $description in $$ ",
		    "[openfh=$__OPEN_FH/$__MAX_OPEN_FH]. Retrying ...\n";
	}
    }
    Forks::Super::pause(0.01 * $try * $try, $try < 3);
    return;
}

my $rescued;
sub Forks::Super::try_to_close_some_open_filehandles {
    my $nclosed = 0;

    if ($$ == $MAIN_PID && !$rescued++) {
        carp("*********************************************************\n",
             "Forks::Super has determined that this program is\n",
             "approaching the system limit on simultaneous open\n",
             "file handles, and will attempt to close some\n",
             "that appear to be unused.\n\n",
             "Remember to call  Forks::Super::close_fh(\$job)  or\n",
             "\$job->dispose  when you are doing with I/O operations\n",
             "on a Forks::Super job.",
             "\n\nSee the \"Socket and file handle gotchas\" section\n",
             "of the Forks::Super docs for more information.\n",
             "*********************************************************\n");
    }

    # in the child, you can close file handles from unrelated jobs ...
    if ($$ != $Forks::Super::MAIN_PID) {
	use POSIX ();
	POSIX::close($_) for 3 .. 1000; # XXX
	return;
    }

    # where are the open file handles, and which ones should we close?
    my @open_handles = ();
    foreach my $handle (@SAFEOPENED) {
	if (ref $handle eq 'ARRAY') {
	    my $fh = $handle->[1];
	    next if $$fh->{closed};
	    push @open_handles, [ $fh, $$fh->{job} ];
	} else {
	    no warnings 'uninitialized';
	    next if $$handle->{closed};
	    push @open_handles, [ $handle, $$handle->{job} ];
	}
    }

    # close jobs that are
    #    * done (have a status)
    #    * old

    my @handles_for_finished_jobs =
	grep { $_->[1]->is_complete } @open_handles;
    @handles_for_finished_jobs = sort {
	$b->[1]->is_reaped <=> $a->[1]->is_reaped
	    ||
	(${$a->[0]}->{closed} || 9E19) <=> (${$b->[0]}->{closed} || 9E19)
	    ||
	(${$a->[0]}->{opened} || 9E19) <=> (${$b->[0]}->{opened} || 9E19)
    } @handles_for_finished_jobs;

    foreach my $handle (@handles_for_finished_jobs) {

	if ($__OPEN_FH > 0.9 * $__MAX_OPEN_FH) {
	    while (my ($key,$jobhandle) = each %{$handle->[1]}) {
		next if $key !~ /^child_/;
		next if $key eq 'child_fh';

		my $zz = eval { _close($jobhandle) } || 0;
		carp $@,$key,$jobhandle if $@;
		if ($zz) {
		    print STDERR "closed ", $jobhandle, " for $key\n";
		}
		$nclosed += $zz;
	    }
	}
    }

    if ($nclosed) {
	warn "Forks::Super::Job::Ipc: Closed $nclosed open file handles ",
             "from jobs that look complete.\n";
	$__OPEN_FH -= $nclosed;
    } else {
        warn "Forks::Super::Job::Ipc: unable to close any open filehandles";
    }

    return;
}

#############################################################################

sub __set_fh_config_from_spec {
    my ($job, $config, $fh_spec) = @_;
    if ($fh_spec =~ /\ball\b/i) {
	$config->{in} = 1;
	$config->{out} = 1;
	$config->{err} = 1;
	$config->{all} = 1;
    } elsif ($fh_spec =~ /\bstress\b/) {
	# for testing -- opens an extra 100 IPC files
	$config->{in} = 1;
	$config->{out} = 1;
	$config->{err} = 1;
	$config->{all} = 1;
	$config->{stress} = 1 if $Forks::Super::Config::IS_TEST;
    } else {
	if ($fh_spec =~ /\bin\b/i) {
	    $config->{in} = 1;
	}
	if ($fh_spec =~ /\bout\b/i) {
	    $config->{out} = 1;
	}
	if ($fh_spec =~ /\berr\b/i) {
	    $config->{err} = 1;
	}
	if ($fh_spec =~ /\bjoin\b/i) {
	    $config->{join} = 1;
	    $config->{out} = 1;
	    $config->{err} = 1;
	}
    }

    if ($fh_spec =~ /\bblock\b/i) {
	$config->{block} = 1;
    }

    my @layers = $fh_spec =~ /(:[()\w]+)/g;
    if (@layers > 0) {
	$config->{layers} = \@layers;
	if ($job->{debug}) {
	    debug("io layers for job: @layers");
	}
    }
    return;
}

sub _preconfig_fh_parse_child_fh {
    my $job = shift;
    my $config = {};

    if (defined $job->{child_fh}) {
	my $fh_spec = $job->{child_fh} || '';
	if (ref $fh_spec eq 'ARRAY') {
	    $fh_spec = join q/;/, @$fh_spec;
	}
	__set_fh_config_from_spec($job, $config, $fh_spec);

	if (($job->{style} ne 'cmd' && $job->{style} ne 'exec') || !&IS_WIN32) {

	    _adjust_fh_config_for_Win32_cmd($job, $fh_spec, $config);

	} elsif (!Forks::Super::Config::CONFIG('filehandles')) {

	    carp 'Forks::Super::Job::_preconfig_fh: ',
	        "Requested cmd/exec-style fork on MSWin32 with\n",
	        "socket based IPC. This is not going to end well.\n";

	    $config->{sockets} = 1;
	}

    } elsif ($job->{child_suppress}) {
	# child_suppress => [in],[out],[err] is an undocumented feature
	# -- I might change the name, or I might not even like the
	# functionality it provides.
	my %suppress = map { $_ => 1 } split /,/, $job->{child_suppress};
	$job->{fh_config}{suppress} = \%suppress;
    }

    if (&IS_WIN32 && !$ENV{WIN32_PIPE_OK} && $config->{pipes}) {
	$config->{sockets} = 1;
	$config->{pipes} = 0;
    }
    return $config;
}

sub _adjust_fh_config_for_Win32_cmd {
    my ($job, $fh_spec, $config) = @_;

    # sockets,pipes not supported for cmd/exec style forks on MSWin32
    # we could support cmd-style with IPC::Open3-like framework?

    # sockets,pipes not supported for daemon processes, because that
    # would require leaving a common file descriptor open in both
    # processes.
    if ($job->{daemon}) {
	if ($fh_spec =~ /sock/i || $fh_spec =~ /pipe/i) {

	    # XXX - support socket IPC and daemon
	    if (Forks::Super::Config::CONFIG('filehandles')) {
		carp 'Forks::Super::Job::_preconfig_fh: ',
		'Socket/pipe based IPC not allowed ',
		'for daemon process.';
	    } else {
		croak 'Forks::Super::Job::_preconfig_fh: ',
		'Socket/pipe based IPC not allowed ',
		'for daemon process.';
	    }
	}
    } elsif ($fh_spec =~ /sock/i) {
	$config->{sockets} = 1;
    } elsif ($fh_spec =~ /pipe/i) {
	$config->{pipes} = 1;
    }
    return;
}

sub _preconfig_fh_parse_stdxxx {
    my ($job, $config) = @_;
    if (defined $job->{stdin}) {
	$config->{in} = 1;
	if (ref $job->{stdin} eq 'ARRAY') {
	    $config->{stdin} = join'', @{$job->{stdin}};
	} elsif (ref $job->{stdin} eq 'SCALAR') {
	    $config->{stdin} = ${$job->{stdin}};
	} else {
	    $config->{stdin} = $job->{stdin};
	}
        $config->{scalar}{in} = 1;
    }

    if (defined $job->{stdout}) {
	if (ref $job->{stdout} ne 'SCALAR') {
	    carp 'Forks::Super::_preconfig_fh: ',
		    "'stdout' option must be a SCALAR ref\n";
	} else {
	    $config->{stdout} = $job->{stdout};
            $config->{scalar}{out} = 1;
	    $config->{out} = 1;
	    $job->{'_callback_collect'} =
                \&Forks::Super::Job::Ipc::collect_output;
	}
    }

    if (defined $job->{stderr}) {
	if (ref $job->{stderr} ne 'SCALAR') {
	    carp 'Forks::Super::_preconfig_fh: ',
		    "'stderr' option must be a SCALAR ref\n";
	} else {
	    $config->{stderr} = $job->{stderr};
	    $config->{err} = 1;
            $config->{scalar}{err} = 1;
	    $job->{'_callback_collect'} =
                \&Forks::Super::Job::Ipc::collect_output;
	}
    }
    return;
}

sub Forks::Super::Job::_preconfig_share {
    my $job = shift;
    if (defined $job->{share}) {
	if ($job->{style} eq 'cmd' || $job->{style} eq 'exec') {
	    carp 'Forks::Super::_preconfig_share: ',
	        'share  option incompatible with cmd or exec option';
	    return;
	}
	$job->{share_ipc} = Forks::Super::Job::Ipc::_choose_fh_filename(
		'.share', purpose => 'share ipc');
	$job->{_callback_share} = \&Forks::Super::Job::Ipc::retrieve_share;
    }
    return;
}

sub Forks::Super::Job::_preconfig_fh {
    my $job = shift;

    # set  %$config{in,out,err,join,block,sockets,pipes}
    my $config = _preconfig_fh_parse_child_fh($job);
    if ($job->{remote} && ($config->{sockets} || $config->{pipes}) &&
        !Forks::Super::Config::CONFIG_module("Net::OpenSSH")) {
        carp "Forks::Super::fork: child_fh => socket|pipe is not compatible ",
                "with 'remote' option";
    }

    # set  %$config{stdin,stdout,stderr}
    _preconfig_fh_parse_stdxxx($job, $config);

    if ($config->{pipes}) {
	_preconfig_fh_pipes($job,$config);
    } elsif (Forks::Super::Config::CONFIG('filehandles')
	     && !$config->{sockets}) {

	_preconfig_fh_files($job, $config);

    } else {
	$config->{sockets} ||= 7;
	_preconfig_fh_sockets($job, $config);
    }

    if (0 < scalar keys %$config) {
	$job->{fh_config} = $config;
    }
    return;
}

# read output from children into scalar reference variables in the parent
sub collect_output {
    my ($job,$pid) = @_;

    my $fh_config = $job->{fh_config};
    if (!defined $fh_config) {
	return;
    }
    my $stdout = $fh_config->{stdout};
    if (defined $stdout) {

	_collect_output($job, $pid, 'f_out', 
			'Forks::Super::read_stdout', $stdout);

	if ($job->{debug}) {
	    debug("Job $pid loaded ", length($$stdout),
		  " bytes from stdout into $stdout");
	}

    }

    my $stderr = $fh_config->{stderr};
    if (defined $stderr) {

	_collect_output($job, $pid, 'f_err',
			'Forks::Super::read_stderr', $stderr);

	if ($job->{debug}) {
	    debug("Job $pid loaded ", length($$stderr),
		  " bytes from stderr into $stderr");
	}
    }

    $job->close_fh('all');
    return;
}

sub _collect_output {
    my ($job, $pid, $fileattr, $altmethod, $vessel) = @_;

    my $fh_config = $job->{fh_config};
    my $attr = $fh_config->{$fileattr};
    if ($attr && $attr ne '__socket__' && $attr ne '__pipe__') {
	local $/ = undef;
	if (_safeopen($job, my $fh, '<', $attr)) {
	    ($$vessel) = <$fh>;
	    _close($fh);
	} else {
	    carp 'Forks::Super::Job::Ipc::collect_output(): ',
		    "Failed to retrieve $fileattr from child $pid: $!\n";
	}
    } else {
	no strict 'refs';
	$$vessel = join'', $altmethod->($pid);
    }
    return;
}

sub retrieve_share {
    my ($job, $pid) = @_;
    if (!defined $job->{share_ipc}) {
	# carp ...
	return;
    }
    if ($job->{is_emulation}) {
        # job ran in foreground, values are already shared
        return;
    }
    my $VAR1 = '';
    my $fh;
    for my $try (1..10) {
	last if open $fh, '<', $job->{share_ipc};      ## no critic (BriefOpen)
	carp 'open ',$job->{share_ipc}, " failed try $try ... $!\n";
	Forks::Super::Util::pause(1);
    }
    my $expr = do { local $/=undef; <$fh> };
    close $fh;
    if ($job->{untaint}) {
	($expr) = $expr =~ /(.*)/s;
    }
    eval $expr;               ## no critic (StringyEval,CheckingReturnValue)
    my @VAR1;

    if (ref $VAR1 eq 'ARRAY') {
	@VAR1 = @$VAR1;
    } else {
	carp "\$VAR1 is:  $expr, not an ARRAY ref!\n";
    }

    if (@VAR1) {
	foreach my $ref (@{$job->{share}}) {
	    require Scalar::Util;
	    my $reftype = Scalar::Util::reftype($ref);
	    my $val = shift @VAR1;
	    if ($reftype eq 'SCALAR') {
		$$ref = $$val;
	    } elsif ($reftype eq 'ARRAY') {
		push @$ref, @$val;
	    } elsif ($reftype eq 'HASH') {
		foreach my $key (keys %$val) {
		    $ref->{$key} = $val->{$key};
		}
	    } else {
		carp 'share element is not a reference!';
	    }
	}
    } else {
	carp 'Forks::Super: no share values returned';
    }
    return;
}

sub _preconfig_fh_files {
    my ($job, $config) = @_;
    if ($config->{in}) {
	$config->{f_in} = _choose_fh_filename('', purpose => 'STDIN', 
					      job => $job);
	debug("Using $config->{f_in} as shared file for child STDIN")
	    if $job->{debug} && $config->{f_in};

	if ($config->{stdin}) {
	    if (_safeopen($job, my $fh, '>', $config->{f_in})) {
		print $fh $config->{stdin};
		_close($fh);
                debug("Stored ",length($config->{stdin})," bytes in ",
                      $config->{f_in}," as child STDIN")
                    if $job->{debug};
	    } else {
		carp 'Forks::Super::Job::_preconfig_fh: ',
		    "scalar standard input not available in child: $!\n";
	    }
	}
    }
    if ($config->{out}) {
	$config->{f_out} = _choose_fh_filename('', purpose => 'STDOUT', 
					       job => $job);
	debug("Using $config->{f_out} as shared file for child STDOUT")
	    if $job->{debug} && $config->{f_out};
    }
    if ($config->{err}) {
	$config->{f_err} = _choose_fh_filename('', purpose => 'STDERR', 
					       job => $job);
	debug("Using $config->{f_err} as shared file for child STDERR")
	    if $job->{debug} && $config->{f_err};
    }

    if ($config->{stress}) {
	for my $n (1 .. $_FILEHANDLES_PER_STRESSED_JOB) {
	    my $fkey = "f_stress_" . $n;
	    $config->{$fkey} = _choose_fh_filename(
		'', purpose => "STRESS FILE " . $n, job => $job);
	    debug("Using $config->{$fkey} as shared file for child STD$n")
		if $job->{debug} && $config->{$fkey};
	}
    }
    return;
}

sub _preconfig_fh_sockets {
    my ($job,$config) = @_;
    if (!Forks::Super::Config::CONFIG('Socket')) {
	carp 'Forks::Super::Job::_preconfig_fh_sockets(): ',
	    'Socket unavailable. ',
	    "Will try to use regular file handles for child ipc.\n";
	delete $config->{sockets};
	return;
    }
    foreach my $channel (qw(in out err)) {
	next if not defined $config->{$channel};
	$config->{"f_$channel"} = '__socket__';
	if ($channel eq 'err' && defined($config->{out}) && $config->{join}) {
	    $config->{csock_err} = $config->{csock_out};
	    $config->{psock_err} = $config->{psock_out};
	} else {
	    ($config->{"csock_$channel"}, $config->{"psock_$channel"})
		= _create_socket_pair($job, $channel eq 'in' ? +1 : -1);

	    if ($job->{debug}) {
		debug('created socket pair/', $config->{"csock_$channel"}, ':',
		      CORE::fileno($config->{"csock_$channel"}), '/',
		      $config->{"psock_$channel"}, ':',
		      CORE::fileno($config->{"psock_$channel"}));
	    }
	}
    }
    return;
}

sub _preconfig_fh_pipes {
    my ($job,$config) = @_;
    if (!$Forks::Super::SysInfo::CONFIG{'pipe'}) {
	carp 'Forks::Super::Job::_preconfig_fh_pipes(): ',
	    'Pipes unavailable. ',
	    "Will try to use regular file handles for child ipc.\n";
	delete $config->{pipes};
	return;
    }

    if ($config->{in}) {
	$config->{f_in} = '__pipe__';
	($config->{p_in}, $config->{p_to_in}) = _create_pipe_pair($job);
    }
    if ($config->{out}) {
	$config->{f_out} = '__pipe__';
	($config->{p_out},$config->{p_to_out}) = _create_pipe_pair($job);
    }
    if ($config->{err} && !$config->{join}) {
	$config->{f_err} = '__pipe__';
	($config->{p_err},$config->{p_to_err}) = _create_pipe_pair($job);
    }

    if ($job->{debug}) {
	debug("created pipe pairs for ", $job->{pid});
    }
    return;
}

sub _create_socket_pair {
    my ($job, $dir) = @_;  # dir:  -1 child->parent, +1 parent->child, 0 bidir.

    if (!Forks::Super::Config::CONFIG('Socket')) {
	croak "Forks::Super::Job::_create_socket_pair(): no Socket\n";
    }
    my ($s_child, $s_parent);
    my $addr_family = Socket::AF_UNIX();
    local $! = undef;
    if (Forks::Super::Config::CONFIG('IO::Socket') && 0) {
	($s_child, $s_parent) = IO::Socket->socketpair(
	    $addr_family, Socket::SOCK_STREAM(), Socket::PF_UNSPEC());
	if (!(defined($s_child) && defined($s_parent))) {
	    warn 'Forks::Super::_create_socket_pair: ',
	    	"IO::Socket->socketpair(AF_UNIX) failed.\n";
	}
    } else {

	# socketpair not supported on MSWin32 5.6
	$s_child = _gensym();
	$s_parent = _gensym();

	my $z = socketpair($s_child, $s_parent, $addr_family,
			   Socket::SOCK_STREAM(), Socket::PF_UNSPEC());
	if ($z == 0) {
	    warn 'Forks::Super::_create_socket_pair: ',
                 "socketpair(AF_UNIX) failed. Trying again\n";
	    $z = socketpair($s_child, $s_parent, $addr_family,
			    Socket::SOCK_STREAM(), Socket::PF_UNSPEC());
	    if ($z == 0) {
		undef $s_child;
		undef $s_parent;
	    }
	}
    }
    if (!(defined($s_child) && defined($s_parent))) {
	carp 'Forks::Super::Job::_create_socket_pair(): ',
		"socketpair failed $! $^E!\n";
	return;
    }
    $s_child->autoflush(1);
    $s_parent->autoflush(1);

    $$s_child->{fileno} = $FILENO{$s_child} = CORE::fileno($s_child);
    $$s_parent->{fileno} = $FILENO{$s_parent} = CORE::fileno($s_parent);
    $s_child->blocking(!!&IS_WIN32);
    $s_parent->blocking(!!&IS_WIN32);

    $$s_child->{glob}       = '' . *$s_child;
    $$s_parent->{glob}      = '' . *$s_parent;
    $$s_child->{job}        = $$s_parent->{job}        = $job;

    $$s_child->{is_socket}  = $$s_parent->{is_socket}  = 1;
    $$s_child->{is_pipe}    = $$s_parent->{is_pipe}    = 0;
    $$s_child->{is_regular} = $$s_parent->{is_regular} = 0;
    $$s_child->{is_child}   = $$s_parent->{is_parent}  = 1;
    $$s_child->{is_parent}  = $$s_parent->{is_child}   = 0;
    $$s_child->{opened}     = $$s_parent->{opened}     = Time::HiRes::time();
    my ($pkg,$file,$line)   = caller(2);
    $$s_child->{caller}     = $$s_parent->{caller}     = "$pkg;$file:$line";

    if ($dir >= 0) {
	$$s_child->{is_write} = $$s_parent->{is_read} = 1;
    }
    if ($dir <= 0) {
	$$s_child->{is_read} = $$s_parent->{is_write} = 1;
    }

    # XXX - $__OPEN_FH += 2 ?

    return ($s_child,$s_parent);
}

sub _create_pipe_pair {
    my $job = shift;
    if (!defined($job)) {
	Carp::confess 'no job supplied to _create_pipe_pair';
    }

    if (!$Forks::Super::SysInfo::CONFIG{'pipe'}) {
	croak "Forks::Super::Job::_create_pipe_pair(): no pipe\n";
    }

    my ($p_read, $p_write) = (_gensym(), _gensym());
    local $! = undef;

    pipe $p_read, $p_write 
	or croak "Forks::Super::Job: create pipe failed $!\n";
    $p_write->autoflush(1);

    $$p_read->{fileno} = $FILENO{$p_read} = CORE::fileno($p_read);
    $$p_write->{fileno} = $FILENO{$p_write} = CORE::fileno($p_write);

    $$p_read->{is_pipe} = $$p_write->{is_pipe} = 1;
    $$p_read->{is_socket} = $$p_write->{is_socket} = 0;
    $$p_read->{is_regular} = $$p_write->{is_regular} = 0;
    $$p_read->{is_read} = $$p_write->{is_write} = 1;
    $$p_read->{is_write} = $$p_write->{is_read} = 1;
    $$p_read->{opened} = $$p_write->{opened} = Time::HiRes::time();
    $$p_read->{job} = $$p_write->{job} = $job;

    my ($pkg,$file,$line) = caller(2);
    $$p_read->{caller} = $$p_write->{caller} = "$pkg;$file:$line";

    # XXX - $__OPEN_FH += 2 ?

    return ($p_read, $p_write);
}

sub _choose_fh_filename {
    my ($suffix, @debug_info) = @_;
    my $basename = $ENV{FORKS_SUPER_IPC_BASENAME} || '.fh_';
    if (!Forks::Super::Config::CONFIG('filehandles')) {
	return;
    }
    if (not defined $_IPC_DIR) {
	_identify_shared_fh_dir();
    }

    $IPC_COUNT++;
    my $file = sprintf ('%s/%s%03d', $_IPC_DIR, $basename, $IPC_COUNT);
    if (defined $suffix) {
	$file .= $suffix;
    }

    if (&IS_WIN32) {
	$file =~ s!/!\\!g;
    }

    _register_ipc_file($file, [ @debug_info ]);

    if (!$IPC_DIR_DEDICATED && -f $file) {
	carp 'Forks::Super::Job::_choose_fh_filename: ',
		"IPC file $file already exists!\n";
	debug("$file already exists ...") if $DEBUG;
    }
    return $file;
}

sub _register_ipc_file {
    my ($file, $info) = @_;
    push @IPC_FILES, $file;
    if (defined $info) {
	$IPC_FILES{$file} = $info;
    }
    return;
}

#
# choose a writeable but discrete location for files to
# handle interprocess communication.
#
sub _identify_shared_fh_dir {
    return if defined $_IPC_DIR;
    return if Forks::Super::Config::CONFIG('filehandles') eq '0';

    # what are the good candidates ???
    # Any:       .
    # Windows:   C:/Temp C:/Windows/Temp %HOME%
    # Other:     /tmp $HOME /var/tmp
    my @search_dirs = ($ENV{'HOME'}, $ENV{'PWD'});
    if (&IS_WIN32) {
	push @search_dirs, 'C:/Temp', $ENV{'TEMP'}, 'C:/Windows/Temp',
	    'C:/Winnt/Temp', 'D:/Windows/Temp', 'D:/Winnt/Temp',
	    'E:/Windows/Temp', 'E:/Winnt/Temp', '.';
    } else {
	my ($cwd) = Forks::Super::Util::abs_path('.') =~ /(.*)/;
        unshift @search_dirs, $cwd;
        unshift @search_dirs, '/dev/shm';
	push @search_dirs, '/tmp', '/var/tmp', '/usr/tmp';
    }

    foreach my $dir (@search_dirs) {
	next if !(defined($dir) && $dir =~ /\S/);
	debug("Considering $dir as shared file handle dir ...") if $DEBUG;
        if (! -w $dir || ! -x $dir || ! -r $dir) {
            $DEBUG && debug("Bad permissions for $dir");
            next;
        }
	if (Forks::Super::Config::configif('filehandles')) {
	    if (set_ipc_dir($dir,0)) {
		debug("Selected $_IPC_DIR as shared file handle dir ...")
		    if $DEBUG;
		return $_IPC_DIR;
	    }
	}
    }
    return;
}

# attempt to set $_IPC_DIR / $Forks::Super::IPC_DIR. Will fail if
# input is not a good directory name.
sub enable_cleanse_mode { return $cleanse_mode = 1; }
sub is_cleanse_mode { return $cleanse_mode; }

sub set_ipc_dir {
    my ($dir, $carp) = @_;

    if (defined($dir) && $dir eq 'undef') {
	# disable file IPC
	$Forks::Super::Config::CONFIG{'filehandles'} = 0;
	$_IPC_DIR = undef;
    }
    return if !Forks::Super::Config::CONFIG('filehandles');

    $dir = Forks::Super::Util::abs_path($dir);
    return if !_check_for_good_ipc_basedir($dir);

    my $dedicated_dirname = _choose_dedicated_dirname($dir);

    if (!defined $dedicated_dirname) {
	carp 'Forks::Super::set_ipc_dir: ',
            "Failed to created new dedicated IPC directory under \"$dir\"\n"
		if $carp;
	return;
    }

    if ($cleanse_mode==0 && ! _mkdir0777("$dir/$dedicated_dirname")) {
	carp 'Forks::Super::set_ipc_dir: ',
		'Could not created dedicated IPC directory ',
		"\"$dir/$dedicated_dirname\"",
		"under \"$dir\": $!\n" if $carp;
	return;
    }

    # success.

    $_IPC_DIR = "$dir/$dedicated_dirname";
    # $Forks::Super::IPC_DIR is tied to this variable

    $IPC_DIR_DEDICATED = 1;
    debug("dedicated IPC directory: $_IPC_DIR") if $DEBUG;

    # create README
    if (!$NO_README && !$cleanse_mode) {
	my $readme = "$_IPC_DIR/README.txt";
	my $localtime1 = time;
	my $localtime2 = scalar localtime;
        my $readme_txt = <<"____";
This directory was created by $^O process $$ at
$localtime2
$localtime1 $$
running
$0 @ARGV
for interprocess communication.

It should be/have been cleaned up when the process completes/completed.
If that didn't happen for some reason, it is safe to delete
this directory. You may also consider running the command
"$^X -MForks::Super=cleanse,$_IPC_DIR" to clean up this
and any other IPC litter.

____
            #';
	if (open my $readme_fh, '>', $readme) {
	    print $readme_fh  $readme_txt;
            close $readme_fh;
	    _register_ipc_file( $readme,
				[ purpose => 'README' ] );
	} else {
	    carp 'Forks::Super::set_ipc_dir: ',
	        "Cannot create annotation file $readme: $!\n"; 
	}
    }
    return 1;
}

sub _mkdir0777 {
    my $dir = shift;
    return mkdir($dir, 0777)
	&& -r $dir
	&& -w $dir
	&& -x $dir;
}

sub _check_for_good_ipc_basedir {
    my ($dir,$carp) = @_;
    return if !defined($dir) || $dir !~ /\S/;
    my $ok = $cleanse_mode;
    if ($dir eq 'undef') {
	# don't use IPC.
	$Forks::Super::Config::CONFIG{'filehandles'} = 0;
	$_IPC_DIR = undef;
	return;
    }
    if (! -d $dir) {
	my $if_carp_msg;
	if (-e $dir) {
	    $if_carp_msg = 'Forks::Super::set_ipc_dir: ' .
		"\"$dir\" is not a directory\n";
	} elsif (!$cleanse_mode) {
	    if (_mkdir0777($dir)) {
		$if_carp_msg = 
		    'Forks::Super::set_ipc_dir: ' .
		    "Created IPC directory \"$dir\"\n";
		$ok = 1;
	    } else {
		$if_carp_msg =
		    'Forks::Super::set_ipc_dir: ' .
		    "IPC directory \"$dir\" does not exist " .
		    "and could not be created: $!\n";
	    }
	}
	if ($carp && $if_carp_msg) {
	    carp $if_carp_msg;
	}
	return $ok;
    }
    if ((! -r $dir) || (! -w $dir) || (! -x $dir)) {
	if ($carp) {
	    carp 'Forks::Super::set_ipc_dir: ',
	    	"Insufficient permission on IPC directory \"$dir\"";
	}
	return;
    }
    return 1;
}

sub _choose_dedicated_dirname {
    my $dir = shift || '.';
    my $dedicated_dirname = ".fhfork$$";
    my $n = 0;
    while (-e "$dir/$dedicated_dirname") {
	$dedicated_dirname = ".fhfork$$-$n";
	$n++;
	if ($n > 10000) {
	    return;
	}
    }
    return $dedicated_dirname;
}

sub _cleanup {
    no warnings 'once';
    return if ($Forks::Super::DONT_CLEANUP || 0) > 0;
    return if !defined $_IPC_DIR;

    if (&IS_WIN32) {
	END_cleanup_MSWin32();
    } else {
	END_cleanup();
    }
    return;
}

# maintenance routine to erase all directories that look like
# temporary IPC directories.
#
# can invoke with
#
#    $ perl -MForks::Super=cleanse
#    $ perl -MForks::Super=cleanse,<directory>
#
sub cleanse {

    $_CLEANUP = 1;
    my $dir = shift;
    if (!defined $dir) {
	_identify_shared_fh_dir();
	$dir = $_IPC_DIR;
    }
    $dir =~ s![\\/]\.fhfork[^\\/]*$!!;
    if (! -e $dir) {
	print "No Forks::Super ipc files found under directory \"$dir\"\n";
	return;
    }
    print "Cleansing ipc directories under $dir\n";
    chdir $dir
	or croak "Forks::Super::Job::Ipc::cleanse: Can't move to $_IPC_DIR\n";
    opendir(D, '.');

    foreach my $ipc_dir (grep { -d $_ && /^\.fhfork/ } readdir (D)) {
	_cleanse_ipc_dir($ipc_dir);
    }
    closedir D;
    return;
}

sub _cleanse_dir {
    my $dir = shift;
    my $dh;

    opendir $dh, $dir;
    my $errors = 0;
    while (my $f = readdir($dh)) {
	next if $f eq '.' || $f eq '..';
	if (-d "$dir/$f") {
	    $errors += _cleanse_dir("$dir/$f");
	} else {
	    unlink "$dir/$f" or $errors++;
	}
    }
    closedir $dh;
    if (!$errors) {
	rmdir $dir and print "Removed $dir\n";
    }
    return $errors;
}

sub _cleanse_ipc_dir {
    my $ipc_dir = shift;

    if ($DEBUG) {
	print STDERR "cleanse $ipc_dir ?\n";
    }

    # try not to remove a directory for a running process ...
    return if _ipc_dir_used_by_live_process($ipc_dir);

    my $errors = _cleanse_dir($ipc_dir);
    if ($errors > 0) {
	no Carp;

	# on MSWin32, errors often mean that an existing process
	# is hanging on to these files?
	if ($^O eq 'MSWin32') {
	    warn "Encountered $errors errors cleaning up $ipc_dir:\n$^E\n";
	} else {
	    warn "Encounted $errors errors cleaning up $ipc_dir\n";
	}
    }
    return;
}

sub _ipc_dir_used_by_live_process {
    my $ipc_dir = shift;
    my $fh;
    if (!(-f "$ipc_dir/README.txt" && open $fh, '<', "$ipc_dir/README.txt")) {
	return 0;
    }
    scalar <$fh>; # header
    scalar <$fh>; # localtime 2
    my ($t, $pid) = split /\s+/, <$fh>;
    close $fh;
    if (!$t || !$pid) {
	# ipc dir mostly removed, just rmdir operation failed?
	return 0;
    }

    if ($DEBUG) {
	print STDERR "pid=$pid, t=$t, age=",time-$t,"\n";
    }

    if ($t < time - 86400) {
	# process started 24hrs ago
	return 0;
    }
    if (! CORE::kill(0, $pid)) {
	# process can't be signalled
	return 0;
    }
    if ($^O ne 'MSWin32' && -e "/proc/$pid" &&
	(-C "/proc/$pid") < (-C $ipc_dir)) {
	# /proc dir is younger than ipc_dir.
	# may be a new process with the same process id
	return 0;
    }

    # how else can we find the age of a running process?
    # especially on Windows?

    warn "Process $pid appears to still be running. ",
	        "Will not erase ipc dir $ipc_dir\n";
    return 1;
}

sub _END_foreground_cleanup {
    return 1 if $_CLEANUP++;
    if ($INC{'Devel/Trace.pm'}) {
	no warnings 'once';
	$Devel::Trace::TRACE = 0;
    }

    foreach my $job (@Forks::Super::ALL_JOBS) {
	next unless ref $job;
	$job->close_fh('all');
    }
    foreach my $fh (values %Forks::Super::CHILD_STDIN,
		    values %Forks::Super::CHILD_STDOUT,
		    values %Forks::Super::CHILD_STDERR) {
	# _close($fh);
	delete $__OPEN_FH{fileno($fh) || -1};
	$__OPEN_FH -= close($fh) || 0;
    }

    # daemonize if there is anything to clean up
    my @unused_files = grep { ! -e $_ } keys %IPC_FILES;
    foreach my $unused_file (@unused_files) {
	delete $IPC_FILES{$unused_file};
    }

    if (0 == scalar keys %IPC_FILES) {
	if (!defined($IPC_DIR_DEDICATED)
	    || ! -d $_IPC_DIR || rmdir $_IPC_DIR) {
	    return 1;
	}
    }

    umask 0;
    return;
}

sub _END_background_cleanup1 {
    # rename process, if supported by the OS, to note that we are cleaning up
    # not everyone will like this "feature"
    local $0 = "Forks::Super:cleanup:$0";
    CORE::sleep 3;

    # removing all the files we created during IPC
    # doesn't always go smoothly. We'll give a
    # 3/4-assed effort to remove the files but
    # nothing more heroic than that.

    my %deleted = ();
    foreach my $ipc_file (keys %IPC_FILES) {
	if (! -e $ipc_file) {
	    $deleted{$ipc_file} = delete $IPC_FILES{$ipc_file};
	} else {
	    local $! = undef;
	    if ($DEBUG) {
		print STDERR "Deleting $ipc_file ... ";
	    }
	    my $z = unlink $ipc_file;
	    if ($z && ! -e $ipc_file) {
		if ($DEBUG) {
		    print STDERR "Delete $ipc_file ok\n";
		}
		$deleted{$ipc_file} = delete $IPC_FILES{$ipc_file};
	    } else {
		if ($DEBUG) {
		    print STDERR "Delete $ipc_file failed: $!\n";
		}
		warn 'Forks::Super::END_cleanup: ',
		    "error disposing of ipc file $ipc_file: $z/$!\n";
	    }
	}
    }
    return %deleted;
}

sub _END_background_cleanup2 {
    # best efforts to cleanup the IPC files
    my %G = @_;
    my $z = rmdir($_IPC_DIR) || 0;
    if (!$z) {
	unlink glob("$_IPC_DIR/*");
	CORE::sleep 5;
	$z = rmdir($_IPC_DIR) || 0;
    }

    if (!$z
	&& -d $_IPC_DIR
	&& glob("$_IPC_DIR/.nfs*")) {

	# Observed these files on Linux running from NSF mounted filesystem
	# .nfsXXX files are usually temporary (~30s) but hard to kill
	for my $i (1..10) {
	    CORE::sleep 5;
	    last unless glob("$_IPC_DIR/.nfs*");
	}
	$z = rmdir($_IPC_DIR) || 0;
    }

    if (!$z && -d $_IPC_DIR) {

	warn "Forks::Super::END_cleanup: rmdir $_IPC_DIR failed. $!\n";

	opendir(my $_Z, $_IPC_DIR);
	my @g = grep { !/^\.nfs/ } readdir($_Z);
	closedir $_Z;
    }
    return;
}

# if we have created temporary files for IPC, clean them up.
# clean them up even if the children are still alive -- these files
# are exclusively for IPC, and IPC isn't needed after the parent
# process is done.
sub END_cleanup {

    if ($$ != ($Forks::Super::MAIN_PID || $MAIN_PID)) {
	return;
    }

    return if _END_foreground_cleanup();

    return if CORE::fork();
    exit 0 if CORE::fork();

    my %G = _END_background_cleanup1();

    return if !defined $IPC_DIR_DEDICATED;
    return if 0 < scalar keys %IPC_FILES;

    my $zz = rmdir($_IPC_DIR) || 0;
    return if $zz;

    CORE::sleep 2;
    exit 0 if CORE::fork();

    # long sleep here for maximum portability.
    CORE::sleep 10;
    _END_background_cleanup2();
    return;
}

sub END_cleanup_MSWin32 {
    return if $$ != ($Forks::Super::MAIN_PID || $MAIN_PID);
    return if $_CLEANUP++;
    $0 = "Forks::Super:cleanup:$0";

    # Use brute force to close all open handles. Leave STDERR open for warns.
    # XXX - is this ok? what if perl script is communicating with a socket?
    use POSIX ();
    for (0,1,3..999) {
        no warnings;
	POSIX::close($_);
    }

    Forks::Super::Job::dispose(@Forks::Super::ALL_JOBS);

    my @G = grep { -e $_ } keys %IPC_FILES;
  FILE_TRY: for my $try (1 .. 3) {
        if (@G == 0) {
	    last FILE_TRY;
	}
	foreach my $G (@G) {
	    local $! = undef;
	    if (!unlink $G) {
		undef $!;
		$G =~ s!/!\\!;
		my $c1 = system("CMD /C DEL /Q \"$G\" 2> NUL");
	    }
	}
    } continue {
	CORE::sleep 1;
	@G = grep { -e $_ } keys %IPC_FILES;
    }

    if (@G != 0) {
	# in Windows, remaining files might be "being used by another process".
	my $dir = $_IPC_DIR;
	$dir =~ s!\\!/!g;
	$dir =~ s!/[^/]+$!!;
	warn 'Forks::Super: failed to clean up ', scalar @G, " temp files.\n",
		"Run  $^X -MForks::Super=cleanse,$dir  ",
		"after this program has ended.\n";
	return;
    }

    if (defined $IPC_DIR_DEDICATED && -d $_IPC_DIR) {
	local $! = undef;
	my $z = rmdir $_IPC_DIR;
	if (!$z) {
	    warn 'Forks::Super: failed to remove dedicated ',
	    	"temp file directory $_IPC_DIR: $!\n";
	}
    }
    return;
}

sub _config_fh_parent_stdin {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    if (defined $fh_config->{stdin}) {
	debug('Passing STDIN from parent to child in scalar variable')
	    if $job->{debug};
	return;
    }

    if ($fh_config->{in}) {
	# intialize $fh_config->{child_stdin}

	if ($fh_config->{sockets}) {
	    __config_fh_parent_stdin_sockets($job);
	} elsif ($fh_config->{pipes}) {
	    __config_fh_parent_stdin_pipes($job);
	} elsif (defined $fh_config->{f_in}) {
	    __config_fh_parent_stdin_file($job);
	} else {
	    # hope we don't / can't get here.
	    Carp::cluck 'fh_config->{in} is specified for ',
                        $job->toFullString(),
                        "but we did not configure it in ",
                        "_config_fh_parent_stdin.\n";
	}
    }
    if (defined $job->{child_stdin}) {
	my $fh = $job->{child_stdin};
	$$fh->{job} = $job;
	$$fh->{purpose} = 'parent write to child stdin';
	$$fh->{is_write} = 1;
    }
    return;
}

sub _apply_layers {
    my ($handle, @layers) = @_;
    foreach my $layer (@layers) {
	for my $redo (1..2) {
	    local $!=0;
	    last if binmode $handle, $layer;
	    if ($redo == 2) {
		carp "Forks::Super: failed to apply PerlIO layer $layer ",
	            "to handle $handle";
	    }
	    Forks::Super::Util::pause(0.01 * $redo);
	}
    }
    return;
}

sub __config_fh_parent_stdin_sockets {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    shutdown $fh_config->{psock_in}, 0;
    ${$fh_config->{psock_in}}->{_SHUTDOWN} = 1;
    push @SAFEOPENED, [ shutdown => $fh_config->{psock_in}, 1 ];
    if ($USE_TIE_SH) {
	$fh_config->{s_in} = _gensym();
	tie *{$fh_config->{s_in}}, 'Forks::Super::Tie::IPCSocketHandle',
	    $fh_config->{psock_in}, $fh_config->{s_in};
    } else {
	$fh_config->{s_in} = $fh_config->{psock_in};
	#_apply_layers($fh_config->{s_in}, @{$fh_config->{layers}})
	#    if $fh_config->{layers};
    }
    $job->{child_stdin}
        = $Forks::Super::CHILD_STDIN{$job->{real_pid}}
        = $Forks::Super::CHILD_STDIN{$job->{pid}}
        = $fh_config->{s_in};
    $fh_config->{f_in} = '__socket__';
    debug("Setting up socket to $job->{pid} stdin $fh_config->{s_in} ",
	  CORE::fileno($fh_config->{s_in})) if $job->{debug};
    return;
}

sub __config_fh_parent_stdin_pipes {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    if ($USE_TIE_PH) {
	my $ph = _gensym();
	tie *$ph, 'Forks::Super::Tie::IPCPipeHandle',
                $fh_config->{p_to_in}, $ph;
	$job->{child_stdin}
	    = $Forks::Super::CHILD_STDIN{$job->{real_pid}}
	    = $Forks::Super::CHILD_STDIN{$job->{pid}}
	    = $ph;
    } else {
	$job->{child_stdin}
	    = $Forks::Super::CHILD_STDIN{$job->{real_pid}}
	    = $Forks::Super::CHILD_STDIN{$job->{pid}}
	    = $fh_config->{p_to_in};
	#_apply_layers($fh_config->{p_to_in}, @{$fh_config->{layers}})
	#	if $fh_config->{layers};
    }
    $fh_config->{f_in} = '__pipe__';
    debug("Setting up pipe to $job->{pid} stdin $fh_config->{p_to_in} ",
	  CORE::fileno($fh_config->{p_to_in})) if $job->{debug};
    return;
}

sub __config_fh_parent_stdin_file {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    my $fh;
    local $! = 0;
    if (_safeopen($job, $fh, '>', $fh_config->{f_in})) {

	debug("Opening $fh_config->{f_in} in parent as child STDIN")
	    if $job->{debug};
	$job->{child_stdin}
	  = $Forks::Super::CHILD_STDIN{$job->{real_pid}}
	  = $fh;
	$Forks::Super::CHILD_STDIN{$job->{pid}} = $fh;
        $job->{child_stdin}->autoflush(1);

        debug('Opened child STDIN (',fileno($fh),') in parent')
            if $job->{debug};

    } else {
	warn 'Forks::Super::Job::config_fh_parent(): ',
		  'could not open file handle to write child STDIN (to ',
		  $fh_config->{f_in}, "): $!\n";
    }
    return;
}

sub _config_fh_parent_stdout {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    if ($fh_config->{out} && $fh_config->{sockets}) {
	__config_fh_parent_stdout_sockets($job);
    } elsif ($fh_config->{out} && $fh_config->{pipes}) {
	__config_fh_parent_stdout_pipes($job);
    } elsif ($fh_config->{out} and defined $fh_config->{f_out}) {
	__config_fh_parent_stdout_file($job);
    }
    if (defined $job->{child_stdout}) {
	my $fh = $job->{child_stdout};
	$$fh->{is_read} = 1;
	$$fh->{job} = $job;
	$$fh->{purpose} = 'parent read from child stdout';
    }
    if ($fh_config->{block}) {
	${$job->{child_stdout}}->{emulate_blocking} = 1;
    }
    if ($fh_config->{join}) {
	delete $fh_config->{err};
	$job->{child_stderr}
	      = $Forks::Super::CHILD_STDERR{$job->{real_pid}}
	      = $Forks::Super::CHILD_STDERR{$job->{pid}}
	      = $job->{child_stdout};
	$fh_config->{f_err} = $fh_config->{f_out};
	debug("Joining stderr to stdout for $job->{pid}") if $job->{debug};
    }
    return;
}

sub __config_fh_parent_stdout_sockets {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    shutdown $fh_config->{psock_out}, 1;
    ${$fh_config->{psock_out}}->{_SHUTDOWN} = 2;
    push @SAFEOPENED, [ shutdown => $fh_config->{psock_out}, 0 ];
    if ($USE_TIE_SH) {
	$fh_config->{s_out} = _gensym();
	tie *{$fh_config->{s_out}}, 'Forks::Super::Tie::IPCSocketHandle',
	    $fh_config->{psock_out}, $fh_config->{s_out};
    } else {
	$fh_config->{s_out} = $fh_config->{psock_out};
	if ($fh_config->{layers}) {
	    _apply_layers($fh_config->{s_out}, @{$fh_config->{layers}});
	}
    }
    $job->{child_stdout} = $Forks::Super::CHILD_STDOUT{$job->{real_pid}}
        = $Forks::Super::CHILD_STDOUT{$job->{pid}} = $fh_config->{s_out};
    $fh_config->{f_out} = '__socket__';
    debug("Setting up socket to $job->{pid} stdout $fh_config->{s_out} ",
	  CORE::fileno($fh_config->{s_out})) if $job->{debug};
    return;
}

sub __config_fh_parent_stdout_pipes {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    if ($USE_TIE_PH) {
	my $ph = _gensym();
	tie *$ph, 'Forks::Super::Tie::IPCPipeHandle', $fh_config->{p_out}, $ph;
	$job->{child_stdout}
	    = $Forks::Super::CHILD_STDOUT{$job->{real_pid}}
	    = $Forks::Super::CHILD_STDOUT{$job->{pid}}
	    = $ph;
    } else {

	$job->{child_stdout}
 	    = $Forks::Super::CHILD_STDOUT{$job->{real_pid}}
	    = $Forks::Super::CHILD_STDOUT{$job->{pid}}
	    = $fh_config->{p_out};
	if ($fh_config->{layers}) {
	    _apply_layers($fh_config->{p_out}, @{$fh_config->{layers}});
	}
    }
    $fh_config->{f_out} = '__pipe__';
    debug("Setting up pipe to $job->{pid} stdout $fh_config->{p_out} ",
	  CORE::fileno($fh_config->{p_out})) if $job->{debug};
    return;
}

sub _config_fh_parent_stress {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    return unless $fh_config->{stress};
    
    for my $n (1 .. $_FILEHANDLES_PER_STRESSED_JOB) {
	my $fh;
	local $! = 0;
	my $fkey = "f_stress_" . $n;
	if (_safeopen($job, $fh, '<', $fh_config->{$fkey}, robust => 1)) {
	    $job->{"child_stress_$n"} = $fh;
	} else {
	    my $_msg = sprintf "%d: %s Failed to open f_stress_%d:%s: %s\n",
	    	$$, Forks::Super::Util::Ctime(), $n, $fh_config->{$fkey}, $!;

	    warn 'Forks::Super::Job::config_fh_parent(): ',
	        'could not open file handle to read child STDOUT (from ',
	    $fh_config->{$fkey}, "): $!\n";
	}
    }
    return;
}

sub __config_fh_parent_stdout_file {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    # creation of $fh_config->{f_out} may be delayed.
    # don't panic if we can't open it right away.
    my $fh;
    debug('Opening ', $fh_config->{f_out}, ' in parent as child STDOUT')
	if $job->{debug};
    local $! = 0;

    if (_safeopen($job, $fh, '<', $fh_config->{f_out}, robust => 1)) {

	debug('Opened child STDOUT (',fileno($fh),') in parent')
            if $job->{debug};
	$job->{child_stdout} = $Forks::Super::CHILD_STDOUT{$job->{real_pid}}
		= $Forks::Super::CHILD_STDOUT{$job->{pid}} = $fh;

	debug("Setting up link to $job->{pid} stdout in $fh_config->{f_out}")
	    if $job->{debug};

    } else {
	my $_msg = sprintf "%d: %s Failed to open f_out=%s: %s\n",
		$$, Forks::Super::Util::Ctime(), $fh_config->{f_out}, $!;

	warn 'Forks::Super::Job::config_fh_parent(): ',
	  'could not open file handle to read child STDOUT (from ',
	  $fh_config->{f_out}, "): $!\n";
    }
    return;
}

sub _config_fh_parent_stderr {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    if ($fh_config->{err} && $fh_config->{sockets}) {
	__config_fh_parent_stderr_sockets($job);
    } elsif ($fh_config->{err} && $fh_config->{pipes}) {
	__config_fh_parent_stderr_pipes($job);
    } elsif ($fh_config->{err} and defined $fh_config->{f_err}) {
	__config_fh_parent_stderr_file($job);
    }
    if (defined $job->{child_stderr}) {
	my $fh = $job->{child_stderr};
	$$fh->{is_read} = 1;
	$$fh->{job} = $job;
	$$fh->{purpose} = 'parent read from child stderr';
    }
    if ($fh_config->{block}) {
	${$job->{child_stderr}}->{emulate_blocking} = 1;
    }
    return;
}

sub __config_fh_parent_stderr_sockets {
    my $job = shift;
    my $fh_config = $job->{fh_config};
  
    shutdown $fh_config->{psock_err}, 1;
    ${$fh_config->{psock_err}}->{_SHUTDOWN} = 2;
    push @SAFEOPENED, [ shutdown => $fh_config->{psock_err}, 0 ];
    if ($USE_TIE_SH) {
	$fh_config->{s_err} = _gensym();
	tie *{$fh_config->{s_err}}, 'Forks::Super::Tie::IPCSocketHandle',
	    $fh_config->{psock_err}, $fh_config->{s_err};
    } else {
	$fh_config->{s_err} = $fh_config->{psock_err};
	if ($fh_config->{layers}) {
	    _apply_layers($fh_config->{s_err}, @{$fh_config->{layers}});
	}
    }

    $job->{child_stderr}
        = $Forks::Super::CHILD_STDERR{$job->{real_pid}}
        = $Forks::Super::CHILD_STDERR{$job->{pid}}
        = $fh_config->{s_err};
    $fh_config->{f_err} = '__socket__';
    debug("Setting up socket to $job->{pid} stderr $fh_config->{s_err} ",
	  CORE::fileno($fh_config->{s_err})) if $job->{debug};
    return;
}

sub __config_fh_parent_stderr_pipes {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    if ($USE_TIE_PH) {
	my $ph = _gensym();
	tie *$ph, 'Forks::Super::Tie::IPCPipeHandle', $fh_config->{p_err}, $ph;

	$job->{child_stderr}
	    = $Forks::Super::CHILD_STDERR{$job->{real_pid}}
	    = $Forks::Super::CHILD_STDERR{$job->{pid}}
	    = $ph;
    } else {
	$job->{child_stderr}
	    = $Forks::Super::CHILD_STDERR{$job->{real_pid}}
	    = $Forks::Super::CHILD_STDERR{$job->{pid}}
	    = $fh_config->{p_err};
	if ($fh_config->{layers}) {
	    _apply_layers($fh_config->{p_err}, @{$fh_config->{layers}});
	}
    }
    $fh_config->{f_err} = '__pipe__';
    debug("Setting up pipe to $job->{pid} stderr ",
	  CORE::fileno($fh_config->{p_err})) if $job->{debug};
    return;
}

sub __config_fh_parent_stderr_file {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    delete $fh_config->{join};
    my $fh;
    debug('Opening ', $fh_config->{f_err}, ' in parent as child STDERR')
	if $job->{debug};
    local $! = 0;
    if (_safeopen($job, $fh, '<', $fh_config->{f_err}, robust => 1)) {

	debug('Opened child STDERR (',fileno($fh),') in parent')
            if $job->{debug};
	$job->{child_stderr}
		= $Forks::Super::CHILD_STDERR{$job->{real_pid}}
		= $Forks::Super::CHILD_STDERR{$job->{pid}}
		= $fh;

	debug("Setting up link to $job->{pid} stderr in $fh_config->{f_err}")
	    if $job->{debug};

    } else {
	my $_msg = sprintf "%d: %s Failed to open f_err=%s: %s\n",
		$$, Forks::Super::Util::Ctime(), $fh_config->{f_err}, $!;
	warn 'Forks::Super::Job::config_fh_parent(): ',
	  'could not open file handle to read child STDERR (from ',
	  $fh_config->{f_err}, "): $!\n";
    }
    return;
}

#
# open file handles to the STDIN, STDOUT, STDERR processes of the job
# to be used by the parent. Presumably the child process is opening
# the same files at about the same time.
#
sub Forks::Super::Job::_config_fh_parent {
    my ($job,$step) = @_;
    return if not defined $job->{fh_config};
    my $fh_config = $job->{fh_config};

    # set up stdin first, so child has more time to set up stdout and stderr
    if ($step != 2) {
        _config_fh_parent_stdin($job);
        return;
    }
    _config_fh_parent_stdout($job);
    _config_fh_parent_stderr($job);

    _config_fh_parent_stress($job);

    if ($job->{fh_config}{sockets}) {

	# is it helpful or necessary for the parent to close the
	# "child" sockets? Yes, apparently, for MSWin32.

	if (!$USE_TIE_SH) {
	    foreach my $channel (qw(in out err)) {
		my $s = $job->{fh_config}{"csock_$channel"};
		_close($s);
	    }
	}
    }
    if ($job->{fh_config}{pipes}) {
	foreach my $pipeattr (qw(p_in p_to_out p_to_err)) {
	    if (defined $job->{fh_config}{$pipeattr}) {
		_close( $job->{fh_config}{$pipeattr} );
		delete $job->{fh_config}{$pipeattr};
	    }
	}
    }

    return;
}

sub _config_fh_child_stdin {
    my $job = shift;
    local $! = undef;
    my $fh_config = $job->{fh_config};
    if ($fh_config->{suppress} && $fh_config->{suppress}{in}) {
	close STDIN;
        open STDIN, '<', Forks::Super::Util::DEVNULL();
	return;
    }
    if (!$fh_config->{in}) {
	close STDIN;
        open STDIN, '<', Forks::Super::Util::DEVNULL();
	return;
    }

    if (defined $fh_config->{stdin}) {
	__config_fh_child_stdin_scalar($job);
    } elsif ($fh_config->{sockets}) {
	__config_fh_child_stdin_sockets($job);
    } elsif ($fh_config->{pipes}) {
	__config_fh_child_stdin_pipes($job);
    } elsif ($fh_config->{f_in}) {
	__config_fh_child_stdin_file($job);
    } else {
	carp 'Forks::Super::Job::Ipc: failed to configure child STDIN: ',
		'fh_config = ', join(' ', %{$job->{fh_config}});
    }
    ${*STDIN}->{is_read} = 1;
    ${*STDIN}->{job} = $job;
    ${*STDIN}->{purpose} = "child $$ STDIN from parent " . $job->{ppid};
    if (defined($fh_config->{block}) && $fh_config->{block}) {
	${*STDIN}->{emulate_blocking} = 1;
    }
    return;
}

sub __config_fh_child_stdin_scalar {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    my $fh;
    if ($fh_config->{sockets} || $fh_config->{pipes}) {
	my $stdin = $fh_config->{stdin};
	if (_safeopen($job, $fh, '<', \$stdin)) {

	    push @{$job->{child_fh_close}}, $fh;
	    close STDIN if &IS_WIN32;
	    *STDIN = $fh;
	    ${*STDIN}->{dup} = $fh;

	} else {
	    carp 'Forks::Super::Job::Ipc::_config_fh_child_stdin: ',
		    "Error initializing scalar STDIN in child $$: $!\n";
	}
        return;
    }
    if (!_safeopen($job, $fh, '<', $fh_config->{f_in}, no_layers => 1)) {
	carp 'Forks::Super::Job::Ipc::_config_fh_child_stdin(): ',
            "Error initializing scalar STDIN in child $$: $!\n";
        return;
    }
    if (!_safeopen($job, *STDIN, '<&', $fh)) {
	carp 'Forks::Super::Job::Ipc::_config_fh_child_stdin(): ',
        "Error initializing scalar STDIN in child $$: $!\n";
        close $fh;
        return;
    }
    push @{$job->{child_fh_close}}, $fh;
    return;
}


sub __config_fh_child_stdin_sockets {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    close STDIN if &IS_WIN32;
    shutdown $fh_config->{csock_in}, 1;
    ${$fh_config->{csock_in}}->{_SHUTDOWN} = 2;
    push @SAFEOPENED, [ shutdown => $fh_config->{csock_in}, 0 ];
    if ($USE_TIE_SH && $job->{style} ne 'cmd' && $job->{style} ne 'exec') {
	my $fh = _gensym();
	tie *$fh, 'Forks::Super::Tie::IPCSocketHandle',
		$fh_config->{csock_in}, $fh;
	*STDIN = *$fh;
	${*STDIN}->{std_delegate} = $fh;
    } else {

	if (!(_safeopen($job, *STDIN, '<&', $fh_config->{csock_in}))) {
	    warn 'Forks::Super::Job::_config_fh_child_stdin(): ',
		    "could not attach child STDIN to input sockethandle: $!\n";
	}
    }
    debug('Opening socket ',*STDIN,'/',CORE::fileno(STDIN), ' in child STDIN')
	if $job->{debug};
    return;
}

sub __config_fh_child_stdin_pipes {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    push @{$job->{child_fh_close}}, $fh_config->{p_in};
    close STDIN;
    if ($USE_TIE_PH && $job->{style} ne 'cmd' && $job->{style} ne 'exec') {
	my $ph = _gensym();
	tie *$ph, 'Forks::Super::Tie::IPCPipeHandle', $fh_config->{p_in}, $ph;
	*STDIN = *$ph;
	${*STDIN}->{std_delegate} = $ph;
    } elsif (!(_safeopen($job, *STDIN, '<&', $fh_config->{p_in}))) {
	warn 'Forks::Super::Job::_config_fh_child_stdin(): ',
		"could not attach child STDIN to input pipe: $!\n";
    } else {
	push @{$job->{child_fh_close}}, *STDIN;
    }
    debug('Opening pipe ',*STDIN,'/',CORE::fileno(STDIN), ' in child STDIN')
	if $job->{debug};
    return;
}

sub __config_fh_child_stdin_file {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    close STDIN if &IS_WIN32;

    my $fh;
    if (_safeopen($job, $fh, '<', $fh_config->{f_in})) {
	push @{$job->{child_fh_close}}, $fh;

	if ($fh_config->{block}) {
	    $$fh->{emulate_blocking} = 1;
	}
	$$fh->{purpose} = 'child read stdin from parent';

	if ($job->{style} eq 'cmd' || $job->{style} eq 'exec') {
	    _safeopen($job, *STDIN, '<&', $fh, robust => 1)
		or warn 'Forks::Super::Job::config_fh_child(): ',
	    	        'could not attach child STDIN ',
                "to input file handle: $!\n";
        } elsif (0) {
	    _safeopen($job, *STDIN, '<&', $fh, robust => 1)
		or warn 'Forks::Super::Job::config_fh_child(): ',
	    	        'could not attach child STDIN ',
                "to input file handle: $!\n";
	} else {
	    tie *STDIN, 'Forks::Super::Tie::IPCDupSTDIN', 
	        GLOB => $fh, 
	        JOB => &Forks::Super::Job::this,
	        TIED => tied(*$fh);
	}
	if ($job->{debug}) {
	    debug("reopened STDIN in child");
	}
    } else {
	warn 'Forks::Super::Job::config_fh_child(): ',
		"could not open file handle to provide child STDIN: $!\n";
    }
    return;
}

sub _config_fh_child_stdout {
    my $job = shift;
    local $! = undef;
    my $fh_config = $job->{fh_config};
    if ($fh_config->{suppress} && $fh_config->{suppress}{out}) {
	close STDOUT;
        open STDOUT, '>', Forks::Super::Util::DEVNULL();
	return;
    }
    return if ! $fh_config->{out};

    if ($fh_config->{sockets}) {
	__config_fh_child_stdout_sockets($job);
    } elsif ($fh_config->{pipes}) {
	__config_fh_child_stdout_pipes($job);
    } elsif ($fh_config->{f_out}) {
	__config_fh_child_stdout_file($job);
    } else {
	carp 'Forks::Super::Job::Ipc: failed to configure child STDOUT: ',
		'fh_config = ', join(' ', %{$job->{fh_config}});
    }
    ${*STDOUT}->{is_write} = 1;
    return;
}

sub __config_fh_child_stdout_sockets {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    close STDOUT;
    shutdown $fh_config->{csock_out}, 0;
    ${$fh_config->{csock_out}}->{_SHUTDOWN} = 1;
    push @SAFEOPENED, [ shutdown => $fh_config->{csock_out}, 1 ];
    if ($USE_TIE_SH && $job->{style} ne 'cmd' && $job->{style} ne 'exec') {
	my $fh = _gensym();
	tie *$fh, 'Forks::Super::Tie::IPCSocketHandle',
		$fh_config->{csock_out}, $fh;
	*STDOUT = *$fh;
	${*STDOUT}->{std_delegate} = $fh;
    } else {
	_safeopen($job, *STDOUT, '>&', $fh_config->{csock_out})
	    or warn 'Forks::Super::Job::_config_fh_child_stdout(): ',
	        "could not attach child STDOUT to output sockethandle: $!\n";
    }

    debug('Opening ',*STDOUT,'/',CORE::fileno(STDOUT),' in child STDOUT')
	if $job->{debug};

    if ($fh_config->{join}) {
	delete $fh_config->{err};
	close STDERR;
	_safeopen($job, *STDERR, '>&', $fh_config->{csock_out})
	    or warn 'Forks::Super::Job::_config_fh_child_stdout(): ',
		    "could not join child STDERR to STDOUT sockethandle: $!\n";

	debug('Joining ',*STDERR,'/',CORE::fileno(STDERR),
	      ' STDERR to child STDOUT') if $job->{debug};
    }
    return;
}

sub __config_fh_child_stdout_pipes {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    close STDOUT;
    if ($USE_TIE_PH) {
	my $fh = _gensym();
	tie *$fh, 'Forks::Super::Tie::IPCPipeHandle',
                $fh_config->{p_to_out}, $fh;
	*STDOUT = *$fh;
	${*STDOUT}->{std_delegate} = $fh;
    } else {
	_safeopen($job, *STDOUT, '>&', $fh_config->{p_to_out})
	    or warn 'Forks::Super::Job::_config_fh_child_stdout(): ',
		    "could not attach child STDOUT to output pipe: $!\n";
    }
    if ($job->{debug}) {
	debug('Opening ',*STDOUT,'/',CORE::fileno(STDOUT),' in child STDOUT');
    }
    push @{$job->{child_fh_close}}, $fh_config->{p_to_out}, *STDOUT;

    if ($fh_config->{join}) {
	delete $fh_config->{err};
	close STDERR;
	_safeopen($job, *STDERR, '>&', $fh_config->{p_to_out})
	    or warn 'Forks::Super::Job::_config_fh_child_stdout(): ',
		    "could not join child STDERR to STDOUT sockethandle: $!\n";
	push @{$job->{child_fh_close}}, *STDERR;
    }
    return;
}

sub __config_fh_child_stdout_file {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    my $fh;
    debug("Opening up $fh_config->{f_out} for output in the child   $$")
	if $job->{debug};
    if (_safeopen($job, $fh,'>',$fh_config->{f_out}, no_layers => 1)) {
	push @{$job->{child_fh_close}}, $fh;
	close STDOUT if &IS_WIN32;

	# can we pass undef fh to _safeopen and reassign to *STDOUT?
	# t/25 says no. Probably because we have already added a ton of
	# stuff to the $fh namespace?
	if (_safeopen($job, *STDOUT, '>&', $fh)) {
	    if ($fh_config->{join}) {
		delete $fh_config->{err};
		close STDERR if &IS_WIN32;
		_safeopen($job, *STDERR, '>&', $fh)
		    or warn 'Forks::Super::Job::config_fh_child(): ',
		        "could not attach STDERR to child output file handle: ",
		        "$!\n";
	    }
	} else {
	    warn 'Forks::Super::Job::config_fh_child(): ',
	        "could not attach STDOUT to child output file handle: $!\n";
	}
    } else {
	warn 'Forks::Super::Job::config_fh_child(): ',
	    "could not open file handle to provide child STDOUT: $!\n";
    }
    return;
}

sub _config_fh_child_stress {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    return unless $fh_config->{stress};

    for my $n (1 .. $_FILEHANDLES_PER_STRESSED_JOB) {
	my $fkey = "f_stress_" . $n;
	next unless $fh_config->{$fkey};
	my $fh;
	if (_safeopen($job,$fh,'>',$fh_config->{$fkey}, no_layers => 1)) {
	    push @{$job->{child_fh_close}}, $fh;
#	    my $glob = "main::STD$n";
#	    _safeopen($job, *$glob, '>&', $fh);
	}
    }
    return;
}

sub _config_fh_child_stderr {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    if ($fh_config->{suppress} && $fh_config->{suppress}{err}) {
	close STDERR;
        open STDERR, '>', Forks::Super::Util::DEVNULL();
	return;
    }
    return if ! $fh_config->{err};
    
    if ($fh_config->{sockets}) {
	__config_fh_child_stderr_sockets($job);
    } elsif ($fh_config->{pipes}) {
	__config_fh_child_stderr_pipes($job);
    } elsif ($fh_config->{f_err}) {
	__config_fh_child_stderr_file($job);
    } else {
	carp 'Forks::Super::Job::Ipc: failed to configure child STDERR: ',
	    'fh_config = ', join(' ', %{$job->{fh_config}});
    }
    ${*STDERR}->{is_write} = 1;

    # RT124316c: workaround for die in child not writing to STDERR
    $SIG{__DIE__} ||= sub { print STDERR @_ };

    return;
}

sub __config_fh_child_stderr_sockets {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    close STDERR;
    shutdown $fh_config->{csock_err}, 0;
    ${$fh_config->{csock_err}}->{_SHUTDOWN} = 1;
    push @SAFEOPENED, [ shutdown => $fh_config->{csock_err}, 1 ];
    if ($USE_TIE_SH && $job->{style} ne 'cmd' && $job->{style} ne 'exec') {
	my $fh = _gensym();

	tie *$fh, 'Forks::Super::Tie::IPCSocketHandle',
	    $fh_config->{csock_err}, $fh;
	*STDERR = *$fh;
	${*STDERR}->{std_delegate} = $fh;
    } else {
	_safeopen($job, *STDERR, '>&', $fh_config->{csock_err})
	    or warn 'Forks::Super::Job::_config_fh_child_stderr(): ',
	        "could not attach STDERR to child error sockethandle: $!\n";
    }
    if ($job->{debug}) {
	debug('Opening ',*STDERR,'/',CORE::fileno(STDERR),' in child STDERR');
    }
    return;
}

sub __config_fh_child_stderr_pipes {
    my $job = shift;
    my $fh_config = $job->{fh_config};

    push @{$job->{child_fh_close}}, $fh_config->{p_to_err};
    close STDERR;
    if ($USE_TIE_PH && $job->{style} ne 'cmd' && $job->{style} ne 'exec') {
	my $fh = _gensym();
	tie *$fh, 'Forks::Super::Tie::IPCPipeHandle', 
		$fh_config->{p_to_err}, $fh;
	*STDERR = *$fh;
	${*STDERR}->{std_delegate} = $fh;
    } elsif (_safeopen($job, *STDERR, '>&', $fh_config->{p_to_err})) {
	debug('Opening ',*STDERR,'/',CORE::fileno(STDERR),
	      ' in child STDERR') if $job->{debug};
	push @{$job->{child_fh_close}}, *STDERR;
    } else {
	warn 'Forks::Super::Job::_config_fh_child_stderr(): ',
	    "could not attach STDERR to child error pipe: $!\n";
    }
    return;
}

sub __config_fh_child_stderr_file {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    my $fh;
    debug("Opening $fh_config->{f_err} as child STDERR")
	if $job->{debug};
    if (_safeopen($job, $fh, '>', $fh_config->{f_err}, no_layers => 1)) {
	push @{$job->{child_fh_close}}, $fh;
	close STDERR if &IS_WIN32;
	_safeopen($job, *STDERR, '>&', $fh)
	    or warn 'Forks::Super::Job::_config_fh_child_stderr(): ',
		    "could not attach STDERR to child error file handle: $!\n";
    } else {
	warn 'Forks::Super::Job::_config_fh_child_stderr(): ',
		"could not open file handle to provide child STDERR: $!\n";
    }

    return;
}

#
# open handles to the files that the parent process will
# have access to, and assign them to the local STDIN, STDOUT,
# and STDERR file handles.
#
sub Forks::Super::Job::_config_fh_child {
    my $job = shift;
    return if not defined $job->{fh_config};

    # "a tie in the parent should not be allowed to cause problems"
    # according to IPC::Open3
    if (!$job->{is_emulation}) {
        untie *STDIN;
        untie *STDOUT;
        untie *STDERR;
    }

    # track handles to close when the child exits
    $job->{child_fh_close} = [];

    if ($job->{style} eq 'cmd' || $job->{style} eq 'exec') {
	if (&IS_WIN32 && Forks::Super::Config::CONFIG('filehandles')) {
	    return _config_cmd_fh_child($job);
	} elsif ($job->{is_emulation}) {
            return _config_cmd_fh_child($job);
        }
    }

    _config_fh_child_stdout($job);
    _config_fh_child_stderr($job);
    _config_fh_child_stdin($job);

    _config_fh_child_stress($job);

    if (!$USE_TIE_SH) {
	if ($job->{fh_config} && $job->{fh_config}{sockets}) {
	    foreach my $channel (qw(in out err)) {
		my $s = $job->{fh_config}{"psock_$channel"};
		if (defined $s) {
		    _close($s);
		}
	    }
	}
    }

    if ($job->{fh_config} && $job->{fh_config}{pipes}) {
	foreach my $pipeattr (qw(p_to_in p_out p_err)) {
	    if (defined $job->{fh_config}{$pipeattr}) {
		_close( $job->{fh_config}{$pipeattr} );
	    }
	}
    }
    return;
}

# not-idiot-proof compression of a list of command arguments
# into a single string with escaped metacharacters
sub _collapse_command {
    my @cmd = @_;
    if (@cmd <= 1) {
	return @cmd;
    }
    my @new_cmd = ();
    foreach my $cmd (@cmd) {
	if ($cmd !~ /[\s\'\"\[\]\;\(\)\<\>\t\|\?\&]/x) {
	    push @new_cmd, $cmd;
	} elsif ($cmd !~ /\"/) {
	    push @new_cmd, "\"$cmd\"";
	} elsif ($cmd !~ /\'/ && !&IS_WIN32) {
	    push @new_cmd, "'$cmd'";
	} else {
	    my $cmd2 = $cmd;
	    $cmd2 =~ s/([\s\'\"\\\[\]\;\(\)\<\>\t\|\?\&])/\\$1/gx;
	    push @new_cmd, "\"$cmd2\"";
	}
    }
    @cmd = (join ' ', @new_cmd);
    return @cmd;
}

# MSWin32 has trouble using the open '>&' and open '<&' syntax.
# We should also use shell I/O redirection in emulation mode
sub _config_cmd_fh_child {
    my $job = shift;
    my $fh_config = $job->{fh_config};
    my $cmd_or_exec = $job->{exec} ? 'exec' : 'cmd';
    my @cmd = @{$job->{$cmd_or_exec}};
    if (@cmd > 1) {
	@cmd = _collapse_command(@cmd);
        $job->{_indirect} = 0;
    }

    # XXX - not idiot proof. FH dir could have a metacharacter.
    if ($fh_config->{out} && $fh_config->{f_out}) {
	$cmd[0] .= " >\"$fh_config->{f_out}\"";
	if ($fh_config->{join}) {
	    $cmd[0] .= ' 2>&1';
            $job->{_indirect} = 0;
	}
    }
    if ($fh_config->{err} && $fh_config->{f_err} && !$fh_config->{join}) {
	$cmd[0] .= " 2>\"$fh_config->{f_err}\"";
        $job->{_indirect} = 0;
    }

    if ($fh_config->{f_in}) {

	# standard input must be specified before the first pipe char,
	# if any (How do you distinguish pipes that are
	# for shell piping, and pipes that are part of some command
	# or command line argument? The shell can do it, obviously,
	# but there is probably lots and lots of code to do it right.
	# And probably regex != doing it right).
	#
	# e.g., want to be able to handle:
	#    $^X -F/\\\|/ -alne '$_=$F[3]-$F[1]-$F[2]' | ./another_program
	#
	# and have input inserted after the SECOND |
	# To solve this we need to parse the command as well as the
	# shell does ...

	$cmd[0] = _insert_input_redir_to_cmdline_crudely(
			    $cmd[0], $fh_config->{f_in});
        $job->{_indirect} = 0;

	# external command must not launch until the input file has been created
	my $try;
	for ($try = 1; $try <= 10; $try++) {
	    if (-r $fh_config->{f_in}) {
		$try = 0;
		last;
	    }
	    Forks::Super::pause(0.2 * $try);
	}
	if ($try >= 10) {
	    warn 'Forks::Super::Job::config_cmd_fh_child(): ',
	    	"child was not able to detect STDIN file $fh_config->{f_in}. ",
	    	"Child may not have any input to read.\n";
	}
    } elsif (!$job->{is_emulation}) {
        close STDIN;
        open STDIN, '<', Forks::Super::Util::DEVNULL();
    }
    debug("config_cmd_fh_config(): child cmd is   $cmd[0]  ")
	if $job->{debug};

    $job->{$cmd_or_exec} = [ @cmd ];
    return;
}

sub _insert_input_redir_to_cmdline_crudely {
    my ($cmd, $input) = @_;

    # a crude parser that looks for the first unescaped
    # pipe char that is not inside single or double quotes,
    # or inside a () [] {} expression and inserts "< $input"
    # before that pipe char, or at the end of the line

    # XXX good enough to pass t/42e but I wonder what edge cases it misses.

    my @chars = split //, $cmd;
    my $result = '';
    my $insert = 0;
    my @group = ('');

    my %opener = qw! ) (  ] [  } { !;
    my %closer = reverse %opener;


    while (@chars) {
	my $char = shift @chars;
	$result .= $char;

	if ($char eq '\\') {
	    $result .= shift @chars;
	} elsif ($char eq '"') {
	    if ($group[-1] eq '"') {
		pop @group;
	    } elsif ($group[-1] ne "'") {
		push @group, '"';
	    }
	} elsif ($char eq "'") {
	    if ($group[-1] eq "'") {
		pop @group;
	    } elsif ($group[-1] ne '"') {
		push @group, "'";
	    }
	} elsif (exists $closer{$char}) {
	    push @group, $char;
	} elsif (exists $opener{$char} && $group[-1] eq $opener{$char}) {
	    pop @group;
	} elsif ($char eq '|' && @group <= 1) {
	    chop $result;
	    $result .= ' <"' . $input . '" | ';
	    $result .= join'', @chars;
	    @chars = ();
	    $insert = 1;
	}
    }
    if (!$insert) {
	$result .= ' <"' . $input . '"';
    }
    return $result;
}

sub _close {
    my $handle = shift;
    return 0 if !defined $handle;
    return 0 if $$handle->{closed};
    if (!defined $$handle->{opened}) {
	# this method should only be used with I/O handles
	# opened by Forks::Super
        Carp::cluck 'Forks::Super::Job::Ipc::_close ',
	    "called on unrecognized file handle $handle\n";
    }

    if (is_socket($handle)) {
	return _close_socket($handle,2);
    }

    _update_handle_for_close($handle);
    my $z = 0;
    my $is_tied = !!tied *$handle;

    fileno($handle) && delete $__OPEN_FH{fileno($handle)};
    if ($is_tied) {
	#my $th = tied *$handle;
	#my $z = $th->CLOSE;
	$z = (tied *$handle)->CLOSE;
	untie *$handle;
    } else {
	$z ||= close $handle;
    }
    if ($z) {
	$__OPEN_FH--;
	if ($DEBUG) {
	    if (defined($$handle->{glob})) {
		debug("$$ closing[2] IPC handle ",$$handle->{glob});
	    } else {
		debug("$$ closing[1] IPC handle ",$handle);
	    }
	}
    }
    return $z;
}

sub _update_handle_for_close {
    my $handle = shift;
    $$handle->{closed} ||= Time::HiRes::time();
    $$handle->{elapsed} ||= $$handle->{closed} - $$handle->{opened};
    return;
}

# close down one-half of a socket. If the other half is already closed,
# then call close on the socket.
sub _close_socket {
    my ($handle, $is_write) = @_;
    return 0 if !defined $handle;
    return 0 if $$handle->{closed};

    $$handle->{shutdown} ||= 0;
    return 0 if $$handle->{shutdown} >= 3;

    $is_write++;    #  0 => 1, 1 => 2, 2 => 3
    if (0 == ($$handle->{shutdown} & $is_write)) {
	my $z = $$handle->{shutdown} |= $is_write;
	if ($$handle->{shutdown} >= 3) {

	    _update_handle_for_close($handle);

	    my $sh = $handle;
	    my $th = tied *$handle;
	    if ($th && $th->isa('Forks::Super::Tie::IPCSocketHandle')) {
		$sh = $th->{SOCKET};
		$z = close $sh;

		# XXX - is untie necessary? see comment in _close()
		# this untie doesn't generate warnings, though ...
		untie *$handle;
		delete $__OPEN_FH{fileno($handle)};
		$z += close $handle;
	    } else {
		$z = close $handle;
		if ($th) {
		    # XXX - is untie necessary? see comment in _close()
		    # no warnings from this untie, though ...
		    untie *$handle;
		    delete $__OPEN_FH{fileno($handle)};
		    $z += close $handle;
		}
	    }
	    $__OPEN_FH--;
	    if ($DEBUG) {
		debug("$$ Closing IPC socket $$handle->{glob}");
	    }
	}
	return $z;
    }
}

sub _close_fh_stdin {
    my $job = shift;
    if (defined($job->{child_stdin}) && !defined($job->{child_stdin_closed})) {
	if (is_socket($job->{child_stdin})) {
	    if (_close_socket($job->{child_stdin}, 1)) {
		$job->{child_stdin_closed} = 1;
		debug("closed child stdin for $job->{pid}") if $job->{debug};
	    }
	} else {
	    if (_close($job->{child_stdin})) {
		$job->{child_stdin_closed} = 1;
		debug("closed child stdin for $job->{pid}") if $job->{debug};
	    }
	}
    }
    # delete $Forks::Super::CHILD_STDIN{...} for this job? No.
    return;
}

sub _close_fh_stdout {
    my $job = shift;
    if (defined($job->{child_stdout}) && 
	!defined($job->{child_stdout_closed})) {
	if (is_socket($job->{child_stdout})) {
	    if (_close_socket($job->{child_stdout}, 0)) {
		$job->{child_stdout_closed} = 1;
		debug("closed child stdout for $job->{pid}") if $job->{debug};
	    }
	} elsif (_close($job->{child_stdout})) {
	    $job->{child_stdout_closed} = 1;
	    debug("closed child stdout for $job->{pid}") if $job->{debug};
	}
	if ($job->{fh_config}{join}) {
	    $job->{child_stderr_closed} = $job->{child_stdout_closed};
	    debug("closed joined child stderr for $job->{pid}")
		if $job->{debug};
	}
    }
    # delete $Forks::Super::CHILD_STDOUT{...} ? No.
    return;
}

sub _close_fh_stderr {
    my $job = shift;
    if (defined($job->{child_stderr}) && 
	!defined($job->{child_stderr_closed})) {

	if (is_socket($job->{child_stderr})) {
	    if (_close_socket($job->{child_stderr}, 0)) {
		$job->{child_stderr_closed} = 1;
		debug("closed child stderr for $job->{pid}") if $job->{debug};
	    }
	} elsif (_close($job->{child_stderr})) {
	    $job->{child_stderr_closed} = 1;
	    debug("closed child stderr for $job->{pid}") if $job->{debug};
	}
    }
    # delete $Forks::Super::CHILD_STDERR{...}? No.
    return;
}

sub close_fh {
    my ($job,@modes) = @_;
    my $modes;
    {
	local $" = ' ';
	$modes = "@modes" || 'all';
	$modes =~ s/\ball\b/stress/i if $job->{fh_config}{stress};
	$modes =~ s/\ball\b/stdin stdout stderr/i;
	$modes =~ s/\bstress\b/stress stdin stdout stderr/i;
    }
    if ($job->{debug}) {
	debug("closing [$modes] on $job");
    }

    if ($modes =~ /stdin/i)  { _close_fh_stdin($job);  }
    if ($modes =~ /stdout/i) { _close_fh_stdout($job); }
    if ($modes =~ /stderr/i) { _close_fh_stderr($job); }
    if ($modes =~ /stress/i) {
	for my $n (1 .. $_FILEHANDLES_PER_STRESSED_JOB) {
	    _close( $job->{"child_stress_$n"} );
	}
    }
    return;
}

sub Forks::Super::Job::write_stdin {
    my ($job, @msg) = @_;
    Forks::Super::Job::_resolve($job);
    my $fh = $job->{child_stdin};
    if (defined $fh) {
	if ($job->{child_stdin_closed}) {
	    carp 'Forks::Super::Job::write_stdin: ',
		    "write on closed stdin handle for job $job->{pid}\n";
	} else {
	    local $! = 0;
	    my $z = print {$fh} @msg;

	    # an MSWin32 hack. Child sockets in t/43d and t/44d choke
	    # (XXX - Why?) without a small pause after each write.
	    # See also &Forks::Super::Tie::IPCSocketHandle::trivial_pause
	    if (&IS_WIN32 && is_socket($fh)) {
		Forks::Super::Util::pause(0.001);
	    }
	    if ($!) {
		carp 'Forks::Super::Job::write_stdin: ',
			"warning on write to job $job->{pid} stdin: $!\n";
	    }
	    return $z;
	}
    } else {
	carp 'Forks::Super::Job::write_stdin: ',
		"stdin handle for job $job->{pid} was not configured\n";
    }
    return;
}

sub _read_socket {
    my ($sh, $job, $wantarray, %options) = @_;

    return if !__sanitize_read_inputs($sh, $job, $wantarray, %options);

    my $zz = eval { $sh->opened };
    if ($@) {
	carp 'Forks::Super::_read_socket: read on unopened, unopenable ',
	    "socket $sh, ref=",ref($sh),", error=$@\n";
	return;
    } elsif (!$zz) {
	carp "Forks::Super::_read_socket: read on unopened socket $sh ",
	    $job->toString(), "\n";
	return;
    }

    # is socket is blocking, then we need to test whether
    # there is input to be read before we read on the socket
    my ($expire, $blocking_desired) = __extract_read_options($sh, \%options);

    while ($sh->blocking() || &IS_WIN32 || $blocking_desired) {
	my $fileno = fileno($sh);
	if (not defined $fileno) {
	    $fileno = Forks::Super::Job::Ipc::fileno($sh);
	    Carp::cluck "Cannot determine FILENO for socket handle $sh!";
	}

	my ($rin,$rout);
	my $timeout = $Forks::Super::SOCKET_READ_TIMEOUT || 1.0;
	($timeout, $blocking_desired)
	    = __get_select_timeout($timeout, $expire, $blocking_desired);

	$rin = '';
	vec($rin, $fileno, 1) = 1;

	# perldoc select: warns against mixing select4
	# (unbuffered input) with readline (buffered input).
	# Do I have to do my own buffering? That would be weak.
	# Or are sockets already unbuffered?

	local $! = undef;
	my ($nfound,$timeleft) = select $rout=$rin, undef, undef, $timeout;

	if ($nfound) {
	    if ($rin ne $rout && $DEBUG) {
		debug("No input found on $sh/$fileno ",
		      "[shouldn't reach this block]");
	    }
	    if ($nfound == -1) {
		next if $!{EINTR}; # interrupted system call -- usually ok.
		warn "Forks::Super:_read_socket: Error in select4(): $! $^E.\n";
	    }
	    last;
	}
	if ($DEBUG) {
	    debug("no input found on $sh/$fileno");
	}
	return if ! $blocking_desired;
    }

    # XXX - see _read_pipe how we used sysread to build a
    #       readline return value from raw input ...
    return readline($sh);
}

sub __get_select_timeout {
    my ($timeout, $expire, $blocking_desired) = @_;
    if ($expire && Time::HiRes::time() + $timeout > $expire) {
	$timeout = $expire - Time::HiRes::time();
	if ($timeout < 0) {
	    $timeout = 0.0;
	    $blocking_desired = 0;
	}
    }
    return ($timeout, $blocking_desired);
}

sub __get_option {
    my ($option, $default, %options) = @_;
    if (defined $options{$option}) {
	return $options{$option};
    } else {
	return $default;
    }
}

sub _read_pipe {
    my ($sh, $job, $wantarray, %options) = @_;

    if (!defined $sh) {
	if (!defined($options{'warn'}) || $options{'warn'}) {
	    carp 'Forks::Super::_read_pipe: ',
	        'read on undefined handle for ',$job->toString(),"\n";
	}
	return;
    }

    if (defined $$sh->{std_delegate}) {
	$sh = $$sh->{std_delegate};
    }

    my $blocking_desired = __get_option(
	'block', $$sh->{emulate_blocking} || 0, %options);

    # pipes are blocking by default.
    if ($blocking_desired) {
	return $wantarray ? readline($sh) : scalar readline($sh);
    }

    my $fileno = fileno($sh);
    if (! defined $fileno) {
	$fileno = Forks::Super::Job::Ipc::fileno($sh);
	Carp::cluck "Cannot determine FILENO for pipe $sh!";
    }

    my ($rin,$rout);
    $rin = '';
    vec($rin, $fileno, 1) = 1;

  SELECT4: {
        my $timeout = __get_option(
	    'timeout', $Forks::Super::SOCKET_READ_TIMEOUT || 1.0, %options);
    
	local $! = undef;
	my ($nfound, $timeleft) = select $rout=$rin, undef, undef, $timeout;

	if ($nfound == 0) {
	    if ($DEBUG) {
		debug("no input found on $sh/$fileno");
	    }
	    return;
	}
	if ($nfound < 0) {
	    redo SELECT4  if $!{EINTR}; 
	    warn "Forks::Super::_read_pipe: error in select4(): $! $^E\n";
	    return; # return ''?
	}

	if ($wantarray) {
	    return _emulate_readline_array($sh, $nfound, $rin);
	} else {
	    return _emulate_readline_scalar($sh, $nfound, $rin);
	}
    }
}

# emulate list context readline from a handle with sysread
sub _emulate_readline_array {
    my ($handle, $nfound, $rin) = @_;
    my ($timeleft, $rout);

    my $input = '';
    while ($nfound) {
	my $buffer = '';
	last if 0 == sysread $handle, $buffer, 1;
	$input .= $buffer;
	($nfound,$timeleft) = select $rout=$rin, undef, undef, 0.0;
    }

    my @return = ();
    my $rs = defined($/) && length($/) ? $/ : chr(0xF0F0F); #"\x{F0F0}";
    while ($input =~ m{$rs}) {
	push @return, substr $input, 0, $+[0];
	substr($input, 0, $+[0], '');
    }
    if (length($input)) {
	push @return, $input;
    }
    return @return;
}

sub _emulate_readline_scalar {
    my ($handle, $nfound, $rin) = @_;
    my ($timeleft, $rout);
    my $input = '';
    while ($nfound) {
	my $buffer = '';
	# XXX - does getc work as well as sysread ..., 1 ?
	# last unless defined($buffer = getc($handle));
	last if 0 == sysread $handle, $buffer, 1;
	$input .= $buffer;
	last if length($/) > 0 && substr($input,-length($/)) eq $/;
	($nfound,$timeleft) = select $rout=$rin, undef, undef, 0.0;
    }
    return $input;
}

sub Forks::Super::Job::read_stdout {
    my $job = shift;
    if (@_ % 2) {
        Carp::cluck "Odd number of elements in hash assignment: @_";
    }
    my %options = @_;
    Forks::Super::Job::_resolve($job);
    return _readline($job->{child_stdout}, $job, wantarray, %options);
}

sub Forks::Super::Job::read_stderr {
    my ($job, %options) = @_;
    Forks::Super::Job::_resolve($job);
    return _readline($job->{child_stderr}, $job, wantarray, %options);
}

sub Forks::Super::Job::getc_stdout {
    my ($job, %options) = @_;
    Forks::Super::Job::_resolve($job);
    return _getc($job->{child_stdout}, $job, %options);
}

sub Forks::Super::Job::getc_stderr {
    my ($job, %options) = @_;
    Forks::Super::Job::_resolve($job);
    return _getc($job->{child_stderr}, $job, %options);
}

sub _getc {
    my ($fh, $job, %options) = @_;
    return if !__sanitize_read_inputs($fh, $job, 0, %options);

    if ($$fh->{is_socket}) {
	return _getc_socket($fh, $job, %options);
    } elsif ($$fh->{is_pipe}) {
	return _getc_pipe($fh, $job, %options);
    }

    my ($expire, $blocking_desired) = __extract_read_options($fh, \%options);
    GETC: {
	local $! = undef;
	my $c = getc($fh);
	if (defined $c) {
	    return $c;
	}

	last if _check_if_job_is_complete_and_close_io($job, $fh);
	seek $fh, 0, 1;
	if ($blocking_desired) {
	    if ($expire > 0 && Time::HiRes::time() >= $expire) {
		$blocking_desired = 0;
	    } else {
		Forks::Super::Util::pause(
		    $Forks::Super::Util::DEFAULT_PAUSE_IO);
	    }
	}
	if (!$blocking_desired) {
	    if ($job->{is_child}) {
		return;
	    } else {
		return '';
	    }
	}
	redo GETC;
    }
}

sub _getc_socket {
    my ($sh, $job, %options) = @_;
    return if !__sanitize_read_inputs($sh, $job, 0, %options);
    my $zz = eval { $sh->opened };
    if ($@) {
	carp 'Forks::Super::_getc_socket: read on unopened, unopenable ',
	    "socket $sh, ref=", ref($sh), ", error=$@\n";
	return;
    } elsif (!$zz) {
	carp "Forks::Super::_getc_socket: read on unopened socket $sh ",
	    $job->toString(), "\n";
	return;
    }

    my ($expire, $blocking_desired) = __extract_read_options($sh, \%options);
    while ($sh->blocking() || &IS_WIN32 || $blocking_desired) {
	my $fileno = fileno($sh);
	if (not defined $fileno) {
	    $fileno = Forks::Super::Job::Ipc::fileno($sh);
	    Carp::cluck "Cannot determine FILENO for socket handle $sh!";
	}

	my ($rin,$rout);
	my $timeout = $Forks::Super::SOCKET_READ_TIMEOUT || 1.0;
	($timeout, $blocking_desired)
	    = __get_select_timeout($timeout, $expire, $blocking_desired);

	$rin = '';
	vec($rin, $fileno, 1) = 1;

	# perldoc select: warns against mixing select4
	# (unbuffered input) with readline (buffered input).
	# Do I have to do my own buffering? That would be weak.
	# Or are sockets already unbuffered?

	local $! = undef;
	my ($nfound,$timeleft) = select $rout=$rin, undef, undef, $timeout;

	if ($nfound) {
	    if ($rin ne $rout && $DEBUG) {
		debug("No input found on $sh/$fileno ",
		      "[shouldn't reach this block]");
	    }
	    if ($nfound == -1) {
		warn "Forks::Super:_read_socket: Error in select4(): $! $^E.\n";
	    }
	    last;
	}
	if ($DEBUG) {
	    debug("no input found on $sh/$fileno");
	}
	return if ! $blocking_desired;
    }

    # prefer recv/sysread to getc, as the latter is susceptible to
    # buffering compatibility problems with 4-arg select.
    if (ref($sh) eq 'Forks::Super::Tie::IPCSocketHandle::Delegator') {
	$sh = $$sh->{DELEGATE};
    }
    my ($n,$c);
    $n = recv $sh, $c, 1, 0;
    return $c;
}

sub _getc_pipe {
    my ($sh, $job, %options) = @_;

    if (!defined $sh) {
	if (!defined($options{'warn'}) || $options{'warn'}) {
	    carp 'Forks::Super::_getc_pipe: ',
	        'read on undefined handle for ',$job->toString(),"\n";
	}
	return;
    }

    if (defined $$sh->{std_delegate}) {
	$sh = $$sh->{std_delegate};
    }

    my $blocking_desired = __get_option(
	'block', $$sh->{emulate_blocking} || 0, %options);

    # pipes are blocking by default.
    if ($blocking_desired) {
	# XXX - prefer  sysread  to  getc  here?
	return _unbuffered_getc($sh);
    }

    my $fileno = fileno($sh);
    if (! defined $fileno) {
	$fileno = Forks::Super::Job::Ipc::fileno($sh);
	Carp::cluck "Cannot determine FILENO for pipe $sh!";
    }

    my ($rin,$rout);
    $rin = '';
    vec($rin, $fileno, 1) = 1;
    my $timeout = __get_option(
	'timeout', $Forks::Super::SOCKET_READ_TIMEOUT || 1.0, %options);

    local $! = undef;
    my ($nfound, $timeleft) = select $rout=$rin, undef, undef, $timeout;

    if ($nfound == 0) {
	if ($DEBUG) {
	    debug("no input found on $sh/$fileno");
	}
	return;
    }
    if ($nfound < 0) {
	# warn "Forks::Super::_getc_pipe: error in select4(): $! $^E\n";
	return; # return ''?
    }

    # XXX - prefer  sysread  to  getc  here ?
    return _unbuffered_getc($sh);
}

sub _unbuffered_getc {

    # sysread can return undef on solaris in t/44j.
    # Maybe SIGCHLD is causing an interruption?

    # this was fixed in F::S::Tie::IPCPipeHandle::GETC in v0.58, but we
    # have to fix it here, too

    my $cc;
    {
	local $!;
	my $n = sysread $_[0], $cc, 1;
	if (!defined $n) {
	    redo if $!{EINTR};
	    carp "FSJ::Ipc::_unbuffered_getc: $!";
	    return;
	}
	return if $n==0;
    }
    return $cc;
}

#
# called from the parent process,
# attempts to read a line from standard output file handle
# of the specified child.
#
# returns "" if the process is running but there is no
# output waiting on the file handle
#
# returns undef if the process has completed and there is
# no output waiting on the file handle
#
# performs trivial seek on file handle before reading.
# this will reduce performance but will always clear
# error condition and eof condition on handle
#
sub _readline {
    my ($fh,$job,$wantarray,%options) = @_;

    return if !__sanitize_read_inputs($fh, $job, $wantarray, %options);

    if ($$fh->{is_socket}) {
	return _read_socket($fh,$job,$wantarray,%options);
    } elsif ($$fh->{is_pipe}) {
	return _read_pipe($fh,$job,$wantarray,%options);
    }

    # WARNING: blocking read on a file handle can lead to deadlock
    my ($expire, $blocking_desired) = __extract_read_options($fh, \%options);

    local $! = undef;
    if ($wantarray) {
	return _readline_array($job,$fh,$expire,$blocking_desired);
    } else {
	return _readline_scalar($job,$fh,$expire,$blocking_desired);
    }
}

sub __sanitize_read_inputs {
    my ($fh, $job, $wantarray, %options) = @_;
    if (!defined $fh) {
	if ( $job->{debug} &&
             (!defined($options{'warn'}) || $options{'warn'}) ) {
	    carp 'Forks::Super::_readline(): ',
	        "read on unconfigured handle for job $job->{pid}\n";
	}
	return;
    }

    # if this is a child and $USE_TIE_SH, then *STDIN has been assigned to
    # another glob but it's not a real GLOB or a blessed reference, so the
    # $sh->opened  call below will fail.  When we reassign *STDIN like that,
    # also set ${*STDIN}->{std_delegate} to return a blessed reference that
    # is tied to the socket we really need to be reading from.

    if (defined $$fh->{std_delegate}) {
	$fh = $_[0] = $$fh->{std_delegate};
    }


    if ($$fh->{closed}) {
	if (!defined($options{'warn'}) || $options{'warn'}) {
	    carp_once 'Forks::Super::_readline(): ',
	        "read on closed handle for job $job->{pid}\n";
	}
	return;
    }
    return 1;
}

sub __extract_read_options {
    my ($fh, $options) = @_;
    my ($expire, $blocking_desired) = (0, $$fh->{emulate_blocking});
    if (defined $options->{block}) {
	$blocking_desired = $options->{block};
    }
    if (defined($options->{timeout}) && $options->{timeout} > 0) {
	$expire = Time::HiRes::time() + $options->{timeout};
	$blocking_desired = 1;
    }
    return ($expire, $blocking_desired);
}

sub _check_if_job_is_complete_and_close_io {
    my ($job, $fh) = @_;
    if ($job->is_complete && Time::HiRes::time() - $job->{end} > 3) {
	if ($job->{debug}) {
	    debug("_readline: job $job->{pid} is complete. Closing $fh");
	}
	if (defined($job->{child_stdout}) && $fh eq $job->{child_stdout}) {
	    $job->close_fh('stdout');
	}
	if (defined($job->{child_stderr}) && $fh eq $job->{child_stderr}) {
	    $job->close_fh('stderr');
	}
	return 1;
    }
    return 0;
}

sub _readline_array {
    my ($job, $fh, $expire, $blocking_desired) = @_;
    my @lines;
    while (@lines == 0) {
	@lines = readline($fh);
	if (@lines > 0) {
	    return @lines;
	}

	if (!_check_if_job_is_complete_and_close_io($job, $fh)) {
	    seek $fh, 0, 1;
	    if ($blocking_desired) {
		if ($expire > 0 && Time::HiRes::time() >= $expire) {
		    $blocking_desired = 0;
		} else {
		    Forks::Super::Util::pause(
			1 * $Forks::Super::Util::DEFAULT_PAUSE_IO);
		}
	    }
	} else {
	    return;
	}
	if (!$blocking_desired) {
	    return;
	}
    }
    return @lines;
}

sub _readline_scalar {
    my ($job, $fh, $expire, $blocking_desired) = @_;
    my $line;
    while (!defined $line) {
	$line = readline($fh);

	if (defined $line) {
	    return $line;
	}

	last if _check_if_job_is_complete_and_close_io($job, $fh);
	seek $fh, 0, 1;
	if ($blocking_desired) {
	    if ($expire > 0 && Time::HiRes::time() >= $expire) {
		$blocking_desired = 0;
	    } else {
		Forks::Super::Util::pause(
		    $Forks::Super::Util::DEFAULT_PAUSE_IO);
	    }
	}
	if (!$blocking_desired) {
	    if (!$job->{is_child}) {
		# in the parent, we can tell the difference between this input

		# stream being empty because the child process is finished
		# (see _check_if_job_is_complete_and_close_io() call, above),
		# and the stream being empty because the child isn't producing
		# enough output to keep it full.

		# We can and do distinguish between these two cases by
		# returning <undef> when the child is finished and will
		# not produce any more input, and  ""  (empty string) when
		# the child is still alive and it could potentially
		# produce more input.

		return '';
	    } else {
		# in the child, we don't make this distinction.
		return;
	    }
	}
    }
    return;
}



sub init_child {
    $IPC_DIR_DEDICATED = 0;
    %IPC_FILES = @IPC_FILES = ();
    @SAFEOPENED = ();
    %SIG_OLD = ();
    return;
}

sub _child_share {
    my $job = shift;
    return if !defined $job->{share};
    return if !defined $job->{share_ipc};
    if (open my $fh, '>', $job->{share_ipc}) {
        print $fh Data::Dumper::Dumper( $job->{share} );
        close $fh;
        if ($job->{debug}) {
            debug("shared data written to $job->{share_ipc}");
        }
    } else {
        carp 'Forks::Super::deinit_child: could not open ',
            "share ipc file $job->{share_ipc}: $!";
    }
}

sub deinit_child {
    use Data::Dumper;
    my $job = Forks::Super::Job->this;
    if ($job->{is_emulation}) {
        local *STDERR = *$Forks::Super::Debug::DEBUG_FH;
        Carp::cluck("FSJ::Ipc: deinit_child called for emulated job!");
    }
    _child_share($job);

    if (@IPC_FILES > 0) {
        Carp::cluck("Child $$ had temp files! @IPC_FILES\n")
	    if $Forks::Super::CHILD_FORK_OK < 0; # stackoverflow/q/15230850
	unlink @IPC_FILES;
	@IPC_FILES = ();
    }
    _close_child_fh($job);
    return;
}

sub _close_child_fh {
    my $job = shift;
    my %closed = ();
    foreach my $fh (@{$job->{child_fh_close}}, @SAFEOPENED) {
	if (ref $fh eq 'ARRAY') {
	    if ($fh->[0] eq 'shutdown') {
		no warnings 'closed', 'unopened';
		shutdown $fh->[1], $fh->[2];
		$fh = $fh->[1];
		$$fh->{closed} = $closed{$fh} = 1;
		close $fh;
	    }
	    next;
	}
	next if $closed{$fh}++ || $$fh->{closed};
	close $fh;
    }
    return;
}

sub Forks::Super::Job::ipcToString {
    my $job = shift;
    my @output = ();
    foreach my $attr (qw(child_stdin child_stdout child_stderr)) {
	next if !defined $job->{$attr};
	my $handle = $job->{$attr};
	push @output, "job $job->{pid} handle $attr $handle " . *$handle;
	push @output, "\tref = " . ref($handle);
	push @output, _ipcHandleToString($handle);
    }
    return join ("\n", @output);
}

sub _ipcHandleToString {
    my $handle = shift;
    my @output = ();
    foreach my $k (sort keys %$$handle) {
	push @output, "\tattribute $k => " . $$handle->{$k} . "\n";
    }
    return wantarray ? @output : join ("\n", @output);
}

1;

=head1 NAME

Forks::Super::Job::Ipc - interprocess communication routines for Forks::Super

=head1 VERSION

0.95

=head1 DESCRIPTION

C<Forks::Super::Job::Ipc> is part of the L<Forks::Super|Forks::Super>
distribution. The functions and variables in this package manage
communication between parent and child processes.

This package is heavily used by the L<Forks::Super::Job|Forks::Super::Job>
package, but there is little reason for a L<Forks::Super|Forks::Super>
user to call this package's functions directly.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2018, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
