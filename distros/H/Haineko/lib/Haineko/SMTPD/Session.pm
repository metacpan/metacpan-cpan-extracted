package Haineko::SMTPD::Session;
use feature ':5.10';
use strict;
use warnings;
use Class::Accessor::Lite;
use Haineko::SMTPD::Response;
use Haineko::SMTPD::Address;
use Time::Piece;

my $rwaccessors = [
    'stage',        # (Integer)
    'started',      # (Time::Piece) When it connected
    'response',     # (Ref->Array->Haineko::SMTPD::Response) SMTP Reponse
    'addresser',    # (Haineko::SMTPD::Address) Envelope sender
    'recipient',    # (Ref->Arrey->Haineko::SMTPD::Address) Envelope recipients
];
my $roaccessors = [
    'queueid',      # (String) Queue ID
    'referer',      # (String) HTTP REFERER
    'useragent',    # (String) User agent name
    'remoteaddr',   # (String) Client IP address
    'remoteport',   # (String) Client port number
];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$rwaccessors );
Class::Accessor::Lite->mk_ro_accessors( @$roaccessors );


sub new {
    my $class = shift;
    my $argvs = { @_ };
    my $nekor = $argvs->{'response'} || undef;
    my $nekos = {
        'stage'    => $argvs->{'stage'} // 0,
        'started'  => Time::Piece->new,
        'queueid'  => $argvs->{'queueid'}  || __PACKAGE__->make_queueid,
    };

    if( $nekor ) {
        if( ref $nekor eq 'Haineko::SMTPD::Response' ) {
            # Response in the argument is an object
            $nekos->{'response'} = [ $nekor ];

        } elsif( ref $nekor eq 'ARRAY' ) {
            # Response in the argument is an array reference
            $nekos->{'response'} = [];
            for my $e ( @$nekor ) {
                # Check each item:
                #   Haineko::SMTPD::Response object or HASH reference
                if( ref $e eq 'Haineko::SMTPD::Response' ) {
                    push @{ $nekos->{'response'} }, $e;

                } elsif( ref $e eq 'HASH' ) {
                    # Create Haineko::SMTPD::Response object from the HASH reference
                    push @{ $nekos->{'response'} }, Haineko::SMTPD::Response->new( %$e );
                }
            }
        }
    }
    map { $nekos->{ $_ } ||= $argvs->{ $_ } || undef } @$roaccessors;

    while(1) {
        # Create email address objects
        my $c = 'Haineko::SMTPD::Address';
        my $r = [];
        my $t = $argvs->{'recipient'} || [];

        map { push @$r, $c->new( 'address' => $_ ) } @$t;
        $nekos->{'recipient'} = $r if scalar @$r;

        last unless defined $argvs->{'addresser'};
        $nekos->{'addresser'} = $c->new( 'address' => $argvs->{'addresser'} );

        last;
    }
    return bless $nekos, __PACKAGE__;
}

sub make_queueid {
    my $class = shift;
    my $size1 = 16;
    my $time1 = new Time::Piece;
    my $chars = [ '0'..'9', 'A'..'Z', 'a'..'x' ];
    my $idstr = q();
    my $queue = {
        'Y' => $chars->[ $time1->_year % 60 ],
        'M' => $chars->[ $time1->_mon ],
        'D' => $chars->[ $time1->mday ],
        'h' => $chars->[ $time1->hour ],
        'm' => $chars->[ $time1->min ],
        's' => $chars->[ $time1->sec ],
        'q' => $chars->[ int rand(60) ],
        'p' => sprintf( "%05d", $$ ),
    };

    $idstr .= $queue->{ $_ } for ( qw/Y M D h m s q p/ );

    while(1) {
        $idstr .= $chars->[ int rand( scalar( @$chars ) ) ];
        last if length $idstr == $size1;
    }
    return $idstr; 
}

sub done {
    my $class = shift;
    my $argvs = shift || return 0;  # (String) SMTP Command
    my $value = {
        'ehlo' => ( 1 << 0 ),
        'auth' => ( 1 << 1 ),
        'mail' => ( 1 << 2 ),
        'rcpt' => ( 1 << 3 ),
        'data' => ( 1 << 4 ),
        'quit' => ( 1 << 5 ),
    };
    return $value->{ $argvs } || 0;
}

sub add_response {
    my $self = shift;
    my $argv = shift || return $self;

    return $self unless ref $argv eq 'Haineko::SMTPD::Response';
    push @{ $self->{'response'} }, $argv;
    return $self;
}

sub ehlo { 
    my $self = shift; 
    my $argv = shift || 0;  # (Integer)
    my $ehlo = __PACKAGE__->done('ehlo');
    $self->{'stage'} = $ehlo if $argv;
    return $self->{'stage'} & $ehlo ? 1 : 0;
}

sub auth {
    my $self = shift;
    my $argv = shift || 0;
    my $auth = __PACKAGE__->done('auth');
    $self->{'stage'} |= $auth if $argv;
    return $self->{'stage'} & $auth ? 1 : 0;
}

sub mail {
    my $self = shift;
    my $argv = shift || 0;
    my $mail = __PACKAGE__->done('mail');
    $self->{'stage'} |= $mail if $argv;
    return $self->{'stage'} & $mail ? 1 : 0;
}

sub rcpt {
    my $self = shift;
    my $argv = shift || 0;
    my $rcpt = __PACKAGE__->done('rcpt');
    $self->{'stage'} |= $rcpt if $argv;
    return $self->{'stage'} & $rcpt ? 1 : 0;
}

