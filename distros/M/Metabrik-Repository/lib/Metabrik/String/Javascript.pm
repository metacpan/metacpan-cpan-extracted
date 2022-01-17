#
# $Id$
#
# string::javascript Brik
#
package Metabrik::String::Javascript;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         eval => [ qw(js_code) ],
         deobfuscate => [ qw(js_code) ],
      },
      require_modules => {
         'JavaScript::V8' => [ ],
         'JavaScript::Beautifier' => [ qw(js_beautify) ],
      },
      need_packages => {
         ubuntu => [ qw(libv8-dev) ],
         debian => [ qw(libv8-dev) ],
         kali => [ qw(libv8-dev) ],
      },
   };
}

sub eval {
   my $self = shift;
   my ($js) = @_;

   $self->brik_help_run_undef_arg('eval', $js) or return;

   $@ = undef;

   my $context = JavaScript::V8::Context->new;
   if (defined($@) && ! defined($context)) {
      chomp($@);
      return $self->log->error("eval: cannot init V8 context: $@");
   }

   my $r = $context->eval($js);
   if (defined($@) && ! defined($r)) {
      chomp($@);
      return $self->log->error("eval: cannot eval JS: $@");
   }

   return $r;
}

sub deobfuscate {
   my $self = shift;
   my ($js) = @_;

   $self->brik_help_run_undef_arg('deobfuscate', $js) or return;

   $@ = undef;

   my $context = JavaScript::V8::Context->new;
   if (defined($@) && ! defined($context)) {
      chomp($@);
      return $self->log->error("deobfuscate: cannot init V8 context: $@");
   }

   my $buf = '';
   $context->bind_function(eval => sub { $buf .= join(' ', @_); });
   $context->bind_function(alert => sub { $buf .= join(' ', @_); });
   $context->bind_function(ActiveXObject => sub { $buf .= join(' ', @_); });
   $context->bind_function(WScript => sub { $buf .= join(' ', @_); });
   # Google V8 has no XMLHttpRequest nor network related functions.
   # We should replace it by NodeJS at some point.
   $context->bind_function(XMLHttpRequest => sub { $buf .= join(' ', @_); });

   my $r = $context->eval($js);
   if (defined($@) && ! defined($r)) {
      chomp($@);
      return $self->log->error("deobfuscate: cannot eval JS: $@");
   }

   my $b = JavaScript::Beautifier::js_beautify($buf, {
      indent_size => 2,
      indent_character => ' ',
   });

   return $b;
}

1;

__END__

=head1 NAME

Metabrik::String::Javascript - string::javascript Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
