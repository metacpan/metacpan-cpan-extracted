use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::ReportPrereqs;
# ABSTRACT: Report on prerequisite versions during automated testing

our $VERSION = '0.027';

use Dist::Zilla 4 ();

use Moose;
with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::PrereqSource';

use Sub::Exporter::ForMethods;
use Data::Section 0.200002 # encoding and bytes
  { installer => Sub::Exporter::ForMethods::method_installer }, '-setup';

use Data::Dumper;
use Moose::Util::TypeConstraints 'enum';

sub mvp_multivalue_args {
    return qw( include exclude );
}

foreach my $attr (qw( include exclude )) {
    has "${attr}s" => (
        init_arg => $attr,
        is       => 'ro',
        traits   => ['Array'],
        default  => sub { [] },
        handles  => { "${attr}d_modules" => 'elements', },
    );
}

has verify_prereqs => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has version_extractor => (
    is      => 'ro',
    isa     => enum( [qw(ExtUtils::MakeMaker Module::Metadata)] ),
    default => 'ExtUtils::MakeMaker',
);

sub register_prereqs {
    my $self = shift;

    $self->zilla->register_prereqs(
        {
            phase => 'test',
            type  => 'requires',
        },
        'Test::More'             => 0,
        $self->version_extractor => 0,
        'File::Spec'             => 0,
    );

    $self->zilla->register_prereqs(
        {
            phase => 'test',
            type  => 'recommends',
        },
        'CPAN::Meta' => '2.120900',
    );
}

sub gather_files {
    my $self = shift;

    my $data = $self->merged_section_data;
    return unless $data and %$data;

    require Dist::Zilla::File::InMemory;

    for my $filename ( keys %$data ) {
        $self->add_file(
            Dist::Zilla::File::InMemory->new(
                {
                    name    => $filename,
                    content => $self->_munge_test( ${ $data->{$filename} } ),
                }
            )
        );
    }

    require Dist::Zilla::File::FromCode;
    $self->add_file(
        Dist::Zilla::File::FromCode->new(
            {
                name => $self->_dump_filename,
                code => sub { $self->_dump_prereqs },
            }
        )
    );

    return;
}

sub _munge_test {
    my ( $self, $guts ) = @_;
    $guts =~ s{INSERT_VERSION_HERE}{$self->VERSION || '<self>'}e;
    $guts =~ s{INSERT_DD_FILENAME_HERE}{'./' . $self->_dump_filename}e;
    $guts =~ s{INSERT_INCLUDED_MODULES_HERE}{_format_list($self->included_modules)}e;
    $guts =~ s{INSERT_EXCLUDED_MODULES_HERE}{_format_list($self->excluded_modules)}e;
    $guts =~ s{INSERT_VERIFY_PREREQS_CONFIG}{$self->verify_prereqs ? 1 : 0}e;
    $guts =~ s{VERSION_EXTRACTOR_MODULE}{$self->version_extractor}e;
    if ( $self->version_extractor eq 'ExtUtils::MakeMaker' ) {
        $guts
          =~ s'VERSION_EXTRACTION'MM->parse_version( File::Spec->catfile($prefix, $file) )';

    }
    else { # Module::Metadata
        $guts
          =~ s'VERSION_EXTRACTION'Module::Metadata->new_from_file( File::Spec->catfile($prefix, $file) )->version';
    }

    return $guts;
}

sub _dump_filename { 't/00-report-prereqs.dd' }

sub _format_list {
    return join( "\n", map { "  $_" } @_ );
}

sub _dump_prereqs {
    my $self    = shift;
    my $prereqs = $self->zilla->prereqs->as_string_hash;
    return ("do { my "
          . Data::Dumper->new( [$prereqs], ['x'] )->Purity(1)->Sortkeys(1)->Terse(0)->Dump()
          . '  $x;'
          . "\n }" );
}

__PACKAGE__->meta->make_immutable;

1;