sub data {
    my $self = shift;
    my $argv = shift || 0;
    my $data = __PACKAGE__->done('data');
    $self->{'stage'} |= $data if $argv;
    return $self->{'stage'} & $data ? 1 : 0;
}

sub rset {
    my $self = shift;
    $self->{'stage'} = __PACKAGE__->done('ehlo');
    return 1;
}

sub quit {
    my $self = shift;
    $self->{'stage'} = 0;
    return 1;
}

sub damn {
    my $self = shift;
    my $smtp = {};

    for my $e ( @$rwaccessors, @$roaccessors ) {

        next if $e =~ m/(?:response|addresser|recipient|started|stage)/;
        $smtp->{ $e } = $self->{ $e };
    }

    while(1) {
        last unless defined $self->{'addresser'};
        last unless ref $self->{'addresser'};
        last unless ref $self->{'addresser'} eq 'Haineko::SMTPD::Address';

        $smtp->{'addresser'} = $self->{'addresser'}->address;
        last;
    }

    while(1) {
        last unless defined $self->{'recipient'};
        last unless ref $self->{'recipient'} eq 'ARRAY';

        $smtp->{'recipient'} = [];
        for my $e ( @{ $self->{'recipient'} } ) {

            next unless ref $e eq 'Haineko::SMTPD::Address';
            push @{ $smtp->{'recipient'} }, $e->address;
        }
        last;
    }

    while(1) {
        last unless defined $self->{'response'};
        last unless ref $self->{'response'} eq 'ARRAY';

        $smtp->{'response'} = [];
        for my $e ( @{ $self->{'response'} } ) {
            next unless ref $e eq 'Haineko::SMTPD::Response';
            push @{ $smtp->{'response'} }, $e->damn;
        }

        last if scalar @{ $smtp->{'response'} };
        $smtp->{'response'} = [ Haineko::SMTPD::Response->new ];
        last;
    }

    $smtp->{'timestamp'} = {
        'datetime' => $self->started->cdate,
        'unixtime' => $self->started->epoch,
    };
    return $smtp;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Session - HTTP to SMTP Session class

=head1 DESCRIPTION

Haineko::SMTPD::Session manages a connection from HTTP and SMTP session on 
Haineko server.

=head1 SYNOPSIS

    use Haineko::SMTPD::Session;
    my $v = { 
        'useragent' => 'Mozilla',
        'remoteaddr' => '127.0.0.1',
        'remoteport' => 62401,
    };
    my $e = Haineko::SMTPD::Session->new( %$v );
    $e->addresser( 'kijitora@example.jp' );
    $e->recipient( [ 'neko@example.org' ] );

    print $e->queueid;              # r64CvGQ21769QslMmPPuD2jC
    print $e->started;              # Thu Jul  4 18:00:00 2013 (Time::Piece object)
    print $e->addresser->user;      # kijitora (Haineko::SMTPD::Address object)
    print $e->recipient->[0]->host; # example.org (Haineko::SMTPD::Address object)

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::SMTPD::Session

    my $e = Haineko::SMTPD::Session->new( 
            'useragent' => $self->req->headers->user_agent,
            'remoteaddr' => $self->req->headers->header('REMOTE_HOST'),
            'remoteport' => $self->req->headers->header('REMOTE_PORT'),
            'addresser' => 'kijitora@example.jp',
            'recipient' => [ 'neko@example.org', 'cat@example.com' ],
    );

=head2 C<B<load( I<Hash reference> )>>

C<load()> is also a constructor of Haineko::SMTPD::Session. 

    my $v = {
        'queueid' => 'r64CvGQ21769QslMmPPuD2jC',
        'addresser' => 'kijitora@example.jp',
    };
    my $e = Haineko::SMTPD::Session->load( %$v );

    print $e->queueid;              # r64CvGQ21769QslMmPPuD2jC
    print $e->addresser->address;   # kijitora@example.jp

=head2 C<B<make_queueid>>

C<make_queueid()> generate a queue id string.

    print Haineko::SMTPD::Session->make_queueid;   # r64IHFV22109f8KATxdNDSj7
    print Haineko::SMTPD::Session->make_queueid;   # r64IHJP22111Q9PCwpWX1Pd0
    print Haineko::SMTPD::Session->make_queueid;   # r64IHV622112od227ioJMxhh

=head1 INSTANCE METHODS

=head2 C<B<r( I<SMTP command>, I<Error type> [,I<Message>] )>>

C<r()> sets Haineko::SMTPD::Response object from a SMTP Command and an error type.

    my $e = Haineko::SMTPD::Session->new( ... );
    print $e->response->dsn;    # undef

    $e->r( 'RCPT', 'rejected' );
    print $e->response->dsn;    # 5.7.1
    print $e->response->code;   # 553

=head2 C<B<damn>>

C<damn()> returns instance data as a hash reference

    warn Data::Dumper::Dumper $e;
    $VAR1 = {
          'referer' => undef,
          'queueid' => 'r64IQ9X22396oA0bjQZIU7rn',
          'addresser' => 'kijitora@example.jp',
          'response' => {
                'dsn' => undef,
                'error' => undef,
                'message' => undef,
                'command' => undef,
                'code' => undef
          },
          'remoteaddr' => '127.0.0.1',
          'useragent' => 'CLI',
          'timestamp' => {
                'unixtime' => 1372929969,
                'datetime' => "Wed Jul 17 12:00:27 2013"
          },
          'stage' => 4,
          'remoteport' => 1024
        };

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
