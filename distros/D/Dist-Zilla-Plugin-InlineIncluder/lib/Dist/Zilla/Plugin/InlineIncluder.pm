package Dist::Zilla::Plugin::InlineIncluder;
our $VERSION = '0.02';

use Moose;

extends 'Dist::Zilla::Plugin::ModuleIncluder';

has module => (
  isa => 'ArrayRef[Str]',
  traits => ['Array'],
  handles => {
    modules => 'elements',
  },
  default => sub {[qw(
    Inline
    Inline::C
    Inline::MakeMaker
  )]},
);

has blacklist => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => {
        blacklisted_modules => 'elements',
    },
    default => sub {[qw(
        XXX
        Inline::Filters
        Inline::Struct
    )]},
);


sub gather_files {
  my $self = shift;
  for my $prefix (qw(.. ../..)) {
    my $inline = "$prefix/inline-pm";
    my $inline_c = "$prefix/inline-c-pm";
    if (
        -d "$inline/.git" and
        -d "$inline_c/.git"
    ) {
        eval "use lib '$inline/lib', '$inline_c/lib'; 1" or die $@;
        $self->SUPER::gather_files(@_);
        return;
    }
  }
  die "Inline and Inline-C repos missing or not in right state";
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
