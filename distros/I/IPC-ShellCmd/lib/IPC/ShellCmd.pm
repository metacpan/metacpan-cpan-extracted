package IPC::ShellCmd;

use strict;
use Carp qw(carp croak);
use Scalar::Util;
use IO::Pipe;
use POSIX qw(:sys_wait_h);
use 5.008004; # May work with lower, unwilling to support unless you provide patches :)

our $VERSION = '0.001';
$VERSION = eval $VERSION;

$IPC::ShellCmd::BufferLength = 16384;

=head1 NAME

IPC::ShellCmd - Run a command with a given environment and capture output

=head1 SYNOPSIS

    my $isc = IPC::ShellCmd->new(["perl", "Makefile.PL"])
	    ->working_directory("/path/to/IPC_ShellCmd-0.01")
	    ->stdin(-filename => "/dev/null")
	    ->add_envs(PERL5LIB => "/home/mbm/cpanlib/lib/perl5")
	    ->chain_prog(
	        IPC::ShellCmd::Sudo->new(
		        User => 'cpanbuild',
		        SetHome => 1,
		    )
	    )->run();

    my $stdout = $isc->stdout();
    my $status = $isc->status();

=head1 DESCRIPTION

This module comes from the nth time I've had to implement a select loop
and wanted appropriate sudo/su privilege magic, environment variables that
are set in the child, working directories set etc.

It aims to provide a reasonable interface for setting up command execution
environment (working directory, environment variables, stdin, stdout and
stderr redirection if necessary), but allowing for ssh and sudo and magicing
in the appropriate shell quoting.

It tries to be flexible about how you might want to capture output, exit
status and other such, but in such a way as it's hopefully easy to understand
and make it work.

Setup method calls are chainable in a L<File::Find::Rule> kind of a way.

=head2 my I<$isc> = IPC::ShellCmd->B<new>(\I<@cmd>, I<%opts>)

Creates a new IPC::ShellCmd object linking to the command and arguments. Possible options:

=over 4

=item -nowarn

Don't throw warnings for overwriting values that have already been set

=item -debug

Set the debug level

=back

=cut

sub new {
    my $package = shift;
    my $cmd = shift;
    my %options = @_;

    if(!$cmd || !ref($cmd) || ref($cmd) ne "ARRAY") {
	    croak "Expecting an ARRAYREF for the command";
    }

    my @cmd = @$cmd;

    if(!@cmd) {
	    croak "Must specify at least one thing to run";
    }

    for my $cmd_el (@cmd) {
	    croak "Command arguments must all be strings"
	        if(!defined $cmd_el || ref($cmd_el)); 
    }

    my $self = bless {cmd => [@cmd], opts => {}}, $package;

    $self->_init(\%options);

    $self->_debug(2, "Constructor succeeded");

    return $self;
}

sub _init {
    my $self = shift;
    my $opts = shift;

    $self->{opts}->{warn} = 1
	    unless $opts->{'-nowarn'};

    $self->{select}->[0] =
	$self->{select}->[1] =
	$self->{select}->[2] = 1;

    $self->{debug} = 0;
    $self->{debug} = $opts->{'-debug'}
	    if($opts->{'-debug'} && $opts->{'-debug'} =~ /^\d+$/);

    $self->{'argv0'} = $self->{cmd}->[0];
    $self->{'argv0'} = $opts->{'-argv0'}
	    if($opts->{'-argv0'} && !ref $opts->{'-argv0'});
}

sub _debug {
    my $self = shift;
    my $level = shift;
    my $string = shift;

    carp sprintf("%s::debug%d: %s", ref($self), $level, $string)
	    if ($level <= $self->{debug});
}

=head2 I<$isc>->B<set_umask>(I<$mask>)

Sets the umask that this command is going to have, and returns
I<> so that it can be chained.

=cut

sub set_umask {
    my $self = shift;
    my $umask = shift;

    if($self->{opts}->{warn} && defined $self->{umask}) {
	    carp "Overwriting umask";
    }

    if(!defined $umask) {
	    croak "Can't use an undefined umask";
    }

    if($self->{run}) {
	    croak "Can't change setup after command has been run";
    }

    if(ref $umask || $umask !~ /^\d+$/) {
	    croak "Invalid umask";
    }

    $self->{umask} = $umask;

    return $self;
}

