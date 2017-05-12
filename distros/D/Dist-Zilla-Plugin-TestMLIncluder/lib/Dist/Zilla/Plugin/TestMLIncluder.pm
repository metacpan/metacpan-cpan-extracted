package Dist::Zilla::Plugin::TestMLIncluder;
our $VERSION = '0.12';

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
    TestML::Util
    TestML::Compiler::Lite
    TestML::Compiler::Pegex::Grammar
    TestML::Compiler::Pegex::AST
    TestML::Compiler::Pegex
    TestML::Library::Debug
    TestML::Library::Standard
    TestML::Compiler
    TestML::Runtime::TAP
    TestML::Runtime
    TestML::Base
    TestML::Bridge
    TestML
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
        TestML::Object
    )]},
);


sub gather_files {
  my $self = shift;
  for my $prefix (qw(.. ../..)) {
    my $pegex = "$prefix/pegex-pm";
    my $testml = "$prefix/testml-pm";
    if (
        -d "$pegex/.git" and
        -d "$testml/.git"
    ) {
        eval "use lib '$pegex/lib', '$testml/lib'; 1" or die $@;
        $self->SUPER::gather_files(@_);
        return;
    }
  }
  die "Pegex and TestML repos missing or not in right state";
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;
