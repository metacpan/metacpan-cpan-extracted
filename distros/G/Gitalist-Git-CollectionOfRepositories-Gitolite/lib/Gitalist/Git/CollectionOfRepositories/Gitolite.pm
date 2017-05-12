package Gitalist::Git::CollectionOfRepositories::Gitolite;
{
  $Gitalist::Git::CollectionOfRepositories::Gitolite::VERSION = '0.002';
}
use MooseX::Declare;
use namespace::autoclean;
use Gitalist::Git::CollectionOfRepositories::Gitolite::Impl;

# ABSTRACT: Adds support for gitolite to gitalist

class Gitalist::Git::CollectionOfRepositories::Gitolite
    with Gitalist::Git::CollectionOfRepositoriesWithRequestState 
{
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;    
    use Gitalist::Git::Types qw/DirOrUndef /;

    has gitolite_conf => (
        is       => 'ro',
        isa      => NonEmptySimpleStr,
        default  => '/home/git/.gitolite.rc',
        required => 0,
    );

    has gitolite_bin_dir => (
        is       => 'ro',
        isa      => DirOrUndef,
        default  => '/home/git/bin',
        required => 0,
        coerce   => 1,
        lazy     => 1,
    );
    
    method implementation_class { 'Gitalist::Git::CollectionOfRepositories::Gitolite::Impl' }
    method debug_string { 'Chose ' . ref($self) }

    method extract_request_state ($ctx) {
        return (
            remote_user => $ctx->request->remote_user || $ENV{REMOTE_USER} || 'gitweb',
        );
    }
}

=head1 NAME

Gitalist::Git::CollectionOfRepositories::Gitolite

=head1 SYNOPSIS

 gitalist.conf:

    <Model::CollectionOfRepos>
        class Gitalist::Git::CollectionOfRepositories::Gitolite
        # optional, /home/git/.gitolite.rc
        gitolite_conf /home/git/.gitolite.rc
        # optional, defaults to /home/git/bin/
        gitolite_bin_dir /home/git/bin/
    </Model::CollectionOfRepos>

=head1 DESCRIPTION

Adds support for gitolite to gitalist

=head1 SEE ALSO

L<Gitalist>, L<Gitalist::Git::CollectionOfRepositories>, L<Gitalist::Git::Repository>, 
L<https://github.com/broquaint/Gitalist>

=head1 AUTHORS

Gavin Mogan <halkeye@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Gavin Mogan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
