package Git::ReleaseRepo::Command::status;
{
  $Git::ReleaseRepo::Command::status::VERSION = '0.006';
}
# ABSTRACT: Show the status of a release repository

use strict;
use warnings;
use List::MoreUtils qw( uniq );
use Moose;
use Git::ReleaseRepo -command;
use Progress::Any;

with 'Git::ReleaseRepo::WithVersionPrefix';

sub description {
    return 'Show the status of a release repository';
}

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    # "master" looks at master since latest release branch
    # "bugfix" looks at release branch since latest release
    my ( $since_version, %outdated, %diff );
    my $git = $self->git;
    my $bugfix = $git->current_branch ne 'master';

    # We must fetch in order to get an accurate picture of the status
    my @repos = ( $self->git, map { $self->git->submodule_git( $_ ) } keys %{ $self->git->submodule } );
    my $progress = Progress::Any->get_indicator( task => "fetch" );
    $progress->pos( 0 );
    $progress->target( ~~@repos );
    for my $git ( @repos ) {
        next unless $git->has_remote( 'origin' );
        my $cmd = $git->command( 'fetch', 'origin' );
        my @stderr = readline $cmd->stderr;
        my @stdout = readline $cmd->stdout;
        $cmd->close;
        if ( $cmd->exit != 0 ) {
            die "ERROR: Could not fetch.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                . "\nSTDOUT: " . ( join "\n", @stdout );
        }
        my ( $name ) = $git->work_tree =~ m{/([^/]+)$};
        $progress->update( message => "Fetched $name" );
    }
    $progress->finish;

    # Deploy branch
    if ( my $track = $self->config->{track} ) {
        my $current = $git->current_release;
        print "On release $current";
        my $latest = $git->latest_version( $track );
        if ( $git->current_release ne $latest ) {
            print " (can update to $latest)";
        }
        print "\n";
        return 0;
    }
    # Bugfix release
    elsif ( $bugfix ) {
        my $rel_branch = $git->current_branch;
        $since_version = $git->latest_version( $rel_branch );
        %outdated = map { $_ => 1 } $git->outdated_branch( $rel_branch );
        %diff = map { $_ => 1 } $git->outdated_tag( $since_version );
    }
    # Regular release
    else {
        $since_version = $git->has_remote( 'origin' )
                       ? $git->latest_release_branch( 'remotes/origin' )
                       : $git->latest_release_branch;
        %outdated = map { $_ => 1 } $git->outdated_branch( 'master' );
        %diff = $since_version ? map { $_ => 1 } $git->outdated_tag( $since_version . '.0' ) 
                # If we haven't had a release yet, everything we have is different
                 : map { $_ => 1 } keys %{$git->submodule};
    }

    my $header = "Changes since " . ( $since_version || "development started" );
    print $header . "\n";
    print "-" x length( $header ) . "\n";
    my @changed = sort( uniq( keys %outdated, keys %diff ) );
    #; use Data::Dumper; print Dumper \@changed;
    for my $changed ( @changed ) {
        print "$changed";
        if ( !$since_version || $diff{ $changed } ) {
            print " changed";
        }
        if ( $outdated{$changed} ) {
            print " (can update)";
        }
        print "\n";
    }
};

1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::Command::status - Show the status of a release repository

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
