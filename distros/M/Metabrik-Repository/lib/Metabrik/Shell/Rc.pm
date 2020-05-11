#
# $Id$
#
# shell::rc Brik
#
package Metabrik::Shell::Rc;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(custom) ],
      attributes => {
         input => [ qw(file) ],
         create_default => [ qw(0|1) ],
      },
      attributes_default => {
         create_default => 1,
      },
      commands => {
         load => [ qw(input|OPTIONAL) ],
         execute => [ qw($line_list) ],
         write_default => [ ],
         load_and_execute => [ qw(input|OPTIONAL) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         input => defined($self->global) && $self->global->homedir.'/.metabrik_rc'
            || defined($ENV{HOME}) && $ENV{HOME}.'/.metabrik_rc' || '/tmp/.metabrik_rc',
      },
   };
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;

   if (! -f $input && $self->create_default) {
      $self->write_default;
   }

   if (! -f $input && ! $self->create_default) {
      return $self->log->error("load: can't find rc file [$input]");
   }

   my @lines = ();
   open(my $in, '<', $input)
      or return $self->log->error("local: can't open rc file [$input]: $!");
   while (defined(my $line = <$in>)) {
      chomp($line);
      next if $line =~ /^\s*$/;   # Skip blank lines
      next if $line =~ /^\s*#/;   # Skip comments
      $line =~ s/^(.*)#.*$/$1/;   # Strip comments at end of line
      push @lines, "$line ";      # Add a trailing slash in case of a multiline
                                  # So when joining them, there is no unwanted concatenation
   }
   close($in);

   $self->log->debug("load: success");

   return \@lines;
}

sub execute {
   my $self = shift;
   my ($lines) = @_;

   if (! defined($self->shell)) {
      return $self->log->error("execute: no core::shell Brik");
   }

   $self->brik_help_run_undef_arg('execute', $lines) or return;
   $self->brik_help_run_invalid_arg('execute', $lines, 'ARRAY') or return;

   my $shell = $self->shell;

   $shell->cmdloop($lines);

   return 1;
}

sub write_default {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->input;

   if (-f $file) {
      return $self->log->error("write_default: file [$file] already exists");
   }

   open(my $out, '>', $file)
      or return $self->log->error("write_default: open: file [$file]: $!");

   my $content = <<EOF;
set core::shell echo 0

my \$home = \$ENV{HOME}
my \$user = \$ENV{USER}

set core::global ctimeout 5
set core::global rtimeout 5
set core::shell ps1 Meta
set core::log level 1

use shell::command
use shell::history
use brik::tool
use brik::search

alias reuse "run core::context reuse"
alias pwd "run core::shell pwd"
alias update_available "run core::context update_available"
alias reuse "run core::context reuse"
alias system "run shell::command system"
alias capture "run shell::command capture"
alias ls "run shell::command capture ls -Fh"
alias l "run shell::command capture ls -lFh"
alias ll "run shell::command capture ls -lFh"
alias cp "run shell::command capture cp -rfp"
alias rm "run shell::command capture rm -rf"
alias find "run shell::command capture find"
alias grep "run shell::command capture grep"
alias ! "run shell::history exec"
alias history "run shell::history show"
alias source "run shell::rc load_and_execute"
alias search "run brik::search"
alias show "run brik::search all"

run shell::history load

set core::shell echo 1
EOF

   print $out $content;

   close($out);

   $self->log->verbose("write_default: default rc file [$file] created");

   return 1;
}

sub load_and_execute {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;

   my $lines = $self->load($input) or return;
   return $self->execute($lines);
}

1;

__END__

=head1 NAME

Metabrik::Shell::Rc - shell::rc Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
