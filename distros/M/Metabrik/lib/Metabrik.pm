#
# $Id$
#
package Metabrik;
use strict;
use warnings;

# Breaking.Feature.Fix
our $VERSION = '1.41';
our $FIX = '0';

use base qw(Class::Gomor::Hash);

our @AS = qw(
   init_done
   preinit_done
   check_use_properties_done
   context
   global
   log
   shell
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub brik_version {
   my $self = shift;

   my $revision = $self->brik_properties->{revision};
   $revision =~ s/^.*\s([a-f0-9]+)\s.*$/$1/;

   return $VERSION.'.'.$FIX.'-'.$revision;
}

sub brik_author {
   my $self = shift;

   my $author = $self->brik_properties->{author};

   # Default to GomoR
   return $author || 'GomoR <GomoR[at]metabrik.org>';
}

sub brik_license {
   my $self = shift;

   my $license = $self->brik_properties->{license};

   # Default to BSD 3-Clause
   return $license || 'http://opensource.org/licenses/BSD-3-Clause';
}

sub brik_properties {
   return {
      revision => '$Revision$',
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      tags => [ ],
      attributes => {
         init_done => [ qw(0|1) ],
         context => [ qw(core::context) ],
         global => [ qw(core::global) ],
         log => [ qw(core::log) ],
         shell => [ qw(core::shell) ],
      },
      attributes_default => {
         init_done => 0,
      },
      commands => {
         brik_version => [ ],
         brik_author => [ ],
         brik_license => [ ],
         brik_help_set => [ qw(Attribute) ],
         brik_help_run => [ qw(Command) ],
         brik_class => [ ],
         brik_classes => [ ],
         brik_name => [ ],
         brik_repository => [ ],
         brik_category => [ ],
         brik_tags => [ ],
         brik_has_tag => [ qw(Tag) ],
         brik_commands => [ ],             # Return full list of Commands
         brik_base_commands => [ ],        # Return only base class Commands
         brik_inherited_commands => [ ],   # Return only inherited Commands
         brik_own_commands => [ ],         # Return only own Commands
         brik_has_command => [ qw(Command) ],
         brik_attributes => [ ],            # Return full list of Attributes
         brik_base_attributes => [ ],       # Return only base class Attributes
         brik_inherited_attributes => [ ],  # Return only inherited Attributes
         brik_own_attributes => [ ],        # Return only own Attributes
         brik_has_attribute => [ qw(Attribute) ],
         brik_preinit => [ qw(Arguments) ],
         brik_preinit_no_checks => [ qw(Arguments) ],
         brik_init => [ qw(Arguments) ],
         brik_init_no_checks => [ qw(Arguments) ],
         brik_self => [ ],
         brik_fini => [ qw(Arguments) ],
         brik_create_attributes => [ ],
         brik_set_default_attributes => [ ],
         brik_check_require_modules => [ ],
         brik_check_require_binaries => [ ],
         brik_check_properties => [ ],
         brik_check_use_properties => [ ],
         brik_checks => [ ],
         brik_has_binary => [ qw(binary) ],
         brik_has_module => [ qw(module) ],
         brik_help_run_undef_arg => [ qw(Command Arg) ],
         brik_help_set_undef_arg => [ qw(Command Arg) ],
         brik_help_run_invalid_arg => [ qw(Command Arg valid_list) ],
         brik_help_run_empty_array_arg => [ qw(Command Arg) ],
         brik_help_run_file_not_found => [ qw(Command Arg) ],
         brik_help_run_directory_not_found => [ qw(Command Arg) ],
         brik_help_run_must_be_root => [ qw(Command) ],
      },
      require_modules => { },
      optional_modules => { },
      require_binaries => { },
      optional_binaries => { },
      need_packages => { },
      need_services => { },
   };
}

sub brik_use_properties {
   return { };
}

sub brik_help_set {
   my $self = shift;
   my ($attribute) = @_;

   my $name = $self->brik_name;

   if (! defined($attribute)) {
      return $self->log->info("run $name brik_help_set <attribute>");
   }

   my $classes = $self->brik_classes;

   for my $class (reverse @$classes) {
      my $attributes = $class->brik_attributes;

      if (exists($attributes->{$attribute})) {
         my $help = sprintf("%s ", $attribute);
         for (@{$attributes->{$attribute}}) {
            $help .= "<$_> ";
         }
         return $help;
      }
   }

   return;
}

sub brik_help_run {
   my $self = shift;
   my ($command) = @_;

   my $name = $self->brik_name;

   if (! defined($command)) {
      return $self->log->info("run $name brik_help_run <command>");
   }

   my $classes = $self->brik_classes;

   for my $class (reverse @$classes) {
      my $commands = $class->brik_commands;

      if (exists($commands->{$command})) {
         my $help = sprintf("%s ", $command);
         for (@{$commands->{$command}}) {
            if (m{\|OPTIONAL}) {
               s/\|OPTIONAL\s*$//;
               $help .= "[ <$_> ] ";
            }
            else {
               $help .= "<$_> ";
            }
         }
         return $help;
      }
   }

   return;
}

sub brik_check_properties {
   my $self = shift;
   my ($properties) = @_;

   my $name = $self->brik_name;
   if (! $self->can('brik_properties')) {
      return $self->log->error("brik_check_properties: Brik [$name] has no brik_properties");
   }

   $properties ||= $self->brik_properties;

   my $error = 0;

   # Check all mandatory keys are present
   my @mandatory_keys = qw(
      tags
   );
   for my $key (@mandatory_keys) {
      if (! exists($properties->{$key})) {
         print("[-] brik_check_properties: Brik [$name]: brik_properties lacks mandatory key [$key]\n");
         $error++;
      }
   }

   # Check all keys are valid
   my %valid_keys = (
      revision => 1,
      author => 1,
      license => 1,
      tags => 1,
      attributes => 1,
      attributes_default => 1,
      commands => 1,
      require_modules => 1,
      optional_modules => 1,
      require_binaries => 1,
      optional_binaries => 1,
      need_packages => 1,
      need_services => 1,
   );
   for my $key (keys %$properties) {
      if (! exists($valid_keys{$key})) {
         print("[-] brik_check_properties: brik_properties has invalid key [$key]\n");
         $error++;
      }
      elsif ($key eq 'tags' && ref($properties->{$key}) ne 'ARRAY') {
         print("[-] brik_check_properties: brik_properties with key [$key] is not an ARRAYREF\n");
         $error++;
      }
      elsif ($key ne 'revision' && $key ne 'author' && $key ne 'license' && $key ne 'tags' && ref($properties->{$key}) ne 'HASH') {
         print("[-] brik_check_properties: brik_properties with key [$key] is not a HASHREF\n");
         $error++;
      }
   }

   # Check HASHREFs contains pointers to ARRAYREFs
   for my $key (keys %$properties) {
      next if ($key eq 'revision' || $key eq 'author' || $key eq 'license' || $key eq 'tags' || $key eq 'attributes_default');

      for my $subkey (keys %{$properties->{$key}}) {
         if (ref($properties->{$key}->{$subkey}) ne 'ARRAY') {
            print("[-] brik_check_properties: brik_properties with key [$key] and subkey [$subkey] is not an ARRAYREF\n");
            $error++;
         }
      }
   }

   if ($error) {
      print("[-] brik_check_properties: Brik [$name] has invalid properties ($error error(s) found)\n");
      return 0;
   }

   return 1;
}

sub brik_check_use_properties {
   my $self = shift;
   my ($use_properties) = @_;

   # Do it once.
   return 1 if $self->check_use_properties_done;

   my $name = $self->brik_name;
   if (! $self->can('brik_use_properties')) {
      return 1;
   }

   $use_properties ||= $self->brik_use_properties;

   my $error = 0;

   # Check all mandatory keys are present
   my @mandatory_keys = qw(
   );
   for my $key (@mandatory_keys) {
      if (! exists($use_properties->{$key})) {
         print("[-] brik_check_use_properties: Brik [$name]: brik_use_properties lacks mandatory key [$key]\n");
         $error++;
      }
   }

   # Check all keys are valid
   my %valid_keys = (
      revision => 1,
      author => 1,
      license => 1,
      tags => 1,
      attributes => 1,
      attributes_default => 1,
      commands => 1,
      require_modules => 1,
      optional_modules => 1,
      require_binaries => 1,
      optional_binaries => 1,
      need_packages => 1,
      need_services => 1,
   );
   for my $key (keys %$use_properties) {
      if (! exists($valid_keys{$key})) {
         print("[-] brik_check_use_properties: brik_use_properties has invalid key [$key]\n");
         $error++;
      }
      elsif ($key eq 'tags' && ref($use_properties->{$key}) ne 'ARRAY') {
         print("[-] brik_check_use_properties: brik_use_properties with key [$key] is not an ARRAYREF\n");
         $error++;
      }
      elsif ($key ne 'revision' && $key ne 'author' && $key ne 'license' && $key ne 'tags' && ref($use_properties->{$key}) ne 'HASH') {
         print("[-] brik_check_use_properties: brik_use_properties with key [$key] is not a HASHREF\n");
         $error++;
      }
   }

   # Check HASHREFs contains pointers to ARRAYREFs
   for my $key (keys %$use_properties) {
      next if ($key eq 'revision' || $key ne 'author' && $key ne 'license' || $key eq 'tags' || $key eq 'attributes_default');

      for my $subkey (keys %{$use_properties->{$key}}) {
         if (ref($use_properties->{$key}->{$subkey}) ne 'ARRAY') {
            print("[-] brik_check_use_properties: brik_use_properties with key [$key] and subkey [$subkey] is not an ARRAYREF\n");
            $error++;
         }
      }
   }

   if ($error) {
      print("[-] brik_check_use_properties: Brik [$name] has invalid properties ($error error(s) found)\n");
      return 0;
   }

   $self->check_use_properties_done(1);

   return 1;
}

sub brik_checks {
   my $self = shift;

   $self->brik_check_properties or return;
   $self->brik_check_use_properties or return;
   $self->brik_check_require_modules or return;
   $self->brik_check_require_binaries or return;

   return $self;
}

sub _msg {
   my ($self, $msg) = @_;
   $msg ||= 'undef';
   chomp($msg);
   my $class = ref($self) || $self;
   $class = lc($class);
   $class =~ s/^metabrik:://i;
   return lc($class).": $msg";
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $r = $self->brik_create_attributes;
   if (! defined($r)) {
      if (defined($self->log)) {
         return $self->log->error("new: brik_create_attributes failed");
      }
      else {
         my $msg = _msg($self, "new: brik_create_attributes failed");
         print("[-] $msg\n");
         return;
      }
   }

   # Create a default core::loglite Brik, if not given.
   if (! defined($self->log)) {
      {
         no strict 'refs';

         push @{'Metabrik::Core::Loglite::ISA'}, 'Metabrik';

         *{'Metabrik::Core::Loglite::allow_log_override'} = sub {
            my $self = shift;
            my ($value) = @_;
            if (defined($value)) {
               $self->{allow_log_override} = $value;
            }
            return $self->{allow_log_override};
         };

         *{'Metabrik::Core::Loglite::level'} = sub {
            my $self = shift;
            my ($value) = @_;
            if (defined($value)) {
               $self->{level} = $value;
            }
            return $self->{level};
         };

         *{'Metabrik::Core::Loglite::color'} = sub {
            my $self = shift;
            my ($value) = @_;
            if (defined($value)) {
               $self->{color} = $value;
            }
            return $self->{color};
         };

         *{'Metabrik::Core::Loglite::info'} = sub {
            my $self = shift;
            my ($msg) = @_;
            return 1 if ($self->level < 1);
            $msg = _msg($self, $msg);
            print("[+] $msg\n");
            return 1;
         };

         *{'Metabrik::Core::Loglite::error'} = sub {
            my $self = shift;
            my ($msg) = @_;
            return if ($self->level < 1);
            $msg = _msg($self, $msg);
            print("[-] $msg\n");
            return;
         };

         *{'Metabrik::Core::Loglite::fatal'} = sub {
            my $self = shift;
            my ($msg) = @_;
            # In log level 0, we print nothing except fatal errors.
            $msg = _msg($self, $msg);
            die("[F] $msg\n");
            return;
         };

         *{'Metabrik::Core::Loglite::warning'} = sub {
            my $self = shift;
            my ($msg) = @_;
            return 1 if ($self->level < 1);
            $msg = _msg($self, $msg);
            print("[!] $msg\n");
            return 1;
         };

         *{'Metabrik::Core::Loglite::verbose'} = sub {
            my $self = shift;
            my ($msg) = @_;
            return 1 if ($self->level < 2);
            $msg = _msg($self, $msg);
            print("[*] $msg\n");
            return 1;
         };

         *{'Metabrik::Core::Loglite::debug'} = sub {
            my $self = shift;
            my ($msg) = @_;
            return 1 if ($self->level < 3);
            $msg = _msg($self, $msg);
            print("[D] $msg\n");
            return 1;
         };
      }

      $self->log(bless(
          { level => 1, color => 0, allow_log_override => 0 },
          'Metabrik::Core::Loglite',
      ));
   }

   return $self->brik_preinit;
}

sub new_no_checks {
   my $self = shift->SUPER::new(
      @_,
   );

   my $r = $self->brik_create_attributes;
   if (! defined($r)) {
      return $self->log->error("new_no_checks: brik_create_attributes failed");
   }

   return $self->brik_preinit_no_checks;
}

sub new_from_brik {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error("new_from_brik: you must give a Brik object as argument");
   }

   my $log = $brik->log;
   my $glo = $brik->global;
   my $con = $brik->context;
   my $she = $brik->shell;

   my %args = ();
   if (defined($log)) {
      $args{log} = $log;
   }
   if (defined($glo)) {
      $args{global} = $glo;
   }
   if (defined($con)) {
      $args{context} = $con;
   }
   if (defined($she)) {
      $args{shell} = $she;
   }

   return $self->new(%args);
}

