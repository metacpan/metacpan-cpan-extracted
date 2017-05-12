package Dist::Zilla::Plugin::PrereqsClean;

our $VERSION = '0.93'; # VERSION
# ABSTRACT: Automatically cleans up the mess from other Prereq modules

use sanity;

use Moose;
use MooseX::Types -declare => ['RemovalLevelInt'];
use MooseX::Types::Moose qw/Int/;

use Module::CoreList 3.10;  # (try to keep this one current)
use List::AllUtils qw(min max part);
use version 0.77;

with 'Dist::Zilla::Role::PrereqSource';
with 'Dist::Zilla::Role::MetaCPANInterfacer';

has minimum_perl => (
   is      => 'ro',
   isa     => 'Str',
   lazy    => 1,
   default => sub {
      $_[0]->zilla->prereqs->requirements_for('runtime', 'requires')->requirements_for_module('perl') ||
      'v5.8.8'  # released in 2006... C'mon, people!  Don't make me lower this!
   }
);

use constant {
   RL_NONE          => 0,
   RL_CORE_ONLY     => 1,
   RL_DIST_NO_SPLIT => 2,
   RL_DIST_ALL      => 3,
};

subtype RemovalLevelInt,
   as Int,
   where   { $_ >= RL_NONE && $_ <= RL_DIST_ALL },
   message { "removal_level should be between ".(RL_NONE)." and ".(RL_DIST_ALL) };

has removal_level => (
   is      => 'ro',
   isa     => RemovalLevelInt,
   default => RL_DIST_NO_SPLIT,
);

