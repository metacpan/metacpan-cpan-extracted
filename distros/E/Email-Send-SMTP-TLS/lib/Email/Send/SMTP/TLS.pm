package Email::Send::SMTP::TLS;

use warnings;
use strict;
use vars qw[$VERSION];
use Email::Address;
use Net::SMTP::TLS::ButMaintained;
use Return::Value;

$VERSION   = '0.04';

sub is_available {
    return 1;
}

sub get_env_sender {
    my ( $class, $message ) = @_;

    my $from
        = ( Email::Address->parse( $message->header('From') ) )[0]->address;
}

sub get_env_recipients {
    my ( $class, $message ) = @_;

    my %to = map { $_->address => 1 }
        map { Email::Address->parse( $message->header($_) ) } qw(To Cc Bcc);

    return keys %to;
}

sub send {
    my ($class, $message, @args) = @_;

    my %args;
    if ( @args % 2 ) {
        my $host = shift @args;
        %args = @args;
        $args{Host} = $host;
    } else {
        %args = @args;
    }

    my $host = delete($args{Host}) || 'localhost';
    my $SMTP = Net::SMTP::TLS::ButMaintained->new($host, %args);
    
    eval {
        my $from = $class->get_env_sender($message);
        $SMTP->mail($from);
        
        my @to = $class->get_env_recipients($message);
        $SMTP->to( @to );
        
    };
    return failure $@ if $@;
    
    $SMTP->data();
    $SMTP->datasend( $message->as_string );
    $SMTP->dataend;
    $SMTP->quit;

     return success 1;
}

1;
__END__

=head1 NAME

Email::Send::SMTP::TLS - Send Email using Net::SMTP::TLS (esp. Gmail)

=head1 SYNOPSIS

    use Email::Send;
    
    my $mailer = Email::Send->new( {
        mailer => 'SMTP::TLS',
        mailer_args => [
            Host => 'smtp.gmail.com',
            Port => 587,
            User => 'username@gmail.com',
            Password => 'password',
            Hello => 'fayland.org',
        ]
    } );
    
    use Email::Simple::Creator; # or other Email::
    my $email = Email::Simple->create(
        header => [
            From    => 'username@gmail.com',
            To      => 'to@mail.com',
            Subject => 'Subject title',
        ],
        body => 'Content.',
    );
    
    eval { $mailer->send($email) };
    die "Error sending email: $@" if $@;

=head1 DESCRIPTION

We can use this module to send email through smtp.gmail.com. L<Email::Send::Gmail> use SSL, while this module use TLS.

Of course, others who support TLS also can use it.

=head1 SEE ALSO

L<Email::Send>, L<Net::SMTP::TLS>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut