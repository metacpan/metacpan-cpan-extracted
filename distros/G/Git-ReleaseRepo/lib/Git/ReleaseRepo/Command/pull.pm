package Git::ReleaseRepo::Command::pull;
{
  $Git::ReleaseRepo::Command::pull::VERSION = '0.006';
}
# ABSTRACT: Update a release repository

use Moose;
extends 'Git::ReleaseRepo::Command';

override usage_desc => sub {
    my ( $self ) = @_;
    return super();
};

sub description {
    return 'Update a deployed release repository';
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    return $self->usage_error( "Too many arguments" ) if ( @$args > 0 );
}

around opt_spec => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        [ 'branch=s' => 'Specify the release branch to deploy. Defaults to the latest release branch.' ],
        [ 'master' => 'Deploy the "master" version of the repository and all submodules, for testing.' ],
    );
};

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    my $git         = $self->git;
    my $branch      = $opt->{master} ? "master"
                    : $opt->{branch} ? $opt->{branch}
                    : $self->config->{track} ? $self->config->{track}
                    : $git->current_branch;
    my @repos = ( $self->git, map { $self->git->submodule_git( $_ ) } keys %{ $self->git->submodule } );
    my $version_prog = Progress::Any->get_indicator( task => 'main' );
    $version_prog->pos( 0 );
    $version_prog->target( ~~@repos );
    my $version; # Filled in after the first pull
    for my $repo ( @repos ) {
        my ( $name ) = $repo->work_tree =~ m{/([^/]+)$};
        if ( $repo->has_remote( 'origin' ) ) {
            my $cmd = $repo->command( checkout => $branch );
            my @stderr = readline $cmd->stderr;
            my @stdout = readline $cmd->stdout;
            $cmd->close;
            if ( $cmd->exit != 0 ) {
                die "Could not checkout branch $branch\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                    . "\nSTDOUT: " . ( join "\n", @stdout );
            }
            $cmd = $repo->command( qw(fetch origin) );
            @stderr = readline $cmd->stderr;
            @stdout = readline $cmd->stdout;
            $cmd->close;
            if ( $cmd->exit != 0 ) {
                die "Could not fetch origin\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                    . "\nSTDOUT: " . ( join "\n", @stdout );
            }
            $cmd = $repo->command( qw(pull origin), $branch );
            @stderr = readline $cmd->stderr;
            @stdout = readline $cmd->stdout;
            $cmd->close;
            if ( $cmd->exit != 0 ) {
                die "Could not pull branch $branch from origin\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                    . "\nSTDOUT: " . ( join "\n", @stdout );
            }
        }
        $version ||= $opt->{master}  ? "master"
                 : $self->config->{track} ? $git->latest_version( $branch )
                 : $branch;
        my $cmd = $repo->command( checkout => $version );
        my @stderr = readline $cmd->stderr;
        my @stdout = readline $cmd->stdout;
        $cmd->close;
        if ( $cmd->exit != 0 ) {
            die "Could not checkout $version\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                . "\nSTDOUT: " . ( join "\n", @stdout );
        }
        $version_prog->update( message => "Pulled $name" );
    }
    $version_prog->finish;
};

1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::Command::pull - Update a release repository

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
