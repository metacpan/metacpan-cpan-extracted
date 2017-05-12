package Devel::InterpreterSize;
use strict;
use warnings;
use Carp qw/ confess /;
use Config;
use Class::Load qw/ load_class /;
# The following code is wholesale is nicked from Apache::SizeLimit::Core

our $VERSION = '0.01';

sub new {
    my $class = shift;
    confess("Need Linux::Smaps or Linux::Pid or BSD::Resource, or your osname $Config{'osname'} is unsupported")
        unless _can_check_size();
    bless {@_}, $class;
}

sub can_check_size {
    _can_check_size();
}

sub check_size {
    my $class = shift;

    my ($size, $share) = $class->_platform_check_size();

    return ($size, $share, $size - $share);
}

our $USE_SMAPS;
BEGIN {
    my ($major,$minor) = split(/\./, $Config{'osvers'});
    if ($Config{'osname'} eq 'solaris' &&
        (($major > 2) || ($major == 2 && $minor >= 6))) {
        *_can_check_size = sub () { 1 };
        *_platform_check_size   = \&_solaris_2_6_size_check;
        *_platform_getppid = \&_perl_getppid;
    }
    elsif ($Config{'osname'} eq 'linux' && load_class('Linux::Pid')) {
        *_platform_getppid = \&_linux_getppid;
        *_can_check_size = sub () { 1 };
        if (load_class('Linux::Smaps') && Linux::Smaps->new($$)) {
            $USE_SMAPS = 1;
            *_platform_check_size = \&_linux_smaps_size_check;
        }
        else {
            $USE_SMAPS = 0;
            *_platform_check_size = \&_linux_size_check;
        }
    }
    elsif ($Config{'osname'} =~ /(?:darwin|bsd|aix)/i && load_class('BSD::Resource')) {
        # on OSX, getrusage() is returning 0 for proc & shared size.
        *_can_check_size = sub () { 1 };
        *_platform_check_size   = \&_bsd_size_check;
        *_platform_getppid = \&_perl_getppid;
    }
    else {
        *_can_check_size = sub () { 0 };
    }
}
 
sub _linux_smaps_size_check {
    my $class = shift;
 
    return $class->_linux_size_check() unless $USE_SMAPS;
 
    my $s = Linux::Smaps->new($$)->all;
    return ($s->size, $s->shared_clean + $s->shared_dirty);
}
 
sub _linux_size_check {
    my $class = shift;
 
    my ($size, $share) = (0, 0);
 
    if (open my $fh, '<', '/proc/self/statm') {
        ($size, $share) = (split /\s/, scalar <$fh>)[0,2];
        close $fh;
    }
    else {
        $class->_error_log("Fatal Error: couldn't access /proc/self/status");
    }
 
    # linux on intel x86 has 4KB page size...
    return ($size * 4, $share * 4);
}
 
sub _solaris_2_6_size_check {
    my $class = shift;
 
    my $size = -s "/proc/self/as"
        or $class->_error_log("Fatal Error: /proc/self/as doesn't exist or is empty");
    $size = int($size / 1024);
 
    # return 0 for share, to avoid undef warnings
    return ($size, 0);
}
 
# rss is in KB but ixrss is in BYTES.
# This is true on at least FreeBSD, OpenBSD, & NetBSD
sub _bsd_size_check {
 
    my @results = BSD::Resource::getrusage();
    my $max_rss   = $results[2];
    my $max_ixrss = int ( $results[3] / 1024 );
 
    return ($max_rss, $max_ixrss);
}
 
sub _win32_size_check {
    my $class = shift;
 
    # get handle on current process
    my $get_current_process = Win32::API->new(
        'kernel32',
        'get_current_process',
        [],
        'I'
    );
    my $proc = $get_current_process->Call();
 
    # memory usage is bundled up in ProcessMemoryCounters structure
    # populated by GetProcessMemoryInfo() win32 call
    my $DWORD  = 'B32';    # 32 bits
    my $SIZE_T = 'I';      # unsigned integer
 
    # build a buffer structure to populate
    my $pmem_struct = "$DWORD" x 2 . "$SIZE_T" x 8;
    my $mem_counters
        = pack( $pmem_struct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
 
    # GetProcessMemoryInfo is in "psapi.dll"
    my $get_process_memory_info = new Win32::API(
        'psapi',
        'GetProcessMemoryInfo',
        [ 'I', 'P', 'I' ],
        'I'
    );
 
    my $bool = $get_process_memory_info->Call(
        $proc,
        $mem_counters,
        length $mem_counters,
    );

    # unpack ProcessMemoryCounters structure
    my $peak_working_set_size =
        (unpack($pmem_struct, $mem_counters))[2];

    # only care about peak working set size
    my $size = int($peak_working_set_size / 1024);

    return ($size, 0);
}

sub _perl_getppid { return getppid }
sub _linux_getppid { return Linux::Pid::getppid() }

1;

__END__

=head1 NAME

Devel::InterpreterSize - Get rough sizes for the memory useage of perl

=head1 SYNOPIS

    use Devel::InterpreterSize;
    my ($total, $shared, $unshared) = Devel::InterpreterSize->new->check_size;

=head1 DESCRIPTION

Gives you back some simple figures for how much memory your perl us using,
in kilobytes.

=head1 ORIGINAL AUTHOR

Most of the code was stolen from L<Apache2::SizeLimit> with slight
tweaks.

=head1 THIS MODULES AUTHOR

Tomas (t0m) Doran C<<bobtfish@bobtfish.net>>

=head1 AUTHORS

All code taken from mod_perl is copyright the authors llisted in
L<Apache2::SizeLimit>.

And below:

=over

=item Doug Bagley <doug+modperl bagley.org>, channeling Procrustes.

-item Brian Moseley <ix maz.org>: Solaris 2.6 support

=item Doug Steinwand and Perrin Harkins <perrin elem.com>: added support for shared memory and additional diagnostic info

=item Matt Phillips <mphillips virage.com> and Mohamed Hendawi <mhendawi virage.com>: Win32 support

=item Torsten Foertsch <torsten.foertsch gmx.net>: Linux::Smaps support

=back

=head1 LICENSE

The Apache Software License, Version 2.0.

=cut

