package Log::Dump;

use strict;
use warnings;
use Sub::Install qw( install_sub );
use Scalar::Util qw( blessed );

our $VERSION = '0.14';
our @CARP_NOT = qw/Log::Dump Log::Dump::Class Log::Dump::Functions/;

sub import {
  my $class = shift;
  my $caller = caller;

  return if $caller eq 'main';

  my @methods = qw/logger logfilter logfile logcolor logtime log/;
  for my $method (@methods) {
    install_sub({
      as   => $method,
      into => $caller,
      code => \&{$method},
    });
  }
}

sub logger {
  my $self = shift;

  my $logger = $_[0];
  if ( blessed $self ) {
    @_ ? $self->{_logger} = $logger : $self->{_logger};
  }
  else {
    no strict 'refs';
    @_ ? ${"$self\::_logger"} = $logger : ${"$self\::_logger"};
  }
}

sub logfilter {
  my $self = shift;

  my $filter = undef;
  if (@_ && $_[0]) {
    $filter = {pos => [], neg => []};
    for (@_) {
      if (substr($_, 0, 1) eq '!') {
        push @{$filter->{neg}}, substr($_, 1);
      }
      else {
        push @{$filter->{pos}}, $_;
      }
    }
  }

  if ( blessed $self ) {
    @_ ? $self->{_logfilter} = $filter : $self->{_logfilter};
  }
  else {
    no strict 'refs';
    @_ ? ${"$self\::_logfilter"} = $filter : ${"$self\::_logfilter"};
  }
}

sub logfile {
  my $self = shift;

  my $logfile_ref;
  if ( blessed $self ) {
    $logfile_ref = \($self->{_logfile});
    }
  else {
    no strict 'refs';
    $logfile_ref = \(${"$self\::_logfile"});
  }

  if ( @_ && $_[0] ) {
    push @_, 'w' if @_ == 1;
    require IO::File;
    my $fh = IO::File->new(@_) or $self->log( fatal => $! );
    $$logfile_ref = $fh;
  }
  elsif ( @_ && !$_[0] ) {
    $$logfile_ref->close if $$logfile_ref;
    $$logfile_ref = undef;
  }
  else {
    $$logfile_ref;
  }
}

sub logtime {
  my $self = shift;

  my $logtime_ref;
  if ( blessed $self ) {
    $logtime_ref = \($self->{_logtime});
    }
  else {
    no strict 'refs';
    $logtime_ref = \(${"$self\::_logtime"});
  }

  if ( @_ && $_[0] ) {
    eval { require Time::Piece };
    return $$logtime_ref = undef if $@;

    my $format = $_[0] =~ /%/ ? $_[0] : '%Y-%m-%d %H:%M:%S';
    $$logtime_ref = sub { Time::Piece->new(shift)->strftime($format) };
  }
  elsif ( @_ && !$_[0] ) {
    $$logtime_ref = undef;
  }
  else {
    $$logtime_ref;
  }
}

sub logcolor {
  my $self = shift;

  my $logcolor_ref;
  if ( blessed $self ) {
    $logcolor_ref = \($self->{_logcolor});
    }
  else {
    no strict 'refs';
    $logcolor_ref = \(${"$self\::_logcolor"});
  }

  unless ( defined $$logcolor_ref ) {
    eval { require Term::ANSIColor };
    $$logcolor_ref = $@ ? 0 : {};

    eval { require Win32::Console::ANSI } if $^O eq 'MSWin32';
  }
  return unless $$logcolor_ref;

  if ( @_ == 1 && $_[0] ) {
    $$logcolor_ref->{$_[0]};
  }
  elsif ( @_ && !$_[0] ) {
    $$logcolor_ref = {};
  }
  elsif ( @_ % 2 == 0 ) {
    $$logcolor_ref = { %{ $$logcolor_ref }, @_ };
  }
}

