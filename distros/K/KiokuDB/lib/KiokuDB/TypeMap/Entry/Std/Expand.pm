package KiokuDB::TypeMap::Entry::Std::Expand;
BEGIN {
  $KiokuDB::TypeMap::Entry::Std::Expand::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::Std::Expand::VERSION = '0.57';
use Moose::Role;

no warnings 'recursion';

use namespace::clean -except => 'meta';

requires qw(
    compile_create
    compile_clear
    compile_expand_data
);

sub compile_expand {
    my ( $self, $class, @args ) = @_;

    my $create = $self->compile_create($class, @args);
    my $expand_data = $self->compile_expand_data($class, @args);

    return sub {
        my ( $linker, $entry, @args ) = @_;

        my ( $instance, @register_args ) = $linker->$create($entry, @args);

        # this is registered *before* any other value expansion, to allow circular refs
        $linker->register_object( $entry => $instance, @register_args );

        $linker->$expand_data($instance, $entry, @args);

        return $instance;
    };
}

sub compile_refresh {
    my ( $self, $class, @args ) = @_;

    my $clear = $self->compile_clear($class, @args);
    my $expand_data = $self->compile_expand_data($class, @args);

    return sub {
        my ( $linker, $instance, $entry, @args ) = @_;

        $linker->$clear($instance, $entry, @args);

        $linker->$expand_data($instance, $entry, @args);
    };
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::Std::Expand

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
