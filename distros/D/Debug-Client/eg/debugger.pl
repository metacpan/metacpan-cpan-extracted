use strict;
use warnings;
use 5.010;

use Cwd qw(cwd);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

my %opt = (
	port => 12345,
	perl => $^X,        # allow the user to supply the path to another perl
	host => '127.0.0.1',
);

usage() if not @ARGV;
GetOptions(
	\%opt,
	'help',
	'port=i',
	'perl=s',
) or usage();
usage() if $opt{help};

my ( $script, @args ) = @ARGV;


my $pid = fork();
die if not defined $pid;

if ( not $pid ) {
	local $ENV{PERLDB_OPTS} = "RemotePort=$opt{host}:$opt{port}";
	exec("$opt{perl} -d $script @args");
}
say "PID: $pid";

#require IPC::Run;

require Debug::Client;
my $debugger = Debug::Client->new(
	host => $opt{host},
	port => $opt{port},
);
$debugger->listen;
say 'listening';

# my @cmd = ($opt{perl}, '-d', @ARGV);
# {
# local $ENV{PERLDB_OPTS} = "RemotePort=$opt{host}:$opt{port}";
# IPC::Run::run(\@cmd, sub {}, \&out, \&err);
# }
# say 'launched';

# sub out {
# print "OUT @_";
# }
# sub err {
# print "ERR @_";
# }

# my $process;
# if ($^O =~ /win32/i) {
# require Win32::Process;
# require Win32;
# local $ENV{PERLDB_OPTS} = "RemotePort=$opt{host}:$opt{port}";
# Win32::Process::Create($process, $opt{perl}, "-d $script @args", 0, 0, cwd);
# }
# print "launched " . $process->GetProcessID .  "\n";


my $out = $debugger->get;
print $out;
my $last_step;
while (1) {
	chomp( my $input = <STDIN> );
	if ( $input eq '' ) {
		next if not $last_step;
		$input = $last_step;
	}

	given ($input) {
		when ( [ 'h', '?' ] ) {
			help();
		}
		when ('s') {
			$last_step = 's';
			my $out = $debugger->step_in;
			print $out;
		}
		when ('n') {
			$last_step = 'n';
			my $out = $debugger->step_over;
			print $out;
		}
		when ('r') {
			my $out = $debugger->step_out;
			print $out;
		}
		when ('T') {
			my $out = $debugger->get_stack_trace;
			print $out;
		}
		when ('.') {
			my $out = $debugger->show_line;
			print $out;
		}
		when ('q') {
			last;
		}
		when (qr/^c   (?:\s+(\w+))?  $/x) {
			my $out = $debugger->run($1);
			print $out;
		}
		default {
			#my $out = $debugger->execute_code($input);
			#print $out;
			print "Invalid command\n";
		}
	}
}

sub help {
	print <<'END_HELP'
s - step in
n - step over
r - step out
T - stack trace
. - show current line
c (line|sub) - run till
q - quit
h or ? - help
END_HELP

}


# ...

# On Windows kill() does not seem to have effect
# print "Killing the script...\n";
END {
	kill 9, $pid if $pid;
}

# Win32::Process
#$process->Kill(0);

sub usage {
	pod2usage();
}


=head1 SYNOPSIS

  script param param

  --port PORT                  defaults to 12345
  --help                       This help
  --perl /path/to/other/perl   defaults to current perl

=cut

