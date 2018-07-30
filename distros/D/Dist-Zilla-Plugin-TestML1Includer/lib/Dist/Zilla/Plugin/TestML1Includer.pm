package Dist::Zilla::Plugin::TestML1Includer;
our $VERSION = '0.0.2';

use Moose;

extends 'Dist::Zilla::Plugin::ModuleIncluder';

has module => (
  isa => 'ArrayRef[Str]',
  traits => ['Array'],
  handles => {
    modules => 'elements',
  },
  default => sub {[qw(
    Pegex::Input
    Pegex::Grammar
    Pegex::Base
    Pegex::Optimizer
    Pegex::Parser
    Pegex::Tree
    Pegex::Receiver
    TestML1::Util
    TestML1::Compiler::Lite
    TestML1::Compiler::Pegex::Grammar
    TestML1::Compiler::Pegex::AST
    TestML1::Compiler::Pegex
    TestML1::Library::Debug
    TestML1::Library::Standard
    TestML1::Compiler
    TestML1::Runtime::TAP
    TestML1::Runtime
    TestML1::Base
    TestML1::Bridge
    TestML1
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
        TestML1::Object
    )]},
);


sub gather_files {
  my $self = shift;
  for my $prefix (qw(.. ../..)) {
    my $pegex = "$prefix/pegex-pm";
    my $testml1 = "$prefix/testml1-pm";
    if (
        -d "$pegex/.git" and
        -d "$testml1/.git"
    ) {
        eval "use lib '$pegex/lib', '$testml1/lib'; 1" or die $@;
        $self->SUPER::gather_files(@_);
        return;
    }
  }
  die "Pegex and TestML1 repos missing or not in right state";
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
