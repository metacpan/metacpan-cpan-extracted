package Dist::Zilla::Role::TravisYML;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.15'; # VERSION
# ABSTRACT: Role for .travis.yml creation

use v5.10;
use Moose::Role;

use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str Bool is_Bool };

use List::AllUtils qw{ first sum uniq };
use YAML qw{ Dump };

use Module::CoreList;
use version 0.77;

requires 'zilla';
requires 'logger';

with 'Dist::Zilla::Role::MetaCPANInterfacer';

sub log       { shift->logger->log(@_)       }
sub log_debug { shift->logger->log_debug(@_) }
sub log_fatal { shift->logger->log_fatal(@_) }

# needs our to pass to mvp_multivalue_args
our @phases = qw(
   before_install
   install
   after_install
   before_script
   script
   after_script
   after_success
   after_failure
   after_deploy
);
my @yml_order = (qw(
   sudo
   language
   perl
   env
   matrix
   branches
), @phases, qw(
   notifications
));


### HACK: Need these rw for ChainSmoking ###
has $_ => ( rw, isa => ArrayRef[Str], default => sub { [] } ) for (
   map { $_, $_.'_dzil', $_.'_build' }
   map { $_, 'pre_'.$_, 'post_'.$_ }
   @phases
);

has dzil_branch      => ( rw, isa => Str );
has build_branch     => ( rw, isa => Str,           default => '/^build\/.*/' );
has notify_email     => ( rw, isa => ArrayRef[Str], default => sub { [ 1 ] }  );
has notify_irc       => ( rw, isa => ArrayRef[Str], default => sub { [ 0 ] }  );
has mvdt             => ( rw, isa => Bool,          default => 0              );
has test_authordeps  => ( rw, isa => Bool,          default => 0              );
has test_deps        => ( rw, isa => Bool,          default => 1              );
has support_builddir => ( rw, isa => Bool,          default => 0              );
has sudo             => ( rw, isa => Bool,          default => 0              );

has irc_template  => ( rw, isa => ArrayRef[Str], default => sub { [
   "%{branch}#%{build_number} by %{author}: %{message} (%{build_url})",
] } );

has perl_version       => ( rw, isa => Str, default => '-blead 5.20 5.18 5.16 5.14 5.12 5.10 -5.8' );
has perl_version_build => ( rw, isa => Str, lazy, default => sub { shift->perl_version } );

has _releases => ( ro, isa => ArrayRef[Str], lazy, default => sub {
   my $self = shift;

   # Find the lowest required dependencies and tell Travis-CI to install them
   my (%releases, %versions);
   if ($self->mvdt) {
      my $prereqs = $self->zilla->prereqs;
      $self->log("Searching for minimum dependency versions");

      my $minperl = version->parse(
         $prereqs->requirements_for('runtime', 'requires')->requirements_for_module('perl') ||
         v5.8.8  # released in 2006... C'mon, people!  Don't make me lower this!
      );
      foreach my $phase (qw( runtime configure build test )) {
         $self->logger->set_prefix("{Phase '$phase'} ");
         my $req = $prereqs->requirements_for($phase, 'requires');

         foreach my $module ( sort ($req->required_modules) ) {
            next if $module eq 'perl';  # obvious

            my $modver = $req->requirements_for_module($module);
            my ($distro, $release, $minver) = $self->_mcpan_module_minrelease($module, $modver);
            next unless $release;
            my $mod_in_perlver = Module::CoreList->first_release($module, $minver);

            if ($mod_in_perlver && $minperl >= $mod_in_perlver) {
               $self->log_debug(['Module %s v%s is already found in core Perl v%s (<= v%s)', $module, $minver, $mod_in_perlver, $minperl]);
               next;
            }

            # Only install the latest version, in cases of a conflict between phases
            if (!$versions{$distro} || $minver > $versions{$distro}) {
               $releases{$distro} = $release;
               $versions{$distro} = $minver;
               $self->log_debug(['Found minimum dep version for Module %s as %s', $module, $release]);
            }
            else {
               $self->log_debug(['Module %s v%s has a higher version due to be installed in %s v%s', $module, $minver, $distro, ''.$versions{$distro}]);
            }
         }
      }
      $self->logger->clear_prefix;
   }

   return [ map { $releases{$_} } sort keys %releases ];
});

