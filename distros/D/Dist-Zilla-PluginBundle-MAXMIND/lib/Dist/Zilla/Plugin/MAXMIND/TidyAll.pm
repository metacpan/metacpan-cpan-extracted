package Dist::Zilla::Plugin::MAXMIND::TidyAll;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.80';

use Code::TidyAll::Config::INI::Reader 0.44;
use List::Util 1.45 qw( uniqstr );
use Path::Class qw( file );
use Path::Iterator::Rule;
use Perl::Critic::Moose 1.05;
use Sort::ByExample qw( sbe );

use Moose;

with qw(
    Dist::Zilla::Role::BeforeBuild
    Dist::Zilla::Role::TextTemplate
);

my $perltidyrc = <<'EOF';
-l=78
-i=4
-ci=4
-se
-b
-bar
-boc
-vt=0
-vtc=0
-cti=0
-pt=1
-bt=1
-sbt=1
-bbt=1
-nolq
-npro
-nsfs
--blank-lines-before-packages=0
--opening-hash-brace-right
--no-outdent-long-comments
--iterations=2
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

[InputOutput::RequireCheckedSyscalls]
functions = :builtins
exclude_functions = sleep
severity = 3

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
add_packages = Carp Test::Builder

[-Subroutines::RequireFinalReturn]

# This incorrectly thinks signatures are prototypes.
[-Subroutines::ProhibitSubroutinePrototypes]

[-ErrorHandling::RequireCarping]

# No need for /xsm everywhere
[-RegularExpressions::RequireDotMatchAnything]
[-RegularExpressions::RequireExtendedFormatting]
[-RegularExpressions::RequireLineBoundaryMatching]

# http://stackoverflow.com/questions/2275317/why-does-perlcritic-dislike-using-shift-to-populate-subroutine-variables
[-Subroutines::RequireArgUnpacking]

# "use v5.14" is more readable than "use 5.014"
[-ValuesAndExpressions::ProhibitVersionStrings]

# Explicitly returning undef is a _good_ thing in many cases, since it
# prevents very common errors when using a sub in list context to construct a
# hash and ending up with a missing value or key.
[-Subroutines::ProhibitExplicitReturnUndef]

# Sometimes I want to write "return unless $x > 4"
[-ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions]
EOF

sub before_build {
    my $self = shift;

    file('tidyall.ini')->spew( $self->_tidyall_ini_content );

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

    file($file)->spew($content);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Creates default tidyall.ini, perltidyrc, and perlcriticrc files if they don't yet exist

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MAXMIND::TidyAll - Creates default tidyall.ini, perltidyrc, and perlcriticrc files if they don't yet exist

=head1 VERSION

version 0.80

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Dist-Zilla-PluginBundle-MAXMIND/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky and MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
