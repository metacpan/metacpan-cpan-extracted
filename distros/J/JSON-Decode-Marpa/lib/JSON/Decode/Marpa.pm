package JSON::Decode::Marpa;

our $DATE = '2014-08-27'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use MarpaX::Simple qw(gen_parser);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(from_json);

my $parser = gen_parser(
    grammar => <<'EOF',
:default     ::= action => do_array

:start       ::= json

json         ::= object action => do_first
               | array action => do_first

object       ::= ('{') members ('}') action => do_hash

members      ::= pair*                 separator => <comma>

pair         ::= string (':') value

value        ::= string action => do_first
               | object action => do_first
               | number action => do_first
               | array action => do_first
               | 'true' action => do_true
               | 'false' action => do_false
               | 'null' action => do_undef


array        ::= ('[' ']')
               | ('[') elements (']') action => do_first

elements     ::= value+                separator => <comma>

number         ~ int
               | int frac
               | int exp
               | int frac exp

int            ~ digits
               | '-' digits

digits         ~ [\d]+

frac           ~ '.' digits

exp            ~ e digits

e              ~ 'e'
               | 'e+'
               | 'e-'
               | 'E'
               | 'E+'
               | 'E-'

string ::= <string lexeme> action => do_string

<string lexeme> ~ quote <string contents> quote
# This cheats -- it recognizers a superset of legal JSON strings.
# The bad ones can sorted out later, as desired
quote ~ ["]
<string contents> ~ <string char>*
<string char> ~ [^"\\] | '\' <any char>
<any char> ~ [\d\D]

comma          ~ ','

:discard       ~ whitespace
whitespace     ~ [\s]+
EOF
    actions => {
        do_array  => sub { shift; [@_] },
        do_hash   => sub { shift; +{map {@$_} @{ $_[0] } } },
        do_first  => sub { $_[1] },
        do_undef  => sub { undef },
        do_string => sub {
            shift;

            my($s) = $_[0];

            $s =~ s/^"//;
            $s =~ s/"$//;

            $s =~ s/\\u([0-9A-Fa-f]{4})/chr(hex($1))/eg;

            $s =~ s/\\n/\n/g;
            $s =~ s/\\r/\r/g;
            $s =~ s/\\b/\b/g;
            $s =~ s/\\f/\f/g;
            $s =~ s/\\t/\t/g;
            $s =~ s/\\\\/\\/g;
            $s =~ s{\\/}{/}g;
            $s =~ s{\\"}{"}g;

            return $s;
        },
        do_true   => sub { 1 },
        do_false  => sub { 0 },
    },
);

sub from_json {
    $parser->(shift);
}

1;
# ABSTRACT: JSON parser using Marpa

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Decode::Marpa - JSON parser using Marpa

=head1 VERSION

This document describes version 0.02 of JSON::Decode::Marpa (from Perl distribution JSON-Decode-Marpa), released on 2014-08-27.

=head1 SYNOPSIS

 use JSON::Decode::Marpa qw(from_json);
 my $data = from_json(q([1, true, "a", {"b":null}]));

=head1 DESCRIPTION

This module is based on L<MarpaX::Demo::JSONParser> (using C<json.2.bnf>), but
offers a more convenient interface for JSON decoding. I packaged this for casual
benchmarking against L<Pegex::JSON> and L<JSON::Decode::Regexp>.

The result on my computer: Pegex::JSON and JSON::Decode::Marpa are roughly the
same speed (but Pegex has a much smaller startup overhead than Marpa).
JSON::Decode::Regexp is about an order of magnitude faster than this module, and
JSON::XS is about I<three orders of magnitude> faster. So that's that.

This is the benchmark code used:

 use 5.010;
 use strict;
 use warnings;

 use Benchmark qw(timethese);
 use JSON::Decode::Marpa ();
 use JSON::Decode::Regexp ();
 use JSON::XS ();
 use Pegex::JSON;

 my $json = q([1,"abc\ndef",-2.3,null,[],[1,2,3],{},{"a":1,"b":2}]);
 my $pgx  = Pegex::JSON->new;

 timethese -0.5, {
     pegex  => sub { $pgx->load($json) },
     regexp => sub { JSON::Decode::Regexp::from_json($json) },
     marpa  => sub { JSON::Decode::Marpa::from_json($json) },
     xs     => sub { JSON::XS::decode_json($json) },
 };

=head1 FUNCTIONS

=head2 from_json($str) => DATA

Decode JSON in C<$str>. Dies on error.

=head1 FAQ

=head1 SEE ALSO

L<JSON>, L<JSON::PP>, L<JSON::XS>, L<JSON::Tiny>, L<JSON::Decode::Regexp>,
L<Pegex::JSON>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/JSON-Decode-Marpa>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-JSON-Decode-Marpa>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=JSON-Decode-Marpa>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
