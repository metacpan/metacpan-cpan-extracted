use strict;
use warnings;

use Test::More;

use ExtUtils::testlib;
use lib './lib';
use_ok q{Image::Libpuzzle};

my @methods =
  qw/new get_cvec fill_cvec_from_file get_signature set_lambdas set_p_ratio
  set_max_width set_max_height set_noise_cutoff set_contrast_barrier_for_cropping set_max_cropping_ratio
  set_autocrop vector_euclidean_length vector_normalized_distance is_similar is_very_similar is_most_similar
  PUZZLE_VERSION_MAJOR PUZZLE_VERSION_MINOR PUZZLE_CVEC_SIMILARITY_THRESHOLD PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD
  PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD/;

can_ok q{Image::Libpuzzle}, @methods;

my $p1 = new_ok q{Image::Libpuzzle};
my $p2 = new_ok q{Image::Libpuzzle};

my $pic1 = q{t/pics/luxmarket_tshirt01.jpg};
my $pic2 = q{t/pics/luxmarket_tshirt01_sal.jpg};

my $sig1 = $p1->fill_cvec_from_file($pic1);
ok $sig1, q{Signature for picture 1 defined};

my $sig2 = $p2->fill_cvec_from_file($pic2);
ok $sig2, q{Signature for picture 2 defined};

my $string1 = $p1->signature_as_char_string;
ok $string1, q{Stringified as char signature 1 is not empty};

my $hex_string1 = $p1->signature_as_hex_string;
ok $hex_string1, q{Stringified as char signature 1 is not empty};

my $words1_ref = $p1->signature_as_char_ngrams;
ok @$words1_ref, q{Ngrams not empty for signature 1};

my $hex_words1_ref = $p1->signature_as_hex_ngrams;
ok @$hex_words1_ref, q{Ngrams not empty for signature 1};

my $string2 = $p2->signature_as_char_string;
ok $string2, q{Stringified char signature 2 is not empty};

my $hex_string2 = $p2->signature_as_hex_string;
ok $hex_string2, q{Stringified as char signature 2 is not empty};

my $words2_ref = $p2->signature_as_char_ngrams;
ok @$words2_ref, q{Ngrams not empty for signature 2};

my $hex_words2_ref = $p2->signature_as_hex_ngrams;
ok @$hex_words2_ref, q{Ngrams not empty for signature 2};

ok $p1->vector_normalized_distance($p2) > 0,
  q{Signature distance is greater than 0};

ok $p1->is_most_similar($p2), q{Images are "most" similar};

ok $p1->vector_normalized_distance($p2) <
  $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD,
  q{Images are "most" simiar, once again};

ok defined $Image::Libpuzzle::PUZZLE_VERSION_MAJOR
  && $Image::Libpuzzle::PUZZLE_VERSION_MAJOR ==
  Image::Libpuzzle->PUZZLE_VERSION_MAJOR, q{Ensuring PUZZLE_VERSION_MAJOR};
ok defined $Image::Libpuzzle::PUZZLE_VERSION_MINOR
  && $Image::Libpuzzle::PUZZLE_VERSION_MINOR ==
  Image::Libpuzzle->PUZZLE_VERSION_MINOR, q{Ensuring PUZZLE_VERSION_MINOR};
ok defined $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_THRESHOLD
  && $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_THRESHOLD ==
  Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_THRESHOLD,
  q{Ensuring PUZZLE_CVEC_SIMILARITY_THRESHOLD};
ok defined $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD
  && $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD ==
  Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD,
  q{Ensuring PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD};
ok defined $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD
  && $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD ==
  Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD,
  q{Ensuring PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD};
ok defined $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD
  && $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD ==
  Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD,
  q{Ensuring PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD};

done_testing;

__END__
