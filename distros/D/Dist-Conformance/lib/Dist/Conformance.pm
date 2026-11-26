package Dist::Conformance 0.011;

# ABSTRACT: Whether the development harness of a repository conforms to its standards, and bringing it up to date

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
no autovivification;
use Mojo::Base -base, -signatures;

use List::Util();
use Module::Runtime();
use Mojo::File();

use Dist::Conformance::Check();
use Dist::Conformance::Config();
use Dist::Conformance::Flavor();
use Dist::Conformance::Schema();
use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Source::Directory();
use Dist::Conformance::Source::Git();
use Dist::Conformance::Update();


has 'root';
has snapshot => sub ($self) {
    die "Dist::Conformance needs a root or a snapshot\n" if !defined $self->root;
    return Dist::Conformance::Snapshot::Directory->new( root => $self->root );
};
has config => sub ($self) { Dist::Conformance::Config::load( $self->snapshot ) };
has 'cache';
has offline => 0;
has 'standards';
has source => sub ($self) { $self->build_source };
has flavor => sub ($self) { Dist::Conformance::Flavor->load( $self->source, $self->config->{flavor} ) };

# The source that the C<source> key of the configuration describes, with
# L</standards>, L</cache> and L</offline> applied: a directory for
# L</standards> or for C<directory>, and else a git repository.
# @returns InstanceOf["Dist::Conformance::Source"]  the new source
# @example my $source = $conformance->build_source;
sub build_source ($self) {
    my $config = $self->config->{source};
    my %path   = ( path => $config->{path} // q{} );
    if ( defined $self->standards ) {
        return Dist::Conformance::Source::Directory->new( directory => $self->standards, %path );
    }
    if ( defined $config->{git} ) {
        my %options = ( url => $config->{git}, offline => $self->offline, %path );
        $options{ref}   = $config->{ref} if defined $config->{ref};
        $options{cache} = $self->cache   if defined $self->cache;
        return Dist::Conformance::Source::Git->new(%options);
    }
    my $directory = Mojo::File->new( $config->{directory} );
    $directory = Mojo::File->new( $self->root )->child( $config->{directory} ) if !$directory->is_abs && defined $self->root;
    return Dist::Conformance::Source::Directory->new( directory => "$directory", %path );
}

# The names of the checks that F<.conformance.yml> skips.
# @returns HashRef  from the name of each skipped check to 1
# @throws  when F<.conformance.yml> skips or configures a check that the flavor
# does not run, with a message that starts with C<.conformance.yml is not valid:>
# @example my $skipped = $conformance->skipped;
sub skipped ($self) {
    my $config = $self->config;
    my $flavor = $self->flavor;
    my %runs   = map { $_ => 1 } $flavor->check_names;
    my @wrong  = (
        ( map { "/skip/$_" } grep { !$runs{ $config->{skip}[$_] } } 0 .. $#{ $config->{skip} } ),
        ( map { "/checks/$_" } grep { !$runs{$_} } sort keys %{ $config->{checks} } ),
    );
    if (@wrong) {
        my $name = $flavor->name;
        Dist::Conformance::Schema::refuse( $Dist::Conformance::Config::FILE, map { "$_: names a check that the flavor $name does not run" } @wrong );
    }
    return { map { $_ => 1 } @{ $config->{skip} } };
}

# The L<Dist::Conformance::Check> objects that run, in order, with the
# configuration of the flavor and of F<.conformance.yml> merged and validated.
# Memoized.
# @returns ArrayRef[InstanceOf["Dist::Conformance::Check"]]  the checks
# @throws  on a check whose module does not load or is not a check, and on a
# configuration that its schema refuses; each message names the check and the
# flavor
# @example say $_->name for @{ $conformance->checks };
sub checks ($self) {
    return $self->{checks} //= do {
        my $flavor  = $self->flavor;
        my $skipped = $self->skipped;
        my %merged  = %{ $flavor->checks };
        Dist::Conformance::Flavor::merge_checks( \%merged, $self->config->{checks} );
        my %variables = ( %{ $flavor->variables }, %{ $self->config->{variables} } );
        [
            map  { local ($_) = $_; $self->make_check( $_, $merged{$_}, \%variables ) }
            grep { !$skipped->{$_} } $flavor->check_names
        ];
    };
}

# The check C<$name> of the flavor, from its merged configuration.
# @param   name       Str      the name of the check in the flavor
# @param   config     HashRef  its merged configuration, with C<module> when the module is not
# the name
# @param   variables  HashRef  the values of the placeholders of the templates
# @returns InstanceOf["Dist::Conformance::Check"]  the check
# @throws  when the module of the check is not the name of a module, does not
# load, or is not a L<Dist::Conformance::Check>, and when the schema of the check
# refuses the configuration
# @example my $check = $conformance->make_check( 'ClaudeMd', { file => 'CLAUDE.md', mentions => [] }, {} );
sub make_check ( $self, $name, $config, $variables ) {
    my $flavor = $self->flavor->name;
    my $module = $config->{module} // $name;
    my $class  = index( $module, '::' ) >= 0 ? $module : "Dist::Conformance::Check::$module";
    if ( !Dist::Conformance::Schema::matches( $Dist::Conformance::Check::MODULE, $class ) ) {
        die "The flavor $flavor runs the check $name, but $class is not the name of a module\n";
    }
    if ( !eval { Module::Runtime::require_module($class); 1 } ) {
        die( "The flavor $flavor runs the check $name, but its module $class does not load: " . Dist::Conformance::Schema::first_line($@), "\n" );
    }
    die "The flavor $flavor runs the check $name, but $class is not a Dist::Conformance::Check\n" if !$class->isa('Dist::Conformance::Check');
    my $repo = exists $self->config->{checks}{$name} ? " with $Dist::Conformance::Config::FILE" : q{};
    return $class->from_config(
        name      => $name,
        config    => $config,
        source    => $self->source,
        variables => $variables,
        where     => "the check $name of the flavor $flavor$repo",
    );
}

our %STATUSES = map { $_ => 1 } qw{pass fail info};

# Runs every check of the flavor against the snapshot.
#
# A check that dies, or returns a status that is not one of the three, fails, and
# its detail says so.  A failure of a check at C<level: info> is reported as
# C<info>.
# @returns ArrayRef  of hash references, one for each check of the flavor, in the order of
# their names: C<check>, the name; C<status>, which is C<pass>, C<fail>, C<info>,
# or C<skip> for a check that F<.conformance.yml> skips; and C<detail>
# @throws  when the checks cannot be made, as L</checks> says
# @example my $results = $conformance->check;
sub check ($self) {
    my $snapshot = $self->snapshot;
    my %run      = map { local ($_) = $_; $_->name => $_ } @{ $self->checks };
    my @results;
    for my $name ( $self->flavor->check_names ) {
        my $check = $run{$name};
        if ( !$check ) {
            push @results, { check => $name, status => 'skip', detail => "skipped by $Dist::Conformance::Config::FILE" };
            next;
        }
        my ( $status, $detail ) = eval { $check->check($snapshot) };
        if ( !defined $status ) {
            ( $status, $detail ) = ( 'fail', 'the check died: ' . Dist::Conformance::Schema::first_line($@) );
        }
        elsif ( !$STATUSES{$status} ) {
            ( $status, $detail ) = ( 'fail', "the check returned the status $status, which is not pass, fail or info" );
        }
        $status = 'info' if $status eq 'fail' && $check->config->{level} eq 'info';
        push @results, { check => $name, status => $status, detail => $detail // q{} };
    }
    return \@results;
}

# Runs the update of every check that is not skipped on the checkout, after
# fetching the standards when the source is git.  A check whose update dies has
# the error in C<manual>, and the other checks still run.
# @param   dry_run  Bool  optional: when true, writes nothing, and says what it would write
# @returns ArrayRef  of hash references, one for each check that ran, in order: C<check>, the
# name; C<changes>, what it changed or would change, each with an C<action> and a
# C<path>; and C<manual>, what is left for a person
# @throws  when the checks cannot be made, as L</checks> says
# @example my $results = $conformance->update( dry_run => 1 );
sub update ( $self, %options ) {
    my @results;
    for my $check ( @{ $self->checks } ) {
        my $update = Dist::Conformance::Update->new( snapshot => $self->snapshot, dry_run => $options{dry_run} // 0 );
        if ( !eval { $check->update($update); 1 } ) {
            $update->by_hand( 'The update died: ' . Dist::Conformance::Schema::first_line($@) );
        }
        push @results, { check => $check->name, changes => $update->changes, manual => $update->manual };
    }
    return \@results;
}

# Asks every check that is not skipped what configuration would accept the
# checkout as it is now, through L<Dist::Conformance::Check/adopt>.
# @returns HashRef  from the name of each check that has an answer to the answer,
# which is what the check would take under C<checks> in F<.conformance.yml>
# @throws  when the checks cannot be made, as L</checks> says, and when the adopt
# of a check dies
# @example my $adopted = $conformance->adopt;
sub adopt ($self) {
    my $snapshot = $self->snapshot;
    my %adopted;
    for my $check ( @{ $self->checks } ) {
        my $answer = $check->adopt($snapshot) // next;
        $adopted{ $check->name } = $answer;
    }
    return \%adopted;
}


sub failed ($results) {
    return List::Util::any { $_->{status} eq 'fail' } @$results;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance - Whether the development harness of a repository conforms to its standards, and bringing it up to date

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance;

    my $conformance = Dist::Conformance->new( root => '/bogus/checkout' );
    for my $result ( @{ $conformance->check } ) {
        say join "\t", @{$result}{qw{status check detail}};
    }

    my $plan = $conformance->update( dry_run => 1 );
    say "$_->{action} $_->{path}" for map { @{ $_->{changes} } } @$plan;

=head1 DESCRIPTION

Dist::Conformance answers one question about a repository: does its
development harness conform to the standards of an organization, and if not,
can the tool bring it up to date?

The harness is everything around the code that makes working on it safe: the
agent's instructions in F<CLAUDE.md>, the perlcritic profile and the
configuration of the other tools, the git hooks that run them, the files that
the build needs, and the Claude Code settings that load the right plugin.

Four pieces answer the question:

=over

=item The standards

A tree of flavor files and templates, in a git repository that is fetched into
a cache, or in a directory.  See L<Dist::Conformance::Source>, and the layout
in L<Dist::Conformance::Flavor/THE STANDARDS REPOSITORY>.

=item A flavor

A named set of checks with their configuration, which builds on other flavors
with C<extends>.  There is one for each kind of repository: a distribution on a
perl you control, one on an installed perl, a deployed service.  See
L<Dist::Conformance::Flavor>.

=item The choice of the repository

F<.conformance.yml> at the root of the repository names its flavor and source,
the checks it skips, and what it sets differently.  See
L<Dist::Conformance::Config>.

=item The checks

One module for each question, each told by its configuration what to expect.
Each can check a snapshot of a repository, local or remote, and update a local
checkout.  See L<Dist::Conformance::Check>, which also says how to write one.

=back

The program L<conformance> runs all of this from the shell.

=head1 ATTRIBUTES

=head2 root

The directory of a checkout.  Required unless L</snapshot> is given; L<update|/"update(dry_run)">
needs it.

=head2 snapshot

The L<Dist::Conformance::Snapshot> to check.  Default a
L<Dist::Conformance::Snapshot::Directory> of L</root>.  For a repository that
is not on this machine, pass a L<Dist::Conformance::Snapshot::Tree>.

=head2 config

The validated F<.conformance.yml>.  Default the file of the snapshot.  A caller
that has the configuration from somewhere else passes it through
L<Dist::Conformance::Config/"validate($data)">.

=head2 cache

The cache directory of a git source.  Default as
L<Dist::Conformance::Source::Git/cache> says.

=head2 offline

When true, a git source is not fetched, and its cached copy is used.

=head2 standards

A directory that replaces the C<git> or the C<directory> of the source, and
keeps its C<path>, such as a checkout of the standards that you are editing.

=head2 source

The L<Dist::Conformance::Source>.  Default built from the configuration and
the attributes above.

=head2 flavor

The L<Dist::Conformance::Flavor>, loaded from the source.

=head1 FUNCTIONS

=head2 failed($results)

Whether any result of L</check> failed.

=over 4

=item results - ArrayRef[HashRef] - the results, as L</check> returns them

=back

Returns Bool, true when the status of a result is C<fail>.

    exit 1 if Dist::Conformance::failed( $conformance->check );

=head1 METHODS

=head2 adopt

Asks every check that is not skipped what configuration would accept the checkout as it is now, through L<Dist::Conformance::Check/adopt>.

Returns HashRef, from the name of each check that has an answer to the answer, which is what the check would take under C<checks> in F<.conformance.yml>.

Dies when the checks cannot be made, as L</checks> says, and when the adopt of a check dies.

    my $adopted = $conformance->adopt;

=head2 build_source

The source that the C<source> key of the configuration describes, with L</standards>, L</cache> and L</offline> applied: a directory for L</standards> or for C<directory>, and else a git repository.

Returns a Dist::Conformance::Source object, the new source.

    my $source = $conformance->build_source;

=head2 check

Runs every check of the flavor against the snapshot.

A check that dies, or returns a status that is not one of the three, fails, and its detail says so.  A failure of a check at C<level: info> is reported as C<info>.

Returns ArrayRef, of hash references, one for each check of the flavor, in the order of their names: C<check>, the name; C<status>, which is C<pass>, C<fail>, C<info>, or C<skip> for a check that F<.conformance.yml> skips; and C<detail>.

Dies when the checks cannot be made, as L</checks> says.

    my $results = $conformance->check;

=head2 checks

The L<Dist::Conformance::Check> objects that run, in order, with the configuration of the flavor and of F<.conformance.yml> merged and validated. Memoized.

Returns ArrayRef[InstanceOf["Dist::Conformance::Check"]], the checks.

Dies on a check whose module does not load or is not a check, and on a configuration that its schema refuses; each message names the check and the flavor.

    say $_->name for @{ $conformance->checks };

=head2 make_check(name, config, variables)

The check C<$name> of the flavor, from its merged configuration.

=over 4

=item name - Str - the name of the check in the flavor

=item config - HashRef - its merged configuration, with C<module> when the module is not the name

=item variables - HashRef - the values of the placeholders of the templates

=back

Returns a Dist::Conformance::Check object, the check.

Dies when the module of the check is not the name of a module, does not load, or is not a L<Dist::Conformance::Check>, and when the schema of the check refuses the configuration.

    my $check = $conformance->make_check( 'ClaudeMd', { file => 'CLAUDE.md', mentions => [] }, {} );

=head2 skipped

The names of the checks that F<.conformance.yml> skips.

Returns HashRef, from the name of each skipped check to 1.

Dies when F<.conformance.yml> skips or configures a check that the flavor does not run, with a message that starts with C<.conformance.yml is not valid:>.

    my $skipped = $conformance->skipped;

=head2 update(dry_run)

Runs the update of every check that is not skipped on the checkout, after fetching the standards when the source is git.  A check whose update dies has the error in C<manual>, and the other checks still run.

=over 4

=item dry_run - Bool - optional: when true, writes nothing, and says what it would write

=back

Returns ArrayRef, of hash references, one for each check that ran, in order: C<check>, the name; C<changes>, what it changed or would change, each with an C<action> and a C<path>; and C<manual>, what is left for a person.

Dies when the checks cannot be made, as L</checks> says.

    my $results = $conformance->update( dry_run => 1 );

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<conformance>

=item *

L<Dist::Conformance::Check>

=item *

L<Dist::Conformance::Flavor>

=item *

L<Dist::Conformance::Config>

=item *

L<Dist::Conformance::Snapshot>

=item *

L<Dist::Conformance::Source>

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

=head1 CONTRIBUTORS

=for stopwords troglodyne-bot troglodyne-robot

=over 4

=item *

troglodyne-bot <morpheus@troglodyne.net>

=item *

troglodyne-bot <troglodyne-bot@users.noreply.github.com>

=item *

troglodyne-robot <trogbot@troglodyne.net>

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
