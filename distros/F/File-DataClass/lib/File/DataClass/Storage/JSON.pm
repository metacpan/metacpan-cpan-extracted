package File::DataClass::Storage::JSON;

use boolean;
use namespace::autoclean;

use File::DataClass::Functions qw( extension_map throw );
use File::DataClass::Types     qw( Object );
use JSON::MaybeXS              qw( JSON );
use Try::Tiny;
use Moo;

extends q(File::DataClass::Storage);

extension_map 'JSON' => '.json';

# Private functions
my $_build_transcoder = sub {
   my $options = shift; my $json = JSON->new;

   for (grep { $_ ne 'reboolify' } keys %{ $options }) {
      $json = $json->$_( $options->{ $_ } );
   }

   return $json;
};

my $_reboolify; $_reboolify = sub {
   my $in = shift; my $ref = ref $in;

   if (not $ref) { return $in }
   elsif  ($ref eq 'HASH') {
      return { map { $_ => $_reboolify->( $in->{ $_ } ) } keys %{ $in } };
   }
   elsif  ($ref eq 'ARRAY') { return [ map { $_reboolify->( $_ ) } @{ $in } ] }
   elsif  ($ref =~ m{ ::Boolean \z }mx) { return ${ $in } ? true : false }

   return $in;
};

# Public attributes
has '+extn'          => default => '.json';

has '+read_options'  => builder => sub { { utf8 => false, } };

has '+write_options' => builder => sub { {
   canonical         => true, convert_blessed => true,
   pretty            => true, utf8            => false, } };

# Private attributes
has '_decoder'       => is => 'lazy', isa => Object,
   builder           => sub { $_build_transcoder->( $_[ 0 ]->read_options  ) };

has '_encoder'       => is => 'lazy', isa => Object,
   builder           => sub { $_build_transcoder->( $_[ 0 ]->write_options ) };

# Public methods
sub read_from_file {
   my ($self, $rdr) = @_; my $json = $self->_decoder; my $data;

   $self->encoding and $rdr->encoding( $self->encoding );
   $rdr->is_empty  and return {};

   try   {
      $data = $json->decode( $rdr->all );
      $self->read_options->{reboolify} and $data = $_reboolify->( $data );
   }
   catch { s{ at \s [^ ]+ \s line \s\d+\. }{}mx; throw "${_} in file ${rdr}" };

   return $data;
}

sub write_to_file {
   my ($self, $wtr, $data) = @_; my $json = $self->_encoder;

   $self->encoding and $wtr->encoding( $self->encoding );
   $wtr->print( $json->encode( $data ) );
   return $data;
}

1;

__END__

=pod

=head1 Name

File::DataClass::Storage::JSON - Read/write JSON data storage model

=head1 Synopsis

   use Moo;

   extends 'File::DataClass::Schema';

   has '+storage_class' => default => 'JSON';

=head1 Description

Uses L<JSON::MaybeXS> to read and write JSON files

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<extn>

The extension appended to filenames. Defaults to F<.json>

=item C<read_options>

This hash reference is used to customise the JSON decoder object used when
reading the file. It defaults to C<reboolify> false (causes booleans to be
inflated to objects) and C<utf8> false (the io object does the encoding).  This
filter would cause the data to be untainted (running C<suid>). I shit you not

   filter_json_object => sub { $_[ 0 ] }

=item C<write_options>

This hash reference is used to customise the JSON encoder object used when
writing the file. It defaults to C<canonical> true (sorts the keys in the
hashes), C<convert_blessed> true (looks for and uses the C<TO_JSON> method),
C<pretty> true (uses whitespace for indentation), and C<utf8> false (the io
object does the encoding)

=back

=head1 Subroutines/Methods

=head2 read_from_file

API required method. Calls L<JSON::MaybeXS/decode> to parse the input

=head2 write_to_file

API required method. Calls L<JSON::MaybeXS/encode> to generate the output

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass::Storage>

=item L<JSON::MaybeXS>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

Using the module L<JSON::XS> causes the round trip test to fail

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
