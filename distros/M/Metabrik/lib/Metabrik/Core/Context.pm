#
# $Id$
#
package Metabrik::Core::Context;
use strict;
use warnings;

# Breaking.Feature.Fix
our $VERSION = '1.41';
our $FIX = '0';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(main core) ],
      attributes => {
         _lp => [ qw(INTERNAL) ],
      },
      commands => {
         new_brik_run => [ qw(Brik Command Args) ],
         use => [ qw(Brik) ],
         set => [ qw(Brik Attribute Value) ],
         get => [ qw(Brik Attribute) ],
         run => [ qw(Brik Command) ],
         do => [ qw(Code) ],
         call => [ qw(Code) ],
         variables => [ ],
         find_available => [ ],
         update_available => [ ],
         available => [ ],
         is_available => [ qw(Brik) ],
         used => [ ],
         get_used => [ qw(Brik) ],
         is_used => [ qw(Brik) ],
         not_used => [ ],
         is_not_used => [ qw(Brik) ],
         status => [ ],
         reuse => [ ],
         save_state => [ qw(Brik) ],
         restore_state => [ qw(Brik) ],
      },
      require_modules => {
         'Data::Dump' => [ qw(dump) ],
         'File::Find' => [ ],
         'Lexical::Persistence' => [ ],
         'Module::Reload' => [ ],
         'Metabrik::Core::Global' => [ ],
         'Metabrik::Core::Log' => [ ],
         'Metabrik::Core::Shell' => [ ],
      },
   };
}

# Only used to avoid compile-time errors
my $CON;
my $SHE;
my $LOG;
my $GLO;

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   eval {
      my $lp = Lexical::Persistence->new;
      $lp->set_context(_ => {
         '$CON' => 'undef',
         '$SHE' => 'undef',
         '$LOG' => 'undef',
         '$GLO' => 'undef',
         '$USE' => 'undef',
         '$SET' => 'undef',
         '$GET' => 'undef',
         '$RUN' => 'undef',
         '$ERR' => 'undef',
         '$MSG' => 'undef',
         '$REF' => 'undef',
      });
      $lp->call(sub {
         my %args = @_;

         $CON = $args{self};

         $CON->{used} = {
            'core::context' => $CON,
            'core::global' => Metabrik::Core::Global->new,
            'core::log' => Metabrik::Core::Log->new,
            'core::shell' => Metabrik::Core::Shell->new,
         };
         $CON->{available} = { };
         $CON->{set} = { };

         $CON->{log} = $CON->{used}->{'core::log'};
         $CON->{global} = $CON->{used}->{'core::global'};
         $CON->{shell} = $CON->{used}->{'core::shell'};
         $CON->{context} = $CON->{used}->{'core::context'};

         $SHE = $CON->{shell};
         $LOG = $CON->{log};
         $GLO = $CON->{global};

         # When new() was done, some Attributes were empty. We fix that here.
         for (qw(core::context core::global core::shell core::log)) {
            $CON->{used}->{$_}->{context} = $CON;
            $CON->{used}->{$_}->{log} = $CON->{log};
            $CON->{used}->{$_}->{global} = $CON->{global};
            $CON->{used}->{$_}->{shell} = $CON->{shell};
         }

         my $ERR = 0;

         return 1;
      }, self => $self);
      $self->_lp($lp);
   };
   if ($@) {
      chomp($@);
      die("[F] core::context: new: unable to create context: $@\n");
   }

   return $self->brik_preinit;
}

sub new_brik_run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   my $con = Metabrik::Core::Context->new or return;
   # We have to init because some Briks like brik::tool will search context information
   # like available Briks, for instance.
   $con->brik_init or return;

   $con->use($brik) or return;
   my $data = $con->run($brik, $command, @args) or return;
   $con->brik_fini;

   # Compatibility with file::dump Brik
   print Data::Dump::dump($data)."\n";

   return $con;
}

sub brik_init {
   my $self = shift;

   my $r = $self->update_available;
   if (! defined($r)) {
      return $self->log->error("brik_init: unable to init Brik [core::context]: ".
         "update_available failed"
      );
   }

   return $self->SUPER::brik_init(@_);
}

sub do {
   my $self = shift;
   my ($code) = @_;

   if (! defined($code)) {
      return $self->log->error($self->brik_help_run('do'));
   }

   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->do($code);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("do: $@");
   }

   $self->log->debug("do: returned[".(defined($res) ? $res : 'undef')."]");

   return defined($res) ? $res : 'undef';
}

