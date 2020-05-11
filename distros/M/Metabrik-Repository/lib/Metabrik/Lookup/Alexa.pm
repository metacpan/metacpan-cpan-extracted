#
# $Id$
#
# lookup::alexa Brik
#
package Metabrik::Lookup::Alexa;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable top million 1m) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         url => [ qw(url) ],
         input => [ qw(file) ],
         _loaded => [ qw(INTERNAL) ],
      },
      attributes_default => {
         url => 'http://s3.amazonaws.com/alexa-static/top-1m.csv.zip',
         input => 'top-1m.csv',  # Stored in datadir by default
      },
      commands => {
         update => [ ],
         load => [ qw(input|OPTIONAL) ],
         from_string => [ qw(domain) ],
         from_pattern => [ qw(domain) ],
         list_from_pattern => [ qw(domain) ],
      },
      require_modules => {
         'Metabrik::File::Compress' => [ ],
         'Metabrik::File::Csv' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;
   my $url = $self->url;
   my $outfile_zip = $datadir.'/alexa-top1m.csv.zip';
   my $outfile_csv = $datadir.'/alexa-top1m.csv';

   my $files = $self->mirror($url, $outfile_zip) or return;

   my @updated = ();
   if (@$files > 0) {  # Update was available
      my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
      for my $file (@$files) {
         my $uncompressed = $fc->uncompress($file, $outfile_csv, $datadir) or next;
         push @updated, @$uncompressed;
      }
   }

   return \@updated;
}

sub load {
   my $self = shift;
   my ($input) = @_;

   # If not provided, we use the default from datadir
   if (! defined($input)) {
      $input = $self->datadir.'/'.$self->input;
   }
   $self->brik_help_run_file_not_found('load', $input) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->separator(',');
   $fc->first_line_is_header(0);

   return $fc->read($input);
}

sub from_string {
   my $self = shift;
   my ($domain) = @_;

   $self->brik_help_run_undef_arg('from_string', $domain) or return;

   my $data = $self->_loaded;
   if (! defined($data)) {
      $data = $self->load or return;
      $self->_loaded($data);
   }

   for my $this (@$data) {
      if ($this->[1] eq $domain) {
         return 1;
      }
   }

   return 0;
}

sub from_pattern {
   my $self = shift;
   my ($domain) = @_;

   $self->brik_help_run_undef_arg('from_pattern', $domain) or return;

   my $data = $self->_loaded;
   if (! defined($data)) {
      $data = $self->load or return;
      $self->_loaded($data);
   }

   for my $this (@$data) {
      if ($this->[1] =~ m{$domain}i) {
         return 1;
      }
   }

   return 0;
}

sub list_from_pattern {
   my $self = shift;
   my ($domain) = @_;

   $self->brik_help_run_undef_arg('list_from_pattern', $domain) or return;

   my $data = $self->_loaded;
   if (! defined($data)) {
      $data = $self->load or return;
      $self->_loaded($data);
   }

   my @list = ();
   for my $this (@$data) {
      if ($this->[1] =~ m{$domain}i) {
         push @list, $this->[1];
      }
   }

   return \@list;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Alexa - lookup::alexa Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
