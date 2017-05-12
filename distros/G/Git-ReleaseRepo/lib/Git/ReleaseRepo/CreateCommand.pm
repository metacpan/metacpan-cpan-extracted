package Git::ReleaseRepo::CreateCommand;
{
  $Git::ReleaseRepo::CreateCommand::VERSION = '0.006';
}
# ABSTRACT: Base class for commands that have to create a new repository

use strict;
use warnings;
use Moose;
extends 'Git::ReleaseRepo::Command';
use File::Spec::Functions qw( catfile );
use YAML qw( LoadFile DumpFile );

override usage_desc => sub {
    my ( $self ) = @_;
    return super() . " <repo_url> [<repo_name>]";
};

sub update_config {
    my ( $self, $opt, $repo, $extra ) = @_;
    $extra ||= {};
    my $config_file = catfile( $repo->git_dir, 'release' );
    my $config = -f $config_file ? LoadFile( $config_file ) : {};

    for my $conf ( qw( version_prefix ) ) {
        if ( exists $opt->{$conf} ) {
            $config->{$conf} = $opt->{$conf};
        }
    }

    $config = { %$config, %$extra };
    DumpFile( $config_file, $config );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    return $self->usage_error( "Must give a repository URL!" ) if ( @$args < 1 );
    return $self->usage_error( "Too many arguments" ) if ( @$args > 3 );
    return $self->usage_error( 'Must specify --version_prefix' ) unless $opt->{version_prefix};
}

around opt_spec => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        [ 'version_prefix:s' => 'Set the version prefix of the release repository' ],
        [ 'reference_root=s' => 'Specify a directory containing existing submodules to reference' ],
    );
};

1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::CreateCommand - Base class for commands that have to create a new repository

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