sub new_from_brik_no_checks {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error("new_from_brik_no_checks: you must give a Brik object as argument");
   }

   my $log = $brik->log;
   my $glo = $brik->global;
   my $con = $brik->context;
   my $she = $brik->shell;

   my %args = ();
   if (defined($log)) {
      $args{log} = $log;
   }
   if (defined($glo)) {
      $args{global} = $glo;
   }
   if (defined($con)) {
      $args{context} = $con;
   }
   if (defined($she)) {
      $args{shell} = $she;
   }

   return $self->new_no_checks(%args);
}

sub new_from_brik_init {
   my $self = shift;

   my $brik = $self->new_from_brik(@_)
      or return $self->log->error("new_from_brik_init: new_from_brik failed");
   $brik->brik_init
      or return $self->log->error("new_from_brik_init: brik_init failed");

   return $brik;
}

sub new_from_brik_init_no_checks {
   my $self = shift;

   my $brik = $self->new_from_brik_no_checks(@_)
      or return $self->log->error("new_from_brik_init_no_checks: new_from_brik_no_checks failed");
   $brik->brik_init_no_checks
      or return $self->log->error("new_from_brik_init_no_checks: brik_init_no_checks failed");

   return $brik;
}

sub new_brik_init {
   my $self = shift;

   my $brik = $self->new(@_)
      or return $self->log->error("new_brik_init: new failed");
   $brik->brik_init
      or return $self->log->error("new_brik_init: brik_init failed");

   return $brik;
}

