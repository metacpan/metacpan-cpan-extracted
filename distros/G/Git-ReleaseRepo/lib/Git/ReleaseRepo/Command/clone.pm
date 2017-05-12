package Git::ReleaseRepo::Command::clone;
{
  $Git::ReleaseRepo::Command::clone::VERSION = '0.006';
}
# ABSTRACT: Clone an existing release repository

use strict;
use warnings;
use Moose;
extends 'Git::ReleaseRepo::CreateCommand';
use Cwd qw( abs_path getcwd );
use File::Spec::Functions qw( catdir catfile );
use File::HomeDir;
use File::Path qw( make_path );
use File::Slurp qw( write_file );
use File::Basename qw( basename );

sub description {
    return 'Clone an existing release repository';
}

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    # Clone the repo
    my $repo_dir = $args->[1];
    if ( !$repo_dir ) {
        $repo_dir = catdir( getcwd, $self->repo_name_from_url( $args->[0] ) );
    }
    my $cmd = Git::Repository->command( clone => $args->[0], $repo_dir );
    my @stdout = readline $cmd->stdout;
    my @stderr = readline $cmd->stderr;
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        die "Could not clone '$args->[0]'.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
            . "\nSTDOUT: " . ( join "\n", @stdout );
    }

    my $repo = Git::Repository->new( work_tree => $repo_dir );
    if ( $opt->{reference_root} ) {
        for my $submodule ( keys %{ $repo->submodule } ) {
            my $reference = catdir( $opt->{reference_root}, $submodule );
            $cmd = $repo->command( submodule => 'update', '--init', '--reference' => $reference, $submodule);
            @stdout = readline $cmd->stdout;
            @stderr = readline $cmd->stderr;
            $cmd->close;
            if ( $cmd->exit != 0 ) {
                die "Could not update submodule '$submodule'.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                    . "\nSTDOUT: " . ( join "\n", @stdout );
            }
        }
    }
    else {
        $cmd = $repo->command( submodule => update => '--init' );
        @stdout = readline $cmd->stdout;
        @stderr = readline $cmd->stderr;
        $cmd->close;
        if ( $cmd->exit != 0 ) {
            die "Could not update submodules.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                . "\nSTDOUT: " . ( join "\n", @stdout );
        }
    }

    $self->update_config( $opt, $repo );
};

1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::Command::clone - Clone an existing release repository

=head1 VERSION

version 0.006

=head1 AUTHORS

=over 4

=item *

Doug Bell <preaction@cpan.org>

=item *

Andrew Goudzwaard <adgoudz@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
