use strict;
use warnings;

package Gentoo::MetaEbuild::Spec::MiniSpec;
BEGIN {
  $Gentoo::MetaEbuild::Spec::MiniSpec::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::MetaEbuild::Spec::MiniSpec::VERSION = '0.1.1';
}

# ABSTRACT: Minimal Conforming spec for MetaEbuilds.


use Moose;
extends 'Gentoo::MetaEbuild::Spec::Base';


__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Gentoo::MetaEbuild::Spec::MiniSpec - Minimal Conforming spec for MetaEbuilds.

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    use Gentoo::MetaEbuild::Spec::MiniSpec;
    if( Gentoo::MetaEbuild::Spec::MiniSpec->check( json_decode( scalar slurp( $file ) ) ) ){
        print "$file is metaspec compliant\n";
    }

=head1 DESCRIPTION

Most the work for this module is performed by the parent class L<< C<::Spec::Base>|Gentoo::MetaEbuild::Spec::Base >>.

Everything outside that is governed by the .json files shipped in this distributions "Share" directory.

=head1 SCHEMA

    $root = {
        SCHEME => $scheme_spec                   # required
        ...                                      # anything.
    }

    $scheme_spec = {
        min_version => "Minimum Version String", # required
        standard    => "Schema Standard",        # required
        generator   => $generator_spec           # optional
    }

    $generator_spec = {
        type       => "Type String",             # required
        author     => $generator_auth_spec       # optional
        module     => $generator_modu_spec       # optional
    }

    $generator_auth_spec = {
        name      => "Authors name"              # required
        email     => "Authors contact Email"     # required
    }

    $generator_modu_spec = {
        name      => "Module::Name",             # required
        version   => "Module Version String",    # required
    }

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