sub new_brik_init_no_checks {
   my $self = shift;

   my $brik = $self->new_no_checks(@_)
      or return $self->log->error("new_brik_init_no_checks: new_no_checks failed");
   $brik->brik_init_no_checks
      or return $self->log->error("new_brik_init_no_checks: brik_init_no_checks failed");

   return $brik;
}

# Build Attributes, Class::Gomor style
sub brik_create_attributes {
   my $self = shift;

   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      my $attributes = $class->brik_properties->{attributes};

      my @as = ( keys %$attributes );
      if (@as > 0) {
         no strict 'refs';

         my %current = map { $_ => 1 } @{$class.'::AS'};
         my @new = ();
         for my $this (@as) {
            if (! exists($current{$this})) {
               push @new, $this;
            }
         }

         push @{$class.'::AS'}, @new;
         for my $this (@new) {
            if (! $class->can($this)) {
               $class->cgBuildAccessorsScalar([ $this ]);
            }
         }
      }
   }

   return 1;
}

# Set default values for Attributes
sub brik_set_default_attributes {
   my $self = shift;

   my $classes = $self->brik_classes;

   # Set default Attributes from brik_properties hierarchy
   for my $class (@$classes) {
      # brik_properties() is the general value to use for the default_attributes
      if (exists($class->brik_properties->{attributes_default})) {
         for my $attribute (keys %{$class->brik_properties->{attributes_default}}) {
            #next unless defined($self->$attribute); # Do not overwrite if set on new
            $self->$attribute($class->brik_properties->{attributes_default}->{$attribute});
         }
      }
   }

   # Special case: automatic setting of some defaults (datadir)
   # No inheritance here, it is just for currently instanciated Brik.
   # We either take the global datadir if avail, or the Brik's one.
   # Global datadir is just the base path, like $ENV{HOME}."/metabrik".
   my $datadir;
   my $global_datadir;
   my $global = $self->global;
   if (defined($global)) {
      $global_datadir = $self->global->datadir;
   }

   if (exists($self->brik_properties->{attributes})
   &&  exists($self->brik_properties->{attributes}->{datadir})) {
      $datadir = $self->datadir;

      my $dir;
      # If datadir is set by user, we use it blindly.
      # Usually, only core::global will have it set.
      if (defined($datadir)) {
         $dir = $datadir;
      }
      # Else, we build it
      else {
         $dir = $global_datadir || (defined($ENV{HOME}) && $ENV{HOME}."/metabrik")
                                || "/tmp/metabrik";
         if (! -d $dir) {
            mkdir($dir)
               or return $self->log->error("brik_set_default_attributes: mkdir ".
                  "[$dir] failed: $!");
         }

         (my $subdir = $self->brik_name) =~ s/::/-/g;
         if (length($subdir)) {
            $dir .= '/'.$subdir;
         }

         $self->datadir($dir);
      }

      if (! -d $dir) {
         mkdir($dir)
            or return $self->log->error("brik_set_default_attributes: mkdir [$dir] ".
               "failed: $!");
      }
   }

   return 1;
}

