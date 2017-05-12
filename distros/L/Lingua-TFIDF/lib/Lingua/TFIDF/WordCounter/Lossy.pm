package Lingua::TFIDF::WordCounter::Lossy;

use strict;
use warnings;
use Algorithm::LossyCount;
use Smart::Args;

sub new {
  args
    my $class => 'ClassName',
    my $max_error_ratio => 'Num';

  bless +{
    counter => Algorithm::LossyCount->new(max_error_ratio => $max_error_ratio),
    max_error_ratio => $max_error_ratio,
  } => $class;
}

sub add_count {
  args_pos
    my $self,
    my $word => 'Str';

  $self->counter->add_sample($word);
}

sub clear {
  args
    my $self;

  $self->{counter} =
    Algorithm::LossyCount->new(max_error_ratio => $self->max_error_ratio);
}

sub counter { $_[0]->{counter} }

sub frequencies { $_[0]->counter->frequencies }

sub max_error_ratio { $_[0]->{max_error_ratio} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TFIDF::WordCounter::Lossy

=head1 VERSION

version 0.01

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
