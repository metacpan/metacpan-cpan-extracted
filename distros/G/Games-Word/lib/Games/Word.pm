package Games::Word;
BEGIN {
  $Games::Word::AUTHORITY = 'cpan:DOY';
}
{
  $Games::Word::VERSION = '0.06';
}
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw/random_permutation is_permutation all_permutations
                    shared_letters shared_letters_by_position
                    random_string_from
                    is_substring all_substrings
                    is_subpermutation all_subpermutations/;

use Math::Combinatorics qw/factorial/;
use Test::Deep::NoTest;
# ABSTRACT: utility functions for writing word games


sub random_permutation {
    my $word = shift;

    return '' if $word eq '';

    my $letter = substr $word, int(rand length $word), 1, '';

    return $letter . random_permutation($word);
}


sub is_permutation {
    my @word_letters = split //, shift;
    my @perm_letters = split //, shift;

    return eq_deeply(\@word_letters, bag(@perm_letters));
}

sub _permutation {
    my $word = shift;
    my $perm_index = shift;

    return '' if $word eq '';

    my $len = length $word;
    die "invalid permutation index" if $perm_index >= factorial($len) ||
                                       $perm_index < 0;

    use integer;

    my $current_index = $perm_index / factorial($len - 1);
    my $rest = $perm_index % factorial($len - 1);

    my $first_letter = substr($word, $current_index, 1);
    substr($word, $current_index, 1) = '';

    return $first_letter . _permutation($word, $rest);
}


sub all_permutations {
    my $word = shift;

    my @ret = ();
    push @ret, _permutation($word, $_)
        for 0..(factorial(length $word) - 1);

    return @ret;
}


sub shared_letters {
    my @a = sort split //, shift;
    my @b = sort split //, shift;

    my @letters = ();
    my ($a, $b) = (shift @a, shift @b);
    while (defined $a && defined $b) {
        if ($a eq $b) {
            push @letters, $a;
            ($a, $b) = (shift @a, shift @b);
        }
        elsif ($a lt $b) {
            $a = shift @a;
        }
        else {
            $b = shift @b;
        }
    }

    return @letters;
}


sub shared_letters_by_position {
    my @a = split //, shift;
    my @b = split //, shift;

    my @letters = ();
    while (my ($a, $b) = (shift @a, shift @b)) {
        last unless (defined $a || defined $b);
        if (defined $a && defined $b && $a eq $b) {
            push @letters, $a;
        }
        else {
            push @letters, undef;
        }
    }

    return wantarray ? @letters : grep { defined } @letters;
}


sub random_string_from {
    my ($letters, $length) = @_;

    die "invalid letter list" if length $letters < 1 && $length > 0;
    my @letters = split //, $letters;
    my $ret = '';
    $ret .= $letters[int rand @letters] for 1..$length;

    return $ret;
}


sub is_substring {
    my ($substring, $string) = @_;

    return 1 if $substring eq '';
    return 0 if $string eq '';
    my $re = join('?', map { quotemeta } split(//, $string)) . '?';
    return $substring =~ /^$re$/;
}


sub all_substrings {
    my $string = shift;

    return ('') if $string eq '';

    my @substrings = ($string);
    my $before = '';
    my $current = substr $string, 0, 1, '';
    while ($current) {
        @substrings = (@substrings,
                       map { $before . $_ } all_substrings($string));
        $before .= $current;
        $current = substr $string, 0, 1, '';
    }

    return @substrings;
}


sub is_subpermutation {
    my @subword = split //, shift;
    my @word = split //, shift;

    return eq_deeply(\@subword, subbagof(@word));
}


sub all_subpermutations {
    return map { all_permutations $_ } all_substrings shift;
}


1;

__END__
=pod

=head1 NAME

Games::Word - utility functions for writing word games

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Games::Word;
    print "permutation!\n" if is_permutation 'word', 'orwd';
    my $mm_solution = random_string_from "abcdefgh";
    my $mm_guess = <>;
    chomp $mm_guess;
    my $mm_correct_letters = shared_letters $mm_solution, $mm_guess;
    my $mm_correct_positions = shared_letters_by_position $mm_solution,
                                                          $mm_guess;

=head1 DESCRIPTION

Games::Word provides several utility functions for writing word games, such as
manipulating permutations of strings, testing for similarity of strings, and
finding strings from a given source of characters.

=over 4

=item random_permutation STRING

Returns a string which is a random permutation of the letters in STRING.

=item is_permutation STRING1, STRING2

Returns true of STRING1 is a permutation of STRING2, and false otherwise.

=item all_permutations STRING

Returns a list containing all permutations of the characters in STRING.

=item shared_letters STRING1 STRING2

Returns a list of the characters that STRING1 and STRING2 have in common,
ignoring their position in the string.

=item shared_letters_by_position STRING1 STRING2

In list context, returns a list that is the length of the larger of STRING1 and
STRING2, which contains the character at that position in both strings if they
are the same, and undef otherwise.

In scalar context, returns the number of characters that are the same in both
value and position between STRING1 and STRING2.

=item random_string_from STRING LENGTH

Uses STRING as an alphabet to generate a random string of length LENGTH.
Characters in STRING may be repeated.

=item is_substring SUBSTRING STRING

Returns true if SUBSTRING consists of only characters from STRING, in order.
For example, 'word' is a substring of 'awobbrcd', but not of 'dcrbbowa' or
'awbbrcd'.

=item all_substrings STRING

Returns a list of all substrings (see
L<is_substring|/"is_substring SUBSTRING STRING">) of STRING.

=item is_subpermutation SUBSTRING STRING

Returns true if SUBSTRING is a subpermutation (like
L<is_substring|/"is_substring SUBSTRING STRING">, but without caring about
order) of STRING, and false otherwise.

=item all_subpermutations STRING

Like L<all_substrings|/"all_substrings STRING">, except using
L<is_subpermutation|/"is_subpermutation SUBSTRING STRING"> instead.

=back

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-games-word at rt.cpan.org>, or browse
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Word>.

=head1 SEE ALSO

L<Games::Word::Wordlist>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Games::Word

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Word>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Word>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Word>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Word>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

