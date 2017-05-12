package Log::Minimal::Instance;

use strict;
use warnings;
use parent 'Log::Minimal';
use File::Stamped;
use File::Spec;

our $VERSION = '0.06';

BEGIN {
    # for object methods
    for my $level (qw/crit warn info debug croak/) {
        for my $suffix (qw/f ff d/) {
            my $method = $level.$suffix;

            my $parent_code = Log::Minimal->can( ($suffix eq 'd') ? $level."f" : $method );

            no strict 'refs';
            my $code = sub {
                my $self = shift;
                local $Log::Minimal::TRACE_LEVEL = ($Log::Minimal::TRACE_LEVEL||0) + 1;
                local $Log::Minimal::LOG_LEVEL   = $self->{level};
                local $Log::Minimal::PRINT       = $self->{_print};
                $parent_code->( ($suffix eq 'd') ? Log::Minimal::ddf(@_) : @_ );
            };
            *{$method} = $code;
        }
    }
}

sub new {
    my ($class, %args) = @_;

    my $pattern           = exists $args{pattern}           ? $args{pattern}           : undef;
    my $symlink           = exists $args{symlink}           ? $args{symlink}           : undef;
    my $base_dir          = exists $args{base_dir}          ? $args{base_dir}          : '.';
    my $iomode            = exists $args{iomode}            ? $args{iomode}            : '>>:utf8';
    my $rotationtime      = exists $args{rotationtime}      ? $args{rotationtime}      : 1;
    my $autoflush         = exists $args{autoflush}         ? $args{autoflush}         : 1;
    my $close_after_write = exists $args{close_after_write} ? $args{close_after_write} : 1;
    my $auto_make_dir     = exists $args{auto_make_dir}     ? $args{auto_make_dir}     : 0;
    my $callback          = exists $args{callback}          ? $args{callback}          : undef;

    my $fh;
    if ($pattern) {
        $pattern = $class->_build_pattern($base_dir, $pattern);
        $symlink = $class->_build_pattern($base_dir, $symlink);
        $fh = File::Stamped->new(
            defined $pattern  ? (pattern  => $pattern)  : (),
            defined $callback ? (callback => $callback) : (),
            defined $symlink  ? (symlink  => $symlink)  : (),
            iomode            => $iomode,
            autoflush         => $autoflush,
            close_after_write => $close_after_write,
            rotationtime      => $rotationtime,
        );
    }
    else {
        $fh = *STDERR;
    }

    bless {
        level             => $args{level} || 'DEBUG',
        base_dir          => $base_dir,
        iomode            => $iomode,
        rotationtime      => $rotationtime,
        autoflush         => $autoflush,
        close_after_write => $close_after_write,
        auto_make_dir     => $auto_make_dir,

        _fh    => $fh,
        _print => sub {
            my ($time, $type, $message, $trace) = @_;
            print {$fh}  "$time [$type] $message at $trace\n"
        },
    }, $class;
}

sub log_to {
    my ($self, $opts, @args) = @_;

    if (ref $opts eq 'ARRAY') {
        $opts = {
            pattern => $opts->[0],
            symlink => $opts->[1],
        };
    }
    elsif (!ref $opts) {
        $opts = { pattern => $opts };
    }

    my ($pattern, $symlink, $callback);
    my $base_dir = defined $opts->{base_dir} ? $opts->{base_dir} : $self->{base_dir};
    $pattern  = $self->_build_pattern($base_dir, $opts->{pattern});
    $symlink  = $self->_build_pattern($base_dir, $opts->{symlink});
    $callback = exists $opts->{callback} ? $opts->{callback} : undef;

    my $fh = File::Stamped->new(
        defined $pattern  ? (pattern  => $pattern)  : (),
        defined $callback ? (callback => $callback) : (),
        defined $symlink  ? (symlink  => $symlink)  : (),
        iomode            => defined $opts->{iomode}            ? $opts->{iomode}            : $self->{iomode},
        autoflush         => defined $opts->{autoflush}         ? $opts->{autoflush}         : $self->{autoflush},
        close_after_write => defined $opts->{close_after_write} ? $opts->{close_after_write} : $self->{close_after_write},
        rotationtime      => defined $opts->{rotationtime}      ? $opts->{rotationtime}      : $self->{rotationtime},
        auto_make_dir     => defined $opts->{auto_make_dir}     ? $opts->{auto_make_dir}     : $self->{auto_make_dir},
    );

    local $self->{_fh}    = $fh;
    local $self->{_print} = sub {
        my ($time, $type, $message, $trace) = @_;
        print {$fh} "$time $message at $trace\n";
    };

    local $Log::Minimal::TRACE_LEVEL = ($Log::Minimal::TRACE_LEVEL||0) + 1;
    local $Log::Minimal::LOG_LEVEL   = 'DEBUG'; # Must be logging!
    $self->critf(@args);
}