sub brik_set_use_default_attributes {
   my $self = shift;

   # Set default Attributes from brik_use_properties, no hierarchy, just inheritance
   my $class = $self->brik_class;
   if ($self->can('brik_use_properties') && exists($self->brik_use_properties->{attributes_default})) {
      for my $attribute (keys %{$self->brik_use_properties->{attributes_default}}) {
         #next unless defined($self->$attribute); # Do not overwrite if set on new
         # Do not overwrite if Attribute is set by brik_properties
         next if exists($class->brik_properties->{attributes_default}->{$attribute});
         $self->$attribute($self->brik_use_properties->{attributes_default}->{$attribute});
      }
   }

   return 1;
}

# Module check
sub brik_check_require_modules {
   my $self = shift;
   my ($require_modules) = @_;

   my @require_modules_list = ();
   if (defined($require_modules)) {
      push @require_modules_list, $require_modules;
   }
   else {
      my $classes = $self->brik_classes;
      for my $class (@$classes) {
         push @require_modules_list, $class->brik_properties->{require_modules};
      }
   }

   my $error = 0;
   for my $require_modules (@require_modules_list) {
      for my $module (keys %$require_modules) {
         eval("require $module;");
         if ($@) {
            chomp($@);
            $self->log->error("brik_check_require_modules: you have to install ".
               "module [$module]");
            $self->log->debug("brik_check_require_modules: $@");
            $error++;
            next;
         }

         my @imports = @{$require_modules->{$module}};
         if (@imports > 0) {
            eval('$module->import(@imports);');
            if ($@) {
            chomp($@);
               $self->log->error("brik_check_require_modules: unable to import ".
                  "functions [@imports] from module [$module]");
               $self->log->debug("brik_check_require_modules: $@");
               $error++;
               next;
            }
         }
      }
   }

   return $error ? 0 : 1;
}

