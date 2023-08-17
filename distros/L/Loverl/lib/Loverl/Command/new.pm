package Loverl::Command::new;

# ABSTRACT: Initializes a new LÖVE2D project directory

use Loverl -command;
use Loverl::Create::Directory;
use v5.36;
use Carp;
use Git::Repository;

use constant { true => 1, false => 0 };

my $isVerbose = false;

my $project_dir = Loverl::Create::Directory->new();

sub command_names { qw(new --new -n) }

sub abstract { "initializes a new LÖVE2D project" }

sub description { "Initializes a new LÖVE2D project directory." }

sub validate_args ( $self, $opt, $args ) {
}

sub execute ( $self, $opt, $args ) {
    $project_dir->dir_name(@$args);
    $isVerbose = true if $self->app->global_options->{verbose};
    $project_dir->create_dir($isVerbose);
    if ( Git::Repository->version_gt('1.6.5') ) {
        Git::Repository->run( init => $project_dir->project_dir() );
        my $repo =
          Git::Repository->new( work_tree => $project_dir->project_dir() );
    }
    else {
        croak("Install the latest version of git");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Loverl::Command::new - Initializes a new LÖVE2D project directory

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    loverl new

    or

    loverl new [New Project Name]

=head1 DESCRIPTION

Loverl's new command will initialize the LÖVE2D project directory.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Nobunaga.

This is free software, licensed under:

  The MIT (X11) License

=cut
