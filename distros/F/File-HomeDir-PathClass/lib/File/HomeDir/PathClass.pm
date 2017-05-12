#
# This file is part of File-HomeDir-PathClass
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package File::HomeDir::PathClass;
BEGIN {
  $File::HomeDir::PathClass::VERSION = '1.112060';
}
# ABSTRACT: File::HomeDir returning Path::Class objects

use File::HomeDir 0.93 ();
use Path::Class;
use Sub::Exporter -setup => {
    exports => [ @File::HomeDir::EXPORT_OK ],
    #groups => {    },
};


# wrap all file::homedir relevant methods
foreach my $sub ( @File::HomeDir::EXPORT_OK ) {
    no strict 'refs';   ## no critic
    # create a new sub...
    *{ $sub } = sub {
        shift if defined($_[0]) && $_[0] eq __PACKAGE__;
        # ... that just pass through to file::homedir method...
        my $result = *{"File::HomeDir::$sub"}->(@_);
        # ... and wrap the result as a path::class object
        return dir( $result );
    };
}

1;


=pod

=head1 NAME

File::HomeDir::PathClass - File::HomeDir returning Path::Class objects

=head1 VERSION

version 1.112060

=head1 SYNOPSIS

    use File::HomeDir::PathClass '-all';
    my $home = home();
    # $home is a Path::Class object now

    # - or -

    use File::HomeDir::PathClass;
    my $home = File::HomeDir::PathClass->home;
    # $home is a Path::Class object now

=head1 DESCRIPTION

This module is just a wrapper around L<File::HomeDir> methods,
transforming their return value to L<Path::Class> objects. This allows
for easier usage of the value.

Refer to L<File::HomeDir#METHODS> for a list of which functions are
supported.

C<File::HomeDir::PathClass> supports both original L<File::HomeDir> interfaces.

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

    File::HomeDir::PathClass->method();

In this case, one doesn't need to import anything during module use-age.

=for Pod::Coverage home my_.* users_.*

=head1 SEE ALSO

Find other relevant information in L<File::HomeDir> and L<Path::Class>.

You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-HomeDir-PathClass>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-HomeDir-PathClass>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-HomeDir-PathClass>

=item * Git repository

L<http://github.com/jquelin/file-homedir-pathclass.git>.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

