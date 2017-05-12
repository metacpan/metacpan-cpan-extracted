package Dist::Zilla::Plugin::Test::ReportMetadata;

use 5.008;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Data::Dumper;
use Dist::Zilla 4 ();
use File::Spec;
use Moose;
use Sub::Exporter::ForMethods;

use Data::Section 0.200002 # encoding and bytes
  { installer => Sub::Exporter::ForMethods::method_installer }, '-setup';

with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::PrereqSource';

has 'env_vars' => is => 'ro', traits => [ 'Array' ], default => sub {
   [ qw( AUTHOR_TESTING AUTOMATED_TESTING EXTENDED_TESTING
         NONINTERACTIVE_TESTING PERL_CPAN_REPORTER_CONFIG
         PERL_CR_SMOKER_CURRENT PERL5_CPAN_IS_RUNNING
         PERL5_CPANPLUS_IS_VERSION TEST_CRITIC TEST_SPELLING ) ] },
   handles     => { 'display_vars' => 'elements', }, init_arg => 'env_var';

has 'excludes' => is => 'ro', traits => [ 'Array' ], default => sub { [] },
   handles     => { 'excluded_modules' => 'elements', }, init_arg => 'exclude';

has 'includes' => is => 'ro', traits => [ 'Array' ], default => sub { [] },
   handles     => { 'included_modules' => 'elements', }, init_arg => 'include';

has 'verify_prereqs' => is => 'ro', isa => 'Bool', default => 1;

sub _dump_filename {
   return File::Spec->catfile( 't', '00report-metadata.dd' );
}

sub _dump_prereqs {
   my $self    = shift;
   my $prereqs = $self->zilla->prereqs->as_string_hash;
   my $dumper  = Data::Dumper->new( [ $prereqs ], [ 'x' ] );
   my $dumped  = $dumper->Purity( 1 )->Sortkeys( 1 )->Terse( 0 )->Dump();

   return "do { my ${dumped}  \$x;\n }";
}

sub _format_list {
    return join "\n", map { "  ${_}" } @_;
}

sub _munge_test {
   my ($self, $guts) = @_;

   $guts =~ s{INSERT_VERSION_HERE}{$self->VERSION || '<self>'}e;
   $guts =~ s{INSERT_DD_FILENAME_HERE}{$self->_dump_filename}e;
   $guts =~ s{INSERT_DISPLAY_VARS_HERE}{_format_list( $self->display_vars )}e;
   $guts =~ s{INSERT_INCLUDED_MODULES_HERE}{_format_list( $self->included_modules )}e;
   $guts =~ s{INSERT_EXCLUDED_MODULES_HERE}{_format_list( $self->excluded_modules )}e;
   $guts =~ s{INSERT_VERIFY_PREREQS_CONFIG}{$self->verify_prereqs ? 1 : 0}e;
   return $guts;
}

sub gather_files {
   my $self = shift; my $data = $self->merged_section_data;

   $data and %{ $data } or return;

   require Dist::Zilla::File::InMemory;

   for my $filename (keys %{ $data }) {
      $self->add_file
         ( Dist::Zilla::File::InMemory->new
           ( { name    => $filename,
               content => $self->_munge_test( ${ $data->{ $filename } } ) } ) );
   }

   require Dist::Zilla::File::FromCode;

   $self->add_file
      ( Dist::Zilla::File::FromCode->new
        ( { name => $self->_dump_filename,
            code => sub { $self->_dump_prereqs }, } ) );

   return;
}

sub mvp_multivalue_args {
   return qw( env_var exclude include );
}

