package Log::LTSV::Instance;
use 5.008001;
use strict;
use warnings;
use Time::Piece;
use File::RotateLogs;
use Data::Dumper;
use Carp;
use Log::LTSV::Instance::Flatten;

our $VERSION = "0.06";

my %LOG_LEVEL_MAP = (
    DEBUG    => 1,
    INFO     => 2,
    WARN     => 3,
    CRITICAL => 4,
    ERROR    => 99,
);

sub new {
    my ($class, %args) = @_;

    my $level = $LOG_LEVEL_MAP{$args{level} || 'DEBUG'};

    Carp::croak("level required ERROR or CRITICAL or WARN or INFO or DEBUG") unless $level;

    my ($logger, $rotatelogs);
    if ($args{logger}) {
        $logger = $args{logger};
    } elsif (not defined $args{logfile}) {
        $logger = sub { print @_ };
    } else {
        my $rotatelogs = File::RotateLogs->new(
            logfile      => $args{logfile},
            defined $args{maxage} ? ( maxage => $args{maxage} ) : (),
            $args{linkname} ? ( linkname     => $args{linkname} ) : (),
            $args{rotationtime} ? ( rotationtime => $args{rotationtime} ) : (),
        );
        $logger = sub { $rotatelogs->print(@_) };
    }

    my $flatten = Log::LTSV::Instance::Flatten->new;

    bless {
        rotatelogs  => $rotatelogs,
        logger      => $logger,
        level       => $level,
        sticks      => {},
        default_key => $args{default_key} || 'message',
        _flatten    => $flatten,
    }, $class;
}

sub error { shift->print('ERROR', @_) }
sub crit  { shift->print('CRITICAL', @_) }
sub warn  { shift->print('WARN', @_) }
sub info  { shift->print('INFO', @_) }
sub debug { shift->print('DEBUG', @_) }

sub sticks {
    my ($self, @args) = @_;
    while (@args) {
        my ($key, $value) = splice @args, 0, 2;
        $self->{sticks}{$key} = $value;
    }
}

sub _escape {
    my ($self, $val) = @_;

    $val =~ s/\t/\\t/g;
    $val =~ s/\n/\\n/g;

    return $val;
}

sub labeled_values {
    my ($self, $key, $value) = @_;
    my %lv = $self->{_flatten}->flatten($key, $value);
    $lv{$_} = $self->_escape($lv{$_}) for ( keys %lv );
    map { join ':', $_, $lv{$_} } keys %lv;
}

sub print {
    my ($self, $level, @args) = @_;
    return if ($LOG_LEVEL_MAP{$level} < $self->{level});

    if (ref $args[0] eq 'HASH') {
        @args = %{ $args[0] };
    } elsif ( scalar @args == 1 && ref $args[0] eq '' ) {
        @args = ( $self->{default_key} => $args[0] );
    }

    my @msgs;

    push @msgs, sprintf("time:%s", localtime->datetime);
    push @msgs, "log_level:$level";

    for my $key (keys %{ $self->{sticks} }) {
        my $value = $self->{sticks}->{$key};
        $value = $value->() if ref $value;
        push @msgs, $self->labeled_values($key, $value);
    }

    while (@args) {
        my ($key, $value) = splice @args, 0, 2;
        push @msgs, $self->labeled_values($key, $value);
    }
    my $ltsv = join "\t", @msgs;
    $self->{logger}->($ltsv."\n");
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::LTSV::Instance - LTSV logger

=head1 SYNOPSIS

    use Log::LTSV::Instance;
    my $logger = Log::LTSV::Instance->new(
        logger => sub { print @_ },
        level  => 'DEBUG',
    );
    $logger->crit(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:CRITICAL      msg:hungup

=head1 DESCRIPTION

Log::LTSV::Instance is LTSV logger.

cf. http://ltsv.org/

=head1 METHODS

=head2 new

=over

=item logger

=item level

=back

=head2 ( error / crit / warn / info / debug )

    $logger->error(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:ERROR      msg:hungup

    $logger->crit(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:CRITICAL      msg:hungup

    $logger->warn(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:WARN      msg:hungup

    $logger->info(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:INFO      msg:hungup

    $logger->debug(msg => 'hungup');
    # time:2015-03-06T22:27:40        log_level:INFO      msg:hungup

=head2 sticks

    $logger->sticks(
        id   => 1,
        meta => sub {
            my @caller = caller(2);
            {
                file => $caller[1],
                line => $caller[2],
            }
        },
    );
    $logger->crit(msg => 'hungup');
    # time:2015-03-06T22:27:40      log_level:CRITICAL    id:1      meta.file:t/print.t     meta.line:115       msg:hungup
    $logger->info(msg => 'hungup');
    # time:2015-03-06T22:27:40      log_level:INFO    id:1      meta.file:t/print.t     meta.line:115       msg:hungup


=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>git@hixi-hyi.comE<gt>

=cut

