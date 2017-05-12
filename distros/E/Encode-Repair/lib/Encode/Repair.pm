package Encode::Repair;
our $VERSION = '0.0.2';
use strict;
use warnings;

our @EXPORT_OK = qw(repair_double learn_recoding repair_encoding);
use Exporter qw(import);
use Encode qw(encode decode);
use Algorithm::Loops qw(NestedLoops MapCar);

# since Algorithm::Loops already provides MapCar, it is very easy to implement
# zip() with it, instead of introducing another dependency (on
# List::MoreUtils, specifically)
sub zip {
    MapCar {  @_ == 2 ? @_ : () } @_;
}

my %subs = (
    encode  => \&encode,
    decode  => \&decode,
);

sub repair_encoding {
    my ($str, $actions) = @_;
    for (my $i = 0; $i < @$actions; $i += 2) {
        my $type     = $actions->[$i];
        my $encoding = $actions->[$i+1];
        no warnings 'utf8';
        $str = $subs{$type}->($encoding, $str);
    }
    $str;
}

sub repair_double {
    my ($buf, $options) = @_;
    my $via = 'ISO-8859-1';
    $via = $options->{via} if $options && exists $options->{via};
    repair_encoding($buf, [
            'decode', 'UTF-8',
            'encode', $via,
            'decode', 'UTF-8',
    ]);
}

sub learn_recoding {
    my %args        = @_;
    my $source      = $args{from};
    my $target      = $args{to};
    my $encodings   = $args{encodings};
    my $maxdepth    = $args{depth} || 5;
    my $search_mode = $args{search} || 'first';
    return [] if $source eq $target;

    my @result;
    for my $depth (1..$maxdepth) {
        my $iter = NestedLoops( [($encodings) x $depth] );
        my @ed   =  (qw(encode decode)) x (int($depth / 2) + 1);
        my @de   =  (qw(decode encode)) x (int($depth / 2) + 1);
        while (my @steps = $iter->()) {
            no warnings 'uninitialized';
            for my $steps ([zip \@ed, \@steps], [zip \@de, \@steps]) {
#                use Data::Dumper;
#                warn Dumper($steps);
                if (eval {repair_encoding($source, $steps)} eq $target) {
                    if (lc($search_mode) eq 'first') {
                        return $steps;
                    } else {
                        push @result, $steps;
                    }
                }
            }
        }
        return \@result if @result && lc($search_mode) eq 'shallow';
    }
    return \@result if @result;
    return;
}

1;

=encoding utf-8

=head1 NAME

Encode::Repair - Repair wrongly encoded text strings

=head1 SYNOPSIS

    # Simple usage
    use Encode::Repair qw(repair_double);
    binmode STDOUT, ':encoding(UTF-8)';

    # prints: small ae: ä
    print repair_double("small ae: \xc3\x83\xc2\xa4\n");

    # prints: beta: β
    print repair_double("beta: \xc4\xaa\xc2\xb2\n", {via => 'Latin-7'});


    # Advanced usage
    # assumes you have a sample text both correctly decoded in a
    # character string, and as a wrongly encoded buffer

    use Encode::Repair qw(repair_encoding learn_recoding);
    use charnames qw(:full);
    binmode STDOUT, ':encoding(UTF-8)';

    my $recoding_pattern  = learn_recoding(
        from        => "beta: \xc4\xaa\xc2\xb2",
        to          => "beta: \N{GREEK SMALL LETTER BETA}",
        encodings   => ['UTF-8', 'Latin-1', 'Latin-7'],
    );
    if ($recoding_pattern) {
        my $mojibake = "\304\252\302\273\304\252\302\261\304\252\302"
                    ."\274\304\252\342\200\234\304\252\302\261";
        print repair_encoding($mojibake, $recoding_pattern), "\n";
    } else {
        print "Sorry, could not help you :-(\n";
    }


=head1 DESCRIPTION

Sometimes software or humans mess up the character encoding of text. In some
cases it is possible to reconstruct the original text. This module helps you
to do it.

