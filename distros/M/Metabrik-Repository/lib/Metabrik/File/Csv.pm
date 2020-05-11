#
# $Id$
#
# file::csv Brik
#
package Metabrik::File::Csv;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
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
         encoded_fields => [ qw(fields) ],
         object_fields => [ qw(fields) ],
         _csv => [ qw(INTERNAL) ],
         _fd => [ qw(INTERNAL) ],
         _sb => [ qw(INTERNAL) ],
         _sc => [ qw(INTERNAL) ],
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
         'Data::Dump' => [ ],
         'Text::CSV_XS' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Write' => [ ],
         'Metabrik::String::Base64' => [ ],
         'Metabrik::String::Compress' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   my $sc = Metabrik::String::Compress->new_from_brik_init($self) or return;
   $self->_sb($sb);
   $self->_sc($sc);

   return $self->SUPER::brik_init;
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

   # When some content is too complex to be stored as a standard CSV cell,
   # we should encode it as base64.
   my $sb = $self->_sb;
   my $sc = $self->_sc;
   my $encoded_fields = $self->encoded_fields;
   if (defined($encoded_fields)) {
      my $str = join(',', @$encoded_fields);
      $encoded_fields = { map { $_ => 1 } @$encoded_fields };
      $self->log->debug("read: will decode field(s) [$str] in encoded format");
   }
   my $object_fields = $self->object_fields;
   if (defined($object_fields)) {
      my $str = join(',', @$object_fields);
      $object_fields = { map { $_ => 1 } @$object_fields };
      $self->log->debug("read: will decode field(s) [$str] in object format");
   }

   my $object_re = qr/^OBJECT:(.*)$/;
   my $base64_re = qr/^BASE64:(.*)$/;  # Keep for backward compat.

   my $sep = $self->separator;
   my $headers;
   my $count;
   my $first_line = 1;
   my @rows = ();
   while (my $row = $csv->getline($fd)) {
      # The CSV file has a header, we output an array of hashes
      if ($self->first_line_is_header) {
         if ($first_line) {  # This is first line
            $headers = $row;
            $count = scalar @$row - 1;
            $first_line = 0;
            $self->header($headers);
            next;
         }

         my $h;
         # We have to decode some fields
         if ($encoded_fields || $object_fields) {
            for (0..$count) {
               my $k = $headers->[$_];
               my $v = $row->[$_];
               next unless defined($v);
               # Decode only if it has been asked and the value is not empty.
               # Decode the encode format
               if ($encoded_fields && exists($encoded_fields->{$k}) && length($v)) {
                  my $decoded = $sb->decode($v);
                  if (! defined($decoded)) {
                     $self->log->error("read: decode encoded format failed, ".
                        "skipping data with length [".length($v)."]");
                     next;
                  }
                  my $gunzipped = $sc->gunzip($decoded);
                  if (! defined($gunzipped)) {
                     $self->log->error("read: gunzip failed, skipping ".
                        "decoded data with length [".length($decoded)."]");
                     next;
                  }
                  $v = $$gunzipped;
               }
               # Decode the object format
               if ($object_fields && exists($object_fields->{$k}) && length($v)
               &&  ($v =~ $object_re || $v =~ $base64_re)) {
                  my $decoded = $sb->decode($1);
                  if (! defined($decoded)) {
                     $self->log->error("read: decode object format failed, ".
                        "skipping data with length [".length($v)."]");
                     next;
                  }
                  $v = eval($decoded);
               }
               $h->{$k} = $v;
            }
         }
         # Or not.
         else {
            for (0..$count) {
               $h->{$headers->[$_]} = $row->[$_];
            }
         }
         push @rows, $h;
      }
      # The CSV has no header, we output an array of arrays
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

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->output($output);
   $fw->encoding($self->encoding);
   $fw->overwrite($self->overwrite);
   $fw->append($self->append);
   $fw->use_locking($self->use_locking);
   $fw->unbuffered($self->unbuffered);

   # When some content is too complex to be stored as a standard CSV cell,
   # we should encode it as base64.
   my $sb = $self->_sb;
   my $sc = $self->_sc;
   my $encoded_fields = $self->encoded_fields;
   if (defined($encoded_fields)) {
      my $str = join(',', @$encoded_fields);
      $encoded_fields = { map { $_ => 1 } @$encoded_fields };
      $self->log->debug("write: will encode field(s) [$str] in encoded format");
   }
   my $object_fields = $self->object_fields;
   if (defined($object_fields)) {
      my $str = join(',', @$object_fields);
      $object_fields = { map { $_ => 1 } @$object_fields };
      $self->log->debug("write: will encode field(s) [$str] in object format");
   }

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

   my $header_count = @header;

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

   my $separator = $self->separator;
   my $escape = $self->escape;

   local $Data::Dump::INDENT = "";    # No indentation shorten length
   local $Data::Dump::TRY_BASE64 = 0; # Never encode in base64

   # Write the structure to file.
   for my $this (@$csv_struct) {
      my @fields = ();
      # We have to decode some fields
      if ($encoded_fields || $object_fields) {
         for my $key (keys %$this) {
            # We may have some unwanted data in this HASH, we skip it.
            next if (! defined($order{$key}));
            my $k = $key;
            my $v = $this->{$key};
            next unless defined($v);
            # Encode only if it has been asked and the value is not empty.
            if ($encoded_fields && exists($encoded_fields->{$k}) && length($v)) {
               # Gzip to handle UTF-like encodings, cause Base64 does not like that.
               my $gzipped = $sc->gzip($v);
               if (! defined($gzipped)) {
                  $self->log->error("write: gzip failed, skipping");
                  next;
               }
               $v = $sb->encode($$gzipped);
               if (! defined($v)) {
                  $self->log->error("write: encode in encoded format failed, skipping");
                  next;
               }
            }
            # Encode only if it has been asked and the value is not empty.
            if ($object_fields && exists($object_fields->{$k}) && length($v)) {
               # Encode ARRAYs and HASHes only if they are not empty.
               # Do not encode simple strings.
               if (ref($v) eq 'ARRAY' && @$v > 0
               ||  ref($v) eq 'HASH' && keys %$v > 0) {
                  $v = Data::Dump::dump($v); $v =~ s{\n}{}g;
                  $v = 'OBJECT:'.$sb->encode($v);
                  if (! defined($v)) {
                     $self->log->error("write: encode in object format failed, skipping");
                     next;
                  }
               }
               # If this is a simple string, we do not encode at all.
               elsif (ref($v) eq '' && length($v)) {
               }
               # And for empty objects, we set them to empty string.
               else {
                  $v = "";
               }
            }
            $fields[$order{$key}] = $v;
         }
      }
      # Or not.
      else {
         for my $key (keys %$this) {
            # We may have some unwanted data in this HASH, we skip it.
            next if (! defined($order{$key}));
            $fields[$order{$key}] = $this->{$key};
         }
      }

      @fields = map { defined($_) ? $_ : '' } @fields;

      # If this entry has less fields than the header, we add null entries.
      my $field_count = @fields;
      if ($field_count < $header_count) {
         my $diff = $header_count - $field_count;
         for (1..$diff) {
            push @fields, '';
         }
      }

      if ($self->use_quoting) {
         for (@fields) {
            s/"/${escape}"/g;
            $_ = '"'.$_.'"';
         }
      }

      my $data = join($separator, @fields)."\n";

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
      $self->log->debug('read_next: first call, create _csv');
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

   # When some content is too complex to be stored as a standard CSV cell,
   # we should encode it as base64.
   my $sb = $self->_sb;
   my $sc = $self->_sc;
   my $encoded_fields = $self->encoded_fields;
   if (defined($encoded_fields)) {
      my $str = join(',', @$encoded_fields);
      $encoded_fields = { map { $_ => 1 } @$encoded_fields };
      $self->log->debug("read_next: will decode field(s) [$str] in base64");
   }
   my $object_fields = $self->object_fields;
   if (defined($object_fields)) {
      my $str = join(',', @$object_fields);
      $object_fields = { map { $_ => 1 } @$object_fields };
      $self->log->debug("read_next: will decode field(s) [$str] in object format");
   }

   my $object_re = qr/^OBJECT:(.*)$/;
   my $base64_re = qr/^BASE64:(.*)$/;  # Keep for backward compat.

   my $row = $csv->getline($fd);

   # If a header is given as an Attribute, we use it to return a HASH
   my $header = $self->header;
   if (defined($header)) {
      my $h = {};
      my $i = 0;
      # We have to decode some fields
      if ($encoded_fields || $object_fields) {
         for (@$header) {
            my $k = $_;
            my $v = $row->[$i++];
            next unless defined($v);
            # Decode only if it has been asked and the value is not empty.
            # Decode the encode format
            if ($encoded_fields && exists($encoded_fields->{$k}) && length($v)) {
               my $decoded = $sb->decode($v);
               if (! defined($decoded)) {
                  $self->log->error("read_next: decode failed, skipping data with ".
                     "with length [".length($v)."]");
                  next;
               }
               my $gunzipped = $sc->gunzip($decoded);
               if (! defined($gunzipped)) {
                  $self->log->error("read_next: gunzip failed, skipping ".
                     "decoded data with length [".length($decoded)."]");
                  next;
               }
               $v = $$gunzipped;
            }
            # Decode the object format
            if ($object_fields && exists($object_fields->{$k}) && length($v)
            &&  ($v =~ $object_re || $v =~ $base64_re)) {
               my $decoded = $sb->decode($1);
               if (! defined($decoded)) {
                  $self->log->error("read_next: decode object format failed, ".
                     "skipping data with length [".length($v)."]");
                  next;
               }
               $v = eval($decoded);
            }
            $h->{$k} = $v;
         }
      }
      # Or not.
      else {
         for (@$header) {
            $h->{$_} = $row->[$i++];
         }
      }
      $row = $h;
   }

   if ($csv->eof) {
      $self->log->debug('read_next: eof reached');
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

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
