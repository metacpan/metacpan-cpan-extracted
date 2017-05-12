package Decl::Semantics::Macro;

use warnings;
use strict;

use base qw(Decl::Node);
use Data::Dumper;

=head1 NAME

Decl::Semantics::Macro - defines or instantiates a macro.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

The C<Decl> macro facility is still pretty green; it will probably go through a few iterations before I really like it.

This initial implementation provides three tags: "define" defines a named macro that can then be used anywhere and will instantiate a new
node at build time based on its environment; "express" expresses a macro in situ at runtime; and "<=" defines and instantiates an anonymous
macro in place, also at runtime.  I'm not 100% sure that the build time/runtime distinction will be terribly significant, but more use will
doubtlessly result in some places where it will be a useful one.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.

=cut
sub defines { ('define', 'express', '<=') }
our %build_handlers = ();
sub tags_defined { Decl->new_data(<<EOF); }
define
express
<=
EOF

=head2 build_payload ()

The C<build_payload> function is then called when this object's payload is built.  It handles the three tags separately, plus any defined
tags we've built in the meantime.

=cut
sub build_payload {
   my ($self) = @_;
   
   if ($self->code || $self->bracket) {  # Handle basic code macros.
      Decl::Semantics::Code::build_macro_payload($self);
   }
   $self->build_children();
   if ($self->is('define'))  { $self->build_define;  return; }
   if ($self->is('<='))      { $self->build_inplace; return; }
   if ($self->is('express')) { $self->build_express; return; }
   
   $self->{force_text} = 1;  # We don't want any of our children built; they're treated as text.
   $self->instantiate;
   1;
}

=head2 build_define - defining a macro

Actually, definition of a macro doesn't do a lot.  All the good stuff happens at instantiation.

=cut

sub build_define {
   my ($self) = @_;
   my $macroname = $self->name;
   $self->{instantiated} = 0;
   $self->root()->{macro_definitions}->{$macroname} = $self;
   $self->root()->register_builder (ref ($self), $self->parameter('domain', 'core'), Decl->new_data(<<"   EOF"));
      $macroname
   EOF
}

=head2 instantiate - instantiating a macro once defined

Once a macro is defined, its name is treated just like any other tag.  When this class is called to instantiate it, we build a new
node based on the current environment (that is, whatever variables have already been set, including the parameters on the invocation)
and macro-insert it.  If the inserted result is callable, then the invocation will mark it as a proxy and execute its code on "go", while
the result itself will be unmarked as callable - this ensures that the code will run at the point of the invocation, not at the eventual
place of insertion of the macro result (which is at the end of the list of children of the parent - not the right place to run it).

=cut

sub instantiate {
   my ($self, $definition) = @_;
   $definition = $self->root()->{macro_definitions}->{$self->tag} unless defined $definition;
   return unless $definition;

   $self->{instantiates} = $definition;
   $definition->{callable} = 0;   # A macro, at least once instantiated, cannot be considered for execution.
   
   # First off, let's set all the parameters from the tag line - e.g. mymacro (parm1 = "something")
   # This will make these available to template macros as well as to full-on macros.
   #foreach my $parameter ($self->parmlist) {
   #   $definition->{hashtie}->just_store($parameter, $self->parameter($parameter));
   #}
   
   # There are three varieties of macro: a code macro just runs some Perl and inserts the output; a text macro is a template that is 
   # expressed and that expression is inserted; and a nodal macro does some fancy stuff, of which more below.
   if ($definition->{owncode}) {  # Code macro.
      $definition->{output} = '';
      $definition->go($self);
      $self->parent->macroinsert($definition->{output}, $self);
      return 1;
   }
   
   if ($definition->hasbody) {    # Simple template.
      my $output = $Decl::template_engine->express($definition->{body}, $self);  # Instantiate template in macro definition, using instantiation as the data source.
      $self->parent->macroinsert($output, $self);
      return 1;
   }
   
   # Complex case.  Essentially, we're going to scan down the children, running callable things and treating any output and setup children
   # as templates.  Setup children are only output once.
   foreach ($definition->nodes) {
      if ($_->is ('yield') || $_->is('setup')) {
         next if $_->is('setup') and $definition->{instantiated};
         if ($_->{owncode}) {
            $_->{output} = '';
            $_->go($self);
            $self->parent->macroinsert($_->{output}, $self);
         } elsif ($_->hasbody) {
            my $output = $Decl::template_engine->express($_->{body}, $self);
            $self->parent->macroinsert($output, $self);
         }
      } elsif ($_->is('parameter')) {
         my $parameter = $_->name;
         # Can I find this parameter in the invocation?
         #next if exists $self->{v}->{$parameter};     # If it's a tagline parameter, skip it; we already did this.
         my $value = $self->{parameters}->{$parameter};
         if (not defined $value) {
            if (my $child = $self->first($parameter)) {
               if ($child->label) {
                  $value = $child->label;
               } elsif ($child->{callable} eq 1) {
                  $value = $child->go;
               } else {
                  $value = $child->describe_content;
               }
            }
            # Nope: set the default.  TODO: this code could use some refactorization, couldn't it?
            elsif (defined $_->label) {
               $value = $_->label;
            } elsif ($_->{callable} eq 1) {
               $value = $_->go;
            } else {
               $value = $child->describe_content;
            }
         }
         $definition->{hashtie}->just_store($parameter, $value);
      } else {
         my $return = $_->go ($self, @_);
      }
   }

   $definition->{instantiated} = 1;  # Shut off further output of "setup" children.
}

=head2 build_inplace - defining and instantiating a macro at the same time

In-place instantiation of a "here" macro allows code to be written that expresses a macro expansion at build time.

=cut

sub build_inplace {
   my ($self) = @_;
   $self->instantiate($self);
   1;
}

=head2 build_express: instantiating a macro at runtime, *or* expressing a template, depending on what the expressed thing is.




=head2 output, iterate

The C<output> function usually diverts to writing, but for macro instantiation it is the input to creating our expression.
So we collect it.  At the end of the instantiation, we'll evaluate it.

The C<iterate> function (normal output) is disabled for macro calls; the instantiation should do this work.

=cut

sub output { $_[0]->{output} .= $_[1] }
sub iterate { }

=head2 go

The C<go> function overrides the usual running function of nodes because we're either acting as a proxy for our macro results, or we're going
to instantiate at runtime.

=cut

sub go {
   my $self = shift;
   my $instance = shift;
   my $return;

   #return unless $self->{callable};           - Note that this is specifically disabled for macro definitions.
   if ($self->{owncode} && $self->{sub}) {
      $return = &{$self->{sub}}($instance, @_);
   } else {
      foreach ($self->nodes) {
         $return = $_->go ($instance, @_);
      }
   }
   return $return;
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

1; # End of Decl::Semantics::Macro