sub build_travis_yml {
   my ($self, $is_build_branch) = @_;

   my %travis_yml = (
      sudo     => $self->sudo ? 'true' : 'false',
      language => 'perl',
      matrix   => { fast_finish => 'true' },
      $self->support_builddir ? (
         env   => [ 'BUILD=0', 'BUILD=1' ],
      ) : (),
   );

   my $email = $self->notify_email->[0];
   my $irc   = $self->notify_irc->[0];
   my $rmeta = $self->zilla->distmeta->{resources};

   my %notifications;

   # Perl versions
   my (@perls, @perls_allow_failures);
   if ($self->support_builddir && !$is_build_branch) {  # dual DZIL+build YAML
      @perls = uniq map { s/^\-//; $_ } split(/\s+/, $self->perl_version.' '.$self->perl_version_build);
      @perls_allow_failures = (
         (
            map { +{ perl => $_, env => 'BUILD=0' } }
            grep { s/^\-// }
            split(/\s+/, $self->perl_version)
         ), (
            map { +{ perl => $_, env => 'BUILD=1' } }
            grep { s/^\-// }
            split(/\s+/, $self->perl_version_build)
         )
      );
   }
   else {
      @perls = split(/\s+/, $is_build_branch ? $self->perl_version : $self->perl_version_build);
      @perls_allow_failures =
         map { +{ perl => $_ } }
         grep { s/^\-// }  # also strips the dash from @perls
         @perls
      ;
   }
   $travis_yml{perl} = \@perls;
   $travis_yml{matrix}{allow_failures} = \@perls_allow_failures if @perls_allow_failures;

   # IRC
   $irc eq "1" and $irc = $self->notify_irc->[0] = $rmeta->{ first { /irc$/i } keys %$rmeta } || "0";
   s#^irc:|/+##gi for @{$self->notify_irc};

   if ($irc) {
      my %irc = (
         on_success => 'change',
         on_failure => 'always',
         use_notice => 'true',
      );
      $irc{channels} = [grep { $_ } @{$self->notify_irc}];
      $irc{template} = [grep { $_ } @{$self->irc_template}];
      $notifications{irc} = \%irc;
   }

   # Email
   $notifications{email} = ($email eq "0") ? "false" : [ grep { $_ } @{$self->notify_email} ]
      unless ($email eq "1");

   $travis_yml{notifications} = \%notifications if %notifications;

   ### Prior to the custom mangling by the user, establish a default .travis.yml to work from
   my %travis_code = (
      common => { # run for both dzil *and* build
         before_install => [ # install haarg's perl travis helpers
            'export AUTOMATED_TESTING=1 NONINTERACTIVE_TESTING=1 HARNESS_OPTIONS=j10:c HARNESS_TIMER=1',
            'git clone git://github.com/haarg/perl-travis-helper',
            'source perl-travis-helper/init',
            'build-perl',
            'perl -V',
         ],
      },
      dzil  => {},
      build => {},
   );

   # needed for MDVT
   my @releases = @{$self->_releases};
   my @releases_install;
   if (@releases) {
      @releases_install = (
         # Install the lowest possible required version for the dependencies
         'export OLD_CPANM_OPT=$PERL_CPANM_OPT',
         "export PERL_CPANM_OPT='--mirror http://cpan.metacpan.org/ --mirror http://search.cpan.org/CPAN' \$PERL_CPANM_OPT",
         (map { 'cpanm --verbose '              .$_ } @releases),  # first pass to force minimum versions
         (map { 'cpanm --verbose --installdeps '.$_ } @releases),  # second pass to make sure conflicting deps are handled correctly
         'export PERL_CPANM_OPT=$OLD_CPANM_OPT',
      );
   }

   # DZIL Travis YAML

   # verbosity/testing and parallelized installs don't mix
   my $notest_cmd = 'xargs -n 5 -P 10 cpanm --quiet --notest';
   my $test_cmd   = 'cpanm --verbose';

   $travis_code{dzil}{before_install} = [
      # Fix for https://github.com/travis-ci/travis-cookbooks/issues/159
      'git config --global user.name "TravisCI"',
      'git config --global user.email $HOSTNAME":not-for-mail@travis-ci.org"',
   ];
   $travis_code{dzil}{install} = scalar(@releases) ? \@releases_install : [
      "cpanm --quiet --notest --skip-satisfied Dist::Zilla",  # this should already exist anyway...
      "dzil authordeps          --missing | grep -vP '[^\\w:]' | ".($self->test_authordeps ? $test_cmd : $notest_cmd),
      "dzil listdeps   --author --missing | grep -vP '[^\\w:]' | ".($self->test_deps       ? $test_cmd : $notest_cmd),
   ];
   $travis_code{dzil}{script} = [
      "dzil smoke --release --author",
   ];

   # Build Travis YAML

   $travis_code{build}{before_install} = [
      # Prevent any test problems with this file
      'rm .travis.yml',
      # Build tests shouldn't be considered "author testing"
      'export AUTHOR_TESTING=0',
   ];
   $travis_code{build}{install} = scalar(@releases) ? \@releases_install : [
      'cpanm --installdeps --verbose '.($self->test_deps ? '' : '--notest').' .',
   ];

   if (my $bbranch = $self->build_branch) {
      $travis_code{build}{branches} = { only => $bbranch };
   }

   ### See if any custom code is requested

   foreach my $phase (@phases) {
      # First, replace any new blocks, then deal with pre/post blocks
      foreach my $ft ('', '_dzil', '_build') {  # YML file type; specific wins priority
         my $method = $phase.$ft;
         my $custom_cmds = $self->$method;

         if ($custom_cmds && @$custom_cmds) {
            foreach my $key ('dzil', 'build') {
               next unless (!$ft || substr($ft, 1) eq $key);
               $travis_code{$key}{$phase} = [ @$custom_cmds ];
            }
         }
      }

      foreach my $ft ('', '_dzil', '_build') {
         foreach my $pos (qw(pre post)) {
            my $method = $pos.'_'.$phase.$ft;
            my $custom_cmds = $self->$method;

            if ($custom_cmds && @$custom_cmds) {
               foreach my $key ('dzil', 'build') {
                  next unless (!$ft || substr($ft, 1) eq $key);
                  $travis_code{$key}{$phase} //= [];

                  $pos eq 'pre' ?
                     unshift(@{$travis_code{$key}{$phase}}, @$custom_cmds) :
                     push   (@{$travis_code{$key}{$phase}}, @$custom_cmds)
                  ;
               }
            }
         }
      }
   }

   # Insert %travis_code into %travis_yml
   unless ($is_build_branch) {
      # Standard DZIL YAML
      unless ($self->support_builddir) {
         %travis_yml = (%travis_yml, %{ $travis_code{dzil} });
      }
      # Dual DZIL+build YAML
      else {
         foreach my $phase (@phases) {  # skip branches as well
            my @common  = $travis_code{common}{$phase} ? @{ $travis_code{common} {$phase} } : ();
            my @dzil    = $travis_code{dzil}  {$phase} ? @{ $travis_code{dzil}   {$phase} } : ();
            my @build   = $travis_code{build} {$phase} ? @{ $travis_code{build}  {$phase} } : ();

            if ($phase eq 'before_install') {
               @build = grep { $_ ne 'rm .travis.yml' } @build;  # this won't actually exist in .build/testing
               unshift @build, 'cd .build/testing';
            }

            if (@common || @dzil || @build) {
               $travis_yml{$phase} = [
                  @common,
                  ( map { 'if [[ $BUILD == 0 ]]; then '.$_.'; fi' } @dzil ),
                  ( map { 'if [[ $BUILD == 1 ]]; then '.$_.'; fi' } @build ),
               ];
            }

            # if the directory doesn't exist, unset $BUILD, so that everything else is a no-op
            unshift @{ $travis_yml{$phase} }, 'if [[ $BUILD == 1 && ! -d .build/testing ]]; then unset BUILD; fi'
               if $phase eq 'before_install';

            # because {build}{script} normally doesn't have any lines, mimic the Travis default
            if ($phase eq 'script' and not @build) {
               push @{ $travis_yml{$phase} }, (
                  'if [[ $BUILD == 1 && -f Makefile.PL ]]; then perl Makefile.PL && make test;    fi',
                  'if [[ $BUILD == 1 && -f Build.PL    ]]; then perl Build.PL    && ./Build test; fi',
                  'if [[ $BUILD == 1 && ! -f Makefile.PL && ! -f Build.PL ]]; then  make test;    fi',
               );
            }
         }
      }

      # Add 'only' option, if specified
      $travis_code{build}{branches} = { only => $self->dzil_branch } if $self->dzil_branch;
   }
   # Build branch YAML
   elsif ($self->build_branch) {
      %travis_yml = (%travis_yml, %{ $travis_code{build} });
   }
   else {
      return;  # no point in staying here...
   }

   ### Dump YML (in order)
   local $YAML::Indent    = 3;
   local $YAML::UseHeader = 0;

   my $node = YAML::Bless(\%travis_yml);
   $node->keys([grep { exists $travis_yml{$_} } @yml_order]);
   $self->log( "Rebuilding .travis.yml".($is_build_branch ? ' (in build dir)' : '') );

   # Add quotes to perl version strings, as Travis tends to remove the zeroes
   my $travis_yml = Dump \%travis_yml;
   $travis_yml =~ s/^(\s+- )(5\.\d+|blead)$/$1'$2'/gm;
   $travis_yml =~ s/^(\s+(?:- )?perl: )(5\.\d+|blead)$/$1'$2'/gm;

   my $file = Path::Class::File->new($self->zilla->built_in, '.travis.yml');
   $file->spew($travis_yml);
   return $file;
}

sub _as_lucene_query {
   my ($self, $ver_str) = @_;

   # simple versions short-circuits
   return () if $ver_str eq '0';
   return ('module.version_numified:['.version->parse($ver_str)->numify.' TO 999999]')
      unless ($ver_str =~ /[\<\=\>]/);

   my ($min, $max, $is_min_inc, $is_max_inc, @num_conds, @str_conds);
   foreach my $ver_cmp (split(qr{\s*,\s*}, $ver_str)) {
      my ($cmp, $ver) = split(qr{(?<=[\<\=\>])\s*(?=\d)}, $ver_cmp, 2);

      # Normalize string, but keep originals for alphas
      my $use_num = 1;
      my $orig_ver = $ver;
      $ver = version->parse($ver);
      my $num_ver = $ver->numify;
      if ($ver->is_alpha) {
         $ver = $orig_ver;
         $ver =~ s/^v//i;
         $use_num = 0;
      }
      else { $ver = $num_ver; }

      if ($cmp eq '==') { return 'module.version'.($use_num ? '_numified' : '').':'.$ver; }  # no need to look at anything else
      if ($cmp eq '!=') { $use_num ? push(@num_conds, '-'.$ver) : push(@str_conds, '-'.$ver); }
      ### XXX: Trying to do range-based searches on strings isn't a good idea, so we always use the number field ###
      if ($cmp eq '>=') { ($min, $is_min_inc) = ($num_ver, 1); }
      if ($cmp eq '<=') { ($max, $is_max_inc) = ($num_ver, 1); }
      if ($cmp eq '>')  { ($min, $is_min_inc) = ($num_ver, 0); }
      if ($cmp eq '<')  { ($max, $is_max_inc) = ($num_ver, 0); }
      else              { die 'Unable to parse complex module requirements with operator of '.$cmp.' !'; }
   }

   # Min/Max parsing
   if ($min || $max) {
      $min ||= 0;
      $max ||= 999999;
      my $rng = $min.' TO '.$max;

      # Figure out the inclusive/exclusive status
      my $inc = $is_min_inc.$is_max_inc;  # (this is just easier to deal with as a combined form)
      unshift @num_conds, '-'.($inc eq '01' ? $min : $max)
         if ($inc =~ /0/ && $inc =~ /\d\d/);  # has mismatch of inc/exc (reverse order due to unshift)
      unshift @num_conds, '+'.($inc =~ /1/ ? '['.$rng.']' : '{'.$rng.'}');  # +[{ $min TO $max }]
   }

   # Create the string
   my @lq;
   push @lq, 'module.version_numified:('.join(' ', @num_conds).')' if @num_conds;
   push @lq, 'module.version:('         .join(' ', @str_conds).')' if @str_conds;
   return @lq;
}

sub _mcpan_module_minrelease {
   my ($self, $module, $ver_str, $try_harder) = @_;

   my @lq = $self->_as_lucene_query($ver_str);
   my $maturity_q = ($ver_str =~ /==/) ? undef : 'maturity:released';  # exact version may be a developer one

   ### XXX: This should be replaced with a ->file() method when those
   ### two pull requests of mine are put into CPAN...
   my $q = join(' AND ', 'module.name:"'.$module.'"', $maturity_q, 'module.authorized:true', @lq);
   $self->log_debug("Checking module $module via MetaCPAN");
   #$self->log_debug("   [q=$q]");
   my $details = $self->mcpan->fetch("file/_search",
      q      => $q,
      sort   => 'module.version_numified',
      fields => 'author,release,distribution,module.version,module.name',
      size   => $try_harder ? 20 : 1,
   );
   unless ($details && $details->{hits}{total}) {
      $self->log("??? MetaCPAN can't even find a good version for $module!");
      return undef;
   }

   ### XXX: Figure out better ways to find these modules with multiple package names (ie: Moose::Autobox, EUMM)

   # Sometimes, MetaCPAN just gets highly confused...
   my @hits = @{ $details->{hits}{hits} };
   my $hit;
   my $is_bad = 1;
   while ($is_bad and @hits) {
      $hit = shift @hits;
      # (ie: we shouldn't have multiples of modules or versions, and sort should actually have a value)
      $is_bad = !$hit->{sort}[0] || ref $hit->{fields}{'module.name'} || ref $hit->{fields}{'module.version'};
   };

   if ($is_bad) {
      if ($try_harder) {
         $self->log("??? MetaCPAN is highly confused about $module!");
         return undef;
      }
      $self->log_debug("   MetaCPAN got confused; trying harder...");
      return $self->_mcpan_module_minrelease($module, $ver_str, 1)
   }

   $hit = $hit->{fields};

   # This will almost always be .tar.gz, but TRIAL versions might have different names, etc.
   my $fields = $self->mcpan->release(
      search => {
         q      => 'author:'.$hit->{author}.' AND name:"'.$hit->{release}.'"',
         fields => 'archive,tests',
         size   => 1,
      },
   )->{hits}{hits}[0]{fields};

   # Warn about test failures
   my $t = $fields->{tests};
   my $ttl = sum @$t{qw(pass fail unknown na)};
   unless ($ttl) {
      $self->log(['%s has no CPAN test results!  You should consider upgrading the minimum dep version for %s...', $hit->{release}, $module]);
   }
   else {
      my $per   = $t->{pass} / $ttl * 100;
      my $f_ttl = $ttl - $t->{pass};

      if ($per < 70 || $t->{fail} > 20 || $f_ttl > 30) {
         $self->log(['CPAN Test Results for %s:', $hit->{release}]);
         $self->log(['   %7s: %4u (%3.1f)', $_, $t->{lc $_}, $t->{lc $_} / $ttl * 100]) for (qw(Pass Fail Unknown NA));
         $self->log(['You should consider upgrading the minimum dep version for %s...', $module]);
      }
   }

   my $v = $hit->{'module.version'};
   return ($hit->{distribution}, $hit->{author}.'/'.$fields->{archive}, $v && version->parse($v));
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::TravisYML - Role for .travis.yml creation

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-TravisCI>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::TravisCI/>.

=head1 AUTHOR

Brendan Byrd <bbyrd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
