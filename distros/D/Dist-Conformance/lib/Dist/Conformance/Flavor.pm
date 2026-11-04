package Dist::Conformance::Flavor 0.001;

# ABSTRACT: A named set of checks and their configuration, read from a standards source

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base -base, -signatures;

use List::Util();

use Dist::Conformance::Schema();


has 'name';
has 'description';
has checks    => sub { {} };
has variables => sub { {} };
has lineage   => sub { [] };

our %SCHEMA = (
    type                 => 'object',
    required             => ['name'],
    additionalProperties => 0,
    properties           => {
        name        => $Dist::Conformance::Schema::NAME,
        description => { type => 'string' },
        extends     => { type => 'array',  items                => $Dist::Conformance::Schema::NAME, default => [] },
        variables   => { type => 'object', additionalProperties => { type => 'string' },                default => {} },
        checks      => { type => 'object', additionalProperties => { type => 'object', nullable => 1 }, default => {} },
    },
);


sub load ( $class, $source, $name ) {
    my @order = linearize( $source, $name );
    my ( %checks, %variables );
    for my $data (@order) {
        %variables = ( %variables, %{ $data->{variables} } );
        merge_checks( \%checks, $data->{checks} );
    }
    return $class->new(
        name        => $name,
        description => $order[-1]{description},
        checks      => \%checks,
        variables   => \%variables,
        lineage     => [ map { $_->{name} } @order ],
    );
}


sub linearize ( $source, $name ) {
    my ( @order, %done );
    my @path = ( { name => $name, data => read_file( $source, $name ), next => 0 } );
    while (@path) {
        my $frame  = $path[-1];
        my $parent = $frame->{data}{extends}[ $frame->{next}++ ];
        if ( !defined $parent ) {
            push @order, $frame->{data};
            $done{ $frame->{name} } = 1;
            pop @path;
            next;
        }
        my @names = map { $_->{name} } @path;
        die 'The flavors extend each other in a cycle: ', join( ' -> ', @names, $parent ), "\n" if List::Util::any { $_ eq $parent } @names;
        next if $done{$parent};
        push @path, { name => $parent, data => read_file( $source, $parent, $frame->{name} ), next => 0 };
    }
    return @order;
}


sub check_names ($self) {
    my @names = sort keys %{ $self->checks };
    return @names;
}


