package HTTP::Proxy::GreaseMonkey::Redirector;

use warnings;
use strict;
use Carp;
use JSON;
use HTTP::Response;
use HTML::Tiny;
use YAML qw( DumpFile LoadFile );
use LockFile::Simple qw( lock unlock );

use base qw( HTTP::Proxy::HeaderFilter );

=head1 NAME

HTTP::Proxy::GreaseMonkey::Redirector - Proxy cross-site requests

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey::Redirector version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS
  
=head1 DESCRIPTION

=head1 INTERFACE 

=head2 C<< passthru >>

Set the passthru key.

=cut

sub passthru {
    my $self = shift;
    my $key  = quotemeta shift;
    $self->{passthru} = qr{ ^/ $key 
                 / ( [-a-z0-9]+ (?: \. [-a-z0-9]+ )+ ) 
                 (/.*) $}xi;
    $self->{internal} = qr{ ^/ $key 
                 / \$ internal \$ $ }xi;
}

=head2 C<< filter >>

Filter the request headers.

=cut

sub filter {
    my ( $self, $headers, $message ) = @_;

    my $passthru = $self->{passthru} || return;

    my $uri  = $message->uri;
    my $path = $uri->path;

    # print "$path, $self->{internal}\n";

    if ( $path =~ $self->{internal} ) {
        $self->proxy->response(
            $self->_despatch_internal(
                $headers, $message, $uri->query
            )
        );
    }
    elsif ( $path =~ $passthru ) {
        # Redirect
        my $real_uri = $uri->scheme . '://' . $1 . $2;
        if ( my $query = $uri->query ) {
            $real_uri = join '?', $real_uri, $query;
        }
        $message->uri( $real_uri );
        $headers->header( host => $1 );
    }
}

=head2 C<< state_file >>

Set the name of the file that will be used to store state.

=cut

sub state_file {
    my $self = shift;
    $self->{state_file} = shift if @_;
    croak "No state_file defined" unless defined $self->{state_file};
    return $self->{state_file};
}

sub _load_state {
    my $file = shift->state_file;
    return -f $file ? LoadFile( $file ) : {};
}

sub _save_state {
    DumpFile( shift->state_file, @_ );
}

sub _locked {
    my ( $self, $func ) = @_;
    my $file = $self->state_file;
    lock( $file );
    my @res = $func->();
    unlock( $file );
    return @res;
}

sub _despatch_internal {
    my ( $self, $headers, $message, $query ) = @_;
    my $result = eval {
        # JSON == YAML, right?
        my %handler = (
            setValue => sub {
                my ( $args, $name, $val ) = @_;
                $self->_locked(
                    sub {
                        my $state = $self->_load_state;
                        $state->{ $args->{ns} }->{ $args->{n} }->{$name}
                          = $val;
                        $self->_save_state( $state );
                    }
                );
                return 1;
            },
            getValue => sub {
                my ( $args, $name, $dflt ) = @_;
                my ( $state )
                  = $self->_locked( sub { $self->_load_state } );
                my $val
                  = $state->{ $args->{ns} }->{ $args->{n} }->{$name};
                return defined $val ? $val : $dflt;
            },
            log => sub {
                my ( $args, @argv ) = @_;
                print join( ': ', $args->{n}, join( '', @argv ) ), "\n";
                return 1;
            },
        );

        my $h    = $self->{_html} ||= HTML::Tiny->new;
        my $qs   = $h->url_decode( $query );
        my $args = from_json( $qs );

        my $method = delete $args->{m}
          || die "Missing 'm' arg";
        my $code = $handler{$method}
          || die "No method $method";

        my @arguments = @{ delete $args->{a} || [] };

        my $result = $code->( $args, @arguments );

        return HTTP::Response->new(
            200, 'OK',
            [ 'content_type' => 'application/json' ],
            to_json( [$result] )
        );
    };

    if ( $@ ) {
        ( my $err = $@ ) =~ s/\s+/ /g;
        print "Error: $err\n";
        return HTTP::Response->new( 500, $err );
    }

    return $result;
}

1;

__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
HTTP::Proxy::GreaseMonkey::Redirector requires no configuration files or
environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-http-proxy-greasemonkey@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
