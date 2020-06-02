package File::ArchivableFormats;
use Moose;
use namespace::autoclean;

# ABSTRACT: Be able to select archivable formats

use File::Basename qw(fileparse);
use File::MimeInfo::Magic;
use List::Util qw(first);
use Module::Pluggable::Object;
use Moose::Util::TypeConstraints;

our $VERSION = '1.8';

subtype 'PluginRole'
    => as 'Object'
    => where sub { $_->does('File::ArchivableFormats::Plugin') };

has driver => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_driver',
);

has _driver => (
    is      => 'ro',
    isa     => 'PluginRole',
    builder => '_build_driver',
    lazy    => 1,
);

sub _build_driver {
    my $self = shift;
    return first { $_->name eq $self->driver } $self->installed_drivers;
}

my @DRIVERS;

sub installed_drivers {
    if (!@DRIVERS) {
        my $finder = Module::Pluggable::Object->new(
            search_path => 'File::ArchivableFormats::Plugin',
            instantiate => 'new',
        );
        @DRIVERS = $finder->plugins;
    }
    return @DRIVERS;
}

sub identify_from_fh {
    my ($self, $fh) = @_;

    if (blessed($fh) && $fh->isa('Path::Tiny')) {
        # Path::Tiny doesn't have a seek and it doesn't play well with .docx as
        # it than identifies as a zip file. See t/200-dans.t for the test.
        return $self->identify_from_fh("$fh");
    }

    my $info = { mime_type => mimetype($fh)} ;
    return $self->identify_from_mimetype($info->{mime_type});
}

sub identify_from_path {
    my ($self, $path) = @_;
    return $self->identify_from_fh($path);
}

sub parse_extension {
    my ($self, $filename) = @_;

    my (undef, undef, $ext) = fileparse($filename, '\.[^\.]*');
    return lc($ext);
}

sub identify_from_mimetype {
    my ($self, $mimetype) = @_;

    my %rv = ( mime_type => $mimetype );

    if ($self->has_driver) {
        $rv{ $self->driver } = $self->_driver_mimetype($self->_driver, $mimetype);
    }
    else {
        for my $driver ($self->installed_drivers) {
            $rv{ $driver->name } = $self->_driver_mimetype($driver, $mimetype);
        }
    }

    return \%rv;
}

sub _driver_mimetype {
    my ($self, $driver, $mimetype) = @_;
    return {
        archivable => $driver->is_archivable($mimetype) || 0,
        %{ $driver->allowed_extensions($mimetype) },
    };

}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ArchivableFormats - Be able to select archivable formats

=head1 VERSION

version 1.8

=head1 SYNOPSIS

    use File::ArchivableFormats;

    my $archive = File::ArchivableFormats->new();

    open my $fh, '<', 'path/to/file';

    my $result_fh = $archive->identify_from_fh($fh);

    my $result_path = $archive->identify_from_path('/path/to/file');

=head1 DESCRIPTION

This module identifies filetypes and tells you whether they are considered
archivable by various institutes. This is done via a plugin mechanism.

=head1 ATTRIBUTES

=head1 METHODS

=head2 parse_extension

Parses the filename and returns the extension. Uses
L<File::Basename/fileparse>

=head2 identify_from_fh

Identify the file from a file handle. Please note that this does not
work with a L<File::Temp> filehandle.

Returns a data structure like this:

    {
        # DANS is the Prefered format list
        'DANS' => {
            # Types tell  you something about why something is on the
            # preferred format list
            'types' => [
                'Plain text (Unicode)',
                'Plain text (Non-Unicode)',
                'Statistical data (data (.csv) + setup)',
                'Raspter GIS (ASCII GRID)',
                'Raspter GIS (ASCII GRID)'
            ],
            # The extensions by which belongs to the mime type/file
            'allowed_extensions' => ['.asc', '.txt'],
            # Boolean which tells you if the file is archivable and
            # therfore preferred.
            'archivable'         => 1
        },
        'mime_type' => 'text/plain'
    };

=head2 identify_from_path

Identify the file from path/filename.

=head2 identify_from_mimetype

Identify based on the mimetype

=head2 installed_drivers

Returns an array with all the installed plugins.

=head1 SEE ALSO

=over

=item L<File::MimeInfo::Magic>

=item IANA

L<http://www.iana.org/assignments/media-types/media-types.xhtml>

L<http://www.iana.org/assignments/media-types/application.csv>

=back

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mintlab BV.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