#pod =for Pod::Coverage
#pod gather_files
#pod mvp_multivalue_args
#pod register_prereqs
#pod
#pod =head1 SYNOPSIS
#pod
#pod   # in dist.ini
#pod   [Test::ReportPrereqs]
#pod   include = Acme::FYI
#pod   exclude = Acme::Dont::Care
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Dist::Zilla> plugin adds a F<t/00-report-prereqs.t> test file and an accompanying
#pod F<t/00-report-prereqs.dd> data file. It reports
#pod the version of all modules listed in the distribution metadata prerequisites
#pod (including 'recommends', 'suggests', etc.).  However, any 'develop' prereqs
#pod are not reported (unless they show up in another category).
#pod
#pod If a F<MYMETA.json> file exists and L<CPAN::Meta> is installed on the testing
#pod machine, F<MYMETA.json> will be examined for prerequisites in addition, as it
#pod would include any dynamic prerequisites not set in the distribution metadata.
#pod
#pod Versions are reported based on the result of C<parse_version> from
#pod L<ExtUtils::MakeMaker>, which means prerequisite modules are not actually
#pod loaded (which avoids various edge cases with certain modules). Parse errors are
#pod reported as "undef".  If a module is not installed, "missing" is reported
#pod instead of a version string.
#pod
#pod Additionally, if L<CPAN::Meta> is installed, unfulfilled required prerequisites
#pod are reported after the list of all versions based on either F<MYMETA>
#pod (preferably) or F<META> (fallback).
#pod
#pod =head1 CONFIGURATION
#pod
#pod =head2 include
#pod
#pod An C<include> attribute can be specified (multiple times) to add modules
#pod to the report.  This can be useful if there is a module in the dependency
#pod chain that is problematic but is not directly required by this project.
#pod These modules will be listed in an "Other Modules" section at the end of
#pod the report.
#pod
#pod =head2 exclude
#pod
#pod An C<exclude> attribute can be specified (multiple times) to remove
#pod modules from the report (if you had a reason to do so).
#pod
#pod =head2 verify_prereqs
#pod
#pod When set, installed versions of all 'requires' prerequisites are verified
#pod against those specified.  Defaults to true, but requires CPAN::Meta to be installed.
#pod
#pod =head2 version_extractor
#pod
#pod Specifies the module to use to extract each installed prerequisite's
#pod version.  Defaults to L<ExtUtils::MakeMaker>, which is recommended for most
#pod situations.  It can also be specified as L<Module::Metadata>, which can be
#pod useful if L<ExtUtils::MakeMaker>'s mechanism is too naive, or if
#pod L<ExtUtils::MakeMaker> is not already a prerequisite of the distribution.
#pod
#pod =head1 SEE ALSO
#pod
#pod Other Dist::Zilla::Plugins do similar things in slightly different ways that didn't
#pod suit my style and needs.
#pod
#pod =for :list
#pod * L<Dist::Zilla::Plugin::Test::PrereqsFromMeta> -- requires prereqs to be satisfied
#pod * L<Dist::Zilla::Plugin::Test::ReportVersions> -- bundles a copy of YAML::Tiny, reads prereqs only from META.yml, and attempts to load them with C<require>
#pod * L<Dist::Zilla::Plugin::ReportVersions::Tiny> -- static list only, loads modules with C<require>
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::ReportPrereqs - Report on prerequisite versions during automated testing

=head1 VERSION

version 0.027

=head1 SYNOPSIS

  # in dist.ini
  [Test::ReportPrereqs]
  include = Acme::FYI
  exclude = Acme::Dont::Care

=head1 DESCRIPTION

This L<Dist::Zilla> plugin adds a F<t/00-report-prereqs.t> test file and an accompanying
F<t/00-report-prereqs.dd> data file. It reports
the version of all modules listed in the distribution metadata prerequisites
(including 'recommends', 'suggests', etc.).  However, any 'develop' prereqs
are not reported (unless they show up in another category).

If a F<MYMETA.json> file exists and L<CPAN::Meta> is installed on the testing
machine, F<MYMETA.json> will be examined for prerequisites in addition, as it
would include any dynamic prerequisites not set in the distribution metadata.

Versions are reported based on the result of C<parse_version> from
L<ExtUtils::MakeMaker>, which means prerequisite modules are not actually
loaded (which avoids various edge cases with certain modules). Parse errors are
reported as "undef".  If a module is not installed, "missing" is reported
instead of a version string.

Additionally, if L<CPAN::Meta> is installed, unfulfilled required prerequisites
are reported after the list of all versions based on either F<MYMETA>
(preferably) or F<META> (fallback).

=for Pod::Coverage gather_files
mvp_multivalue_args
register_prereqs

=head1 CONFIGURATION

=head2 include

