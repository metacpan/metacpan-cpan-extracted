package Dist::Zilla::App::Command::listdeps 6.032;
# ABSTRACT: print your distribution's prerequisites

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod   $ dzil listdeps | cpan
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a command plugin for L<Dist::Zilla>. It provides the C<listdeps>
#pod command, which prints your distribution's prerequisites. You could pipe that
#pod list to a CPAN client like L<cpan> to install all of the dependencies in one
#pod quick go.
#pod
#pod =head1 OPTIONS
#pod
#pod =head2 --author (or --develop)
#pod
#pod Include author dependencies (those listed under C<develop_requires>).
#pod
#pod =head2 --missing
#pod
#pod List only dependencies which are unsatisfied.
#pod
#pod =head2 --requires / --no-requires
#pod
#pod Add required dependencies to the list (or don't).
#pod
#pod Default: on.
#pod
#pod =head2 --recommends / --no-recommends
#pod
#pod Add recommended dependencies to the list (or don't).
#pod
#pod Default: on.
#pod
#pod =head2 --suggests / --no-suggests
#pod
#pod Add suggested dependencies to the list (or don't).
#pod
#pod Default: off.
#pod
#pod =head2 --versions
#pod
#pod Also display the required versions of listed modules.
#pod
#pod =head2 --cpanm-versions
#pod
#pod Also display the required versions of listed modules, but in a format suitable
#pod for piping into F<cpanm>.
#pod
#pod =head2 --json
#pod
#pod Lists all prerequisites in JSON format, as they would appear in META.json
#pod (broken out into phases and types)
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod This code was originally more or less a direct copy of Marcel Gruenauer (hanekomu)
#pod Dist::Zilla::App::Command::prereqs, updated to work with the Dist::Zilla v2
#pod API.
#pod
#pod =cut

sub abstract { "print your distribution's prerequisites" }

sub opt_spec {
  [ 'develop|author', 'include author/develop dependencies' ],
  [ 'missing', 'list only the missing dependencies' ],
  [ 'requires!', 'list the required dependencies', { default => 1 } ],
  [ 'recommends!', 'list the recommended dependencies', { default => 1 } ],
  [ 'suggests!', 'list the suggested dependencies', {default => 0 } ],
  [ 'versions', 'include required version numbers in listing' ],
  [ 'cpanm-versions', 'format versions for consumption by cpanm' ],
  [ 'json', 'list dependencies by phase, in JSON format' ],
  [ 'omit-core=s', 'Omit dependencies that are shipped with the specified version of perl' ],
}

sub prereqs {
  my ($self, $zilla) = @_;

  $_->before_build for @{ $zilla->plugins_with(-BeforeBuild) };
  $_->gather_files for @{ $zilla->plugins_with(-FileGatherer) };
  $_->set_file_encodings for @{ $zilla->plugins_with(-EncodingProvider) };
  $_->prune_files  for @{ $zilla->plugins_with(-FilePruner) };
  $_->munge_files  for @{ $zilla->plugins_with(-FileMunger) };
  $_->register_prereqs for @{ $zilla->plugins_with(-PrereqSource) };

  my $prereqs = $zilla->prereqs;
}

my @phases = qw/configure build test runtime develop/;
my @relationships = qw/requires recommends suggests/;

sub filter_core {
  my ($prereqs, $core_version) = @_;
  $core_version = sprintf '%7.6f', $core_version if $core_version >= 5.010;
  $prereqs = $prereqs->clone if $prereqs->is_finalized;
  require Module::CoreList;
  for my $phase (@phases) {
    for my $relation (@relationships) {
      my $req = $prereqs->requirements_for($phase, $relation);
      for my $module ($req->required_modules) {
        next if not exists $Module::CoreList::version{$core_version}{$module};
        $req->clear_requirement($module) if $req->accepts_module($module, $Module::CoreList::version{$core_version}{$module});
      }
    }
  }
  return $prereqs;
}

sub extract_dependencies {
  my ($self, $zilla, $phases, $opt) = @_;

  my $prereqs = $self->prereqs($zilla);
  $prereqs = filter_core($prereqs, $opt->omit_core) if $opt->omit_core;

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->new;

  for my $phase (@$phases) {
    $req->add_requirements( $prereqs->requirements_for($phase, 'requires') )   if $opt->requires;
    $req->add_requirements( $prereqs->requirements_for($phase, 'recommends') ) if $opt->recommends;
    $req->add_requirements( $prereqs->requirements_for($phase, 'suggests') )   if $opt->suggests;
  }

  my @required = grep { $_ ne 'perl' } $req->required_modules;
  if ($opt->missing) {
    require Module::Runtime;
    @required =
      grep {
        # Keep modules that can't be loaded or that don't have a $VERSION
        # matching our requirements
        ! eval {
          my $m = $_;
          # Will die if module is not installed
          Module::Runtime::require_module($m);
          # Returns true if $VERSION matches, so we will exclude the module
          $req->accepts_module($m => $m->VERSION)
        }
      } @required;
  }

  my $versions = $req->as_string_hash;
  return map { $_ => $versions->{$_} } @required;
}

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->app->chrome->logger->mute;

  my @phases = qw(build test configure runtime);
  push @phases, 'develop' if $opt->develop;

  my $omit_core = $opt->omit_core;
  if($opt->json) {
    my $prereqs = $self->prereqs($self->zilla);
    $prereqs = filter_core($prereqs, $omit_core) if $omit_core;
    my $output = $prereqs->as_string_hash;

    require JSON::MaybeXS;
    print JSON::MaybeXS->new(ascii => 1, canonical => 1, pretty => 1)->encode($output), "\n";
    return 1;
  }

  my %modules = $self->extract_dependencies($self->zilla, \@phases, $opt);

  my @names = sort { lc $a cmp lc $b } keys %modules;
  if ($opt->versions) {
      print "$_ = $modules{$_}\n" for @names;
  } elsif ($opt->cpanm_versions) {
      print qq{$_~"$modules{$_}"\n} for @names;
  } else {
      print "$_\n" for @names;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::listdeps - print your distribution's prerequisites

=head1 VERSION

version 6.032

=head1 SYNOPSIS

  $ dzil listdeps | cpan

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<listdeps>
command, which prints your distribution's prerequisites. You could pipe that
list to a CPAN client like L<cpan> to install all of the dependencies in one
quick go.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 OPTIONS

=head2 --author (or --develop)

Include author dependencies (those listed under C<develop_requires>).

=head2 --missing

List only dependencies which are unsatisfied.

=head2 --requires / --no-requires

Add required dependencies to the list (or don't).

Default: on.

=head2 --recommends / --no-recommends

Add recommended dependencies to the list (or don't).

Default: on.

=head2 --suggests / --no-suggests

Add suggested dependencies to the list (or don't).

Default: off.

=head2 --versions

Also display the required versions of listed modules.

=head2 --cpanm-versions

Also display the required versions of listed modules, but in a format suitable
for piping into F<cpanm>.

=head2 --json

Lists all prerequisites in JSON format, as they would appear in META.json
(broken out into phases and types)

=head1 ACKNOWLEDGEMENTS

This code was originally more or less a direct copy of Marcel Gruenauer (hanekomu)
Dist::Zilla::App::Command::prereqs, updated to work with the Dist::Zilla v2
API.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
