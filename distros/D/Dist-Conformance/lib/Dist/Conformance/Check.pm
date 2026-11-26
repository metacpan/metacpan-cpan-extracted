package Dist::Conformance::Check 0.011;

# ABSTRACT: The interface of a check, and what the checks share

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base -base, -signatures;

use List::Util();
use Module::Runtime();

use Dist::Conformance::Schema();


has 'name';
has config => sub { {} };
has 'source';
has variables => sub { {} };

my $MODULE_NAME_RX = $Module::Runtime::module_name_rx;
my $MODULE_RX      = qr/\A$MODULE_NAME_RX\z/;
our $MODULE = { type => 'string', pattern => "$MODULE_RX" };

# The schema of the keys that this check takes.  Every key in it is documented
# in the POD of the check.  The base class takes none of its own; L</schema>
# adds L</THE KEYS THAT EVERY CHECK TAKES>.
# @returns HashRef  with C<properties>, and C<required> if any key is required
# @example my $schema = Dist::Conformance::Check::ClaudeMd->config_schema;
sub config_schema ($) { return { properties => {} } }

# The whole schema of the configuration: L</config_schema>, the keys that every
# check takes, and no others.
# @returns HashRef  an object schema that allows no other keys
# @example my $schema = Dist::Conformance::Check::ClaudeMd->schema;
sub schema ($class) {
    my $own = $class->config_schema;
    return {
        type                 => 'object',
        additionalProperties => 0,
        required             => $own->{required} // [],
        properties           => {
            module => $MODULE,
            level  => { type => 'string', enum => [qw{fail info}], default => 'fail' },
            %{ $own->{properties} },
        },
    };
}

