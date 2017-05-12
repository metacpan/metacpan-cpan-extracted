# $Id: BonDigi.pm 16 2008-01-13 14:22:02Z Cosimo $

package Test::Games::BonDigi;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Games::BonDigi;

our $VERSION = '0.02';

sub iterator_default : Test(114)
{

    my $obj = Games::BonDigi->new();
    isa_ok($obj, 'Games::BonDigi', 'class constructor');

    can_ok($obj, 'sequence');
    my $iter = $obj->sequence();
    ok(ref $iter eq 'CODE', 'Iterator with object');

    my $iter2 = Games::BonDigi->sequence();
    ok(ref $iter2 eq 'CODE', 'Iterator with class');

    my $word = $iter->();
    is($iter2->(), $word, 'class/object iterators are equivalent');

    # Test iterator fixed part
    is($word, 'bon',      'Header: first word is "bon"');
    is($iter->(), 'digi', 'Header: then "digi"');
    is($iter->(), 'bon',  'Header: then "bon" again');
    is($iter->(), 'digi', 'Header: then "digi" again');

    # Payload 
    is($iter->(), 'bon',  'Payload: "bon"');
    is($iter->(), 'bon',  'Payload: "bon" again');
    is($iter->(), 'digi', 'Payload: "digi"');
    is($iter->(), 'digi', 'Payload: "digi" again');

    # Restart
    is($iter->(), 'bon',  'Restart of sequence: "bon"');

    # Sequence must be uninterrupted
    my $words_re = qr/bon|digi/;
    for(1 .. 100)
    {
        like($iter->(), $words_re, 'next ' . $_ . ' word is correct');
    }

    return;
}

sub iterator_custom : Test(16)
{
    my $obj = Games::BonDigi->new();
    isa_ok($obj, 'Games::BonDigi', 'class constructor');

    # Start with 2 repeats, end at 5, words are: x, y
    my $iter = $obj->sequence(2, 5, qw(x y));
    ok(ref $iter eq 'CODE', 'Custom iterator with object');
    
    my $iter2 = Games::BonDigi->sequence(2, 5, qw(x y));
    ok(ref $iter2 eq 'CODE', 'Custom iterator with class');

    # Iterator sequence must stop at 5
    my @seq = ();

    # Detect infinite loops (broken iterator)
    eval
    {
        local $SIG{ALRM} = sub { die 'Endless loop' };
        alarm 5;
        while(my $word = $iter->())
        {
            push @seq, $word;
        }
        alarm 0;
    };

    unlike($@, qr/Endless loop/, 'iterator correctly stops at given endpoint');

    # Test iterator fixed part
    is($seq[0], 'x', 'first word is "x"');
    is($seq[1], 'y', 'then "y"');
    is($seq[2], 'x', 'then "x" again');
    is($seq[3], 'y', 'then "y" again');

    # Payload 
    is($seq[4], 'x',  'Payload: "x"');
    is($seq[5], 'x',  '"x" again');
    is($seq[6], 'y', 'Payload: "y"');
    is($seq[7], 'y', '"y" again');

    # Sanity tests on generated sequence
    is(scalar(@seq), 4 * 4 + (2 + 3 + 4 + 5) * 2, 'sequence was generated exactly, no less and no more');
    is($seq[$#seq], 'y', 'last element must be "y"');

    # Same number of 'x' and 'y' must have been generated
    my $num_x = 0;
    my $num_y = 0;

    for(@seq)
    {
        if($_ eq 'x')    { $num_x++ }
        elsif($_ eq 'y') { $num_y++ }
    }

    is($num_x, $num_y, '"x" elements == "y" elements');
    is($num_x + $num_y, scalar(@seq), 'only "x" and "y" have been generated');

    return;
}

1;

__END__

=head1 NAME

Test::Games::BonDigi

=head1 ABSTRACT

Testing class for Games::BonDigi. Uses Test::Class.

=head1 SYNOPSIS

Don't use that.

=head1 DESCRIPTION

Testing class for Games::BonDigi.
Uses Test::Class framework.

=head1 DEDICATION

To Q&A Departments in all the planet.

=head1 METHODS

=over

=item C<iterator_default()>

Tests iterator behaviour in default case, when no parameters
are passed to the C<sequence()> method.

=item C<iterator_custom()>

Tests customized iterator behaviour, when you pass your parameters to
the C<sequence()> method. Check out C<Games::BonDigi> class
documentation for the C<sequence()> method.

=back

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Cosimo Streppone.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> in Perl 5.8.1 or later.

=cut
