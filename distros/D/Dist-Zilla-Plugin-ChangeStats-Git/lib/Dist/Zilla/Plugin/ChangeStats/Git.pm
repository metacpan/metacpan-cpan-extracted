package Dist::Zilla::Plugin::ChangeStats::Git;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: add code churn statistics to the changelog
$Dist::Zilla::Plugin::ChangeStats::Git::VERSION = '0.6.0';

use strict;
use warnings;

use CPAN::Changes 0.17;
use Perl::Version;
use Git::Repository;
use Path::Tiny;
use Try::Tiny;

use Moose;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::AfterRelease
/;

with 'Dist::Zilla::Role::Author::YANICK::RequireZillaRole' => {
    roles => [ '+Dist::Zilla::Role::Author::YANICK::Changelog' ],
};

sub mvp_multivalue_args { qw/ skip_file skip_match / }

has repo => (
    is => 'ro',
    default => sub { Git::Repository->new( work_tree => '.' ) },
);

has change_file => (
    is => 'ro',
    default => 'Changes',
);

has "develop_branch" => (
    isa => 'Str',
    is => 'ro',
    default => 'master'
);

has "release_branch" => (
    isa => 'Str',
    is => 'ro',
    default => 'releases'
);

has "auto_previous_tag" => (
    isa => 'Bool',
    is => 'ro',
    default => 0,
);

has group => (
    is => 'ro',
    default => '',
);

has skip_file => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    traits => ['Array'],
    handles => {
        all_skip_files => 'elements',
        has_skip_files => 'count',
    }
);

has skip_match => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    traits => ['Array'],
    handles => {
        all_skip_matches => 'elements',
        has_skip_matches => 'count',
    }
);

has text => (
    is => 'ro',
    isa => 'Str',
    default => 'code churn',
);


has stats => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

    my $comparison_data = $self->_get_comparison_data;
    if ( defined $comparison_data ) {
        my $stats = (length $self->text ? $self->text . ': ' : '') . $comparison_data;
        $stats =~ s/\s+/ /g;
        return $stats;
    } else {
        return;
    }
    }
);
sub _get_comparison_data {
    my $self = shift;

    # What are we diffing against? :)
    my( $prev, $next ) = ( $self->release_branch, $self->develop_branch );
    if ( $self->auto_previous_tag ) {
        $prev = $self->_get_previous_tag;
        return if ! defined $prev;
    }
    $self->log_debug( "Comparing '$prev' against '$next' for code stats" );

    my $output;
    if($self->has_skip_files || $self->has_skip_matches) {
        my @numstats = try { $self->repo->run( 'diff', '--numstat',
            join '...', $prev, $next
        ) } catch {
            warn "could not gather stats: $_\n";
            return;
        } or return;

        my $data = { files => 0, insertions => 0, deletions => 0 };

        ITEM:
        for my $item (@numstats) {
            my($insertions, $deletions, $path) = split /\s+/, $item, 3;
            next ITEM if grep { $path eq $_ } $self->all_skip_files;
            next ITEM if grep { $path =~ m{$_}i } $self->all_skip_matches;

            # binary files get '-' for insertions/deletions
            ++$data->{'files'};
            $data->{'insertions'} += $insertions =~ m{^\d+$} ? $insertions : 0;
            $data->{'deletions'} += $deletions =~ m{^\d+$} ? $deletions : 0;
        }

        $output = sprintf '%d file%s changed, %d insertion%s(+), %d deletion%s(-)',
                  $data->{'files'},
                  $data->{'files'} == 1 ? '' : 's',
                  $data->{'insertions'},
                  $data->{'insertions'} == 1 ? '' : 's',
                  $data->{'deletions'},
                  $data->{'deletions'} == 1 ? '' : 's';
    }
    else {
        ($output) = try {
            $self->repo->run( 'diff', '--shortstat', join '...', $prev, $next) 
        } catch {
            warn "could not gather stats: $_\n";
            return;
        };
    }
    return $output;
}

sub _get_previous_tag {
    my( $self ) = @_;
    my @plugins = grep { $_->isa('Dist::Zilla::Plugin::Git::Tag') } @{ $self->zilla->plugins_with( '-Git::Repo' ) };
    die "We dont know what to do with multiple Git::Tag plugins loaded!" if scalar @plugins > 1;
    die "Please load the Git::Tag plugin to use auto_release_tag or disable it!" if ! scalar @plugins;
    (my $match = $plugins[0]->tag_format) =~ s/\%\w/\.\+/g; # hack.
    $match = ( grep { $_ =~ /$match/ } $self->repo->run( 'tag' ) )[-1];
    if ( ! defined $match ) {
        $self->log( "Unable to find the previous tag, trying to find the first commit!" );
        $match = $self->repo->run( 'rev-list', "--max-parents=0", 'HEAD' );
        if ( ! defined $match ) {
            $self->log( "Unable to find the first commit, giving up!" );
            return;
        }
    }
    return $match;
}

sub munge_files {
  my ($self) = @_;
  return unless $self->stats;
  my $changelog = $self->zilla->changelog;

  my ( $next ) = reverse $changelog->releases;

  $next->add_changes( { group => $self->group  }, $self->stats );

  $self->zilla->save_changelog($changelog);

}

sub after_release {
  my $self = shift;
  return unless $self->stats;
  my $changes = CPAN::Changes->load(
      $self->zilla->changelog_name,
      next_token => qr/\{\{\$NEXT\}\}/
  );

  for my $next ( reverse $changes->releases ) {
    next if $next->version =~ /NEXT/;

    $next->add_changes( { group => $self->group  }, $self->stats );

    # and finally rewrite the changelog on disk
    path($self->zilla->changelog_name)->spew($changes->serialize);

    return;
  }

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ChangeStats::Git - add code churn statistics to the changelog

=head1 VERSION

version 0.6.0

=head1 SYNOPSIS

    In the dist.ini:

    [ChangeStats::Git]
    group=STATISTICS
    skip_match=^meta

=head1 DESCRIPTION

Adds a line to the changelog giving some stats about the
code churn since the last release, which will look like:

  - code churn: 6 files changed, 111 insertions(+), 1 deletions(-)

=head1 ARGUMENTS

=head2 group

If given, the line is added to the specified group.

=head2 develop_branch

The master developing branch. Defaults to I<master>.

=head2 auto_previous_tag

If enabled, look in the guts of the L<Dist::Zilla::Plugin::Git::Tag> plugin in order to find the
previous release's tag. This will be then compared against the develop_branch. Defaults to false (0).

=head2 release_branch

The branch recording the releases. Defaults to I<releases>.

=head2 text

The text before git output. If it is a non-empty string, C<:E<lt>spaceE<gt>> will be appended. Defaults to I<code churn>.

=head2 skip_file

A complete path (from the distribution root) that should not be included in the statistics. Can be given
multiple times.

=head2 skip_match

A part of a regex used to match against complete paths. Paths that match are not included in the statistics. Can be
given multiple times.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
