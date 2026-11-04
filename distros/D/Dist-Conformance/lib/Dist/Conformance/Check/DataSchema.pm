package Dist::Conformance::Check::DataSchema 0.001;

# ABSTRACT: A JSON or YAML file parses and matches a schema

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Dist::Conformance::Schema();


my %PARSER = (
    json => \&Dist::Conformance::Schema::parse_json,
    yaml => \&Dist::Conformance::Schema::parse_yaml,
);

my %FORMAT_OF_EXTENSION = ( json => 'json', yml => 'yaml', yaml => 'yaml' );

sub config_schema ($) {
    return {
        required   => [qw{file schema}],
        properties => {
            file    => $Dist::Conformance::Schema::PATH,
            schema  => { type => 'object' },
            format  => { type => 'string', enum => [ sort keys %PARSER ] },
            missing => { %$Dist::Conformance::Schema::STATUS, default => 'info' },
        },
    };
}


sub from_config ( $class, %arguments ) {
    my $where = $arguments{where} // "the check $arguments{name}";
    my $self  = $class->SUPER::from_config(%arguments);
    my $file  = $self->config->{file};
    die "$where is not valid:\n  /format: $file does not end in .json, .yml or .yaml, so give json or yaml\n" if !defined $self->file_format;
    return $self;
}


sub file_format ($self) {
    my $config = $self->config;
    return $config->{format} if defined $config->{format};
    my ($extension) = $config->{file} =~ m/[.]([^.\/]+)\z/;
    return defined $extension ? $FORMAT_OF_EXTENSION{ lc $extension } : undef;
}


sub check ( $self, $snapshot ) {
    my ( $file, $schema ) = @{ $self->config }{qw{file schema}};
    my $text   = $snapshot->content($file)                                // return ( $self->config->{missing}, "there is no $file" );
    my $data   = eval { $PARSER{ $self->file_format }->( $text, $file ) } // return ( 'fail',                   Dist::Conformance::Schema::first_line($@) );
    my @errors = Dist::Conformance::Schema::errors( $data, $schema );
    return ( 'fail', "$file does not match the schema: " . join '; ', @errors ) if @errors;
    return ( 'pass', 'valid' );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::DataSchema - A JSON or YAML file parses and matches a schema

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Some programs read a configuration file that a person writes by hand, and
ignore a key that they do not know without a word.  In such a file a
misspelling turns a rule off.  F<.perl-slop.json> of the perl-slop plugin is
one, as above.  This check reports C<missing> when the file is absent.  It
fails when the file does not parse as a JSON object or a YAML mapping, or does
not match C<schema>, and passes otherwise.

The schema is in the flavor, so that it changes in the same commit as the
standards that describe the file.  It is an OpenAPI v3 schema, as
L<Dist::Conformance::Schema> describes.

What a file should say is the repository's own choice, so the update changes
nothing.  It says what is wrong when the check fails.

=head1 METHODS

=head2 from_config

The same as L<Dist::Conformance::Check/from_config>.  It also dies when there
is no C<format> and the name of C<file> does not say one.

=head2 file_format

C<json> or C<yaml>: C<format>, or the format that the extension of C<file>
says.  Undefined when neither says one.

=head2 check

=head1 IN A FLAVOR

    checks:
      PerlSlopConfig:
        module: DataSchema
        file: .perl-slop.json
        missing: info
        schema:
          type: object
          additionalProperties: false
          properties:
            before_edit:
              type: object
            before_commit:
              type: object

=head1 CONFIGURATION

=over

=item file

Required.  The path of the file.

=item schema

Required.  The schema that its content must match.

=item format

C<json> or C<yaml>: how to parse the file.  Default C<json> for a file whose
name ends in F<.json>, and C<yaml> for one whose name ends in F<.yml> or
F<.yaml>.  A file with any other name needs it.

=item missing

The status when the file is absent.  Default C<info>, because a file of this
kind is usually optional.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Dist-Conformance/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
