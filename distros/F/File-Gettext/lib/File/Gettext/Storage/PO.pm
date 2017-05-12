package File::Gettext::Storage::PO;

use namespace::autoclean;

use Date::Format                 ( );
use Encode                     qw( decode encode );
use File::DataClass::Constants qw( NUL SPC );
use File::DataClass::Functions qw( extension_map );
use File::Gettext::Constants   qw( CONTEXT_SEP );
use Moo;

extension_map '+File::Gettext::Storage::PO' => '.po';

extends q(File::DataClass::Storage);

has '+extn' => default => '.po';

# Private functions
my $_comment_field = sub {
   return { '#'  => q(translator_comment),
            '# ' => q(translator_comment),
            '#.' => q(extracted_comment),
            '#:' => q(reference),
            '#,' => q(flags),
            '#|' => q(previous), }->{ $_[ 0 ] };
};

my $_comment_prefix = sub {
   return { 'translator_comment' => '# ',
            'extracted_comment'  => '#.',
            'reference'          => '#:',
            'flags'              => '#,',
            'previous'           => '#|', }->{ $_[ 0 ] };
};

my $_decode_hash; $_decode_hash = sub {
   my ($charset, $in) = @_; my $out = {};

   for my $k (grep { defined } keys %{ $in }) {
      my $values = $in->{ $k }; defined $values or next;

      if (ref $values eq 'HASH') {
         $out->{ $k } = $_decode_hash->( $charset, $values );
      }
      elsif (ref $values eq 'ARRAY') {
         $out->{ $k } = [ map { decode( $charset, $_ ) } @{ $values } ];
      }
      else { $out->{ $k } = decode( $charset, $values ) }
   }

   return $out;
};

my $_header_inflate = sub {
   my $data = shift; my $header = (delete $data->{ NUL() }) || { msgstr => [] };

   my $null_entry = $header->{msgstr}->[ 0 ]; $header->{msgstr} = {};

   $null_entry or return $header;

   for my $line (split m{ [\n] }msx, $null_entry) {
      my ($k, $v) = split m{ [:] }msx, $line, 2;

      $k =~ s{ [-] }{_}gmsx; $v =~ s{ \A \s+ }{}msx;
      $header->{msgstr}->{ lc $k } = $v;
   }

   return $header;
};

my $_original_order = sub {
   my ($hash, $lhs, $rhs) = @_;

   # New elements will be  added at the end
   exists $hash->{ $lhs }->{_order} or return  1;
   exists $hash->{ $rhs }->{_order} or return -1;
   return $hash->{ $lhs }->{_order} <=> $hash->{ $rhs }->{_order};
};

