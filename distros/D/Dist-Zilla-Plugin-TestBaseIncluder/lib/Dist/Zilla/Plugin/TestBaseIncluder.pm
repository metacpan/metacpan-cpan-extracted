package Dist::Zilla::Plugin::TestBaseIncluder;
our $VERSION = '0.09';

use Moose;

extends 'Dist::Zilla::Plugin::ModuleIncluder';

has module => (
  isa => 'ArrayRef[Str]',
  traits => ['Array'],
  handles => {
    modules => 'elements',
  },
  default => sub {[qw(
    Test::Base
    Test::Base::Filter
  )]},
);

has blacklist => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => {
        blacklisted_modules => 'elements',
    },
    default => sub {[qw(
        LWP::Simple
        Test::Deep
        Text::Diff
        YAML
    )]},
);


sub gather_files {
  my $self = shift;
  for my $prefix (qw(.. ../..)) {
    my $testbase = "$prefix/test-base-pm";
    if (
      -d "$testbase/.git"
    ) {
      eval "use lib '$testbase/lib'; 1" or die $@;
      $self->SUPER::gather_files(@_);
      return;
    }
}
  die "Test::Base repo missing or not in right state";
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
