package Haineko::Root;
use feature ':5.10';
use strict;
use warnings;

sub index {
    # GET /
    use Haineko;
    my $class = shift;
    my $httpd = shift;
    my $neko1 = { 'name' => $httpd->name, 'version' => $Haineko::VERSION };

    return $httpd->res->json( 200, $neko1 );
}

sub info {
    # GET /dump, /conf
    my $class = shift;
    my $httpd = shift;

    my $xforwarded = [ split( ',', $httpd->req->header('X-Forwarded-For') || q() ) ];
    my $remoteaddr = pop @$xforwarded || $httpd->req->address // undef;
    my $ip4network = undef;

    # Only 127.0.0.1 is permitted
    use Net::CIDR::Lite;
    $ip4network = Net::CIDR::Lite->new( '127.0.0.1/32' );

    if( $ip4network->find( $remoteaddr ) ) {

        my $requesturl = $httpd->req->path_info;
        my $configfile = q();
        my $configdata = {};
        my $smtpconfig = undef;

        if( $requesturl eq '/dump' ) {
            # /dump
            use Data::Dumper;
            return $httpd->res->text( 200, Data::Dumper::Dumper $httpd );

        } else {
            # /conf
            use Haineko::JSON;
            use File::Basename;

            if( defined $ENV{'HAINEKO_CONF'} ) {

                if( -f -r -s $ENV{'HAINEKO_CONF'} ) {
                    # HAINEKO_CONF=/path/to/haineko.cf
                    $configfile = $ENV{'HAINEKO_CONF'};

                } else {
                    $configfile = 'Haineko::Default->conf' 
                }
            }

            $configdata->{'haineko.cf'} = { 
                            'path' => $configfile,
                            'data' => $httpd->conf,
            };
            $smtpconfig = $configdata->{'haineko.cf'}->{'data'}->{'smtpd'};

            for my $e ( 'mailer', 'access' ) {
                # mailer: auth, mail, rcpt
                # access: conn, rcpt
                for my $f ( keys %{ $smtpconfig->{ $e } } ) {
                    # Load mailertables, access configurations
                    my $g = $smtpconfig->{ $e }->{ $f };
                    my $h = File::Basename::basename $g; $h =~ s/[-]debug\z//;

                    $configdata->{ $h } = {
                        'path' => undef,
                        'data' => undef,
                    };
                    next unless -f -r -s $g;

                    $configdata->{ $h }->{'path'} = $g;
                    $configdata->{ $h }->{'data'} = Haineko::JSON->loadfile( $g );

                    next unless $h eq 'authinfo';
                    for my $i ( keys %{ $configdata->{'authinfo'}->{'data'} } ) {
                        # Mask username and password with '*'
                        my $j = $configdata->{'authinfo'}->{'data'}->{ $i };
                        $j->{'username'} =~ s/\A(.).+\z/$1*******/;
                        $j->{'password'} =  '********';
                    }
                }
            }

            if( defined $ENV{'HAINEKO_AUTH'} && -f -r -s $ENV{'HAINEKO_AUTH'} ) {
                # Load password file
                $configdata->{'password'} = {
                    'path' => $ENV{'HAINEKO_AUTH'},
                    'data' => Haineko::JSON->loadfile( $ENV{'HAINEKO_AUTH'} ),
                };
            }

            return $httpd->res->json( 200, Haineko::JSON->dumpjson( $configdata ) );
        }

    } else {
        # Respond "Access denied" as a JSON
        require Haineko::SMTPD::Response;
        require Haineko::SMTPD::Session;

        my $mesg = Haineko::SMTPD::Response->r( 'http', 'forbidden' )->damn;
        my $argv = {
            'referer'    => $httpd->req->referer // undef,
            'response'   => [ $mesg ],
            'remoteaddr' => $remoteaddr,
            'remoteport' => $httpd->req->env->{'REMOTE_ADDR'} // undef,
            'useragent'  => $httpd->req->user_agent // undef,
        };
        my $sess = Haineko::SMTPD::Session->new( %$argv )->damn;

        $sess->{'queueid'} = undef;
        return $httpd->response->json( 403, $sess );
    }
}

sub neko {
    # GET /neko
    my $class = shift;
    my $httpd = shift;

    return $httpd->res->text( 200, 'Nyaaaaa' );
}

1;
__END__
=encoding utf-8

=head1 NAME

Haineko::Root - Controller except /submit

=head1 DESCRIPTION

Haineko::Root is a controller except url /submit. The module provide following
URLs: /conf, /dump, and /neko.

=head2 URL

    http://127.0.0.1:2794/

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
