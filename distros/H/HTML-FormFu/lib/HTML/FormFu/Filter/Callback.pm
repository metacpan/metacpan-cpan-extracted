use strict;

package HTML::FormFu::Filter::Callback;
$HTML::FormFu::Filter::Callback::VERSION = '2.07';
# ABSTRACT: filter with custom subroutine

use Moose;
use MooseX::Attribute::Chained;
extends 'HTML::FormFu::Filter';

has callback => ( is => 'rw', traits => ['Chained'] );

sub filter {
    my ( $self, $value, $params ) = @_;

    my $callback = $self->callback || sub {$value};

    ## no critic (ProhibitNoStrict);
    no strict 'refs';

    return $callback->( $value, $params );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Filter::Callback - filter with custom subroutine

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    $field->filter({
        type     => 'Callback',
        callback => \&my_filter,
    });

    ---
    elements:
      - type: Text
        name: foo
        filters:
          - type: Callback
            callback: "main::my_filter"

    sub my_filter {
        my ($value) = @_;

        # do something to $value

        return $value;
    }

=head1 DESCRIPTION

Filter using a user-provided subroutine.

=head1 METHODS

=head2 callback

Arguments: \&code-reference

Arguments: "subroutine-name"

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

Based on the original source code of L<HTML::Widget::Filter::Callback>, by
Lyo Kato, C<lyo.kato@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
