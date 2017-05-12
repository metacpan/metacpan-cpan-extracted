package Lingua::TFIDF::Types;

use strict;
use warnings;
use Mouse::Util::TypeConstraints;

subtype 'Lingua::TFIDF::TermFrequency', as 'HashRef[Str]';

duck_type 'Lingua::TFIDF::WordCounter' => [qw/add_count clear frequencies/];

duck_type 'Lingua::TFIDF::WordSegmenter' => [qw/segment/];

no Mouse::Util::TypeConstraints;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TFIDF::Types

=head1 VERSION

version 0.01

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
