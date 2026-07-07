package Inline::CLIPS;

use strict;
use warnings;

use Carp qw(croak);
use File::Spec;
use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

our $VERSION = '0.001';

sub new {
  my ($class, %args) = @_;
  my $self = bless {
    executable => $args{executable},
    library    => $args{library},
  }, $class;
  return $self;
}

sub executable {
  my ($self) = @_;
  return $self->{executable} if defined $self->{executable};

  $self->{executable} = $ENV{INLINE_CLIPS_EXECUTABLE}
    || _path_executable('clips')
    || _alien_executable()
    || q{};

  return $self->{executable};
}

sub library {
  my ($self) = @_;
  return $self->{library} if defined $self->{library};

  $self->{library} = $ENV{INLINE_CLIPS_LIB}
    || _alien_library()
    || q{};

  return $self->{library};
}

sub run_program {
  my ($self, $program, @commands) = @_;
  croak 'program text is required' if !defined $program;

  my ($fh, $tmp) = tempfile('inline-clips-XXXX', SUFFIX => '.clp', UNLINK => 1);
  print {$fh} "(clear)\n";
  print {$fh} $program;
  print {$fh} "\n" if $program !~ /\n\z/;
  print {$fh} "(reset)\n";
  print {$fh} "$_\n" for @commands;
  print {$fh} "(exit)\n";
  close $fh;

  return $self->run_file($tmp);
}

sub run_file {
  my ($self, $file) = @_;
  croak 'file path is required' if !defined $file || $file eq q{};
  croak "CLIPS file not found: $file" if !-f $file;

  my $exe = $self->executable;
  croak 'CLIPS executable is not available; set INLINE_CLIPS_EXECUTABLE or install CLIPS/Alien::CLIPS'
    if !$exe;

  my $err = gensym;
  my $pid = open3(my $in, my $out, $err, $exe, '-f2', $file);
  close $in;

  local $/ = undef;
  my $stdout = <$out> // q{};
  my $stderr = <$err> // q{};
  waitpid($pid, 0);
  my $status = $? >> 8;

  return {
    status => $status,
    stdout => $stdout,
    stderr => $stderr,
  };
}

sub _path_executable {
  my ($name) = @_;
  for my $dir (File::Spec->path) {
    my $candidate = File::Spec->catfile($dir, $name);
    return $candidate if -x $candidate;
  }
  return;
}

sub _alien_executable {
  my $alien = _load_alien() or return;
  my @bins = $alien->can('bin_dir') ? $alien->bin_dir : ();
  for my $dir (@bins) {
    my $candidate = File::Spec->catfile($dir, 'clips');
    return $candidate if -x $candidate;
  }
  return;
}

sub _alien_library {
  my $alien = _load_alien() or return;
  my @libs = $alien->can('dynamic_libs') ? $alien->dynamic_libs : ();
  return $libs[0] if @libs;
  return;
}

sub _load_alien {
  my $ok = eval {
    require Alien::CLIPS;
    Alien::CLIPS->import();
    1;
  };
  return if !$ok;
  return 'Alien::CLIPS';
}

1;

__END__

=head1 NAME

Inline::CLIPS - Perl interface to run CLIPS programs

=head1 SYNOPSIS

  use Inline::CLIPS;

  my $clips = Inline::CLIPS->new;
  my $result = $clips->run_program(q{
    (deftemplate animal (slot name) (slot class))
    (deffacts initial (animal (name "penguin") (class bird)))
    (defrule print-animal
      (animal (name ?n) (class ?c))
      =>
      (printout t ?n " is a " ?c crlf))
  }, '(run)');

=head1 DESCRIPTION

This module provides a small Perl API for executing CLIPS programs.
It will use a CLIPS executable from C<$PATH>, C<INLINE_CLIPS_EXECUTABLE>,
or from C<Alien::CLIPS> when available.

