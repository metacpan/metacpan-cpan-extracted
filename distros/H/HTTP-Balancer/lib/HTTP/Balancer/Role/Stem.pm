package HTTP::Balancer::Role::Stem;
use Modern::Perl;
use Moose::Role;

with qw( HTTP::Balancer::Role::Command );

around _getopt_get_options => sub {
   my ($orig, $self, $params, $opt_spec) = @_;
   my $command_name = $self->command_name;
   my $subcommands  = join(" | ", @{$self->leaves});
   Getopt::Long::Descriptive::describe_options("usage: %c $command_name [ $subcommands ]");
};

before run => sub {
    my $self = shift;
    $self->usage->die();
};

no Moose::Role;

1;
__END__

=head1 NAME

HTTP::Balancer::Role::Stem - subcommand presenter for command handlers

=head1 SYNOPSIS

    package HTTP::Balancer::Command::Any::Foo;

    package HTTP::Balancer::Command::Any::Bar;

    package HTTP::Balancer::Command::Any;
    use Modern::Perl;
    use Moose;
    with qw( HTTP::Balancer::Role::Command
             HTTP::Balancer::Role::Stem );

    sub run {
    }

=head1 DESCRIPTION

    $ http-balancer any
    usage: http-balancer any [subcommands]
    Available subcommands:
        foo
        bar

=cut
