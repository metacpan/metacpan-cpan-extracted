#
# Forks::Super::Config package - determines what features and
#         modules are available on the current system
#         at run-time.
#
# Some useful system info is expensive to compute so it is
# determined at build time and put into Forks/Super/SysInfo.pm
#


package Forks::Super::Config;
use Forks::Super::Debug qw(debug);
use Forks::Super::SysInfo;
use Carp;
use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(CONFIG CONFIG_module);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.91';

our (%CONFIG, $IS_TEST, $IS_TEST_CONFIG, %SIGNO, $CONFIG_FILE);


sub init {

    %CONFIG = ();
    $CONFIG{filehandles} = 1;

    $IS_TEST = 0;
    $IS_TEST_CONFIG = 0;

    if ($ENV{NO_WIN32_API}) {
	$CONFIG{'Win32::API'} = 0;
    }

    use Config;
    my $i = 0;
    if (defined $Config::Config{'sig_name'}) {
	%SIGNO = map { $_ => $i++ } split / /, $Config::Config{'sig_name'};
    }

    if (defined $ENV{FORKS_SUPER_CONFIG}) {
	my @cfg_spec = split /,/, $ENV{FORKS_SUPER_CONFIG};
	foreach my $spec (@cfg_spec) {
	    if ($spec =~ s/^!//) {
		$CONFIG{$spec} = 0;
	    } elsif ($spec =~ s/^\?//) {
		delete $CONFIG{$spec};
		CONFIG($spec);
	    } else {
		$CONFIG{$spec} = 1;
	    }
	}
    }
    return;
}

sub init_child {
    untie $CONFIG{'filehandles'};
    untie %CONFIG;
#   unconfig('filehandles');
    return;
}

sub unconfig {
    my $module = shift;
    $CONFIG{$module} = 0;
    return 0;
}

sub config {
    my $module = shift;
    $CONFIG{$module} = 1;
    return 1;
}

sub configif {
    my $module = shift;
    return $CONFIG{$module} if defined $CONFIG{$module};
    return config($module);
}

sub deconfig {
    my $module = shift;
    return delete $CONFIG{$module};
}

#
# try to import some modules, with the expectation that the module
# might not be available.
#
# Hmmmm. We often run this subroutine from the children, which could mean
# we have to run it for every child.
#
sub CONFIG {
    my ($module, $warn, @settings) = @_;
    if (defined $CONFIG{$module}) {
	return $CONFIG{$module};
    }

    if (substr($module,0,1) eq '/') {
	return $CONFIG{$module} = CONFIG_external_program($module);
    } elsif ($module eq 'filehandles') {
	return $CONFIG{$module} = 1; # available by default
    } else {
	return $CONFIG{$module} =
	    CONFIG_module($module,$warn,@settings);
    }
}

sub CONFIG_module {
    my ($module,$warn, @settings) = @_;
    if (defined $CONFIG{$module}) {
	return $CONFIG{$module};
    }
    my $zz = eval " require $module ";     ## no critic (StringyEval)
    if ($@) {
	carp 'Forks::Super::CONFIG: ',
	    "Module $module could not be loaded: $@\n" if $warn;
	return 0;
    }

    if (@settings) {
	$zz = eval " $module->import(\@settings) ";  ## no critic (StringyEval)
	if ($@ && $warn) {
	    carp 'Forks::Super::CONFIG: Module ',
	        "$module was loaded but could not import with settings [",
 	        join (',', @settings), "]\n";
	}
    }

    if ($IS_TEST_CONFIG) {
	my $v = eval "\$$module" . '::VERSION';       ## no critic (StringyEval)
	if (defined $v) {
	    print STDERR "[$module enabled (v$v)]\n";
	} else {
	    print STDERR "[$module enabled]\n";
	}
    }
    return 1;
}

sub CONFIG_external_program {
    my ($external_program) = @_;
    if (defined $CONFIG{$external_program}) {
	return $CONFIG{$external_program};
    }

    if (-x $external_program) {
	if ($IS_TEST_CONFIG) {
	    print STDERR "CONFIG\{$external_program\} enabled\n";
	}
	return $external_program;
    }

    my $xprogram = $external_program;
    $xprogram =~ s{^/}{};
    if (-w '/dev/null') {
	my $which = qx(which $xprogram 2> /dev/null); ## no critic (Backtick)
	$which =~ s{\s+$}{};
	if ($which && -x $which) {
	    if ($IS_TEST_CONFIG) {
		print STDERR "CONFIG\{$external_program\} enabled\n";
	    }
	    return $CONFIG{$external_program} = $CONFIG{$which} = $which;
	}
    }

    # poor man's which
    my @path1 = split /:/, $ENV{PATH};
    my @path2 = split /;/, $ENV{PATH};
    foreach my $path (@path1, @path2, '.') {
	if (-x "$path/$xprogram") {
	    if ($IS_TEST_CONFIG) {
		print STDERR "CONFIG\{$external_program\} enabled\n";
	    }
	    return $CONFIG{$external_program} = "$path/$xprogram";
	}
    }
    return 0;
}

