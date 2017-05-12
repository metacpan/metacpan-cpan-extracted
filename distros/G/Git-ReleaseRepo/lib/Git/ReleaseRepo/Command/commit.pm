package Git::ReleaseRepo::Command::commit;
{
  $Git::ReleaseRepo::Command::commit::VERSION = '0.006';
}
# ABSTRACT: Commit a release

use strict;
use warnings;
use Moose;
use Git::ReleaseRepo -command;
use Git::Repository;

with 'Git::ReleaseRepo::WithVersionPrefix';

sub description {
    return 'Perform a release';
}

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    my ( $version, $branch_version );
    my $git = $self->git;
    my $prefix = $self->release_prefix;
    my $bugfix = $git->current_branch ne 'master';
    if ( $args->[0] ) {
        $version = $args->[0];
        ( $branch_version ) = $args->[0] =~ m/^($prefix\d+[.]\d+)/;
    }
    else {
        my $latest_version = $git->latest_version;
        my @parts = $latest_version ? split /[.]/, $latest_version
                  : ( "${prefix}0", 0, 0 ); # Our first release!
        if ( $bugfix ) {
            # Bugfix releases increment the third number
            $parts[2]++;
        }
        else {
            # Normal releases increment the second number
            $parts[1]++;
            $parts[2] = 0;
        }
        # Remove anything after the 3rd number. If they wanted more, they
        # should have given us an argument!
        $version = join ".", @parts[0..2];
        $branch_version = join ".", @parts[0..1];
    }
    print "Release version $version\n";
    print "Starting release cycle $branch_version\n" if !$bugfix;

    # Release all modules too!
    for my $module ( keys %{ $git->submodule } ) {
        my $subgit = $git->submodule_git( $module );
        if ( !$bugfix ) {
            $self->branch_release( $subgit, $branch_version );
        }
        $self->tag_release( $subgit, $version );
    }
    if ( !$bugfix ) {
        $self->branch_release( $git, $branch_version );
    }
    $self->tag_release( $git, $version );
};

sub branch_release {
    my ( $self, $git, $version ) = @_;
    $git->run( branch => $version );
}

sub tag_release {
    my ( $self, $git, $version ) = @_;
    $git->run( tag => $version );
}

1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::Command::commit - Commit a release

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