sub brik_check_require_binaries {
   my $self = shift;
   my ($require_binaries) = @_;

   my @require_binaries_list = ();
   if (defined($require_binaries)) {
      push @require_binaries_list, $require_binaries;
   }
   else {
      my $classes = $self->brik_classes;
      for my $class (@$classes) {
         push @require_binaries_list, $class->brik_properties->{require_binaries};
      }
   }

   my %binaries_found = ();
   for my $require_binaries (@require_binaries_list) {
      for my $binary (keys %$require_binaries) {
         $binaries_found{$binary} = 0;
         my @path = split(':', $ENV{PATH});
         for my $path (@path) {
            if (-f "$path/$binary") {
               $binaries_found{$binary} = 1;
               last;
            }
         }
      }
   }

   my $error = 0;
   for my $binary (keys %binaries_found) {
      if (! $binaries_found{$binary}) {
         $self->log->error("brik_check_require_binaries: binary [$binary] not found in PATH");
         $error++;
      }
   }

   return $error ? 0 : 1;
}

sub brik_repository {
   my $self = shift;

   my $name = $self->brik_name;

   my @toks = split('::', $name);

   # No repository defined
   if (@toks == 2) {
      return 'main';
   }
   elsif (@toks > 2) {
      my ($repository) = $name =~ /^(.*?)::.*/;
      return $repository;
   }

   # Error, repository not found
   return $self->log->fatal("brik_repository: no Repository found for Brik [$name] (invalid format?)");
}

sub brik_category {
   my $self = shift;

   my $name = $self->brik_name;

   my @toks = split('::', $name);

   # No repository defined
   if (@toks == 2) {
      my ($category) = $name =~ /^(.*?)::.*/;
      return $category;
   }
   elsif (@toks > 2) {
      my ($category) = $name =~ /^.*?::(.*?)::.*/;
      return $category;
   }

   # Error, category not found
   return $self->log->fatal("brik_category: no Category found for Brik [$name] (invalid format?)");
}

sub brik_name {
   my $self = shift;

   my $module = lc($self->brik_class);
   $module =~ s/^metabrik:://;

   return $module;
}

sub brik_class {
   my $self = shift;

   return ref($self) || $self;
}

sub brik_classes {
   my $self = shift;

   my $class = $self->brik_class;
   my $ary = [ $class ];
   $class->cgGetIsaTree($ary);

   my @classes = ();

   for my $class (@$ary) {
      # We may have Metabrik subclasses from other stuff than Metabrik
      next if ($class !~ /^Metabrik/);
      push @classes, $class;
   }

   return [ reverse @classes ];
}

sub brik_tags {
   my $self = shift;

   my $tags = $self->brik_properties->{tags};

   my $brik_name = $self->brik_name;
   my @auto_tags = split(/::/, $brik_name);

   my %uniq = map { $_ => 1 } (@auto_tags, @$tags);

   return [ sort { $a cmp $b } keys %uniq ];
}

