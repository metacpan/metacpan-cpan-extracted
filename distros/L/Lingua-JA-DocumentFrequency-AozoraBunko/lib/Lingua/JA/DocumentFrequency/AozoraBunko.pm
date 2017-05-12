package Lingua::JA::DocumentFrequency::AozoraBunko;

use 5.008001;
use strict;
use warnings;

use Carp ();
use Exporter qw/import/;
use Storable ();
use File::ShareDir ();

our $VERSION   = '0.01';
our @EXPORT    = qw(aozora_df);
our @EXPORT_OK = qw(number_of_documents df);

my $DATA_PATH = File::ShareDir::dist_file('Lingua-JA-DocumentFrequency-AozoraBunko', 'df.st');
my $DF_OF     = Storable::retrieve($DATA_PATH) or Carp::croak("Cannot read: $DATA_PATH");

sub number_of_documents { 11176 }

sub df
{
    my $word = shift;
    return undef unless defined $word;
    return defined $DF_OF->{$word} ? $DF_OF->{$word} : 0;
}

*aozora_df = \&df;

1;

__END__

=encoding utf-8

=head1 NAME

Lingua::JA::DocumentFrequency::AozoraBunko - Return the document frequency in Aozora Bunko

=head1 SYNOPSIS

  use Lingua::JA::DocumentFrequency::AozoraBunko;
  use utf8;

  aozora_df('本');         # => 5180
  aozora_df('遊蕩');       # => 160
  aozora_df('チャカポコ'); # => 3
  aozora_df('しおらしい'); # => 149
  aozora_df('イチロー');   # => 0

  Lingua::JA::DocumentFrequency::AozoraBunko::df('ジャピイ'); # => 2
  Lingua::JA::DocumentFrequency::AozoraBunko::df('カア');     # => 23

  my $N = Lingua::JA::DocumentFrequency::AozoraBunko::number_of_documents(); # => 11176
  idf('ジャピイ'); # => 8.62837672037685
  idf('カア');     # => 6.18602968500765

  sub idf { log( $N / aozora_df(shift) ) }

=head1 DESCRIPTION

Lingua::JA::DocumentFrequency::AozoraBunko returns the document frequency in Aozora Bunko.

=head1 METHODS

=head2 df($word)

Returns the document frequency of $word.

=head2 aozora_df($word)

Same as df method, but this method is exported by default.

=head2 number_of_documents

Returns the number of the documents in Aozora Bunko.

=head1 LICENSE

Copyright (C) pawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=cut
