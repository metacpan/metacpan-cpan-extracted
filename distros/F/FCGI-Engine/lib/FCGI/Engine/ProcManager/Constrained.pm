package FCGI::Engine::ProcManager::Constrained;
use Moose;

use Config;
use Class::Load ();
use Try::Tiny;

extends 'FCGI::Engine::ProcManager';

sub BUILD {
    my $self = shift;
    if ($self->sizecheck_num_requests && ! _can_check_size()) {
        confess "Cannot load size check modules for your platform: sizecheck_num_requests > 0 unsupported";
    }
}

has max_requests => (
    isa => 'Int',
    is => 'ro',      # FIXME - This is fuck ugly.
    default => sub { $ENV{PM_MAX_REQUESTS} || 0 },
);

has request_count => (
    isa => 'Int',
    is => 'ro',
    traits => ['Counter'],
    handles => {
        _reset_request_counter => 'reset',
        _inc_request_counter => 'inc',
    },
    init_arg => undef,
    default => 0,
);

has [qw/
    sizecheck_num_requests
    max_process_size
    min_share_size
    max_unshared_size
/] => (
    isa => 'Int',
    is => 'ro',
    default => 0,
);

augment server_init => sub {
    my $self = shift;
    $self->_reset_request_counter();
};

augment post_dispatch => sub {
    my $self = shift;
    $self->exit("safe exit after max_requests (" . $self->max_requests . ")")
        if ($self->max_requests and $self->_inc_request_counter == $self->max_requests);

    if ($self->sizecheck_num_requests
        and $self->request_count # Not the first request
        and $self->request_count % $self->sizecheck_num_requests == 0
    ) {
        $self->exit("safe exit due to memory limits exceeded after " . $self->request_count . " requests")
            if $self->_limits_are_exceeded;
    }
};

sub _limits_are_exceeded {
    my $self = shift;

    my ($size, $share, $unshared) = $self->_check_size();

    return 1 if $self->max_process_size  && $size > $self->max_process_size;
    return 0 unless $share;
    return 1 if $self->min_share_size    && $share < $self->min_share_size;
    return 1 if $self->max_unshared_size && $unshared > $self->max_unshared_size;

    return 0;
}


# The following code is wholesale is nicked from Apache::SizeLimit::Core

sub _check_size {
    my $class = shift;

    my ($size, $share) = $class->_platform_check_size();

    return ($size, $share, $size - $share);
}

sub _load {
    my $mod = shift;
    try { Class::Load::load_class($mod); 1; }
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
    elsif ($Config{'osname'} eq 'linux' && _load('Linux::Pid')) {
        *_platform_getppid = \&_linux_getppid;
        *_can_check_size = sub () { 1 };
        if (_load('Linux::Smaps') && Linux::Smaps->new($$)) {
            $USE_SMAPS = 1;
            *_platform_check_size = \&_linux_smaps_size_check;
        }
        else {
            $USE_SMAPS = 0;
            *_platform_check_size = \&_linux_size_check;
        }
    }
    elsif ($Config{'osname'} =~ /(?:bsd|aix)/i && _load('BSD::Resource')) {
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

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

FCGI::Engine::ProcManager::Constrained - FastCGI applications with memory and number of request limits.

=head1 DESCRIPTION

A constrained process manager that restarts child workers after a number of requests
or if they use too much memory.

Most of the memory usage code is stolen from L<Apache2::SizeLimit>.

=head1 ATTRIBUTES

=head2 max_requests

The number of requests a child process can handle before being terminated.

0 (the default) means let child processes do an infinite number of requests

=head2 sizecheck_num_requests

The number of requests between a check on the process size taking place.

0 (the default) means never attempt to check the process size.

=head2 max_process_size

The maximum size of the process (both shared and unshared memory) in KB.

0 (the default) means unlimited.

=head2 max_unshared_size

The maximum amount of memory in KB this process can have that isn't Copy-On-Write
shared with other processes.

0 (the default) means unlimited.

=head2 min_share_size

The minimum amount of memory in KB this process can have Copy-On-Write from
it's parent process before it is terminate.

=head1 METHODS

I will fill this in more eventually, but for now if you really wanna know,
read the source.

=head1 SEE ALSO

=over

=item L<FCGI::Engine::ProcManager>

=item L<Apache2::SizeLimit>.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>

=head1 COPYRIGHT AND LICENSE

Code sections copied from L<Apache2::SizeLimit> are Copyright their
respective authors.

Copyright 2007-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
