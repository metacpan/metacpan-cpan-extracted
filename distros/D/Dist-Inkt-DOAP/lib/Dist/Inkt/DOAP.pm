use 5.010001;
use strict;
use warnings;

package Dist::Inkt::DOAP;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022';

1;

__END__

=pod

=encoding utf-8

=for stopwords tarball

=head1 NAME

Dist::Inkt::DOAP - various DOAP-related roles for Dist::Inkt

=head1 DESCRIPTION

Dist::Inkt is a framework for writing your own distribution builder.
It's a simple class that makes an empty directory, creates a MANIFEST
file listing the contents of the directory, and then compresses it
into a tarball.

Which seems pretty useless. However, it provides tonnes of hooks that
can be used by roles applied to the class. This distribution provides a
collection of roles that help you populate the distribution's metadata
(META.json, Changes, etc) from DOAP.

=head2 The Straight DOAP

So what is DOAP? This explanation is lifted from
L<Wikipedia|http://en.wikipedia.org/wiki/DOAP>.

I<< DOAP (Description of a Project) is an RDF Schema and XML vocabulary
to describe software projects, in particular free and open source
software. >>

I<< It was created and initially developed by Edd Dumbill to convey
semantic information associated with open source software projects. >>

I<< It is currently used in the Mozilla Foundation's project page and
in several other software repositories, notably the Python Package
Index. >>

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt-DOAP>.

=head1 SEE ALSO

L<Dist::Inkt>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

