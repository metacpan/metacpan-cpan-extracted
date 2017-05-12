package File::Tempdir;

use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Path;

our $VERSION = '0.02';

=head1 NAME

File::Tempdir

=head1 SYNOPSYS

    use File::Tempdir;

    {
        my $tmpdir = File::Tempdir->new()
        my $dir = $tmpdir->name;
    }
    # the directory has been trashed
    my $adir = 'any directory';
    {
        my $tmpdir = File::Tempdir->new($dir)
        my $dir = $tmpdir->name;
    }
    # the directory has not been trashed

=head1 DESCRIPTION

This module provide an object interface to tempdir() from L<File::Temp>.
This allow to destroy the temporary directory as soon you don't need it 
anymore using the magic DESTROY() function automatically call be perl
when the object is no longer reference.

If a value is passed to at object creation, it become only a container
allowing to keep same code in your function.

=head1 FUNCTIONS

=head2 new(@options)

if @options is only one defined value, the directory is simply
retain in memory and will not been trashed.

Otherwise, @options are same than tempdir() from L<File::Temp>.
Refer to L<File::Temp> documentation to have options list.
In this case, the directory will be trashed.

=cut

sub new {
    my ($class, @args) = @_;
    if (@args == 1 && defined($args[0])) {
        # Not a tempdir, simply to have same interface in code
        return bless({ dir => $args[0] }, $class);
    } else {
        my $dir = tempdir(@args) or return undef;
        return bless({ tmpdir => $dir }, $class);
    }
}

sub DESTROY {
    my ($self) = @_;
    if ($self->{tmpdir}) {
        rmtree($self->{tmpdir}, 0, 0);
    }
}

=head2 name

Return the name of the directory handle by the object.

=cut

sub name {
    defined($_[0]->{tmpdir}) ? $_[0]->{tmpdir} : $_[0]->{dir}
}

1;

__END__

=head1 SEE ALSO

In L<File::Temp/"tempdir">
L<File::Path>
L<Directory::Scratch>

=head1 AUTHOR

Olivier Thauvin <nanardon@nanardon.zarb.org>

=head1 URL

http://nanardon.zarb.org/darcsweb/darcsweb.cgi?r=Tempdir

darcs get http://nanardon.zarb.org/darcs/Tempdir

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
