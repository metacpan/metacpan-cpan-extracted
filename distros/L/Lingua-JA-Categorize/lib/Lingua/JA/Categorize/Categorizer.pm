package Lingua::JA::Categorize::Categorizer;
use strict;
use warnings;
use Algorithm::NaiveBayes;
use Lingua::JA::Categorize::Result;
use base qw( Lingua::JA::Categorize::Base );

__PACKAGE__->mk_accessors($_) for qw( brain );

sub import {
    use Algorithm::NaiveBayes::Util;
    use List::Util qw(min max sum);
    no warnings 'redefine';
    *Algorithm::NaiveBayes::Util::rescale = sub {
        my ($scores) = @_;
        my $min      = min( values %$scores );
        my $sum      = sum( values %$scores );
        $sum -= $min * ( keys %$scores );
        for ( sort { $scores->{$b} <=> $scores->{$a} } keys %$scores ) {
            $scores->{$_} = ( $scores->{$_} - $min ) / $sum;
        }
        my $max = max( values %$scores );
        for ( sort { $scores->{$b} <=> $scores->{$a} } keys %$scores ) {
            $scores->{$_} = sprintf( "%0.2f", $scores->{$_} / $max );
        }
        return $scores;
    };
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->brain( Algorithm::NaiveBayes->new( purge => 0 ) );
	#use Devel::Size qw(size total_size);
	#use Devel::Peek;
    {
        no warnings 'redefine';
        *Algorithm::NaiveBayes::Model::Frequency::do_predict = sub {
            my ( $self, $m, $newattrs ) = @_;
		#	print "IN :", total_size($m), "\n";	
            my %scores = %{ $m->{prior_probs} };
            while ( my ( $feature, $value ) = each %$newattrs ) {
                unless ( exists $m->{attributes}{$feature} ) {
                    push( @{ $self->{no_match_features} }, $feature );
                    next;
                }
                else {
                    push( @{ $self->{match_features} }, $feature );
                }
                while ( my ( $label, $attributes ) = each %{ $m->{probs} } ) {
					my $p = ($attributes->{$feature} || $m->{smoother}{$label});
					$scores{$label} += $p * $value;

                    #$scores{$label} +=
                    #  ( $attributes->{$feature} || $m->{smoother}->{$label} ) *
                    #  $value;
                }
            }
		#	print "OUT:", total_size($m), "\n";	
            Algorithm::NaiveBayes::Util::rescale( \%scores );

            return \%scores;
        };
    }
    return $self;
}

sub categorize {
    my $self           = shift;
    my $word_set       = shift;
    my $user_extention = shift;
    $self->brain->{no_match_features} = [];
    $self->brain->{match_features}    = [];
    my $score      = $self->brain->predict( attributes => $word_set );
    my $no_matches = $self->brain->{no_match_features};
    my $matches    = $self->brain->{match_features};
    my $result     = Lingua::JA::Categorize::Result->new(
        context        => $self->context,
        score          => $score,
        matches        => $matches,
        no_matches     => $no_matches,
        word_set       => $word_set,
        user_extention => $user_extention,
    );
    return $result;
}

sub save {
    my $self      = shift;
    my $save_file = shift;
    $self->brain->save_state($save_file);
}

sub load {
    my $self      = shift;
    my $save_file = shift;
    my $brain     = $self->brain;
    $brain = Algorithm::NaiveBayes->restore_state($save_file);
    $self->brain($brain);
}

1;
__END__

=head1 NAME

Lingua::JA::Categorize::Categorizer - The brain of L::J::C

=head1 SYNOPSIS

  use Lingua::JA::Categorize::Categorizer;

  my $categorizer = Lingua::JA::Categorize::Categorizer->new;
  $categorizer->load('save_file');
  my $result = $categorizer->categorize($text);
  print Dumper $result->score;

=head1 DESCRIPTION

Lingua::JA::Categorize::Categorizer is a brain of this module.

It is just a warpper of Algorithm::NaiveBayes.

=head1 METHODS

=head2 new

=head2 categorize

=head2 save

=head2 load

=head2 brain

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
