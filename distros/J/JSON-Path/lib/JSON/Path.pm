use 5.008;
use strict;
use warnings;

package JSON::Path;
$JSON::Path::VERSION = '0.420';
# VERSION

use Exporter::Tiny ();
our @ISA       = qw/ Exporter::Tiny /;
our $AUTHORITY = 'cpan:POPEFELIX';
our $Safe      = 1;

use Carp;
use JSON::MaybeXS qw/decode_json/;
use JSON::Path::Evaluator;
use Scalar::Util qw[blessed];
use LV ();

our @EXPORT_OK = qw/ jpath jpath1 jpath_map /;

use overload '""' => \&to_string;

sub jpath {
    my ( $object, $expression ) = @_;
    my @return = __PACKAGE__->new($expression)->values($object);
}

sub jpath1 : lvalue {
    my ( $object, $expression ) = @_;
    __PACKAGE__->new($expression)->value($object);
}

sub jpath_map (&$$) {
    my ( $coderef, $object, $expression ) = @_;
    return __PACKAGE__->new($expression)->map( $object, $coderef );
}

sub new {
    my ( $class, $expression ) = @_;
    return $expression
        if blessed($expression) && $expression->isa(__PACKAGE__);
    return bless \$expression, $class;
}

sub to_string {
    my ($self) = @_;
    return $$self;
}

sub paths {
    my ( $self, $object ) = @_;
    my @paths = JSON::Path::Evaluator::evaluate_jsonpath( $object, "$self", want_path => 1);
    return @paths;
}

sub get {
    my ( $self, $object ) = @_;
    my @values = $self->values($object);
    return wantarray ? @values : $values[0];
}

sub set {
    my ( $self, $object, $value, $limit ) = @_;

    if ( !ref $object ) {
        # warn if not called internally. If called internally (i.e. from value()) we will already have warned.
        my @c = caller(0);
        if ( $c[1] !~ /JSON\/Path\.pm$/ ) {
            carp qq{Useless attempt to set a value on a non-reference};
        }
    }
    my $count = 0;
    my @refs = JSON::Path::Evaluator::evaluate_jsonpath( $object, "$self", want_ref => 1 );
    for my $ref (@refs) {
        ${$ref} = $value;
        ++$count;
        last if $limit && ( $count >= $limit );
    }
    return $count;
}

sub value : lvalue {
    my ( $self, $object ) = @_;
    LV::lvalue(
        get => sub {
            my ($value) = $self->get($object);
            return $value;
        },
        set => sub {
            my $value = shift;
            # do some caller() magic to warn at the right place
            if ( !ref $object ) {
                my @c = caller(2);
                my ( $filename, $line ) = @c[ 1, 2 ];
                warn qq{Useless attempt to set a value on a non-reference at $filename line $line\n};
            }
            $self->set( $object, $value, 1 );
        },
    );
}