# A new check, whose C<config> is validated against L</schema> first.  The other
# arguments, such as C<source> and C<variables>, are the attributes of the new
# check.
# @param   name    Str      the name of the check in the flavor
# @param   config  HashRef  optional: the configuration, default empty
# @param   where   Str      optional: names the configuration in an error, such as
# C<the check ClaudeMd of the flavor troglodyne>; default C<the check NAME>
# @returns InstanceOf["Dist::Conformance::Check"]  the check, of the class that it is called on
# @throws  when the schema refuses the configuration, with the message of
# L<Dist::Conformance::Schema/"validate($data, $schema, $where)">
# @example my $check = Dist::Conformance::Check::ClaudeMd->from_config(
#     name   => 'ClaudeMd',
#     config => { file => 'CLAUDE.md', mentions => [] },
#     source => $source,
# );
sub from_config ( $class, %arguments ) {
    my $where  = delete $arguments{where} // "the check $arguments{name}";
    my $config = Dist::Conformance::Schema::validate( $arguments{config} // {}, $class->schema, $where );
    return $class->new( %arguments, config => $config );
}

# Checks the L<Dist::Conformance::Snapshot> that it is given.  A subclass must
# implement it.
# @returns C<($status, $detail)>, as a list: the status is C<pass>, C<fail> or
# C<info>, and the detail is one line for a person
# @throws  when the subclass does not implement it
# @example my ( $status, $detail ) = $check->check($snapshot);
sub check ( $self, $ ) { die( ref($self) . " does not implement check\n" ) }

# Changes the checkout of C<< $update->snapshot >> through the
# L<Dist::Conformance::Update>.
#
# The default is for a check that cannot change anything: when L</check> fails,
# it records the detail and that there is no automatic fix.
# @param   update  InstanceOf["Dist::Conformance::Update"]  what records and writes the changes
# @returns what the subclass chooses, which no caller reads: L<Dist::Conformance/"update(dry_run)">
# ignores it.  The default returns nothing.
# @example $check->update($update);
sub update ( $self, $update ) {
    my ( $status, $detail ) = $self->check( $update->snapshot );
    $update->by_hand( "$detail: " . $self->name . ' has no automatic fix' ) if $status eq 'fail';
    return;
}

# The configuration that would make this check accept the repository in the
# L<Dist::Conformance::Snapshot> that it is given as it is now, as the keys of
# this check for F<.conformance.yml>.
# C<conformance adopt> prints it, so that a person can record the choices of a
# repository before an update replaces them.  The default is nothing: a check
# whose configuration has no room for the choices of a repository has nothing to
# adopt.
# @returns HashRef  the keys, or nothing
# @example my $keys = $check->adopt($snapshot);
sub adopt ( $, $ ) { return }

# The template at C<$path> in the source with the variables filled in, and then
# the sorted names of the placeholders that no variable fills.
# @param   path  Str  the path of the template in the source
# @returns the text, and then the names of the placeholders that are left, as a list
# @throws  when the source has no such file, with the message of
# L<Dist::Conformance::Source/"file(relative)">
# @example my ( $text, @unfilled ) = $check->template('templates/CLAUDE.md');
sub template ( $self, $path ) {
    my $text      = $self->source->file($path);
    my $variables = $self->variables;
    $text =~ s/\{\{ ([[:upper:]][[:upper:][:digit:]_]*) \}\}/exists $variables->{$1} ? $variables->{$1} : "{{$1}}"/ge;
    my @unfilled = List::Util::uniq( sort $text =~ m/\{\{ ([[:upper:]][[:upper:][:digit:]_]*) \}\}/g );
    return ( $text, @unfilled );
}

# Writes the template C<$template> to C<$path>, with C<$mode>, through
# C<$update>.  When a placeholder is left, writes nothing and records what is
# needed.
# @param   update    InstanceOf["Dist::Conformance::Update"]  what writes the file
# @param   path      Str  the path to write in the checkout
# @param   template  Str  the path of the template in the source
# @param   mode      Int  optional: the permissions, default 0644
# @returns Bool  whether it wrote
# @throws  when the source has no such template, with the message of L<template|/"template(path)">
# @example $check->write_template( $update, '.perltidyrc', 'templates/perltidyrc' );
sub write_template ( $self, $update, $path, $template, $mode = oct 644 ) {
    my ( $text, @unfilled ) = $self->template($template);
    if (@unfilled) {
        $update->by_hand( "Write $path from $template by hand, or set the variables " . join( ', ', @unfilled ) . ' in .conformance.yml: nothing sets them' );
        return 0;
    }
    return $update->write( $path, $text, $mode );
}


sub missing ( $, $snapshot, @paths ) {
    my @missing = grep { local ($_) = $_; !$snapshot->contains($_) } @paths;
    return @missing;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check - The interface of a check, and what the checks share

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Check::ClaudeMd;
    use Dist::Conformance::Snapshot::Directory;
    use Dist::Conformance::Source::Directory;

    my $check = Dist::Conformance::Check::ClaudeMd->from_config(
        name   => 'ClaudeMd',
        config => { file => 'CLAUDE.md', mentions => ['perl-slop:reading-perl'] },
        source => Dist::Conformance::Source::Directory->new( directory => '/bogus/standards' ),
        where  => 'the check ClaudeMd',
    );
    my ( $status, $detail ) = $check->check( Dist::Conformance::Snapshot::Directory->new( root => '/bogus/checkout' ) );

=head1 DESCRIPTION

A check is one question about a repository, such as "does it have the current
perlcritic profile", asked of a L<Dist::Conformance::Snapshot>.  It knows two
things:

=over

=item how to check

L</check> reads the snapshot, and returns a status and a detail.

=item how to update

L<update|/"update(update)"> changes a checkout so that the check passes, through a
L<Dist::Conformance::Update>, which records what it changed and writes nothing
on a dry run.  What it cannot do safely, it says so, as a sentence for a
person, rather than guessing.

=back

A check holds no expectations of its own.  The files, the templates, the
policies, whether a miss fails or is only worth knowing: all of that is its
configuration, which comes from the flavor (see L<Dist::Conformance::Flavor>)
and from F<.conformance.yml> (see L<Dist::Conformance::Config>).  Each check
module documents the keys that it takes, and validates them against its
L</config_schema> before it runs.

=head1 ATTRIBUTES

=head2 name

The name of the check in the flavor.

=head2 config

Its configuration, validated, with the defaults of L</config_schema> filled in.

=head2 source

The L<Dist::Conformance::Source> that the templates come from.

=head2 variables

The values of the placeholders of the templates.

=head1 METHODS

=head2 missing($snapshot, @paths)

The paths of C<@paths> that the snapshot does not have, in their order.

=over 4

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - the repository

=item paths - Str - the paths to look for

=back

Returns the missing paths, as a list.

    my @missing = $check->missing( $snapshot, 'dist.ini', 'Changes' );

=head2 adopt

The configuration that would make this check accept the repository in the L<Dist::Conformance::Snapshot> that it is given as it is now, as the keys of this check for F<.conformance.yml>. C<conformance adopt> prints it, so that a person can record the choices of a repository before an update replaces them.  The default is nothing: a check whose configuration has no room for the choices of a repository has nothing to adopt.

Returns HashRef, the keys, or nothing.

    my $keys = $check->adopt($snapshot);

=head2 check

Checks the L<Dist::Conformance::Snapshot> that it is given.  A subclass must implement it.

Returns C<($status, $detail)>, as a list: the status is C<pass>, C<fail> or C<info>, and the detail is one line for a person.

Dies when the subclass does not implement it.

    my ( $status, $detail ) = $check->check($snapshot);

=head2 config_schema

The schema of the keys that this check takes.  Every key in it is documented in the POD of the check.  The base class takes none of its own; L</schema> adds L</THE KEYS THAT EVERY CHECK TAKES>.

Returns HashRef, with C<properties>, and C<required> if any key is required.

    my $schema = Dist::Conformance::Check::ClaudeMd->config_schema;

=head2 from_config(where, name, config)

A new check, whose C<config> is validated against L</schema> first.  The other arguments, such as C<source> and C<variables>, are the attributes of the new check.

=over 4

=item where - Str - optional: names the configuration in an error, such as C<the check ClaudeMd of the flavor troglodyne>; default C<the check NAME>

=item name - Str - the name of the check in the flavor

=item config - HashRef - optional: the configuration, default empty

=back

Returns a Dist::Conformance::Check object, the check, of the class that it is called on.

Dies when the schema refuses the configuration, with the message of L<Dist::Conformance::Schema/"validate($data, $schema, $where)">.

    my $check = Dist::Conformance::Check::ClaudeMd->from_config(
        name   => 'ClaudeMd',
        config => { file => 'CLAUDE.md', mentions => [] },
        source => $source,
    );

=head2 schema

The whole schema of the configuration: L</config_schema>, the keys that every check takes, and no others.

Returns HashRef, an object schema that allows no other keys.

    my $schema = Dist::Conformance::Check::ClaudeMd->schema;

=head2 template(path)

The template at C<$path> in the source with the variables filled in, and then the sorted names of the placeholders that no variable fills.

=over 4

=item path - Str - the path of the template in the source

=back

Returns the text, and then the names of the placeholders that are left, as a list.

Dies when the source has no such file, with the message of L<Dist::Conformance::Source/"file(relative)">.

    my ( $text, @unfilled ) = $check->template('templates/CLAUDE.md');

=head2 update(update)

Changes the checkout of C<< $update->snapshot >> through the L<Dist::Conformance::Update>.

The default is for a check that cannot change anything: when L</check> fails, it records the detail and that there is no automatic fix.

=over 4

=item update - InstanceOf["Dist::Conformance::Update"] - what records and writes the changes

=back

Returns what the subclass chooses, which no caller reads: L<Dist::Conformance/"update(dry_run)"> ignores it.  The default returns nothing.

    $check->update($update);

=head2 write_template(update, path, template, mode)

Writes the template C<$template> to C<$path>, with C<$mode>, through C<$update>.  When a placeholder is left, writes nothing and records what is needed.

=over 4

=item update - InstanceOf["Dist::Conformance::Update"] - what writes the file

=item path - Str - the path to write in the checkout

=item template - Str - the path of the template in the source

=item mode - Int - optional: the permissions, default 0644

=back

Returns Bool, whether it wrote.

Dies when the source has no such template, with the message of L<template|/"template(path)">.

    $check->write_template( $update, '.perltidyrc', 'templates/perltidyrc' );

=head1 STATUSES

=over

=item pass

The repository meets the standard.

=item fail

It does not.  C<conformance check> exits non-zero when any check fails.

=item info

Worth knowing, and not a failure: an optional file is absent, or a hook differs
from its template because the repository customized it.

=back

A check that dies while checking reports C<fail>, with the error as the detail.

=head1 WHAT UPDATE CHANGES

An update brings the checkout to what the configuration describes, whatever
status L</check> reports.  A status of C<info> changes what C<check> reports,
not what C<update> does: L<Dist::Conformance::Check::ClaudeSettings> with
C<missing: info> still writes the settings when they are missing.  To keep
C<update> away from something, skip its check in F<.conformance.yml>, or
configure the check not to write it, such as C<replace: false>.

A file that a check writes comes from a template of the standards, with each
C<{{NAME}}> replaced by the variable C<NAME> of the flavor or of
F<.conformance.yml>.  A template that still has a placeholder that nothing sets
is not written: the update says which variables it needs instead.

=head1 THE KEYS THAT EVERY CHECK TAKES

=over

=item module

The module of the check: C<Foo> means C<Dist::Conformance::Check::Foo>, and a
name with C<::> in it is the whole package name.  Default the name of the
check.  So a flavor can run one module twice under two names.

=item level

C<fail> or C<info>.  At C<info>, a failure of this check is reported as
C<info>, so that it never fails a run.  Default C<fail>.

=back

=head1 THE CHECKS

=over

=item L<Dist::Conformance::Check::ClaudeMd>

F<CLAUDE.md> exists and names the skills that it must.

=item L<Dist::Conformance::Check::CriticProfile>

The perlcritic profile is its template, with the overrides of the repository.

=item L<Dist::Conformance::Check::ToolConfiguration>

The configuration files of the tools exist.

=item L<Dist::Conformance::Check::GitHooks>

The hooks are tracked, match their templates, and are installed.

=item L<Dist::Conformance::Check::DistFiles>

A distribution has the files that its build needs.

=item L<Dist::Conformance::Check::DataSchema>

A JSON, YAML or INI file, such as F<.perl-slop.json>, matches a schema.

=item L<Dist::Conformance::Check::RefusedIniKeys>

An INI file, such as F<dist.ini>, sets no key that the flavor refuses, and the
update removes each one.

=item L<Dist::Conformance::Check::AuthorDeps>

F<dist.ini> asks for each authordep of its template, at the version of the
template or later, and the update raises or adds each one.

=item L<Dist::Conformance::Check::IniTemplate>

An INI file, such as F<weaver.ini>, is its template with the overrides of the
repository, and the update writes it.

=item L<Dist::Conformance::Check::DistIni>

F<dist.ini> is its template with the overrides of the repository, its
authordeps included.

=item L<Dist::Conformance::Check::ClaudeSettings>

F<.claude/settings.json> enables the plugins.

=item L<Dist::Conformance::Check::Workflows>

The CI workflows exist.

=item L<Dist::Conformance::Check::SystemPackages>

The system packages and archives that F<metamerge.yml> declares are valid, and
include those of a template.

=back

=head1 WRITING A CHECK

Subclass this module, and name the subclass in a flavor:

    package My::Check::HasReadme;

    use 5.040;
    use Mojo::Base 'Dist::Conformance::Check', -signatures;

    sub config_schema ($class) {
        return { required => ['file'], properties => { file => $Dist::Conformance::Schema::PATH, template => $Dist::Conformance::Schema::PATH } };
    }

    sub check ( $self, $snapshot ) {
        my $file = $self->config->{file};
        return $snapshot->contains($file) ? ( 'pass', "$file exists" ) : ( 'fail', "$file is missing" );
    }

    sub update ( $self, $update ) {
        my $config = $self->config;
        return if $update->snapshot->contains( $config->{file} );
        return $self->write_template( $update, $config->{file}, $config->{template} ) if defined $config->{template};
        return $update->by_hand("Write $config->{file}");
    }

And in the flavor:

    checks:
      Readme:
        module: My::Check::HasReadme
        file: README.md
        template: templates/README.md

A check must not keep state between calls: one object checks, and then can
update, and the snapshot can have changed in between.  A check reads only
through the snapshot, so that it runs against a repository that is not on this
machine, and writes only through the update.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance>

=item *

L<Dist::Conformance::Flavor>

=item *

L<Dist::Conformance::Update>

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
