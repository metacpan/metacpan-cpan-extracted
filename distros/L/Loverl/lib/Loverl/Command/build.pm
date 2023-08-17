package Loverl::Command::build;

# ABSTRACT: Builds the LÖVE2D project into a build directory

use Loverl -command;
use v5.36;
use Carp;
use Archive::Zip;
use Cwd;

my $zip = Archive::Zip->new();

my $game_file = 'Game.love';
my $dir       = getcwd();

sub command_names { qw(build --build -b) }

sub abstract { "builds the LÖVE2D project" }

sub description { "Builds the LÖVE2D project into a build directory." }

sub validate_args ( $self, $opt, $args ) {
    $self->usage_error(
        "Remove @$args\n
        run \"loverl build\""
    ) if @$args;
}

sub execute ( $self, $opt, $args ) {
    if ( -e "main.lua" ) {
        if ( -e "conf.lua" ) {
            system("sudo rm -rf $game_file") if -e "$game_file";
            $zip->addTree( '.', '/' );
            $zip->writeToFileNamed($game_file);
            print( "+ " . $dir . "/$game_file\n" );
        }
        else {
            croak("you are missing a conf.lua file");
        }
    }
    else {
        croak("you are missing a main.lua file");
    }
    print("test verbose") if $self->app->global_options->{verbose};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Loverl::Command::build - Builds the LÖVE2D project into a build directory

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    loverl build

=head2 Requirements

Need main.lua and conf.lua to exist in order to use the command.

=head1 DESCRIPTION

Loverl's build command will build the LÖVE2D project into a build directory.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