sub log {
  my $self = shift;

  my $logger = $self->logger;

  if ( defined $logger and !$logger ) {
    return;
  }
  elsif ( $logger and $logger =~ /^[A-Za-z]/ && $logger->can('log') ) {
    $logger->log(@_);
  }
  else {
    my $label = shift;

    if ($self->logfilter) {
      if (my @neg = @{ $self->logfilter->{neg} }) {
        return if grep { $label eq $_ } @neg;
      }
      if (my @pos = @{ $self->logfilter->{pos} }) {
        return if !grep { $label eq $_ } @pos;
      }
    }

    require Data::Dump;
    my $msg = join '', map { ref $_ ? Data::Dump::dump($_) : $_ } @_;
    my $colored_msg = $msg;
    if ( my $color = $self->logcolor($label) ) {
      eval { $colored_msg = Term::ANSIColor::colored($msg, $color) };
      $colored_msg = $msg if $@;
    }
    my $time = '';
    if (my $func = $self->logtime) {
      $time = $func->(time) . " ";
    }

    if ( $label eq 'fatal' ) {
      require Carp;
      Carp::croak $time."[$label] $colored_msg";
    }
    elsif ( $label eq 'error' or $label eq 'warn' ) {
      require Carp;
      Carp::carp $time."[$label] $colored_msg";
      $self->logfile->print(Carp::shortmess($time."[$label] $msg"), "\n") if $self->logfile;
    }
    else {
      print STDERR $time."[$label] $colored_msg\n";
      $self->logfile->print($time."[$label] $msg\n") if $self->logfile;
    }
  }
}

1;

__END__

=head1 NAME

Log::Dump - simple logger mainly for debugging

=head1 SYNOPSIS

    use Log::Dump; # installs 'log' and other methods

    # class log
    __PACKAGE__->log( error => 'foo' );

    # object log
    sub some_method {
      my $self = shift;

      # you can pass multiple messages (will be concatenated)
      # and objects (will be dumped via L<Data::Dump>).
      $self->log( info => 'my self is ', $self );
    }

    # you can control which log should be shown by labels.
    sub broken_method {
      my $self = shift;

      $self->logfilter('broken_only');
      $self->log( broken_only => 'shown' );
      $self->log( debug       => 'not shown' );
    }

    # you can log to a file
    __PACKAGE__->logfile('log.txt');
    __PACKAGE__->log( file => 'will be saved' );
    __PACKAGE__->logfile('');  # to close

    # you can color logs to stderr
    sub important_method {
      my $self = shift;
      $self->logcolor( important => 'bold red on_white' );
      $self->log( important => 'bold red message' );
      $self->logcolor(0);  # no color
    }

    # you can log with timestamp
    __PACKAGE__->logtime(1);
    $self->log( $ENV{REMOTE_ADDR} => 'foo' );
    __PACKAGE__->logtime(0); # hide timestamp

    # you can turn off the logging; set to true to turn on.
    __PACKAGE__->logger(0);

    # or you can use better loggers (if they have a 'log' method)
    __PACKAGE__->logger( Log::Dispatch->new );

=head1 DESCRIPTION

L<Log::Dump> is a simple logger mix-in mainly for debugging. This installs six methods into a caller (the class that C<use>d L<Log::Dump>) via L<Sub::Install>. The point is you don't need to load extra dumper modules or you don't need to concatenate messages. Just log things and they will be dumped (and concatenated if necessary) to stderr, and to a file if you prefer. Also, you can use these logging methods as class methods or object methods (though usually you don't want to mix them, especially when you're doing something special).

=head1 METHODS

=head2 log

logs things to stderr. The first argument (other than class/object) is considered as a label for the messages, and will be wrapped with square blackets. Objects in the messages will be dumped through L<Data::Dump>, and multiple messages will be concatenated. And usually line feed/carriage return will be appended.

The C<fatal> label is special: if you log things with this label, the logger croaks the messages (and usually the program will die).

Also, if you log things with C<error> or C<warn> labels, the logger carps the messages (with a line number and a file name).

Other labels have no special meaning for the logger, but as you can filter some of the logs with these labels, try using meaningful ones for you.

Note that these special labels doesn't work with custom loggers. Actually, you can pass anything to C<log> method to conform to your logger's requirement.

=head2 logger

turns on/off the logger if you set this to true/false (preferably, 1/0 to avoid confusion). And if you set a class name (or an object) that provides C<log> method, it will be used while logging.

=head2 logfilter

If you specify some labels through this, only logs with those labels will be shown. Set a false value to disable this filtering.

=head2 logfile

If you want to log to a file, set a file name, and an optional open mode for L<IO::File> (C<w> for write by default). When you set a false value, the opened file will be closed. Note that this doesn't disable logging to stderr. Logs will be dumped both to stderr and to a file while the file is open.

=head2 logcolor

If you want to color logs to stderr, provide a label and its color specification (actually a hash of them) to C<logcolor>. Then, log will be colored (if L<Term::ANSIColor> is installed and your terminal supports the specification). If you set a false scalar, coloring will be disabled. See L<Term::ANSIColor> for color specifications.

=head2 logtime

If you set this to true, timestamp will be prepended. You can pass a strftime format if you need finer control. Set a false value to disable this timestamp.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
