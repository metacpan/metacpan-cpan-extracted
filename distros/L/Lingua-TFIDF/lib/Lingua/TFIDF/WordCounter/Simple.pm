package Lingua::TFIDF::WordCounter::Simple;

use strict;
use warnings;
use Smart::Args;

sub new { bless +{ frequencies => +{} } => $_[0] }

sub add_count {
  args_pos
    my $self,
    my $word => 'Str';

  ++$self->{frequencies}{$word};
}

sub clear { $_[0]->{frequencies} = +{} }

sub frequencies { $_[0]->{frequencies} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TFIDF::WordCounter::Simple

=head1 VERSION

version 0.01

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
