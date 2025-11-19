package Dev::Util::OS;

use Dev::Util::Syntax;
use Exporter qw(import);

use IPC::Cmd qw[can_run run];

our $VERSION = version->declare("v2.19.6");

our @EXPORT_OK = qw(
    get_os
    get_hostname
    is_linux
    is_mac
    is_freebsd
    is_openbsd
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

sub is_freebsd {
    if ( get_os() eq "FreeBSD" ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_openbsd {
    if ( get_os() eq "OpenBSD" ) {
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

my %osx_distro_ver = (
                       10.0  => 'Cheetah',
                       10.1  => 'Puma',
                       10.2  => 'Jaguar',
                       10.3  => 'Panther',
                       10.4  => 'Tiger',
                       10.5  => 'Leopard',
                       10.6  => 'Snow Leopard',
                       10.7  => 'Lion',
                       10.8  => 'Mountain Lion',
                       10.9  => 'Mavericks',
                       10.10 => 'Yosemite',
                       10.11 => 'El Capitan',
                       10.12 => 'Sierra',
                       10.13 => 'High Sierra',
                       10.14 => 'Mojave',
                       10.15 => 'Catalina',
                     );
my %macos_distro_ver = (
                         11 => 'Big Sur',
                         12 => 'Monterey',
                         13 => 'Ventura',
                         14 => 'Sonoma',
                         15 => 'Sequioa',
                         16 => 'Tahoe',
                       );

my %ubuntu_distro_ver = (
                          '4.10'  => 'Warty Warthog',
                          '5.04'  => 'Hoary Hedgehog',
                          '5.10'  => 'Breezy Badger',
                          '6.06'  => 'Dapper Drake',
                          '6.10'  => 'Edgy Eft',
                          '7.04'  => 'Feisty Fawn',
                          '7.10'  => 'Gutsy Gibbon',
                          '8.04'  => 'Hardy Heron',
                          '8.10'  => 'Intrepid Ibex',
                          '9.04'  => 'Jaunty Jackalope',
                          '9.10'  => 'Karmic Koala',
                          '10.04' => 'Lucid Lynx',
                          '10.10' => 'Maverick Meerkat',
                          '11.04' => 'Natty Narwhal',
                          '11.10' => 'Oneiric Ocelot',
                          '12.04' => 'Precise Pangolin',
                          '12.10' => 'Quantal Quetzal',
                          '13.04' => 'Raring Ringtail',
                          '13.10' => 'Saucy Salamander',
                          '14.04' => 'Trusty Tahr',
                          '14.10' => 'Utopic Unicorn',
                          '15.04' => 'Vivid Vervet',
                          '15.10' => 'Wily Werewolf',
                          '16.04' => 'Xenial Xerus',
                          '16.10' => 'Yakkety Yak',
                          '17.04' => 'Zesty Zapus',
                          '17.10' => 'Artful Aardvark',
                          '18.04' => 'Bionic Beaver',
                          '18.10' => 'Cosmic Cuttlefish',
                          '19.04' => 'Disco Dingo',
                          '19.10' => 'Eoan Ermine',
                          '20.04' => 'Focal Fossa',
                          '20.10' => 'Groovy Gorilla',
                          '21.04' => 'Hirsute Hippo',
                          '21.10' => 'Impish Indri',
                          '22.04' => 'Jammy Jellyfish',
                          '22.10' => 'Kinetic Kudu',
                          '23.04' => 'Lunar Lobster',
                          '23.10' => 'Mantic Minotaur',
                          '24.04' => 'Noble Numbat',
                          '24.10' => 'Oracular Oriole',
                          '25.04' => 'Plucky Puffin',
                          '25.10' => 'Questing Quokka',
                          '26.04' => 'Resolute Raccoon',
                        );

my %opensuse_distro_ver = (
                            11.2 => 'Emerald',
                            11.3 => 'Teal',
                            11.4 => 'Celadon',
                            12.1 => 'Asparagus',
                            12.2 => 'Mantis',
                            12.3 => 'Dartmoth',
                            13.1 => 'Bottle',
                            13.2 => 'Harlequin',
                            42.1 => 'Malacite',
                          );

my %debian_distro_ver = (
                          '1.1' => 'buzz',
                          '1.2' => 'rex',
                          '1.3' => 'bo',
                          '2.0' => 'hamm',
                          '2.1' => 'slink',
                          '2.2' => 'potato',
                          '3.0' => 'woody',
                          '3.1' => 'sarge',
                          '4.0' => 'etch',
                          '5.0' => 'lenny',
                          '6.0' => 'squeeze',
                          '7'   => 'wheezy',
                          '8'   => 'jessie',
                          '9'   => 'stretch',
                          '10'  => 'buster',
                          '11'  => 'bullseye',
                          '12'  => 'bookworm',
                          '13'  => 'trixie',
                          '14'  => 'forky',
                          '15'  => 'duke',
                        );

my %redhat_distro_ver = (
                          '2.1' => 'Pensacola',
                          '3'   => 'Taroon',
                          '4'   => 'Nahant',
                          '5'   => 'Tikanga',
                          '6'   => 'Santiago',
                          '7'   => 'Maipo',
                          '8'   => 'Ootpa',
                          '9'   => 'Plow',
                          '10'  => 'Coughlan',
                        );

my %raspbian_distro_ver = (
                            '7'  => 'wheezy',
                            '8'  => 'jessie',
                            '9'  => 'stretch',
                            '10' => 'buster',
                            '11' => 'bullseye',
                            '12' => 'bookworm',
                            '13' => 'trixie',
                          );

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

Version v2.19.6

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
    is_freebsd
    is_openbsd
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

=head2 B<is_freebsd>

Return true if the current system is FreeBSD.

    my $system_is_FreeBSD = is_freebsd();

=head2 B<is_openbsd>

Return true if the current system is OpenBSD.

    my $system_is_OpenBSD = is_openbsd();

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
