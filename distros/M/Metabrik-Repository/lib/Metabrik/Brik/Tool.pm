#
# $Id: Tool.pm,v 28a22d60af64 2017/10/19 08:44:25 gomor $
#
# brik::tool Brik
#
package Metabrik::Brik::Tool;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 28a22d60af64 $',
      tags => [ qw(unstable program) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         repository => [ qw(Repository) ],
      },
      attributes_default => {
         use_pager => 1,
      },
      commands => {
         get_require_briks => [ qw(Brik|OPTIONAL) ],
         get_require_briks_recursive => [ qw(Brik|OPTIONAL) ],
         get_require_modules => [ qw(Brik|OPTIONAL) ],
         get_require_modules_recursive => [ qw(Brik) ],
         get_need_packages => [ qw(Brik|OPTIONAL) ],
         get_need_packages_recursive => [ qw(Brik) ],
         get_brik_hierarchy => [ qw(Brik) ],
         get_brik_hierarchy_recursive => [ qw(Brik) ],
         install_packages => [ qw(package_list) ],
         install_modules => [ qw(module_list) ],
         install_all_require_modules => [ ],
         install_all_need_packages => [ ],
         install_needed_packages => [ qw(Brik) ],
         install_required_modules => [ qw(Brik) ],
         install_required_briks => [ qw(Brik) ],
         install => [ qw(Brik) ],
         create_tool => [ qw(filename.pl Repository|OPTIONAL) ],
         create_brik => [ qw(Brik Repository|OPTIONAL) ],
         update_core => [ ],
         update_repository => [ ],
         update => [ ],
         test_repository => [ ],
         view_brik_source => [ qw(Brik) ],
         get_brik_module_file => [ qw(Brik directory_list|OPTIONAL) ],
         clone => [ qw(Brik Repository|OPTIONAL) ],
         get_require_binaries => [ qw(Brik|OPTIONAL) ],
      },
      # We can't activate that, because we would have a chicken-and-egg problem.
      #need_packages => {
         #ubuntu => [ qw(mercurial) ],
         #debian => [ qw(mercurial) ],
         #freebsd => [ qw(mercurial) ],
      #},
      #require_binaries => {
         #hg => [ ],
      #},
      require_modules => {
         'Metabrik::Devel::Mercurial' => [ ],
         'Metabrik::File::Find' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::Perl::Module' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::System::Package' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         repository => $self->global->repository,
      },
   };
}

sub get_require_briks {
   my $self = shift;
   my ($brik) = @_;

   my $con = $self->context;

   my $available = $con->available;

   # If we asked for one Brik, we rewrite available to only have this one.
   if (defined($brik)) {
      $available = { $brik => $available->{$brik} };
   }

   my %modules = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      if (defined($available->{$this})
      &&  exists($available->{$this}->brik_properties->{require_modules})) {
         my $list = $available->{$this}->brik_properties->{require_modules};
         for my $m (keys %$list) {
            next if $m !~ m{^Metabrik::};
            $modules{$m}++;
         }
      }
   }

   my @modules = sort { $a cmp $b } keys %modules;
   for (@modules) {
      s{^Metabrik::}{};
      $_ = lc($_);
   }

   return \@modules;
}

sub get_require_briks_recursive {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('get_require_briks_recursive', $brik) or return;

   my $hierarchy = $self->get_brik_hierarchy_recursive($brik) or return;

   my %required = ();
   for my $this ($brik, @$hierarchy) {
      my $require_briks = $self->get_require_briks($this) or next;
      for my $b (@$require_briks) {
         $required{$b}++;
      }
   }

   return [ sort { $a cmp $b } keys %required ];
}

