use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package JSON::LD 0.02 {

  # ABSTRACT: Load and dump JSON files


  use Exporter qw( import );
  use Path::Tiny ();
  use JSON::MaybeXS ();

  our @EXPORT = qw( LoadFile DumpFile );

  sub LoadFile ($filename) {
    return JSON::MaybeXS::decode_json(Path::Tiny->new($filename)->slurp_raw);
  }

  sub DumpFile ($filename, $data) {
    Path::Tiny->new($filename)->spew_raw(JSON::MaybeXS::encode_json($data));
    return undef;
  }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::LD - Load and dump JSON files

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use JSON::LD;

 DumpFile("foo.json", { a => 1 });
 my $data - LoadFile("foo.json:");

=head1 DESCRIPTION

Ever want to load JSON from a file?  Ever forget which module it is that you are
supposed to be using now?  Is it L<JSON> or L<JSON::PP> or L<JSON::XS> or
L<JSON::Syck> or L<Cpanel::JSON::XS> (how many Ns are in Cpanel?  For some reason
I am bad at spelling) or L<JSON::MaybeXS> or 
C<JSON::XS::TheNextForkBecausePreviousMaintainerTurnedOutToBeADouche>.
Which file mode are you supposed to be using again?  It's UTF-8 but I think I'm
supposed to read it as binary?  I forget and I have a headache now.

This module is for you.  It uses a similar interface to L<YAML> for loading
and dumping files.

=head1 FUNCTIONS

All functions are exported by default.

=head2 DumpFile

 DumpFile($filename, $data);

Dumps the data in C<$data> to C<$filename> as properly encoded JSON.  If C<$data>
cannot be represented as JSON or if there is an IO error it will throw an
exception.

=head2 LoadFile

 my $data = LoadFile($filename);

Loads the data in JSON format from C<$filename>.  If the JSON in C<$filename>
is not properly formatted or encoded or if there is an IO error it will throw
an exception.

=head1 CAVEATS

This module is a parody.  However the struggle is real.

=head1 SEE ALSO

=over 4

=item L<JSON::MaybeXS>

=item L<Path::Tiny>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