my $_quote = sub {
   my $text = shift;

   $text =~ s{ \A [\"] }{\\\"}msx; $text =~ s{ ([^\\])[\"] }{$1\\\"}gmsx;

   return '"'.$text.'\n"';
};

my $_store_comment = sub {
   my ($rec, $line, $attr) = @_;

   my $value = length $line > 1 ? substr $line, 2 : NUL;

   if ($attr eq q(flags)) {
      push @{ $rec->{ $attr } }, map    { s{ \s+ }{}msx; $_ }
                                 split m{ [,]      }msx, $value;
   }
   else { $rec->{ $attr } .= $rec->{ $attr } ? "\n${value}" : $value }

   return;
};

my $_time2str = sub {
   my ($format, $time) = @_;

   defined $format or $format = '%Y-%m-%d %H:%M:%S';
   defined $time   or $time   = time;

   return Date::Format::Generic->time2str( $format, $time );
};

my $_unquote = sub {
   my $text = shift;

   $text =~ s{ [\\][n] \z }{\n}msx; $text =~ s{ [\\][\"] }{\"}gmsx;

   return $text;
};

my $_append_msgtext = sub {
   my ($rec, $key, $last, $text) = @_;

   if (ref $rec->{ $key } ne 'ARRAY') { $rec->{ $key } .= $_unquote->( $text ) }
   else { $rec->{ $key }->[ $last || 0 ] .= $_unquote->( $text ) }

   return;
};

my $_store_msgtext = sub {
   my ($rec, $line, $last_ref) = @_; my $key;

   if ($line =~ m{ \A msgctxt \s+ [\"] (.*) [\"] \z }msx) {
      $key = q(msgctxt); $rec->{ $key } = $_unquote->( $1 );
   }
   elsif ($line =~ m{ \A msgid \s+ [\"] (.*) [\"] \z }msx) {
      $key = q(msgid); $rec->{ $key } = $_unquote->( $1 );
   }
   elsif ($line =~ m{ \A msgid_plural \s+ [\"] (.*) [\"] \z }msx) {
      $key = q(msgid_plural); $rec->{ $key } = $_unquote->( $1 );
   }
   elsif ($line =~ m{ \A msgstr \s+ [\"] (.*) [\"] \z }msx) {
      $key = q(msgstr); $rec->{ $key } ||= [];
      $rec->{ $key }->[ ${ $last_ref } = 0 ] .= $_unquote->( $1 );
   }
   elsif ($line =~ m{ \A msgstr\[\s*(\d+)\s*\] \s+ [\"](.*)[\"] \z }msx) {
      $key = q(msgstr); $rec->{ $key } ||= [];
      $rec->{ $key }->[ ${ $last_ref } = $1 ] .= $_unquote->( $2 );
   }

   return $key;
};

# Private common methods
my $_get_charset = sub {
   my ($self, $po_header) = @_; my $charset = $self->schema->charset;

   my $msgstr       = $po_header->{msgstr} || {};
   my $content_type = $msgstr->{content_type} || NUL;

   $content_type =~ s{ .* = }{}msx and $charset = $content_type;

   return $charset;
};

# Private read methods
my $_inflate_and_decode = sub {
   my ($self, $data) = @_;

   my $po_header = $_header_inflate->( $data );
   my $charset   = $self->$_get_charset( $po_header );
   my $tmp       = $data; $data = {};

   # Decode all keys and values using the charset from the header
   for my $k (grep { $_ and defined $tmp->{ $_ } } keys %{ $tmp }) {
      my $rec = $tmp->{ $k }; my $id = decode( $charset, $k );

      $data->{ $id } = $_decode_hash->( $charset, $rec );
   }

   return { po => $data, po_header => $_decode_hash->( $charset, $po_header ) };
};

my $_store_record = sub {
   my ($self, $data, $rec, $order_ref) = @_; exists $rec->{msgid} or return;

   my @ctxt = split m{ [\.] }msx, ($rec->{msgctxt} || NUL), 2;

   $ctxt[ 0 ] = $ctxt[ 0 ] ? $ctxt[ 0 ].SPC : 'messages ';
   $ctxt[ 1 ] = $ctxt[ 1 ] ? SPC.$ctxt[ 1 ] : NUL;
   $rec->{labels} = $ctxt[ 0 ].$rec->{msgid}.$ctxt[ 1 ];
   $rec->{_order} = ${ $order_ref }++;
   $data->{ $self->make_key( $rec ) } = $rec;
   return;
};

my $_read_filter = sub {
   my ($self, $buf) = @_; $buf ||= [];

   my ($data, $order, $rec, $key, $last) = ({}, 0, {});

   for my $line (grep { defined } @{ $buf }) {
      # Lines beginning with a hash are comments
      if ('#' eq substr $line, 0, 1) {
         my $field = $_comment_field->( substr $line, 0, 2 );

         $field and $_store_comment->( $rec, $line, $field );
      }
      # Field names all begin with the prefix msg
      elsif ('msg' eq substr $line, 0, 3) {
         $key = $_store_msgtext->( $rec, $line, \$last );
      }
      # Match any continuation lines
      elsif ($line =~ m{ \A \s* [\"] (.+) [\"] \z }msx and defined $key) {
         $_append_msgtext->( $rec, $key, $last, $1 );
      }
      # A blank line ends the record
      elsif ($line =~ m{ \A \s* \z }msx) {
         $self->$_store_record( $data, $rec, \$order );
         $key = undef; $last = undef; $rec = {};
      }
   }

   $self->$_store_record( $data, $rec, \$order ); # If the last line isn't blank

   return $self->$_inflate_and_decode( $data );
};

# Private write methods
my $_default_po_header = sub {
   my $self       = shift;
   my $charset    = $self->schema->charset;
   my $defaults   = $self->schema->default_po_header;
   my $appname    = $defaults->{appname   };
   my $company    = $defaults->{company   };
   my $email      = $defaults->{email     };
   my $lang       = $defaults->{lang      };
   my $team       = $defaults->{team      };
   my $translator = $defaults->{translator};
   my $rev_date   = $_time2str->( '%Y-%m-%d %H:%M%z' );
   my $year       = $_time2str->( '%Y' );

   return {
      'translator_comment' => join "\n", ( '@(#)$Id'.'$',
                                           'GNU Gettext Portable Object.',
                                           "Copyright (C) ${year} ${company}.",
                                           "${translator} ${email}, ${year}.",
                                           '', ),
      flags       => [ 'fuzzy', ],
      msgstr      => {
         'project_id_version'        => "${appname} ${File::Gettext::VERSION}",
         'po_revision_date'          => $rev_date,
         'last_translator'           => "${translator} ${email}",
         'language_team'             => "${team} ${email}",
         'language'                  => $lang,
         'mime_version'              => '1.0',
         'content_type'              => 'text/plain; charset='.$charset,
         'content_transfer_encoding' => '8bit',
         'plural_forms'              => 'nplurals=2; plural=(n != 1);', }, };
};

my $_get_comment_lines = sub {
   my ($self, $attr_name, $values, $prefix) = @_; my $lines = [];

   $attr_name eq 'flags' and return [ $prefix.SPC.(join ', ', @{ $values }) ];

   $values =~ m{ [\n] \z }msx and $values .= SPC;

   for my $line (map { $prefix.$_ } split m{ [\n] }msx, $values) {
      $line =~ s{ \# \s+ \z }{\#}msx; push @{ $lines }, $line;
   }

   return $lines;
};

my $_get_po_header_key = sub {
   my ($self, $k) = @_; my $key_table = $self->schema->header_key_table;

   defined $key_table->{ $k } and return $key_table->{ $k };

   my $po_key = join q(-), map { ucfirst $_ } split m{ [_] }msx, $k;

   return [ 1 + keys %{ $key_table }, $po_key ];
};

my $_split_on_nl = sub {
   my ($self, $attr_name, $value) = @_;

   $value ||= NUL; my $last_char = substr $value, -1; chomp $value;

   my @lines = split m{ [\n] }msx, $value; my $lines = [];

   if (@lines < 2) { push @{ $lines }, "${attr_name} ".$_quote->( $value ) }
   else {
      push @{ $lines }, $attr_name.' ""';
      push @{ $lines }, map { $_quote->( $_ ) } @lines;
   }

   $last_char ne "\n" and $lines->[ -1 ] =~ s{ [\\][n][\"] \z }{\"}msx;
   return $lines;
};

my $_array_split_on_nl = sub {
   my ($self, $attr, $values) = @_; my $index = 0; my $lines = [];

   for my $value (@{ $values }) {
      push @{ $lines }, @{ $self->$_split_on_nl( "${attr}[${index}]", $value )};
      $index++;
   }

   return $lines;
};

my $_header_deflate = sub {
   my ($self, $po_header) = @_; my $msgstr_ref = $po_header->{msgstr} || {};

   my $header = { %{ $po_header || {} } }; my $msgstr;

   for my $k (sort  { $self->$_get_po_header_key( $a )->[ 0 ]
                  <=> $self->$_get_po_header_key( $b )->[ 0 ] }
              keys %{ $msgstr_ref }) {
      $msgstr .= $self->$_get_po_header_key( $k )->[ 1 ];

#      if ($k eq q(po_revision_date)) {
#         $msgstr .= ': '.$_time2str->( "%Y-%m-%d %H:%M%z" )."\n";
#      }
#      else { $msgstr .= ': '.($msgstr_ref->{ $k } || NUL)."\n" }
      $msgstr .= ': '.($msgstr_ref->{ $k } || NUL)."\n";
   }

   $header->{_order} = 0;
   $header->{msgid } = NUL;
   $header->{msgstr} = [ $msgstr ];
   return $header;
};

my $_get_lines = sub {
   my ($self, $attr_name, $values) = @_; my ($cpref, $lines);

   if ($cpref = $_comment_prefix->( $attr_name )) {
      $lines = $self->$_get_comment_lines( $attr_name, $values, $cpref );
   }
   elsif (ref $values eq 'ARRAY') {
      if (@{ $values } > 1) {
         $lines = $self->$_array_split_on_nl( $attr_name, $values );
      }
      else { $lines = $self->$_split_on_nl( $attr_name, $values->[ 0 ] ) }
   }
   else { $lines = $self->$_split_on_nl( $attr_name, $values ) }

   return $lines;
};

my $_write_filter = sub {
   my ($self, $data) = @_; my $buf ||= [];

   my $po        = $data->{po       } || {};
   my $po_header = $data->{po_header} || $self->$_default_po_header;
   my $charset   = $self->$_get_charset( $po_header );
   my $attrs     = $self->schema->source->attributes;

   $po->{ NUL() } = $self->$_header_deflate( $po_header );

   for my $key (sort { $_original_order->( $po, $a, $b ) } keys %{ $po }) {
      my $rec = $po->{ $key };

      $rec->{name} and not $rec->{msgid}
         and $rec->{msgid} = delete $rec->{name};

      for my $attr_name (grep { exists $rec->{ $_ } } @{ $attrs }) {
         my $values = $rec->{ $attr_name }; defined $values or next;

         ref $values eq 'ARRAY' and @{ $values } < 1 and next;
         push @{ $buf }, map { encode( $charset, $_ ) }
                            @{ $self->$_get_lines( $attr_name, $values ) };
      }

      push @{ $buf }, NUL;
   }

   pop @{ $buf };
   return $buf;
};

# Public methods
sub read_from_file {
   my ($self, $rdr) = @_;

   return $self->$_read_filter( [ $rdr->chomp->getlines ] );
};

sub write_to_file {
   my ($self, $wtr, $data) = @_;

   $wtr->println( @{ $self->$_write_filter( $data ) } );
   return $data;
}

sub decompose_key {
   my ($self, $key) = @_; my $sep = CONTEXT_SEP;

   0 >= index $key, $sep and return (NUL, $key);

   return split m{ $sep }msx, $key, 2;
}

sub make_key {
   my ($self, $rec) = @_;

   return (exists $rec->{msgctxt}
           ? $rec->{msgctxt}.CONTEXT_SEP : NUL).$rec->{msgid};
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

File::Gettext::Storage::PO - Storage class for GNU Gettext portable object format

=head1 Synopsis

=head1 Description

Storage class for GNU Gettext portable object format

=head1 Configuration and Environment

Defines these attributes;

=over 3

=item C<extn>

=back

=head1 Subroutines/Methods

=head2 read_from_file

Required API method

=head2 write_to_file

Required API method

=head2 decompose_key

=head2 make_key

Concatenates the C<msgctxt> and C<msgid> attributes to form the hash key

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass>

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
