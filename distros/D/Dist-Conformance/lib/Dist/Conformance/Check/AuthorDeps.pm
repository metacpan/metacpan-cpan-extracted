package Dist::Conformance::Check::AuthorDeps 0.011;

# ABSTRACT: dist.ini asks for each authordep of its template, at the version of the template or later

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
no autovivification;
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use version();

use Dist::Conformance::Check();
use Dist::Conformance::Schema();


my $VERSION_OR_OFF = { type => 'string', minLength => 1 };

sub config_schema ($) {
    return {
        required   => [qw{file template}],
        properties => {
            file      => $Dist::Conformance::Schema::PATH,
            template  => $Dist::Conformance::Schema::PATH,
            overrides => {
                type                 => 'object',
                propertyNames        => $Dist::Conformance::Check::MODULE,
                additionalProperties => $VERSION_OR_OFF,
                default              => {},
            },
            missing => { %$Dist::Conformance::Schema::STATUS, default => 'info' },
        },
    };
}

# The authordep lines of the INI text C<$text>, as C<dzil authordeps> reads
# them, in their order.
# @param   text  Str  the text of an INI file, such as F<dist.ini>
# @returns the lines, as a list of hash references with the C<line>, counted
# from 0, the C<module>, the C<version>, which is C<0> when the line has no
# C<=>, the C<from> and C<to> offsets of the version in the line, which are
# undef when it has none, and the offset C<after> the name of the module
# @example my @deps = Dist::Conformance::Check::AuthorDeps::authordeps_of( $snapshot->content('dist.ini') );
sub authordeps_of ($text) {
    my @lines = split /^/, $text;
    my @deps;
    for my $index ( 0 .. $#lines ) {
        my ( $module, $version ) = $lines[$index] =~ m/\A\s*;\s*authordep\s*(\S+)\s*(?:=\s*([^;]*[^;\s]))?/ or next;
        my %dep = ( line => $index, module => $module, version => $version // 0, after => $+[1] );
        @dep{qw{from to}} = ( $-[2], $+[2] ) if defined $version;
        push @deps, \%dep;
    }
    return @deps;
}

# What the repository in C<$snapshot> must ask for: the authordeps of the
# template with the overrides, by module, in the order of the template, and
# then the modules that only the overrides name, sorted.  A module that the
# repository has under F<lib/> is left out.
# @param   snapshot  InstanceOf["Dist::Conformance::Snapshot"]  the repository
# @returns the authordeps, as a list of hash references with the C<module>, the
# C<version>, and the C<text> of the line to add for it
# @throws  when the source has no template, with the message of
# L<Dist::Conformance::Source/"file(relative)">
# @example my @wanted = $check->wanted($snapshot);
sub wanted ( $self, $snapshot ) {
    my $config    = $self->config;
    my $overrides = $config->{overrides};
    my ($text)    = $self->template( $config->{template} );
    my @lines     = split /^/, $text;
    my @named     = ( ( map { $_->{module} } authordeps_of($text) ), keys %$overrides );
    my %seen      = map { $_ => 1 } grep { local ($_) = $_; own_module( $snapshot, $_ ) } @named;
    my @wanted;
    for my $dep ( authordeps_of($text) ) {
        my $module = $dep->{module};
        next if $seen{$module}++;
        my $override = $overrides->{$module};
        next if defined $override && $override eq 'off';
        my $line = $lines[ $dep->{line} ] =~ s/\n?\z/\n/r;
        push @wanted, defined $override ? authordep_line( $module, $override ) : { module => $module, version => $dep->{version}, text => $line };
    }
    for my $module ( sort grep { !$seen{$_} && $overrides->{$_} ne 'off' } keys %$overrides ) {
        push @wanted, authordep_line( $module, $overrides->{$module} );
    }
    return @wanted;
}

# Whether the repository in C<$snapshot> has the module C<$module> under
# F<lib/>, so that it builds with its own copy.
# @param   snapshot  InstanceOf["Dist::Conformance::Snapshot"]  the repository, or undef for none
# @param   module    Str  the name of the module
# @returns Bool
# @example my $own = own_module( $snapshot, 'Foo::Bar' );
sub own_module ( $snapshot, $module ) {
    return 0 if !$snapshot;
    return $snapshot->contains( 'lib/' . ( $module =~ s{::}{/}gr ) . '.pm' ) ? 1 : 0;
}

# The text C<$text> with its authordeps as C<$overrides> says, exactly: a
# module that is C<off>, or that the repository in C<$snapshot> has under
# F<lib/>, loses its lines; a version replaces that of the lines; and a module
# that the text lacks gets a line after its last authordep line, or at its end.
# Every other line stays as it was.
# @param   text       Str      the text of the file
# @param   overrides  HashRef  from the name of a module to C<off> or a version
# @param   snapshot   InstanceOf["Dist::Conformance::Snapshot"]  optional: the repository
# @returns Str  the new text
# @example my $text = with_overrides( $template, { 'Foo::Bar' => '1.2' }, $snapshot );
sub with_overrides ( $text, $overrides, $snapshot = undef ) {
    my @lines = split /^/, $text;
    my ( %seen, %drop );
    for my $dep ( authordeps_of($text) ) {
        my $module   = $dep->{module};
        my $override = $overrides->{$module};
        $seen{$module} = 1;
        if ( own_module( $snapshot, $module ) || ( defined $override && $override eq 'off' ) ) {
            $drop{ $dep->{line} } = 1;
            next;
        }
        next if !defined $override;
        my $line = \$lines[ $dep->{line} ];
        if ( defined $dep->{from} ) {
            substr $$line, $dep->{from}, $dep->{to} - $dep->{from}, $override;
        }
        else {
            substr $$line, $dep->{after}, 0, " = $override";
        }
    }
    my @add = map { authordep_line( $_, $overrides->{$_} )->{text} } grep { !$seen{$_} && $overrides->{$_} ne 'off' && !own_module( $snapshot, $_ ) } sort keys %$overrides;
    my @kept;
    my $last;
    for my $index ( 0 .. $#lines ) {
        next if $drop{$index};
        push @kept, $lines[$index];
        $last = $#kept if $lines[$index] =~ m/\A\s*;\s*authordep\s/;
    }
    if (@add) {
        my $after = $last // $#kept;
        $kept[$after] .= "\n" if $after >= 0 && $kept[$after] !~ m/\n\z/;
        splice @kept, $after + 1, 0, @add;
    }
    return join q{}, @kept;
}

# How the authordeps of the text C<$have> differ from those of C<$want>, as
# phrases for a person.
# @param   have  Str  the text that the repository has
# @param   want  Str  the text that it must have
# @returns the phrases, as a list, which is empty when both ask for the same
# @example my @differences = authordep_differences( $text, $expected );
sub authordep_differences ( $have, $want ) {
    my %have = map { $_->{module} => $_->{version} } authordeps_of($have);
    my %want = map { $_->{module} => $_->{version} } authordeps_of($want);
    return (
        ( map { "lacks the authordep $_ $want{$_}" } grep { !exists $have{$_} } sort keys %want ),
        ( map { "asks for $_ $have{$_}, not $want{$_}" } grep { exists $have{$_} && $have{$_} ne $want{$_} } sort keys %want ),
        ( map { "has the authordep $_, which neither the template nor the overrides name" } grep { !exists $want{$_} } sort keys %have ),
    );
}

# The authordep of C<$module> at C<$version>, and its line.
# @param   module   Str  the name of the module
# @param   version  Str  the version to ask for
# @returns HashRef  with the C<module>, the C<version> and the C<text>
# @example my $dep = authordep_line( 'Foo::Bar', '1.2' );
sub authordep_line ( $module, $version ) {
    return { module => $module, version => $version, text => "; authordep $module = $version\n" };
}

# Whether version C<$have> is at least version C<$want>, or undef when either
# is not a version that can be compared, such as a range.
# @param   have  Str  the version that a line asks for
# @param   want  Str  the version that it must ask for
# @returns Bool  or undef
# @example my $enough = at_least( '0.003', '0.004' );    # 0
sub at_least ( $have, $want ) {
    return if !version::is_lax($have) || !version::is_lax($want);
    return version->parse($have) >= version->parse($want) ? 1 : 0;
}

# How the authordeps of the INI text C<$text> differ from what the repository
# in C<$snapshot> must ask for.
# @param   text      Str  the text of the file
# @param   snapshot  InstanceOf["Dist::Conformance::Snapshot"]  the repository
# @returns HashRef  with C<missing>, the wanted authordeps that no line asks
# for; C<low>, the lines that ask for too little, each with the C<want> that
# they must ask for; and C<unknown>, the lines whose version cannot be
# compared, each with its C<want>.  Each is an ArrayRef, in the order of the
# file or of the template.
# @throws  when the source has no template, as L<wanted|/"wanted(snapshot)"> says
# @example my $differences = $check->differences( $snapshot->content('dist.ini'), $snapshot );
sub differences ( $self, $text, $snapshot ) {
    my %have;
    push @{ $have{ $_->{module} } }, $_ for authordeps_of($text);
    my %differences = ( missing => [], low => [], unknown => [] );
    for my $want ( $self->wanted($snapshot) ) {
        my $lines = $have{ $want->{module} };
        if ( !$lines ) {
            push @{ $differences{missing} }, $want;
            next;
        }
        for my $line (@$lines) {
            my $enough = at_least( $line->{version}, $want->{version} );
            push @{ $differences{ defined $enough ? 'low' : 'unknown' } }, { %$line, want => $want->{version} } if !$enough;
        }
    }
    return \%differences;
}

sub check ( $self, $snapshot ) {
    my $file        = $self->config->{file};
    my $text        = $snapshot->content($file)                       // return ( $self->config->{missing}, "there is no $file" );
    my $differences = eval { $self->differences( $text, $snapshot ) } // return ( 'fail',                   Dist::Conformance::Schema::first_line($@) );
    my @problems    = (
        ( map { "lacks $_->{module} $_->{version}" } @{ $differences->{missing} } ),
        ( map { "asks for $_->{module} $_->{version}, not $_->{want}" } @{ $differences->{low} } ),
        ( map { "asks for $_->{module} $_->{version}, which cannot be compared with $_->{want}" } @{ $differences->{unknown} } ),
    );
    return ( 'pass', 'asks for each authordep of the template, at its version or later' ) if !@problems;
    return ( 'fail', "$file " . join '; ', @problems );
}

sub update ( $self, $update ) {
    my $file        = $self->config->{file};
    my $snapshot    = $update->snapshot;
    my $text        = $snapshot->content($file) // return;
    my $differences = eval { $self->differences( $text, $snapshot ) };
    if ( !$differences ) {
        $update->by_hand( Dist::Conformance::Schema::first_line($@) . ': fix it by hand' );
        return;
    }
    foreach my $unknown ( @{ $differences->{unknown} } ) {
        $update->by_hand("In $file, make the authordep of $unknown->{module} ask for $unknown->{want} or later: its version $unknown->{version} cannot be compared");
    }

    my @lines = split /^/, $text;
    for my $low ( @{ $differences->{low} } ) {
        my $line = \$lines[ $low->{line} ];
        if ( defined $low->{from} ) {
            substr $$line, $low->{from}, $low->{to} - $low->{from}, $low->{want};
        }
        else {
            substr $$line, $low->{after}, 0, " = $low->{want}";
        }
    }
    if ( my @add = map { $_->{text} } @{ $differences->{missing} } ) {
        my @deps  = authordeps_of($text);
        my $after = @deps ? $deps[-1]{line} : $#lines;
        $lines[$after] .= "\n" if $after >= 0 && $lines[$after] !~ m/\n\z/;
        splice @lines, $after + 1, 0, @add;
    }
    $update->write( $file, join q{}, @lines );
    return;
}

sub adopt ( $self, $snapshot ) {
    my $text        = $snapshot->content( $self->config->{file} ) // return;
    my $differences = $self->differences( $text, $snapshot );
    my %overrides   = (
        ( map { $_->{module} => 'off' } @{ $differences->{missing} } ),
        ( map { $_->{module} => $_->{version} } @{ $differences->{low} }, @{ $differences->{unknown} } ),
    );
    return if !%overrides;
    return { overrides => { %{ $self->config->{overrides} }, %overrides } };
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::AuthorDeps - dist.ini asks for each authordep of its template, at the version of the template or later

=head1 VERSION

version 0.011

=head1 DESCRIPTION

An C<; authordep Module = version> line of F<dist.ini> names a module that
C<dzil authordeps> installs before a build, and the least version that the
build needs.  A template of F<dist.ini> raises such a version when the build
starts to need a fix of a newer release.  A repository whose F<dist.ini> came
from an older template still asks for the older release, and nothing else
tells it otherwise: L<Dist::Conformance::Check::ToolConfiguration> never
replaces a F<dist.ini> that exists, because the rest of the file is the
repository's own.

This check compares the authordeps of C<file> with those of C<template>.  It
fails for each authordep of the template that the file does not ask for, and
for each that the file asks for at a lower version, and the detail names each
one.  An authordep of the file that the template does not have is the
repository's own, and the check leaves it alone, as it does one that asks for a
higher version.  A line without C<=> asks for version 0.

An authordep of a module that the repository has under F<lib/> is not wanted,
whatever the template says: a distribution builds with its own modules, as
the build of Pod::Coverage::More runs its own C<[Blurbs]>.

The lines are read as C<dzil authordeps> reads them: a comment that starts
with C<authordep>, the name of the module, and an optional C<=> and version.
So the check compares what C<dzil authordeps> installs.  A version that is not
a plain decimal or dotted version, such as a range, cannot be compared, so the
check fails for it and the update leaves it to a person.

The update raises the version of each line that asks for too little, and
changes nothing else on that line.  It adds each authordep that is missing
after the last authordep line of the file, in the order of the template, or at
the end of a file that has none.  Every other line, every comment and the order
stay as they were.  A comment above a raised line that gives the reason for the
old version is not changed: the update cannot know what it says.

=head1 METHODS

=head2 at_least(have, want)

Whether version C<$have> is at least version C<$want>, or undef when either is not a version that can be compared, such as a range.

=over 4

=item have - Str - the version that a line asks for

=item want - Str - the version that it must ask for

=back

Returns Bool, or undef.

    my $enough = at_least( '0.003', '0.004' );    # 0

=head2 authordep_differences(have, want)

How the authordeps of the text C<$have> differ from those of C<$want>, as phrases for a person.

=over 4

=item have - Str - the text that the repository has

=item want - Str - the text that it must have

=back

Returns the phrases, as a list, which is empty when both ask for the same.

    my @differences = authordep_differences( $text, $expected );

=head2 authordep_line(module, version)

The authordep of C<$module> at C<$version>, and its line.

=over 4

=item module - Str - the name of the module

=item version - Str - the version to ask for

=back

Returns HashRef, with the C<module>, the C<version> and the C<text>.

    my $dep = authordep_line( 'Foo::Bar', '1.2' );

=head2 authordeps_of(text)

The authordep lines of the INI text C<$text>, as C<dzil authordeps> reads them, in their order.

=over 4

=item text - Str - the text of an INI file, such as F<dist.ini>

=back

Returns the lines, as a list of hash references with the C<line>, counted from 0, the C<module>, the C<version>, which is C<0> when the line has no C<=>, the C<from> and C<to> offsets of the version in the line, which are undef when it has none, and the offset C<after> the name of the module.

    my @deps = Dist::Conformance::Check::AuthorDeps::authordeps_of( $snapshot->content('dist.ini') );

=head2 differences(text, snapshot)

How the authordeps of the INI text C<$text> differ from what the repository in C<$snapshot> must ask for.

=over 4

=item text - Str - the text of the file

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - the repository

=back

Returns HashRef, with C<missing>, the wanted authordeps that no line asks for; C<low>, the lines that ask for too little, each with the C<want> that they must ask for; and C<unknown>, the lines whose version cannot be compared, each with its C<want>.  Each is an ArrayRef, in the order of the file or of the template.

Dies when the source has no template, as L<wanted|/"wanted(snapshot)"> says.

    my $differences = $check->differences( $snapshot->content('dist.ini'), $snapshot );

=head2 own_module(snapshot, module)

Whether the repository in C<$snapshot> has the module C<$module> under F<lib/>, so that it builds with its own copy.

=over 4

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - the repository, or undef for none

=item module - Str - the name of the module

=back

Returns Bool.

    my $own = own_module( $snapshot, 'Foo::Bar' );

=head2 wanted(snapshot)

What the repository in C<$snapshot> must ask for: the authordeps of the template with the overrides, by module, in the order of the template, and then the modules that only the overrides name, sorted.  A module that the repository has under F<lib/> is left out.

=over 4

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - the repository

=back

Returns the authordeps, as a list of hash references with the C<module>, the C<version>, and the C<text> of the line to add for it.

Dies when the source has no template, with the message of L<Dist::Conformance::Source/"file(relative)">.

    my @wanted = $check->wanted($snapshot);

=head2 with_overrides(text, overrides, snapshot)

The text C<$text> with its authordeps as C<$overrides> says, exactly: a module that is C<off>, or that the repository in C<$snapshot> has under F<lib/>, loses its lines; a version replaces that of the lines; and a module that the text lacks gets a line after its last authordep line, or at its end. Every other line stays as it was.

=over 4

=item text - Str - the text of the file

=item overrides - HashRef - from the name of a module to C<off> or a version

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - optional: the repository

=back

Returns Str, the new text.

    my $text = with_overrides( $template, { 'Foo::Bar' => '1.2' }, $snapshot );

=head1 IN A FLAVOR

    checks:
      AuthorDeps:
        file: dist.ini
        template: templates/dist.ini

And in F<.conformance.yml>, what a repository asks for otherwise:

    checks:
      AuthorDeps:
        overrides:
          Pod::Weaver::Section::Blurbs: off
          Perl::Tests::Covering: '0.001'

=head1 CONFIGURATION

=over

=item file

Required.  The path of F<dist.ini>.

=item template

Required.  The template that it is compared with.

=item overrides

What the repository asks for otherwise than the template, by module: C<off>
to leave an authordep of the template out, or a version to ask for in place of
the template's, lower or higher.  Default none.  An override of a module that
the template does not have adds that authordep.

=item missing

The status when the file is absent.  Default C<info>, because a repository
without the file is not a Dist::Zilla distribution.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=item *

L<Dist::Conformance::Check::CriticProfile>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Dist-Conformance/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
