#!/usr/bin/env perl
# ABSTRACT: Munge travis.ci options
sub {
  my ($yaml) = @_;
  splice @{ $yaml->{before_install} }, 1, 0, ('git --version');
  splice @{ $yaml->{before_install} }, 1, 0, ('perlbrew install-cpanm -f');
  unshift @{ $yaml->{install} },
    ('cpanm --verbose --mirror http://cpan.metacpan.org --no-man-pages \'ExtUtils::MakeMaker~>=6.64\'');

  #  @{ $yaml->{matrix}->{include} } = grep { $_->{perl} ne '5.8' }  @{ $yaml->{matrix}->{include} };
};

