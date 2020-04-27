package Getopt::Kingpin::Command;
use 5.008001;
use strict;
use warnings;
use Getopt::Kingpin -base;
use Carp;

our $VERSION = "0.08";

sub help_short {
    my $self = shift;
    my @help = ($self->name);

    if ($self->name eq "help") {
        push @help, "[<command>...]";
    } else {
        if ($self->flags->count > 1) {
            push @help, "[<flags>]";
        }

        if ($self->commands->count > 0) {
            push @help, "<command>";
            push @help, "[<args> ...]";
        } else {
            foreach my $arg ($self->args->get_all) {
                push @help, $arg->help_name(1);
            }
        }
    }

    return join " ", @help;
}

sub help {
    my $self = shift;
    printf "usage: %s %s\n", $self->parent->name, $self->help_short;
    printf "\n";

    if ($self->description ne "") {
        printf "%s\n", $self->description;
        printf "\n";
    }

    printf "%s\n", $self->flags->help;

    if ($self->args->count > 0) {
        printf "%s\n", $self->args->help;
    }

    if ($self->commands->count > 1) {
        printf "Subcommands:\n";
        foreach my $sub ($self->commands->get_all) {
            next if $sub->name eq "help";
            printf "  %s %s\n", $sub->parent->name, $sub->name;
            printf "    %s\n", $sub->description;
            printf "\n";
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Flags - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin::Flags;
    my $flags = Getopt::Kingpin::Flags->new;
    $flags->add(
        name        => 'help',
        description => 'Show context-sensitive help.',
    )->bool();

=head1 DESCRIPTION

Getopt::Kingpin::Flags は、Getopt::Kingpinから使用するモジュールです。
Flagを集合として扱います。

=head1 METHOD

=head2 new()

Create Getopt::Kingpin::Flags object.

=head2 add(name => $name, description => $description)

$name と $description をもつGetopt::Kingpin::Flagを生成し、管理します。

=head2 get($name)

$name で指定したGetopt::Kingpin::Flagを取り出します。

=head2 keys()

定義されている$nameの一覧の出力します。
add()した順で出力されます。

=head2 values()

定義されているGetopt::Kingpin::Flagをすべて出力します。
add()した順で出力されます。

=head2 _help_length()

short_name、name、descriptionの文字列長を返します。

=head2 help()

ヘルプを表示します。

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

