package Git::ReleaseRepo::Command::init;
{
  $Git::ReleaseRepo::Command::init::VERSION = '0.006';
}
# ABSTRACT: Initialize Git::ReleaseRepo

use strict;
use warnings;
use Moose;
use Git::ReleaseRepo -command;
use Cwd qw( getcwd abs_path );
use File::Spec::Functions qw( catdir catfile );
use File::HomeDir;
use File::Path qw( make_path );
use YAML qw( DumpFile );

sub description {
    return 'Initialize Git::ReleaseRepo';
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    if ( !$opt->{version_prefix} ) {
        $self->usage_error( "Must have a --version_prefix" );
    }
}

around opt_spec => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        [ 'version_prefix:s' => 'Set the version prefix of the release repository' ],
    );
};

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    my $dir = $self->git->git_dir;
    my $conf_file = catfile( $dir, 'release' );
    if ( -e $conf_file ) {
        die "Cannot initialize: File '$conf_file' already exists!\n";
    }
    my $repo_conf = {};
    for my $conf ( qw( version_prefix ) ) {
        if ( exists $opt->{$conf} ) {
            $repo_conf->{$conf} = $opt->{$conf};
        }
    }
    DumpFile( $conf_file, $repo_conf );
};

1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::Command::init - Initialize Git::ReleaseRepo

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
