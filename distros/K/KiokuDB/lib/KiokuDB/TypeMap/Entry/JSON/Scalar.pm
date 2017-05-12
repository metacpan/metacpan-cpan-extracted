package KiokuDB::TypeMap::Entry::JSON::Scalar;
BEGIN {
  $KiokuDB::TypeMap::Entry::JSON::Scalar::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::JSON::Scalar::VERSION = '0.57';
use Moose;

no warnings 'recursion';

use namespace::clean -except => 'meta';

with qw(KiokuDB::TypeMap::Entry::Std);

sub compile_collapse_body {
    my ( $self, $class ) = @_;

    return sub {
        my ( $collapser, %args ) = @_;

        my $scalar = $args{object};

        my $data = $collapser->visit($$scalar);

        $collapser->make_entry(
            %args,
            class => "SCALAR",
            data  => $data,
        );
    };
}

sub compile_expand {
    my ( $self, $reftype ) = @_;

    sub {
        my ( $linker, $entry ) = @_;

        my $scalar;

        $linker->inflate_data($entry->data, \$scalar);

        return \$scalar;
    }
}

sub compile_refresh {
    my ( $self, $class, @args ) = @_;

    return sub {
        my ( $linker, $scalar, $entry ) = @_;

        $linker->inflate_data($entry->data, $scalar );

        return $scalar;
    };
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::JSON::Scalar

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
