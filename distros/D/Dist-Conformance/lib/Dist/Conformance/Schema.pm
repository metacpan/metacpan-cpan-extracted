package Dist::Conformance::Schema 0.011;

# ABSTRACT: Parse YAML, JSON and INI, and validate the result against a schema

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';

use Clone ();
use Cpanel::JSON::XS();
use JSON::Validator::Schema::Troglodyne();
use YAML::XS();


# Each pattern is a qr// in a string, so that it keeps the modifiers of this file.
my $NAME_RX = qr/\A[[:alnum:]][[:alnum:]._-]*\z/;
my $PATH_RX = qr{\A(?!/)(?!(?:[^\n]*/)?[.][.](?:/|\z))[^\n]+\z};

our $NAME   = { type => 'string', pattern => "$NAME_RX" };
our $PATH   = { type => 'string', pattern => "$PATH_RX" };
our $STATUS = { type => 'string', enum    => [qw{pass info fail}] };


sub parse_yaml ( $text, $where ) {
    my $data = eval { YAML::XS::Load($text) };
    die "$where does not parse as YAML: $@"                 if !defined $data && $@;
    die "$where does not hold a mapping at its top level\n" if ref $data ne 'HASH';
    return $data;
}


sub parse_json ( $bytes, $where ) {
    my $data = eval { Cpanel::JSON::XS->new->utf8->decode($bytes) };
    die( "$where does not parse as JSON: " . first_line($@), "\n" ) if !defined $data && $@;
    die "$where does not hold an object at its top level\n"         if ref $data ne 'HASH';
    return $data;
}


sub encode_json ($data) {
    return Cpanel::JSON::XS->new->utf8->pretty->space_before(0)->canonical->indent_length(2)->encode($data);
}


