package Log::Any::Adapter::Multiplex;
# ABSTRACT: Adapter to use allow structured logging across other adapters
our $VERSION = '1.710';

use Log::Any;
use Log::Any::Adapter;
use Log::Any::Adapter::Util qw(make_method);
use Log::Any::Manager;
use Log::Any::Proxy;
use Carp;
use strict;
use warnings;
use base qw(Log::Any::Adapter::Base);

sub init {
    my $self = shift;

    my $adapters = $self->{adapters};
    if ( ( ref($adapters) ne 'HASH' ) ||
         ( grep { ref($_) ne 'ARRAY' } values %$adapters ) ) {
        Carp::croak("A list of adapters and their arguments must be provided");
    }
}

sub structured {
    my ($self, $level, $category, @structured_log_args) = @_;
    my %adapters = %{ $self->{adapters} };
    my $unstructured_log_args;

    for my $adapter ( $self->_get_adapters($category) ) {
        my $is_level = "is_$level";

        if ($adapter->$is_level) {
            # Very simple mimicry of Log::Any::Proxy
            # We don't have to handle anything but the difference in
            # non-structured interfaces
            if ($adapter->can('structured')) {
                $adapter->structured($level, $category, @structured_log_args)
            }
            else {
                if (!$unstructured_log_args) {
                    $unstructured_log_args = [
                        _unstructured_log_args( @structured_log_args )
                    ];
                }
                $adapter->$level(@$unstructured_log_args);
            }
        }
    }
}

sub _unstructured_log_args {
    my @structured   = @_;
    my @unstructured = @structured;

    if ( @structured && ( ( ref $structured[-1] ) eq ref {} ) ) {
        @unstructured = (
            @structured[ 0 .. $#structured - 1 ],
            Log::Any::Proxy::_stringify_params( $structured[-1] ),
        )
    }
    return @unstructured;
}

# Delegate detection methods to other adapters
#
foreach my $method ( Log::Any->detection_methods() ) {
    make_method(
        $method,
        sub {
            my ($self) = @_;
            # Not using List::Util::any because it could break older perl builds
            my @logging_adaptors = grep { $_->$method } $self->_get_adapters();
            return @logging_adaptors ? 1 : 0;
        }
    );
}

sub _get_adapters {
    my ($self) = @_;
    my $category = $self->{category};
    # Log::Any::Manager#get_adapter has similar code
    # But has to handle rejiggering the stack
    # And works with one adapter at a time (instead of a list, as below)
    # Keeping track of multiple categories here is just future-proofing.
    #
    my $category_cache = $self->{category_cache};
    if ( !defined( $category_cache->{$category} ) ) {
        my $new_cache = [];
        my %adapters = %{ $self->{adapters} };
        while ( my ($adapter_name, $adapter_args) = each %adapters ) {
            my $adapter_class = Log::Any::Manager->_get_adapter_class($adapter_name);
            push @$new_cache, $adapter_class->new(
                @$adapter_args,
                category => $category
            );
        }

        $self->{category_cache}{$category} = $new_cache;
    }

    return @{ $self->{category_cache}{$category} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Multiplex - Adapter to use allow structured logging across other adapters

=head1 VERSION

version 1.710

=head1 SYNOPSIS

    Log::Any::Adapter->set(
        'Multiplex',
        adapters => {
            'Stdout' => [],
            'Stderr' => [ log_level => 'warn' ],
            ...
            $adapter => \@adapter_args
        },
    );

=head1 DESCRIPTION

This built-in L<Log::Any> adapter provides a simple means of routing logs to
multiple other L<Log::Any::Adapter>s.

Adapters receiving messages from this adapter can behave just like they are the
only recipient of the log message. That means they can, for example, use
L<Log::Any::Adapter::Development/Structured logging> (or not).

C<adapters> is a hashref whose keys should be adapters, and whose
values are the arguments to pass those adapters on initialization.

Note that this differs from other loggers like L<Log::Dispatch>, which will
only provide its output modules a single string C<$message>, and not the full
L<Log::Any/Log context data>.

=head1 SEE ALSO

L<Log::Any>, L<Log::Any::Adapter>

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
