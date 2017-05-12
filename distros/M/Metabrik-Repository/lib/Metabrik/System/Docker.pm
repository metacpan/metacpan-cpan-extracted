#
# $Id: Docker.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::docker Brik
#
package Metabrik::System::Docker;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable jail) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         name => [ qw(name) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         email => [ qw(email) ],
         force => [ qw(0|1) ],
      },
      attributes_default => {
         force => 1,
      },
      commands => {
         install => [ ], # Inherited
         build => [ qw(name directory) ],
         search => [ qw(name) ],
         get_image_id => [ qw(name) ],
         list => [ ],
         start => [ qw(name|$name_list) ],
         stop => [ qw(name|$name_list) ],
         restart => [ qw(name|$name_list) ],
         create => [ qw(name ip_address) ],
         backup => [ qw(name|$name_list) ],
         restore => [ qw(name ip_address archive_tar_gz) ],
         delete => [ qw(name) ],
         update => [ ],
         execute => [ qw(name command) ],
         console => [ qw(name) ],
         login => [ qw(email|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         push => [ qw(name) ],
         tag => [ qw(id tag) ],
         pull => [ qw(name) ],
      },
      # Have to be optional because of install Command
      optional_binaries => {
         'docker' => [ ],
      },
      require_binaries => {
         'wget' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(wget) ],
         debian => [ qw(wget) ],
      },
   };
}

sub brik_init {
   my $self = shift;

   if (! $self->brik_has_binary("docker")) {
      $self->log->warning("brik_init: you have to execute install Command now");
   }

   return $self->SUPER::brik_init;
}

sub install {
   my $self = shift;

   return $self->SUPER::execute("wget -qO- https://get.docker.com/ | sh");
}

sub build {
   my $self = shift;
   my ($name, $directory) = @_;

   $self->brik_help_run_undef_arg('build', $name) or return;
   $self->brik_help_run_undef_arg('build', $directory) or return;
   $self->brik_help_run_directory_not_found('build', $directory) or return;

   my $cmd = "docker build -t $name $directory";

   return $self->SUPER::execute($cmd);
}

sub search {
   my $self = shift;
   my ($jail_name) = @_;

   $self->brik_help_run_undef_arg('search', $jail_name) or return;

   my $cmd = "docker search $jail_name";

   return $self->SUPER::execute($cmd);
}

sub execute {
   my $self = shift;
   my ($jail_name, $command) = @_;

   $self->brik_help_run_undef_arg('execute', $jail_name) or return;
   $self->brik_help_run_undef_arg('execute', $command) or return;

   return $self->console($jail_name, $command);
}

sub get_image_id {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('get_image_id', $name) or return;

   my $lines = $self->list or return;
   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);
      if ($toks[0] eq $name) {
         return $toks[2];
      }
   }

   return 'undef';
}

sub list {
   my $self = shift;

   my $cmd = "docker images";

   return $self->capture($cmd);
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('stop', $name) or return;

   my $cmd = "docker stop $name";

   return $self->SUPER::execute($cmd);
}

sub start {
   my $self = shift;
   my ($jail_name) = @_;

   $self->brik_help_run_undef_arg('start', $jail_name) or return;

   my $cmd = "TODO";

   return $self->SUPER::execute($cmd);
}

sub restart {
   my $self = shift;
   my ($jail_name) = @_;

   $self->brik_help_run_undef_arg('restart', $jail_name) or return;

   my $cmd = "TODO";

   return $self->SUPER::execute($cmd);
}

sub create {
   my $self = shift;
   my ($jail_name) = @_;

   $self->brik_help_run_undef_arg('create', $jail_name) or return;

   my $cmd = "docker pull $jail_name";

   return $self->SUPER::execute($cmd);
}

sub backup {
   my $self = shift;
   my ($jail_name) = @_;

   $self->brik_help_run_undef_arg('backup', $jail_name) or return;

   my $cmd = "TODO";

   return $self->SUPER::execute($cmd);
}

sub restore {
   my $self = shift;
   my ($jail_name, $archive_tar_gz) = @_;

   $self->brik_help_run_undef_arg('restore', $jail_name) or return;
   $self->brik_help_run_undef_arg('restore', $archive_tar_gz) or return;

   my $cmd = "TODO";

   return $self->SUPER::execute($cmd);
}

sub delete {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('delete', $name) or return;

   my $cmd = "docker rmi -f $name";
   $self->SUPER::execute($cmd) or return;

   return $name;
}

sub update {
   my $self = shift;

   # XXX: needed?

   return 1;
}

sub console {
   my $self = shift;
   my ($name, $shell) = @_;

   $shell ||= '/bin/bash';
   $self->brik_help_run_undef_arg('console', $name) or return;

   my $cmd = "docker run -it $name '$shell'";

   return $self->SUPER::execute($cmd);
}

sub login {
   my $self = shift;
   my ($email, $username, $password) = @_;

   $email ||= $self->email;
   $username ||= $self->username;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('login', $email) or return;
   $self->brik_help_run_undef_arg('login', $username) or return;

   my $cmd = "docker login --username=$username --email=$email";
   if ($password) {
      $cmd .= " --password=$password";
   }

   return $self->SUPER::execute($cmd);
}

sub push {
   my $self = shift;
   my ($name) = @_;

   $name ||= $self->name;
   $self->brik_help_run_undef_arg('push', $name) or return;

   my $cmd = "docker push $name";

   return $self->SUPER::execute($cmd);
}

sub tag {
   my $self = shift;
   my ($id, $tag) = @_;

   $self->brik_help_run_undef_arg('tag', $id) or return;
   $self->brik_help_run_undef_arg('tag', $tag) or return;

   my $cmd = "docker tag $id $tag";

   return $self->SUPER::execute($cmd);
}

sub pull {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('pull', $name) or return;

   my $cmd = "docker pull $name";

   return $self->SUPER::execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Docker - system::docker Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
