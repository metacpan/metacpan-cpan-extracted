#
# $Id$
#
# password::mirai Brik
#
package Metabrik::Password::Mirai;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable dictionary bruteforce iot) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         telnet => [ ],
         save_as_csv => [ qw(output_file) ],
         save_as_couple => [ qw(output_file) ],
      },
      require_modules => {
         'Metabrik::File::Csv' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
      },
   };
}

#
# https://github.com/jgamblin/Mirai-Source-Code/blob/6a5941be681b839eeff8ece1de8b245bcd5ffb02/mirai/bot/scanner.c
#
sub telnet {
   my $self = shift;

   return [
      { login => '666666', passwords => [ qw( 666666 ) ] },
      { login => '888888', passwords => [ qw( 888888 ) ] },
      { login => 'admin', passwords => [ "", qw( 1111 1111111 1234 12345 123456 54321 7ujMko0admin admin admin1234 meinsm pass password smcadmin ) ] },
      { login => 'admin1', passwords => [ qw( password ) ] },
      { login => 'administrator', passwords => [ qw( 1234 ) ] },
      { login => 'Administrator', passwords => [ qw( admin ) ] },
      { login => 'guest', passwords => [ qw( 12345 guest ) ] },
      { login => 'mother', passwords => [ qw( fucker ) ] },
      { login => 'root', passwords => [ "", qw( 00000000 1111 1234 12345 123456 54321 666666 7ujMko0admin 7ujMko0vizxv 888888 admin anko default dreambox hi3518 ikwb juantech jvbzd klv123 klv1234 pass password realtek root system user vizxv xc3511 xmhdipc zlxx.  Zte521 ) ] },
      { login => 'service', passwords => [ qw( service ) ] },
      { login => 'supervisor', passwords => [ qw( supervisor ) ] },
      { login => 'support', passwords => [ qw( support ) ] },
      { login => 'tech', passwords => [ qw( tech ) ] },
      { login => 'ubnt', passwords => [ qw( ubnt ) ] },
      { login => 'user', passwords => [ qw( user ) ] },
   ];
}

sub save_as_csv {
   my $self = shift;
   my ($output_file) = @_;

   $self->brik_help_run_undef_arg('save_as_csv', $output_file) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->header([ qw( login password ) ]);

   if (-f $output_file) {
      my $fs = Metabrik::System::File->new_from_brik_init($self) or return;
      $fs->remove($output_file) or return;
   }

   my @lines = ();
   my $list = $self->telnet or return;
   for my $this (@$list) {
      my $login = $this->{login};
      for my $pass (@{$this->{passwords}}) {
         push @lines, {
            login => $login,
            password => $pass,
         };
      }
   }

   $fc->write(\@lines, $output_file) or return;

   return $output_file;
}

sub save_as_couple {
   my $self = shift;
   my ($output_file) = @_;

   $self->brik_help_run_undef_arg('save_as_couple', $output_file) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;

   if (-f $output_file) {
      my $fs = Metabrik::System::File->new_from_brik_init($self) or return;
      $fs->remove($output_file) or return;
   }

   my @lines = ();
   my $list = $self->telnet or return;
   for my $this (@$list) {
      my $login = $this->{login};
      for my $pass (@{$this->{passwords}}) {
         push @lines, "$login:$pass";
      }
   }

   $ft->write(\@lines, $output_file) or return;

   return $output_file;
}

1;

__END__

=head1 NAME

Metabrik::Password::Mirai - password::mirai Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
