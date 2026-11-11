package Dist::Conformance::Check 0.004;

# ABSTRACT: The interface of a check, and what the checks share

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base -base, -signatures;

use List::Util();

use Dist::Conformance::Schema();


has 'name';
has config => sub { {} };
has 'source';
has variables => sub { {} };

our $MODULE = { type => 'string', pattern => '\A[A-Za-z_]\w*(?:::\w+)*\z' };


sub config_schema ($) { return { properties => {} } }


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


sub from_config ( $class, %arguments ) {
    my $where  = delete $arguments{where} // "the check $arguments{name}";
    my $config = Dist::Conformance::Schema::validate( $arguments{config} // {}, $class->schema, $where );
    return $class->new( %arguments, config => $config );
}


sub check ( $self, $ ) { die( ref($self) . " does not implement check\n" ) }


sub update ( $self, $update ) {
    my ( $status, $detail ) = $self->check( $update->snapshot );
    $update->by_hand( "$detail: " . $self->name . ' has no automatic fix' ) if $status eq 'fail';
    return;
}


sub template ( $self, $path ) {
    my $text      = $self->source->file($path);
    my $variables = $self->variables;
    $text =~ s/\{\{ ([[:upper:]][[:upper:][:digit:]_]*) \}\}/exists $variables->{$1} ? $variables->{$1} : "{{$1}}"/ge;
    my @unfilled = List::Util::uniq( sort $text =~ m/\{\{ ([[:upper:]][[:upper:][:digit:]_]*) \}\}/g );
    return ( $text, @unfilled );
}


sub write_template ( $self, $update, $path, $template, $mode = oct 644 ) {
    my ( $text, @unfilled ) = $self->template($template);
    if (@unfilled) {
        $update->by_hand( "Write $path from $template by hand, or set the variables " . join( ', ', @unfilled ) . ' in .conformance.yml: nothing sets them' );
        return 0;
    }
    return $update->write( $path, $text, $mode );
}


sub missing ( $, $snapshot, @paths ) {
    my @missing = grep { !$snapshot->contains($_) } @paths;
    return @missing;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check - The interface of a check, and what the checks share

=head1 VERSION

version 0.004

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

L</update> changes a checkout so that the check passes, through a
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

=head2 config_schema

The schema of the keys that this check takes, as a hash reference with
C<properties>, and C<required> if any are.  Every key in it is documented in
the POD of the check.  The base class takes none of its own; L</schema> adds
L</THE KEYS THAT EVERY CHECK TAKES>.

=head2 schema

The whole schema of the configuration: L</config_schema>, the keys that every
check takes, and no others.

=head2 from_config

C<(%arguments)>.  A new check, whose C<config> is validated against
L</schema> first.  C<where> names the configuration in an error, such as
C<the check ClaudeMd of the flavor troglodyne>.

=head2 check

C<($snapshot)>.  Returns C<($status, $detail)>: the status is C<pass>, C<fail>
or C<info>, and the detail is one line for a person.  A subclass must
implement it.

=head2 update

C<($update)>.  Changes the checkout of C<< $update->snapshot >> through the
L<Dist::Conformance::Update>.  Returns nothing that the caller reads.

The default is for a check that cannot change anything: when L</check> fails,
it records the detail and that there is no automatic fix.

=head2 template

C<($path)>.  Returns the template at C<$path> in the source with the variables
filled in, and then the sorted names of the placeholders that no variable
fills.  Dies when the source has no such file.

=head2 write_template

C<($update, $path, $template, $mode)>.  Writes the template C<$template> to
C<$path>, with C<$mode>, through C<$update>.  When a placeholder is left,
writes nothing and records what is needed.  Returns whether it wrote.

=head2 missing

C<($snapshot, @paths)>.  The paths of C<@paths> that the snapshot does not
have, in their order.

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

The perlcritic profile enables or turns off every policy that its template
enables.

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

=item L<Dist::Conformance::Check::ClaudeSettings>

F<.claude/settings.json> enables the plugins.

=item L<Dist::Conformance::Check::Workflows>

The CI workflows exist.

=item L<Dist::Conformance::Check::SystemPackages>

The system packages and archives that F<metamerge.yml> declares are valid.

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
