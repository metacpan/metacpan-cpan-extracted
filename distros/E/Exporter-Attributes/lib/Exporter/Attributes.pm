use strict;
use warnings FATAL => 'all';

package Exporter::Attributes;

# ABSTRACT: Export symbols by attributes

use Exporter 5.72 ();
use Attribute::Universal 0.003;
use Carp qw(croak);

our $VERSION = '0.002';    # VERSION

our @EXPORT_OK = qw(import);

my $symbols = {};

my %lists = (
    Exportable => 'export_ok',
    Exported   => 'export',
);

my %sigil = (
    SCALAR => '$',
    ARRAY  => '@',
    HASH   => '%',
    CODE   => '&',
);

sub add {
    my ( $package, $list, $name, @tags ) = @_;
    $symbols->{$package} //= {
        export      => [],
        export_ok   => [],
        export_tags => {},
    };
    push @{ $symbols->{$package}->{$list} } => $name;
    return unless @tags;
    foreach my $tag (@tags) {
        push @{ $symbols->{$package}->{export_tags}->{$tag} } => $name;
    }
}

use namespace::clean;

sub ATTRIBUTE {
    my $attr = Attribute::Universal::to_hash(@_);
    croak(
"lexical symbols are not exportable, in $attr->{file} at line $attr->{line}"
    ) unless ref $attr->{symbol};
    my $sigil = $sigil{ $attr->{type} };
    my $list  = $lists{ $attr->{attribute} };
    my @tags  = map { split /[\s,]+/ } grep defined, @{ $attr->{content} };
    add( $attr->{package}, $list, $sigil . $attr->{label}, @tags );
}

sub import {
    my $class  = $_[0];
    my $caller = scalar caller;

    if ( $class eq __PACKAGE__ ) {
        goto &_my_import;
    }
    else {
        goto &_your_import;
    }
}

sub _my_import {
    my $class  = $_[0];
    my $caller = scalar caller;

    Attribute::Universal->import_into(
        $caller,
        Exportable => 'ANY,BEGIN',
        Exported   => 'ANY,BEGIN',
    );
    goto &Exporter::import;
}

sub _your_import {
    my $class  = $_[0];
    my $caller = scalar caller;

    # get export symbols or just return
    my $_symbols = $symbols->{$class} // return;

    # build :all export tag by concat @EXPORT and @EXPORT_OK
    $_symbols->{export_tags}->{all} =
      [ @{ $_symbols->{export} }, @{ $_symbols->{export_ok} }, ];

# this is a quite easy way to say "our @Class::EXPORT", which is normally not possible
# we are rewriting the symbol table, dont let strict concern about it!
    no strict 'refs';    ## no critic
    *{"${class}::EXPORT"}      = $_symbols->{export};
    *{"${class}::EXPORT_OK"}   = $_symbols->{export_ok};
    *{"${class}::EXPORT_TAGS"} = $_symbols->{export_tags};

    # and finally let import the symbol into the caller namespace.
    goto &Exporter::import;
}

1;

__END__

=pod

=head1 NAME

Exporter::Attributes - Export symbols by attributes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package FooBar;

    use Exporter::Attributes qw(import);

    sub Foo : Exported;
    sub Bar : Exportable;

    our $Cat : Exportable(vars);
    our $Dog : Exportable(vars);

    package main;

    use FooBar;           # import &Foo
    use FooBar qw(Bar);   # import &Bar
    use FooBar qw(:vars); # import $Cat and $Dog
    use FooBar qw(:all);  # import &Foo, &Bar, $Cat and $Dog

=head1 DESCRIPTION

This module is inspired by L<Exporter::Simple>, but this module is broken since a long time. The new implementation uses a smarter way, by rewriting the caller's symbol table and then goto L<Exporter/import>.

The list of the export symbols are captured with L<attributes>. There are two attributes:

=over 4

=item * I<Exported>

Which adds the name of the symbol to C<@EXPORT>

=item * I<Exportable>

Which adds the name of the symbol to C<EXPORT_OK>

=back

The attributes accepts a list of tags as argument.

=head1 FUNCTIONS

=head2 import

This is an ambivalent function. When called as C<< Export::Attributes->import >> it just imports this L</import> function into the namespace of the caller.

When called from any other class, it rewrites C<@EXPORT>, C<@EXPORT_OK> and C<@EXPORT_TAGS> and let the rest of the work do by L<Exporter>.

For overloading the I<import> function, use this template:

    sub import {
        # do some stuff, let @_ untouched
        goto &Exporter::Attributes::import;
    }

=for Pod::Coverage ATTRIBUTE

=head1 TESTS

The tests in this distribution are copied from L<Exporter::Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libexporter-attributes-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

David Zurborg <zurborg@cpan.org>

=item *

Marcel Gruenauer <marcel@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