sub call {
   my $self = shift;
   my ($subref, %args) = @_;

   if (! defined($subref)) {
      return $self->log->error($self->brik_help_run('call'));
   }

   my $lp = $self->_lp;

   my $res;
   eval {
      $res = $lp->call($subref, %args);
   };
   if ($@) {
      chomp($@);
      my @list = caller();
      my $file = $list[1];
      my $line = $list[2];
      if ($self->log->level > 2) {
         return $self->log->debug("call: $@ (source file [$file] at line [$line])");
      }
      return $self->log->error("call: $@");
   }

   return $res;
}

sub variables {
   my $self = shift;

   my $res = $self->call(sub {
      my @__ctx_variables = ();

      for my $__ctx_variable (keys %{$CON->_lp->{context}->{_}}) {
         next if $__ctx_variable !~ /^\$/;
         next if $__ctx_variable =~ /^\$_/;

         push @__ctx_variables, $__ctx_variable;
      }

      return \@__ctx_variables;
   });

   return $res;
}

# Extracted from file::find Brik
sub _file_find {
   my $self = shift;
   my ($path_list) = @_;

   # With these patterns, we include baseclass Briks like Metabrik/Baseclass.pm
   my $dirpattern = 'Metabrik';
   my $filepattern = '.pm$';

   # Escape if we are searching for a directory hierarchy
   $dirpattern =~ s/\//\\\//g;

   my $dir_regex = qr/$dirpattern/;
   my $file_regex = qr/$filepattern/;
   my $dot_regex = qr/^\.$/;
   my $dot2_regex = qr/^\.\.$/;

   my @files = ();

   my $sub = sub {
      my $dir = $File::Find::dir;
      my $file = $_;
      # Skip dot and double dot directories
      if ($file =~ $dot_regex || $file =~ $dot2_regex) {
      }
      elsif ($dir =~ $dir_regex && $file =~ $file_regex) {
         push @files, "$dir/$file";
      }
   };

   {
      no warnings;
      File::Find::find($sub, @$path_list);
   };

   my %uniq_files = map { $_ => 1 } @files;
   @files = map { s/^\.\///; $_ } @files;  # Remove leading dot slash
   @files = sort { $a cmp $b } keys %uniq_files;

   return \@files;
}

sub find_available {
   my $self = shift;

   # Read from @INC, exclude current directory
   my @path_list = ();
   for (@INC) {
      next if /^\.$/;
      push @path_list, $_;
   }

   my $found = $self->_file_find(\@path_list);

   my %available = ();
   for my $this (@$found) {
      my $brik = $this;
      $brik =~ s{/}{::}g;
      $brik =~ s/^.*::Metabrik::(.*?)$/$1/;
      $brik =~ s/.pm$//;
      if (length($brik)) {
         my $module = "Metabrik::$brik";
         $brik = lc($brik);
         $available{$brik} = $module;
      }
   }

   return \%available;
}

sub update_available {
   my $self = shift;

   my $h = $self->find_available;

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_available = $args{available};

      for my $__ctx_this (keys %$__ctx_available) {
         eval("require ".$__ctx_available->{$__ctx_this});
      }

      return $CON->{available} = $args{available};
   }, available => $h);

   return $r;
}

