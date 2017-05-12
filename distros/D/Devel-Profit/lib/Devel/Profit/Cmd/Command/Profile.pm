package Devel::Profit::Cmd::Command::Profile;
use strict;
use warnings;
use IO::File;
use Moose;
extends qw(Devel::Profit::Cmd::Command MooseX::App::Cmd::Command);

sub usage_desc {
    my $self = shift;
    return "devel_profit profile [filename of file to profile]";
}

sub abstract {
    my $self = shift;
    return 'Profile a file';
}

sub run {
    my ( $self, $opt, $args ) = @_;

    unshift @$args, '-MDevel::Profit';
    unshift @$args, $^X;
    system(@$args);
}

1;

