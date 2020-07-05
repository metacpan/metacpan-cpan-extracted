package Markdent::Role::Event;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::Types;

use MooseX::Role::Parameterized;

parameter event_class => (
    is       => 'ro',
    isa      => t('Str'),
    required => 1,
);

role {
    my $p = shift;

    my $class = $p->event_class();
    my ( $action, $event ) = $class =~ /::(Start|End)?(\w+)$/;

    # It's easier to hack this in rather than trying to find a general
    # case for upper-case abbreviations in class names.
    $event =~ s/HTML/html/;

    $event =~ s/(^|.)([A-Z])/$1 ? "$1\L_$2" : "\L$2"/ge;

    my $event_name = join q{_}, map {lc} grep {defined} $action, $event;
    method event_name => sub {$event_name};

    method name => sub {$event};

    my $is_start = ( $action || q{} ) eq 'Start';
    method is_start => sub {$is_start};

    my $is_end = ( $action || q{} ) eq 'End';
    method is_end => sub {$is_end};

    my $is_inline = !defined $action;
    method is_inline => sub {$is_inline};

    my @required;
    my @optional;

    for my $attr ( grep { $_->name() !~ /^_/ }
        $class->meta()->get_all_attributes() ) {

        my $name = $attr->name();

        if ( $attr->is_required() ) {
            push @required, [ $name, $attr->get_read_method() ];
        }
        else {
            die
                "All optional attributes for an event must have a predicate or default value ($class - $name)"
                unless $attr->has_predicate()
                || $attr->has_default()
                || $attr->has_builder();

            push @optional,
                [
                $name,
                $attr->get_read_method(),
                $attr->predicate()
                ];
        }
    }

    _make_kv_pairs_for_attribute_method( \@required, \@optional );
};

sub _make_kv_pairs_for_attribute_method {
    my @required = @{ shift() };
    my @optional = @{ shift() };

    method kv_pairs_for_attributes => sub {
        my $event = shift;

        my %p;

        for my $pair (@required) {
            my ( $name, $reader ) = @{$pair};

            $p{$name} = $event->$reader();
        }

        for my $triplet (@optional) {
            my ( $name, $reader, $pred ) = @{$triplet};

            next if $pred && !$event->$pred();

            $p{$name} = $event->$name();
        }

        return %p;
    };
}

sub debug_dump {
    my $self = shift;

    my $dump = '  - ' . $self->event_name() . "\n";

    for my $attr ( sort { $a->name() cmp $b->name() }
        $self->meta()->get_all_attributes() ) {
        my $name   = $attr->name();
        my $reader = $attr->get_read_method();
        my $pred   = $attr->predicate();

        next if $pred && !$self->$pred();

        my $val = $self->$reader();

        if ( ref $val && ref $val eq 'ARRAY' ) {
            $dump .= sprintf( '    %-16s: |%s|', $name, $val->[0] );
            $dump .= "\n";

            for my $v ( @{$val}[ 1 .. $#{$val} ] ) {
                $self->_debug_value($v);

                $dump .= q{ } x 22;
                $dump .= "|$v|\n";
            }
        }
        elsif ( ref $val && ref $val eq 'HASH' ) {
            $dump .= sprintf( '    %-16s:', $name );
            $dump .= "\n";

            for my $k ( sort keys %{$val} ) {
                $dump .= q{ } x 22;
                $dump .= sprintf(
                    '%-16s: %s', $k,
                    $self->_debug_value( $val->{$k} )
                );
                $dump .= "\n";
            }
        }
        else {
            $dump .= sprintf(
                '    %-16s: %s', $name,
                $self->_debug_value($val)
            );
            $dump .= "\n";
        }
    }

    return $dump;
}

sub _debug_value {
    return defined $_[1] ? $_[1] : '<undef>';
}

1;

# ABSTRACT: Implements behavior shared by all events

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Role::Event - Implements behavior shared by all events

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This role provides shared behavior for all event classes. It is actually
somewhat of a hack, as it is a parameterized role that generates methods for
each class that consumes it.

=head1 METHODS

This role provides the following methods:

=head2 $event->is_start()

=head2 $event->is_end()

=head2 $event->is_inline()

These all returns booleans indicating whether the event is of the specified
type.

=head2 $event->event_name()

This returns a name like "start_blockquote", "end_strong", or "text".

=head2 $event->kv_pairs_for_attributes()

This returns a hash representing the data stored in the object's
attributes. If an attribute is not required and has not been set, it will not
be present in the hash.

=head2 $event->debug_dump()

Returns a string representation of the event suitable for debugging output.

=head1 BUGS

See L<Markdent> for bug reporting details.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
