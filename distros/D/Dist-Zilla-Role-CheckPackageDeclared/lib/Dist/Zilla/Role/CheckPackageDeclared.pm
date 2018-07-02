package Dist::Zilla::Role::CheckPackageDeclared;

our $DATE = '2018-06-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Moose::Role;
with 'Dist::Zilla::Role::ModuleMetadata';

use namespace::autoclean;

my $cache; # hash. key=package name, value = first file that declares it

sub is_package_declared {
    my ($self, $package) = @_;

    unless ($cache) {
        $cache = {};
        for my $file (@{ $self->zilla->find_files(':InstallModules') }) {
            $self->log_fatal([ 'Could not decode %s: %s', $file->name, $file->added_by ])
                if $file->can('encoding') and $file->encoding eq 'bytes';
            my @packages = $self->module_metadata_for_file($file)->packages_inside;
            $cache->{$_} //= $file->name for @packages;
        }
    }

    exists $cache->{$package} ? 1:0;
}

1;
# ABSTRACT: Role to check if a package is provided by your distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::CheckPackageDeclared - Role to check if a package is provided by your distribution

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Role::CheckPackageDeclared (from Perl distribution Dist-Zilla-Role-CheckPackageDeclared), released on 2018-06-26.

=head1 METHODS

=head2 is_package_declared

Usage: my $declared = $obj->is_package_declared($package) => bool

Return true when C<$package> is declared by one of the modules in the
distribution. L<Module::Metadata> is used to extract declared packages in a
file.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Role-CheckPackageDeclared>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Role-CheckPackageDeclared>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-CheckPackageDeclared>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Metadata>

L<Dist::Zilla::Plugin::CheckSelfDependency>

L<Dist::Zilla::Plugin::RemoveSelfDependency>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
