package Lingua::JA::Summarize::Extract::ResultSet;

use strict;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw/ length summary sentences /);

use overload (
    q("") => \&as_string,
    fallback => 1,
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{length} ||= 255;
    $self->init;
    $self;
}

sub init {
    my $self = shift;

    my @ranking = ();
    for my $line (@{ $self->sentences }) {
        next unless $line;
        my $score = 0;
        for my $term (@{ $self->summary }) {
            my @words = split /\s/, $term->{term};
            my %tmp;
            my $tmp_score = 0;
            for my $word (@words) {
                for ($line->{text} =~ /(\Q$word\E)/) {
                    $tmp_score += $term->{score};
                    $tmp{$word} = 1;
                }
            }
            $score += $tmp_score if scalar(@words) == scalar(keys %tmp);
        }
        push @ranking, +{ %{ $line }, score => $score, A => 'II' };
    }
    @ranking = sort { $b->{score} <=> $a->{score} } @ranking;
    $self->sentences(\@ranking);
}

sub as_string {
    my $self = shift;

    my $text;
    my @result;
    for my $line (@{ $self->sentences }) {
        push @result, $line;
        $text .= "$line->{text}\n";
        last if length $text > $self->length;
    }

    if ($self->{sort} ne 'score') {
        $text = '';
        for my $line (sort { $a->{line} <=> $b->{line} } @result) {
            $text .= "$line->{text}\n";
        }
    }

    my $len = $self->length;
    $text =~ s/^(.{$len}).*$/$1\n/s;
    $text;
}

1;
