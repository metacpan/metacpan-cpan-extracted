package HTTP::Balancer::Actor;
use Modern::Perl;
use Moose;
use Path::Tiny;

with qw(HTTP::Balancer::Role);

use Text::Xslate;

our @PATH = qw(
    /usr/local/bin
    /usr/local/sbin
    /usr/bin
    /usr/sbin
);

sub start {
    my $class = shift;
    die "you do not implement the start() for $class";
}

sub stop {
    my $class = shift;
    die "you do not implement the stop() for $class";
}

sub kill {
    my ($self, $pid) = @_;
    if (kill 0, $pid) {
        kill 15, $pid;
    } else {
        warn "could not kill $pid";
    }
}

sub executable {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $name = do {
        no strict "refs";
        ${ $class . "::NAME" } or die $class . "::NAME not defined yet";
    };
    for (@PATH) {
        return path($_)->child($name)->stringify if path($_)->child($name)->exists;
    }
}

sub template {
    my ($self, ) = @_;
    state $result;
    no strict "refs";
    local $/ = undef;
    $result //= readline *{ref($self) . "::DATA"};
}

sub render {
    my ($self, %args) = @_;
    Text::Xslate->new->render_string($self->template, \%args);
}

1;
__END__

=head1 NAME

HTTP::Balancer::Actor - the base class of actors of HTTP::Balancer

=head1 SYNOPSIS

    package HTTP::Balancer::Actor::Foo;
    use Modern::Perl;
    use Moose;
    extends qw(HTTP::Balancer::Actor);

    sub start { ... }
    sub stop  { ... }

    1;
    __DATA__
    here goes the template of configuration

=head1 DESCRIPTION

The Actor in HTTP::Balancer stands for the process manager of implementations of http balancer.

Each subclass of HTTP::Balancer::Actor will be mapped to one implementation such as Perlbal or Nginx.

=cut
