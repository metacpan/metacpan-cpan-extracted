package HTTP::Balancer::Command::Help;

use Modern::Perl;

use Moose;

with qw( HTTP::Balancer::Role::Command );

sub run {
    my ($self, ) = @_;

    say "usage: http-balancer [subcommands]";
    say "Available subcommands:";
    for (@{HTTP::Balancer::Command->leaves}) {
        say "   ", $_;
    }
}

1;
__END__

=head1 NAME

HTTP::Balancer::Command::Help - show help messages

=head1 SYNOPSIS

    $ http-balancer help

=cut
