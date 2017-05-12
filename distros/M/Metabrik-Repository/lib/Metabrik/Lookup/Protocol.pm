#
# $Id: Protocol.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# lookup::protocol Brik
#
package Metabrik::Lookup::Protocol;
use strict;
use warnings;

use base qw(Metabrik::File::Csv);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable iana) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(input) ],
         _load => [ qw(INTERNAL) ],
      },
      attributes_default => {
         separator => ',',
         input => 'protocol-numbers-1.csv',
      },
      commands => {
         update => [ qw(output|OPTIONAL) ],
         load => [ qw(input|OPTIONAL) ],
         from_dec => [ qw(dec_number) ],
         from_hex => [ qw(hex_number) ],
         from_string => [ qw(protocol_string) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub update {
   my $self = shift;
   my ($output) = @_;

   my $url = 'http://www.iana.org/assignments/protocol-numbers/protocol-numbers-1.csv';
   my ($file) = $self->input;

   my $datadir = $self->datadir;
   $output ||= $datadir.'/'.$file;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $files = $cw->mirror($url, $file, $datadir) or return;
   if (@$files == 0) {  # Nothing new
      return $output;
   }

   # We have to rewrite the CSV file, cause some entries are multiline.
   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->overwrite(1);
   $ft->append(0);
   my $text = $ft->read($output)
      or return $self->log->error("update: read failed");

   # Some lines are split on multi-lines, we put into a single line
   # for each record.
   my @new = split(/\r\n/, $text);
   for (@new) {
      s/\n/ /g;
   }

   $ft->write(\@new, $output);

   return $output;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->datadir.'/'.$self->input;
   $self->brik_help_run_file_not_found('load', $input) or return;

   my $data = $self->read($input) or return;

   return $self->_load($data);
}

sub from_dec {
   my $self = shift;
   my ($dec) = @_;

   $self->brik_help_run_undef_arg('from_dec', $dec) or return;

   my $data = $self->_load || $self->load;
   if (! defined($data)) {
      return $self->log->error("from_dec: load failed");
   }

   for my $this (@$data) {
      if ($this->{Decimal} == $dec) {
         return $this->{Keyword};
      }
   }

   # No match
   return 'undef';
}

sub from_hex {
   my $self = shift;
   my ($hex) = @_;

   $self->brik_help_run_undef_arg('from_hex', $hex) or return;

   my $dec = hex($hex);

   return $self->from_dec($dec);
}

sub from_string {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('from_string', $string) or return;

   my $data = $self->_load || $self->load;
   if (! defined($data)) {
      return $self->log->error("from_string: load failed");
   }

   my @match = ();
   for my $this (@$data) {
      if ($this->{Keyword} =~ /$string/i) {
         $self->log->verbose("from_string: match with [".$this->{Keyword}."]");
         push @match, $this->{Decimal};
      }
      elsif ($this->{Protocol} =~ /$string/i) {
         $self->log->verbose("from_string: match with [".$this->{Protocol}."]");
         push @match, $this->{Decimal};
      }
   }

   return \@match;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Protocol - lookup::protocol Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