sub load_config_file {
    my $file = shift || ($CONFIG_FILE ||= "./.forkssuperrc");
    $CONFIG_FILE ||= $file;
    if (open my $fh, '<', $file) {
	while (<$fh>) {
	    next if /^\s*[#;-]/;
	    chomp;
	    my ($key,$val) = split /\s*=\s*/, $_, 2;
	    $key = uc $key;
	    $key =~ s/[-. ]/_/g;

	    # DEBUG, MAX_PROC, MAX_LOAD, ON_BUSY, 
	    # IPC_DIR/FH_DIR, CHILD_FORK_OK,
	    # QUEUE_INTERRUPT, QUEUE_MONITOR_FREQ 
	    if ($key eq 'DEBUG') {
                no warnings 'once';
		$Forks::Super::DEBUG = $val || 0;
	    } elsif ($key eq 'MAX_PROC') {
                no warnings 'once';
		$Forks::Super::MAX_PROC =
		    $val || $Forks::Super::DEFAULT_MAX_PROC;
	    } elsif ($key eq 'MAX_LOAD') {
                no warnings 'once';
		$Forks::Super::MAX_LOAD = $val;
	    } elsif ($key eq 'ON_BUSY') {
		$Forks::Super::ON_BUSY = lc $val;
	    } elsif ($key eq 'IPC_DIR' || $key eq 'FH_DIR') {
		if (-d $val || mkdir($val, 0777)) {
		    Forks::Super::Job::Ipc::set_ipc_dir($val, 1);
		} else {
		    carp "Forks::Super::Config: ",
		    	"cannot use '$val' as IPC directory: $!\n";
		}
	    } elsif ($key eq 'CHILD_FORK_OK') {
                no warnings 'once';
		$Forks::Super::CHILD_FORK_OK = $val || 0;
	    } elsif ($key eq 'QUEUE_INTERRUPT') {
                no warnings 'once';
		$Forks::Super::QUEUE_INTERRUPT = $val;
	    } elsif ($key eq 'QUEUE_MONITOR_FREQ') {
                no warnings 'once';
		$Forks::Super::Deferred::QUEUE_MONITOR_FREQ = $val || 30;
                no warnings 'once';
	    } elsif ($key eq 'QUEUE_MONITOR_LIFESPAN') {
                no warnings 'once';
		$Forks::Super::Deferred::QUEUE_MONITOR_LIFESPAN = $val;
	    } elsif ($key eq 'QUEUE_DEBUG') {
                no warnings 'once';
		$Forks::Super::Deferred::QUEUE_DEBUG = $val;
	    } elsif ($key eq 'SIG_DEBUG') {
                no warnings 'once';
		$Forks::Super::Sigchld::SIG_DEBUG = $val;
	    } elsif ($key eq 'DUMP_SIG') {
		Forks::Super::Debug::enable_dump($val);
	    } elsif ($key eq 'SYNC_YIELD_DURATION') {
                no warnings 'once';
		$Forks::Super::Sync::IPCSempahore::NO_WAIT_YIELD_DURATION
		    = $val/1000;
		$Forks::Super::Sync::Win32::NO_WAIT_YIELD_DURATION = $val;
		$Forks::Super::Sync::Win32Mutex::NO_WAIT_YIELD_DURATION = $val;
	    } elsif ($key eq 'TIE_HANDLES') {
                no warnings 'once';
		$Forks::Super::Job::Ipc::USE_TIE_FH = $val =~ /all|1|file|fh/i;
		$Forks::Super::Job::Ipc::USE_TIE_SH
		    = $val =~ /all|1|socket|sh/i;
		$Forks::Super::Job::Ipc::USE_TIE_PH = $val =~ /all|1|pipe|ph/i;
	    } elsif ($key eq 'DEFAULT_PAUSE') {
                no warnings 'once';
		$Forks::Super::Util::DEFAULT_PAUSE = $val;
	    } elsif ($key eq 'DEFAULT_PAUSE_IO') {
                no warnings 'once';
		$Forks::Super::Util::DEFAULT_PAUSE_IO = $val;
	    } elsif ($key eq 'SOCKET_READ_TIMEOUT') {
                no warnings 'once';
		$Forks::Super::SOCKET_READ_TIMEOUT = $val;
	    } else {
		carp "Forks::Super::Config: ",
			"Unknown configuration parameter '$key'. Ignoring\n";
	    }
	}
    } else {
	carp "failed to open Forks::Super config file '$file': $!";
    }
    return;
}

my @config_sig = ();
my $last_sig;

sub enable_signal_config {
    use Signals::XSIG;

    my $sig = _resolve_signum(shift);
    if (!$sig) {
	delete $XSIG{$_}[1] for @config_sig;
	@config_sig = ();
print STDERR "Disabled signal-based dynamic configuration\n";	
	return;
    }
    @config_sig = ();
    for my $i (0 .. 6) {
	push @config_sig, _resolve_signame($sig+$i);
    }

    $XSIG{$config_sig[0]}[1] = sub {
	$CONFIG_FILE ||= "./.forkssuperrc";
	print STDERR qq[
Dynamic configuration signals:
  kill -$config_sig[0],$$    \tthis help message
  kill -$config_sig[1],$$    \treload setings from config file '$CONFIG_FILE'
  kill -$config_sig[2],$$    \tincrement \$Forks::Super::MAX_PROC
  kill -$config_sig[3],$$    \tderecment \$Forks::Super::MAX_PROC
  kill -$config_sig[4],$$    \tdump active process information
  kill -$config_sig[5],$$    \tdump active and completed process information
  kill -$config_sig[6],$$    \tchange \$Forks::Super::ON_BUSY
];
    };
    $XSIG{$config_sig[1]}[1] = sub {
	print STDERR "Reloading Forks::Super config file\n";
	load_config_file(); 
    };
    $XSIG{$config_sig[2]}[1] = sub { 
        if (!ref($Forks::Super::MAX_PROC)) {
            $Forks::Super::MAX_PROC++;
            print STDERR "MAX_PROC changed to $Forks::Super::MAX_PROC\n";
        } else {
            print STDERR
                "\$Forks::Super::MAX_PROC is a coderef. Unable to increment\n";
        }
    };
    $XSIG{$config_sig[3]}[1] = sub {
        if (!ref($Forks::Super::MAX_PROC)) {
            $Forks::Super::MAX_PROC--; 
            $Forks::Super::MAX_PROC ||= 1;
            print STDERR "MAX_PROC changed to $Forks::Super::MAX_PROC\n";
        } else {
            print STDERR "\$Forks::Super::MAX_PROC is a coderef. ",
                "Unable to decrement\n"; 
        }
    };
    $XSIG{$config_sig[4]}[1] = sub { Forks::Super::Debug::parent_dump(0); };
    $XSIG{$config_sig[5]}[1] = sub { Forks::Super::Debug::parent_dump(1); };
    $XSIG{$config_sig[6]}[1] = sub {
	if ($Forks::Super::ON_BUSY eq 'block') {
	    $Forks::Super::ON_BUSY = 'fail';
	} elsif ($Forks::Super::ON_BUSY eq 'fail') {
	    $Forks::Super::ON_BUSY = 'queue';
	} elsif ($Forks::Super::ON_BUSY eq 'queue') {
	    $Forks::Super::ON_BUSY = 'block';
	}
	print STDERR "ON_BUSY changed to $Forks::Super::ON_BUSY\n";
    }
}

sub _resolve_signum {
    use Config;
    my $sig = shift;
    return $sig if $sig =~ /\d/ && $sig !~ /\D/;
    $sig =~ s/^SIG//i;
    my @names = split ' ', $Config{sig_name};
    my @nums = split ' ', $Config{sig_num};
    for my $i (0..$#names) {
	if (uc $sig eq uc $names[$i]) {
	    return $nums[$i];
	}
    }
    return;
}

sub _resolve_signame {
    my $sig = shift;
    return $sig if $sig =~ /\D/;
    my @names = split ' ', $Config{sig_name};
    my @nums = split ' ', $Config{sig_num};
    for my $i (0..$#names) {
	if ($sig == $nums[$i]) {
	    return $names[$i];
	}
    }
    return;
}

1;
