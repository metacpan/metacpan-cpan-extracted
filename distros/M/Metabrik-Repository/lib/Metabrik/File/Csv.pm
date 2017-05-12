#
# $Id: Csv.pm,v 1e1671f227f5 2017/01/05 17:29:15 gomor $
#
# file::csv Brik
#
package Metabrik::File::Csv;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 1e1671f227f5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         first_line_is_header => [ qw(0|1) ],
         separator => [ qw(character) ],
         escape => [ qw(character) ],
         header => [ qw($column_header_list) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
         append => [ qw(0|1) ],
         write_header => [ qw(0|1) ],
         use_quoting => [ qw(0|1) ],
         use_locking => [ qw(0|1) ],
         unbuffered => [ qw(0|1) ],
         _csv => [ qw(INTERNAL) ],
         _fd => [ qw(INTERNAL) ],
      },
      attributes_default => {
         first_line_is_header => 1,
         separator => ',',
         escape => '"',
         encoding => 'utf8',
         overwrite => 0,
         append => 1,
         write_header => 1,
         use_quoting => 0,
         use_locking => 0,
         unbuffered => 0,
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         write => [ qw(csv_struct output_file|OPTIONAL) ],
         get_column_values => [ qw($data column_name|column_int) ],
         read_next => [ qw(input_file|OPTIONAL) ],
      },
      require_modules => {
         'Text::CSV_XS' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Write' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read', $input) or return;
   $self->brik_help_run_file_not_found('read', $input) or return;

   my $csv = Text::CSV_XS->new({
      binary => 1,
      sep_char => $self->separator,
      allow_loose_quotes => 1,
      allow_loose_escapes => 1,
      escape_char => $self->escape,
   }) or return $self->log->error('read: Text::CSV_XS new failed');

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->encoding($self->encoding);
   my $fd = $fr->open($input) or return;

   my $sep = $self->separator;
   my $headers;
   my $count;
   my $first_line = 1;
   my @rows = ();
   while (my $row = $csv->getline($fd)) {
      if ($self->first_line_is_header) {
         if ($first_line) {  # This is first line
            $headers = $row;
            $count = scalar @$row - 1;
            $first_line = 0;
            $self->header($headers);
            next;
         }

         my $h;
         for (0..$count) {
            $h->{$headers->[$_]} = $row->[$_];
         }
         push @rows, $h;
      }
      else {
         push @rows, $row;
      }
   }

   if (! $csv->eof) {
      my $error_str = "".$csv->error_diag();
      $self->log->error("read: incomplete: error [$error_str]");
      return \@rows;
   }

   $fr->close;

   return \@rows;
}

#
# We only handle ARRAY of HASHes format (aoh) for writing
#
sub write {
   my $self = shift;
   my ($csv_struct, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('write', $csv_struct) or return;
   $self->brik_help_run_invalid_arg('write', $csv_struct, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('write', $csv_struct, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('write', $output) or return;

   if (ref($csv_struct->[0]) ne 'HASH') {
      return $self->log->error("write: csv structure does not contain HASHes");
   }

   my $context = $self->context;

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->output($output);
   $fw->encoding($self->encoding);
   $fw->overwrite($self->overwrite);
   $fw->append($self->append);
   $fw->use_locking($self->use_locking);
   $fw->unbuffered($self->unbuffered);

   #
   # Set header ordering
   #
   my %order = ();
   my @header = ();
   # Order headers either by using user provided one or our own default ordering.
   if ($self->header) {
      @header = @{$self->header};
      my $idx = 0;
      for my $k (@header) {
         $order{$k} = $idx;
         $idx++;
      }
   }
   # If user didn't provide her own header, we use first element from struct.
   else {
      my $first = $csv_struct->[0];
      @header = sort { $a cmp $b } keys %$first;
      my $idx = 0;
      for my $k (@header) {
         $order{$k} = $idx;
         $idx++;
      }
   }

   my $is_new_file = (! -f $output);
   my $fd = $fw->open or return;

   my $written = '';

   # Write header if this is a new file and user asked for it.
   if ($self->write_header && ($is_new_file || $self->overwrite)) {
      my $data = join($self->separator, @header)."\n";
      my $r = $fw->write($data);
      if (! defined($r)) {
         return;
      }
      $written .= $data;
   }

   # Write the structure to file.
   for my $this (@$csv_struct) {
      my @fields = ();
      for my $key (keys %$this) {
         next if (! defined($order{$key}));  # We may have some unwanted data in this HASH
         $fields[$order{$key}] = $this->{$key};
      }

      @fields = map { defined($_) ? $_ : 'undef' } @fields;
      if ($self->use_quoting) {
         for (@fields) {
            s/"/\\"/g;
            $_ = '"'.$_.'"';
         }
      }
      my $data = join($self->separator, @fields)."\n";

      my $r = $fw->write($data);
      if (! defined($r)) {
         next;
      }

      $written .= $data;
   }

   $fw->close;

   if (! length($written)) {
      return $self->log->error("write: nothing to write");
   }

   return $written;
}

sub get_column_values {
   my $self = shift;
   my ($data, $column) = @_;

   $self->brik_help_run_undef_arg('get_column_values', $data) or return;
   $self->brik_help_run_invalid_arg('get_column_values', $data, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('get_column_values', $column) or return;

   my @results = ();
   # CSV structure is an ARRAYREF of HASHREFs
   if ($self->first_line_is_header) {
      if (@{$self->header} == 0) {
         return $self->log->error("get_column_values: no CSV header found");
      }

      for my $row (@$data) {
         if (ref($row) ne 'HASH') {
            $self->log->warning("get_column_values: row is not a HASHREF");
            next;
         }
         if (exists($row->{$column})) {
            push @results, $row->{$column};
         }
      }
   }
   # CSV structure is an ARRAYREF of ARRAYREFs
   elsif ($column =~ m{^\d+$}) {
      for my $row (@$data) {
         if (ref($row) ne 'ARRAY') {
            $self->log->warning("get_column_values: row is not an ARRAYREF");
            next;
         }
         if (exists($row->[$column])) {
            push @results, $row->[$column];
         }
      }
   }

   return \@results;
}

sub read_next {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read_next', $input) or return;
   $self->brik_help_run_file_not_found('read_next', $input) or return;

   my $csv = $self->_csv;
   my $fd = $self->_fd;
   if (! defined($csv)) {
      $self->debug && $self->log->debug('read_next: first call, create _csv');
      $csv = Text::CSV_XS->new({
         binary => 1,
         sep_char => $self->separator,
         allow_loose_quotes => 1,
         allow_loose_escapes => 1,
         escape_char => $self->escape,
      }) or return $self->log->error('read_next: Text::CSV_XS new failed');
      $self->_csv($csv);

      my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
      $fr->encoding($self->encoding);
      $fd = $fr->open($input) or return;
      $self->_fd($fd);

      if ($self->first_line_is_header) {
         my $header = $csv->getline($fd);
         $self->header($header);
      }
   }

   my $row = $csv->getline($fd);

   # If a header is given as an Attribute, we use it to return a HASH
   my $header = $self->header;
   if (defined($header)) {
      my $h = {};
      my $i = 0;
      for (@$header) {
         $h->{$_} = $row->[$i++];
      }
      $row = $h;
   }

   if ($csv->eof) {
      $self->debug && $self->log->debug('read_next: eof reached');
      $self->_fd(undef);
      $self->_csv(undef);
      return 0;
   }

   return $row;
}

1;

__END__

=head1 NAME

Metabrik::File::Csv - file::csv Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