sub use {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('use'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};

      my $ERR = 0;
      my $USE = 'undef';

      my $__ctx_brik_repository = '';
      my $__ctx_brik_category = '';
      my $__ctx_brik_module = '';

      if ($__ctx_brik =~ /^[a-z0-9]+::[a-z0-9]+$/) {
         ($__ctx_brik_category, $__ctx_brik_module) = split('::', $__ctx_brik);
      }
      elsif ($__ctx_brik =~ /^[a-z0-9]+::[a-z0-9]+::[a-z0-9]+$/) {
         ($__ctx_brik_repository, $__ctx_brik_category, $__ctx_brik_module) = split('::', $__ctx_brik);
      }
      else {
         $ERR = 1;
         my $MSG = "use: invalid format for Brik [$__ctx_brik]";
         die("$MSG\n");
      }

      $CON->log->debug("repository[$__ctx_brik_repository]");
      $CON->log->debug("category[$__ctx_brik_category]");
      $CON->log->debug("module[$__ctx_brik_module]");

      $__ctx_brik_repository = ucfirst($__ctx_brik_repository);
      $__ctx_brik_category = ucfirst($__ctx_brik_category);
      $__ctx_brik_module = ucfirst($__ctx_brik_module);

      my $__ctx_module = 'Metabrik::'.(length($__ctx_brik_repository)
         ? $__ctx_brik_repository.'::'
         : '').$__ctx_brik_category.'::'.$__ctx_brik_module;

      $CON->log->debug("module2[$__ctx_brik_module]");

      if ($CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "use: Brik [$__ctx_brik] already used";
         die("$MSG\n");
      }

      eval("require $__ctx_module;");
      if ($@) {
         chomp($@);
         $ERR = 1;
         my $MSG = "use: unable to use Brik [$__ctx_brik]: $@";
         die("$MSG\n");
      }

      $USE = $__ctx_brik;

      my $__ctx_new = $__ctx_module->new(
         context => $CON,
         global => $CON->{global},
         shell => $CON->{shell},
         log => $CON->{log},
      );
      #$__ctx_new->brik_init; # No init now. We wait first run() to let set() actions
      if (! defined($__ctx_new)) {
         $ERR = 1;
         my $MSG = "use: unable to use Brik [$__ctx_brik]";
         die("$MSG\n");
      }

      return $CON->{used}->{$__ctx_brik} = $__ctx_new;
   }, brik => $brik);

   return $r;
}

sub reuse {
   my $self = shift;

   my %stat = ();
   my @reloaded = ();
   # Taken from Module::Reload
   for my $entry (map { [ $_, $INC{$_} ] } keys %INC) {
      my ($module, $file) = @$entry;

      # Some entries don't have a file (XS related)
      next unless defined($file);

      if ($file eq $INC{"Module/Reload.pm"}) {
         next;   # Too confusing
      }

      local $^W = 0;  # Disable 'use warnings';
      my $mtime = (stat $file)[9];
      if (! defined($stat{$file})) {
         $stat{$file} = $^T;
      }

      next unless defined($mtime);

      if ($mtime > $stat{$file}) {
         delete $INC{$module};
         eval { 
            $SIG{__WARN__} = sub {};
            require $module;
         };
         if ($@) {
            chomp($@);
            if ($self->log->level > 2) {
               $self->log->debug("reuse: reloading module [$module] failed: [$@]");
            }
            else {
               $self->log->error("reuse: reloading module [$module] failed");
            }
         }
         else {
            push @reloaded, $module;
         }
      }
      $stat{$file} = $mtime;
   }

   for (@reloaded) {
      $self->log->info("reuse: module [$_] successfully reloaded");
   }

   return 1;
}

sub available {
   my $self = shift;

   my $r = $self->call(sub {
      return $CON->{available};
   });

   return $r;
}

sub is_available {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('is_available'));
   }

   my $available = $self->available;
   if (exists($available->{$brik})) {
      return 1;
   }

   return 0;
}

sub used {
   my $self = shift;

   my $r = $self->call(sub {
      return $CON->{used};
   });

   return $r;
}

sub get_used {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('get_used'));
   }

   my $used = $self->used;

   my $get = $used->{$brik};
   if (! defined($get)) {
      return $self->log->error("get_used: Brik [$brik] not used");
   }

   return $get;
}

sub is_used {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('is_used'));
   }

   my $used = $self->used;
   if (exists($used->{$brik})) {
      return 1;
   }

   return 0;
}

sub not_used {
   my $self = shift;

   my $status = $self->status;

   my $r = {};
   my @not_used = @{$status->{not_used}};
   for my $this (@not_used) {
      my @toks = split('::', $this);

      my $repository = '';
      my $category = '';
      my $name = '';

      # Only baseclass Brik is considered
      if (@toks == 1) {
         $category = $this;
      }
      # No repository defined
      elsif (@toks == 2) {
         ($category, $name) = $this =~ /^(.*?)::(.*)/;
      }
      elsif (@toks > 2) {
         ($repository, $category, $name) = $this =~ /^(.*?)::(.*?)::(.*)/;
      }

      my $class = 'Metabrik::';
      if (length($repository)) {
         $class .= ucfirst($repository).'::';
      }
      $class .= ucfirst($category).'::';
      $class .= ucfirst($name);

      $class =~ s{::$}{};

      $r->{$this} = $class;
   }

   return $r;
}

sub is_not_used {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('is_not_used'));
   }

   my $used = $self->not_used;
   if (exists($used->{$brik})) {
      return 1;
   }

   return 0;
}

