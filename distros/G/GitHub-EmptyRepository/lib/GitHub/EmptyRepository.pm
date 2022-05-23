package GitHub::EmptyRepository;

use Moo 1.007000;

our $VERSION = '0.00002';

use File::HomeDir                       ();
use GitHub::EmptyRepository::Repository ();
use List::Util qw( uniq );
use Module::Runtime qw( require_module use_module );
use MooX::HandlesVia;
use MooX::Options;
use MooX::StrictConstructor;
use Path::Tiny qw( path );
use Pithub                       ();
use Pithub::PullRequests         ();
use Pithub::Repos                ();
use Pithub::Repos::Commits       ();
use Text::SimpleTable::AutoWidth ();
use Types::Standard qw( ArrayRef Bool HashRef InstanceOf Int Str );
use WWW::Mechanize::GZip ();

option debug_useragent => (
    is            => 'ro',
    isa           => Int,
    format        => 'i',
    default       => 0,
    documentation => 'Print a _lot_ of debugging info about LWP requests',
);

my $token_help = <<'EOF';
https://help.github.com/articles/creating-an-access-token-for-command-line-use for instructions on how to get your own GitHub access token
EOF

option cache_requests => (
    is            => 'ro',
    isa           => Bool,
    documentation => 'Try to cache GET requests',
);

option github_token => (
    is            => 'ro',
    isa           => Str,
    required      => 0,
    format        => 's',
    documentation => $token_help,
);

option github_user => (
    is            => 'ro',
    isa           => Str,
    required      => 0,
    format        => 's',
    documentation => 'The username of your GitHub account',
);

option url => (
    is            => 'ro',
    isa           => ArrayRef,
    format        => 's@',
    required      => 0,
    documentation =>
        'Full Github repo url or shorthand of username/repository.  You can pass multiple url args.',
);

option org => (
    is            => 'ro',
    isa           => ArrayRef,
    format        => 's@',
    required      => 0,
    documentation => 'An organization.  You can pass multiple url args.',
);

option terse => (
    is            => 'ro',
    required      => 0,
    documentation => 'Make the report very brief',
);

has _report => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    init_arg    => undef,
    handles     => { _repository_for_url => 'get', _report_urls => 'keys', },
    lazy        => 1,
    builder     => '_build_report',
);

has _github_client => (
    is      => 'ro',
    isa     => InstanceOf ['Pithub'],
    lazy    => 1,
    builder => '_build_github_client'
);

has _mech => (
    is      => 'ro',
    isa     => InstanceOf ['LWP::UserAgent'],
    lazy    => 1,
    builder => '_build_mech',
);

sub _build_github_client {
    my $self = shift;

    return Pithub->new(
        $self->cache_requests
            || $self->debug_useragent ? ( ua => $self->_mech ) : (),
        $self->github_user  ? ( user  => $self->github_user )  : (),
        $self->github_token ? ( token => $self->github_token ) : (),
    );
}

sub _build_mech {
    my $self = shift;

    my $mech;

    if ( $self->cache_requests ) {
        my $dir = path( File::HomeDir->my_home );
        $dir->child('.github-emptyrepository-cache')->mkpath;

        require_module('CHI');
        $mech = use_module( 'WWW::Mechanize::Cached', 1.45 )->new(
            cache => CHI->new(
                driver   => 'File',
                root_dir => $dir->stringify,
            )
        );
    }
    else {
        $mech = WWW::Mechanize::GZip->new;
    }
    if ( $self->debug_useragent ) {
        use_module( 'LWP::ConsoleLogger::Easy', 0.000013 );
        LWP::ConsoleLogger::Easy::debug_ua( $mech, $self->debug_useragent );
    }
    return $mech;
}

sub _build_report {
    my $self = shift;

    my %report;

    # Where we put all urls (from --url AND/OR --org)
    my @urls = ();

    # Where will go urls found from --org
    if ( $self->org ) {
        foreach my $org ( @{ $self->org } ) {
            my $repos = Pithub::Repos->new(
                $self->github_user  ? ( user  => $self->github_user )  : (),
                $self->github_token ? ( token => $self->github_token ) : (),
            );
            my $result = $repos->list( org => $org );

            $result->auto_pagination(1);

            while ( my $row = $result->next ) {
                push @urls, $row->{full_name};
            }
        }
    }

    # Merge --org urls (already in @urls) with --url urls and clean dups
    if ( $self->url ) {
        push @urls, @{ $self->url };
    }
    @urls = uniq @urls;

    foreach my $url (@urls) {
        my $repo = GitHub::EmptyRepository::Repository->new(
            github_client => $self->_github_client,
            url           => $url,
        );
        $report{$url} = $repo;
    }

    return \%report;
}

sub print_report {
    my $self = shift;

    my @repos = map { $self->_repository_for_url($_) } $self->_report_urls;

    return unless @repos;

    my $table = Text::SimpleTable::AutoWidth->new;
    my @cols
        = ( 'user', 'repo', 'empty?', 'commits', 'branches', 'pullrequests' );
    $table->captions( \@cols );

    foreach my $repository (@repos) {
        my $report = $repository->report;

        # TODO:
        # Check if repository is old?
        my $is_empty = 1;
        if ( $report->{nb_branches} > 1 ) {

            # No doubt, not empty because multiple branches
            $is_empty = 0;
        }
        if ( $report->{nb_pullrequests} > 0 ) {

            # No doubt, not empty because at least one pull request
            $is_empty = 0;
        }
        if ( $report->{nb_commits} > 1 ) {

            # No doubt, not empty because more than just a dummy commit
            # It can be a lot of dummy commits xD but that's another story
            $is_empty = 0;
        }
        elsif ( $is_empty and $report->{nb_commits} == 1 ) {

# Possibly "almost" empty if there is one commit with only a boilerplate file (advised by GitHub UI)
            foreach my $file ( @{ $report->{files} } ) {

                # Check filename against list of "whitelisted" filenames
                if (
                    !grep /$file/,
                    (
                        "README.md", ".gitignore",
                        "LICENSE",   "CONTRIBUTING.md"
                    )
                    )
                {
                    # Not empty
                    $is_empty = 0;
                }
            }
        }
        if ( $is_empty and $self->terse ) {
            print $repository->user . "/" . $repository->name . "\n";
        }
        else {
            $table->row(
                $repository->user,
                $repository->name,
                $is_empty                  ? "YES" : "NO",
                $report->{nb_commits} > 1  ? "2+"  : $report->{nb_commits},
                $report->{nb_branches} > 1 ? "2+"  : $report->{nb_branches},
                $report->{nb_pullrequests} > 1
                ? "2+"
                : $report->{nb_pullrequests},
            );
        }
    }

    if ( !$self->terse ) { print $table->draw }

    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

GitHub::EmptyRepository - Scan for empty repositories

=head1 VERSION

version 0.00002

=head1 SYNOPSIS

=head1 AUTHORS

=over 4

=item *

Thibault Duponchelle <thibault.duponchelle@gmail.com>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Thibault Duponchelle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Scan for empty repositories

