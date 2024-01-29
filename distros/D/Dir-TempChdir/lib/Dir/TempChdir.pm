package Dir::TempChdir;

use strict;
use warnings;

use Carp ();
use Config ();
use Cwd ();
use File::Spec ();
use Scalar::Util ();
use XSLoader;

BEGIN {
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = ();
  our @EXPORT_OK = ();
  our @EXPORT_TAGS = ();

  our $VERSION = '0.05';
  our $XS_VERSION = $VERSION;
  $VERSION = eval $VERSION; # so "use Module 0.002" won't warn on underscore

  XSLoader::load(__PACKAGE__, $XS_VERSION);
}

use constant {
  _CURDIR => File::Spec->curdir(),
  _HAVE_FCHDIR => $Config::Config{d_fchdir},
  _O_SRCH => (
    defined &O_SEARCH ? &O_SEARCH :  # POSIX
    defined &O_PATH ? &O_PATH :      # Linux
    undef
  ),
};

use overload
  bool => sub { defined $_[0] },
  '""' => sub { Cwd::getcwd() },
  '0+' => sub { Scalar::Util::refaddr($_[0]) },
  fallback => 1
;


my $_FINAL_ERRNO;
my $_FINAL_ERROR;
my $O_PATH;

sub new {
  my $class = shift;
  my $dir = shift;

  my $self = bless {
    _stack => [],
    _last_errno => undef,
    _last_error => undef,
    _initialized => 0,
  }, $class;

  if (defined $dir && !defined $self->pushd($dir)) {
    return undef;
  }

  $self->{_initialized}++;
  return $self;
}

sub _clear_errors {
  my $self = shift;
  undef $self->{_last_errno};
  undef $self->{_last_error};
}

sub pushd {
  my $self = shift;
  my $dir = shift;

  my $fn;
  # Perl < 5.22 had no newfangled nonsense like the fileno of a handle
  # returned by opendir().
  my $dirname = ref($dir) && defined($fn = fileno $dir) ? "fileno:$fn" : $dir;

  my $cwd = Cwd::getcwd();
  $cwd = sprintf('[%d:%s]', $!, $!) unless defined $cwd;

  my $dh;
  if (_HAVE_FCHDIR && !(defined _O_SRCH and sysopen $dh, _CURDIR, _O_SRCH or opendir $dh, _CURDIR)) {
    $self->{_last_error} = "pushd($dirname): opening '.' failed: $! [cwd:$cwd]";
  }
  elsif (! chdir $dir) {
    $self->{_last_error} = "pushd($dirname): chdir() failed: $! [cwd:$cwd]";
  }
  else {
    $self->_clear_errors();
    push @{$self->{_stack}}, { dh => $dh, path => $cwd };
    return $self;
  }

  $self->{_last_errno} = $!;
  return undef;
}

sub popd {
  my $self = shift;

  my $d = pop @{$self->{_stack}};
  if (defined $d) {
    if (chdir(_HAVE_FCHDIR ? $d->{dh} : $d->{path})) {
      $self->_clear_errors();
      return $self;
    }
    $self->{_last_errno} = $!;
    $self->{_last_error} =
      "popd() couldn't chdir() to (assumedly) $d->{path}: $!";
  }
  elsif ($self->{_initialized}) {
    undef $!;
    $self->_clear_errors();
  }

  return undef;
}

sub backout {
  my $self = shift;

  splice @{$self->{_stack}}, 1;
  return $self->popd();
}

sub stack_size {
  my $self = shift;
  return scalar @{$self->{_stack}};
}

sub errno {
  my $self = shift;
  return Scalar::Util::blessed($self) ? $self->{_last_errno} : $_FINAL_ERRNO;
}

sub error {
  my $self = shift;
  return Scalar::Util::blessed($self) ? $self->{_last_error} : $_FINAL_ERROR;
}

sub DESTROY {
  my $self = shift;

  local($., $@, $!, $^E, $?); # recommended by perldoc perlobj
  if (defined $self->backout()) {
    undef $_FINAL_ERRNO;
    undef $_FINAL_ERROR;
  }
  else {
    $_FINAL_ERRNO = $self->{_last_errno};
    $_FINAL_ERROR = $self->{_last_error};
  }
}

sub import {
  my $this = shift;

  my @args = grep !$_ || $_ ne '-IGNORE_UNSAFE_CHDIR_SECURITY_RISK', @_;
  my $HAVE_IGNORE_UNSAFE_CHDIR_SECURITY_RISK = @args < @_;

  if (_HAVE_FCHDIR) {
    if ($HAVE_IGNORE_UNSAFE_CHDIR_SECURITY_RISK) {
      Carp::carp(
        'Useless -IGNORE_UNSAFE_CHDIR_SECURITY_RISK on fchdir() capable system'
      );
    }
  }
  elsif (! $HAVE_IGNORE_UNSAFE_CHDIR_SECURITY_RISK) {
    Carp::croak('This system lacks support for fchdir()');
  }

  __PACKAGE__->export_to_level(1, $this, @args);
}

1;
