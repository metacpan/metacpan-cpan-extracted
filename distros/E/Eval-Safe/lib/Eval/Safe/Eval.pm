# This is an implementation of Eval::Safe that uses `eval` to execute the user
# provided code.

package Eval::Safe::Eval;

use 5.022;
use strict;
use warnings;

use parent 'Eval::Safe';

use Carp;
use File::Spec::Functions qw(rel2abs);

# Count the number of Eval::Safe::Eval object created to assign each of them a
# specific package name.
my $env_count = 0;

sub new {
  my ($class, %options) = @_;
  my $self = bless \%options, $class;
  $self->{package} = 'Eval::Safe::Eval::Env'.($env_count++) unless $self->{package};
  return $self;
}

sub DESTROY {
  local($., $@, $!, $^E, $?);
  my ($this) = @_;
  CORE::eval('undef %'.($this->{package}).'::');
}

sub eval {
  my ($this, $code) = @_;
  my $eval_str = sprintf "package %s; %s; %s; %s", $this->{package},
                        $this->{strict}, $this->{warnings}, $code;
  print {$this->{debug}} "Evaling (eval): '${eval_str}'\n" if $this->{debug};
  my @ret;
  if (not defined wantarray) {
    CORE::eval($eval_str);
  } elsif (wantarray) {
    @ret = CORE::eval($eval_str);
  } else {
    @ret = scalar CORE::eval($eval_str);
  }
  print {$this->{debug}} "Eval returned an error: $@" if $this->{debug} && $@;  
  return $this->_wrap_code_refs(\&_wrap_in_eval, @ret);
}

sub do {
  my ($this, $file) = @_;
  # do can open relative paths, but in that case it looks them up in the @INC
  # directory, which we want to avoid.
  # We don't use abs_path here to not die (just yet) if the file does not exist.
  my $abs_path = rel2abs($file);
  $this->eval("my \$r = do '${abs_path}'; die \$@ if \$@; \$r");
}

# To emulate the behavior of the Safe approach (where code returned by eval is
# wrapped to trap all exception, we're using this method to wrap code returned
# by eval in the same way).
sub _wrap_in_eval {
  my ($this, $sub) = @_;
  # When $sub is called, we're executing it in an `eval` and also wrapping all
  # its returned code in the same way.
  return sub {
    my @ret;
    if (not defined wantarray) {
      eval { $sub->() };
    } elsif (wantarray) {
      @ret = eval { $sub->() };
    } else {
      @ret = scalar eval { $sub->() };
    }
    $this->_wrap_code_refs(\&_wrap_in_eval, @ret)
  };
}

1;