=head2 I<$isc>->B<working_dir>([I<$path>])

Sets the working directory that this command is going to run under,
and returns I<> so that it can be chained, or returns the
current setting with no arguments.

=cut

sub working_dir {
    my $self = shift;

    if(@_ && !defined $_[0]) {
	    croak "Can't set working directory to undefined path";
    }

    my $path = shift;

    if($self->{opts}->{warn} && defined $self->{wd}) {
	    carp "Overwriting working directory";
    }

    if($self->{run} && defined $path) {
	    croak "Can't change setup after command has been run";
    }

    if(defined $path && !ref $path) {
	    $self->_debug(2, "Setting working directory to \"$path\"");
	    $self->{wd} = $path;
	    return $self;
    }
    elsif(defined $path) {
	    croak "Expecting a string as working dir path";
    }
    return $self->{wd};
}

=head2 I<$isc>->B<add_envs>(I<$env1> => I<$val1> [, I<$env2> => I<$val2>, ...])

Adds environment variables to be setup when the command is run.
Returns I<> so that it can be chained.

=cut

sub add_envs {
    my $self = shift;
    my %env = @_;

    croak "Can't change setup after command has been run"
	    if($self->{run});

    croak "No envs specified"
	    unless @_;

    my $count = 0;

    for my $e (keys %env) {
	    $count++;
	    if($self->{opts}->{warn} && exists $self->{env}->{$e}) {
	        carp "Overwriting environment \"$e\"";
	    }
	    $self->{env}->{$e} = $env{$e};
	    $self->_debug(2, "Adding environment '$e' => '$env{$e}'");
    }

    return $self;
}

=head2 I<$isc>->B<chain_prog>(I<$chain_obj>, [I<$opt> => I<$val>, ...])

Adds a chain object, for example IPC::ShellCmd::Sudo->new(User => 'root')
into the chain. Returns I<> so that it can be chained.

Valid options are:

=over 4

=item -include-stdin

If set, and stdin is a filename (rather than a pipe, open filehandle, or
other type of descriptor) then the file will be included in the chain.  

=item -include-stdout

As above but with stdout.

=item -include-stderr

As above but with stderr.

=back

=cut

sub chain_prog {
    my $self = shift;
    my $obj = shift;
    my %opts = @_;

    croak "Can't change setup after command has been run"
	    if($self->{run});

    croak "Expecting a IPC::ShellCmd::Chain type of object"
	    unless Scalar::Util::blessed($obj) && $obj->can("chain");

    $self->{chain} = []
	unless $self->{chain};

    my $opt = {};
    if($opts{'-include-stdin'}) {
	    $opt->{stdin} = 1;
    }
    if($opts{'-include-stdout'}) {
	    $opt->{stdout} = 1;
    }
    if($opts{'-include-stderr'}) {
	    $opt->{stderr} = 1;
    }

    $self->_debug(2, "chaining a " . ref($obj) . " object");

    push(@{$self->{chain}}, {obj => $obj, opt => $opt});

    return $self;
}

=head2 I<$isc>->B<stdin>($stdin)

=head2 I<$isc>->B<stdin>($type, $stdin)

The 1 argument form takes either

=over 4

=item A scalar

This is the input to the command in full.

=item A scalar ref

This is a reference to the input that will be passed.

=item A code ref 

This is expected to generate the text to send to stdin. It is
called with an argument of the number of bytes that the caller
wants to read. If it generates more, some may be lost - you have
been warned.

=back

The 2 argument form takes a type and then a ref, handle or other.
Valid types:

=over 4

=item -inherit

The argument to this is ignored. If specified this takes stdin
from whatever the caller is reading from.

=item -file

The argument to this is a perl filehandle.

=item -fd

The argument to this is a system file descriptor.

=item -filename

The argument to this is a filename which is opened.

=back

Both of these return I<> for chaining. The default is
an empty scalar.

=cut

