package HTML::Widget::Filter;

use warnings;
use strict;
use base 'Class::Accessor::Chained::Fast';

__PACKAGE__->mk_accessors(qw/names/);

=head1 NAME

HTML::Widget::Filter - Filter Base Class

=head1 SYNOPSIS

    my $f = $widget->filter( $type, @names );
    $c->names(@names);

=head1 DESCRIPTION

Filter Base Class.

=head1 METHODS

=head2 filter

Arguments: $value

Return Value: $filtered_value

FIlter given value.

=cut

sub filter { return $_[0] }

=head2 init

Arguments: $widget

Called once when process() gets called for the first time.

=cut

sub init { }

=head2 names

Arguments: @names

Return Value: @names

Contains names of params to filter.

=head2 prepare

Arguments: $widget

Called whenever process() gets called.

=cut

sub prepare { }

=head2 process

Arguments: \%params, \@uploads

=cut

sub process {
    my ( $self, $params ) = @_;
    my @names = scalar @{ $self->names } ? @{ $self->names } : keys %$params;
    for my $name (@names) {
        my $values = $params->{$name};
        if ( ref $values eq 'ARRAY' ) {
            $params->{$name} = [ map { $self->filter($_); } @$values ];
        }
        else {
            $params->{$name} = $self->filter($values);
        }
    }
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