An C<include> attribute can be specified (multiple times) to add modules
to the report.  This can be useful if there is a module in the dependency
chain that is problematic but is not directly required by this project.
These modules will be listed in an "Other Modules" section at the end of
the report.

=head2 exclude

An C<exclude> attribute can be specified (multiple times) to remove
modules from the report (if you had a reason to do so).

=head2 verify_prereqs

When set, installed versions of all 'requires' prerequisites are verified
against those specified.  Defaults to true, but requires CPAN::Meta to be installed.

=head2 version_extractor

Specifies the module to use to extract each installed prerequisite's
version.  Defaults to L<ExtUtils::MakeMaker>, which is recommended for most
situations.  It can also be specified as L<Module::Metadata>, which can be
useful if L<ExtUtils::MakeMaker>'s mechanism is too naive, or if
L<ExtUtils::MakeMaker> is not already a prerequisite of the distribution.

=head1 SEE ALSO

Other Dist::Zilla::Plugins do similar things in slightly different ways that didn't
suit my style and needs.

=over 4

=item *

L<Dist::Zilla::Plugin::Test::PrereqsFromMeta> -- requires prereqs to be satisfied

=item *

L<Dist::Zilla::Plugin::Test::ReportVersions> -- bundles a copy of YAML::Tiny, reads prereqs only from META.yml, and attempts to load them with C<require>

=item *

L<Dist::Zilla::Plugin::ReportVersions::Tiny> -- static list only, loads modules with C<require>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-Test-ReportPrereqs/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-Test-ReportPrereqs>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-Test-ReportPrereqs.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Brendan Byrd Karen Etheridge Kent Fredric Randy Stauner Yanick Champoux

=over 4

=item *

Brendan Byrd <Perl@ResonatorSoft.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Randy Stauner <randy@magnificent-tears.com>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__DATA__
___[ t/00-report-prereqs.t ]___
#!perl

use strict;
use warnings;

# This test was generated by Dist::Zilla::Plugin::Test::ReportPrereqs INSERT_VERSION_HERE

use Test::More tests => 1;

use VERSION_EXTRACTOR_MODULE;
use File::Spec;

# from $version::LAX
my $lax_version_re =
    qr/(?: undef | (?: (?:[0-9]+) (?: \. | (?:\.[0-9]+) (?:_[0-9]+)? )?
            |
            (?:\.[0-9]+) (?:_[0-9]+)?
        ) | (?:
            v (?:[0-9]+) (?: (?:\.[0-9]+)+ (?:_[0-9]+)? )?
            |
            (?:[0-9]+)? (?:\.[0-9]+){2,} (?:_[0-9]+)?
        )
    )/x;

# hide optional CPAN::Meta modules from prereq scanner
# and check if they are available
my $cpan_meta = "CPAN::Meta";
my $cpan_meta_pre = "CPAN::Meta::Prereqs";
my $HAS_CPAN_META = eval "require $cpan_meta; $cpan_meta->VERSION('2.120900')" && eval "require $cpan_meta_pre"; ## no critic

# Verify requirements?
my $DO_VERIFY_PREREQS = INSERT_VERIFY_PREREQS_CONFIG;

sub _max {
    my $max = shift;
    $max = ( $_ > $max ) ? $_ : $max for @_;
    return $max;
}

sub _merge_prereqs {
    my ($collector, $prereqs) = @_;

    # CPAN::Meta::Prereqs object
    if (ref $collector eq $cpan_meta_pre) {
        return $collector->with_merged_prereqs(
            CPAN::Meta::Prereqs->new( $prereqs )
        );
    }

    # Raw hashrefs
    for my $phase ( keys %$prereqs ) {
        for my $type ( keys %{ $prereqs->{$phase} } ) {
            for my $module ( keys %{ $prereqs->{$phase}{$type} } ) {
                $collector->{$phase}{$type}{$module} = $prereqs->{$phase}{$type}{$module};
            }
        }
    }

    return $collector;
}

my @include = qw(
INSERT_INCLUDED_MODULES_HERE
);

my @exclude = qw(
INSERT_EXCLUDED_MODULES_HERE
);

# Add static prereqs to the included modules list
my $static_prereqs = do 'INSERT_DD_FILENAME_HERE';

# Merge all prereqs (either with ::Prereqs or a hashref)
my $full_prereqs = _merge_prereqs(
    ( $HAS_CPAN_META ? $cpan_meta_pre->new : {} ),
    $static_prereqs
);

