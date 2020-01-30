package Dist::Zilla::Plugin::OALDERS::TidyAll;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.000026';

use Code::TidyAll::Config::INI::Reader 0.44;
use List::Util 1.45 qw( uniqstr );
use Path::Iterator::Rule;
use Path::Tiny qw( path );
use Perl::Critic::Freenode 0.021;
use Perl::Critic::Moose 1.05;
use Sort::ByExample qw( sbe );

use Moose;

with qw(
    Dist::Zilla::Role::BeforeBuild
    Dist::Zilla::Role::TextTemplate
);

my $perltidyrc = <<'EOF';
--blank-lines-before-packages=0
--iterations=2
--no-outdent-long-comments
-bar
-boc
-ci=4
-i=4
-l=78
-nolq
-se
-wbb="% + - * / x != == >= <= =~ !~ < > | & >= < = **= += *= &= <<= &&= -= /= |= >>= ||= .= %= ^= x="
EOF

my $perlcriticrc = <<'EOF';
severity = 3
verbose = 11

theme = core + pbp + bugs + maintenance + cosmetic + complexity + security + tests + moose

program-extensions = pl psgi t

exclude = Subroutines::ProhibitCallsToUndeclaredSubs

[BuiltinFunctions::ProhibitStringySplit]
severity = 3

[CodeLayout::RequireTrailingCommas]
severity = 3

[ControlStructures::ProhibitCStyleForLoops]
severity = 3

[Documentation::RequirePackageMatchesPodName]
severity = 3

[Freenode::WhileDiamondDefaultAssignment]
set_themes = core

[InputOutput::RequireCheckedSyscalls]
functions = :builtins
exclude_functions = sleep
severity = 3

[Moose::RequireCleanNamespace]
modules = Moose Moose::Role MooseX::Role::Parameterized Moose::Util::TypeConstraints
cleaners = namespace::autoclean

[NamingConventions::Capitalization]
package_exemptions = [A-Z]\w+|main
file_lexical_variables = [A-Z]\w+|[^A-Z]+
global_variables = :starts_with_upper
scoped_lexical_variables = [A-Z]\w+|[^A-Z]+
severity = 3

# Given our code base, leaving this at 5 would be a huge pain
[Subroutines::ProhibitManyArgs]
max_arguments = 10

[RegularExpressions::ProhibitComplexRegexes]
max_characters = 200

[RegularExpressions::ProhibitUnusualDelimiters]
severity = 3

[Subroutines::ProhibitUnusedPrivateSubroutines]
private_name_regex = _(?!build)\w+

[TestingAndDebugging::ProhibitNoWarnings]
allow = redefine

[ValuesAndExpressions::ProhibitEmptyQuotes]
severity = 3

[ValuesAndExpressions::ProhibitInterpolationOfLiterals]
severity = 3

[ValuesAndExpressions::RequireUpperCaseHeredocTerminator]
severity = 3

[Variables::ProhibitPackageVars]
add_packages = Test::Builder

[-ControlStructures::ProhibitCascadingIfElse]

[-ErrorHandling::RequireCarping]
[-InputOutput::RequireBriefOpen]

[-ValuesAndExpressions::ProhibitConstantPragma]

# No need for /xsm everywhere
[-RegularExpressions::RequireDotMatchAnything]
[-RegularExpressions::RequireExtendedFormatting]
[-RegularExpressions::RequireLineBoundaryMatching]

# by concensus in standup 2015-05-12 we decided to allow return undef
# this is mainly so bar can be written to return undef so that
# foo( bar => bar(), bazz => baz() ) won't cause problems
[-Subroutines::ProhibitExplicitReturnUndef]

# This incorrectly thinks signatures are prototypes.
[-Subroutines::ProhibitSubroutinePrototypes]

# http://stackoverflow.com/questions/2275317/why-does-perlcritic-dislike-using-shift-to-populate-subroutine-variables
[-Subroutines::RequireArgUnpacking]

[-Subroutines::RequireFinalReturn]

# "use v5.14" is more readable than "use 5.014"
[-ValuesAndExpressions::ProhibitVersionStrings]
EOF

sub before_build {
    my $self = shift;

    path('tidyall.ini')->spew( $self->_tidyall_ini_content );

    $self->_maybe_write_file( 'perlcriticrc', $perlcriticrc );
    $self->_maybe_write_file( 'perltidyrc',   $perltidyrc );

    return;
}

sub _tidyall_ini_content {
    my $self = shift;

    return $self->_new_tidyall_ini
        unless -e 'tidyall.ini';

    return $self->_munged_tidyall_ini;
}

sub _new_tidyall_ini {
    my $self = shift;

    my $perl_select = '**/*.{pl,pm,t,psgi}';
    my %tidyall     = (
        'PerlTidy' => {
            select => [$perl_select],
            ignore => [ $self->_default_perl_ignore ],
        },
        'PerlCritic' => {
            select => [$perl_select],
            ignore => [ $self->_default_perl_ignore ],
        },
        'Test::Vars' => {
            select => ['**/*.pm'],
            ignore => [ $self->_default_perl_ignore ],
        },
    );

    return $self->_config_to_ini( \%tidyall );
}

sub _munged_tidyall_ini {
    my $self = shift;

    my $tidyall
        = Code::TidyAll::Config::INI::Reader->read_file('tidyall.ini');

    my %has_default_ignore
        = map { $_ => 1 } qw( PerlTidy PerlCritic Test::Vars );
    for my $section ( grep { $has_default_ignore{$_} } sort keys %{$tidyall} )
    {
        $tidyall->{$section}{ignore} = [
            uniqstr(
                @{ $tidyall->{$section}{ignore} },
                $self->_default_perl_ignore,
            )
        ];
    }

    return $self->_config_to_ini($tidyall);
}

sub _default_perl_ignore {
    my $self = shift;

    my @ignore = qw(
        .build/**/*
        blib/**/*
        t/00-*
        t/author-*
        t/release-*
        t/zzz-*
        xt/**/*
    );

    my $dist = $self->zilla->name;
    push @ignore, "$dist-*/**/*";

    return @ignore;
}

sub _config_to_ini {
    my $self    = shift;
    my $tidyall = shift;

    my @xt_files = Path::Iterator::Rule->new->file->name(qr/\.t$/)->all('xt');

    if (@xt_files) {
        my $suffix = 'non-auto-generated xt';
        for my $plugin (qw( PerlCritic PerlTidy )) {
            $tidyall->{ $plugin . q{ } . $suffix }{select} = \@xt_files;
        }
    }

    for my $section ( keys %{$tidyall} ) {
        if ( $section =~ /PerlTidy/ ) {
            $tidyall->{$section}{argv} = '--profile=$ROOT/perltidyrc';
        }
        elsif ( $section =~ /PerlCritic/ ) {
            $tidyall->{$section}{argv} = '--profile=$ROOT/perlcriticrc';
        }
    }

    my $sorter = sbe(
        [ 'select', 'ignore' ],
        {
            fallback => sub { $_[0] cmp $_[1] },
        },
    );

    my $ini = q{};
    for my $section ( sort keys %{$tidyall} ) {
        $ini .= "[$section]\n";

        for my $key ( $sorter->( keys %{ $tidyall->{$section} } ) ) {
            for my $val (
                sort ref $tidyall->{$section}{$key}
                ? @{ $tidyall->{$section}{$key} }
                : $tidyall->{$section}{$key}
            ) {

                $ini .= "$key = $val\n";
            }
        }

        $ini .= "\n";
    }

    chomp $ini;

    return $ini;
}

sub _maybe_write_file {
    my $self    = shift;
    my $file    = shift;
    my $content = shift;

    return if -e $file;

    path($file)->spew($content);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Creates default tidyall.ini, perltidyrc, and perlcriticrc files if they don't yet exist

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::OALDERS::TidyAll - Creates default tidyall.ini, perltidyrc, and perlcriticrc files if they don't yet exist

=head1 VERSION

version 0.000026

=for Pod::Coverage .*

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 ACKNOWLEDGEMENTS

This module was copied from L<Dist::Zilla::Plugin::MAXMIND::TidyAll>

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
