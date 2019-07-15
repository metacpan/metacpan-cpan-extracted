package Hash::Key::Quote;

our $DATE = '2019-07-10'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       should_quote_hash_key
               );

sub should_quote_hash_key {
    my $str = shift;
    return 0 if $str =~ /\A-?[A-Za-z_]\w*\z/;
    return 0 if $str =~ /\A-?[1-9]\d{0,8}\z/;
    # TODO: floating point like 123.1, 1.23456789 or -12345678.9
    1;
}

1;
# ABSTRACT: Utility routines related to quoting of hash keys

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Key::Quote - Utility routines related to quoting of hash keys

=head1 VERSION

This document describes version 0.002 of Hash::Key::Quote (from Perl distribution Hash-Key-Quote), released on 2019-07-10.

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 should_quote_hash_key($str) => bool

Return true if C<$str> should be quoted as a hash key when placed before the fat
comma (C<< => >>) operator. According to the L<perlop> documentation:

 The "=>" operator (sometimes pronounced "fat comma") is a synonym for the comma
 except that it causes a word on its left to be interpreted as a string if it
 begins with a letter or underscore and is composed only of letters, digits and
 underscores. This includes operands that might otherwise be interpreted as
 operators, constants, single number v-strings or function calls. If in doubt
 about this behavior, the left operand can be quoted explicitly.

This means strings like C<"and"> or C<"v1"> need not be quoted.

But there are several other cases where a string needs not be quoted. For
example, numbers except in these cases:

 012        # perl will interpret it as a positive octal literal
 -012       # perl will interpret it as a negative octal literal
 1_000_000  # perl will strip the underscores from number
 -1_000_000 # ditto
 1_0e10     # ditto
 -1_0e10    # ditto
 +123       # perl will strip the + sign
 -+123      # ditto
 1e2        # perl will normalize it to "100"
 1_00a      # not a valid number, must be quoted

Another example is non-number string that begins with a dash and followed only
by letters/numbers/underscores, e.g. C<-foo>.

For simplicity, you should probably just always quote. But if you only want to
quote when necessary, this routine can help you.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Hash-Key-Quote>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Hash-Key-Quote>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Key-Quote>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perlop>

L<Data::Dump> from which this code is extracted.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
