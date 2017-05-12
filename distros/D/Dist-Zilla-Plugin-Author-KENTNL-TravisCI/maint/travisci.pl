#!perl
use strict;
use warnings;
return sub {
  splice @{ $_[0]->{install} }, 2, 0,
    'time cpanm --quiet --notest --no-man-pages --dev Dist::Zilla::Plugin::Test::Compile::PerFile';
};
