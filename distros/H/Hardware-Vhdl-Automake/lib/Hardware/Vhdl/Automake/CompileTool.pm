package Hardware::Vhdl::Automake::CompileTool;
use Hardware::Vhdl::Automake::DesignUnit;
use File::Spec::Functions;
use Carp;

use strict;
use warnings;

=head1 NAME

Hardware::Vhdl::Automake::CompileTool - Base class for compilation tool controller

=cut

my $null = File::Spec::Functions::devnull();

sub new { # class or object method, returns a new project object
	my $class=shift;
    $class = ref $class || $class;
	my $self={
        toolid => $class,
        status_callback => undef,
    };
	bless $self, $class;
    $self->init(@_);
    $self;
}

sub toolid { $_[0]->{toolid} }

sub init {
}

sub set_status_callback {
    my $self = shift;
    $self->{status_callback} = shift;
}

sub report_status {
    my $self = shift;
    &{$self->{status_callback}}(@_) if defined $self->{status_callback};
}

sub compile_start {
    my $self = shift;
    $self->report_status({type => 'compile_start', text => 'Starting compilation'});
}

sub compile {
    my $self = shift;
    my $dunit = shift;
    $self->report_status({type => 'compile', text => 'Compiling a design unit'});
    #...
    $dunit->set_compile_info($self->{toolid}, { xxx => 123 });
}

sub compile_finish {
    my $self = shift;
    $self->report_status({type => 'compile_finish', text => 'Finishing compilation'});
}

sub compile_abort {
    my $self = shift;
    $self->report_status({type => 'compile_abort', text => 'Aborting compilation'});
}

sub sys_capture {
    # taken from Shell.pm by Larry Wall, Jenda@Krynicky.cz, Dave Cottle <d.cottle@csc.canterbury.ac.nz> and Casey West <casey@geeknest.com>.
    my $self = shift;
    my $cmd = shift;
    my @cmd_args;
    if (ref $cmd eq 'ARRAY') {
        @cmd_args = @$cmd;
        $cmd = shift @cmd_args;
    }
    my $raw = 0;
    my $capture_stderr = 1;
    #print join(' ',"\n# Executing command:",$cmd, @cmd_args)."\n";
    if ( @cmd_args < 1 ) {
        $capture_stderr == 1      ? qx/$cmd 2>\&1/
          : $capture_stderr == -1 ? qx/$cmd 2>$null/
          : qx/$cmd/;
    } elsif ( $^O eq 'os2' ) {
        local ( *SAVEOUT, *READ, *WRITE );

        open SAVEOUT, '>&STDOUT' or die;
        pipe READ, WRITE or die;
        open STDOUT, '>&WRITE' or die;
        close WRITE;

        my $pid = system( 1, $cmd, @cmd_args );
        die "Can't execute $cmd: $!\n" if $pid < 0;

        open STDOUT, '>&SAVEOUT' or die;
        close SAVEOUT;

        if (wantarray) {
            my @ret = <READ>;
            close READ;
            waitpid $pid, 0;
            @ret;
        } else {
            local ($/) = undef;
            my $ret = <READ>;
            close READ;
            waitpid $pid, 0;
            $ret;
        }
    } else {
        my $a;
        my @arr = @cmd_args;
        unless ($raw) {
            if ( $^O eq 'MSWin32' ) {

                # XXX this special-casing should not be needed
                # if we do quoting right on Windows. :-(
                #
                # First, escape all quotes.  Cover the case where we
                # want to pass along a quote preceded by a backslash
                # (i.e., C<"param \""" end">).
                # Ugly, yup?  You know, windoze.
                # Enclose in quotes only the parameters that need it:
                #   try this: c:> dir "/w"
                #   and this: c:> dir /w
                for (@arr) {
                    s/"/\\"/g;
                    s/\\\\"/\\\\"""/g;
                    $_ = qq["$_"] if /\s/;
                }
                #print "Win32 command: ", join(' ', $cmd, @arr), "\n";
            } else {
                for (@arr) {
                    s/(['\\])/\\$1/g;
                    $_ = $_;
                }
            }
        }
        push @arr, '2>&1'  if $capture_stderr == 1;
        push @arr, '2>$null' if $capture_stderr == -1;
        open( SUBPROC, join( ' ', $cmd, @arr, '|' ) )
          or die "Can't exec $cmd: $!\n";
        if (wantarray) {
            my @ret = <SUBPROC>;
            close SUBPROC;    # XXX Oughta use a destructor.
            @ret;
        } else {
            local ($/) = undef;
            my $ret = <SUBPROC>;
            close SUBPROC;
            $ret;
        }
    }
}

1;
