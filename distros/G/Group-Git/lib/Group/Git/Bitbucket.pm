package Group::Git::Bitbucket;

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

our $VERSION = version->new('0.6.10');

extends 'Group::Git';

sub _httpenc {
    my ($str) = @_;
    $str =~ s/(\W)/sprintf "%%%x", ord $1/egxms;
    return $str;
}

sub _repos {
    my ($self) = @_;
    my %repos = %{ $self->SUPER::_repos() };

    my ($conf) = $self->conf;
    #EG curl --user buserbb:2934dfad https://api.bitbucket.org/1.0/user/repositories

    my @argv = @ARGV;
    @ARGV = ();
    my $mech = $self->mech;
    my $user = _httpenc( $conf->{username} ? $conf->{username} : prompt( -prompt => 'bitbucket username : ' ) );
    my $pass = _httpenc( $conf->{password} ? $conf->{password} : prompt( -prompt => 'bitbucket password : ', -echo => '*' ) );
    my $url  = "https://$user:$pass\@api.bitbucket.org/1.0/user/repositories";
    @ARGV = @argv;

    $mech->get($url);
    my $repos = decode_json $mech->content;
    for my $repo ( @$repos ) {
        $repos{$repo->{name}} = Group::Git::Repo->new(
            name => path($repo->{name}),
            url  => "https://bitbucket.org/$repo->{owner}/$repo->{name}",
            git  => "git\@bitbucket.org:$repo->{owner}/$repo->{name}.git",
        );
    }

    return \%repos;
}

1;

__END__

=head1 NAME

Group::Git::Bitbucket - Adds reading all repositories you have access to on bitbucket.org

=head1 VERSION

This documentation refers to Group::Git::Bitbucket version 0.6.10.

=head1 SYNOPSIS

   use Group::Git::Bitbucket;

   # pull (or clone missing) all repositories that joeblogs has created/forked
   my $ggb = Group::Git::Bitbucket->new(
       conf => {
           username => 'joeblogs@gmail.com',
           password => 'myverysecurepassword',
       },
   );

   # list all repositories
   my $repositories = $ggb->repo();

   # do something to each repository
   for my $repo (keys %{$repositories}) {
       # eg do a pull
       $ggb->pull($repo);
   }

=head1 DESCRIPTION

Reads all repositories for the configured user (if none set user will be
prompted to enter one as well as a password)
Reads all repositories for the configured user. Note: if no username or password
is set you will be prompted to enter a username and password.

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