sub register_prereqs {
   my ($self) = @_;
   my $zilla   = $self->zilla;
   my $prereqs = $zilla->prereqs->cpan_meta_prereqs;

   # consolidate Perl versions between phases (since you can't upgrade Perl in CPAN, etc., anyway)
   my $default_perlver = version->parse( $self->minimum_perl );
   foreach my $phase (qw(configure runtime build)) {  # skip test, since it's a non-critical path
      my $req = $prereqs->requirements_for($phase, 'requires');
      my $phase_perlver = version->parse( $req->requirements_for_module('perl') );
      $default_perlver = max($phase_perlver, $default_perlver) if ($phase_perlver);
   }

   my $latest_perlver = version->parse( (reverse sort keys %Module::CoreList::released)[0] );
   $self->log_debug([ 'Default Perl %s, Latest Perl %s', $default_perlver->normal, $latest_perlver->normal ]);

   # Look for specific things that would change the Perl version
   $self->logger->set_prefix("{Pass 1: Core} ");
   foreach my $phase (qw(configure runtime build test)) {  # phases ordered by importance
      $self->log_debug("Phase '$phase'");
      my $req = $prereqs->requirements_for($phase, 'requires');
      my $perlver = version->parse( $req->requirements_for_module('perl') ) || $default_perlver;
      $perlver = $default_perlver if ($default_perlver > $perlver);

      foreach my $module (sort ($req->required_modules) ) {
         # (speeding through this stuff for this run...)
         next if $module eq 'perl';  # obvious
         #$self->log_debug([ 'Module %s, PerlVer %s',  $module, $perlver->normal ]);
         next if Module::CoreList->is_deprecated($module, $latest_perlver);
         next if Module::CoreList->removed_from($module);
         my $modver = $req->requirements_for_module($module);
         next if ( $modver =~ /\s/ );
         $modver = version->parse($modver);
         my $modver_log = $module.($modver ? ' '.$modver->normal : '');

         # Core module (might as well deal with this whole block while we're here...)
         if ( my $release = version->parse( Module::CoreList->first_release($module, $modver) ) ) {

            if ($release > $perlver) {
               my $distro = $self->_mcpan_module2distro($module) || next;

               if ($distro eq 'perl') {
                  $self->log([ 'Module %s is only found in core Perl; adding Perl %s requirement', $modver_log, $release->normal ]);
                  $req->clear_requirement($module);
                  $req->add_minimum( perl => $release );

                  $perlver = $release;
                  $default_perlver = $release if ($phase =~ /configure|runtime|build/);
               }
               next;
            }
            next unless ($self->removal_level);
            $self->log_debug([ 'Removing core module %s (been available since Perl %s)', $modver_log, $release->normal ]);
            $req->clear_requirement($module);
         }
      }
   }

   $prereqs->requirements_for('runtime', 'requires')->add_minimum( perl => $default_perlver );

   # Okay, clean up the remaining Perl core modules (if any), and any non-cores
   my $distro_mods = {};
   my %module_distro;
   foreach my $phase (qw(configure runtime build test)) {
      $self->logger->set_prefix("{Pass 2.1: Modules} ");
      $self->log_debug("Phase '$phase'");
      my $req = $prereqs->requirements_for($phase, 'requires');

      my %distro_list;  # only saved this phase vs. $distro_mods
      # the rest build up modules as they go, since the phase order works according to CPAN::Meta::Spec processing

      my $perlver = version->parse( $req->requirements_for_module('perl') );
      # Do some general cleanup of the 'perl' version specifically
      if ($default_perlver >= $perlver) {
         $perlver = $default_perlver;
         $req->clear_requirement('perl') if ($phase =~ /configure|build/);
      }

      foreach my $module (sort ($req->required_modules) ) {
         next if $module eq 'perl';  # obvious

         # Skips
         if ( Module::CoreList->is_deprecated($module, $latest_perlver) ) {
            $self->log([ 'Module %s is deprecated in the latest core Perl (%s); you should consider alternatives...', $module, $latest_perlver->normal ]);
            next;
         }
         if ( my $remver = version->parse( Module::CoreList->removed_from($module) ) ) {
            $self->log([ 'Module %s has been removed from core since Perl %s; you should consider alternatives...', $module, $remver->normal ]);
            next;
         }
         next unless ($self->removal_level);

         my $modver = $req->requirements_for_module($module);
         if ( $modver && $modver =~ /\s/ ) {
            # what I really want is $req->is_simple($module)...
            # also, using "complete hack" from is_simple: https://metacpan.org/source/CPAN::Meta::Requirements#L159
            $self->log_debug("Skipping module $module with complex requirements");
            next;
         }
         $modver = version->parse($modver);
         my $modver_log = $module.($modver ? ' '.$modver->normal : '');

         # Core module
         if ( my $release = version->parse( Module::CoreList->first_release($module, $modver) ) ) {
            if ($release > $perlver) {
               $self->log_debug([ 'Skipping core module %s (Perl %s > %s)', $modver_log, $release->normal, $perlver->normal ]);
               next;
            }
            $self->log_debug([ 'Removing core module %s (been available since Perl %s)', $modver_log, $release->normal ]);
            $req->clear_requirement($module);
            next;
         }

         # potentials for culling
         next unless $self->removal_level >= RL_DIST_NO_SPLIT;
         unless ($module_distro{$module}) {
            my ($distro, @modules) = $self->_mcpan_module2distro($module, 1);
            next unless ($distro && @modules > 1);  # must exist in CPAN and be a 2+ module distro
            $module_distro{$_} = $distro for @modules;  # contains all modules vs. $distro_mods
         }

         if (my $distro = $module_distro{$module}) {
            $distro_mods->{$distro} //= {};  # hashes for uniqueness
            $distro_mods->{$distro}{$module} = 1;
            $distro_list{$distro} = 1;
         }
      }
      next unless ($self->removal_level >= RL_DIST_NO_SPLIT);

      # Look through the collected distro lists and figure out which should be removed
      $self->logger->set_prefix("{Pass 2.2: Distros} ");
      my @distros = map { [ $_, keys %{$distro_mods->{$_}} ] } sort keys %distro_list;
      while (my $distro_pair = shift @distros) {
         my $distro = shift @$distro_pair;
         my @modules = sort { length($a) <=> length($b) } @$distro_pair;
         my @dmods   = grep { $module_distro{$_} eq $distro } keys %module_distro;

         # hopefully, we can find a common name to use
         (my $main_module = $distro) =~ s/-/::/g;
         $main_module = $modules[0] unless ($main_module ~~ @dmods);

         # remove any obvious split potentials
         if ($self->removal_level <= RL_DIST_NO_SPLIT) {
            my ($non_ns, $new_mods) = part { /^\Q$main_module\E(?:\:\:|$)/ } @modules;
            @modules = $new_mods ? @$new_mods : ();

            # Add split modules to a "new" distro for further processing
            # (This will clean up both Dist::A::* and Dist::B::* from Dist-A)
            if ($non_ns && $new_mods) {
               @$non_ns = sort { length($a) <=> length($b) } @$non_ns;
               unshift @distros, [ $non_ns->[0], @$non_ns ];
            }

            if (@modules <= 1) {
               $self->log_debug("Skipping module $main_module; distro only has ".scalar @modules." module left since split comparison");
               next;
            }
         }

         my $maxver = max map { version->parse( $req->requirements_for_module($_) || 0 ) } @modules;
         $maxver ||= 0;

         $self->log_debug("Replacing modules from common distro $distro:");
         $self->log_debug('   Using main/replacement module of '.$main_module.($maxver ? ' '.$maxver->normal : ''));
         $self->log_debug("   $_") for @modules;
         $req->clear_requirement($_) for @modules;
         $req->add_minimum( $main_module => $maxver );
      }
   }
}