sub register_prereqs {
   my $self = shift; my $zilla = $self->zilla;

   $zilla->register_prereqs
      ( { phase => 'test', type => 'requires', },
        'File::Spec'       => 0,
        'Module::Metadata' => 0,
        'Sys::Hostname'    => 0, );

   $zilla->register_prereqs
      ( { phase => 'test', type  => 'recommends', },
        'CPAN::Meta' => '2.120900', );

   return;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-dist-zilla-plugin-test-reportmetadata"><img src="https://travis-ci.org/pjfl/p5-dist-zilla-plugin-test-reportmetadata.svg?branch=master" alt="Travis CI Badge"></a>
<a href="http://badge.fury.io/pl/Dist-Zilla-Plugin-Test-ReportMetadata"><img src="https://badge.fury.io/pl/Dist-Zilla-Plugin-Test-ReportMetadata.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Test-ReportMetadata"><img src="http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Test-ReportMetadata.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Dist::Zilla::Plugin::Test::ReportMetadata - Report on prerequisite versions during automated testing

=head1 Synopsis

   # In dist.ini
   [Test::ReportMetadata]

=head1 Description

The is a clone of L<Dist::Zilla::Plugin::Test::ReportPrereqs> but with the
dependency on L<ExtUtils::MakeMaker> replaced with one on
L<Module::Metadata>. If you are using L<Module::Build> then L<Module::Metadata>
is already a dependency

Versions are reported based on the result of the C<version> attribute from
L<Module::Metadata>

Additionally a selection of environment variables are also displayed

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<env_vars>

An array reference of environment variable names displayed on the test report.
Set using the multivalued initialisation argument C<env_var>. If the list
has no values then nothing is printed. An empty list can be set with

   [Test::ReportMetadata]
   env_var = none

=item C<excludes>

An array reference of module names to exclude from the test report.
Set using the multivalued initialisation argument C<exclude>

=item C<includes>

An array reference of module names to include in the test report.
Set using the multivalued initialisation argument C<include>

=item C<verify_prereqs>

A boolean defaulting to true. If true emits lots of warnings if prerequisites
are not satisfied

=back

=head1 Subroutines/Methods

=head2 C<gather_files>

Required by L<Dist::Zilla::Role::FileGatherer>

=head2 C<mvp_multivalue_args>

Returns a list of configuration attribute names that are treated as
multi valued

=head2 C<register_prereqs>

Required by L<Dist::Zilla::Role::PrereqSource>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Data::Dumper>

=item L<Data::Section>

=item L<Dist::Zilla>

=item L<Moose>

=item L<Sub::Exporter::ForMethods>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Test-ReportMetadata.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:

__DATA__
___[ t/00report-metadata.t ]___
#!perl
# Generated by Dist::Zilla::Plugin::Test::ReportMetadata INSERT_VERSION_HERE

use strict;
use warnings;

use File::Spec;
use Module::Metadata;
use Sys::Hostname;

# Instead of importing from Test::More
sub diag (;@) {
   warn @_; return;
}

sub pass () {
   print "ok 1\n1..1\n"; return;
}

# Hide optional CPAN::Meta modules from prereq scanner
# and check if they are available
my $CPAN_META         = 'CPAN::Meta';
my $CPAN_META_PRE     = 'CPAN::Meta::Prereqs';
my @DISPLAY_VARS      = grep { $_ ne 'none' } qw( INSERT_DISPLAY_VARS_HERE );
my $DO_VERIFY_PREREQS = INSERT_VERIFY_PREREQS_CONFIG; # Verify requirements?
my @EXCLUDE           = qw( INSERT_EXCLUDED_MODULES_HERE );
my $HOST              = lc hostname;
my @INCLUDE           = qw( INSERT_INCLUDED_MODULES_HERE );
my $LAX_VERSION_RE    = # From $version::LAX
   qr{(?: undef | (?: (?:[0-9]+) (?: \. | (?:\.[0-9]+) (?:_[0-9]+)? )?
                   |
                   (?:\.[0-9]+) (?:_[0-9]+)?
                   ) | (?:
                        v (?:[0-9]+) (?: (?:\.[0-9]+)+ (?:_[0-9]+)? )?
                        |
                        (?:[0-9]+)? (?:\.[0-9]+){2,} (?:_[0-9]+)?
                        )
       )}x;
my $OSNAME            = lc $^O;
# Add static prereqs to the included modules list
my $STATIC_PREREQS    = do './INSERT_DD_FILENAME_HERE';

my $diag_env = sub {
   my $k = shift; my $v = exists $ENV{ $k } ? $ENV{ $k } : 'undef';

   return diag sprintf "    \$%-30s   %s\n", $k, $v;
};
my $max = sub {
   my $v = shift; $v = ( $_ > $v ) ? $_ : $v for @_; return $v;
};
my $merge_prereqs = sub {
   my ($collector, $prereqs) = @_;

   ref $collector eq $CPAN_META_PRE # CPAN::Meta::Prereqs object
      and return $collector->with_merged_prereqs
         ( CPAN::Meta::Prereqs->new( $prereqs ) );

   for my $phase (keys %{ $prereqs }) { # Raw hashrefs
      for my $type (keys %{ $prereqs->{ $phase } }) {
         for my $module (keys %{ $prereqs->{ $phase }{ $type } }) {
            $collector->{ $phase }{ $type }{ $module }
               = $prereqs->{ $phase }{ $type }{ $module };
         }
      }
   }

   return $collector;
};
my $cpan_meta_ver = "${CPAN_META}->VERSION( '2.120900' )";
my $has_cpan_meta = eval "require ${CPAN_META}; ${cpan_meta_ver}"
                 && eval "require ${CPAN_META_PRE}";
# Merge all prereqs (either with ::Prereqs or a hashref)
my $full_prereqs  = $merge_prereqs->
   ( ( $has_cpan_meta ? $CPAN_META_PRE->new : {} ), $STATIC_PREREQS );
# Add dynamic prereqs to the included modules list (if we can)
my ($source)      = grep { -f } 'MYMETA.json', 'MYMETA.yml';

if ($source and $has_cpan_meta) {
   if (my $meta = eval { CPAN::Meta->load_file( $source ) }) {
      $full_prereqs = $merge_prereqs->( $full_prereqs, $meta->prereqs );
   }
}
else { $source = 'static metadata' }

my @full_reports;
my @dep_errors;
my $req_hash = $has_cpan_meta ? $full_prereqs->as_string_hash : $full_prereqs;

for my $mod (@INCLUDE) { # Add static includes into a fake section
   $req_hash->{other}{modules}{ $mod } = 0;
}

for my $phase (qw( configure build test runtime develop other )) {
   $req_hash->{ $phase } or next;
   $phase eq 'develop' and not $ENV{AUTHOR_TESTING} and next;

   for my $type ( qw( requires recommends suggests conflicts modules ) ) {
      $req_hash->{ $phase }{ $type } or next;

      my $title   = (ucfirst $phase).' '.(ucfirst $type);
      my @reports = [ qw( Module Want Have ) ];

      for my $mod (sort keys %{ $req_hash->{ $phase }{ $type } }) {
         $mod eq 'perl' and next; grep { $_ eq $mod } @EXCLUDE and next;

         my $file     = $mod; $file =~ s{ :: }{/}gmx; $file .= '.pm';
         my ($prefix) = grep { -e File::Spec->catfile( $_, $file ) } @INC;
         my $want     = $req_hash->{ $phase }{ $type }{ $mod };

         defined $want or $want = 'undef';
         not $want and $want == 0 and $want = 'any';

         my $req_string = $want eq 'any'
                        ? 'any version required' : "version '${want}' required";

         if ($prefix) {
            my $path = File::Spec->catfile( $prefix, $file );
            my $info = Module::Metadata->new_from_file( $path );
            my $have = $info->version;

            defined $have or $have = 'undef';
            push @reports, [ $mod, $want, $have ];

            if ($DO_VERIFY_PREREQS and $has_cpan_meta and $type eq 'requires') {
               if ($have !~ m{ \A $LAX_VERSION_RE \z }mx) {
                  push @dep_errors,
                    "${mod} version '${have}' cannot be parsed (${req_string})";
               }
               elsif ( !$full_prereqs->requirements_for( $phase, $type )->accepts_module( $mod => $have ) ) {
                  push @dep_errors,
                  "${mod} version '${have}' is not in required range '${want}'";
               }
            }
         }
         else {
            push @reports, [ $mod, $want, 'missing' ];

            $DO_VERIFY_PREREQS and $type eq 'requires'
               and push @dep_errors, "${mod} is not installed (${req_string})";
         }
      }

      if (@reports) {
         push @full_reports, "=== ${title} ===\n\n";

         my $ml = $max->( map { length $_->[ 0 ] } @reports );
         my $wl = $max->( map { length $_->[ 1 ] } @reports );
         my $hl = $max->( map { length $_->[ 2 ] } @reports );

         if ($type eq 'modules') {
            splice @reports, 1, 0, [ '-' x $ml, q(), '-' x $hl ];
            push @full_reports, map { sprintf "    %*s %*s\n", -$ml,
                                      $_->[ 0 ], $hl, $_->[ 2 ] } @reports;
         }
         else {
            splice @reports, 1, 0, [ '-' x $ml, '-' x $wl, '-' x $hl ];
            push @full_reports, map { sprintf "    %*s %*s %*s\n", -$ml,
                                      $_->[ 0 ], $wl, $_->[ 1 ], $hl,
                                      $_->[ 2 ] } @reports;
         }

         push @full_reports, "\n";
      }
   }
}

if (@DISPLAY_VARS) {
   diag "\nOS: ${OSNAME}, Host: ${HOST}\n";
   diag "\n=== Environment variables ===\n\n";

   $diag_env->( $_ ) for (@DISPLAY_VARS);
}

if (@full_reports) {
   diag "\nVersions for all modules listed in ${source} (including optional ones):\n\n", @full_reports;
}

if (@dep_errors) {
   diag join "\n",
             "\n*** WARNING WARNING WARNING WARNING WARNING WARNING ***\n",
             "The following REQUIRED prerequisites were not satisfied:\n",
             @dep_errors, "\n";
}

pass;
exit 0;
