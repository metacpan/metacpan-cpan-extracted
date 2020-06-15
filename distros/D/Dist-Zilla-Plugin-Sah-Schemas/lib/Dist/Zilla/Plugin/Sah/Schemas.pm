package Dist::Zilla::Plugin::Sah::Schemas;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Sah-Schemas'; # DIST
our $VERSION = '0.020'; # VERSION

use 5.010001;
use strict;
use warnings;
use Moose;

use PMVersions::Util qw(version_from_pmversions);
use Require::Hook::DzilBuild;

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

use namespace::autoclean;

sub mvp_multivalue_args { qw(exclude_module) }

sub _load_schema_modules {
    my $self = shift;

    return $self->{_our_schema_modules} if $self->{_loaded_schema_modules}++;

    local @INC = (Require::Hook::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

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

sub _load_schemas_modules {
    my $self = shift;

    return $self->{_our_schemas_modules} if $self->{_loaded_schemas_modules}++;

    local @INC = (Require::Hook::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %res;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!^lib/(Sah/Schemas/.+\.pm)$!;
        my $pkg_pm = $1;
        (my $pkg = $pkg_pm) =~ s/\.pm$//; $pkg =~ s!/!::!g;
        require $pkg_pm;
        $res{$pkg} = $file;
    }

    $self->{_our_schemas_modules} = \%res;
}

sub munge_files {
    no strict 'refs';

    my $self = shift;

    $self->{_used_schema_modules} //= {};

    $self->_load_schema_modules;
    $self->_load_schemas_modules;

  SAH_SCHEMAS_MODULE:
    for my $pkg (sort keys %{ $self->{_our_schemas_modules} }) {
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
                            return_intermediates => 1,
                        },
                        $nsubsch);
                };
                if ($@) {
                    $self->log(["Can't resolve schema (%s), skipped collecting base schemas for %s", $@, $pkg]);
                    last COLLECT_BASE_SCHEMAS;
                }
                my $intermediates = $res->[2];
                for my $i (0..$#{$intermediates}-1) {
                    my $mod = "Sah::Schema::$intermediates->[$i]";
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
                    {return_intermediates => 1},
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
                    "package $rpkg;\n",
                    "\n",

                    "# DATE\n",
                    "# VERSION\n",
                    "\n",

                    "our \$rschema = ", Data::Dmp::dmp($rschema), ";\n",
                    "\n",

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

# This file was automatically generated by Dist::Zilla::Plugin::Sah::Schemas.

use Test::More;

eval "use Test::Sah::Schema 0.009";
plan skip_all => "Test::Sah::Schema 0.001 required for testing Sah::Schema::* modules"
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
    no strict 'refs';
    require Data::Sah::Resolve;

    my $self = shift;

    # add DevelopRequires to module required by xt/release/sah-schema.t
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Sah::Schema' => '0',
    );

    # add prereqs to base schema modules

    for my $mod (sort keys %{$self->{_used_schema_modules} // {}}) {
        next if $self->is_package_declared($mod);
        $self->log(["Adding prereq to %s", $mod]);
        $self->zilla->register_prereqs({phase=>'runtime'}, $mod => version_from_pmversions($mod) // 0);
    }

    for my $mod (sort keys %{$self->{_our_schema_modules} // {}}) {
        my $nsch = ${"$mod\::schema"};
        my $rsch = Data::Sah::Resolve::resolve_schema($nsch);
        # add prereqs to XCompletion modules
        {
            my $xc = $nsch->[1]{'x.completion'};
            last unless $xc;
            last if ref $xc eq 'CODE';
            $xc = $xc->[0] if ref $xc eq 'ARRAY';
            my $xcmod = "Perinci::Sub::XCompletion::$xc";
            next if $self->is_package_declared($xcmod);
            $self->log(["Adding prereq to %s", $xcmod]);
            $self->zilla->register_prereqs({phase=>'runtime'}, $xcmod => version_from_pmversions($xcmod) // 0);
        }
        # add prereqs to coerce modules
        for my $key ('x.coerce_rules', 'x.perl.coerce_rules') {
            my $crr = $nsch->[1]{$key};
            next unless $crr && @$crr;
            for my $rule (@$crr) {
                next unless $rule =~ /\A\w+(::\w+)*\z/;
                my $crmod = "Data::Sah::Coerce::perl::To_$rsch->[0]::$rule";
                next if $self->is_package_declared($crmod);
                $self->log(["Adding prereq to %s", $crmod]);
                $self->zilla->register_prereqs({phase=>'runtime'}, $crmod => version_from_pmversions($crmod) // 0);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building Sah-Schemas-* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Sah::Schemas - Plugin to use when building Sah-Schemas-* distribution

=head1 VERSION

This document describes version 0.020 of Dist::Zilla::Plugin::Sah::Schemas (from Perl distribution Dist-Zilla-Plugin-Sah-Schemas), released on 2020-06-13.

=head1 SYNOPSIS

In F<dist.ini>:

 [Sah::Schemas]

=head1 DESCRIPTION

This plugin is to be used when building C<Sah-Schemas-*> distribution.

It adds F<xt/release/sah-schema.t> which does the following:

=over

=item * Check that schema is already normalized

=item * Test examples in schema

=back

It does the following to every C<lib/Sah/Schemas/*> .pm file:

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Sah-Schemas>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Sah-Schemas>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Sah-Schemas>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver::Plugin::Sah::Schemas>

L<Sah::Schemas>

L<Sah> and L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
