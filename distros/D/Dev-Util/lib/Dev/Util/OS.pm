package Dev::Util::OS;

use lib 'lib';
use Dev::Util::Syntax;
use Exporter qw(import);
use IPC::Cmd qw[can_run run];

our $VERSION = version->declare("v2.17.17");

our @EXPORT_OK = qw(
    get_os
    get_hostname
    is_linux
    is_mac
    is_sunos
    ipc_run_c
    ipc_run_e
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub get_os {
    my $OS = qx(uname -s);
    chomp $OS;

    return $OS;
}

sub get_hostname {
    my $host = qx(uname -n);
    chomp $host;

    return $host;
}

sub is_linux {
    if ( get_os() eq "Linux" ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_mac {
    if ( get_os() eq "Darwin" ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_sunos {
    if ( get_os() eq "SunOS" ) {
        return 1;
    }
    else {
        return 0;
    }
}

# execute the cmd return 1 on success 0 on failure
sub ipc_run_e {
    my ($arg_ref) = @_;
    $arg_ref->{ debug } ||= 0;
    warn "cmd: $arg_ref->{ cmd }\n" if $arg_ref->{ debug };

    if (
          scalar run(
                      command => $arg_ref->{ cmd },
                      buffer  => $arg_ref->{ buf },
                      verbose => $arg_ref->{ verbose } || 0,
                      timeout => $arg_ref->{ timeout } || 10,
                    )
       )
    {
        return 1;
    }
    return 0;
}

# capture the output of the cmd and return it as an array or undef on failure
sub ipc_run_c {
    my ($arg_ref) = @_;
    $arg_ref->{ debug } ||= 0;
    warn "cmd: $arg_ref->{ cmd }\n" if $arg_ref->{ debug };

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf )
        = run(
               command => $arg_ref->{ cmd },
               verbose => $arg_ref->{ verbose } || 0,
               timeout => $arg_ref->{ timeout } || 10,
             );

    # each element of $stdout_buf can contain multiple lines
    # flatten to one line per element in result returned
    if ($success) {
        my @result;
        foreach my $lines ( @{ $stdout_buf } ) {
            foreach my $line ( split( /\n/, $lines ) ) {
                push @result, $line;
            }
        }
        return @result;
    }
    return;
}

1;    # End of Dev::Util::OS

=pod

=encoding utf-8

=head1 NAME

Dev::Util::OS - OS discovery and functions

=head1 VERSION

Version v2.17.17

=head1 SYNOPSIS

OS discovery and functions

    use Disk::SmartTools::OS;

    my $OS = get_os();
    my $hostname = get_hostname();
    my $system_is_linux = is_linux();
    ...
    my $status = ipc_run_e( { cmd => 'echo hello world', buf => \$buf } );
    my @seq = ipc_run_c( { cmd => 'seq 1 10', } );

=head1 EXPORT

    get_os
    get_hostname
    is_linux
    is_mac
    is_sunos
    ipc_run_e
    ipc_run_c

=head1 SUBROUTINES

=head2 B<get_os>

Return the OS of the current system.

    my $OS = get_os();

=head2 B<get_hostname>

Return the hostname of the current system.

    my $hostname = get_hostname();

=head2 B<is_linux>

Return true if the current system is Linux.

    my $system_is_linux = is_linux();

=head2 B<is_mac>

Return true if the current system is MacOS (Darwin).

    my $system_is_macOS = is_mac();

=head2 B<is_sunos>

Return true if the current system is SunOS.

    my $system_is_sunOS = is_sunos();

=head2 B<ipc_run_e(ARGS_HASH)>

Execute an external program and return the status of it's execution.

B<ARGS_HASH:>
{ cmd => CMD, buf => BUFFER_REF, verbose => VERBOSE_BOOL, timeout => SECONDS, debug => DEBUG_BOOL }

C<CMD> The external command to execute

C<BUFFER_REF> A reference to a buffer

C<VERBOSE_BOOL:optional> 1 (default) for verbose output, 0 not so much

C<SECONDS:optional> number of seconds to wait for CMD to execute, default: 10 sec

C<DEBUG_BOOL: optional> Debug flag, default: 0

    my $status = ipc_run_e( { cmd => 'echo hello world', verbose => 1, timeout => 8 } );

=head2 B<ipc_run_c(ARGS_HASH)>

Capture the output of an external program.  Return the output or return undef on failure.

B<ARGS_HASH:>
{ cmd => CMD, buf => BUFFER_REF, verbose => VERBOSE_BOOL, timeout => SECONDS, debug => DEBUG_BOOL }

    my @seq = ipc_run_c( { cmd => 'seq 1 10', } );

=head1 AUTHOR

Matt Martini, C<< <matt at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dev-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::OS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dev-Util>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Dev-Util>

=item * Search CPAN

L<https://metacpan.org/release/Dev-Util>

=back

=head1 ACKNOWLEDGMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2019-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007

=cut

__END__
