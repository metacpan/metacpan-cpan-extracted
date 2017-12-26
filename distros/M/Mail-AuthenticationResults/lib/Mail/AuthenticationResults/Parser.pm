package Mail::AuthenticationResults::Parser;
use strict;
use warnings;
our $VERSION = '1.20171226'; # VERSION

use Mail::AuthenticationResults::Header;
use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::SubEntry;
use Mail::AuthenticationResults::Header::Comment;

sub new {
    my ( $class, $auth_header ) = @_;
    my $self = {};
    bless $self, $class;

    if ( $auth_header ) {
        $self->parse( $auth_header );
    }

    return $self;
}

sub parse {
    my ( $self, $auth_header ) = @_;

    $auth_header =~ s/\n/ /g;

    my $server_id;
    ( $server_id, $auth_header ) = split( ';', $auth_header, 2 );
    $server_id =~ s/^\s+//;
    $server_id =~ s/\s+$//;

    $self->{ 'header' } = Mail::AuthenticationResults::Header->new()->set_value( $server_id );
    while ( $auth_header ) {
        my $acting_on = Mail::AuthenticationResults::Header::Entry->new();
        $auth_header = $self->_parse_auth_header( \$acting_on, $auth_header );
        $self->{ 'header' }->add_child( $acting_on );
    }
    return $self->parsed();
}

sub parsed {
    my ( $self ) = @_;
    return $self->{ 'header' };
}

sub _parse_auth_header {
    my ($self,$acting_on,$header) = @_;

    my $key;
    my $value;

    $header =~ s/^\s+//;
    ( $key, $value, $header ) = $self->_parse_auth_header_entry( $header );
    ${$acting_on}->{ 'key' }   = $key;
    ${$acting_on}->{ 'value' } = $value;

    $header = q{} if ! $header;

    my $comment_on = $acting_on;

    while ( length($header) > 0 ) {
        $header =~ s/^\s+//;
        if ( $header =~ /^\(/ ) {
            # We have a comment
            my $comment;
            ( $comment, $header ) = $self->_parse_auth_header_comment( $header );
            my $entry = Mail::AuthenticationResults::Header::Comment->new()->set_value( $comment );
            ${$comment_on}->add_child( $entry );
        }
        elsif ( $header =~ /^;/ ) {
            # We are at a separator
            $header =~ s/^;//;
            return $header;
        }
        else {
            # We have another entry
            ( $key, $value, $header ) = $self->_parse_auth_header_entry( $header );
            my $entry = Mail::AuthenticationResults::Header::SubEntry->new()->set_key( $key )->set_value( $value );
            $comment_on = \$entry;
            ${$acting_on}->add_child( $entry );
        }
        $header = q{} if ! $header;
    }

    return;
}

sub _parse_auth_header_comment {
    my ($self,$remain) = @_;
    my $value = q{};
    my $depth = 0;

    while ( length $remain > 0 ) {
        my $first = substr( $remain,0,1 );
        $remain   = substr( $remain,1 );
        $value .= $first;
        if ( $first eq '(' ) {
            $depth++;
        }
        elsif ( $first eq ')' ) {
            $depth--;
            last if $depth == 0;
        }
    }

    $value =~ s/^\(//;
    $value =~ s/\)$//;

    return($value,$remain);
}

sub _parse_auth_header_entry {
    my ($self,$remain) = @_;
    my $key = q{};
    my $value = q{};
    my $in = 'key';
    while ( length $remain > 0 ) {
        my $first = substr( $remain,0,1 );
        $remain   = substr( $remain,1 );
        if ( $in eq 'key' ) {
            if ( $first eq '=' ) {
                $in = 'value';
            }
            elsif ( $first =~ /\s/ ) {
                last;
            }
            elsif ( $first eq ';' ) {
                $remain = ';' . $remain;
                last;
            }
            else {
                $key .= $first;
            }
        }
        elsif ( $in eq 'value' ) {
            if ( $first =~ /\s/ ) {
                last;
            }
            elsif ( $first eq ';' ) {
                $remain = ';' . $remain;
                last;
            }
            else {
                $value .= $first;
            }
        }
    }

    return ($key,$value,$remain);
}

1;