sub status {
   my $self = shift;

   my $available = $self->available;
   my $used = $self->used;

   my @used = ();
   my @not_used = ();

   for my $k (sort { $a cmp $b } keys %$available) {
      exists($used->{$k}) ? push @used, $k : push @not_used, $k;
   }

   return {
      used => \@used,
      not_used => \@not_used,
   };
}

sub set {
   my $self = shift;
   my ($brik, $attribute, $value) = @_;

   if (! defined($brik) || ! defined($attribute) || ! defined($value)) {
      return $self->log->error($self->brik_help_run('set'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_attribute = $args{attribute};
      my $__ctx_value = $args{value};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "set: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CON->used->{$__ctx_brik}->brik_has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "set: Brik [$__ctx_brik] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      # Support variable lookups like '$array' as an Argument
      # Example: set <Brik> <Attribute> $Arg
      if ($__ctx_value =~ /^\$\w+/ || $__ctx_value =~ /^\@\$\w+/
      ||  $__ctx_value =~ /^\@\w+/ || $__ctx_value =~ /^\%\$\w+/
      ||  $__ctx_value =~ /^\%\w+/) {
         eval {
            $__ctx_value = $CON->_lp->do($__ctx_value);
         };
         if ($@) {
            chomp($@);
            $ERR = 1;
            my $MSG = "set: Brik [$__ctx_brik] has invalid Argument [$__ctx_value]";
            die("$MSG\n");
         }
      }
      # Support passing ARRAYs or HASHs or Perl code as an Argument
      # Example: set <Brik> <Attribute> "[ qw(a b c) ]"
      elsif ($__ctx_value =~ /^\[.*\]$/ || $__ctx_value =~ /^\{.*\}$/) {
         eval {
            $__ctx_value = $CON->_lp->do($__ctx_value);
         };
         if ($@) {
            chomp($@);
            $ERR = 1;
            my $MSG = "set: Brik [$__ctx_brik] has invalid Argument [$__ctx_value]";
            die("$MSG\n");
         }
      }

      $CON->{used}->{$__ctx_brik}->$__ctx_attribute($__ctx_value);

      my $SET = $CON->{set}->{$__ctx_brik}->{$__ctx_attribute} = $__ctx_value;

      my $REF = \$SET;

      return $SET;
   }, brik => $brik, attribute => $attribute, value => $value);

   return $r;
}

sub get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   if (! defined($brik) || ! defined($attribute)) {
      return $self->log->error($self->brik_help_run('get'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_attribute = $args{attribute};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "get: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CON->used->{$__ctx_brik}->brik_has_attribute($__ctx_attribute)) {
         $ERR = 1;
         my $MSG = "get: Brik [$__ctx_brik] has no Attribute [$__ctx_attribute]";
         die("$MSG\n");
      }

      if (! defined($CON->{used}->{$__ctx_brik}->$__ctx_attribute)) {
         return my $GET = 'undef';
      }

      my $GET = $CON->{used}->{$__ctx_brik}->$__ctx_attribute;

      my $REF = \$GET;

      return $GET;
   }, brik => $brik, attribute => $attribute);

   return $r;
}

sub run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   if (! defined($brik) || ! defined($command)) {
      return $self->log->error($self->brik_help_run('run'));
   }

   if ($self->log->level > 2) {
      my ($module, $file, $line) = caller();
      $self->log->debug("run: called by module [$module] from [$file] line[$line]");
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};
      my $__ctx_command = $args{command};
      my @__ctx_args = @{$args{args}};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "run: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      if (! $CON->used->{$__ctx_brik}->brik_has_command($__ctx_command)) {
         $ERR = 1;
         my $MSG = "run: Brik [$__ctx_brik] has no Command [$__ctx_command]";
         die("$MSG\n");
      }

      my $__ctx_run = $CON->{used}->{$__ctx_brik};

      # Will brik_init() only if not already done
      # And only for Brik's Commands, not base class Commands
      if (! $__ctx_run->init_done && $__ctx_command !~ /^brik_/) {
         if (! $__ctx_run->brik_init) {
            $ERR = 1;
            my $MSG = "run: Brik [$__ctx_brik] init failed";
            die("$MSG\n");
         }
      }

      for (@__ctx_args) {
         # Support variable lookups like '$array' as an Argument
         # Example: run <Brik> <Command> $Arg1 Arg2
         if (/^\$\w+/ || /^\@\$\w+/ || /^\@\w+/ || /^\%\$\w+/ || /^\%\w+/) {
            eval {
               $_ = $CON->_lp->do($_);
            };
            if ($@) {
               chomp($@);
               $ERR = 1;
               my $MSG = "run: Brik [$__ctx_brik] has invalid Argument [$_]";
               die("$MSG\n");
            }
         }
         # Support passing ARRAYs or HASHs or Perl code as an Argument
         # Example: run <Brik> <Command> "[ qw(a b c) ]"
         elsif (/^\[.*\]$/ || /^\{.*\}$/) {
            eval {
               $_ = $CON->_lp->do($_);
            };
            if ($@) {
               chomp($@);
               $ERR = 1;
               my $MSG = "run: Brik [$__ctx_brik] has invalid Argument [$_]";
               die("$MSG\n");
            }
         }
      }

      my $RUN;
      my $__ctx_return = $__ctx_run->$__ctx_command(@__ctx_args);
      if (! defined($__ctx_return)) {
         $ERR = 1;
         return;
      }

      $RUN = $__ctx_return;

      my $REF = \$RUN;

      return $RUN;
   }, brik => $brik, command => $command, args => \@args);

   return $r;
}