sub _mcpan_module2distro {
   my ($self, $module, $get_module_list) = @_;

   # faster and less bulky than a straight module/$module pull
   ### XXX: This should be replaced with a ->file() method when those
   ### two pull requests of mine are put into CPAN...
   $self->log_debug("Checking module $module via MetaCPAN");
   my $details = $self->mcpan->fetch("file/_search",
      q      => 'module.name:"'.$module.'" AND status:latest AND module.authorized:true',
      fields => 'distribution,release',
      size   => 1,
   );
   unless ($details && $details->{hits}{total}) {
      $self->log("??? MetaCPAN can't even find module $module!");
      return undef;
   }
   my ($distro, $release) = @{ $details->{hits}{hits}[0]{fields} }{qw(distribution release)};
   return $distro unless $get_module_list;

   $self->log_debug("Checking release $release for module list via MetaCPAN");
   $details = $self->mcpan->fetch("file/_search",
      q      => 'release:"'.$release.'" AND module.name:* AND module.authorized:true',
      fields => 'module.name',
      size   => 500,
   );
   unless ($details && $details->{hits}{total}) {
      $self->log("??? MetaCPAN can't find release $release (even after finding it earlier)!");
      return undef;
   }

   my @modules = map { $_->{fields}{'module.name'} } @{ $details->{hits}{hits} };
   return ($distro, @modules);
}

__PACKAGE__->meta->make_immutable;
42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PrereqsClean - Automatically cleans up the mess from other Prereq modules

=head1 SYNOPSIS

    ; ...other Prereq plugins...
    ; (NOTE: Order is important, so PrereqsClean should go last.)
    [PrereqsClean]
    ; defaults
    minimum_perl = {{Runtime Requires for Perl}} || v5.8.8
    removal_level = 2

=head1 DESCRIPTION

Ever notice that it's really easy to figure out if a module's author used Dist::Zilla by
the amount of dependencies?  strict?  warnings?  base?  Every module for Foo::Bar::*,
individually listed?

Well, now you can clean up that junk.  PrereqsClean will find and clean up:

=over

=item *

Core modules that are already in Perl, verifying minimum version requirements

=item *

Core modules that B<only> exist in Perl, which will elevate the minimum Perl version if
necessary

=item *

Multiple modules that already exist in a single distribution

=back

=head2 Why bother?

Why even worry about the dependency list?

=over

=item 1.

Your list of dependencies should give users a general idea of how many B<distributions>
they need to download from CPAN.  Bulking up the dependencies with every single little
module scares away certain users into thinking your module is just too complex to worry
about.

=item 2.

The core module search alone will aid you in setting the most accurate minimum Perl
version.

=item 3.

It's just silly to add in stuff like C<<< strict >>> and C<<< warnings >>> as dependencies, when they
have literally been a part of the Perl language since Day 1.

