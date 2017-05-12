package Etherpad::API;

BEGIN {
    require Etherpad;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.2.12.1';
    @ISA         = qw(Exporter Etherpad);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

=head1 NAME

Etherpad::API - Access Etherpad Lite API easily

=head1 DESCRIPTION

[deprecated] Use L<Etherpad> instead.

This module inherits from L<Etherpad> without changing a thing for compatibility with applications that still use it.

This module will be removed after 18 July 2016. It will not get any update.

To use L<Etherpad>, just change Etherpad::API in your code to Etherpad. The methods are the same as the previous release of Etherpad::API, plus a few more.

=head1 INSTALL

    perl Makefile.PL
    make
    make test
    make install

If you are on a windows box you should use 'nmake' rather than 'make'.

=head1 BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Etherpad::API

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Etherpad-API
    bug-etherpad-api at rt.cpan.org

The latest source code can be browsed and fetched at:

    https://github.com/ldidry/etherpad-api
    git clone git://github.com/ldidry/etherpad-api.git

You can also look for information at:

    RT: CPAN's request tracker

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Etherpad-API
    AnnoCPAN: Annotated CPAN documentation

    http://annocpan.org/dist/Etherpad-API
    CPAN Ratings

    http://cpanratings.perl.org/d/Etherpad-API
    Search CPAN

    http://search.cpan.org/dist/Etherpad-API


=head1 AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    https://fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
