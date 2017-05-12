package HTML::Widget::Filter::Callback;

use warnings;
use strict;
use base 'HTML::Widget::Filter';

__PACKAGE__->mk_accessors(qw/callback/);

*cb = \&callback;

=head1 NAME

HTML::Widget::Filter::Callback - Lower Case Filter

=head1 SYNOPSIS

    my $f = $widget->filter( 'Callback', 'foo' )->callback(sub {
        my $value=shift;
        $value =~ s/before/after/g;
        return $value;
    });

=head1 DESCRIPTION

Callback Filter.

=head1 METHODS

=head1 callback

Argument: \&callback

Define the callback to be used for filter.

L</cb> is an alias for L</callback>.

=head2 filter

=cut

sub filter {
    my ( $self, $value ) = @_;
    my $callback = $self->callback || sub { $_[0] };
    return $callback->($value);
}

=head1 AUTHOR

Lyo Kato, C<lyo.kato@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
