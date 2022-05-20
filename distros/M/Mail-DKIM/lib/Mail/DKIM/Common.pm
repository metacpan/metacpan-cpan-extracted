package Mail::DKIM::Common;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: Common class for Mail::DKIM

# Copyright 2005-2007 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Mail::Address;

use base 'Mail::DKIM::MessageParser';
use Carp;

sub new {
    my $class = shift;
    return $class->new_object(@_);
}

sub add_header {
    my $self = shift;
    my ($line) = @_;

    foreach my $algorithm ( @{ $self->{algorithms} } ) {
        $algorithm->add_header($line);
    }

    if ( $line =~ /^([^:]+?)\s*:(.*)/s ) {
        my $field_name = lc $1;
        my $contents   = $2;
        $self->handle_header( $field_name, $contents, $line );
    }
    push @{ $self->{headers} }, $line;
}

sub add_body {
    my $self = shift;
    if ( $self->{algorithm} ) {
        $self->{algorithm}->add_body(@_);
    }
    foreach my $algorithm ( @{ $self->{algorithms} } ) {
        $algorithm->add_body(@_);
    }
}

sub handle_header {
    my $self = shift;
    my ( $field_name, $contents, $line ) = @_;

    push @{ $self->{header_field_names} }, $field_name;

    # TODO - detect multiple occurrences of From: or Sender:
    # header and reject them

    $self->{headers_by_name}->{$field_name} = $contents;
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    #initialize variables
    $self->{headers}            = [];
    $self->{headers_by_name}    = {};
    $self->{header_field_names} = [];
}

sub load {
    my $self = shift;
    my ($fh) = @_;

    while (<$fh>) {
        $self->PRINT($_);
    }
    $self->CLOSE;
}

sub message_attributes {
    my $self = shift;
    my @attributes;

    if ( my $message_id = $self->message_id ) {
        push @attributes, "message-id=<$message_id>";
    }

    if ( my $sig = $self->signature ) {
        push @attributes, 'signer=<' . $sig->identity . '>';
    }

    if ( $self->{headers_by_name}->{sender} ) {
        my @list = Mail::Address->parse( $self->{headers_by_name}->{sender} );
        if ( $list[0] ) {
            push @attributes, 'sender=<' . $list[0]->address . '>';
        }
    }
    elsif ( $self->{headers_by_name}->{from} ) {
        my @list = Mail::Address->parse( $self->{headers_by_name}->{from} );
        if ( $list[0] ) {
            push @attributes, 'from=<' . $list[0]->address . '>';
        }
    }

    return @attributes;
}

sub message_id {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );

    if ( my $message_id = $self->{headers_by_name}->{'message-id'} ) {
        if ( $message_id =~ /^\s*<(.*)>\s*$/ ) {
            return $1;
        }
    }
    return undef;
}

sub message_originator {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );

    if ( $self->{headers_by_name}->{from} ) {
        my @list = Mail::Address->parse( $self->{headers_by_name}->{from} );
        return $list[0] if @list;
    }
    return Mail::Address->new;
}

sub message_sender {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );

    if ( $self->{headers_by_name}->{sender} ) {
        my @list = Mail::Address->parse( $self->{headers_by_name}->{sender} );
        return $list[0] if @list;
    }
    if ( $self->{headers_by_name}->{from} ) {
        my @list = Mail::Address->parse( $self->{headers_by_name}->{from} );
        return $list[0] if @list;
    }
    return Mail::Address->new;
}

sub result {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );
    return $self->{result};
}

sub result_detail {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );

    if ( $self->{details} ) {
        return $self->{result} . ' (' . $self->{details} . ')';
    }
    return $self->{result};
}

sub signature {
    my $self = shift;
    croak 'wrong number of arguments' unless ( @_ == 0 );
    return $self->{signature};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::Common - Common class for Mail::DKIM

=head1 VERSION

version 1.20220520

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
