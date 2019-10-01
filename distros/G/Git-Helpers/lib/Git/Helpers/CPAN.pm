package Git::Helpers::CPAN;
our $VERSION = '0.000020';
use Moo;

use MetaCPAN::Client ();
use Try::Tiny qw( try );
use Types::Standard qw( HashRef InstanceOf Maybe Str );

has _client => (
    is      => 'ro',
    isa     => InstanceOf ['MetaCPAN::Client'],
    lazy    => 1,
    default => sub { MetaCPAN::Client->new },
);

has _latest_release => (
    is      => 'ro',
    isa     => InstanceOf ['MetaCPAN::Client::Release'],
    lazy    => 1,
    builder => '_build_latest_release',
);

has release_name => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_release_name',
);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has repository => (
    is       => 'ro',
    isa      => Maybe [HashRef],
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_repository',
);

sub _build_repository {
    my $self = shift;

    return $self->_latest_release
        ? $self->_latest_release->resources->{repository}
        : undef;
}

sub _build_release_name {
    my $self = shift;

    return $self->name if $self->name !~ m{::};

    my $release_name;
    try {
        my $module = $self->_client->module( $self->name );
        $release_name = $module->distribution if $module;
    };

    if ( !$release_name ) {
        die sprintf( "Cannot find a module named %s", $self->name );
    }

    return $release_name;
}

sub _build_latest_release {
    my $self = shift;

    my $release;
    try {
        $release = $self->_client->release( $self->release_name );
    };

    if ( !$release ) {
        die sprintf( "Cannot find a release named %s", $self->release_name );
    }
    return $release;
}

1;

# ABSTRACT: Get repository information for a CPAN module or release

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Helpers::CPAN - Get repository information for a CPAN module or release

=head1 VERSION

version 0.000020

=head1 SYNOPSIS

    my $by_module = Git::Helpers::CPAN->new( name => 'Git::Helpers' );
    print $by_module->repository->{web};

    my $by_release = Git::Helpers::CPAN->new( name => 'Git::Helpers' );
    print $by_release->repository->{web};

=head1 CONSTRUCTOR ARGUMENTS

=head2 name

Can be either the name of a CPAN module or a CPAN release.  In the case of this
module, you could either search for C<Git::Helpers> or C<Git-Helpers>.  For
other modules, keep in mind that the release name may not map well to the
module name.   For example C<LWP::UserAgent> and C<libwww-perl>.

=head1 METHODS

=head2 release_name

Returns a C<string> which is the actual release name the search is performed
on.  Mostly helpful for debugging.  It will match your original C<name> arg
except when you've provided a module name.  In that case this will return the
name of the release which the module maps to.

=head2 repository

Returns a C<HashRef> of repository information.  It might return something like:

    {
        type => 'git',
        url  => 'https://github.com/oalders/git-helpers.git',
        web  => 'https://github.com/oalders/git-helpers',
    }

This is essentially the data structure which is returned by the MetaCPAN API,
so it *could* change if/when the MetaCPAN API changes output formats.

This method returns C<undef> if the release was found but does not provide any
repository information.  It will C<die> if the release cannot be found via the
MetaCPAN API.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2019 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
