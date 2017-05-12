package Devel::PackagePath;
use Moose;
our $VERSION = 0.03;
use MooseX::Types::Path::Class qw(Dir);

has package => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has base => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => '.',
);

has directory => (
    isa        => Dir,
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        create => 'mkpath',
        path   => 'stringify',
    },
);

sub _build_directory {
    my @pkg_list = split '::', $_[0]->package;
    pop @pkg_list;    # pop off the file name
    Path::Class::Dir->new( $_[0]->base, @pkg_list );
}

has file_name => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_file_name {
    return ( split '::', $_[0]->package )[-1] . '.pm';
}

no Moose;
1;
__END__


=head1 NAME

Devel::PackagePath - Inspect and Manipulate a Path based on a Package Name

=head1 VERSION

This document describes Devel::PackagePath version 0.0.1

=head1 SYNOPSIS

    use Devel::PackagePath;

    my $path = Devel::PackagePath->new( package => 'MyApp::Base::Object', base => 'lib');
    $path->create; # creates lib/MyApp/Base
    
=head1 DESCRIPTION

Devel::PackagePath is a simple way to inspect and manipulate a path based on a
package name. I went looking for a way to do this when building a class
generator for another project and didn't find anything simple.

=head1 METHODS

=over 4

=item new

=over 4 

=item package PackageName

A package name to turn into a path.

=item base Str

A base directory, defaults to '.'.

=back

=item create

Create the path on the filesystem.

=item path

Get the path back as a string.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Devel::PackagePath requires no configuration files or environment variables.

=head1 DEPENDENCIES

Squirrel, MooseX::Types::Path::Class

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-devel-generatepackagepath@rt.cpan.org>, or through the web interface at
L<http:/ / rt . cpan . org > .

=head1 AUTHOR

Chris Prather  C<< <perigrin@cpan.org> >>
based on an IRC conversation with Matt Trout.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Prather C<< <perigrin@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
