package Lingua::JA::Categorize::Result;
use strict;
use warnings;
use List::Util qw(sum);
use base qw( Lingua::JA::Categorize::Base );

sub word_set {
    my $self     = shift;
    my $word_set = $self->{word_set};
    my @list;
    for ( sort { $word_set->{$b} <=> $word_set->{$a} } keys %$word_set ) {
        push( @list, { $_ => $word_set->{$_} } );
    }
    return \@list;
}

sub score {
    my $self = shift;
    my $num  = shift;
    $num ||= 3;
    unless ( $self->word_set->[0] ) {
        return undef;
    }
    my $score = $self->{score};
    my @list;
    my $i = 0;
    for ( sort { $score->{$b} <=> $score->{$a} } keys %$score ) {
        push( @list, { $_ => $score->{$_} } ) if $score->{$_} > 0;
        $i++;
        last if ( $i == $num );
    }
    return \@list;
}

sub confidence {
    my $self = shift;

    # マッチor ノーマッチによる確信度計算
    my $match_word_point = $self->_match_word_point;

    # エントロピーによる確信度計算
    my $entropy_point = $self->_entropy_point;

    # 距離計算
    my $v3             = $self->_distance_point(3);
    my $v10            = $self->_distance_point(10);
    my $distance_point = 1 - $v3 / $v10;

    # 線形結合（重みは適当）
    my $w1 = 5;
    my $w2 = 1;
    my $w3 = 1;
    my $confidence_point
        = (   $w1 * $match_word_point 
            + $w2 * $entropy_point
            + $w3 * $distance_point ) / ( $w1 + $w2 + $w3 );

    #print "M:", $match_word_point, "\n";
    #print "E:", $entropy_point,    "\n";
    #print "D:", $distance_point,   "\n";

    return $confidence_point;

}

sub _distance_point {
    my $self  = shift;
    my $n     = shift || 3;
    my $brain = $self->context->categorizer->brain;
    my @categories
        = map { keys %$_; } @{ $self->score($n) };

    # 必要なデータを抽出
    my $data;
    for (@categories) {
        $data->{$_} = $brain->{training_data}->{labels}->{$_}->{attributes};
    }

    # 重心を測定
    my $centroid;
    my %counter;
    my %sum;
    while ( my ( $label, $ref ) = each(%$data) ) {
        while ( my ( $attr, $score ) = each(%$ref) ) {
            $counter{$attr}++;
            $sum{$attr} += $score;
        }
    }
    while ( my ( $key, $value ) = each(%sum) ) {
        $centroid->{$key} = $value / $counter{$key};
    }

    # 重心からの平均距離を求める
    my @array;
    for (@categories) {
        my $p = $data->{$_};
        my $distance = $self->_distance( $centroid, $p );
        push( @array, $distance );
    }
    my $avg = sum(@array) / int( keys %$data );
    return $avg;
}

sub _distance {
    my $slef  = shift;
    my $arg1  = shift;
    my $arg2  = shift;
    my %hash1 = %$arg1;
    my %hash2 = %$arg2;
    my $sum;
    while ( my ( $attr, $score ) = each(%hash1) ) {
        my $d = $score;
        if ( my $score2 = delete $hash2{$attr} ) {
            $d = $score - $score2;
        }
        else {
        }
        $sum += ( $d**2 );
    }
    while ( my ( $attr, $score ) = each(%hash2) ) {
        $sum += ( ( 0 - $score )**2 );
    }
    return sqrt($sum);
}

sub _match_word_point {
    my $self     = shift;
    my $match    = 0;
    my $no_match = 0;
    if ( $self->matches ) {
        for ( @{ $self->matches } ) {
            $match += $self->{word_set}->{$_};
        }
    }
    if ( $self->no_matches ) {
        for ( @{ $self->no_matches } ) {
            $no_match += $self->{word_set}->{$_};
        }
    }
    my $ratio = $match / ( $match + $no_match );
    return $ratio;
}

sub _entropy_point {
    my $self = shift;
    my @scores
        = map { values %$_; } @{ $self->score(5) };
    my $sum = sum(@scores);
    my $e   = 0;
    my ( $p, $z );
    for (@scores) {
        if ( $_ > 0 ) {
            $p = $_ / $sum;
            $z = -$p * $self->_log2($p);
            $e += $z;
        }
    }
    my $we    = 2**$e;
    my $max   = int @scores;
    my $scale = 1000;
    my $ee    = $self->_log2( ( $max - $we ) * $scale );
    my $e_max = $self->_log2( $max * $scale );
    return $ee / $e_max;
}

sub _log2 {
    my $self = shift;
    my $n    = shift;
    log($n) / log(2);
}

sub no_matches {
    my $self       = shift;
    my $no_matches = $self->{no_matches};
    return $no_matches;
}

sub matches {
    my $self    = shift;
    my $matches = $self->{matches};
    return $matches;
}

sub user_extention {
    my $self           = shift;
    my $user_extention = $self->{user_extention};
    return $user_extention;
}

1;
__END__

=head1 NAME

Lingua::JA::Categorize::Result - Result of L::J::C working 

=head1 SYNOPSIS

  use Lingua::JA::Categorize::Result;

  my $result = Lingua::JA::Categorize::Result->new(word_set => $word_set, score => $score);
  print Dumper $result->score;
  print Dumper $result->word_set;

=head1 DESCRIPTION

Lingua::JA::Categorize::Result is a result storage of L::J::C working 

=head1 METHODS

=head2 new

=head2 score  

=head2 confidence 

=head2 word_set

=head2 matches

=head2 no_matches

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
