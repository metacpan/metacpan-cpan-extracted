# SYNOPSIS

    use File::ArchivableFormats;

    my $archive = File::ArchivableFormats->new();

    open my $fh, '<', 'path/to/file';

    my $result_fh = $archive->identify_from_fh($fh);

    my $result_path = $archive->identify_from_path('/path/to/file');

# DESCRIPTION

TODO: Add clear description

# ATTRIBUTES

## magic

The [File::LibMagic](https://metacpan.org/pod/File::LibMagic) accessor

# METHODS

## parse\_extension

Parses the filename and returns the extension. Uses
["fileparse" in File::Basename](https://metacpan.org/pod/File::Basename#fileparse)

## identify\_from\_fh

Identify the file from a file handle. Please note that this does not
work with a [File::Temp](https://metacpan.org/pod/File::Temp) filehandle.

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

## identify\_from\_path

Identify the file from path/filename.

## identify\_from\_mimetype

Identify based on the mimetype

## identify\_via\_libexif

Identify mimetype via libexif.
You will need to have [Archive::Zip](https://metacpan.org/pod/Archive::Zip) installed for MS Office documents

## installed\_drivers

Returns an array with all the installed plugins.

# SEE ALSO

- IANA

    [http://www.iana.org/assignments/media-types/media-types.xhtml](http://www.iana.org/assignments/media-types/media-types.xhtml)

    [http://www.iana.org/assignments/media-types/application.csv](http://www.iana.org/assignments/media-types/application.csv)

- [File::LibMagic](https://metacpan.org/pod/File::LibMagic)
