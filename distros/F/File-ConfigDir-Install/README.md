## NAME

    File::ConfigDir::Install - allows installing configuration files

## SYNOPSIS

    use ExtUtils::MakeMaker;
    use File::ConfigDir::Install;

    install_config 'etc';

    WriteMakefile( ... );       # As you normaly would

    package MY;
    use File::ConfigDir::Install qw(:MY);

## DESCRIPTION

    File::ConfigDir::Install allows you to install configuration files from
    a distribution.

## AUTHOR

    Jens Rehsack, "<rehsack at cpan.org>"

## BUGS

    Please report any bugs or feature requests to
    C<bug-file-configdir-install at rt.cpan.org>, or through the web interface at
    L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ConfigDir-Install>.
    I will be notified, and then you'll automatically be notified of progress
    on your bug as I make changes.

## SUPPORT

    You can find documentation for this module with the perldoc command.

        perldoc File::ConfigDir::Install

    You can also look for information at:

    *   RT: CPAN's request tracker (report bugs here)

        <http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ConfigDir-Install>

    *   AnnoCPAN: Annotated CPAN documentation

        <http://annocpan.org/dist/File-ConfigDir-Install>

    *   CPAN Ratings

        <http://cpanratings.perl.org/d/File-ConfigDir-Install>

    *   Search CPAN

        <http://search.cpan.org/dist/File-ConfigDir-Install/>

## LICENSE AND COPYRIGHT

    Copyright 2014 Jens Rehsack.

    This program is free software; you can redistribute it and/or modify it
    under the terms of either: the GNU General Public License as published
    by the Free Software Foundation; or the Artistic License.

    See <http://dev.perl.org/licenses/> for more information.