sub brik_has_tag {
   my $self = shift;
   my ($tag) = @_;

   if (! defined($tag)) {
      return $self->log->error($self->brik_help_run('brik_has_tag'));
   }

   my %h = map { $_ => 1 } @{$self->brik_tags};

   if (exists($h{$tag})) {
      return 1;
   }

   return 0;
}

# Will return all Commands, base, inherited, and own ones.
sub brik_commands {
   my $self = shift;

   my $commands = { };

   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      #$self->log->info("brik_commands: class[$class]");

      if (exists($class->brik_properties->{commands})) {
         for my $command (keys %{$class->brik_properties->{commands}}) {
            next unless $command =~ /^[a-z]/; # Brik Commands always begin with a minuscule
            next if $command =~ /^cg[A-Z]/; # Class::Gomor stuff
            next if $command =~ /^_/; # Internal stuff
            next if $command =~ /^(?:a|b|import|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff

            #$self->log->info("command[$command]");

            $commands->{$command} = $class->brik_properties->{commands}->{$command};
         }
      }
   }

   return $commands;
}

# Will return only base Commands
sub brik_base_commands {
   my $self = shift;

   my $commands = { };

   for my $command (keys %{Metabrik->brik_properties->{commands}}) {
      next unless $command =~ /^[a-z]/; # Brik Commands always begin with a minuscule
      next if $command =~ /^cg[A-Z]/; # Class::Gomor stuff
      next if $command =~ /^_/; # Internal stuff
      next if $command =~ /^(?:a|b|import|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff

      #$self->log->info("command[$command]");

      $commands->{$command} = Metabrik->brik_properties->{commands}->{$command};
   }

   return $commands;
}

# Will return only inherited Commands
sub brik_inherited_commands {
   my $self = shift;

   my $commands = { };

   my $classes = $self->brik_classes;
   my $own_class = ref($self);

   for my $class (@$classes) {
      next if $class eq 'Metabrik'; # Skip base class Commands
      next if $class eq $own_class; # Skip own class Commands
      if (exists($class->brik_properties->{commands})) {
         for my $command (keys %{$class->brik_properties->{commands}}) {
            next unless $command =~ /^[a-z]/; # Brik Commands always begin with a minuscule
            next if $command =~ /^cg[A-Z]/; # Class::Gomor stuff
            next if $command =~ /^_/; # Internal stuff
            next if $command =~ /^(?:a|b|import|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff

            $commands->{$command} = $class->brik_properties->{commands}->{$command};
         }
      }
   }

   return $commands;
}

# Will return only own Commands
sub brik_own_commands {
   my $self = shift;

   my $commands = { };

   if (exists($self->brik_properties->{commands})) {
      for my $command (keys %{$self->brik_properties->{commands}}) {
         next unless $command =~ /^[a-z]/; # Brik Commands always begin with a minuscule
         next if $command =~ /^cg[A-Z]/; # Class::Gomor stuff
         next if $command =~ /^_/; # Internal stuff
         next if $command =~ /^(?:a|b|import|new|SUPER::|BEGIN|isa|can|EXPORT|AA|AS|ISA|DESTROY|__ANON__)$/; # Perl stuff

         #$self->log->info("command[$command]");

         $commands->{$command} = $self->brik_properties->{commands}->{$command};
      }
   }

   return $commands;
}

sub brik_has_command {
   my $self = shift;
   my ($command) = @_;

   if (! defined($command)) {
      return $self->log->error($self->brik_help_run('brik_has_command'));
   }

   if (exists($self->brik_commands->{$command})) {
      return 1;
   }

   return 0;
}

# Will return all Attributes, base, inherited, and own ones.
sub brik_attributes {
   my $self = shift;

   my $attributes = { };

   my $classes = $self->brik_classes;

   for my $class (@$classes) {
      #$self->log->info("brik_attributes: class[$class]");

      if (exists($class->brik_properties->{attributes})) {
         for my $attribute (keys %{$class->brik_properties->{attributes}}) {
            next unless $attribute =~ /^[a-z]/; # Brik Attributes always begin with a minuscule
            next if $attribute =~ /^_/;         # Internal stuff

            $attributes->{$attribute} = $class->brik_properties->{attributes}->{$attribute};
         }
      }
   }

   return $attributes;
}

# Will return only base Attributes
sub brik_base_attributes {
   my $self = shift;

   my $attributes = { };

   for my $attribute (keys %{Metabrik->brik_properties->{attributes}}) {
      next unless $attribute =~ /^[a-z]/; # Brik Attributes always begin with a minuscule
      next if $attribute =~ /^_/;         # Internal stuff

      $attributes->{$attribute} = Metabrik->brik_properties->{attributes}->{$attribute};
   }

   return $attributes;
}

# Will return only inherited Attributes
sub brik_inherited_attributes {
   my $self = shift;

   my $attributes = { };

   my $classes = $self->brik_classes;
   my $own_class = ref($self);

   for my $class (@$classes) {
      next if $class eq 'Metabrik';  # Skip base class Attributes
      next if $class eq $own_class;  # Skip own class Attributes
      if (exists($class->brik_properties->{attributes})) {
         for my $attribute (keys %{$class->brik_properties->{attributes}}) {
            next unless $attribute =~ /^[a-z]/; # Brik Attributes always begin with a minuscule
            next if $attribute =~ /^_/;         # Internal stuff

            $attributes->{$attribute} = $class->brik_properties->{attributes}->{$attribute};
         }
      }
   }

   return $attributes;
}

# Will return only own Attributes
sub brik_own_attributes {
   my $self = shift;

   my $attributes = { };

   if (exists($self->brik_properties->{attributes})) {
      for my $attribute (keys %{$self->brik_properties->{attributes}}) {
         next unless $attribute =~ /^[a-z]/; # Brik Attributes always begin with a minuscule
         next if $attribute =~ /^_/;         # Internal stuff

         $attributes->{$attribute} = $self->brik_properties->{attributes}->{$attribute};
      }
   }

   return $attributes;
}

sub brik_has_attribute {
   my $self = shift; 
   my ($attribute) = @_;

   if (! defined($attribute)) {
      return $self->log->error($self->brik_help_run('brik_has_attribute'));
   }

   if (exists($self->brik_attributes->{$attribute})) {
      return 1;
   }

   return 0;
}

sub brik_has_module {
   my $self = shift;
   my ($module) = @_;

   if (! defined($module)) {
      return $self->log->error($self->brik_help_run('brik_has_module'));
   }

   eval("require $module;");
   if ($@) {
      return 0;
   }

   return 1;
}

sub brik_has_binary {
   my $self = shift;
   my ($binary) = @_;

   if (! defined($binary)) {
      return $self->log->error($self->brik_help_run('brik_has_binary'));
   }

   my @path = split(':', $ENV{PATH});
   for my $path (@path) {
      if (-f "$path/$binary") {
         return 1;
      }
   }

   return 0;
}

# brik_preinit() directly runs after new() is run. new() is called on use().
sub brik_preinit {
   my $self = shift;

   # Do it once.
   return $self if $self->preinit_done;

   my $r = $self->brik_set_default_attributes;
   if (! defined($r)) {
      return $self->log->error("brik_preinit: brik_set_default_attributes failed");
   }

   # We have to put it here, cause brik_use_properties method is called, and 
   # we want some default attributes to be set defore that (datadir special case)
   # brik_preinit method is called by new(), so no problem, it will be checked.
   $r = $self->brik_checks;
   if (! defined($r)) {
      return $self->log->error("brik_preinit: brik_checks failed");
   }

   # Now, we can set default Attributes from brik_use_properties, all brik_properties
   # Attributes should be inited with defaults.
   $r = $self->brik_set_use_default_attributes;
   if (! defined($r)) {
      return $self->log->error("brik_preinit: brik_set_use_default_attributes failed");
   }

   $self->preinit_done(1);

   return $self;
}

sub brik_preinit_no_checks {
   my $self = shift;

   # Do it once.
   return $self if $self->preinit_done;

   my $r = $self->brik_set_default_attributes;
   if (! defined($r)) {
      return $self->log->error("brik_preinit: brik_set_default_attributes failed");
   }

   # Now, we can set default Attributes from brik_use_properties, all brik_properties
   # Attributes should be inited with defaults.
   $r = $self->brik_set_use_default_attributes;
   if (! defined($r)) {
      return $self->log->error("brik_preinit: brik_set_use_default_attributes failed");
   }

   $self->preinit_done(1);

   return $self;
}

sub brik_init {
   my $self = shift;

   return $self->init_done(1);
}

sub brik_init_no_checks {
   my $self = shift;

   return $self->init_done(1);
}

sub brik_self {
   my $self = shift;

   return $self;
}

# brik_fini Command is run when core::shell run_exit Command is called
# It itselves call core::context brik_fini Command which loops over all used Briks
sub brik_fini {
   my $self = shift;

   return $self;
}

sub brik_help_run_undef_arg {
   my $self = shift;
   my ($command, $argument) = @_;

   my ($package, $filename, $line) = caller();
   my $brik = lc($package);
   $brik =~ s/^metabrik:://;

   if (! defined($argument)) {
      return $self->log->error("$brik: ".$self->brik_help_run($command));
   }

   return 1;
}

sub brik_help_set_undef_arg {
   my $self = shift;
   my ($command, $argument) = @_;

   my ($package, $filename, $line) = caller();
   my $brik = lc($package);
   $brik =~ s/^metabrik:://;

   if (! defined($argument)) {
      return $self->log->error("$brik: ".$self->brik_help_set($command));
   }

   return 1;
}

sub brik_help_run_invalid_arg {
   my $self = shift;
   my ($command, $argument, @values) = @_;

   my ($package, $filename, $line) = caller();
   my $brik = lc($package);
   $brik =~ s/^metabrik:://;

   my $ref = ref($argument) || 'SCALAR';
   my $values = { map { $_ => 1 } @values };
   if (! exists($values->{$ref})) {
      my $ok = join(', ', @values);
      return $self->log->error("$brik: $command: invalid Argument [$argument], must be from [$ok]");
   }

   return $ref;
}

sub brik_help_run_empty_array_arg {
   my $self = shift;
   my ($command, $argument) = @_;

   my ($package, $filename, $line) = caller();
   my $brik = lc($package);
   $brik =~ s/^metabrik:://;

   if (ref($argument) ne 'ARRAY') {
      return $self->log->error("$brik: $command: Argument [$argument] is not an ARRAY");
   }

   if (@$argument <= 0) {
      return $self->log->error("$brik: $command: ARRAY Argument [$argument] is empty");
   }

   return 1;
}

sub brik_help_run_file_not_found {
   my $self = shift;
   my ($command, $argument) = @_;

   my ($package, $filename, $line) = caller();
   my $brik = lc($package);
   $brik =~ s/^metabrik:://;

   if (! -f $argument) {
      return $self->log->error("$brik: $command: file Argument [$argument] not found");
   }

   return 1;
}

sub brik_help_run_directory_not_found { 
   my $self = shift;
   my ($command, $argument) = @_;

   my ($package, $filename, $line) = caller();
   my $brik = lc($package);
   $brik =~ s/^metabrik:://;

   if (! -d $argument) {
      return $self->log->error("$brik: $command: directory Argument [$argument] not found"); 
   }

   return 1;
}

sub brik_help_run_must_be_root {
   my $self = shift;
   my ($command) = @_;

   my ($package, $filename, $line) = caller();
   my $brik = lc($package);
   $brik =~ s/^metabrik:://;

   if ($< != 0) {
      return $self->log->error("$brik: $command: must be root to run Command [$command]"); 
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik - There is Brik for that.

=head1 SYNOPSIS

   use base qw(Metabrik);

=head1 DESCRIPTION

This is the B<Metabrik> Superclass. Every Brik derives from this one at the very least.

=head1 ATTRIBUTES

At B<The Metabrik Shell>, just type:

L<get core::global>

=head1 COMMANDS

At B<The Metabrik Shell>, just type:

L<help core::global>

=head1 METHODS

=over 4

=item B<brik_properties>

=item B<brik_use_properties>

=item B<new>

=item B<new_from_brik>

=item B<new_from_brik_init>

=item B<new_no_checks>

=item B<new_from_brik_no_checks>

=item B<new_from_brik_init_no_checks>

=item B<new_brik_init>

=item B<new_brik_init_no_checks>

=item B<brik_self>

=item B<brik_preinit>

=item B<brik_preinit_no_checks>

=item B<brik_init>

=item B<brik_init_no_checks>

=item B<brik_attributes>

=item B<brik_author>

=item B<brik_category>

=item B<brik_class>

=item B<brik_classes>

=item B<brik_commands>

=item B<brik_license>

=item B<brik_name>

=item B<brik_tags>

=item B<brik_version>

=item B<brik_base_attributes>

=item B<brik_base_commands>

=item B<brik_check_properties>

=item B<brik_check_require_binaries>

=item B<brik_check_require_modules>

=item B<brik_check_use_properties>

=item B<brik_checks>

=item B<brik_create_attributes>

=item B<brik_has_attribute>

=item B<brik_has_binary>

=item B<brik_has_command>

=item B<brik_has_module>

=item B<brik_has_tag>

=item B<brik_help_run>

=item B<brik_help_run_directory_not_found>

=item B<brik_help_run_empty_array_arg>

=item B<brik_help_run_file_not_found>

=item B<brik_help_run_must_be_root>

=item B<brik_help_run_invalid_arg>

=item B<brik_help_run_undef_arg>

=item B<brik_help_set_undef_arg>

=item B<brik_help_set>

=item B<brik_inherited_attributes>

=item B<brik_inherited_commands>

=item B<brik_own_attributes>

=item B<brik_own_commands>

=item B<brik_repository>

=item B<brik_set_default_attributes>

=item B<brik_set_use_default_attributes>

=item B<brik_fini>

=back

=head1 SEE ALSO

L<Metabrik>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
