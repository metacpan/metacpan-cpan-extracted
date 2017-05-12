package Devel::Command;
use strict;
use warnings;
use Data::Dumper;

use Module::Pluggable search_path=>["Devel::Command"], require=>1;
use Module::Pluggable search_path=>['Devel::Command::DBSub'], 
                      sub_name => 'DB_subs';

our $VERSION = '0.11';

sub import {
  # Find and install all the plugins.
  # Uncomment the following line to verify plugin/patch loading in the debugger.
  # $DB::single=1;
  my @plugins = __PACKAGE__->plugins;
  foreach my $plugin (@plugins) {
    # Skip patch plugins.
    next if $plugin =~ /^Devel::Command::DBSub/;

    # get the signature(s) (name, entry point).
    my(@signatures) = $plugin->signature();

    # Install the command(s) in our lookup table.
    while (@signatures) {
      my $cmd_name = shift @signatures;
      my $cmd_ref  = shift @signatures;
      $DB::commands{$cmd_name} = $cmd_ref;
    }

    # Export our eval into the plugin.
    {
      no  strict 'refs';
      *{$plugin."::eval"} = \&eval;
    }
  }

  # Add our local 'cmds' command to the table.
  $DB::commands{"cmds"} = \&cmds;

  # Install the alternate version of DB::DB.  
  {
    no warnings 'redefine';
    my $patch;
    print STDERR map {"# $_"} Dumper(__PACKAGE__->DB_subs());
    foreach my $DB_module (__PACKAGE__->DB_subs) {
      my $subref;
      warn "# Trying " .Dumper($DB_module);
      if ($subref = $DB_module->import()) {
        # This module could work for the current Perl.
        $patch = [$subref, $DB_module];
      }
    }
    if (! defined $patch) {
      die "Your Perl can't be patched by Devel::Command (yours is Perl $])\n";
    }
    else {
      print "Patching with ", $patch->[1], "\n";
        *DB::DB = $patch->[0];
    }
  }
}

sub cmds {
  for my $key (keys %DB::commands) {
    print DB::OUT $key,"\n";
  }
  1;
}

sub DB::afterinit {
  my @plugins = __PACKAGE__->plugins;
  foreach my $plugin (@plugins) {
    $plugin->afterinit if $plugin->can('afterinit');
  }
}

sub eval {
  my  $arg = shift;
  $DB::evalarg = $arg;
  DB::eval();
}

sub signature {
  my $class = shift;
  # Generate a command name based on the name
  # of this plugin (the final qualifier),
  # lowercased. Assumes that the actual
  # code to execute the command is in a 
  # sub named 'command' in that package.
  (lc(substr($class,rindex($class,'::')+2)), 
   eval "\\&".$class."::command");
}

1;
__END__

=head1 NAME

Devel::Command - Perl extension to automatically load and register debugger command extensions

=head1 SYNOPSIS

  # in .perldb:
  use Devel::Command;
  sub afterinit {
     Devel::Command->install;
  }

=head1 DESCRIPTION

C<Devel::Command> provides a simple means to extend the Perl debugger with
custom commands. It uses C<Module::Pluggable> to locate the command modules,
and installs these into a debugger global (C<%DB::commands>).

It then searches the C<Devel::Command::DBSub> namespace to locate an
appropriate debugger patch plugin and installs it to enable the new commands.

=head1 ROUTINES

=head2 import

C<import> finds all of the command plugins for this package
(i.e., any module in the C<Devel::Command::> namespace),
calls the module's C<signature> method to get the name of
the command and its entry point, and then exports our
C<eval> subroutine into the command's namespace.

Finally, it overrides the debugger's C<DB::DB()>
subroutine with the proper patched version of that routine
by calling the C<import()> routine in each of the C<DB>
plugins in ascending version order; the last one that returns a subroutine 
reference is used.

=head2 cmds

A new debugger command to list the commands
installed by C<Devel::Command>.

=head2 afterinit

Does any necessary initialization for a 
debugger command module. Gets run after the
debugger has initialized, but before the
initial prompt. Calls the C<afterinit> subroutine 
in each command plugin's namespace.

=head1 EXPORTED INTO PLUGINS

=head2 eval

This routine is explicitly exported into the 
plugins so that they can call the debugger's
C<eval> routinei without having to fiddle with
the bizarre calling sequence used by the debugger. 

=head1 INHERITED BY SUBCLASSES

=head2 signature

The C<signature> method is common to all subclasses
and is needed to handle the interfacing to this
module. The default method (this one) returns a best-guess
name for the command (by downcasing the last qualifier of the
fully-qualified package name) and a reference to the 
C<command()> subroutine in the command package itself.

Note that subclasses are free to override this method
and do anything they please as long as the overrding method
returns a command name and a subroutine reference to the
code to be used to perform the command.

=head1 SEE ALSO

C<perl5db.pl>, notably the documentation for the C<DB::DB> subroutine
in more recent Perls (5.8.1 and later).

=head1 AUTHOR

Joe McMahon, E<lt>mcmahon@ibiblio.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Joe McMahon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

