# This is an implementation of Eval::Safe that uses the Safe module to execute
# the user provided code.

package Eval::Safe::Safe;

use 5.022;
use strict;
use warnings;

use parent 'Eval::Safe';

use Carp;
use Eval::Safe::ForkedSafe;
use File::Spec::Functions qw(rel2abs);

sub new {
  my ($class, %options) = @_;
  my $self = bless \%options, $class;
  my $safe = Eval::Safe::ForkedSafe->new($self->{package});
  $self->{package} = $safe->root() unless $self->{package};
  # This option is always set if we're building an Eval::Safe::Safe.
  if ($self->{safe} > 1) {
    $safe->permit_only(qw(:base_core :base_mem :base_loop :base_math :base_orig
                          :load));
    $safe->deny(qw(tie untie bless));
  } else {
    $safe->deny_only(qw(:subprocess :ownprocess :others :dangerous));
  }
  $self->{safe} = $safe;
  return $self;
}


sub DESTROY {
  local($., $@, $!, $^E, $?);
  my ($this) = @_;
  delete $this->{safe};
  # The package is not entirely deleted by the Safe destructor.
  CORE::eval('undef %'.($this->{package}).'::');
}


sub eval {
  my ($this, $code) = @_;
  my $eval_str = sprintf "%s; %s; %s", $this->{strict}, $this->{warnings}, $code;
  print {$this->{debug}} "Evaling (safe): '${eval_str}'\n" if $this->{debug};
  my @ret;
  if (not defined wantarray) {
    $this->{safe}->reval($eval_str);
  } elsif (wantarray) {
    @ret = $this->{safe}->reval($eval_str);
  } else {
    @ret = scalar $this->{safe}->reval($eval_str);
  }
  print {$this->{debug}} "Safe returned an error: $@" if $this->{debug} && $@;  
  if (defined wantarray) {
    return (wantarray) ? @ret : $ret[0];
  }
  return;
}

sub do {
  my ($this, $file) = @_;
  # do can open relative paths, but in that case it looks them up in the @INC
  # directory, which we want to avoid.
  # We don't use abs_path here to not die (just yet) if the file does not exist.
  my $abs_path = rel2abs($file);
  $this->{safe}->rdo($abs_path);
}

1;
