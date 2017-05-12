package Magpie::Dispatcher::RequestParam;
$Magpie::Dispatcher::RequestParam::VERSION = '1.163200';
use MooseX::Role::Parameterized;

# ABSTRACT: Request Parameter Dispatcher

parameter state_param => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'appstate',
);

role {
    my $p = shift;

    has 'state_param' => (
        is          => 'ro',
        isa         => 'Str',
        default     => $p->state_param,
    );
};

sub load_queue {
    my $self = shift;
    my @events = ();

    if ($self->can('init')) {
        push @events, 'init';
    }

    my $state = $self->request->param( $self->state_param );

    if ($state and $self->can($state)) {
        push @events, $state;
    }
    else {
        push(@events, 'default') if $self->can('default');
    }

    return @events;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Magpie::Dispatcher::RequestParam - Request Parameter Dispatcher

=head1 VERSION

version 1.163200

=head1 AUTHORS

=over 4

=item *

Kip Hampton <kip.hampton@tamarou.com>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Tamarou, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
