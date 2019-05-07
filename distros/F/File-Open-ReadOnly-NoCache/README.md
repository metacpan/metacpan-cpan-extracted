# NAME

File::Open::ReadOnly::NoCache - Open a file and clear the cache afterward

# VERSION

Version 0.01

# SUBROUTINES/METHODS

## new

Open a file and flush the cache afterwards.
One use case is building a large database from smaller files that are
only read in once.
Once the file has been used it's a waste of RAM to keep it in cache.

    use File::Open::ReadOnly::NoCache;
    my $fh = File::Open::ReadOnly::NoCache->new('/etc/passwd');

## fd

Returns the file descriptor of the file

    my $fd = $fh->fd();
    my $line = <$fd>;

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to
`bug-file-Open::ReadOnly::NoCache at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Open::ReadOnly::NoCache](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Open::ReadOnly::NoCache).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Open::ReadOnly::NoCache

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Open::ReadOnly::NoCache](http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Open::ReadOnly::NoCache)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/File-Open::ReadOnly::NoCache](http://annocpan.org/dist/File-Open::ReadOnly::NoCache)

- CPAN Ratings

    [http://cpanratings.perl.org/d/File-Open::ReadOnly::NoCache](http://cpanratings.perl.org/d/File-Open::ReadOnly::NoCache)

- Search CPAN

    [http://search.cpan.org/dist/File-Open::ReadOnly::NoCache/](http://search.cpan.org/dist/File-Open::ReadOnly::NoCache/)

# LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

\* Personal single user, single computer use: GPL2
\* All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
