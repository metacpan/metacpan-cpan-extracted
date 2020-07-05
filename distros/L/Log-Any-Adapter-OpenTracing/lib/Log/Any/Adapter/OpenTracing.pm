package Log::Any::Adapter::OpenTracing;
# ABSTRACT: provides Log::Any support for OpenTracing spans

use strict;
use warnings;

our $VERSION = '0.001';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(Log::Any::Adapter::Base);

no indirect;
use utf8;

=encoding utf8

=head1 NAME

Log::Any::Adapter::OpenTracing - Log::Any support for OpenTracing spans

=head1 SYNOPSIS

 use OpenTracing::DSL qw(:v1);
 use Log::Any qw($log);
 use Log::Any::Adapter qw(OpenTracing);
 trace {
  $log->info('Messages in a span should be logged');
 };
 $log->info('Messages outside a span would not be logged');

=head1 DESCRIPTION

This L<Log::Any::Adapter> implementation provides support for log messages attached
to L<OpenTracing::Span> instances.

It's most likely to be useful in conjunction with L<Log::Any::Adapter::Multiplexor>,
so that you keep STDERR/file logging and augment spans whenever they are active.

=cut

use Log::Any::Adapter::Util ();
use OpenTracing::Any qw($tracer);

# Copied directly from Log::Any::Adapter::Stderr
my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');

sub init {
    my ($self) = @_;
    if ( exists $self->{log_level} && $self->{log_level} =~ /\D/ ) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level( $self->{log_level} );
        if ( !defined($numeric_level) ) {
            require Carp;
            Carp::carp( sprintf 'Invalid log level "%s". Defaulting to "%s"', $self->{log_level}, 'trace' );
        }
        $self->{log_level} = $numeric_level;
    }
    if ( !defined $self->{log_level} ) {
        $self->{log_level} = $trace_level;
    }
}

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level($method);
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if $method_level > $self->{log_level};
        return unless my $span = $tracer->current_span;
        $span->log($text);
    };
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    my $base = substr( $method, 3 );
    my $method_level = Log::Any::Adapter::Util::numeric_level($base);
    *{$method} = sub {
        return !!( $method_level <= $_[0]->{log_level} );
    };
}

1;

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2019-2020. Licensed under the same terms as Perl itself.

