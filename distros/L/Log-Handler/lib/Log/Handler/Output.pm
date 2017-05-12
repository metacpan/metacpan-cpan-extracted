=head1 NAME

Log::Handler::Output - The output builder class.

=head1 DESCRIPTION

Just for internal usage!

=head1 METHODS

=head2 new()

=head2 log()

=head2 reload()

=head2 flush()

=head2 errstr()

=head1 PREREQUISITES

    Carp
    UNIVERSAL

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler::Output;

use strict;
use warnings;
use Carp;
use UNIVERSAL;

our $VERSION = "0.10";
our $ERRSTR  = "";

sub new {
    my ($class, $options, $output) = @_;
    my $self = bless $options, $class;
    $self->{output} = $output;
    return $self;
}

sub log {
    my $self = shift;
    my $level = shift;
    my $output = $self->{output};
    my $message = { };
    my $wanted = { message => join(" ", grep defined, @_) };

    # The patterns must be generated for each output. The reason
    # is that each output can have their own time/date format
    # and the code which is executed can return another value.
    foreach my $r (@{$self->{wanted_pattern}}) {
        $wanted->{$r->{name}} = &{$r->{code}}($self, $level);
    }

    if ($self->{message_pattern}) {
        &{$self->{message_pattern_code}}($wanted, $message);
    }

    if ($self->{message_layout}) {
        &{$self->{message_layout_code}}($wanted, $message);
    } else {
        $message->{message} = $wanted->{message};
    }

    if ($self->{message_pattern}) {
        if ($message->{message}) {
            $wanted->{message} = $message->{message};
        }
        &{$self->{message_pattern_code}}($wanted, $message);
    }

    if ($self->{debug_trace} || $Log::Handler::TRACE) {
        $self->_add_trace($message);
    }

    if ($self->{skip_message} && $message->{message} =~ /$self->{skip_message}/) {
        return 1;
    }

    if ($self->{filter_message}) {
        $self->_filter_msg($message) or return 1;
    }

    if ($self->{prepare_message}) {
        eval { &{$self->{prepare_message}}($message) };
        if ($@) {
            return $self->_raise_error("prepare_message failed - $@");
        }
    }

    if ($self->{newline} && $message->{message} !~ /(?:\015|\012)\z/) {
        $message->{message} .= "\n";
    }

    # The substr solution to determine if a newline exists
    # at the end of the message is ~60% faster than the regex.
    # Maybe it will be released in the future.
    #if ($self->{newline}) {
    #    my $last = substr $message->{message}, -1, 1;
    #    if ($last eq "\015" || $last eq "\012" || $last eq "\015\012" || $last eq "\012\015") {
    #        $message->{message} .= "\n";
    #    }
    #}

    $output->log($message)
        or return $self->_raise_error($output->errstr);

    return 1;
}

sub flush {
    my $self   = shift;
    my $output = $self->{output};

    if ( UNIVERSAL::can($output, "flush") ) {
        $output->flush
            or return $self->_raise_error($output->errstr);
    }

    return 1;
}

sub reload {
    my ($self, $opts) = @_;

    foreach my $key (keys %$opts) {
        $self->{$key} = $opts->{$key};
    }
}

sub errstr {
    return $ERRSTR;
}

#
# private stuff
#

sub _add_trace {
    my ($self, $message) = @_;
    my @caller = ();
    my $skip   = $self->{debug_skip};

    if ( $message->{message} =~ /.\z/ ) {
        $message->{message} .= "\n";
    }

    for (my $i=0; my @c = caller($i); $i++) {
        my %frame;
        @frame{qw/package filename line subroutine hasargs wantarray evaltext is_require/} = @c[0..7];
        push @caller, \%frame;
    }

    foreach my $i (reverse $skip..$#caller) {
        $message->{message} .= " " x 3 . "CALL($i):";
        my $frame = $caller[$i];
        foreach my $key (qw/package filename line subroutine hasargs wantarray evaltext is_require/) {
            next unless defined $frame->{$key};
            if ($self->{debug_mode} == 1) { # line mode
                $message->{message} .= " $key($frame->{$key})";
            } elsif ($self->{debug_mode} == 2) { # block mode
                $message->{message} .= "\n" . " " x 6 . sprintf("%-12s", $key) . $frame->{$key};
            }
        }
        $message->{message} .= "\n";
    }
}

sub _filter_msg {
    my ($self, $message) = @_;
    my $filter = $self->{filter_message};
    my $result = $filter->{result};
    my $code   = $filter->{code};
    my $return = ();

    if (!$filter->{condition}) {
        $return = &$code($message) || 0;
    } else {
        foreach my $match ( keys %$result ) {
            $result->{$match} =
                $message->{message} =~ /$filter->{$match}/ || 0;
        }
        $return = &$code($result);
    }

    return $return;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef unless $self->{die_on_errors};
    my $class = ref($self);
    Carp::croak "$class: $ERRSTR";
}

1;
