package Developer::Dashboard::EnvInclude;

use strict;
use warnings;

our $VERSION = '5.51';

use File::Spec;
use Developer::Dashboard::DirEntries qw(sorted_dir_entries);
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::PathRegistry;

# include($spec)
# Includes one named skill's (or, with a trailing ".*", one skill and every
# nested sub-skill's) .env and .env.pl files into the current process
# environment, namespacing every included variable under the skill's dotted
# depth path converted to UPPERCASE with double underscores separating the
# namespace from the variable name (foo.bar's BOB=1 becomes FOO_BAR__BOB).
# Every DD-OOP-LAYER that has the named skill installed contributes its own
# copy, applied from home toward the deepest layer so a deeper layer's value
# for the same key wins without dropping a shallower layer's own key.
# Input: dotted skill path string, optionally suffixed with ".*".
# Output: ordered array reference of the env files that were loaded.
sub include {
    my ( $class, $spec ) = @_;
    die "Missing skill path\n" if !defined $spec || $spec eq '';
    my $paths = Developer::Dashboard::PathRegistry->new;
    my @loaded;
    for my $target ( $class->_resolve_targets( $paths, $spec ) ) {
        push @loaded, @{ $class->_include_one( $target->{dir}, $target->{name} ) };
    }
    return \@loaded;
}

