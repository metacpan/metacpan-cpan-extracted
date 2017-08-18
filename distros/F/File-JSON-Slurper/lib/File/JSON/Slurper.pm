package File::JSON::Slurper;
$File::JSON::Slurper::VERSION = '0.03';
use 5.006;
use strict;
use warnings;

use parent 'Exporter';
use JSON::MaybeXS qw/ encode_json decode_json /;
use File::Slurper qw/ read_text write_text /;

our @EXPORT_OK = qw/ read_json write_json /;

sub read_json
{
    my $json = read_text(@_);
    return decode_json($json);
}

sub write_json
{
    my ($filename, $ref, @args) = @_;
    my $json = encode_json($ref);
    return write_text($filename, $json, @args);
}

1;

=head1 NAME

File::JSON::Slurper - slurp a JSON file into a data structure, and the reverse

=head1 SYNOPSIS

 use File::JSON::Slurper qw/ read_json write_json /;

 my $ref = read_json('stuff.json');

 my $data = { name => 'NEILB', age => 21 };
 write_json('fibber.json', $data);


=head1 DESCRIPTION

This module provides two functions for getting Perl data structures
into and out of files in JSON format.
One will read a Perl data structure from a JSON file,
and the other will take a Perl data structure and write it to a file
as JSON.

I wrote this module because I kept finding myself using
L<File::Slurper> to read JSON from a file,
and then L<JSON::MaybeXS> to convert the JSON to a Perl data structure.

No functions are exported by default,
you must specify which function(s) you want to import.


=head1 FUNCTIONS

=head2 read_json($filename, $encoding)

Read JSON from C<$filename> and convert it to a Perl data structure.
You'll get back either an arrayref or a hashref.

You can optionally specify the C<$encoding> of the file,
which defaults to UTF-8.


=head2 write_json($filename, $ref, $encoding)

Takes a Perl data structure C<$ref>,
converts it to JSON and then writes it to file C<$filename>.

You can optionally specify an C<$encoding>,
which defaults to UTF-8.


=head1 SEE ALSO

L<JSON::Parse> provides a function L<JSON::Parse/json_file_to_perl>
which is like the C<read_json> function provided by this module.
But you can't specify an encoding,
and it doesn't provide a function for writing to a file as JSON.

L<File::Slurper> is used to read and write files.

L<JSON::MaybeXS> is used to encode and decode JSON.
This itself is a front-end to the various JSON modules
available on CPAN.


=head1 REPOSITORY

L<https://github.com/neilb/File-JSON-Slurper>


=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
