package Group::Git::Stash;

# Created on: 2013-05-04 20:18:24
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
use IO::Prompt qw/prompt/;
use JSON qw/decode_json/;
use WWW::Mechanize;
use Path::Tiny;

our $VERSION = version->new('0.6.3');

extends 'Group::Git';

has '+recurse' => (
    default => 1,
);
has 'mech' => (
    is      => 'rw',
    default => sub { WWW::Mechanize->new; },
);

sub _httpenc {
    my ($str) = @_;
    $str =~ s/(\W)/sprintf "%%%x", ord $1/egxms;
    return $str;
}

sub _repos {
    my ($self) = @_;
    my %repos = %{ $self->SUPER::_repos() };

    my ($conf) = $self->conf;
    #EG curl --user buserbb:2934dfad https://stash.example.com/rest/api/1.0/repos

    my @argv = @ARGV;
    @ARGV = ();
    my $mech  = $self->mech;
    my $user  = _httpenc( $conf->{username} ? $conf->{username} : prompt( -prompt => 'stash username : ' ) );
    my $pass  = _httpenc( $conf->{password} ? $conf->{password} : prompt( -prompt => 'stash password : ', -echo => '*' ) );
    my $url   = "https://$user:$pass\@$conf->{stash_host}/rest/api/1.0/repos?limit=100&start=";
    my $start = 0;
    my $more  = 1;
    @ARGV = @argv;

    while ($more) {
        $mech->get( $url . $start );
        my $response = decode_json $mech->content;

        for my $repo (@{ $response->{values} }) {
            my $project = $repo->{project}{name};
            my $url     = $repo->{links}{self}[0]{href};
            my %clone   = map {($_->{name} => $_->{href})} @{ $repo->{links}{clone} };
            my $dir     = $self->recurse ? path("$project/$repo->{name}") : path($repo->{name});

            $repos{$dir} = Group::Git::Repo->new(
                name => $dir,
                url  => $url,
                git  => $conf->{clone_type} && $conf->{clone_type} eq 'http' ? $clone{http} : $clone{ssh},
            );
            push @{ $conf->{tags}{$project} }, "$dir";
        }
        $more  = !$response->{isLastPage};
        $start = $response->{nextPageStart};
    }

    return \%repos;
}

1;

__END__

=head1 NAME

Group::Git::Stash - Adds reading all repositories you have access to on your local Stash server

=head1 VERSION

This documentation refers to Group::Git::Stash version 0.6.3.

=head1 SYNOPSIS

   use Group::Git::Stash;

   # pull (or clone missing) all repositories that joeblogs has created/forked
   my $ggs = Group::Git::Stash->new(
       conf => {
           username => 'joeblogs@example.com',
           password => 'myverysecurepassword',
       },
       # resursive is turned on by default for stash to allow for stash projects
       recurse => 1,
   );

   # list all repositories
   my $repositories = $ggs->repo();

   # do something to each repository
   for my $repo (keys %{$repositories}) {
       # eg do a pull
       $ggs->pull($repo);
   }

=head1 DESCRIPTION

Reads all repositories that the configured user has access to. Note: if no
user is set up (or no password is supplied) then you will be prompted to
enter the username and/or password.

=head1 SUBROUTINES/METHODS

=over 4

=item mech

Property for storing the L<WWW::Mechanize> object for talking to stash

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

When using with the C<group-git> command the group-git.yml can be used
to configure this plugin:

C<group-git.yml>

 ---
 type: Stash
 username: stash.user
 password: supperSecret
 stash_host: stash.example.com

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
