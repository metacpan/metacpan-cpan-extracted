#
# $Id$
#
# database::sinfp3 Brik
#
package Metabrik::Database::Sinfp3;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network sinfp scanner signature) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         db => [ qw(sinfp3_db) ],
      },
      commands => {
         active_signature_export => [ qw(sinfp3_db|OPTIONAL output|OPTIONAL) ],
         passive_signature_export => [ qw(sinfp3_db|OPTIONAL output|OPTIONAL) ],
      },
      require_modules => {
         'Net::SinFP3::Plugin::Signature' => [ ],
         'Net::SinFP3::Global' => [ ],
         'Net::SinFP3::Log::Console' => [ ],
         'Net::SinFP3::Input::Null' => [ ],
         'Net::SinFP3::Search::Null' => [ ],
         'Net::SinFP3::Mode::Null' => [ ],
         'Net::SinFP3::DB::SinFP3' => [ ],
         'Net::SinFP3::Output::Export' => [ ],
         'Net::SinFP3::Output::ExportP' => [ ],
         'Net::SinFP3' => [ ],
      },
   };
}

#
# sinfp3.pl -input-null -db-sinfp3 -db-file FILE -mode-null -search-null -output Export
#
sub active_signature_export {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->db;
   $self->brik_help_run_undef_arg('active_signature_export', $file) or return;
   $self->brik_help_run_file_not_found('active_signature_export', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => 0,
   ) or return $self->log->error("active_signature_export: log failed");

   my $global = Net::SinFP3::Global->new(
      log => $log,
   ) or return $self->log->error("active_signature_export: global failed");

   my $input = Net::SinFP3::Input::Null->new(global => $global);
   my $search = Net::SinFP3::Search::Null->new(global => $global);
   my $mode = Net::SinFP3::Mode::Null->new(global => $global);

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      db => $file,
   );

   my $output = Net::SinFP3::Output::Export->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $res = $sinfp3->run;

   $log->post;

   return $res;
}

#
# sinfp3.pl -input-null -db-sinfp3 -db-file FILE -mode-null -search-null -output ExportP
#
sub passive_signature_export {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->db;
   $self->brik_help_run_undef_arg('passive_signature_export', $file) or return;
   $self->brik_help_run_file_not_found('passive_signature_export', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => 0,
   ) or return $self->log->error("passive_signature_export: log failed");

   my $global = Net::SinFP3::Global->new(
      log => $log,
   ) or return $self->log->error("passive_signature_export: global failed");

   my $input = Net::SinFP3::Input::Null->new(global => $global);
   my $search = Net::SinFP3::Search::Null->new(global => $global);
   my $mode = Net::SinFP3::Mode::Null->new(global => $global);

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      db => $file,
   );

   my $output = Net::SinFP3::Output::ExportP->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $res = $sinfp3->run;

   $log->post;

   return $res;
}

1;

__END__

=head1 NAME

Metabrik::Database::Sinfp3 - database::sinfp3 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
