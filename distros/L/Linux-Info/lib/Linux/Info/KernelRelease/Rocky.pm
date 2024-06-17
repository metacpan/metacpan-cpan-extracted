package Linux::Info::KernelRelease::Rocky;

use warnings;
use strict;
use parent 'Linux::Info::KernelRelease';
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_revision     => 'revision',
    get_architecture => 'architecture',
    get_distro_info  => 'distro_info',
};

our $VERSION = '2.17'; # VERSION

# ABSTRACT: a subclass of Linux::Info::KernelRelease specific to parse RockyLinux kernel information

sub _set_proc_ver_regex {
    my $self = shift;
    $self->{proc_regex} =
qr/^Linux\sversion\s(?<version>[\w\._-]+)\s\((?<compiled_by>[\w\.\-\@]+)\)\s\(gcc\sversion\s(?<gcc_version>[\d\.]+).*\)\s#1\s(?<type>\w+)\s(?<build_datetime>.*)/;
}


sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    # 4.18.0-513.5.1.el8_9.x86_64
    my $regex = qr/^\d+\.\d+\.\d+\-(\d+\.\d+\.\d+)\.(\w+\_\d)\.(\w+)$/;

    if ( $self->{version} =~ $regex ) {
        $self->{revision}     = $1;
        $self->{distro_info}  = $2;
        $self->{architecture} = $3;
    }
    else {
        confess( 'Failed to match "' . $self->{version} . "\" against $regex" );
    }

    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::KernelRelease::Rocky - a subclass of Linux::Info::KernelRelease specific to parse RockyLinux kernel information

=head1 VERSION

version 2.17

=head2 new

Overrides parent method, introducing the parsing of content from the
corresponding L<Linux::Info::KernelSource> C<get_version_signature> method
string returns.

=head2 get_revision

Return the kernel version.

=head2 get_distro_info

Returns the associated distribution information with the kernel.

=head2 get_architecture

Returns the processor architecture the kernel was compiled for.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
