package Dist::Zilla::Plugin::Sah::SchemaBundle;

use 5.010001;
use strict;
use warnings;
use Moose;

use PMVersions::Util qw(version_from_pmversions);
use Require::Hook::Source::DzilBuild;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-13'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Sah-SchemaBundle'; # DIST
our $VERSION = '0.034'; # VERSION

with (
    'Dist::Zilla::Role::CheckPackageDeclared',
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
    'Dist::Zilla::Role::PrereqSource',
    #'Dist::Zilla::Role::RequireFromBuild',
);

has exclude_module => (is => 'rw');

has schemar_preamble => (is => 'rw');

has schemar_postamble => (is => 'rw');

use namespace::autoclean;

sub mvp_multivalue_args { qw(exclude_module) }

sub _load_schema_modules {
    my $self = shift;

    return $self->{_our_schema_modules} if $self->{_loaded_schema_modules}++;

    local @INC = (Require::Hook::Source::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %res;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!^lib/(Sah/Schema/.+\.pm)$!;

        my $pkg_pm = $1;
        (my $pkg = $pkg_pm) =~ s/\.pm$//; $pkg =~ s!/!::!g;

        if ($self->exclude_module && grep { $pkg eq $_ } @{ $self->exclude_module }) {
            $self->log_debug(["Sah schema module %s excluded", $pkg]);
            next;
        }

        $self->log_debug(["Loading schema module %s ...", $pkg_pm]);
        delete $INC{$pkg_pm};
        require $pkg_pm;
        $res{$pkg} = $file;
    }

    $self->{_our_schema_modules} = \%res;
}

sub _load_schemabundle_modules {
    my $self = shift;

    return $self->{_our_schemabundle_modules} if $self->{_loaded_schemabundle_modules}++;

    local @INC = (Require::Hook::Source::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %res;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!^lib/(Sah/SchemaBundle/.+\.pm)$!;
        my $pkg_pm = $1;
        (my $pkg = $pkg_pm) =~ s/\.pm$//; $pkg =~ s!/!::!g;
        require $pkg_pm;
        $res{$pkg} = $file;
    }

    $self->{_our_schemabundle_modules} = \%res;
}