=back

For the flip side, see L</CAVEATS>.

=head1 OPTIONS

=head2 minimum_perl

This is the bare minimum version of Perl you want to start off with.  Some people already
have a minimum in their code, which it will use by default.  Otherwise, you can override
here, instead of inside the modules.

The "last resort" default is v5.8.8, which is the minimum version of Perl that included
L<EUMM|ExtUtils::MakeMaker>.

=head2 removal_level

This dictates just how zealous this module should remove dependencies from the list.  The
default (level 2) should work fine for most people.

=over

=item *

B<Level 0> = This is the completely safe and boring option.  It won't actually remove
anything unless the module exists B<only> in Perl, which dependencies wouldn't have fixed
anyway.  It will also elevate your minimum Perl version from that discovery, and warn you
of deprecatedE<sol>removed modules from core Perl.

=item *

B<Level 1> = This is the "core only" removal level, which adds support to remove
"dual-life" (CPAN+Perl) core modules, if the minimum version is covered in the existing
version of Perl.

=item *

B<Level 2> = This is the default removal level, which will condense multiple modules into
a single distribution requirement.

=item *

B<Level 3> = This level will remove the "split protection" safeguards that allow it to only
remove multiple modules if they fall into the same parent namespace.  (For example, split
protection would remove all of the C<<< Foo::Bar::\* >>> modules as one C<<< Foo::Bar >>> requirement, and
the C<<< Blah::\* >>> modules as a C<<< Blah >>> requirement, even if all of those modules are in the same
distribution.)

=back

=head1 CAVEATS

=head2 Core module deprecation

B<Situation:> Once in a blue moon, the Perl folks will decide that a module is either too old, too
broken, or too obscure to keep into core.  Once that happens, there is a deprecation process.
First, the module is marked as deprecated for an entire major release cycle (C<<< 5.##.\* >>>).  If it
was in the middle of a cycle, it will likely last another full cycle.

Finally, the module is removed from core.  In many cases, the module isn't even available on
CPAN, since the whole thing has been retired.

B<Problem:> If PrereqsClean removed the module and if you haven't had a release in a large span
of time (missing the entire deprecation cycle), then users might experience missing dependencies
for newer versions of Perl.

B<Risk:> As of the time of this writing, out of the 773 modules that have ever been in Perl core,
32 modules or module sets (93 indiv modules) have been removed from core, 10 of which were removed
during a massive cleanup during the 5.8E<sol>9 cycle.

Given that you're using something as modern as L<Dist::Zilla>, you're probably not depending on
modules that are 10 years old.  And you're probably releasing often enough that you'll run into
the built-in deprecation warning before it gets removed.

B<Solution:> If the module is still in CPAN, re-release your distro.  Problem solved.

If not, you're pretty much SOL, anyway.  Switch to a different module.

=head2 Distribution split

B<Situation:> An author of a large distribution has decided that some of the modules are better off
split up into another (or more) distro.

B<Problem:> If PrereqsClean removed the module from the split, then users might experience missing
dependencies.  However, the chances are high that the distro author is now including the split
modules in their dependency list, so CPAN will install it correctly, anyway.

B<Risk:> This is a very rare event, but it does happen to major modules.  For example, GAAS had
split off all of the non-LWP modules from L<libwww-perl> for his 6.0 release.  However, again,
he also included dependency links back to those modules, so CPAN would have installed it
correctly.  Plus, it was a logical namespace split, so PrereqsClean's "split protection" would
have already safeguarded against any problems.

So, the odds of this causing any problems are very, very low.

B<Solution:> Again, C<<< dzil release >>>.  Problem solved.

=head2 TL;DR

If any of this is too scary for you, just set the removal_level to 0.

=head1 SEE ALSO

Other Dist::Zilla Prereq plugins: L<Prereqs|Dist::Zilla::Plugin::Prereqs>, L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>,
L<LatestPrereqs|Dist::Zilla::Plugin::LatestPrereqs>, L<DarkPAN|Dist::Zilla::Plugin::DarkPAN>

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-PluginBundle-Prereqs>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Prereqs/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