It covers the rather common case that a program assumes a wrong character
encoding on reading some input, and converts it to Mojibake (see
L<http://en.wikipedia.org/wiki/Mojibake>).

If you use this module on a regular basis, it most likely indicates that
something is wrong in your processs. It should only be used for one-time tasks
such as migrating a database to a new system.

=head1 FUNCTIONS

=over

=item repair_double

Repairs the common case when a UTF-8 string was read as another encoding,
and was encoded as UTF-8 again. The other encoding defaults to ISO-8859-1 aka
Latin-1, and can be overridden with the C<via> option:

    my $repaired = repair_double($buffer, {via => 'ISO-8859-2' });

It expects an octet string as input, and returns a decoded character string.

=item learn_recoding

Given a sample of text twice, once correctly decoded and once mistreated,
attemps to find a sequence of encoding and decoding that turns the mistreated
text into the correct form.

    my $coding_pattern = learn_recoding(
        from        => $mistreated_buffer,
        to          => $correct_string,
        encodings   => \@involved_encodings,
        depth       => 5,
        search      => 'first',
    );

C<encodings> should be an array reference containing all the character
encodings involved in the process that messes up the encoding. If you don't
know these, try it with C<UTF-8>, C<ISO-8859-1> and the encoding that your
system uses by default.

C<depth> is the maximal number of encoding and decoding steps to be tried. For
example C<repair_double> needs three steps. Defaults to 5; higher values might
slow down the program significantly, although smaller depths are tried first.

The return value is C<undef> on failure, and an array reference otherwise. It
returns the encoding/decoding steps suitable for feeding into C<repair_encoding>.
It contains a list of even size, where elements with even indexes are either
C<'encode'> or C<'decode'>, and those with odd indexes contain the name of the
encoding.

With C<search> you can adjust how long the function searches for a recoding
sequence.
WIth the default of C<'first'> it returns the first possible sequence. With
C<'shallow'> it searches for the first working sequence and all other
sequences of the same length, and then returns an array reference containing
array references to all sequences. With the value C<'all'>, all possible
sequences are searched and returned, but often that's a very bad idea, because
it also finds sequences where parts of the sequence undo the work of other
sequences (something like C<[qw(encode latin-1 decode latin-1)]>).

Since Version 0.0.2 C<learn_recoding> forces strict pattern of alternatining
encoding and decoding. So even if C<['decode', 'UTF-8', 'decode', 'UTF-8']> is
a working input, C<learn_recoding> will return C<['decode', 'UTF-8', 'encode',
'Latin-1', 'decode', 'UTF-8']> instead. So you might have to include C<Latin-1>
in your encoding list even if it is not strictly involved.

=item repair_encoding

Takes an input string and an encoding/decoding pattern (as returned from
C<learn_recoding>) as input and returns the repaired string.

=back

=head1 Troubleshooting

If C<learn_recoding> returns C<undef>, you can increase the C<depth> option
value (for example to 7). If that doesn't help, check that the two input
strings actually corespond. C<learn_recoding> does an exact equality check, so
trailing newline characters or spaces will cause it to fail.

If C<repair_encoding> produces errors or warnings, it is likely that the sample
you used for learning was not long enough, or not representative. For example
if your system uses both ISO-8859-1 and ISO-8859-15 (which are quite similar),
C<learn_recoding> uses the first match, so the sample data has to contain at
least one character that's in ISO-8859-15 but not in ISO-8859-1, like the
Euro sign (€).

=head1 Further Reading

This document tries to stick to the terminology introduced in the L<Encode>
module.

If you want to learn more about the way text is encoded and how perl handles
that, take a look at L<http://perlgeek.de/en/article/encodings-and-unicode>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008, 2009 by Moritz Lenz, L<http://perlgeek.de/>,
moritz@faui2k3.org.

This is free software; you my use it under the terms of the Artistic License 2
as published by The Perl Foundation.

The code examples distributed with this package are an exception, and may be
used, modified and redistributed without any limitations.

Encode::Repair is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=head1 Development

The source code is stored in a public git repository at
L<http://github.com/moritz/Encode-Repair>. If you find any bugs, please used the
issue tracker linked from this site.

If you find a case of messed-up encodings that can be repaired deterministically
and that's not covered by this module, please contact the author, providing a
hex dump of both input and output, and as much information of the encoding and
decoding process as you have.

Patches are also very welcome.

=cut
