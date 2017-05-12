package Linux::Proc::Cpuinfo;

use 5.006000;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load( 'Linux::Proc::Cpuinfo', $VERSION );

sub DESTROY {
    my $self = shift;
    $self->destroy;
}

1;

__END__

=head1 NAME

Linux::Proc::Cpuinfo - XS wrapper for libproccpuinfo - a generic parser for /proc/cpuinfo

=head1 SYNOPSIS

    use Linux::Proc::Cpuinfo;

    my $info = Linux::Proc::Cpuinfo->new;
    if ( defined $info ) {
        print "Architecture:\t\t",    $info->architecture,      "\n";
        print "Hardware Platform:\t", $info->hardware_platform, "\n";
        print "Frequency:\t\t",       $info->frequency,         "\n";
        print "Bogomips:\t\t",        $info->bogomips,          "\n";
        print "Cache:\t\t\t",         $info->cache,             "\n";
        print "CPUs:\t\t\t",          $info->cpus,              "\n";
    }

=head1 DESCRIPTION

L<Linux::Proc::Cpuinfo> is a XS wrapper for C<libproccpuinfo>
(L<https://savannah.nongnu.org/projects/proccpuinfo/>). It provides a generic
interface to access C</proc/cpuinfo>.

=head1 METHODS

=head2 C<new> or C<new('filename')>

Returns a new L<Linux::Proc::Cpuinfo> object. Without any argument, parses
C</proc/cpuinfo>. If C<filename> is passed, then the file with that name is
parsed.

On error, returns C<undef>.

=head2 C<architecture>

Returns CPU architecture. If C</proc/cpuinfo> file does not list these values or
if the library fails to recognise the architecture, then the value will be set
to C<undef>.

=head2 C<hardware_platform>

Returns hardware platform. If C</proc/cpuinfo> file does not list these values
or if the library fails to recognise the hardware platform, then the value will
be set to C<undef>.

=head2 C<frequency>

Returns the CPU clock speed in MHz. If the C</proc/cpuinfo> file does not list
the clock speed or if the library fails to recognise the clock speed, then this
value defaults to C<undef>.

=head2 C<bogomips>

Returns the BogoMips as calculated by the kernel. BogoMips defaults to C<undef>
if the C</proc/cpuinfo> file does not list the BogoMips or if the library fails
to recognise the BogoMips.

=head2 C<cache>

Returns the amount of L2 cache in kilobytes. If the C</proc/cpuinfo> file does
not list the amount of L2 cache or if the library fails to recognise the amount
of L2 cache, then the value defaults to C<undef>.

=head2 C<cpus>

Returns the total number of processors detected. On systems that list the number
of detected processors and the number of active/enabled processors, the number
of detected processors is used. If the C</proc/cpuinfo> file does not list the
number of processors or if the library fails to determine the number of
processors, then the value defaults to C<1> since all running computers have at
least 1 processor.

=head1 INSTALLING C<libproccpuinfo>

=over 4

=item * Gentoo Linux

    # emerge libproccpuinfo

=item * Generic Linux

Download the latest archive (named similar to C<libproccpuinfo-x.x.x.tar.bz2>)
from L<http://download.savannah.gnu.org/releases/proccpuinfo/> and extract it.

    $ cmake -D CMAKE_INSTALL_PREFIX=/usr .
    $ make
    $ make test
    # make install

Please send me information on how to install it on other systems and I will
update it here.

=back

=head1 ACKNOWLEDGEMENT

Tim Heaney - reported missing dependency C<Devel::CheckLib>

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