sub merge_checks ( $checks, $over ) {
    for my $check ( sort keys %$over ) {
        my $config = $over->{$check};
        if ( !defined $config ) {
            delete $checks->{$check};
            next;
        }
        my %merged = ( %{ $checks->{$check} // {} }, %$config );
        delete @merged{ grep { !defined $merged{$_} } keys %merged };
        $checks->{$check} = \%merged;
    }
    return $checks;
}


sub read_file ( $source, $name, $extended_by = undef ) {
    my $file = "conformance/$name.yml";
    die "$name is not the name of a flavor\n" if !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, $name );
    if ( !$source->exists_file($file) ) {
        my $by = defined $extended_by ? ", which conformance/$extended_by.yml extends" : q{};
        die( "There is no flavor $name$by: the standards at " . $source->describe . " have no $file\n" );
    }
    my $data = Dist::Conformance::Schema::validate( Dist::Conformance::Schema::parse_yaml( $source->file($file), $file ), \%SCHEMA, $file );
    die "$file is not valid:\n  /name: is $data->{name}, not $name, the name of the file\n" if $data->{name} ne $name;
    for my $check ( sort keys %{ $data->{checks} } ) {
        die "$file is not valid:\n  /checks/$check: is not the name of a check\n" if !Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, $check );
    }
    return $data;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Flavor - A named set of checks and their configuration, read from a standards source

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Flavor;
    use Dist::Conformance::Source::Directory;

    my $source = Dist::Conformance::Source::Directory->new( directory => '/bogus/standards' );
    my $flavor = Dist::Conformance::Flavor->load( $source, 'troglodyne-5.040' );
    say for $flavor->check_names;                 # ClaudeMd, CriticProfile, ...
    say $flavor->checks->{CriticProfile}{template};
    say join ' then ', @{ $flavor->lineage };     # troglodyne then troglodyne-5.040

=head1 DESCRIPTION

A flavor is the answer to "what does a conforming repository look like" for one
kind of repository.  It names the checks to run and gives each its
configuration: which files, which templates, which header, and whether a miss
is a failure or only worth knowing.  A check module has no expectations of its
own; everything it compares against comes from here.

Flavors build on each other with C<extends>, so a standard is written once and
varied where it differs: by the perl it runs on, by whether it is a CPAN
distribution, by whether it runs CI, or by anything else that a check can see.

=head1 ATTRIBUTES

=head2 name

The name of the flavor that was loaded.

=head2 description

Its description, or C<undef>.  Never inherited.

=head2 checks

The merged configuration: a hash reference from each check name to its
configuration.

=head2 variables

The merged variables.

=head2 lineage

The names of the flavors that were merged, in the order of the merge, ending
with L</name>.

=head1 METHODS

=head2 load

C<($class, $source, $name)>.  Reads the flavor C<$name> and everything it
extends from C<$source>, a L<Dist::Conformance::Source>, and returns the merged
flavor.  Dies when a file is missing, does not parse or does not match the
schema, when a check has a name that is not a L<Dist::Conformance::Schema/$NAME>,
and on a cycle in C<extends>.  Each message names the file, and the key where
there is one.

=head2 check_names

The names of the checks, in the order that they run.

=head1 FUNCTIONS

=head2 linearize

C<($source, $name)>.  The validated contents of the flavor files that make up
the flavor C<$name>, in the order of L</THE MERGE RULE>.  Dies on a cycle.

=head2 merge_checks

C<(\%checks, \%over)>.  Lays C<%over>, a mapping of check names to
configurations, over C<%checks> in place, by L</THE MERGE RULE>.  A
configuration in C<%checks> is replaced, never changed, so that a caller can
share one with another flavor.

=head2 read_file

C<($source, $name, $extended_by)>.  The validated content of
F<conformance/$name.yml>.  C<$extended_by> is the flavor whose C<extends> named
it, for the message when it is missing.

=head1 THE FLAVOR FILE

A flavor named C<NAME> is the YAML file F<conformance/NAME.yml> of a standards
source.  These are its keys:

=over

=item name

Required.  The name of the flavor, the same as the file name without F<.yml>.
A letter or a digit, then letters, digits, C<.>, C<_> and C<->.

=item description

One line that says what kind of repository the flavor is for.

=item extends

A list of the flavors that this one builds on, in order.  See L</THE MERGE
RULE>.

=item variables

A mapping from a placeholder name to its value, a string.  A template that
contains C<{{NAME}}> gets the value of C<NAME> when an update writes it.
Quote a value that looks like a number, such as C<'5.040'>.  YAML::XS keeps
the text of an unquoted C<5.040>, but YAML itself calls it the number 5.04, and
another reader of the file can take it at its word.

=item checks

A mapping from the name of a check to its configuration, itself a mapping.  The
name picks the module, C<Dist::Conformance::Check::NAME>, unless the
configuration says C<module>.  So one module can run twice under two names,
with two configurations.  The keys that every check takes, and the module of
each check that this distribution ships, are documented in
L<Dist::Conformance::Check>.

A check whose configuration is C<~>, the YAML null, is removed: the flavor does
not run a check that a flavor it extends runs.

=back

The checks run in the order of their names.

This is F<troglodyne-5.040.yml> from the fixtures of this distribution:

    name: troglodyne-5.040
    description: A troglodyne distribution that declares use 5.040 or later
    extends:
      - troglodyne
    variables:
      PERL_FLOOR: '5.040'
    checks:
      CriticProfile:
        file: .perlcriticrc
        template: templates/perlcriticrc
        outdated:
          - '# Troglodyne perlcritic policy'
        replace: false

And this is a flavor that differs for a reason other than the perl: a service,
which is deployed and not released to CPAN.  It runs the 5.040 standards and
the CI of a second flavor, drops the dist files, and requires the Claude Code
settings:

    name: troglodyne-service
    extends:
      - troglodyne-5.040
      - github-ci
    checks:
      DistFiles: ~
      ToolConfiguration:
        files:
          .perltidyrc: templates/perltidyrc
          .preferred_modules.ini: templates/preferred_modules.ini
          .tests-covering-map.pl: templates/tests-covering-map
      ClaudeSettings:
        missing: fail

=head1 THE MERGE RULE

A flavor is merged from itself and every flavor that it extends, directly or
not.  First the flavors are put in order:

=over

=item 1.

Each flavor comes after every flavor that it extends.

=item 2.

The flavors that one flavor extends come in the order of its C<extends> list,
each with its own ancestors before it.

=item 3.

A flavor that two paths reach is used once, at its first place.  So in a
diamond, where C<service> extends C<perl> and C<ci>, and both extend C<base>,
the order is C<base>, C<perl>, C<ci>, C<service>.

=back

Then each flavor in that order is laid over the result of the ones before it:

=over

=item *

A variable replaces the variable of the same name.

=item *

A check that the result does not have yet is added.

=item *

A check that it has already is merged key by key: each key of the later
configuration replaces the same key of the earlier one, and the keys that the
later one does not name stay.  The value of a key is replaced whole, never
merged: a later C<files> mapping is the whole list of files, not an addition to
the earlier one.

=item *

A key whose value is C<~> is removed from the configuration of the check, so
the check sees it as not set.

=item *

A check whose configuration is C<~> is removed altogether.  A later flavor can
add it again.

=back

So the last word goes to the flavor named last, and to the flavor itself over
everything that it extends.  F<.conformance.yml> is laid over the result by the
same rule; see L<Dist::Conformance::Config>.

A flavor that extends itself, directly or through others, is an error, and so is
an C<extends> that names a flavor that the source does not have.

=head1 THE STANDARDS REPOSITORY

A standards source is a directory tree, in a git repository or on disk.  Its
C<path> is the directory inside the tree that the flavors are read from, and
every path that a flavor names is relative to that directory too:

    PATH/
        conformance/
            NAME.yml          one file for each flavor
            ...
        templates/            the files that the flavors name, where you like
            perlcriticrc
            pre-commit
            ...

Only F<conformance/> has a fixed name.  The templates can live anywhere below
C<PATH>, because each flavor names them by path, and a path that leaves
C<PATH>, absolute or with C<..>, is refused.  Keep the flavors in the
repository of the templates that they name, so that one commit changes a
template and the flavor that expects it, and every repository that fetches the
standards sees both or neither.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=item *

L<Dist::Conformance::Config>

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