# _resolve_targets($paths, $spec)
# Resolves one include spec into the ordered set of concrete skill
# directories it names, across every DD-OOP-LAYER that has that skill
# installed, from home toward the deepest layer.
# Input: path registry object and the raw include spec string.
# Output: ordered list of hash references with dir and dotted name.
sub _resolve_targets {
    my ( $class, $paths, $spec ) = @_;
    my $recursive = ( $spec =~ s/\.\*\z// ) ? 1 : 0;
    my @segments = grep { $_ ne '' } split /\./, $spec;
    return () if !@segments;
    return () if grep { !$class->_valid_segment($_) } @segments;

    my @matches;
    for my $skills_root ( reverse $paths->skills_roots ) {
        my $dir = File::Spec->catdir( $skills_root, $segments[0] );
        next if !-d $dir;
        my $ok = 1;
        for my $seg ( @segments[ 1 .. $#segments ] ) {
            $dir = File::Spec->catdir( $dir, 'skills', $seg );
            if ( !-d $dir ) { $ok = 0; last }
        }
        next if !$ok;
        my $name = join( '.', @segments );
        push @matches, { dir => $dir, name => $name };
        push @matches, $class->_recursive_sub_skills( $dir, $name ) if $recursive;
    }
    return @matches;
}

# _valid_segment($segment)
# Rejects any dotted-spec segment that could smuggle a path-traversal or
# absolute-path component through File::Spec->catdir - a defense-in-depth
# guard: splitting the spec on "." already structurally cannot preserve a
# literal ".." token (the two dots become empty, filtered segments), but a
# lone "/" segment (from a spec like "../..") or a segment carrying an
# embedded "/" survives that split, so it is rejected here explicitly rather
# than relying on the emergent property of how the split happens to behave.
# Input: one candidate segment string.
# Output: boolean true when the segment is a safe single path component.
sub _valid_segment {
    my ( $class, $segment ) = @_;
    return 0 if !defined $segment || $segment eq '';
    return 0 if $segment eq '.' || $segment eq '..';
    return 0 if $segment =~ m{[/\\]};
    return 0 if $segment =~ /[\x00-\x1F\x7F]/;
    return 1;
}

# _recursive_sub_skills($dir, $name)
# Expands one matched skill directory into every nested sub-skill directory
# beneath its own skills/ subdirectory, recursively.
# Input: matched skill directory path and its dotted name.
# Output: ordered list of hash references with dir and dotted name.
sub _recursive_sub_skills {
    my ( $class, $dir, $name ) = @_;
    my $skills_dir = File::Spec->catdir( $dir, 'skills' );
    return () if !-d $skills_dir;
    my @out;
    opendir my $dh, $skills_dir or die "Unable to read $skills_dir: $!";
    for my $entry ( sorted_dir_entries($dh) ) {
        my $sub_dir = File::Spec->catdir( $skills_dir, $entry );
        next if !-d $sub_dir;
        my $sub_name = "$name.$entry";
        push @out, { dir => $sub_dir, name => $sub_name };
        push @out, $class->_recursive_sub_skills( $sub_dir, $sub_name );
    }
    closedir $dh;
    return @out;
}

# _include_one($dir, $name)
# Loads one skill directory's .env and .env.pl files in isolation and merges
# only the resulting changes into the real process environment under the
# namespaced key.
# Input: skill directory path and its dotted name.
# Output: array reference of the env files that were loaded.
sub _include_one {
    my ( $class, $dir, $name ) = @_;
    require Developer::Dashboard::EnvLoader;
    my @files = (
        File::Spec->catfile( $dir, '.env' ),
        File::Spec->catfile( $dir, '.env.pl' ),
    );
    my $result = Developer::Dashboard::EnvLoader->load_files_into_hash( files => \@files );
    my $prefix = $class->_namespace_prefix($name);
    for my $key ( sort keys %{ $result->{env} } ) {
        next if $key eq 'DEVELOPER_DASHBOARD_ENV_AUDIT';
        my $value = $result->{env}{$key};
        my $target_key = $prefix eq '' ? $key : "${prefix}__${key}";
        $ENV{$target_key} = $value;
        Developer::Dashboard::EnvAudit->record( $target_key, $value, "include:$name" );
    }
    return $result->{files};
}

# _namespace_prefix($name)
# Converts one dotted skill depth path into its UPPERCASE, single-underscore
# joined namespace prefix (foo.bar becomes FOO_BAR).
# Input: dotted skill path string.
# Output: normalized uppercase namespace prefix string.
sub _namespace_prefix {
    my ( $class, $name ) = @_;
    return uc(
        join( '_',
            map {
                my $segment = $_;
                $segment =~ s/[^A-Za-z0-9]+/_/g;
                $segment =~ s/\A_+|_+\z//g;
                $segment;
            } split( /\./, $name )
        )
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Developer::Dashboard::EnvInclude - pull one skill's env files into the current environment, namespaced

=head1 SYNOPSIS

  use Developer::Dashboard::EnvInclude;

  Developer::Dashboard::EnvInclude->include('foo.bar');
  Developer::Dashboard::EnvInclude->include('foo.bar.*');

=head1 DESCRIPTION

Resolves a dotted skill path (C<foo.bar> for a nested sub-skill C<bar> under
top-level skill C<foo>) against every installed DD-OOP-LAYER, loads that
skill's C<.env> and C<.env.pl> files in isolation, and merges only the
resulting new or changed keys into the real process environment under a
namespaced key: the dotted path uppercased with single underscores joining
its own segments, then a double underscore, then the original variable name
(C<foo.bar>'s C<BOB=1> becomes C<$FOO_BAR__BOB>). A trailing C<.*> segment
additionally includes every nested sub-skill beneath the named skill,
recursively.

This is the engine behind two callers: the C<# include E<lt>foo.barE<gt>>
comment directive C<Developer::Dashboard::EnvLoader> recognizes in plain
C<.env> files, and the C<env-E<gt>include(...)> method C<.env.pl> files can
call directly after C<use Developer::Dashboard;> (see the C<env> package in
F<lib/Developer/Dashboard.pm>).

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module resolves and loads one named skill's environment files on demand, independent of the normal ancestor-directory env-layer chain, so a C<.env>/C<.env.pl> file can deliberately pull in another skill's variables under a namespaced key.

=head1 WHY IT EXISTS

The normal layered env loading only ever walks ancestor directories toward the current working directory. This module exists for the opposite case: reaching sideways or across the tree to a specific named skill by its dotted path, on request, with the result kept clearly namespaced so it can never silently collide with the including file's own variables.

=head1 WHEN TO USE

Use this when a C<.env> or C<.env.pl> file needs another skill's configuration values available under a predictable, namespaced key, rather than relying on that skill happening to be an ancestor directory in the normal load chain.

=head1 HOW TO USE

From a plain C<.env> file, write C<# include E<lt>foo.barE<gt>> (or C<# include E<lt>foo.bar.*E<gt>> to also pull in every sub-skill beneath it) on its own line. From a C<.env.pl> file, call C<env-E<gt>include('foo.bar')> after C<use Developer::Dashboard;>.

=head1 WHAT USES IT

C<Developer::Dashboard::EnvLoader> (the C<.env> comment-directive path) and the C<env> package in F<lib/Developer/Dashboard.pm> (the C<.env.pl> programmatic path).

=head1 EXAMPLES

Example 1:

  Developer::Dashboard::EnvInclude->include('foo.bar');

Loads skill C<foo>'s nested C<bar> sub-skill's C<.env>/C<.env.pl> across every DD-OOP-LAYER that has it installed, namespacing every resulting variable as C<FOO_BAR__E<lt>nameE<gt>>.

Example 2:

  Developer::Dashboard::EnvInclude->include('foo.bar.*');

Same as above, plus every sub-skill nested beneath C<foo.bar>, each namespaced under its own deeper dotted path.

=for comment FULL-POD-DOC END

=cut
