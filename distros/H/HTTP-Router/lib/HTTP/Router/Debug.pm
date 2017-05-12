package HTTP::Router::Debug;

use strict;
use warnings;
use Text::SimpleTable;

our @EXPORT = qw(show_table routing_table);

sub import {
    require HTTP::Router;
    no strict 'refs';
    for my $name (@EXPORT) {
        *{"HTTP::Router::$name"} = \&{$name};
    }
}

sub show_table {
    my $table = $_[0]->routing_table->draw;
    print "$table\n";
}

sub routing_table {
    my $self = shift;

    my $table = Text::SimpleTable->new(
        [qw(35 path)      ],
        [qw(10 method)    ],
        [qw(10 controller)],
        [qw(10 action)    ],
    );

    for my $route ($self->routes) {
        my $method = $route->conditions->{method};
        $method = [ $method ] unless ref $method;

        $table->row(
            $route->path,
            join(',', @$method),
            $route->params->{controller},
            $route->params->{action}
        );
    }

    return $table;
}

1;

=head1 NAME

HTTP::Router::Debug

=head1 SYNOPSIS

    use HTTP::Router;
    use HTTP::Router::Debug;

    my $router = HTTP::Router->define(...);

    print $router->routing_table->draw;
    # or
    $router->show_table;

=head1 METHODS

=head2 routing_table

Returns a Text::SimpleTable object for routing information.

=head2 show_table

Constructs and Prints a table for routing information.

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Router>, L<Text::SimpleTable>

=cut
