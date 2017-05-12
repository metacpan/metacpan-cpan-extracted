package KiokuDB::Meta::Instance;
BEGIN {
  $KiokuDB::Meta::Instance::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Meta::Instance::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Moose::Meta::Instance level support for lazy loading.

use namespace::clean -except => 'meta';

around 'get_slot_value' => sub {
    my ( $next, $self, $instance, $slot, @args ) = @_;

    my $value = $self->$next($instance, $slot, @args);

    if ( ref($value) eq 'KiokuDB::Thunk' ) {
        $value = $value->vivify($instance);
    }

    return $value;
};

around 'inline_get_slot_value' => sub {
    my ( $next, $self, $instance_expr, $slot_expr, @args ) = @_;

    my $get_expr = $self->$next($instance_expr, $slot_expr, @args);

    return 'do {
        my $value = ' . $get_expr . ';
        if ( ref($value) eq "KiokuDB::Thunk" ) {
            $value = $value->vivify(' . $instance_expr . ');
        }
        $value;
    }'
};

sub inline_get_is_lvalue { 0 }

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Meta::Instance - Moose::Meta::Instance level support for lazy loading.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # use KiokuDB::Meta::Attribute::Lazy

=head1 DESCRIPTION

This role is applied to the meta instance class automatically by
L<KiokuDB::Class>. When it finds L<KiokuDB::Thunk> objects in the low level
attribute storage it will cause them to be loaded.

This allows your L<Moose::Meta::Attributes> to remain oblivious to the fact
that the value is deferred, making sure that all the type constraints, lazy
defaults, and various other L<Moose> features continue to work normally.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