sub stdin {
    my $self = shift;

    croak "Can't change setup after command has been run"
	    if ($self->{run});

    carp "Overwriting stdin"
	    if ($self->{opts}->{warn} && $self->{stdin});

    if(@_ == 1) {
	    if (!defined $_[0]) {
	        croak "Argument wasn't defined";
	    }

	    if (ref $_[0] && ref $_[0] ne "CODE" && ref $_[0] ne "SCALAR") {
	        croak "Expecting string, coderef or scalarref for one-argument form";
	    }
	    elsif(!ref $_[0]) {
	        $self->{stdin} = [plain => $_[0]];
	        $self->{select}->[0] = 1;
	    }
	    elsif(ref $_[0] eq "CODE") {
	        $self->{stdin} = [coderef => $_[0]];
	        $self->{select}->[0] = 1;
	    }
	    elsif(ref $_[0] eq "SCALAR") {
	        $self->{stdin} = [scalarref => $_[0]];
	        $self->{select}->[0] = 1;
	    }
	    else {
	        die "Should be unreachable";
	    }
    }
    elsif(@_ == 2) {
	    if(!defined $_[0]) {
	        croak "Type wasn't defined";
	    }

	    if($_[0] eq "-inherit") {
	        $self->{stdin} = [file => \*STDIN];
	        $self->{select}->[0] = 0;
	    }
	    elsif($_[0] eq "-file") {
	        $self->{stdin} = [file => $_[1]];
	        $self->{select}->[0] = 0;
	    }
	    elsif($_[0] eq "-filename") {
	        if(!defined $_[1] || ref $_[1] || $_[1] =~ /\000/) {
		        croak "Argument to -filename wasn't a valid filename";
	        }
	        $self->{stdin} = [filename => $_[1]];
	        $self->{select}->[0] = 0;
	    }
	    elsif($_[0] eq "-fd") {
	        if(!defined $_[1] || ref $_[1] || $_[1] !~ /^\d+$/) {
		        croak "Argument to -fd wasn't a file descriptor";
	        }
	        $self->{stdin} = [fd => $_[1]];
	        $self->{select}->[0] = 0;
	    }
	    else {
	        croak "Unknown type \"$_[0]\"";
	    }
    }
    else {
	    croak "Expecting 1 or 2 arguments";
    }

    $self->_debug(2, "Updating stdin to be of type '" . $self->{stdin}->[0] . "'");

    return $self;
}

=head2 I<$isc>->B<stdout>()

=head2 I<$isc>->B<stderr>()

These 0-argument forms return the captured stdout/stderr if the
default stdout/stderr handler is set and B<run>() has been called.
If either has been setup elsewhere, then these will croak() an
error.

=head2 I<$isc>->B<stdout>(I<$value>)

=head2 I<$isc>->B<stderr>(I<$value>)

=head2 I<$isc>->B<stdout>(I<$type>, I<$value>)

=head2 I<$isc>->B<stderr>(I<$type>, I<$value>)

These setup stdout/stderr as appropriate. The forms are similar
to the B<stdin> method above.

The 1 argument form takes either

=over 4

=item A scalar ref

This is a reference to a scalar that will have the output appended
to it.

=item A code ref 

This code will be called (probably more than once) with a scalar
of text to be appended which has been read from stdout/stderr.

=back

The 2 argument form takes a type and then a ref, handle or other.
Valid types:

=over 4

=item -inherit

The argument to this is ignored. If specified this takes stdout/stderr
from whatever the caller is set to.

=item -file

The argument to this is a perl filehandle.

=item -fd

The argument to this is a system file descriptor.

=item -filename

The argument to this is a filename which is opened.

=back

All of these forms return I<> for chaining. The default is
that it will populate an internal variable to be used by the
corresponding 0-argument form.

=cut

sub stdout {
    my $self = shift;
    return $self->_access_out("stdout", 1, @_);
}

sub stderr {
    my $self = shift;
    return $self->_access_out("stderr", 2, @_);
}