sub munge_files {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

    my $self = shift;

    $self->{_used_schema_modules} //= {};

    $self->_load_schema_modules;
    $self->_load_schemabundle_modules;

  SAH_SCHEMABUNDLE_MODULE:
    for my $pkg (sort keys %{ $self->{_our_schemabundle_modules} }) {
        # ...
    }

  SAH_SCHEMA_MODULE:
    for my $pkg (sort keys %{ $self->{_our_schema_modules} }) {
        my $file = $self->{_our_schema_modules}{$pkg};

        my $file_content = $file->content;

        my $sch = ${"$pkg\::schema"} or do {
            $self->log_fatal(["No schema defined in \$schema in %s", $file->name]);
        };
        # actually we don't have to normalize manually, we require the schemas
        # to be normalized anyway. but to be safer.
        my $nsch = Data::Sah::Normalize::normalize_schema($sch);

        # compile schema to perl code and collect the required modules
        $self->{_modules_required_by_schema} = {};

        # collect other Sah::Schema::* modules that are used, this will
        # be added as prereq
      COLLECT_BASE_SCHEMAS:
        {
            require Data::Sah::Normalize;
            require Data::Sah::Resolve;
            require Data::Sah::Util::Subschema;

            $self->log_debug(["Finding schema modules required by %s", $pkg]);

            my $subschemas;
            eval {
                $subschemas = Data::Sah::Util::Subschema::extract_subschemas(
                    {schema_is_normalized => 1},
                    $nsch,
                );
            };
            if ($@) {
                $self->log(["Can't extract subschemas from schema in %s (%s), skipped", $pkg, $@]);
                last COLLECT_BASE_SCHEMAS;
            }

            for my $subsch ($nsch, @$subschemas) {
                my $nsubsch = Data::Sah::Normalize::normalize_schema($subsch);
                my $res;
                eval {
                    $res = Data::Sah::Resolve::resolve_schema(
                        {
                            schema_is_normalized => 1,
                        },
                        $nsubsch);
                };
                if ($@) {
                    $self->log(["Can't resolve schema (%s), skipped collecting base schemas for %s", $@, $pkg]);
                    last COLLECT_BASE_SCHEMAS;
                }
                my $resolve_path = $res->{resolve_path};
                for my $i (1..$#{$resolve_path}) {
                    my $mod = "Sah::Schema::$resolve_path->[$i]";
                    $self->{_used_schema_modules}{$mod}++;
                }
            }
        }

        # set ABSTRACT from schema's summary
        {
            unless ($file_content =~ m{^#[ \t]*ABSTRACT:[ \t]*([^\n]*)[ \t]*$}m) {
                $self->log_debug(["Skipping setting ABSTRACT %s: no # ABSTRACT", $file->name]);
                last;
            }
            my $abstract = $1;
            if ($abstract =~ /\S/) {
                $self->log_debug(["Skipping setting ABSTRACT %s: already filled (%s)", $file->name, $abstract]);
                last;
            }

            $file_content =~ s{^#\s*ABSTRACT:.*}{# ABSTRACT: $sch->[1]{summary}}m
                or die "Can't set abstract for " . $file->name;
            $self->log(["setting abstract for %s (%s)", $file->name, $sch->[1]{summary}]);
            $file->content($file_content);
        }

        # create lib/Sah/SchemaR/*.pm
      CREATE_SCHEMAR:
        {
            require Data::Dmp;
            require Data::Sah::Resolve;
            require Dist::Zilla::File::InMemory;

            my $rschema;
            eval {
                $rschema = Data::Sah::Resolve::resolve_schema(
                    {},
                    $sch,
                );
            };
            if ($@) {
                $self->log(["Can't resolve schema (%s), skipped creating SchemaR version for %s", $@, $pkg]);
                last CREATE_SCHEMAR;
            }

            my $rname = $file->name; $rname =~ s!^lib/Sah/Schema/!lib/Sah/SchemaR/!;
            my $rpkg  = $pkg; $rpkg =~ s/^Sah::Schema::/Sah::SchemaR::/;
            my $rfile = Dist::Zilla::File::InMemory->new(
                name => $rname,
                content => join(
                    "",
                    "## no critic: TestingAndDebugging::RequireStrict\n",
                    "package $rpkg;\n",
                    "\n",

                    (defined($self->schemar_preamble) ? ("# preamble code\n", $self->schemar_preamble, "\n\n") : ()),

                    "# DATE\n",
                    "# VERSION\n",
                    "\n",

                    "our \$rschema = ", Data::Dmp::dmp($rschema), ";\n",
                    "\n",

                    (defined($self->schemar_postamble) ? ("# postamble code\n", $self->schemar_postamble, "\n\n") : ()),

                    "1;\n",
                    "# ABSTRACT: $sch->[1]{summary}\n",
                    "\n",

                    "=head1 DESCRIPTION\n\n",
                    "This module is automatically generated by ".__PACKAGE__." during distribution build.\n\n",
                    "A Sah::SchemaR::* module is useful if a client wants to quickly lookup the base type of a schema without having to do any extra resolving. With Sah::Schema::*, one might need to do several lookups if a schema is based on another schema, and so on. Compare for example L<Sah::Schema::poseven> vs L<Sah::SchemaR::poseven>, where in Sah::SchemaR::poseven one can immediately get that the base type is C<int>. Currently L<Perinci::Sub::Complete> uses Sah::SchemaR::* instead of Sah::Schema::* for reduced startup overhead when doing tab completion.\n\n",
                ),
            );
            $self->log(["Creating file %s", $rname]);
            $self->add_file($rfile);
        }

    } # Sah::Schema::*
}

sub gather_files {
    my ($self) = @_;

  SAH_SCHEMA_T: {
        my $filename = "xt/release/sah-schema.t";
        my $filecontent = <<'_';
#!perl

# This file was automatically generated by Dist::Zilla::Plugin::Sah::SchemaBundle.

use Test::More;

eval "use Test::Sah::Schema 0.016";
plan skip_all => "Test::Sah::Schema 0.016 required for testing Sah::Schema::* modules"
  if $@;

sah_schema_modules_ok();
_

        $self->log(["Adding %s ...", $filename]);
        require Dist::Zilla::File::InMemory;
        $self->add_file(
            Dist::Zilla::File::InMemory->new({
                name => $filename,
                content => $filecontent,
            })
          );
    }
}

sub register_prereqs {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    require Data::Sah::Resolve;

    my $self = shift;

    # add DevelopRequires to module required by xt/release/sah-schema.t
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Sah::Schema' => '0.016',
    );

    # add prereqs to base schema modules

    for my $mod (sort keys %{$self->{_used_schema_modules} // {}}) {
        next if $self->is_package_declared($mod);
        $self->log(["Adding prereq to %s", $mod]);
        $self->zilla->register_prereqs({phase=>'runtime'}, $mod => version_from_pmversions($mod) // 0);
    }

    # add prereqs to modules required by schemas when they are compiled to perl
    for my $schemamod (sort keys %{$self->{_our_schema_modules} // {}}) {
        $self->log_debug(["Compiling schema %s", $schemamod]);
        my $nsch = ${"$schemamod\::schema"};

        require Data::Sah;
        my $cd = Data::Sah->get_compiler("perl")->compile(schema => $nsch, schema_is_normalized=>1);

        for my $modrec (@{ $cd->{modules} }) {
            next if $self->is_package_declared($modrec->{name});
            $self->log(["Adding prereq to %s", $modrec->{name}]);
            $self->zilla->register_prereqs({phase=>'runtime'}, $modrec->{name} => version_from_pmversions($modrec->{name}) // 0);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building Sah-SchemaBundle-* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Sah::SchemaBundle - Plugin to use when building Sah-SchemaBundle-* distribution

=head1 VERSION

This document describes version 0.034 of Dist::Zilla::Plugin::Sah::SchemaBundle (from Perl distribution Dist-Zilla-Plugin-Sah-SchemaBundle), released on 2024-02-13.

=head1 SYNOPSIS

In F<dist.ini>:

 [Sah::SchemaBundle]

=head1 DESCRIPTION

This plugin is to be used when building C<Sah-SchemaBundle-*> distribution.

It adds F<xt/release/sah-schema.t> which does the following:

=over

=item * Check that schema is already normalized

=item * Test examples in schema

=back

It does the following to every C<lib/Sah/SchemaBundle/*> .pm file:

=over

=item *

=back

It does the following to every C<lib/Sah/Schema/*> .pm file:

=over

=item * Set module abstract from the schema's summary

=item * Add a prereq to other Sah::Schema::* module if schema depends on those other schemas

=item * Produce pre-resolved editions of schemas into C<lib/Sah/SchemaR/*>

These are useful if a client wants to lookup the base type of a schema without
having to do any extra resolving. Currently L<Perinci::Sub::Complete> uses this
to reduce startup overhead when doing tab completion.

=back

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 exclude_module

Currently this means to exclude loading the specified schema module during
build, skip resolving the schema, skip parsing the schema and extracting
prerequisites from the schema, the and skip creating the corresponding
C<Sah::SchemaR::*> module.

=head2 schemar_preamble

Code to add at the beginning of generated F<Sah/SchemaR/*.pm> files (put after
the C<package> statemnet).

=head2 schemar_postamble

Code to add at the end of generated F<Sah/SchemaR/*.pm> files (put before the
ending C<1;>).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Sah-SchemaBundle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Sah-SchemaBundle>.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::Sah::SchemaBundle>

L<Sah::SchemaBundle>

L<Sah> and L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Sah-SchemaBundle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
