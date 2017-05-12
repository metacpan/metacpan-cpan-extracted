#
# $Id: Mojo.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# devel::mojo Brik
#
package Metabrik::Devel::Mojo;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
      },
      commands => {
         generate_lite_app => [ qw(file_pl) ],
         generate_app => [ qw(MyApp) ],
         morbo => [ qw(file_pl) ],
         inflate => [ qw(file_pl) ],
         get => [ qw(url) ],
         test => [ qw(file_pl) ],
         routes => [ qw(file_pl) ],
      },
      require_modules => {
         Mojolicious => [ ],
      },
      require_binaries => {
         mojo => [ ],
         morbo => [ ],
      },
   };
}

sub generate_lite_app {
   my $self = shift;
   my ($pl) = @_;

   my $she = $self->shell;
   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('generate_lite_app', $pl) or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "mojo generate lite_app \"$pl\"";
   my $r = $self->execute($cmd);

   $she->run_cd($cwd) or return;

   return $r;
}

sub generate_app {
   my $self = shift;
   my ($module) = @_;

   my $she = $self->shell;
   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('generate_app', $module) or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "mojo generate app \"$module\"";
   my $r = $self->execute($cmd);

   $she->run_cd($cwd) or return;

   return $r;
}

sub morbo {
   my $self = shift;
   my ($pl) = @_;

   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('morbo', $pl) or return;
   $self->brik_help_run_file_not_found('morbo', $pl) or return;

   my $cmd = "morbo \"$pl\"";
   return $self->execute($cmd);
}

sub inflate {
   my $self = shift;
   my ($pl) = @_;

   my $she = $self->shell;
   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('inflate', $pl) or return;
   $self->brik_help_run_file_not_found('inflate', $pl) or return;

   my $cwd = $she->pwd;

   $she->run_cd($datadir) or return;

   my $cmd = "perl \"$pl\" inflate";
   my $r = $self->execute($cmd);

   $she->run_cd($cwd) or return;

   return $r;
}

#
# ./myapp.pl get -v '/?user=sebastian&pass=secr3t'
#
sub get {
   my $self = shift;
   my ($pl, $url) = @_;

   $self->brik_help_run_undef_arg('get', $pl) or return;
   $self->brik_help_run_undef_arg('get', $url) or return;

   my $cmd = "perl \"$pl\" get -v '$url'";
   return $self->execute($cmd);
}

sub test {
   my $self = shift;
   my ($pl) = @_;

   $self->brik_help_run_undef_arg('test', $pl) or return;

   my $cmd = "perl \"$pl\" test";
   return $self->execute($cmd);
}

#
# ./myapp.pl routes -v
#
sub routes {
   my $self = shift;
   my ($pl) = @_;

   $self->brik_help_run_undef_arg('routes', $pl) or return;

   my $cmd = "perl \"$pl\" routes -v";
   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Devel::Mojo - devel::mojo Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
