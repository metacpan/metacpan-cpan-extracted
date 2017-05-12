package Dist::Zilla::Plugin::NextVersion::Semantic;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: update the next version, semantic-wise
$Dist::Zilla::Plugin::NextVersion::Semantic::VERSION = '0.2.5';
use strict;
use warnings;

use 5.10.0;

use CPAN::Changes 0.20;
use Perl::Version;
use List::AllUtils qw/ any min /;

use Moose;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::TextTemplate
    Dist::Zilla::Role::BeforeRelease
    Dist::Zilla::Role::AfterRelease
    Dist::Zilla::Role::VersionProvider
    Dist::Zilla::Plugin::NextVersion::Semantic::Incrementer
/;

use Moose::Util::TypeConstraints;

subtype 'ChangeCategory',
    as 'ArrayRef[Str]';

coerce ChangeCategory =>
    from 'Str',
    via {
        [ split /\s*,\s*/, $_ ]
    };


has change_file  => ( is => 'ro', isa=>'Str', default => 'Changes' );


has numify_version => ( is => 'ro', isa => 'Bool', default => 0 );


has format => (
    is => 'ro',
    isa => 'Str',
    default => '%d.%3d.%3d',
);


has major => (
    is => 'ro',
    isa => 'ChangeCategory',
    coerce => 1,
    default => sub { [ 'API CHANGES' ] },
    traits  => ['Array'],
    handles => { major_groups => 'elements' },
);


has minor => (
    is => 'ro',
    isa => 'ChangeCategory',
    coerce => 1,
    default => sub { [ 'ENHANCEMENTS', 'UNGROUPED' ] },
    traits  => ['Array'],
    handles => { minor_groups => 'elements' },
);


has revision => (
    is => 'ro',
    isa => 'ChangeCategory',
    coerce => 1,
    default => sub { [ 'BUG FIXES', 'DOCUMENTATION' ] },
    traits  => ['Array'],
    handles => { revision_groups => 'elements' },
);

sub before_release {
    my $self = shift;

    my ($changes_file) = grep { $_->name eq $self->change_file } @{ $self->zilla->files };

  my $changes = CPAN::Changes->load_string(
      $changes_file->content,
      next_token => qr/\{\{\$NEXT\}\}/
  );

  my( $next ) = reverse $changes->releases;

  my @changes = values %{ $next->changes };

  $self->log_fatal("change file has no content for next version")
    unless @changes;

}

sub after_release {
  my ($self) = @_;
  my $filename = $self->change_file;

  my $changes = CPAN::Changes->load(
      $self->change_file,
      next_token => qr/\{\{\$NEXT\}\}/
  );

  # remove empty groups
  $changes->delete_empty_groups;

  my ( $next ) = reverse $changes->releases;

  $next->add_group( grep { $_ ne 'UNGROUPED' } $self->all_groups );

  $self->log_debug([ 'updating contents of %s on disk', $filename ]);

  # and finally rewrite the changelog on disk
  open my $out_fh, '>', $filename
    or Carp::croak("can't open $filename for writing: $!");

  print $out_fh $changes->serialize;

  close $out_fh or Carp::croak("error closing $filename: $!");
}

sub all_groups {
    my $self = shift;

    return map { $self->$_ } map { $_.'_groups' } qw/ major minor revision /
}

has previous_version => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $plugins =
            $self->zilla->plugins_with('-YANICK::PreviousVersionProvider');

        $self->log_fatal(
            "at least one plugin with the role PreviousVersionProvider",
            "must be referenced in dist.ini"
        ) unless ref $plugins and @$plugins >= 1;

        for my $plugin ( @$plugins ) {
            my $version = $plugin->provide_previous_version;

            return $version if defined $version;
        }

        return undef;
    },
);

sub provide_version {
  my $self = shift;

  # override (or maybe needed to initialize)
  return $ENV{V} if exists $ENV{V};

  my $new_ver = $self->next_version( $self->previous_version);

  $self->zilla->version("$new_ver");
}

sub next_version {
    my( $self, $last_version ) = @_;


    my $new_ver = $self->increment_version( $self->increment_level );

    $new_ver = Perl::Version->new( $new_ver )->numify if $self->numify_version;

    no warnings;
    $self->log("Bumping version from $last_version to $new_ver");
    return $new_ver;
}

