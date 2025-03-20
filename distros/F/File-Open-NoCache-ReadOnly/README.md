# NAME

File::Open::NoCache::ReadOnly - Open a file and flush from memory on closing

# VERSION

Version 0.05

# DESCRIPTION

The `File::Open::NoCache::ReadOnly` module is designed to open files for sequential,
read-only access while optimizing memory usage by minimizing filesystem caching.
This is particularly useful for processing large data files that only need to be read once,
such as during database population or bulk data imports.
The `new` method facilitates opening files with options to specify file paths directly or via a parameter hash,
and it can enforce fatal errors on failure if desired.
The module uses [IO::AIO::fadvise](https://metacpan.org/pod/IO%3A%3AAIO%3A%3Afadvise) to signal the operating system to avoid retaining file data in cache,
improving memory efficiency.
The module provides a `fd` method to retrieve the file descriptor and a `close` method for explicit resource cleanup.
The destructor also ensures file closure when the object is destroyed,
with safeguards to prevent redundant closure attempts.

# SUBROUTINES/METHODS

## new

Open a file that will be read once sequentially and not again,
optimising the filesystem cache accordingly.
One use case is building a large database from smaller files that are
only read in once,
once the file has been used it's a waste of RAM to keep it in cache.

    use File::Open::NoCache::ReadOnly;
    my $fh = File::Open::NoCache::ReadOnly->new('/etc/passwd');
    my $fh2 = File::Open::NoCache::ReadOnly->new(filename => '/etc/group', fatal => 1);

## fd

Returns the file descriptor of the file

    my $fd = $fh->fd();
    my $line = <$fd>;

## close

Shouldn't be needed as close happens automatically when the variable goes out of scope.
However Perl isn't as good at reaping as it'd have you believe, so this is here to force it when you
know you're finished with the object.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to
`bug-file-Open-NoCache-ReadOnly at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Open-NoCache-ReadOnly](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Open-NoCache-ReadOnly).
I will be notified, and then you'll
automatically be notified of the progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc File::Open::NoCache::ReadOnly

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Open-NoCache-ReadOnly](http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Open-NoCache-ReadOnly)

- Search CPAN

    [http://search.cpan.org/dist/File-Open-NoCache-ReadOnly/](http://search.cpan.org/dist/File-Open-NoCache-ReadOnly/)

# LICENSE AND COPYRIGHT

Copyright 2019-2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
