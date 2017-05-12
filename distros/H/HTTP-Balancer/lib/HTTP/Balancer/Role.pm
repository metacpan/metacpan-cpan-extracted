package HTTP::Balancer::Role;

=head1 NAME

HTTP::Balancer::Role - base of all roles in HTTP::Balancer

=head1 SYNOPSIS

    package HTTP::Balancer::Role::Any;
    use Modern::Perl;
    use Moose::Role;
    with qw(HTTP::Balancer::Role);

    # your code goes here

    no Moose::Role;

=cut

use Modern::Perl;

use Moose::Role;

=head2 model($name)

given the last name of a model, returns the whole name of the model, and requires this model.

=cut

sub model {
    my ($self, $name) = @_;
    $name = ucfirst($name);
    my $model = "HTTP::Balancer::Model::$name";
    eval qq{use $model};
    die $@ if $@;
    return $model;
}

=head2 actor($name)

=cut

sub actor {
    my ($self, $name) = @_;
    $name = ucfirst($name);
    my $actor = "HTTP::Balancer::Actor::$name";
    eval qq{use $actor};
    die $@ if $@;
    return $actor;
}

=head2 config()

return the singleton of the configuration.

=cut

use HTTP::Balancer::Config;
sub config {
    return HTTP::Balancer::Config->instance;
}

no Moose::Role;

1;

=pod

=head1 NAME

HTTP::Balancer::Role - base of all roles of HTTP::Balancer

=head1 SYNOPSIS

    package HTTP::Balancer::Role::Foo;
    use Moose::Role;
    with qw( HTTP::Balancer::Role );

=cut
