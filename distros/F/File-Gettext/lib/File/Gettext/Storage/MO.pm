package File::Gettext::Storage::MO;

use namespace::autoclean;

use Encode                     qw( decode );
use File::DataClass::Constants qw( NUL );
use File::DataClass::Functions qw( extension_map throw );
use File::Gettext::Constants   qw( MAGIC_N MAGIC_V PLURAL_SEP );
use Moo;

extension_map '+File::Gettext::Storage::MO' => '.mo';

extends q(File::DataClass::Storage);

has '+extn' => default => '.mo';

# Private subroutines
my $_decode = sub {
   my ($charset, $text) = @_; defined $text or return;

   $text = decode( $charset, $text );
   $text =~ s{ [\\][\'] }{\'}gmsx; $text =~ s{ [\\][\"] }{\"}gmsx;
   return $text;
};

# Private methods
my $_read_filter = sub {
   my ($self, $rdr) = @_; my $path = $rdr->pathname; my $raw = $rdr->all;

   my $size = length $raw; $size < 28 and throw 'Path [_1] corrupted', [ $path];
   my %meta = (); my $unpack = 'N';

   $meta{magic} = unpack $unpack, substr $raw, 0, 4;

   if    ($meta{magic} == MAGIC_V) { $unpack = 'V' }
   elsif ($meta{magic} != MAGIC_N) { throw 'Path [_1] bad magic', [ $path ] }

   @meta{ qw( revision num_strings msgids_off msgstrs_off hash_size hash_off ) }
      = unpack( ($unpack x 6), substr $raw, 4, 24 );

   $meta{revision} == 0 or throw 'Path [_1 ] invalid version', [ $path ];

   my $nstrs = $meta{num_strings};

   $meta{msgids_off}  + 4 * $nstrs > $size and
      throw 'Path [_1] bad msgid offset', [ $path ];
   $meta{msgstrs_off} + 4 * $nstrs > $size and
      throw 'Path [_1] bad msgstr offset', [ $path ];

   my @orig_tab  = unpack( ($unpack x (2 * $nstrs)),
      substr $raw, $meta{msgids_off},  8 * $nstrs );
   my @trans_tab = unpack( ($unpack x (2 * $nstrs)),
      substr $raw, $meta{msgstrs_off}, 8 * $nstrs );
   my $sep       = PLURAL_SEP;
   my $messages  = {};

   for (my $count = 0; $count < 2 * $nstrs; $count += 2) {
      my $orig_length  = $orig_tab[ $count ];
      my $orig_offset  = $orig_tab[ $count + 1 ];
      my $trans_length = $trans_tab[ $count ];
      my $trans_offset = $trans_tab[ $count + 1 ];

      $orig_offset  + $orig_length  > $size
         and throw 'Path [_1] bad key length', [ $path ];
      $trans_offset + $trans_length > $size
         and throw 'Path [_1] bad text length', [ $path ];

      my @origs = split m{ $sep }mx, substr $raw, $orig_offset,  $orig_length;
      my @trans = split m{ $sep }mx, substr $raw, $trans_offset, $trans_length;
      my $msgs  = { msgstr => [ @trans ] };

      # The singular is the origs 0, the plural is origs 1
      $messages->{ $origs[ 0 ] || NUL } = $msgs;
      $origs[ 1 ] and $messages->{ $origs[ 1 ] } = $msgs;
   }

   my $header = {}; my $null_entry;

   # Try to find po header information.
   if ($null_entry = $messages->{ NUL() }->{msgstr}->[ 0 ]) {
      for my $line (split m{ [\n] }msx, $null_entry) {
         my ($k, $v) = split m{ [:] }msx, $line, 2;

         $k =~ s{ [-] }{_}gmsx; $v =~ s{ \A \s+ }{}msx;
         $header->{ lc $k } = $v;
      }
   }

   if (exists $header->{content_type}) {
      my $content_type = $header->{content_type};

      $content_type =~ s{ .* = }{}msx and $header->{charset} = $content_type;
   }

   my $charset = exists $header->{charset}
               ? $header->{charset} : $self->schema->charset;
   my $tmp     = $messages; $messages = {};

   for my $key (grep { $_ } keys %{ $tmp }) {
      my $msg = $tmp->{ $key }; my $id = $_decode->( $charset, $key );

      $messages->{ $id } = { msgstr => [ map { $_decode->( $charset, $_ ) }
                                            @{ $msg->{msgstr} || [] } ] };
      defined $msg->{msgid_plural}
         and $messages->{ $id }->{msgid_plural}
            = $_decode->( $charset, $msg->{msgid_plural} );
   }

   my $code = $header->{plural_forms} || NUL;
   my $s    = '[ \t\r\n\013\014]'; # Whitespace, locale-independent.

   # Untaint the plural header. Keep line breaks as is Perl 5_005 compatibility
   if ($code =~ m{ \A ($s* nplurals $s* = $s* [0-9]+ $s* ; $s*
                       plural $s* = $s*
                       (?:$s|[-\?\|\&=!<>+*/\%:;a-zA-Z0-9_\(\)])+ ) }msx) {
      $header->{plural_forms} = $1;
   }
   else { $header->{plural_forms} = NUL }

   return { meta      => \%meta,
            mo        => $messages,
            po_header => { msgid => NUL, msgstr => $header } };
};

# Public methods
sub read_from_file {
   my ($self, $rdr) = @_; return $self->$_read_filter( $rdr );
}

sub write_to_file {
   my ($self, $wtr, $data) = @_; return $data;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

File::Gettext::Storage::MO - Storage class for GNU gettext machine object format

=head1 Synopsis

=head1 Description

Storage class for GNU gettext machine object format

=head1 Configuration and Environment

Defines these attributes;

=over 3

=item C<extn>

=back

=head1 Subroutines/Methods

=head2 read_from_file

=head2 write_to_file

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
