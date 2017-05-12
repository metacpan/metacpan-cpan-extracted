package Exception::Chain;
use 5.008005;
use strict;
use warnings;
use overload
    '""' => sub { $_[0]->to_string || $_[0] };

use Class::Accessor::Lite (
    ro => [qw/ delivery /],
);
use Data::Dumper;
use Data::Util qw(is_instance);

our $VERSION   = "0.11";
our $SkipDepth = 0;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        tags     => {},
        stack    => [],
        message  => undef,
        delivery => undef,
    }, $class;
}

sub _target_caller {
    my $class = shift;
    my $i = 0;
    while (my @caller = caller(++$i)) {
        unless ($caller[0] =~ /^Exception::Chain/) {
            my $level = $i + $SkipDepth;
            @caller = caller($level);
            return @caller;
        }
    }
}

sub _build_arg {
    my ($class, @info) = @_;

    if (scalar @info == 0) {
        return { };
    }
    elsif (scalar @info == 1) {
        if ($class->_is_my_instance($info[0])) {
            return { error => $info[0] };
        }
        else {
            return { message => $class->dumper($info[0]) };
        }
    }
    else {
        my %data = @info;
        my $ret = {};

        $ret->{message} = $class->dumper($data{message});
        for my $name (qw/tag error delivery/) {
            $ret->{$name} = $data{$name};
        }

        return $ret;
    }
}

sub _is_my_instance {
    my ($class, $instance) = @_;
    is_instance($instance, 'Exception::Chain');
}

sub dumper {
    my ($self, $value) = @_;
    if ( defined $value && ref($value) ) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Sortkeys = 1;
        return Data::Dumper::Dumper($value);
    }
    return $value;
}

sub throw {
    my ($class, @args) = @_;
    my $builded_args = $class->_build_arg(@args);
    my $self;
    if (not defined $builded_args->{error}) {
        $self = $class->new;
        $self->{message}  = $builded_args->{message};
    }
    elsif ($class->_is_my_instance($builded_args->{error})) {
        $self = delete $builded_args->{error};
    }
    else {
        $self = $class->new;
        push @{$self->{stack}}, $builded_args->{error};
        $self->rethrow(%{$builded_args});
    }
    $self->logging($builded_args);
    die $self;
}

sub rethrow {
    my ($self, @args) = @_;
    $self->logging($self->_build_arg(@args));
    die $self;
}

sub to_string {
    my $self = shift;
    my $string = join( ' ', @{$self->{stack}} );
    $string =~ s/\n//g;
    return $string;
}

sub match {
    my ($self, @tags) = @_;
    return scalar grep { defined $self->{tags}{$_} } @tags;
}

sub first_message {
    my $self = shift;
    return $self->{message};
}

sub add_message {
    my ($self, $message) = @_;
    $self->logging($self->_build_arg($message));
}

sub logging {
    my ($self, $args) = @_;

    my ($pkg, $file, $line) = $self->_target_caller;

    if (%{$args}) {
        if (my $tags = $args->{tag}) {
            $tags = [$tags] unless ref $tags;
            for my $tag (@$tags) {
                $self->{tags}{$tag} = 1;
            }
        }
        if (my $message = $args->{message}) {
            push @{$self->{stack}}, "$message at $file line $line.";
        }
        if (my $delivery = $args->{delivery}) {
            $self->{delivery} = $delivery;
        }
    }
    else {
        push @{$self->{stack}}, "at $file line $line.";
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Exception::Chain - It's chained exception module

=head1 SYNOPSIS

    use Exception::Chain;

    eval {
        process($params);
    };
    if (my $e = $@) {
        if ($e->match('critical')) {
            logging($e->to_string);
            # can not connect server at get_user line [A]. dbname=user is connection failed at get_user line [B]. request_id : [X] at process line [C].
        }
        if ($e->match('critical', 'internal server error')) { # or
            send_email($e->to_string);
        }

        if (my $error_response = $e->delivery) {
            return $error_response;
        }
        else {
            return HTTP::Response->(500, 'unknown error');
        }
    }

    sub process {
        my ($params) = @_;
        eval {
            get_user($params->{user_id});
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                error    => $e,
                tag      => 'internal server error',
                message  => sprintf('params : %s', $params->as_string),
                delivery => HTTP::Response->(500, 'internal server error'),
            );
        }
    }

    sub get_user {
        my ($user_id) = @_;
        eval {
            # die 'can not connect server',
        };
        if (my $e = $@) {
            Exception::Chain->throw(
                tag      => 'critical',
                message  => 'database error',
                error    => $e,
            );
        }
    }

=head1 DESCRIPTION

Exception::Chain is chained exception module

=head1 METHODS

=head2 throw(%info)

store a following value.

=over

=item tag ($info{tag})

=item message ($info{message})

=item delivery ($info{delivery})

=back

    throw($e); # Exception::Chain instance or message
    throw(
        tag     => 'critical',
        message => 'connection failed',
    )
    throw(
        tag     => ['critical', 'database error'],
        message => 'connection failed',
    )
    throw(
        tag     => ['critical', 'database error'],
        message => 'connection failed',
        error   => $@
    )
    throw(
        tag     => ['critical', 'database error'],
        message => 'connection failed',
        delivery => HTTP::Response->new( 500, 'internal server error' ),
    )

=head2 rethrow

rethrow exception object.

=head2 to_string

chained log.

=head2 first_message

first message.

=head2 match(@tags)

matching stored tag.

=head2 delivery

delivered object. (or scalar object)

=head1 GLOBAL VARIABLES

$Exception::Chain::SkipDepth

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>git@hixi-hyi.comE<gt>

=cut