sub save_state {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('save_state'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "save_state: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      my $__ctx_state;
      my $__ctx_attributes = $CON->{used}->{$__ctx_brik}->brik_attributes || {};
      for my $__ctx_this (keys %$__ctx_attributes) {
         $__ctx_state->{$__ctx_this} = $CON->{used}->{$__ctx_brik}->$__ctx_this;
      }
      $CON->{used}->{$__ctx_brik}->{"__ctx_state"} = $__ctx_state;

      return 1;
   }, brik => $brik);

   return $r;
}

sub restore_state {
   my $self = shift;
   my ($brik) = @_;

   if (! defined($brik)) {
      return $self->log->error($self->brik_help_run('restore_state'));
   }

   my $r = $self->call(sub {
      my %args = @_;

      my $__ctx_brik = $args{brik};

      my $ERR = 0;

      if (! $CON->is_used($__ctx_brik)) {
         $ERR = 1;
         my $MSG = "restore_state: Brik [$__ctx_brik] not used";
         die("$MSG\n");
      }

      my $__ctx_state = $CON->{used}->{$__ctx_brik}->{"__ctx_state"};
      if (defined($__ctx_state)) {
         for my $__ctx_this (keys %$__ctx_state) {
            $CON->{used}->{$__ctx_brik}->$__ctx_this($__ctx_state->{$__ctx_this});
         }
      }

      return 1;
   }, brik => $brik);

   return $r;
}

sub brik_fini {
   my $self = shift;

   my $used = $self->used;
   for my $brik (keys %$used) {
      next if $brik eq 'core::context'; # Avoid recursive loop
      $used->{$brik}->brik_fini;
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Core::Context - core::context Brik

=head1 SYNOPSIS

   # From a Perl program
   use Metabrik::Core::Context;   

   my $con = Metabrik::Core::Context->new or die("core::context");

   # Or from a shell, to call a Command with a one-liner
   perl -MMetabrik::Core::Context -e 'Metabrik::Core::Context->new_brik_run( \
      "brik::tool", "install", "lookup::iplocation")'

=head1 DESCRIPTION

This Brik keeps track of everything that happens within B<Metabrik>. That includes persistence of Perl variables and loaded Briks along with their set Attributes for instance.

This is the only Brik that is mandatory to B<use> when writing a Tool, and it will auto-load B<core::log>, B<core::global> and B<core::shell> for you. When these Briks are loaded from B<core::context>, some global variables are set as pointers to them: B<$CON>, B<$GLO>, B<$LOG>, and B<$SHE> to point to respectively B<core::context>, B<core::global>, B<core::log> and B<core::shell> Briks.

=head1 ATTRIBUTES

At B<The Metabrik Shell>, just type:

L<get core::context>

=head1 COMMANDS

At B<The Metabrik Shell>, just type:

L<help core::context>

=head1 METHODS

=over 4

=item B<brik_properties>

=item B<new>

=item B<new_brik_run>

=item B<brik_init>

=item B<available>

=item B<call>

=item B<do>

=item B<find_available>

=item B<get>

=item B<get_used>

=item B<is_available>

=item B<is_not_used>

=item B<is_used>

=item B<log>

=item B<not_used>

=item B<restore_state>

=item B<reuse>

=item B<run>

=item B<save_state>

=item B<set>

=item B<status>

=item B<update_available>

=item B<use>

=item B<used>

=item B<variables>

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