#
# Will return the complete list of required modules if no Argument is given,
# or the list of required modules for the specified Brik.
#
sub get_require_modules {
   my $self = shift;
   my ($brik) = @_;

   my $con = $self->context;
   my $available = $con->available;

   # If we asked for one Brik, we rewrite available to only have this one.
   if (defined($brik)) {
      $available = { $brik => $available->{$brik} };
   }

   my %modules = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      if (defined($available->{$this})
      &&  exists($available->{$this}->brik_properties->{require_modules})) {
         my $list = $available->{$this}->brik_properties->{require_modules};
         for my $m (keys %$list) {
            next if $m =~ m{^Metabrik::};
            $modules{$m}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %modules ];
}

#
# Will return the complete list of required modules of given Brik.
# This includes searching in the Brik complete hierarchy recursively.
#
sub get_require_modules_recursive {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('get_require_modules_recursive', $brik) or return;

   my $hierarchy = $self->get_brik_hierarchy_recursive($brik) or return;

   my %required = ();
   for my $this ($brik, @$hierarchy) {
      my $require_modules = $self->get_require_modules($this) or next;
      for my $b (@$require_modules) {
         $required{$b}++;
      }
   }

   return [ sort { $a cmp $b } keys %required ];
}

#
# Will return the complete list of needed packages if no Argument is given,
# or the list of needed packages for the specified Brik.
#
sub get_need_packages {
   my $self = shift;
   my ($brik) = @_;

   my $con = $self->context;
   my $available = $con->available;

   # If we asked for one Brik, we rewrite available to only have this one.
   if (defined($brik)) {
      $available = { $brik => $available->{$brik} };
   }

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   my $os = $sp->my_os or return;

   my %packages = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      if (defined($available->{$this})
      &&  exists($available->{$this}->brik_properties->{need_packages})) {
         my $list = $available->{$this}->brik_properties->{need_packages}{$os} or next;
         for my $p (@$list) {
            $packages{$p}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %packages ];
}

#
# Will return the complete list of needed packages of given Brik.
# This includes searching in the Brik complete hierarchy recursively.
#
sub get_need_packages_recursive {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('get_require_packages_recursive', $brik) or return;

   my $hierarchy = $self->get_brik_hierarchy_recursive($brik) or return;

   my %needed = ();
   for my $this ($brik, @$hierarchy) {
      my $need_packages = $self->get_need_packages($this) or next;
      for my $b (@$need_packages) {
         $needed{$b}++;
      }
   }

   return [ sort { $a cmp $b } keys %needed ];
}

#
# Return the list of ancestors for the Brik.
#
sub get_brik_hierarchy {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('get_brik_hierarchy', $brik) or return;

   my @toks = split(/::/, $brik);

   my @final = ();

   # Rebuild module name from Brik name so we can read its @ISA
   my $m = 'Metabrik';
   for (@toks) {
      $_ = ucfirst($_);
      $m .= "::$_";
   }

   {
      no strict 'refs';
      my @isa = @{$m.'::ISA'};
      for (@isa) {
         next unless /^Metabrik::/;
         (my $name = $_) =~ s/^Metabrik:://;
         $name = lc($name);
         push @final, $name;
         my $list = $self->get_brik_hierarchy($name) or next;
         push @final, @$list;
      }
   }

   return \@final;
}

#
# Will return a list of all Briks needed to complete the full hierarchy.
# That means we also crawl required Briks own hierarchy.
#
sub get_brik_hierarchy_recursive {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('get_brik_hierarchy_recursive', $brik) or return;

   my $hierarchy = {};

   # We first gather the provided Brik hierarchy
   my $provided = $self->get_brik_hierarchy($brik) or return;
   for (@$provided) {
      $self->debug && $self->log->debug("get_brik [$_]");
      $hierarchy->{$_}++;
   }

   # And required Briks hierarchy
   my $required = $self->get_require_briks($brik) or return;
   for (@$required) {
      $self->debug && $self->log->debug("get_require [$_]");
      $hierarchy->{$_}++;
   }

   # Then we search for complete hierarchy recursively
   for my $this (keys %$hierarchy) {
      next if $this eq $brik;  # Skip the provided one.
      next if exists $hierarchy->{$this}; # Skip already analyzed ones.
      my $new = $self->get_brik_hierarchy_recursive($this) or return;
      for (@$new) {
         $hierarchy->{$_}++;
      }
   }

   return [ sort { $a cmp $b } keys %$hierarchy ];
}

sub install_packages {
   my $self = shift;
   my ($packages) = @_;

   $self->brik_help_run_undef_arg('install_packages', $packages) or return;
   $self->brik_help_run_invalid_arg('install_packages', $packages, 'ARRAY') or return;

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   return $sp->install($packages);
}

sub install_modules {
   my $self = shift;
   my ($modules) = @_;

   $self->brik_help_run_undef_arg('install_modules', $modules) or return;
   $self->brik_help_run_invalid_arg('install_modules', $modules, 'ARRAY') or return;

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   return $pm->install($modules);
}

sub install_all_need_packages {
   my $self = shift;

   # We don't want to fail on a missing package, so we install Brik by Brik
   #my $packages = $self->get_need_packages or return;
   #my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   #return $sp->install($packages);

   my $con = $self->context;

   my @missing = ();
   my $available = $con->available;
   for my $brik (sort { $a cmp $b } keys %$available) {
      # Skipping log modules to avoid messing stuff
      next if ($brik =~ /^log::/);
      # Skipping system packages modules too
      next if ($brik =~ /^system::.*(?:::)?package$/);
      $self->log->verbose("install_all_need_packages: installing packages for Brik [$brik]");
      my $r = $self->install_needed_packages($brik);
      if (! defined($r)) {
         push @missing, $brik;
      }
   }

   if (@missing > 0) {
      $self->log->warning("install_all_need_packages: unable to install packages for ".
         "Brik(s): [".join(', ', @missing)."]");
   }

   return 1;
}

sub install_all_require_modules {
   my $self = shift;

   my $modules = $self->get_require_modules or return;

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   return $pm->install($modules);
}

sub install_needed_packages {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('install_needed_packages', $brik) or return;

   my $packages = $self->get_need_packages_recursive($brik) or return;
   if (@$packages == 0) {
      return 1;
   }

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   return $sp->install($packages);
}

#
# Install modules that are NOT Briks.
#
sub install_required_modules {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('install_required_modules', $brik) or return;

   my $modules = $self->get_require_modules_recursive($brik) or return;
   if (@$modules == 0) {
      return 1;
   }

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   return $pm->install($modules);
}

#
# Install modules that are ONLY Briks.
#
sub install_required_briks {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('install_required_briks', $brik) or return;

   my $briks = $self->get_require_briks_recursive($brik) or return;
   if (@$briks == 0) {
      return 1;
   }

   my $packages = [];
   my $modules = [];
   for my $brik (@$briks) {
      my $this_packages = $self->get_need_packages_recursive($brik) or next;
      my $this_modules = $self->get_require_modules_recursive($brik) or next;
      push @$packages, @$this_packages;
      push @$modules, @$this_modules;
   }

   my $uniq_packages = {};
   my $uniq_modules = {};
   for (@$packages) { $uniq_packages->{$_}++; }
   for (@$modules) { $uniq_modules->{$_}++; }
   $packages = [ sort { $a cmp $b } keys %$uniq_packages ];
   $modules = [ sort { $a cmp $b } keys %$uniq_modules ];

   $self->install_packages($packages);
   $self->install_modules($modules);

   return 1;
}

sub install {
   my $self = shift;
   my ($briks) = @_;

   $self->brik_help_run_undef_arg('install', $briks) or return;
   my $ref = $self->brik_help_run_invalid_arg('install', $briks, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'SCALAR') {
      $briks = [ $briks ];
   }

   my $packages = [];
   my $modules = [];
   for my $brik (@$briks) {
      $packages = $self->get_need_packages_recursive($brik) or return;
      $modules = $self->get_require_modules_recursive($brik) or return;
      my $this_briks = $self->get_require_briks_recursive($brik) or return;

      for my $this_brik (@$this_briks) {
         my $this_packages = $self->get_need_packages_recursive($this_brik) or next;
         my $this_modules = $self->get_require_modules_recursive($this_brik) or next;
         push @$packages, @$this_packages;
         push @$modules, @$this_modules;
      }

      my $uniq_packages = {};
      my $uniq_modules = {};
      for (@$packages) { $uniq_packages->{$_}++; }
      for (@$modules) { $uniq_modules->{$_}++; }
      $packages = [ sort { $a cmp $b } keys %$uniq_packages ];
      $modules = [ sort { $a cmp $b } keys %$uniq_modules ];
   }

   $self->install_packages($packages) or return;
   $self->install_modules($modules) or return;

   # Execute special install Command if any.
   for my $brik (@$briks) {
      my $module = 'Metabrik';
      my @toks = split(/::/, $brik);
      for (@toks) {
         $module .= '::'.ucfirst($_);
      }

      my $new = $module->new_from_brik_no_checks($self) or return;
      if ($new->can('install')) {
         $new->install or return;
      }
   }

   return 1;
}

sub create_tool {
   my $self = shift;
   my ($filename, $repository) = @_;

   $repository ||= $self->repository || '';
   $self->brik_help_run_undef_arg('create_tool', $filename) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   my $data =<<EOF
#!/usr/bin/env perl
#
# \$Id\$
#
use strict;
use warnings;

# Uncomment to use a custom repository
#use lib qw($repository/lib);

use Data::Dumper;
use Metabrik::Core::Context;
# Put other Briks to use here
# use Metabrik::File::Text;

my \$con = Metabrik::Core::Context->new or die("core::context");

# Init other Briks here
# my \$ft = Metabrik::File::Text->new_from_brik_init(\$con) or die("file::text");

# Put Metatool code here
# \$ft->write("test", "/tmp/test.txt");

exit(0);
EOF
;

   $ft->write($data, $filename) or return;

   return $filename;
}

sub create_brik {
   my $self = shift;
   my ($brik, $repository) = @_;

   $repository ||= $self->repository;
   $self->brik_help_run_undef_arg('create_brik', $brik) or return;
   $self->brik_help_run_undef_arg('create_brik', $repository) or return;

   $brik = lc($brik);
   if ($brik !~ m{^\w+::\w+(::\w+)*$}) {
      return $self->log->error("create_brik: invalid format for Brik [$brik]");
   }

   my @toks = split(/::/, $brik);
   if (@toks < 2) {
      return $self->log->error("create_brik: invalid format for Brik [$brik]");
   }
   for (@toks) {
      $_ = ucfirst($_);
   }

   my $directory;
   if (@toks > 2) {
      $directory = join('/', $repository, 'lib/Metabrik', @toks[0..$#toks-1]);
   }
   else {
      $directory = join('/', $repository, 'lib/Metabrik', $toks[0]);
   }
   my $filename = $directory.'/'.$toks[-1].'.pm';
   my $package = join('::', 'Metabrik', @toks);

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($directory) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   my $data =<<EOF
#
# \$Id\$
#
# $brik Brik
#
package $package;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '\$Revision\$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
      },
      commands => {
         install => [ ],  # Inherited
      },
      require_modules => {
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

sub brik_use_properties {
   my \$self = shift;

   return {
      attributes_default => {
      },
   };
}

sub brik_preinit {
   my \$self = shift;

   # Do your preinit here, return 0 on error.

   return \$self->SUPER::brik_preinit;
}

sub brik_init {
   my \$self = shift;

   # Do your init here, return 0 on error.

   return \$self->SUPER::brik_init;
}

sub example_command {
   my \$self = shift;
   my (\$arg1, \$arg2) = \@_;

   \$arg2 ||= \$self->arg2;
   \$self->brik_help_run_undef_arg('example_command', \$arg1) or return;
   my \$ref = \$self->brik_help_run_invalid_arg('example_command', \$arg2, 'ARRAY', 'SCALAR')
      or return;

   if (\$ref eq 'ARRAY') {
      # Do your stuff
   }
   else {
      # Do other stuff
   }

   return 1;
}

sub brik_fini {
   my \$self = shift;

   # Do your fini here, return 0 on error.

   return \$self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

$package - $brik Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
EOF
;

   $ft->write($data, $filename) or return;

   return $filename;
}

sub update_core {
   my $self = shift;

   my $datadir = $self->datadir;

   my $url = 'https://www.metabrik.org/hg/core';

   my $dm = Metabrik::Devel::Mercurial->new_from_brik_init($self) or return;
   $dm->use_pager(0);
   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   $pm->use_pager(0);

   if (! -d $datadir.'/core') {
      $dm->clone($url, $datadir.'/core') or return;
   }
   else {
      $dm->update($datadir.'/core') or return;
   }

   $pm->build($datadir.'/core') or return;
   $pm->clean($datadir.'/core') or return;
   $pm->build($datadir.'/core') or return;
   $pm->test($datadir.'/core') or return;
   $pm->install($datadir.'/core') or return;

   return 1;
}

sub update_repository {
   my $self = shift;

   # If we define the core::global repository Attribute, we use that as 
   # a local repository. We will not install Metabrik::Repository in that case.
   my $datadir = $self->datadir;
   my $repository = $datadir.'/repository';

   my $url = 'https://www.metabrik.org/hg/repository';

   my $dm = Metabrik::Devel::Mercurial->new_from_brik_init($self) or return;
   $dm->use_pager(0);
   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   $pm->use_pager(0);

   if (! -d $repository) {
      $dm->clone($url, $repository) or return;
   }
   else {
      $dm->update($repository) or return;
   }

   $pm->build($repository) or return;
   $pm->clean($repository) or return;
   $pm->build($repository) or return;
   $pm->test($repository) or return;
   $pm->install($repository) or return;

   $self->execute("cat $repository/UPDATING");

   $self->log->info("update_repository: the file just showed contains information that ".
                    "helps you follow API changes.");
   $self->log->info("Read it here [$repository/UPDATING].");

   return "$repository/UPDATING";
}

sub update {
   my $self = shift;

   $self->update_core or return;
   $self->update_repository or return;

   return 1;
}

sub test_repository {
   my $self = shift;
   my ($repository) = @_;

   $repository ||= $self->repository;
   $self->brik_help_run_undef_arg('test_repository', $repository) or return;

   my $pm = Metabrik::Perl::Module->new_from_brik_init($self) or return;
   $pm->use_pager(0);

   $pm->test($repository) or return;

   return 1;
}

sub view_brik_source {
   my $self = shift;
   my ($brik) = @_;

   $self->brik_help_run_undef_arg('view_brik_source', $brik) or return;

   my @toks = split(/::/, $brik);
   if (@toks < 2 && $brik ne 'metabrik') {
      return $self->log->error("view_brik_source: invalid Brik format for [$brik]");
   }

   # Handle special case for Metabrik.pm
   if ($brik eq 'metabrik') {
      @toks = ();
   }

   my $pager = $ENV{PAGER} || 'less';

   my $pm = 'Metabrik';
   for (@toks) {
      $_ = ucfirst($_);
      $pm .= "/$_";
   }
   $pm .= '.pm';

   $self->log->debug("view_brik_source: pm [$pm]");

   my $cmd = '';
   for (@INC) {
      $self->log->debug("view_brik_source: search [$_/$pm] file");
      if (-f "$_/$pm") {
         $cmd = "$pager $_/$pm";
         last;
      }
   }

   if (length($cmd) == 0) {
      return $self->log->error("view_brik_source: unable to find Brik [$brik] in \@INC");
   }

   return $self->system($cmd);
}

sub get_brik_module_file {
   my $self = shift;
   my ($brik, $inc) = @_;

   $self->brik_help_run_undef_arg('get_brik_module_file', $brik) or return;
   my @toks = split('::', $brik);
   if (@toks < 2 || @toks > 3) {
      return $self->log->error("get_brik_module_file: invalid Brik format [$brik]");
   }

   # If directories are not given, we use the default one
   if (! defined($inc)) {
      $inc = [ @INC ];
   }

   my $repository = $self->global->repository;

   my $name = $toks[-1];
   $name = ucfirst($name);
   $name .= '\.pm';

   my $file = 'undef';
   my $ff = Metabrik::File::Find->new_from_brik_init($self) or return;
   for my $directory (@$inc) {
      next if ! -d $directory; # Skip if directory does not exists

      my $list = $ff->files($directory, "^$name\$") or return;
      for my $this (@$list) {
         my $this_brik = $this;
         $this_brik =~ s{^$directory/Metabrik/}{};
         $this_brik =~ s{/}{::}g;
         $this_brik =~ s{\.pm$}{}g;
         $this_brik = lc($this_brik);
         if ($this_brik eq $brik) {
            $file = $this;
            last;
         }
      }

      if ($file ne 'undef') {
         last;
      }
   }

   return $file;
}

sub clone {
   my $self = shift;
   my ($brik, $repository) = @_;

   $repository ||= $self->global->repository;
   $self->brik_help_run_undef_arg('clone', $brik) or return;

   my @directories = ();
   for (@INC) {
      next if $_ eq $repository;  # Skip local repository
      push @directories, $_;
   }

   my $module_file = $self->get_brik_module_file($brik, \@directories) or return;
   if ($module_file eq 'undef') {
      $self->log->error("clone: unable to find file name matching Brik [$brik]");
   }

   $self->log->verbose("clone: found Brik [$brik] to clone from module file [$module_file]");

   my @toks = split('::', $brik);
   my $file = '';
   for (@toks) {
      $_ = ucfirst($_);
      $file .= "$_/";
   }
   $file =~ s{/$}{.pm};

   my $src_file = $module_file;
   my $dst_file = $repository.'/lib/Metabrik/'.$file;
   (my $dst_mkdir = $dst_file) =~ s{/[^/]+$}{};

   $self->debug && $self->log->debug("clone: src[$src_file] dst[$dst_file]");
   $self->debug && $self->log->debug("clone: mkdir[$dst_mkdir]");

   if (-f $dst_file) {
      return $self->log->error("clone: destination file [$dst_file] already exists");
   }

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($dst_mkdir) or return;
   $sf->copy($src_file, $dst_file) or return;
   $sf->chmod($dst_file, '644') or return;

   $self->context->update_available or return;

   return $dst_file;
}

#
# Will return the complete list of required binaries if no Argument is given,
# or the list of required binaries for the specified Brik.
#
sub get_require_binaries {
   my $self = shift;
   my ($brik) = @_;

   my $con = $self->context;
   my $available = $con->available;

   # If we asked for one Brik, we rewrite available to only have this one.
   if (defined($brik)) {
      $available = { $brik => $available->{$brik} };
   }

   my $sp = Metabrik::System::Package->new_from_brik_init($self) or return;
   my $os = $sp->my_os or return;

   my %packages = ();
   for my $this (keys %$available) {
      next if $this =~ m{^core::};
      if (defined($available->{$this})
      &&  exists($available->{$this}->brik_properties->{require_binaries})) {
         my $list = [ keys %{$available->{$this}->brik_properties->{require_binaries}} ];
         for my $p (@$list) {
            $packages{$p}++;
         }
      }
   }

   return [ sort { $a cmp $b } keys %packages ];
}

1;

__END__

=head1 NAME

Metabrik::Brik::Tool - brik::tool Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
