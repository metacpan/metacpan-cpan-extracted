package Math::Cryptarithm;

use 5.034000;
use strict;
use warnings;
use Algorithm::Permute;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.

sub new {
    my ($class) = @_;
    bless {
        _equations => $_[1]
    }, $class;
}

sub _check_syntax_of_an_equation {
    my $equation = $_[0];
    # to be written
    return 1;
}

sub _seperate_lhs_rhs {
    my $eq_text = $_[0];
    my $i = index($eq_text, "=");
    return [ substr($eq_text, 0, $i ), substr($eq_text, $i+1) ];
}

sub _replacement {
    my $original_text = $_[0];
    my $text = $_[0];
    my @arr_ab = @{$_[1]};
    my @arr_digits = @{$_[2]};
    for (0..$#arr_digits) {
        $text =~ s/$arr_ab[$_]/$arr_digits[$_]/g;
    }

    #BEGIN: cut leading zeros
    substr($text,0,1) = " " 
        if substr($text,0,1) eq '0' && substr($text,1,1) =~ m/[0-9]/;
    for my $i (1..(length($text) - 2) ) {
        if (    substr($text,$i,1) eq '0' 
             && substr($text,$i-1,1) !~ m/[1-9]/
             && substr($text,$i+1,1) =~ m/\d/ ) 
        { 
            substr($text,$i,1) = " ";
        }
    }
    #END cut leading zeros
    return $text;
}

sub _list_alphabets {
    my @eq = @{$_[0]};
    my %abcdz;
    for my $symbol ('A'..'Z') {
        for my $e (@eq) {
            $abcdz{$symbol} = 1 if $e =~ m/$symbol/;
        }
    }
    return [sort keys %abcdz];
}

sub equations {
    $_[0]->{_equations};
}

sub solve {
    my ($self) = @_;
    my @eqs = @{$self->equations};
    my @answers = ();

    _check_syntax_of_an_equation($_) foreach @eqs;

    my @eqs_lhs, my @eqs_rhs;
    foreach (@eqs) {
        my $temp_l, my $temp_r;
        ($temp_l, $temp_r) = _seperate_lhs_rhs($_)->@*;
        push @eqs_lhs, $temp_l;
        push @eqs_rhs, $temp_r;
    }

    my @arr_alphabets = _list_alphabets(\@eqs)->@*;
    my $num_of_alphabets = scalar @arr_alphabets; 

    my $iter = Algorithm::Permute->new([0..9], $num_of_alphabets);
    COMBIN_TEST: while (my @res = $iter->next) {
        my $ok = undef;
        for my $i (0..$#eqs) {
            $ok = undef;
            my $str_lhs = 
                _replacement( $eqs_lhs[$i] , \@arr_alphabets, \@res );
            my $str_rhs = 
                _replacement( $eqs_rhs[$i] , \@arr_alphabets, \@res );
            my $val_lhs = eval $str_lhs;
            my $val_rhs = eval $str_rhs;
            die "LHS is not numeric:\n $eqs_lhs[$i]\n\"$str_lhs\"\n" 
                if $val_lhs  !~ m/^[0-9]+$/;
            die "RHS is not numeric:\n $eqs_rhs[$i]\n\"$str_rhs\"\n" 
                if $val_rhs !~ m/^[0-9]+$/;
            next COMBIN_TEST unless $val_lhs == $val_rhs;
            $ok = 1;
        }
        if ($ok) {
            my %temp_hash;
            for my $i (0..$num_of_alphabets-1) {
                $temp_hash{$arr_alphabets[$i]} = $res[$i];
            }
            push @answers, \%temp_hash;
        }
    }
    return \@answers;
}

sub solve_ans_in_equations {
    my ($self) = @_;
    my @eqs = @{$self->equations};
    my @answers_of_hashes = $self->solve()->@*;
    my @answers_in_eq;
    for my $my_hash (@answers_of_hashes) {
        my @a_set_of_answer_in_eq;
        for my $crypt_eq (@eqs) {
            my $numeric_eq = $crypt_eq;
            foreach my $k (keys %{$my_hash}) {
                my $digit = $$my_hash{$k};
                $numeric_eq =~ s/$k/$digit/g;
            } 
            push @a_set_of_answer_in_eq, $numeric_eq;
        }
        push @answers_in_eq, \@a_set_of_answer_in_eq;
    }
    return \@answers_in_eq;
}

1;
__END__

=head1 NAME

Math::Cryptarithm - Solving simple cryptarithm.


=head1 VERSION

Version 0.02


=head1 DESCRIPTION

A primitive cryptarithm (also known as verbal arithmetic) solver.

See L<English Wikipedia: Verbal arithmetic|https://en.wikipedia.org/wiki/Verbal_arithmetic>.


=head1 SYNOPSIS

    use Math::Cryptarithm;
    use Data::Dumper;

    my $abc5 = ["A + B = C5 ", "A % 2 = 0"];

    my $abc5_ans_in_eqs = Math::Cryptarithm->new($abc5)->solve_ans_in_equations();

    for my $set ($abc5_ans_in_eqs->@*) { 
        print join "\n", @{$set};
        print "\n\n"
    }

    # 2 + 3 = 05 
    # 2 % 2 = 0
    # 
    # 4 + 1 = 05 
    # 4 % 2 = 0
    #
    # 8 + 7 = 15 
    # 8 % 2 = 0
    #
    # 6 + 9 = 15 
    # 6 % 2 = 0


    my $abcd = [
        "ABA * ABA = CCDCC", 
        "ABA * A = CAC", 
        "ABA * B = ABA"
    ];

    my $abcd_ans = Math::Cryptarithm->new($abcd)->solve();

    say scalar $abcd_ans->@*;             # 1
    say $abcd_ans->[0]->{"A"};            # 2
    say $abcd_ans->[0]->{"B"};            # 1
    say $abcd_ans->[0]->{"C"};            # 4
    say $abcd_ans->[0]->{"D"};            # 9 


    my $magical_seven = ["ABCDEF * 6 = DEFABC"];
    my $magical_seven_ans = Math::Cryptarithm->new($magical_seven)->solve();

    print Dumper($magical_seven_ans);

    # $VAR1 = [ { 'A' => 1, 'F' => 7, 'E' => 5, 'B' => 4,'D' => 8, 'C' => 2 ];


=head1 METHODS

=head2 solve()

Return a list object of hashes with all possible solutions. Different letters represent different digits.

=head2 solve_ans_in_equations()

Return the possible solutions in "decrypted equations" form. See the section Synopsis.

=head1 TODOS

=head2 Improve the Module by Backtracking instead of Permutations

Currently the module runs slowly when the number of variables is equal to or more than 6. Using a backtracking as the algorithm should improve the performance of the module.

=head2 setRep($symbol)

To determine whether allow repetitions. 1 is no repetitions. 0 means repetitions are allowed. Default should be 1.

=head2 setLeadingZeros($symbol)

To determine whether allow zeros as possible values as the leading part of a number. 1 is allowed. 0 means not allowed. Default should be 1.

=head1 AUTHOR

Cheok-Yin Fung, <fungcheokyin at gmail.com>

=head1 REPOSITORY

L<https://github.com/E7-87-83/Math-Cryptarithm|https://github.com/E7-87-83/Math-Cryptarithm>.

=head1 COPYRIGHT & LICENSE

Copyright 2021 FUNG CHEOK YIN, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the
terms of the the Artistic License (2.0).
=cut