sub _access_out {
    my $self = shift;
    my $name = shift;
    my $fd = shift;

    if(@_ == 0) {
	    if($self->{run}) {
	        if(exists $self->{$name . "_text"}) {
		        return $self->{$name . "_text"};
	        }
	        else {
		        croak "Can't read $name from type \"" . $self->{$name}->[0] . \"";
	        }
	    }
	    else {
	        croak "Can't get $name until run() has happened";
	    }
    }

    # At this point, we're in a >0 argument form

    croak "Can't change setup after command has been run"
	    if($self->{run});

    if(@_ == 1) {
	    if(!defined $_[0]) {
	        croak "Argument wasn't defined";
	    }

	    if(!ref $_[0] || ref $_[0] ne "CODE" && ref $_[0] ne "SCALAR") {
	        croak "Expecting coderef or scalarref for one-argument form";
	    }
	    elsif(ref $_[0] eq "CODE") {
	        $self->{$name} = [coderef => $_[0]];
	        $self->{select}->[$fd] = 1;
	    }
	    elsif(ref $_[0] eq "SCALAR") {
	        $self->{$name} = [scalarref => $_[0]];
	        $self->{select}->[$fd] = 1;
	    }
	    else {
	        die "Should be unreachable";
	    }
    }
    elsif(@_ == 2) {
	    if(!defined $_[0]) {
	        croak "Type wasn't defined";
	    }

	    if($_[0] eq "-inherit") {
	        if($name eq "stdout") {
		        $self->{$name} = [file => \*STDOUT];
	        }
	        else {
		        $self->{$name} = [file => \*STDERR];
	        }
	        $self->{select}->[$fd] = 0;
	    }
	    elsif($_[0] eq "-file") {
	        $self->{$name} = [file => $_[1]];
	        $self->{select}->[$fd] = 0;
	    }
	    elsif($_[0] eq "-filename") {
	        if(!defined $_[1] || ref $_[1] || $_[1] =~ /\000/) {
		        croak "Argument to -filename wasn't a valid filename";
	        }
	        $self->{$name} = [filename => $_[1]];
	        $self->{select}->[$fd] = 0;
	    }
	    elsif($_[0] eq "-fd") {
	        if(!defined $_[1] || ref $_[1] || $_[1] !~ /^\d+$/) {
                croak "Argument to -fd wasn't a file descriptor";
            }
            $self->{$name} = [fd => $_[1]];
            $self->{select}->[$fd] = 0;
        }
        else {
            croak "Unknown type \"$_[0]\"";
        }
    }
    else {
        croak "Expecting 0, 1 or 2 arguments";
    }

    $self->_debug(2, "Updating $name to be of type '" . $self->{$name}->[0] . "'");

    return $self;
}

=head2 I<$isc>->B<status>()

Returns the exit status of the command if it got run.

=cut

sub status {
    my $self = shift;

    if($self->{run}) {
        return($self->{status});
    }
    else {
        croak "Can't get status before command has been run";
    }
}

=head2 I<$isc>->B<run>()

Runs the command with all the setup that has been done.

=cut

sub run {
    my $self = shift;

    my @cmd = $self->_transform_cmd();

    $self->_debug(1, "About to run \`" . join("', \`", @cmd) . "'");

    $self->_verify_fh();

    for my $fh (qw(stdin stdout stderr)) {
	my $select = $self->{select}->[{stdin => 0, stdout => 1, stderr => 2}->{$fh}];
    if($select) {
        my $pipe = IO::Pipe->new();
        if(!defined $pipe) {
            die "pipe(): $!";
        }
        push(@{$self->{$fh}}, $pipe);
    }
}

    my $pid = fork();

    if(!defined $pid) {
        die "fork(): $!";
    }
    if(!$pid) {
        # child
        # In here, we only die, we don't croak, as the caller is very definitely parent only

        my $ret;
        if(defined $self->{umask}) {
            $ret = umask $self->{umask};
            if(!defined $ret) {
                die "umask(): $!\n";
            }
        }
        if(defined $self->{wd}) {
            $ret = chdir($self->{wd});
            if(!defined $ret) {
                die "chdir(): $!\n";
            }
        }
        if(keys %{$self->{env}||{}}) {
            for my $e (keys %{$self->{env}}) {
                $ENV{$e} = $self->{env}->{$e};
            }
        }

        if($self->{stdin}->[0] eq "file") {
            if(!open(STDIN, "<&", $self->{stdin}->[1])) {
                die("dup2(stdin): $!\n");
            }
        }
        else {
            $self->{stdin}->[2]->reader();
            if(!open(STDIN, "<&", $self->{stdin}->[2])) {
                die("dup2(stdin): $!\n");
            }
        }

        if($self->{stdout}->[0] eq "file") {
            if(!open(STDOUT, ">>&", $self->{stdout}->[1])) {
                die("dup2(stdout): $!\n");
            }
        }
        else {
            $self->{stdout}->[2]->writer();
            if(!open(STDOUT, ">>&", $self->{stdout}->[2])) {
                die("dup2(stdout): $!\n");
            }
        }

        if($self->{stderr}->[0] eq "file") {
            if(!open(STDERR, ">>&", $self->{stderr}->[1])) {
                die("dup2(stderr): $!\n");
            }
        }
        else {
            $self->{stderr}->[2]->writer();
            if(!open(STDERR, ">>&", $self->{stderr}->[2])) {
                die("dup2(stderr): $!\n");
            }
        }

        for(my $i = 3 ; $i < 16384; $i++) {
            POSIX::close($i);
        }

        exec(@cmd);
        die("exec: $!\n");
    }
    else {
        # parent

        $self->_debug(2, "After fork: child $pid");

        for my $fh (qw(stdin stdout stderr)) {
            if($self->{$fh}->[0] eq "file") {
                if($self->{$fh}->[2]) {
                    $self->_debug(2, "Closing $fh in parent due to being a file");
                    close($self->{$fh}->[1]);
                }
            }
            else {
                if($fh eq "stdin") {
                    $self->_debug(2, "Setting $fh as non-block writer in parent");
                    $self->{$fh}->[2]->writer();
                    $self->{$fh}->[2]->blocking(0);
                }
                else {
                    $self->_debug(2, "Setting $fh as non-block reader in parent");
                    $self->{$fh}->[2]->reader();
                    $self->{$fh}->[2]->blocking(0);
                }
            }
        }

        $self->_select_wait($pid);
    }

    $self->{run} = 1;

    return $self;
}

