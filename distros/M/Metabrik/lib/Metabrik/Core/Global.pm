#
# $Id$
#
# core::global Brik
#
package Metabrik::Core::Global;
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
         device => [ qw(device) ],
         family => [ qw(ipv4|ipv6) ],
         protocol => [ qw(udp|tcp) ],
         ctimeout => [ qw(seconds) ],
         rtimeout => [ qw(seconds) ],
         wtimeout => [ qw(seconds) ],
         datadir => [ qw(directory) ],
         username => [ qw(username) ],
         hostname => [ qw(hostname) ],
         homedir => [ qw(directory) ],
         # encoding: see `perldoc Encode::Supported' for other types
         encoding => [ qw(utf8|ascii) ],
         exit_on_sigint => [ qw(0|1) ],
         pid => [ qw(metabrik_main_pid) ],
         repository => [ qw(repository) ],
      },
      attributes_default => {
         device => 'eth0',
         family => 'ipv4',
         protocol => 'tcp',
         ctimeout => 5,
         rtimeout => 5,
         wtimeout => 5,
         username => $ENV{USER} || 'root',
         hostname => $ENV{HOST} || 'localhost',
         homedir => $ENV{HOME} || '/tmp',
         encoding => 'utf8',
         exit_on_sigint => 0,
         pid => $$,
      },
      require_modules => {
         'File::Path' => [ qw(make_path) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $homedir = $ENV{HOME} || '/tmp';
   my $datadir = $homedir.'/metabrik';
   my $repository = $homedir.'/metabrik/repository';

   eval("use File::Path qw(make_path);");
   File::Path::make_path($homedir, $datadir, $repository, {
      mode => 0755,
   });

   return {
      attributes_default => {
         homedir => $homedir,
         datadir => $datadir,
         repository => $repository,
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::Core::Global - core::global Brik

=head1 SYNOPSIS

   use Metabrik::Core::Global;

   my $GLO = Metabrik::Core::Global->new;

=head1 DESCRIPTION

This Brik holds some global Attributes like timeout values, paths or default network interface. You don't need to use this Brik directly. It is auto-loaded by B<core::context> Brik and is stored in its B<global> Attribute.

=head1 ATTRIBUTES

At B<The Metabrik Shell>, just type:

L<get core::global>

=head1 COMMANDS

At B<The Metabrik Shell>, just type:

L<help core::global>

=head1 METHODS

=over 4

=item B<brik_properties>

Class Properties for the Brik. See B<Metabrik>.

=item B<brik_use_properties>

Instanciated Properties when the Brik is first used. See B<use> Command.

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
