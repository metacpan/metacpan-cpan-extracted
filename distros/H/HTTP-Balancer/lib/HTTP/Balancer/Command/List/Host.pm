package HTTP::Balancer::Command::List::Host;
use Modern::Perl;
use Moose;
with qw(HTTP::Balancer::Role::Command);

sub run {
    my ($self, ) = @_;

    my @columns = (
        "id",
        "name",
        grep {!/^(id|name)$/} $self->model("Host")->columns
    );

    my $table = Text::Table->new(@columns);

    $table->load(
        $self
        ->model("Host")
        ->all(sub { [ shift->slice(@columns) ] })
    );

    print $table;
}

1;
