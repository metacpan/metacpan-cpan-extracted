#
# This file is part of File-ShareDir-PathClass
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package File::ShareDir::PathClass;
{
  $File::ShareDir::PathClass::VERSION = '1.112440';
}
# ABSTRACT: File::ShareDir returning Path::Class objects

use File::ShareDir ();
use Path::Class;
use Sub::Exporter -setup => {
    exports => [ @File::ShareDir::EXPORT_OK ],
    #groups => {    },
};


# wrap all file::sharedir relevant methods
foreach my $sub ( @File::ShareDir::EXPORT_OK ) {
    no strict 'refs';   ## no critic
    # create a new sub...
    *{ $sub } = sub {
        shift if defined($_[0]) && $_[0] eq __PACKAGE__;
        # ... that just pass through to file::sharedir method...
        my $result = "File::ShareDir::$sub"->(@_);
        # ... and wrap the result as a path::class object
        return $sub =~ /_file\z/ ? file( $result ) : dir( $result );
    };
}

1;


=pod

=head1 NAME

File::ShareDir::PathClass - File::ShareDir returning Path::Class objects

=head1 VERSION

version 1.112440

=head1 SYNOPSIS

    use File::ShareDir::PathClass '-all';
    my $dir = dist_dir("File-ShareDir-PathClass")
    # $dir is a Path::Class object now

    # - or -

    use File::ShareDir::PathClass;
    my $dir = File::ShareDir::PathClass->dist_dir("File-ShareDir-PathClass");
    # $dir is a Path::Class object now

=head1 DESCRIPTION

This module is just a wrapper around L<File::ShareDir> functions,
transforming their return value to L<Path::Class> objects. This allows
for easier usage of the value.

Refer to L<File::ShareDir> (section FUNCTIONS) for a list of which
functions are supported.

C<File::ShareDir::PathClass> supports both a procedural and a clas
methods API.

=head2 Procedural mode

All functions are exportable. Nothing is exported by default, though.
One has to list which function(s) she wants to import.

Some groups are defined for your convenience:

=over 4

=item * C<all> - all available functions.

=back

Note that this module is exporting subs via L<Sub::Exporter>, so groups
are available either as C<:group> or C<-group>. One can also play any
trick supported by L<Sub::Exporter>, check its documentation for further
information.

=head2 Class method mode

Otherwise, functions are available as class methods, called as:

    File::ShareDir::PathClass->method();

In this case, one doesn't need to import anything during module use-age.

=for Pod::Coverage dist_.*
    module_.*
    class_.*

=head1 SEE ALSO

Find other relevant information in L<File::ShareDir> and L<Path::Class>.

You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-ShareDir-PathClass>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-ShareDir-PathClass>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ShareDir-PathClass>

=item * Git repository

L<http://github.com/jquelin/file-sharedir-pathclass.git>.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

