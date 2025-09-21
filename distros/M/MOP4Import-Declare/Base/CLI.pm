#!/usr/bin/env perl
package MOP4Import::Base::CLI;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro qw/c3/;

use File::Basename ();
use Data::Dumper ();

use attributes ();

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

use Module::Runtime ();

use MOP4Import::Base::Configure -as_base, qw/FieldSpec/;

#========================================

*run = *cli_run; *run = *cli_run;

sub cli_run :method {
  my ($class, $arglist, $opt_alias) = @_;

  {
    my $modFn = Module::Runtime::module_notional_filename($class);
    $INC{$modFn} //= 1;
  }

  my MY $self = $class->new($class->cli_parse_opts($arglist, undef, $opt_alias));

  unless (@$arglist) {
    # Invoke help command if no arguments are given.
    $self->cmd_help;
    return;
  }

  my $cmd = shift @$arglist;
  if (my $sub = $self->can("cmd_$cmd")) {
    # Invoke official command.

    $self->cli_precmd($cmd);

    $sub->($self, @$arglist);

  } elsif ($self->can($cmd)) {
    # Invoke unofficial internal methods. Development aid.

    $self->cli_invoke($cmd, @$arglist);

  } else {
    # Last resort. You can implement your own subcommand interpretations here.

    $self->cli_unknown_subcommand($cmd, $arglist);
  }
}

#========================================
# Hooks and default implementations
#========================================

#
# Each class can override parse_opts method.
#
*parse_opts = *cli_parse_opts; *parse_opts = *cli_parse_opts;
sub cli_parse_opts :method {
  my ($pack, $list, $result, $opt_alias) = @_;

  MOP4Import::Util::parse_opts($pack, $list, $result, $opt_alias);
}

sub cli_precmd :method {} # hook called just before cmd_zzz

sub cli_invoke {
  (my MY $self, my ($method, @args)) = @_;

  $self->cli_precmd($method);

  my @res = $self->$method(@args);
  $self->cli_output(\@res) if @res;

  if ($method =~ /^has_/) {
    # If method name starts with 'has_' and result is empty,
    # exit with 1.
    exit(@res ? 0 : 1);

  } elsif ($method =~ /^is_/) {
    # If method name starts with 'is_' and first result is false,
    # exit with 1.
    exit($res[0] ? 0 : 1);
  }
}

sub cli_output :method {
  (my MY $self, my $res) = @_;
  print join("\n", map {MOP4Import::Util::terse_dump($_)} @$res), "\n";
}

sub cli_unknown_subcommand :method {
  (my MY $self, my ($cmd, $arglist)) = @_;

  $self->cmd_help("Error: No such subcommand '$cmd'\n");
}

#========================================

sub onconfigure_help :method {
  (my MY $self, my $val) = @_;
  $self->cmd_help;
  exit;
}

sub cli_inspector {
  require MOP4Import::Util::Inspector;
  'MOP4Import::Util::Inspector';
}

sub cmd_help :method {
  my $self = shift;
  my $pack = ref $self || $self;

  # Invoke precmd (mainly for binmode handling)
  $self->cli_precmd();

  my @msg = (join("\n", @_, <<END));
Usage: @{[File::Basename::basename($0)]} [--opt=value].. <Command> ARGS...
END

  my $insp = $self->cli_inspector;

  if (my @cmds = $insp->describe_commands_of($self)) {
    push @msg, "\nCommands\n", @cmds;
  }

  if (my @opts = $insp->describe_options_of($self)) {
    push @msg, "\n", @opts;
  }

  die join("", @msg);
}

MY->cli_run(\@ARGV) unless caller;

1;