# Add dynamic prereqs to the included modules list (if we can)
my ($source) = grep { -f } 'MYMETA.json', 'MYMETA.yml';
my $cpan_meta_error;
if ( $source && $HAS_CPAN_META
    && (my $meta = eval { CPAN::Meta->load_file($source) } )
) {
    $full_prereqs = _merge_prereqs($full_prereqs, $meta->prereqs);
}
else {
    $cpan_meta_error = $@;    # capture error from CPAN::Meta->load_file($source)
    $source = 'static metadata';
}

my @full_reports;
my @dep_errors;
my $req_hash = $HAS_CPAN_META ? $full_prereqs->as_string_hash : $full_prereqs;

# Add static includes into a fake section
for my $mod (@include) {
    $req_hash->{other}{modules}{$mod} = 0;
}

for my $phase ( qw(configure build test runtime develop other) ) {
    next unless $req_hash->{$phase};
    next if ($phase eq 'develop' and not $ENV{AUTHOR_TESTING});

    for my $type ( qw(requires recommends suggests conflicts modules) ) {
        next unless $req_hash->{$phase}{$type};

        my $title = ucfirst($phase).' '.ucfirst($type);
        my @reports = [qw/Module Want Have/];

        for my $mod ( sort keys %{ $req_hash->{$phase}{$type} } ) {
            next if $mod eq 'perl';
            next if grep { $_ eq $mod } @exclude;

            my $file = $mod;
            $file =~ s{::}{/}g;
            $file .= ".pm";
            my ($prefix) = grep { -e File::Spec->catfile($_, $file) } @INC;

            my $want = $req_hash->{$phase}{$type}{$mod};
            $want = "undef" unless defined $want;
            $want = "any" if !$want && $want == 0;

            my $req_string = $want eq 'any' ? 'any version required' : "version '$want' required";

            if ($prefix) {
                my $have = VERSION_EXTRACTION;
                $have = "undef" unless defined $have;
                push @reports, [$mod, $want, $have];

                if ( $DO_VERIFY_PREREQS && $HAS_CPAN_META && $type eq 'requires' ) {
                    if ( $have !~ /\A$lax_version_re\z/ ) {
                        push @dep_errors, "$mod version '$have' cannot be parsed ($req_string)";
                    }
                    elsif ( ! $full_prereqs->requirements_for( $phase, $type )->accepts_module( $mod => $have ) ) {
                        push @dep_errors, "$mod version '$have' is not in required range '$want'";
                    }
                }
            }
            else {
                push @reports, [$mod, $want, "missing"];

                if ( $DO_VERIFY_PREREQS && $type eq 'requires' ) {
                    push @dep_errors, "$mod is not installed ($req_string)";
                }
            }
        }

        if ( @reports ) {
            push @full_reports, "=== $title ===\n\n";

            my $ml = _max( map { length $_->[0] } @reports );
            my $wl = _max( map { length $_->[1] } @reports );
            my $hl = _max( map { length $_->[2] } @reports );

            if ($type eq 'modules') {
                splice @reports, 1, 0, ["-" x $ml, "", "-" x $hl];
                push @full_reports, map { sprintf("    %*s %*s\n", -$ml, $_->[0], $hl, $_->[2]) } @reports;
            }
            else {
                splice @reports, 1, 0, ["-" x $ml, "-" x $wl, "-" x $hl];
                push @full_reports, map { sprintf("    %*s %*s %*s\n", -$ml, $_->[0], $wl, $_->[1], $hl, $_->[2]) } @reports;
            }

            push @full_reports, "\n";
        }
    }
}

if ( @full_reports ) {
    diag "\nVersions for all modules listed in $source (including optional ones):\n\n", @full_reports;
}

if ( $cpan_meta_error || @dep_errors ) {
    diag "\n*** WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING ***\n";
}

if ( $cpan_meta_error ) {
    my ($orig_source) = grep { -f } 'MYMETA.json', 'MYMETA.yml';
    diag "\nCPAN::Meta->load_file('$orig_source') failed with: $cpan_meta_error\n";
}

if ( @dep_errors ) {
    diag join("\n",
        "\nThe following REQUIRED prerequisites were not satisfied:\n",
        @dep_errors,
        "\n"
    );
}

pass;

# vim: ts=4 sts=4 sw=4 et:
