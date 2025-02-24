package Dist::Zilla::Plugin::Rinci::AddPrereqs;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-10'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Rinci-AddPrereqs'; # DIST
our $VERSION = '0.145'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
    'Dist::Zilla::Role::DumpPerinciCmdLineScript',
);

use Perinci::Access;
use Perinci::Sub::Normalize qw(normalize_function_metadata);
use PMVersions::Util qw(version_from_pmversions);
use Version::Util qw(max_version);

sub munge_files {
    my $self = shift;

    # roughly list all packages in this dist, from the filenames. XXX does dzil
    # already provide this?
    my %pkgs;
    for (@{ $self->found_files }) {
        next unless $_->name =~ m!\Alib/(.+)\.pm\z!;
        my $pkg = $1; $pkg =~ s!/!::!g;
        $pkgs{$pkg} = $_->name;
    }
    $self->{_packages} = \%pkgs;

    $self->{_added_prereqs} = {};

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub _add_prereq {
    my ($self, $mod, $ver) = @_;
    return if defined($self->{_added_prereqs}{$mod}) &&
        $self->{_added_prereqs}{$mod} >= $ver;
    $self->log("Adding prereq: $mod => $ver");
    $self->zilla->register_prereqs({phase=>'runtime'}, $mod, $ver);
    $self->{_added_prereqs}{$mod} = $ver;
}

sub _add_prereqs_from_func_meta {

    my ($self, $meta, $cli_info) = @_;

    $meta = normalize_function_metadata($meta);

    {
        require Perinci::Sub::Util::DepModule;
        my $mods = Perinci::Sub::Util::DepModule::get_required_dep_modules($meta);
        $self->_add_prereq($_ => $mods->{$_} // 0) for keys %$mods;
    }

    {
        my $args = $meta->{args};
        last unless $args;
        for my $arg_name (keys %$args) {
            my $arg_spec = $args->{$arg_name};
            my $e;

            # from x.schema.{entity,element_entity} & x.completion (cli scripts
            # only)
            $e = $arg_spec->{'x.schema.entity'};
            if ($e && $cli_info) {
                my $pkg = "Perinci::Sub::ArgEntity::$e";
                $self->_add_prereq($pkg => version_from_pmversions($pkg) // 0);
            }
            $e = $arg_spec->{'x.schema.element_entity'};
            if ($e && $cli_info) {
                my $pkg = "Perinci::Sub::ArgEntity::$e";
                $self->_add_prereq($pkg => version_from_pmversions($pkg) // 0);
            }
            $e = $arg_spec->{'x.completion'};
            if ($e && $cli_info) {
                {
                    my $xcomp_name;
                    if (ref $e eq 'ARRAY') {
                        $xcomp_name = $e->[0];
                    } elsif (!ref $e) {
                        $xcomp_name = $e;
                    } else {
                        $self->log_fatal("Can't handle x.completion value $e");
                    }
                    my $pkg = "Perinci::Sub::XCompletion::$xcomp_name";
                    $self->_add_prereq($pkg => version_from_pmversions($pkg) // 0);
                }
            }
            $e = $arg_spec->{'x.element_completion'};
            if ($e && $cli_info) {
                my $xcomp_name;
                if (ref $e eq 'CODE') {
                    # can't do anything about it for now
                } elsif (ref $e eq 'ARRAY') {
                    $xcomp_name = $e->[0];
                } else {
                    $xcomp_name = $e;
                }
                my $pkg = "Perinci::Sub::XCompletion::$xcomp_name";
                $self->_add_prereq($pkg => version_from_pmversions($pkg) // 0);
            }

            # from schema (coerce rule modules, etc) (cli scripts only)
            {
                last unless $cli_info;
                my $sch = $arg_spec->{'schema'};
                last unless $sch;
                state $plc = do {
                    require Data::Sah;
                    Data::Sah->new->get_compiler('perl');
                };
                my $cd = $plc->compile(schema => $sch);
                for my $mod (@{ $cd->{modules} }) {
                    if ($cli_info->[3]{'func.is_inline'}) {
                        next unless $mod->{phase} eq 'runtime';
                    } else {
                        next unless $mod->{phase} eq 'compile';
                    }
                    $self->_add_prereq($mod->{name} => max_version(
                        $mod->{version} // 0,
                        version_from_pmversions($mod->{name}) // 0,
                    ));
                }
            }
        }
    }

    # property modules
    {
        require Perinci::Sub::Util::PropertyModule;
        my $mods = Perinci::Sub::Util::PropertyModule::get_required_property_modules($meta);
        $self->_add_prereq($_ => version_from_pmversions($_) // 0) for @$mods;
    }
}

sub munge_file {
    no strict 'refs';

    my ($self, $file) = @_;

    state $pa = Perinci::Access->new;

    local @INC = ('lib', @INC);

    if (my ($pkg_pm, $pkg) = $file->name =~ m!^lib/((.+)\.pm)$!) {
        # XXX to support non-ondisk modules later, we can dump to some $tmpdir
        # and add $tmpdir to @INC.
        unless ($file->isa("Dist::Zilla::File::OnDisk")) {
            $self->log_debug(["skipping module %s: not an ondisk file, currently only ondisk modules are processed", $file->name]);
            return;
        }

        $pkg =~ s!/!::!g;
        require $pkg_pm;
        my $spec = \%{"$pkg\::SPEC"};
        $self->log_debug(["Found module with non-empty %%SPEC: %s (%s)", $file->name, $pkg])
            if keys %$spec;
        for my $func (grep {/\A\w+\z/} sort keys %$spec) {
            $self->log_debug(["Found function from \%%SPEC: %s\::%s", $pkg, $func]);
            $self->_add_prereqs_from_func_meta($spec->{$func}, 0);
        }
    } else {
        my $res = $self->dump_perinci_cmdline_script($file);
        if ($res->[0] == 412) {
            $self->log_debug(["Skipped %s: %s",
                              $file->name, $res->[1]]);
            return;
        }
        $self->log_fatal(["Can't dump Perinci::CmdLine script '%s': %s - %s",
                          $file->name, $res->[0], $res->[1]]) unless $res->[0] == 200;
        my $cli = $res->[2];
        my $cli_info = $res->[3]{'func.detect_res'};

        $self->log_debug(["Found Perinci::CmdLine-based script: %s", $file->name]);

        my @urls;
        push @urls, $cli->{url};
        if ($cli->{subcommands} && ref($cli->{subcommands}) eq 'HASH') {
            push @urls, $_->{url} for values %{ $cli->{subcommands} };
        }
        my %seen_urls;
        for my $url (@urls) {
            next unless defined $url;
            next if $seen_urls{$url}++;

            # only inspect local function Riap URL
            next unless $url =~ m!\A(?:pl:)?/(.+)/[^/]+\z!;

            # add prereq to package, unless it's from our own dist
            my $pkg = $1; $pkg =~ s!/!::!g;

            my @metas;
            if ($pkg eq 'main') {
                my $fmetas = $res->[3]{'func.meta'};
                next unless $fmetas;
                push @metas, values %$fmetas;
            } else {
                $self->_add_prereq($pkg => version_from_pmversions($pkg) // 0)
                    unless $self->{_packages}{$pkg};
                $self->log_debug(["Performing Riap request: meta => %s", $url]);
                my $res = $pa->request(meta => $url);
                $self->log_fatal(["Can't meta %s: %s-%s", $url, $res->[0], $res->[1]])
                    unless $res->[0] == 200;
                push @metas, $res->[2];
            }

            for my $meta (@metas) {
                $self->_add_prereqs_from_func_meta($meta, $cli_info);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Add prerequisites from Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Rinci::AddPrereqs - Add prerequisites from Rinci metadata

=head1 VERSION

This document describes version 0.145 of Dist::Zilla::Plugin::Rinci::AddPrereqs (from Perl distribution Dist-Zilla-Plugin-Rinci-AddPrereqs), released on 2020-06-10.

=head1 SYNOPSIS

In C<dist.ini>:

 [Rinci::AddPrereqs]

=head1 DESCRIPTION

This plugin will first collect L<Rinci> metadata from the following:

=over

=item * %SPEC variable in all modules of the distribution

=item * Perinci::CmdLine scripts

This plugin will also search all L<Perinci::CmdLine>-based scripts, request
Rinci function metadata from all local Riap URI's used by the scripts. Plus,
will add a dependency to the module mentioned in the local Riap URI. For
example, in Perinci::CmdLine-based script:

 url => '/MyApp/myfunc',

The plugin will retrieve the Rinci metadata in C<MyApp> module as well as add a
runtime-requires dependency to the C<MyApp> module (unless C<MyApp> is in the
same/current distribution).

=back

=head2 Prereqs from Rinci function metadata

The following prereqs will be added according to information in Rinci L<function
metadata|Rinci::function>.

=over

=item * Additional property module

If the Rinci metadata contains non-standard properties, which require
corresponding C<Perinci::Sub::Property::NAME> modules, then these modules will
be added as prereqs.

=item * schema

Currently will only do this for Rinci metadata for CLI scripts.

The plugin will compile every schema of function argument using L<Data::Sah>,
then add a prereq to each module required by the generated argument validator
produced by Data::Sah. For example, in Rinci metadata:

 args => {
     arg1 => {
         schema => 'color::rgb24*',
         ...
     },
     ...
 }

When the C<color::rgb24> schema is compiled, the following modules are required:
L<Sah::Schema::color::rgb24>,
L<Data::Sah::Coerce::perl::To_str::From_str::rgb24_from_colorname_X_or_code>.
The generated validator code requires these modules: L<strict>, L<warnings>,
L<Graphics::ColorNames>, L<Graphics::ColorNames::X>. All of which will be added
as prereq.

=item * x.schema.entity, x.schema.element_entity

Currently will only do this for Rinci metadata for CLI scripts.

For every entity mentioned in C<x.schema.entity> or C<x.schema.element_entity>
in argument specification in function metadata, the plugin will add a prereq to
C<Perinci::Sub::ArgEntity::NAME>. For example, in
Rinci metadata:

 args => {
     arg1 => {
         'x.schema.entity' => 'dirname',
          ...
     },
     ...
 }

(Note that C<x.schema.entity> is deprecated.)

=item * x.completion, x.element_completion

For every completion mentioned in C<x.completion> or C<x.element_completion> in
argument specification in function metadata, which can have the value of C<NAME>
or C<[NAME, ARGS]>, the plugin will add a prereq to corresponding
C<Perinci::Sub::XCompletion::NAME>. For example, in Rinci metadata:

 args => {
     arg1 => {
         'schema' => 'str*',
         'x.completion' => 'colorname',
         ...
     },
     ...
 }

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Rinci-AddPrereqs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Rinci-AddPrereqs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Rinci-AddPrereqs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
