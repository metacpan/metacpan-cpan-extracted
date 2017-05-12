package Devel::REPL::Script;

our $VERSION = '1.003028';

use Moose;
use Devel::REPL;
use File::HomeDir;
use File::Spec;
use Module::Runtime 'use_module';
use namespace::autoclean;

our $CURRENT_SCRIPT;

with 'MooseX::Getopt';

has 'rcfile' => (
  is => 'ro', isa => 'Str',
  default => sub { 'repl.rc' },
);

has 'profile' => (
  is       => 'ro',
  isa      => 'Str',
  default  => sub { $ENV{DEVEL_REPL_PROFILE} || 'Minimal' },
);

has '_repl' => (
  is => 'ro', isa => 'Devel::REPL',
  default => sub { Devel::REPL->new() }
);

sub BUILD {
  my ($self) = @_;
  $self->load_profile($self->profile);
  $self->load_rcfile($self->rcfile);
}

sub load_profile {
  my ($self, $profile) = @_;
  $profile = "Devel::REPL::Profile::${profile}" unless $profile =~ /::/;
  use_module $profile;
  confess "Profile class ${profile} doesn't do 'Devel::REPL::Profile'"
    unless $profile->does('Devel::REPL::Profile');
  $profile->new->apply_profile($self->_repl);
}

sub load_rcfile {
  my ($self, $rc_file) = @_;

  # plain name => ~/.re.pl/${rc_file}
  if ($rc_file !~ m!/!) {
    $rc_file = File::Spec->catfile(File::HomeDir->my_home, '.re.pl', $rc_file);
  }

  $self->apply_script($rc_file);
}

sub apply_script {
  my ($self, $script, $warn_on_unreadable) = @_;

  if (!-e $script) {
    warn "File '$script' does not exist" if $warn_on_unreadable;
    return;
  }
  elsif (!-r _) {
    warn "File '$script' is unreadable" if $warn_on_unreadable;
    return;
  }

  open RCFILE, '<', $script or die "Couldn't open ${script}: $!";
  my $rc_data;
  { local $/; $rc_data = <RCFILE>; }
  close RCFILE; # Don't care if this fails
  $self->eval_script($rc_data);
  warn "Error executing script ${script}: $@\n" if $@;
}

sub eval_script {
  my ($self, $data) = @_;
  local $CURRENT_SCRIPT = $self;
  $self->_repl->eval($data);
}

sub run {
  my ($self) = @_;
  $self->_repl->run;
}

sub import {
  my ($class, @opts) = @_;
  return unless (@opts == 1 && $opts[0] eq 'run');
  $class->new_with_options->run;
}

sub current {
  confess "->current should only be called as class method" if ref($_[0]);
  confess "No current instance (valid only during rc parse)"
    unless $CURRENT_SCRIPT;
  return $CURRENT_SCRIPT;
}

1;
