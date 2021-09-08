use 5.012;
use strict;
use warnings;

package Lingua::Poetry::Haiku::Finder::SentencePart;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moo::Role;
use namespace::autoclean;
requires qw( text syllables is_word );

1;