sub _build_pattern {
    my ($self, $base_dir, $pattern) = @_;
    return unless defined $pattern;

    unless (File::Spec->file_name_is_absolute($pattern)) {
        $pattern = File::Spec->catfile($base_dir, $pattern);
    }
    return $pattern;
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Log::Minimal::Instance - Instance based on Log::Minimal

=head1 SYNOPSIS

  use Log::Minimal::Instance;

  # log to file
  my $log = Log::Minimal::Instance->new(
      base_dir => 'log',
      pattern  => 'myapp.log.%Y%m%d',  # File::Stamped style
  );

  # same as Log::Minimal method
  $log->debugf('debug');
  $log->infof('info');

  # ./log/myapp.log.20130101
  2013-01-01T16:15:39 [DEBUG] debug at lib/MyApp.pm line 10
  2013-01-01T16:15:39 [INFO] info at lib/MyApp.pm line 11

  # log to stderr
  $log = Log::Minimal::Instance->new();

  # specified $Log::Minimal::LOG_LEVEL
  $log = Log::Minimal::Instance->new(
      level => 'WARN',
  );

  # original methods
  $log->infod(\%hash);
  $log->warnd(\@array);
  $log->log_to('finish.log.%Y%m%d', $message); # log to log/finish.log.20130101

=head1 DESCRIPTION

Log::Minimal::Instance is used in Log::Minimal based module to create an instance.

=head1 IMPORTED METHODS

See L<Log::Minimal>

=over 4

=item new(%args)

Create new instance of Log::Minimal::Instance based on L<Log::Minimal>.

Attributes are following:

=over 4

=item level

  Set to $Log::Minimal::LOG_LEVEL

=item base_dir

  Base directory for log file

=item pattern

  This is file name pattern that is same of L<File::Stamped>.

=item symlink

  Generate symlink file for log file.

=item callback

  See L<File::Stamped>.

=item close_after_write

  Default value is 1.

=item iomode

  Default value is '>>:utf8'.

=item autoflush

  Default value is true.

=item rotationtime

  Default value is true.

=item auto_make_dir

  Default value is false.

=back

=item critf

=item warnf

=item infof

=item debugf

=item critff

=item warnff

=item infoff

=item debugff

=back

=head1 ORIGINAL METHODS

=over 4

=item critd($value)

=item warnd($value)

=item infod($value)

=item debugd($value)

=back

When expressed in code the above methods:

  use Log::Minimal;
  infof( ddf(\%hash) );

=over 4

=item log_to($pattern, $message)

=item log_to([ $pattern, $symlink ], $message)

=item log_to({ pattern => $pattern, symlink => $symlink, ... }, $message)

  # $pattern is File::Stamped style.
  $log->log_to('trace.log.%Y%m%d', 'traceroute');

  # ./log/trace.log.20130101
  2013-01-01T16:15:40 traceroute at lib/MyApp.pm line 13

  # with symlink
  $log->log_to([ 'trace.log.%Y%m%d', 'trace.log' ], 'blah blah blah');

=back

=head1 AUTHOR

Kosuke Arisawa E<lt>arisawa {at} gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Kosuke Arisawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Minimal>

L<File::Stamped>

=cut