sub _select_wait {
    my $self = shift;
    my $pid = shift;

    local $Carp::CarpLevel = 1;

    # select loop
    my($rin, $win, $ein, $rout, $wout, $eout) = ("", "", "");

    if($self->{stdin}->[0] ne "file") {
        $self->_debug(3, "Adding stdin to writers");
        vec($win, fileno($self->{stdin}->[2]), 1) = 1;
    }

    for my $fh (qw(stdout stderr)) {
        if($self->{$fh}->[0] ne "file") {
            $self->_debug(3, "Adding $fh to readers");
            vec($rin, fileno($self->{$fh}->[2]), 1) = 1;
        }
    }

    while($rin =~ /[^\0]/ || $win =~ /[^\0]/) {
        select($rout = $rin, $wout = $win, $eout = $ein, 0.01);

        if($self->{stdin}->[0] ne "file" && vec($wout, fileno($self->{stdin}->[2]), 1)) {
            if($self->{stdin}->[0] eq "plain") {
                my $length = length($self->{stdin}->[1]);
                if($length) {
                    $length = $IPC::ShellCmd::BufferLength
                    if($length > $IPC::ShellCmd::BufferLength);
                    $self->_debug(3, "Writing into stdin from plain scalar");
                    my $rc = syswrite($self->{stdin}->[2], $self->{stdin}->[1], $length);
                    if(!defined $rc) {
                        die("write(->stdin): $!\n");
                    }

                    $self->{stdin}->[1] = substr($self->{stdin}->[1], $rc);
                }
                if(!length($self->{stdin}->[1])) {
                    $self->_debug(3, "Removing stdin from writers, and closing");
                    vec($win, fileno($self->{stdin}->[2]), 1) = 0;
                    close($self->{stdin}->[2]);
                }
            }
            elsif($self->{stdin}->[0] eq "scalarref") {
                $self->{stdin}->[3] = 0 unless defined $self->{stdin}->[3];
                my $length = length(${$self->{stdin}->[1]}) - $self->{stdin}->[3];
                if($length) {
                    $length = $IPC::ShellCmd::BufferLength
                    if($length > $IPC::ShellCmd::BufferLength);
                    $self->_debug(3, "Writing into stdin from scalarref");
                    my $rc = syswrite($self->{stdin}->[2],
                        substr(${$self->{stdin}->[1]}, $self->{stdin}->[3]), $length);
                        if(!defined $rc) {
                            die("write(->stdin): $!\n");
                        }

                        $self->{stdin}->[3] += $rc;
                    }
                    if(length(${$self->{stdin}->[1]}) == $self->{stdin}->[3]) {
                        $self->_debug(3, "Removing stdin from writers, and closing");
                        vec($win, fileno($self->{stdin}->[2]), 1) = 0;
                        close($self->{stdin}->[2]);
                    }
                }
                elsif($self->{stdin}->[0] eq "coderef") {
                    $self->{stdin}->[3] = ""
                    unless defined $self->{stdin}->[3];

                    $self->{stdin}->[4] = 0
                    unless defined $self->{stdin}->[4];
                    my $finished = $self->{stdin}->[4];

                    if(!$finished && length $self->{stdin}->[3] < $IPC::ShellCmd::BufferLength) {
                        my $data = $self->{stdin}->[1]->($IPC::ShellCmd::BufferLength - length($self->{stdin}->[3]));
                        if(!defined $data) {
                            $finished = 1;
                        }

                        $self->{stdin}->[3] .= $data;
                        if(length($self->{stdin}->[3]) > $IPC::ShellCmd::BufferLength) {
                            $self->{stdin}->[3] = substr($self->{stdin}->[3], 0, $IPC::ShellCmd::BufferLength);

                        }
                    }

                    if(length($self->{stdin}->[3])) {
                        $self->_debug(3, sprintf("Writing %d into stdin from coderef", length($self->{stdin}->[3])));
                        my $rc = syswrite($self->{stdin}->[2], $self->{stdin}->[3], length($self->{stdin}->[3]));
                        if(!defined $rc) {
                            die("write(->stdin): $!\n");
                        }

                        $self->{stdin}->[3] = substr($self->{stdin}->[3], $rc);
                    }

                    $self->{stdin}->[4] = $finished;

                    if($finished && !length($self->{stdin}->[3])) {
                        $self->_debug(3, "Removing stdin from writers, and closing");
                        vec($win, fileno($self->{stdin}->[2]), 1) = 0;
                        close($self->{stdin}->[2]);
                    }
                }
            }

            for my $fh (qw(stdout stderr)) {
                if($self->{$fh}->[0] ne "file" && vec($rout, fileno($self->{$fh}->[2]), 1)) {
                    my $buff = "";
                    $self->_debug(3, "Reading $IPC::ShellCmd::BufferLength from $fh");
                    my $rc = sysread($self->{$fh}->[2], $buff, $IPC::ShellCmd::BufferLength);
                    if(!defined $rc) {
                        die("read(->$fh): $!\n");
                    }
                    if(!$rc) {
                        $self->_debug(3, "Removing $fh from readers, and closing");
                        vec($rin, fileno($self->{$fh}->[2]), 1) = 0;
                        close($self->{$fh}->[2]);
                    }
                    else {
                        if($self->{$fh}->[0] eq "scalarref") {
                            ${$self->{$fh}->[1]} .= $buff;
                        }
                        elsif($self->{$fh}->[0] eq "coderef") {
                            $self->{$fh}->[1]->($buff);
                        }
                    }
                }
            }

            if(!defined $self->{status} && waitpid($pid, WNOHANG)) {
                $self->_debug(3, "Reaped child $pid in loop");
                $win = "";
                $self->{status} = $?;
            }
        }

        if($rin !~ /[^\0]/ && $win !~ /[^\0]/ && !defined $self->{status}) {
            $self->_debug(3, "Trying to reap child $pid");
            my $rc = waitpid($pid, 0);
            $self->_debug(3, "Reaped child $pid");
            if(defined $rc) {
                $self->{status} = $?;
            }
            else {
                die("waitpid: $!\n");
            }
        }
        return;
    }

    sub _verify_fh {
        my $self = shift;

        for my $fh (qw(stdin stdout stderr)) {
            if(!$self->{$fh}) {
                croak "Defaulting didn't happen for $fh";
            }

            my $type = $self->{$fh}->[0];
            my $select = $self->{select}->[{stdin => 0, stdout => 1, stderr => 2}->{$fh}];

            # all of the "filename" and "fd" types should have been got rid of as a part
            # of the _transform_cmd called before this.

            # First check the types of all the fhs
            if($type ne "plain" && $type ne "coderef" && $type ne "scalarref" &&
            $type ne "file") {
                # this is an assert so there's no CarpLevel...
                croak "Unrecognised type $type for $fh";
            }
            elsif($type eq "plain" && $fh ne "stdin") {
                croak "Plain is only useful for stdin, not $fh";
            }

            # Then we check that select is correctly set.
            if($type eq "plain" || $type eq "coderef" || $type eq "scalarref") {
                if(!$select) {
                    croak "$type should be selected on but isn't for $fh";
                }
            }
            else {
                if($select) {
                    croak "$type shouldn't be selected on but is for $fh";
                }
            }
        }
    }

    sub _transform_cmd {
        my $self = shift;

        my $count = 1;

        my $file = { stdin => 0, stdout => 0, stderr => 0 };

        for my $fh (qw(stdin stdout stderr)) {
            if($self->{$fh} && $self->{$fh}->[0] eq "filename") {
                $file->{$fh} = 1;
            }
        }

        my @cmd = @{$self->{cmd}};

        for my $el (@{$self->{chain}||[]}) {
            $self->_debug(2, "Before chain $count cmd = \`" . join("', \`", @cmd) . "'");

            my @args = ();
            if($count == 1) {
                if(defined($self->{wd})) {
                    push(@args, "-wd", $self->{wd});
                    delete $self->{wd};
                }
                if(keys %{$self->{env}}) {
                    push(@args, "-env", {%{$self->{env}}});
                    delete $self->{env};
                }
                if(defined($self->{umask})) {
                    push(@args, "-umask", $self->{umask});
                    delete $self->{umask};
                }
            }

            for my $fh (qw(stdin stdout stderr)) {
                if($file->{$fh} && $el->{opt}->{$fh}) {
                    push(@args, "-" . $fh, $self->{$fh}->[1]);
                    $file->{$fh} = 0;
                    # in this sub bit, because of $file->{fh}, this must be
                    # a filename, so we can do the following.
                    $self->{$fh}->[1] = "/dev/null";
                }
            }

            $self->_debug(2, "Calling chain $count with args = \`" . join("', \`", @args) . "'");
            @cmd = $el->{obj}->chain([@cmd], {@args});

            $self->_debug(2, "After chain $count cmd = \`" . join("', \`", @cmd) . "'");

            $count++;
        }

        # Figure out all the command defaults
        if(!$self->{stdin}) {
            $self->{stdin} = [filename => "/dev/null"];
            $self->{select}->[0] = 0;
        }
        for my $fh (qw(stdout stderr)) {
            if(!$self->{$fh}) {
                $self->{$fh . "_text"} = "";
                my $ref = \$self->{$fh . "_text"};
                $self->{$fh} = [scalarref => $ref];
            }
        }

        # as a side effect of this sub, we also end up transforming filenames and fds
        # into file handles.
        for my $fh (qw(stdin stdout stderr)) {
            local $Carp::CarpLevel = 1;
            if($self->{$fh} && $self->{$fh}->[0] eq "filename") {
                my $pfh;
                if(open($pfh, ($fh eq "stdin"?"<":">>"), $self->{$fh}->[1])) {
                    $self->{$fh} = [file => $pfh, 1];
                }
                else {
                    croak "Couldn't open file \"" . $self->{$fh}->[1] . "\": $!";
                }
            }
            elsif($self->{$fh} && $self->{$fh}->[0] eq "fd") {
                my $pfh;
                if(open($pfh, ($fh eq "stdin"?"<&=":">>&="), $self->{$fh}->[1])) {
                    $self->{$fh} = [file => $pfh];
                }
                else {
                    croak "Couldn't fdopen " . $self->{$fh}->[1] . ": $!";
                }
            }
        }

        return @cmd;
    }

=head1 BUGS

Apart from the ones that are probably in there and that I don't know
about, this is a very UNIX-centric view of the world, it really should
cope with Win32 concepts etc.

=head1 SEE ALSO

L<IPC::ShellCmd::Generic>, L<IPC::ShellCmd::Sudo>, L<IPC::ShellCmd::SSH>, L<IO::Select>, L<IPC::Open3>

=head1 AUTHORS

    Matthew Byng-Maddick <matthew.byng-maddick@bbc.co.uk> <mbm@colondot.net>

    Tomas Doran (t0m) <bobtfish@bobtfish.net>

=head1 COPYRIGHT

Copyright (c) 2009 the British Broadcasting Corperation.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
