package Decl::Semantics::Commandline;

use warnings;
use strict;

use base qw(Decl::Node);
use Getopt::Lucid qw(:all);
use Scalar::Util qw(refaddr);
use Decl::Semantics::Code;
use Data::Dumper;

=head1 NAME

Decl::Semantics::Commandline - implements a command line parser in an event context, using Getopt::Lucid

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

When running any script, the command line provides a first-line configuration and specification mechanism for the action to be taken.
Perl simply provides the usual @ARGV list that C also does (granted, Perl does some of the irritating tasks for you that C doesn't), but
it's up to you to do something sensible with that list.

This module allows you to define a C<command-line> tag that extracts various sorts of parameters from the command line, then takes the
remaining parts of the list and treats it as a command to be executed.

It also provides a command loop (an internal command line) that can be embedded into any program to provide interactive services.  A
default set of commands could be provided as a debugger, for instance.  (TODO: write a default set of commands as a debugger.)

Here's an example:

   command-line argv (loop)
      switch version "version|-V"
      counter verbose "verbose|-v"
      param config (anycase) "config|c"
      list libraries "lib"
      keypair def "define"
      
      command start "start something" {
         # Start something
      }
      command help "get help" {
         # Print a help text
      }
      
      do {
         # Handle unknown commands
      }
      
The top five lines in our specification represent the five types of named command line argument supported.  Anything left on the command line
after all the named parameters have been consumed is treated as a command and passed to the appropriate "on" event.  The search order is the
usual one: if a like-named event isn't found in the command line, the parent node will be searched, and so on up to the root.  If no matching
"on" is found, the arglist is passed to the "do" handler, if there is one.  

If a command is on the command line, it executes only after all parsing is finished; that is, the command is executed as the "start" action
of the program.

If there is no command and "loop" is specified, the start action passes control to a L<Term::Shell> REPL loop using the same event logic.
If "loop=always" is specified, the loop will run even if an initial command is given.  The shell will use the quoted labels of the events as
summary text for the help system; for longer texts, a "help" tag must be given, like this:

   command-line (loop)
      command start "start something"
         help
            The "start" command is used to start something
            and its help text may be multi-line.  It is not
            parsed.
         do { # start something }
         
If no command was found on the command line, and no loop is specified, then the command line will not be marked as callable, so the program
won't call it as its start action and will have to look elsewhere.  If you never want the command line to be the start action, you can
flag it:

   command-line (nocall)
         
Normally, if not used as a command loop, the command line is just treated as a data source by name to permit its values to be queried from
code elsewhere in the program. You can also specify a target data source like this:

   command-line (store=system.argv)
      switch verbose (anycase) "verbose|V"
      
There are four modifiers that can be added to named arguments:

   command-line
      switch parm1 (anycase) "parm1"
      keypair parm2 (required) "parm2"
      switch parm3 (needs=parm4) "parm3"
      param parm4 (valid="\d+") "parm4"
      
The C<anycase> modifier makes the parameter case-insensitive.  The C<required> modifier means that this value must be specified or an error
is raised.  The C<needs> modifier means that if parm3 is specified, then parm4 must also be specified or an error is raised.  Finally, the
C<valid> modifier is a regexp that must be matched or (wait for it ...) an error is raised.

One or more named error handlers may be provided:

   command-line
      keypair parm2 (required, needs=parm3) "parm2"
         on error required {
            print STDERR "You need to specify parm2.\n"
         }
         on error needs {
            print STDERR "You can't specify parm2 without defining parm3.\n";
         }
      param parm3 (valid="\d+") "parm3"
         on error valid {
            print STDERR "parm3 must be numeric\n";
         }
         
You can also provide a more heavy-duty validator:

   command-line
      param configfile "config"
         valid { -r }
         on error valid {
            print STDERR "The configuration file you specified does not exist.\n";
         }
         
Almost all of that is just the semantics of L<Getopt::Lucid>, which really is the end-all and be-all of command line parsing.
         
=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.

=cut
sub defines { ('command-line', 'shell'); }
sub tags_defined { Decl->new_data(<<EOF); }
command-line (body=vanilla)
shell (body=vanilla)
EOF

=head2 post_build

All the work is done in the post_build stage.

=cut

sub post_build {
   my ($self) = @_;
   $self->{callable} = 0;  # Not callable by default.
   $self->{callable} = 1 if $self->parameter('loop');
   $self->{callable} = 1 if $self->is('shell');
   
   if ($self->is('command-line')) {
      my @specs = ();
      foreach my $child ($self->nodes()) {
         my $spec = undef;
         if ($child->is ('switch')) {
            $spec = Switch ($child->label);
         } elsif ($child->is ('counter')) {
            $spec = Counter ($child->label);
         } elsif ($child->is ('list')) {
            $spec = List ($child->label);
         } elsif ($child->is ('param')) {
            $spec = Param ($child->label);
         } elsif ($child->is ('keypair')) {
            $spec = Keypair ($child->label);
         }
         if (defined $spec) {
            $spec->required if $child->parameter('required');
            $spec->anycase  if $child->parameter('anycase');
            $spec->valid($child->parameter('valid')) if $child->parameter('valid');
            $spec->needs($child->parameter('needs')) if $child->parameter('needs');
            my $validator = $child->first('valid');
            if ($validator) {
               Decl::Semantics::Code->build_payload($validator, 0);
               $spec->valid($validator->sub);
            }
            push @specs, $spec;
         }
      }
   
      $self->{payload} = Getopt::Lucid->getopt(\@specs);  # Magic!
   
      if (@ARGV) { # TODO: point it to something other than ARGV at some point.
         # We have a command.  Make ourselves callable.
         $self->{first_command} = join ' ', @ARGV;
         $self->{callable} = 1;
      }
   }
   
   my $shell_pname = "Shell_" . refaddr($self);
   my $shell_package = <<"EOF";
   
package $shell_pname;
use warnings;
use strict;
use base qw(Term::Shell);
sub prompt_str { \$_[0]->{parent}->prompt_str(); }

EOF
   if ($self->parameter('debug')) {
      foreach my $c ('show', 'list', 'goto') {
         foreach my $h ('run', 'smry', 'help') {
            $shell_package .= "sub ${h}_$c { my (\$self, \@args) = \@_; \$self->{parent}->${h}_$c(\@args); }\n";
         }
      }
   }
   
   foreach my $command ($self->nodes('command')) {
      # Add custom commands here.
   }
   
   $shell_package .= "1;\n";
   
   eval $shell_package;
   print STDERR $@ if $@;
   
   $self->{payload} = $shell_pname->new();
   $self->{payload}->{parent} = $self;
   $self->{current_node} = $self->root;
}

=head2 go

Called when the element is run (that is, when the shell is invoked, if any).

=cut

sub go {
   my $self = shift;
   if ($self->{first_command}) {
      $self->{payload}->cmd($self->{first_command});
      $self->{first_command} = '';
      return if $self->parameter('loop') ne 'always';
   }
   $self->{payload}->cmdloop();
}

=head1 THE TERMINAL

The standard shell

=head1 STANDARD COMMANDS

The default command line provides debugging and introspection tools - a REPL - along with whatever commands you define.
Those commands are defined in this section.  They can be disabled for a given command line with (debug=no).

=head2 run_show, smry_show, help_show

The C<show> command shows the text of the current node (pages if necessary).  If you give it one argument (e.g. "show code") it will use the argument to
access the node's hashref and display the results.  If the results are undefined, it will say so.  If they're a scalar, it will print the scalar (through
paging). If they're a ref, it will print the output of Data::Dumper (again through paging).

=cut

sub run_show {
   my ($self, @args) = @_;
   if (not @args) {
      $self->{payload}->page($self->{current_node}->describe(1));
      return;
   }
   if (@args == 1) {
      if ($args[0] eq '-') {
         $self->{payload}->page(join ("\n", grep {defined $self->{current_node}->{$_}} keys(%{$self->{current_node}})) . "\n");
         return;
      }
      my $display = $self->{current_node}->{$args[0]};
      if (not defined $display) {
         $self->{payload}->page("node->{" . $args[0] . "} is not defined\n");
      } elsif (not ref $display) {
         $self->{payload}->page($display . "\n");
      } else {
         $self->{payload}->page(Dumper($display));
      }
      return;
   }
   print "Don't know how to show " . join (' ', @args) . "\n";
}
sub smry_show { "Show the current node" }
sub help_show { <<EOF }
The 'show' command with no argument shows the macro-expanded structure of the current node.  It uses paged output, in case the node is large.
Use 'goto' to select a subnode of the current node.

The 'show -' command shows a list of the hash keys of the node; 'show <key>' shows the contents of a hash key - as text if not a reference, or as
the Data::Dumper output if it is a reference.
EOF

=head2 run_list, smry_list, help_list

The C<list> command lists the text of the current node (pages if necessary).  With a single argument, lists the nodes with that tag.

=cut

sub run_list {
   my ($self, @args) = @_;
   my $return = '';
   foreach ($self->{current_node}->nodes($args[0])) {
      $return .= $_->myline() . "\n";
   }
   $self->{payload}->page($return);
}
sub smry_list { "List the children of the current node" }
sub help_list { <<EOF }
The 'list' command lists the children of the current node, including macro expansions and collapsing groups.
EOF

=head2 run_goto, smry_goto, help_goto

The C<goto> command changes the current node by applying a "find" to the current node and switching the current node if it succeeds.
If you provide neither [] nor (), the command assumes [].

=cut

sub run_goto {
   my ($self, @args) = @_;
   my @loc = split /\//, (join ' ', @args);
   foreach (@loc) {
      s/^ *//;
      s/ *$//;
      if ($_ =~ ' ' and $_ !~ /\[/ and $_ !~ /\(/) {
         s/ /\[/;
         $_ .= ']';
      }
   }
   my $l = join ('/', @loc);
   my $possible = $self->{current_node};
   if ($loc[0] eq '') {
      shift @loc;
      $possible = $possible->root;
   }
   while ($loc[0] =~ /^\.+$/) {
      my $up = shift @loc;
      $possible = $possible->parent if $up eq '..';
   }
   $possible = $possible->find(join '/', @loc) if defined $possible and @loc and $loc[0];
   if (defined($possible)) {
      $self->{current_node} = $possible;
   } else {
      print "Can't find node '$l'.\n";
   }
}
sub smry_goto { "Make a node the current node" }
sub help_goto { <<EOF }
The 'goto' command moves the node cursor by using a path notation.
goto / -> goes to the root node.
goto /node1 -> goes to the first "node1" under the root node.
goto .. -> goes to the current node's parent.
goto node1 -> goes to the first "node1" under the current node.
goto node1 sam -> goes to the first "node1" named sam under the current node.
goto node1[sam] -> same thing.
goto node1(2) -> goes to the third "node1" under the current node.
EOF

=head2 prompt_str()

Returns the current prompt.  TODO: make this overridable from the node definition.

=cut

sub prompt_str {
   my $self = shift;
   my $l = $self->{current_node}->mylocation();
   $l = "*root*" if $l eq '/';
   $l . " > ";
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Semantics::Commandline