sub insert_yaml ( $text, $path, $data ) {
    my $indent_of = sub ($line) { return length( $line =~ s/\S.*//sr ) };
    my $fragment  = sub ( $value, $indent ) {
        return map { ( q{ } x $indent ) . $_ } split /\n/, YAML::XS::Dump($value) =~ s/\A---\n//r;
    };
    my @lines = split /\n/, $text, -1;
    pop @lines if @lines && $lines[-1] eq q{};
    my ( $indent, $from, $to, @keys ) = ( 0, 0, scalar @lines, @$path );
    while ( defined( my $key = shift @keys ) ) {
        my ($at) = grep { $lines[$_] =~ m/\A[ ]{$indent}\Q$key\E:/ } $from .. $to - 1;
        if ( !defined $at ) {
            my $nested = $data;
            for my $inner ( reverse @keys ) { $nested = { $inner => $nested } }
            splice @lines, $to, 0, $fragment->( { $key => $nested }, $indent );
            return join( "\n", @lines ) . "\n";
        }
        die "$key has something after it on its line\n" if $lines[$at] !~ m/:\s*(?:\#.*)?\z/;
        my @block;
        for my $index ( grep { $lines[$_] =~ m/\A\s*[^\s\#]/ } $at + 1 .. $to - 1 ) {
            last if $indent_of->( $lines[$index] ) <= $indent;
            push @block, $index;
        }
        ( $from, $to ) = ( $at + 1, @block ? $block[-1] + 1 : $at + 1 );
        $indent = @block ? $indent_of->( $lines[ $block[0] ] ) : $indent + 2;
    }
    splice @lines, $to, 0, $fragment->( $data, $indent );
    return join( "\n", @lines ) . "\n";
}


sub validate ( $data, $schema, $where ) {
    my $copy   = Clone::clone($data);
    my @errors = errors( $copy, $schema );
    refuse( $where, @errors ) if @errors;
    return $copy;
}


sub refuse ( $where, @errors ) {
    die join( "\n", "$where is not valid:", map { "  $_" } @errors ), "\n";
}


sub errors ( $data, $schema ) {
    my $validator = JSON::Validator::Schema::Troglodyne->new;
    $validator->coerce( { %{ $validator->coerce }, defaults => 1, booleans => 1 } );
    my @errors = map { "$_" } $validator->validate( $data, $schema );
    return @errors;
}


sub matches ( $fragment, $value ) {

    # (?^:) gives the pattern the default flags that JSON::Validator matches it with, not the /s of this file.
    return defined $value && $value =~ m/(?^:$fragment->{pattern})/;
}


sub relative_path ( $path, $inside ) {

    die( ( $path // 'undef' ) . " is not a relative path inside $inside\n" ) if !matches( $PATH, $path );
    return $path;
}


sub parse_ini ( $text, $where ) {
    my $data = eval { Dist::Conformance::Schema::INIReader->read_string($text) };
    die( "$where does not parse as INI: " . first_line($@), "\n" ) if !defined $data;
    return $data;
}


sub first_line ($text) {
    my ($line) = split /\n/, $text // q{};
    $line //= q{};
    $line =~ s/\ at\ \S+\ line\ \d+[.]?\z//;
    return $line;
}

# Config::INI::Reader keeps the last value of a repeated key, so it collects each repeat into a list.
package Dist::Conformance::Schema::INIReader 0.011 {
    use parent 'Config::INI::Reader';

    sub set_value ( $self, $name, $value ) {
        my $values = $self->{ __PACKAGE__ . '/values' }{ $self->current_section }{$name} //= [];
        push @$values, $value;
        return $self->SUPER::set_value( $name, @$values == 1 ? $value : [@$values] );
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Schema - Parse YAML, JSON and INI, and validate the result against a schema

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Schema;

    my $data = Dist::Conformance::Schema::parse_yaml( "name: troglodyne\n", 'conformance/troglodyne.yml' );
    $data = Dist::Conformance::Schema::validate(
        $data,
        { type => 'object', required => ['name'], properties => { name => $Dist::Conformance::Schema::NAME } },
        'conformance/troglodyne.yml',
    );

=head1 DESCRIPTION

Every file that Dist::Conformance reads is data that somebody wrote by hand: a
flavor file, F<.conformance.yml>, the configuration of a check.  This module
holds the two things that each of them needs: a parser whose error names the
file, and a validator whose errors name the file and the key.

The schemas are OpenAPI v3 schemas for L<JSON::Validator::Schema::Troglodyne>.
That means C<nullable> instead of a type list, and no C<propertyNames>.  The
validator fills in the C<default> of each key that the data leaves out, and
coerces C<true>, C<false>, C<yes>, C<no>, C<1>, C<0> and the empty string to a
boolean where the schema asks for one.

=head1 FUNCTIONS

=head2 parse_yaml($text, $where)

The mapping that the YAML document C<$text> holds.

=over 4

=item text - Str - the YAML document

=item where - Str - names the document in an error, such as its file

=back

Returns HashRef, the mapping.

Dies with a message that starts with C<$where> when the text does not parse,
or when its top level is not a mapping.

    my $data = Dist::Conformance::Schema::parse_yaml( "name: troglodyne\n", 'conformance/troglodyne.yml' );

=head2 parse_json($bytes, $where)

The same as L<parse_yaml|/"parse_yaml($text, $where)">, for UTF-8 JSON text.

=over 4

=item bytes - Str - the JSON text, as UTF-8 bytes

=item where - Str - names the text in an error, such as its file

=back

Returns HashRef, the object.

Dies with a message that starts with C<$where> when the text does not parse,
or when its top level is not an object.

    my $settings = Dist::Conformance::Schema::parse_json( '{"enabledPlugins":{}}', '.claude/settings.json' );

=head2 encode_json($data)

C<$data> as UTF-8 JSON, indented by two spaces, with the keys sorted, and with
a final newline, so that a file that this distribution writes gives a small
diff the next time it changes.

=over 4

=item data - Ref - the data to encode

=back

Returns Str, the JSON, as UTF-8 bytes.

    my $json = Dist::Conformance::Schema::encode_json( { enabledPlugins => {} } );

=head2 insert_yaml($text, $path, $data)

The YAML text C<$text>, with C<$data> added to the collection at the keys of
C<@$path> from the top.  C<$data> is a mapping, whose entries are added, or a
list, whose items are added.  They go at the end of the block of the last key,
at the indentation of the block, and every other line stays as it is.  A key
that is not there is added at the end of the block of the key above it, or of
the text, with C<$data> under it.

It edits text, and does not parse it.  So it can give text that does not say
what it should, such as for a key in quotes, or a list at the indentation of
its key.  The caller parses the result, and compares it with what it expects.

=over 4

=item text - Str - the YAML text

=item path - ArrayRef[Str] - the keys, from the top, such as C<['x_system_sources', 'deb']>

=item data - HashRef|ArrayRef - the entries or the items to add

=back

Returns Str, the new text, which ends in a newline.

Dies when a key on the path has something after it on its line, such as a
collection in flow style or an anchor.

    my $text = Dist::Conformance::Schema::insert_yaml( $yaml, ['x_system_packages'], { aspell => { deb => 'aspell' } } );

=head2 validate($data, $schema, $where)

A copy of C<$data> with the defaults of C<$schema> filled in.  The caller's
data is not changed.

=over 4

=item data - HashRef - the data to check

=item schema - HashRef - the schema, as L</DESCRIPTION> says

=item where - Str - names the data in an error, such as its file

=back

Returns HashRef, the copy.

Dies when the data does not match: the message starts with C<$where is not
valid:>, and then gives each error on a line of its own, as the JSON pointer
of the key and what is wrong with it, such as C</checks/ClaudeMd/file:
Expected string - got array.>

    my $data = Dist::Conformance::Schema::validate( { name => 'troglodyne' }, { type => 'object', properties => { name => $Dist::Conformance::Schema::NAME } }, 'conformance/troglodyne.yml' );

=head2 refuse($where, @errors)

Dies with the message of L<validate|/"validate($data, $schema, $where)">: C<$where is not valid:>, and then each
error on a line of its own.  For a check of the data that a schema cannot
express, so that its errors read as those of the schema.

=over 4

=item where - Str - names the data, such as its file

=item errors - Array - the errors, each as the JSON pointer of a key and what is wrong with it

=back

Returns nothing: it always dies.

    Dist::Conformance::Schema::refuse( '.conformance.yml', '/skip/0: names a check that the flavor troglodyne does not run' );

=head2 errors($data, $schema)

The errors of C<$data> against C<$schema>.  Fills in the defaults of
C<$schema> in C<$data>, and coerces its booleans, in place.

=over 4

=item data - HashRef - the data to check, which it changes

=item schema - HashRef - the schema

=back

Returns the errors, as a list of strings that each start with the JSON
pointer of the key, or an empty list.

    my @errors = Dist::Conformance::Schema::errors( $data, { type => 'object', required => ['name'] } );

=head2 matches($fragment, $value)

Whether C<$value> is defined and matches the C<pattern> of C<$fragment>, such
as L</$NAME>, in the way that JSON::Validator matches it.

=over 4

=item fragment - HashRef - a schema with a C<pattern>

=item value - Str|Undef - the value to match

=back

Returns Bool.

    my $ok = Dist::Conformance::Schema::matches( $Dist::Conformance::Schema::NAME, 'troglodyne' );

=head2 relative_path($path, $inside)

C<$path>, when it matches L</$PATH>.  Every read and write of a path that a
flavor names goes through it.

=over 4

=item path - Str|Undef - the path

=item inside - Str - what the path is inside, for the message, such as C<the checkout>

=back

Returns Str, C<$path>.

Dies with C<$path is not a relative path inside $inside> otherwise.

    my $path = Dist::Conformance::Schema::relative_path( 'templates/CLAUDE.md', 'the standards' );

=head2 parse_ini($text, $where)

The same as L<parse_yaml|/"parse_yaml($text, $where)">, for an INI file such as F<dist.ini>.  The keys
before the first header are in the section C<_>.  A key that a section gives
more than once, such as C<run> in C<[Run::Test]>, has the list of its values,
in order, as Dist::Zilla reads it.  Any other key has its value.

=over 4

=item text - Str - the INI text

=item where - Str - names the text in an error, such as its file

=back

Returns HashRef, of sections by their whole header, such as C<GithubMeta> or
C<Git::Commit / Release>, each a hash of its keys.

Dies with a message that starts with C<$where> when the text does not parse.

    my $ini = Dist::Conformance::Schema::parse_ini( "[GithubMeta]\nissues = 1\n", 'dist.ini' );

=head2 first_line($text)

The first line of an error from other code, without the "at FILE line N" that
perl adds to it, for a message that is about a file of the user and not about
a line of this code.  The errors of this distribution end in a newline, so
perl adds nothing to them.

=over 4

=item text - Str|Undef - the error

=back

Returns Str, the line, which is empty for an undefined error.

    my $line = Dist::Conformance::Schema::first_line($@);

=head1 SCHEMA FRAGMENTS

These package variables are pieces that the schemas of this distribution share.
A check module can use them in its own C<config_schema>.

=over

=item C<$NAME>

A name of a flavor or a check: a letter or digit, then letters, digits, C<.>,
C<_> or C<->.  A name never holds a C</>, so it can be a file name.

=item C<$PATH>

A relative path inside a repository or a standards source: not absolute, and
with no C<..> component.

=item C<$STATUS>

C<pass>, C<info> or C<fail>.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance>

=item *

L<JSON::Validator::Schema::OpenAPIv3>

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