sub increment_level {
    my ( $self ) = @_;

    my ($changes_file) = grep { $_->name eq $self->change_file } @{ $self->zilla->files }
        or die "no changelog file found\n";

    my $changes = CPAN::Changes->load_string( $changes_file->content,
        next_token => qr/\{\{\$NEXT\}\}/ );

    my ($changelog) = reverse $changes->releases;

    my %category_map = (
        map( { $_ => 0 } $self->major_groups ),
        map( { $_ => 1 } $self->minor_groups ),
    );

    $category_map{''} = $category_map{UNGROUPED};

    no warnings;

    my $increment_level = min 
        grep { defined } 
        map  { $category_map{$_} }
        grep { scalar @{ $changelog->changes($_) } }  # only groups with items
        $changelog->groups;

    return (qw/MAJOR MINOR PATCH/)[$increment_level//2];
}

sub munge_files {
  my ($self) = @_;

  my ($file) = grep { $_->name eq $self->change_file } @{ $self->zilla->files };
  return unless $file;

  my $changes = CPAN::Changes->load_string( $file->content,
      next_token => qr/\{\{\$NEXT\}\}/
  );

  my ( $next ) = reverse $changes->releases;

  $next->delete_group($_) for grep { !@{$next->changes($_)} } $next->groups;

  $self->log_debug([ 'updating contents of %s in memory', $file->name ]);
  $file->content($changes->serialize);
}


__PACKAGE__->meta->make_immutable;
no Moose;

{
    package Dist::Zilla::Plugin::NextVersion::Semantic::Incrementer;
our $AUTHORITY = 'cpan:YANICK';
$Dist::Zilla::Plugin::NextVersion::Semantic::Incrementer::VERSION = '0.2.5';
use List::AllUtils qw/ first_index any /;

    use Moose::Role;

    requires 'previous_version', 'format';

    sub nbr_version_levels {
        my @tokens = $_[0]->format =~ /(%\d*d)/g;
        return scalar @tokens;
    }

    sub version_lenghts {
        return $_[0]->format =~ /%0*(\d*)/g;
    }

    sub increment_version {
        my( $self, $level ) = @_;
        $level ||= 'PATCH';

        my @version = (0,0,0);

        # initial version is special
        if ( my $previous = $self->previous_version ) {
            my $regex = quotemeta $self->format;
            $regex =~ s/\\%0(\d+)d/(\\d{$1})/g;
            $regex =~ s/\\%(\d+)d/(\\d{1,$1})/g;
            $regex =~ s/\\%d/(\\d+)/g;

            @version = $previous =~ m/$regex/
                or die "previous version '$previous' doesn't match format '@{[$self->format]}'" ;
        }

        my @levels = qw/ MAJOR MINOR PATCH /;
        my $index = first_index { $level eq $_ } @levels;

        $version[$index]++;
        $version[$_] = 0 for $index+1..2;

        # if the incremental level is below the number of levels we 
        # have, increment the lowest level we consider
        if( any { $version[$_] > 0 } $self->nbr_version_levels..2 ) {
            $version[ $self->nbr_version_levels -1 ]++;
            $version[$_] = 0 for $self->nbr_version_levels..2;
        }

        # exceeding sizes?
        my @sizes = $self->version_lenghts;
        for my $i ( grep { $sizes[$_] } reverse 0..2 ) {
            if ( length( $version[$i] ) > $sizes[$i] ) {
                $version[$i-1]++;
                $version[$i] = 0;
            }
        }

        no warnings; # possible redundant args for sprintf

        my $version = sprintf $self->format, @version;
        $version =~ y/ //d;

        return $version;
    }


}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::NextVersion::Semantic - update the next version, semantic-wise

=head1 VERSION

version 0.2.5

=head1 SYNOPSIS

    # in dist.ini

    [NextVersion::Semantic]
    major = MAJOR, API CHANGE
    minor = MINOR, ENHANCEMENTS
    revision = REVISION, BUG FIXES

    ; must also load a PreviousVersionProvider
    [PreviousVersion::Changelog]

=head1 DESCRIPTION

Increases the distribution's version according to the semantic versioning rules
(see L<http://semver.org/>) by inspecting the changelog.

More specifically, the plugin performs the following actions:

=over

=item at build time

Reads the changelog using C<CPAN::Changes> and filters out of the C<{{$NEXT}}>
release section any group without item.

=item before a release

Ensures that there is at least one recorded change in the changelog, and
increments the version number in consequence.   If there are changes given
outside of the sections, they are considered to be minor.

=item after a release

Updates the new C<{{$NEXT}}> section of the changelog with placeholders for
all the change categories.  With categories as given in the I<SYNOPSIS>,
this would look like

    {{$NEXT}}

      [MAJOR]

      [API CHANGE]

      [MINOR]

      [ENHANCEMENTS]

      [REVISION]

      [BUG FIXES]

=back

If a version is given via the environment variable C<V>, it will taken
as-if as the next version.

For this plugin to work, your L<Dist::Zilla> configuration must also contain a plugin
consuming the L<Dist::Zilla::Role::YANICK::PreviousVersionProvider> role.

In the different configuration attributes where change group names are given,
the special group name C<UNGROUPED> can be given to 
specify the nameless group.

    0.1.3 2013-07-18

    - this item will be part of UNGROUPED.

    [BUG FIXES]
    - this one won't.

=head1 PARAMETERS

=head2 change_file

File name of the changelog. Defaults to C<Changes>.

=head2 numify_version

If B<true>, the version will be a number using the I<x.yyyzzz> convention instead
of I<x.y.z>.  Defaults to B<false>.

=head2 format

Specifies the version format to use. Follows the '%d' convention of
C<sprintf> (see examples below), excepts for one detail: '%3d' won't pad 
with whitespaces, but will only determine the maximal size of the number. 
If a version component exceeds its given
size, the next version level will be incremented.

Examples:

    %d.%3d.%3d 
        PATCH LEVEL INCREASES: 0.0.998 -> 0.0.999 -> 0.1.0
        MINOR LEVEL INCREASES: 0.0.8 -> 0.1.0 -> 0.2.0
        MAJOR LEVEL INCREASES: 0.1.8 -> 1.0.0 -> 2.0.0

    %d.%02d%02d
        PATCH LEVEL INCREASES: 0.0098 -> 0.00099 -> 0.0100
        MINOR LEVEL INCREASES: 0.0008 -> 0.0100 -> 0.0200
        MAJOR LEVEL INCREASES: 0.0108 -> 1.0000 -> 2.0000

    %d.%05d
        MINOR LEVEL INCREASES: 0.99998 -> 0.99999 -> 1.00000
        MAJOR LEVEL INCREASES: 0.00108 -> 1.00000 -> 2.00000

Defaults to '%d.%3d.%3d'.

=head2 major

Comma-delimited list of categories of changes considered major.
Defaults to C<API CHANGES>.

=head2 minor

Comma-delimited list of categories of changes considered minor.
Defaults to C<ENHANCEMENTS> and C<UNGROUPED>.

=head2 revision

Comma-delimited list of categories of changes considered revisions.
Defaults to C<BUG FIXES, DOCUMENTATION>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
