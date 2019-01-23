package Group::Git::Github;

# Created on: 2013-05-04 20:18:31
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Net::GitHub;
use Path::Tiny;

our $VERSION = version->new('0.7.0');

extends 'Group::Git';

has github => (
    is      => 'rw',
    #isa     => 'Net::GitHub',
    builder => '_github',
    lazy    => 1,
);

sub _repos {
    my ($self) = @_;
    my ($conf) = $self->conf;
    my %repos = %{ $self->SUPER::_repos() };

    my $repo = $self->github->repos;
    my @list = $repo->list;
    my $page = 0;
    do {
        $page++;
        @list = $repo->query( $repo->next_url ) if !@list;

        for my $repo (@list) {
            my $url = $repo->{git_url};
            # convert urls of the form:
            #   git://github.com/ivanwills/meteor.git
            # to
            #   git@github.com:ivanwills/meteor.git
            # as git doesn't like the form that github uses
            $url =~ s{git://github.com/([^/]+)}{git\@github.com:$1};

            $repos{ $repo->{name} } = Group::Git::Repo->new(
                name => path($repo->{name}),
                git  => $url,
            );

            # tag fork repos and original repos
            if ( $repo->{fork} ) {
                push @{ $conf->{tags}{forks} }, $repo->{name};
            }
            else {
                push @{ $conf->{tags}{originals} }, $repo->{name};
            }
        }
        @list = ();
    } while ( $repo->has_next_page );

    return \%repos;
}

sub _github {
    my ($self) = @_;
    my $conf = $self->conf;

    return Net::GitHub->new(
        $conf->{access_token}
        ? ( access_token => $conf->{access_token} )
        : (
            login => $conf->{username} ? $conf->{username} : prompt( -prompt => 'github.com username : ' ),
            pass  => $conf->{password} ? $conf->{password} : prompt( -prompt => 'github.com password : ', -echo => '*' ),
            (
                $conf->{otp}
                ? ( pass  => prompt( -prompt => 'github.com password : ', -echo => '*' ) )
                : ()
            )
        )
    );
}

1;

__END__

=head1 NAME

Group::Git::Github - Adds reading all repositories you have access to on github.com

=head1 VERSION

This documentation refers to Group::Git::Github version 0.7.0.


=head1 SYNOPSIS

   use Group::Git::Github;

   # pull (or clone missing) all repositories that joeblogs has created/forked
   my $ggg = Group::Git::Github->new(
       conf => {
           username => 'joeblogs@gmail.com',
           password => 'myverysecurepassword',
       },
   );

   # or if you have two factor auth turned on
   my $ggg = Group::Git::Github->new(
       conf => {
           username => 'joeblogs@gmail.com',
           password => 'myverysecurepassword',
           ota      => 1,
       },
   );

   # Alternitavely using personal access tokens
   # You can setup at https://github.com/settings/applications
   my $ggg = Group::Git::Github->new(
       conf => {
           access_token => '...',
       },
   );

   # list all repositories
   my $repositories = $ggg->repo();

   # do something to each repository
   for my $repo (keys %{$repositories}) {
       # eg do a pull
       $ggg->pull($repo);
   }

=head1 DESCRIPTION

Reads all repositories for the configured user. Note: if no username, password
or access_token is set you will be prompted to enter a username and password.

=head2 Configuration

There are three configuration parameters that are currently used

=over 4

=item access_token

A github OAuth personal access token. If supplied then username and password
are ignored.

=item username

Specify the user to login as, if not specified the user will be prompted to
enter a username.

=item password

Specify the password to login with, if not specified the user will be prompted
to enter a password.

=back

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