sub values {
    my ( $self, $object ) = @_;
    croak q{non-safe evaluation, died} if "$self" =~ /\?\(/ && $JSON::Path::Safe;

    return JSON::Path::Evaluator::evaluate_jsonpath( $object, "$self", script_engine => 'perl' );
}

sub map {
    my ( $self, $object, $coderef ) = @_;
    my $count;
    foreach my $path ( $self->paths( $object ) ) {
        my ($ref) = JSON::Path::Evaluator::evaluate_jsonpath( $object, $path, want_ref => 1 );
        ++$count;
        my $value = do {
            no warnings 'numeric';
            local $_ = ${$ref};
            local $. = $path;
            scalar $coderef->();
        };
        ${$ref} = $value;
    }
    return $count;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Path

=head1 VERSION

version 0.420

=head1 SYNOPSIS

 my $data = {
  "store" => {
    "book" => [ 
      { "category" =>  "reference",
        "author"   =>  "Nigel Rees",
        "title"    =>  "Sayings of the Century",
        "price"    =>  8.95,
      },
      { "category" =>  "fiction",
        "author"   =>  "Evelyn Waugh",
        "title"    =>  "Sword of Honour",
        "price"    =>  12.99,
      },
      { "category" =>  "fiction",
        "author"   =>  "Herman Melville",
        "title"    =>  "Moby Dick",
        "isbn"     =>  "0-553-21311-3",
        "price"    =>  8.99,
      },
      { "category" =>  "fiction",
        "author"   =>  "J. R. R. Tolkien",
        "title"    =>  "The Lord of the Rings",
        "isbn"     =>  "0-395-19395-8",
        "price"    =>  22.99,
      },
    ],
    "bicycle" => [
      { "color" => "red",
        "price" => 19.95,
      },
    ],
  },
 };
 
 use JSON::Path 'jpath_map';

 # All books in the store
 my $jpath   = JSON::Path->new('$.store.book[*]');
 my @books   = $jpath->values($data);
 
 # The author of the last (by order) book
 my $jpath   = JSON::Path->new('$..book[-1:].author');
 my $tolkien = $jpath->value($data);
 
 # Convert all authors to uppercase
 jpath_map { uc $_ } $data, '$.store.book[*].author';

=head1 DESCRIPTION

This module implements JSONPath, an XPath-like language for searching
JSON-like structures.

JSONPath is described at L<http://goessner.net/articles/JsonPath/>.

=head2 Constructor

=over 4

=item C<<  JSON::Path->new($string)  >>

Given a JSONPath expression $string, returns a JSON::Path object.

=back

=head2 Methods

=over 4

=item C<<  values($object)  >>

Evaluates the JSONPath expression against an object. The object $object
can be either a nested Perl hashref/arrayref structure, or a JSON string
capable of being decoded by JSON::MaybeXS::decode_json.

Returns a list of structures from within $object which match against the
JSONPath expression. In scalar context, returns the number of matches.

=item C<<  value($object)  >>

Like C<values>, but returns just the first value. This method is an lvalue
sub, which means you can assign to it:

  my $person = { name => "Robert" };
  my $path = JSON::Path->new('$.name');
  $path->value($person) = "Bob";

TAKE NOTE! This will create keys in $object. E.G.:

    my $obj = { foo => 'bar' };
    my $path = JSON::Path->new('$.baz');
    $path->value($obj) = 'bak'; # $obj->{baz} is created and set to 'bak';

=item C<<  paths($object)  >>

As per C<values> but instead of returning structures which match the
expression, returns canonical JSONPaths that point towards those structures.

=item C<<  get($object)  >>

In list context, identical to C<< values >>, but in scalar context returns
the first result.

=item C<<  set($object, $value, $limit)  >>

Alters C<< $object >>, setting the paths to C<< $value >>. If set, then
C<< $limit >> limits the number of changes made. 

TAKE NOTE! This will create keys in $object. E.G.:

    my $obj = { foo => 'bar' };
    my $path = JSON::Path->new('$.baz');
    $path->set($obj, 'bak'); # $obj->{baz} is created and set to 'bak'

Returns the number of changes made.

=item C<<  map($object, $coderef)  >>

Conceptually similar to Perl's C<map> keyword. Executes the coderef
(in scalar context!) for each match of the path within the object,
and sets a new value from the coderef's return value. Within the
coderef, C<< $_ >> may be used to access the old value, and C<< $. >>
may be used to access the curent canonical JSONPath.

=item C<<  to_string  >>

Returns the original JSONPath expression as a string.

This method is usually not needed, as the JSON::Path should automatically
stringify itself as appropriate. i.e. the following works:

 my $jpath = JSON::Path->new('$.store.book[*].author');
 print "I'm looking for: " . $jpath . "\n";

=back

=head2 Functions

The following functions are available for export, but are not exported
by default:

=over

=item C<< jpath($object, $path_string) >>

Shortcut for C<< JSON::Path->new($path_string)->values($object) >>.

=item C<< jpath1($object, $path_string) >>

Shortcut for C<< JSON::Path->new($path_string)->value($object) >>.
Like C<value>, it can be used as an lvalue.

=item C<< jpath_map { CODE } $object, $path_string >>

Shortcut for C<< JSON::Path->new($path_string)->map($object, $code) >>. 

=back

=head1 NAME

JSON::Path - search nested hashref/arrayref structures using JSONPath

=head1 PERL SPECIFICS

JSONPath is intended as a cross-programming-language method of
searching nested object structures. There are however, some things
you need to think about when using JSONPath in Perl...

=head2 JSONPath Embedded Perl Expressions

JSONPath expressions may contain subexpressions that are evaluated
using the native host language. e.g.

 $..book[?($_->{author} =~ /tolkien/i)]

The stuff between "?(" and ")" is a Perl expression that must return
a boolean, used to filter results. As arbitrary Perl may be used, this
is clearly quite dangerous unless used in a controlled environment.
Thus, it's disabled by default. To enable, set:

 $JSON::Path::Safe = 0;

There are some differences between the JSONPath spec and this
implementation.

=over 4

=item * JSONPath uses a variable '$' to refer to the root node.
This is not a legal variable name in Perl, so '$root' is used
instead.

=item * JSONPath uses a variable '@' to refer to the current node.
This is not a legal variable name in Perl, so '$_' is used
instead.

=back

=head2 Blessed Objects

Blessed objects are generally treated as atomic values; JSON::Path
will not follow paths inside them. The exception to this rule are blessed
objects where:

  Scalar::Util::blessed($object)
  && $object->can('typeof')
  && $object->typeof =~ /^(ARRAY|HASH)$/

which are treated as an unblessed arrayref or hashref appropriately.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

Specification: L<http://goessner.net/articles/JsonPath/>.

Implementations in PHP, Javascript and C#:
L<http://code.google.com/p/jsonpath/>.

Related modules: L<JSON>, L<JSON::JOM>, L<JSON::T>, L<JSON::GRDDL>,
L<JSON::Hyper>, L<JSON::Schema>.

Similar functionality: L<Data::Path>, L<Data::DPath>, L<Data::SPath>,
L<Hash::Path>, L<Path::Resolver::Resolver::Hash>, L<Data::Nested>,
L<Data::Hierarchy>... yes, the idea's not especially new. What's different
is that JSON::Path uses a vaguely standardised syntax with implementations
in at least three other programming languages.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 MAINTAINER

Kit Peters E<lt>popefelix@cpan.orgE<gt>

=head1 CONTRIBUTORS

Szymon Nieznański E<lt>s.nez@member.fsf.orgE<gt> 

Kit Peters E<lt>popefelix@cpan.orgE<gt>

Heiko Jansen E<lt>hjansen@cpan.orgE<gt>.

Mitsuhiro Nakamura E<lt>m.nacamura@gmail.comE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright 2007 Stefan Goessner.

Copyright 2010-2013 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=head2 a.k.a. "The MIT Licence"

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 AUTHOR

Kit Peters <kit.peters@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kit Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
