package Filesys::Btrfs;

use 5.10.1;
use strict;
use warnings;
use Carp;
use IPC::Cmd;
use Path::Class qw();

=head1 NAME

Filesys::Btrfs - Simple wrapper around Linux L<btrfs> util.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Simple wrapper around Linux C<btrfs> util. Btrfs util is used to
manage btrfs filesystem: manage snapshots, subvolumes and etc.  Only
subset of C<btrfs> options is supported (hopefuly it is useful
subset).

For more information about C<btrfs> util please see L<btrfs> manpage.

B<WARNING> This module is hightly experimental (as btrfs itself). API
can change in the future.

Example:

    use Filesys::Btrfs;

    my $btrfs = Filesys::Btrfs->new($mount_point);
    $btrfs->subvolume_create('subvolume');
    ...

Note: all methods croak if error occures.

=head1 CONSTANTS

=head2 Filesys::Btrfs::BTRFS_CMD

Default path to look for btrfs program: C</sbin/btrfs>.

=cut

use constant BTRFS_CMD => '/sbin/btrfs';

=head1 METHODS

=head2 Filesys::Btrfs->new($mount_point, %options);

Create new C<Filesys::Btrfs> object.

    my $btrfs = Filesys::Btrfs->new('/mnt/disk');

=over

=item $mount_point

Mount point of C<btrfs> filesystem. Filesystem has to be mounted before
this module can be used. All methods of C<Filesys::Btrfs> object operate
with paths absolute or relative to mount point.

=item %options

Additional options. Currently only one option is supported:
C<btrfs_cmd> - specifies different path to btrfs util.

=back

=cut

sub new {
    my ($class, $mount_point) = (shift, shift);
    croak('Mount point is required') unless($mount_point);
    my %options;
    if(@_ % 2 == 0) {
        %options = @_;
    } else {
        croak('Unexpected options: '.join(', ', @_)) if(@_);
    }
    my $btrfs_cmd = delete($options{btrfs_cmd});
    croak('Unexpected options: '.join(', ', keys(%options))) if(%options);

    my $self = bless({
        btrfs_cmd => $btrfs_cmd ? $btrfs_cmd : BTRFS_CMD(),
        mount_point => Path::Class::dir($mount_point)
       }, $class);

    return $self;
}

=head2 $btrfs->btrfs_cmd();

Returns path to C<btrfs> util being used.

=cut

sub btrfs_cmd {
    return $_[0]->{btrfs_cmd};
}

=head2 $btrfs->mount_point();

Returns mount point being used.

=cut

sub mount_point {
    return $_[0]->{mount_point};
}

=head2 $btrfs->version();

Returns version of btrfs util being used.

=cut

sub version {
    my ($self) = @_;
    #look at the last line of help output
    my $stdout = $self->_run('help');
    my ($version) = ($stdout->[-1] =~ /^Btrfs Btrfs v([0-9\.]+)$/m);
    unless($version) {
        warn('Cannot determine btrfs version');
    }
    return $version;
}

=head2 $btrfs->subvolume_list($dir);

Get list of all subvolumes. Returns hashref of (subvolume_name => id).

=over

=item $dir

If C<$dir> is specified then only subvolumes located in this directory
are returned.

=back

=cut

sub subvolume_list {
    my ($self, $dir) = @_;
    $dir = $self->_absolute_path($dir) if($dir);
    my $stdout = $self->_run('subvolume', 'list', $self->{mount_point});
    my %subvolumes;
    foreach (@$stdout) {
        if(my ($id, $path) = /^ID\s+(\d+)\s+.*\s+path\s+(.+)$/) {
            my $absolute_path = $self->_absolute_path($path);
            if(!$dir
                   || ($absolute_path ne $dir && $dir->subsumes($absolute_path))) {
                $subvolumes{$path} = $id;
            }
        }
        else {
            warn('Cannot parse subvolume list result line: '.$_);
        }
    }
    return \%subvolumes;
}

=head2 $btrfs->subvolume_create($dir);

Create new subvolume in C<$dir>.

=cut

sub subvolume_create {
    my ($self, $dir) = @_;
    croak('Dir is required') unless($dir);
    $self->_run('subvolume', 'create', $self->_absolute_path($dir));
}

=head2 $btrfs->subvolume_delete($dir);

Delete subvolume in C<$dir>.

=cut

sub subvolume_delete {
    my ($self, $dir) = @_;
    croak('Dir is required') unless($dir);
    $self->_run('subvolume', 'delete', $self->_absolute_path($dir));
}

=head2 $btrfs->subvolume_set_default($id);

Set subvolume with C<$id> to be mounted by default.

=cut

sub subvolume_set_default {
    my ($self, $id) = @_;
    croak('Subvolume id is required') unless(defined($id));
    $self->_run('subvolume', 'set-default', $id, $self->{mount_point});
}

=head2 $btrfs->filesystem_sync();

Force a sync on filesystem.

=cut

sub filesystem_sync {
    my ($self) = @_;
    $self->_run('filesystem', 'sync', $self->{mount_point});
}

=head2 $btrfs->filesystem_balance();

Balance the chunks across the device.

=cut

sub filesystem_balance {
    my ($self) = @_;
    $self->_run('filesystem', 'balance', $self->{mount_point});
}

# Private method. Calls btrfs util and performs simple processing.
# Returns arrayref with command output split by newlines.
sub _run {
    my $self = shift;
    my @cmd = ($self->{btrfs_cmd}, @_);
    my ($success, $error_code, undef, $stdout, $stderr)
        = IPC::Cmd::run(command => \@cmd, verbose => 0);
    if($success) {
        if(@$stderr) {
            warn('Btrfs reported warnings to stderr: '.join('', @$stderr));
        }
        return [split('\n', join('', @$stdout))];
    }
    else {
        croak("Error running btrfs command ($error_code): ".join('', @$stderr));
    }
}

#Private method. Makes path absolute using mount point as base dir.
sub _absolute_path {
    my ($self, $path) = @_;
    return Path::Class::dir($path)->absolute($self->{mount_point});
}

=head1 AUTHOR

Nikolay Martynov, C<< <kolya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-filesys-btrfs at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filesys-Btrfs>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Filesys::Btrfs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filesys-Btrfs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Filesys-Btrfs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Filesys-Btrfs>

=item * Search CPAN

L<http://search.cpan.org/dist/Filesys-Btrfs/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Nikolay Martynov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Filesys::Btrfs
