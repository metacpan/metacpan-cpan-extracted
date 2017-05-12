# NAME

Exception::Chain - It's chained exception module

# SYNOPSIS

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

# DESCRIPTION

Exception::Chain is chained exception module

# METHODS

## throw(%info)

store a following value.

- tag ($info{tag})
- message ($info{message})
- delivery ($info{delivery})

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

## rethrow

rethrow exception object.

## to\_string

chained log.

## first\_message

first message.

## match(@tags)

matching stored tag.

## delivery

delivered object. (or scalar object)

# GLOBAL VARIABLES

$Exception::Chain::SkipDepth

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <git@hixi-hyi.com>
