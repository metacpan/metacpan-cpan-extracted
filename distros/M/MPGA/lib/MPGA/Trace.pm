package MPGA::Trace;

use strict;
use warnings;
use Sub::Util qw(subname);
use MPGA; # Загружаю ядро, чтобы получить доступ к его функциям

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(flow_trace flow_ctx_trace);

our $VERSION = '0.24';
our $TRACER; # Активный трассировщик

# Сохраняю ссылки на оригинальные функции ядра один раз при загрузке
my $orig_step  = \&MPGA::step;
my $orig_chunk = \&MPGA::chunk;

# Декоратор: перехват ДО выполнения бизнес-функции
sub chunk_trace {
    my ($flow) = @_;
    
    my ($fun, $args) = $orig_chunk->($flow);
    
    if (my $tracer = $TRACER) {
        if ($fun) {
            my $func_name = subname($fun) || 'ANONYMOUS';
            $tracer->("ВЫЗОВ: $func_name", $args, $flow);
        }
    }
    
    return ($fun, $args);
}

# Декоратор: перехват ПОСЛЕ выполнения бизнес-функции
sub step_trace {
    my ($flow, $ctx) = @_;
    
    $orig_step->($flow, $ctx);
    
    if (my $tracer = $TRACER) {
        $tracer->("ПОСЛЕ ВЫЗОВА", undef, $flow);
    }
}

# Функция запуска трассировки
sub flow_trace {
    # Всегда берем трассировщик с конца, чтобы $ctx и $max_steps могли быть опциональными
    my $tracer = pop;
    return if ref($tracer) ne 'CODE';

    my $flow      = shift;
    my $ctx       = shift;
    my $max_steps = shift || 0;

    local $TRACER = $tracer;
    
    no warnings 'redefine';
    local *MPGA::chunk = \&chunk_trace;
    local *MPGA::step  = \&step_trace; 

    MPGA::flow($flow, $ctx, $max_steps);
}

# Функция трассировки для потоков с контекстом
sub flow_ctx_trace {
    my $tracer = pop;
    return if ref($tracer) ne 'CODE';

    my $flow = shift;

    return if !$flow;
    return if ref($flow) ne 'ARRAY';
    return if !scalar @$flow;

    my $ctx = shift @$flow;
    flow_trace($flow, $ctx, 0, $tracer);
}

1;

__END__

=encoding utf8

=head1 NAME

MPGA::Trace - Real-time flow execution tracer for MPGA

=head1 SYNOPSIS

  use MPGA::Trace;

  my $tracer = sub {
      my ($msg, $args, $flow) = @_;
      print "$msg | Flow size: " . scalar(@$flow) . "\n";
  };

  # Standard trace
  flow_trace($flow_array, $ctx, $max_steps, $tracer);

  # Context trace
  flow_ctx_trace($flow_array, $tracer);

=head1 DESCRIPTION

This module provides decorators to monitor flow execution in real-time, 
hooking into execution before and after every function in the flow.

It safely uses typeglob aliasing to intercept calls without permanently 
altering the C<MPGA> module namespace.

=head1 FUNCTIONS

=head2 flow_trace( $flow, [$ctx, $max_steps,] $tracer_coderef )

Executes a flow with tracing enabled. The tracer receives:

=over 4

=item * C<$msg> - A string (e.g. "ВЫЗОВ: fun_name" or "ПОСЛЕ ВЫЗОВА")

=item * C<$args> - An array reference of arguments about to be passed

=item * C<$flow> - The current state of the flow

=back

=head2 flow_ctx_trace( $flow, $tracer_coderef )

Identical to C<flow_trace>, but extracts the first element of C<$flow> 
and uses it as the shared context.

=head1 AUTHOR

Nikolay Neustroev (NN)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1997-2026 by Nikolay Neustroev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
