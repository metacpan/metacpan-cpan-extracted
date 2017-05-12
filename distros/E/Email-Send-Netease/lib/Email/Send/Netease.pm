package Email::Send::Netease;

use 5.006;
use strict;
use warnings;
use MIME::Lite;
use MIME::Words qw(encode_mimewords);
use Carp qw/croak/;

our $VERSION = '0.02';


sub new {

    my $class = shift;
    my $email = shift;
    my $passwd = shift;
    my $debug = shift;

    if ($email =~ /\@(126|163|188|)\.com$/ or $email =~ /\@yeah\.net$/) {
        # fine
     } else {
        croak "must be Netease's email account at one of 163.com, 126.com, 188.com, yeah.net";
     }

    $debug = 0 unless defined $debug;

    eval {
        require MIME::Base64;
        require Authen::SASL;
    } or croak "Need MIME::Base64 and Authen::SASL for sendmail";

    bless {email=>$email,passwd=>$passwd,debug=>$debug}, $class;
}

sub sendmail {

    my $self = shift;
    my $title = shift;
    my $html_body = shift;
    my @recepients = @_;

    my $to_address = join ',',@recepients;
    my $from_address = $self->{email};
    my ($user,$domain) = split/\@/,$self->{email};
    my $smtpsvr = 'smtp.'.$domain;

    my $subject = encode_mimewords($title,'Charset','UTF-8');

    my $msg = MIME::Lite->new (
        From => $from_address,
        To => $to_address,
        Subject => $subject,
        Type     => 'text/html',
        Data     => $html_body,
        Encoding => 'base64',
    ) or croak "create container failed: $!";

    $msg->attr('content-type.charset' => 'UTF-8');
    $msg->send(  'smtp',
                 $smtpsvr,
                 AuthUser=>$user,
                 AuthPass=>$self->{passwd},
                 Debug=>$self->{debug}
              );
}


1;

=head1 NAME

Email::Send::Netease - Send email with Netease's SMTP servers

=head1 VERSION

Version 0.02


=head1 SYNOPSIS

    use Email::Send::Netease;
    my $smtp = Email::Send::Netease->new('john@126.com','mypasswd');
    $smtp->sendmail($subject,$html_body,'foo@163.com','bar@sina.com');


=head1 METHODS

=head2 new($email, $password, [$debug])

Create the object.

The email and password are what you registered on Netease, whose domains include 126.com, 163.com, 188.com, yeah.net

    my $smtp = Email::Send::Netease->new('foo@126.com','password');
    # or with debug
    my $smtp = Email::Send::Netease->new('foo@126.com','password',1);

=head2 sendmail($subject, $html_body, @recepients)

Send the message. 

The subject and body can be Chinese (if so they must be UTF-8 string).
They will be encoded with UTF-8 for sending.

The message body should be HTML syntax compatible, it will be sent with text/html format.

    my $subject = "Hello";
    my $html_body =<<EOF;
<html>
<body>
<h1>Hello there</h1>
<p>It's nice to see you.</p>
</body>
</html>
EOF

    $smtp->sendmail($subject,$html_body,'foo@163.com');
    # send to more than one people
    $smtp->sendmail($subject,$html_body,'foo@163.com','bar@sina.com', ...);
    

=head1 AUTHOR

Ken Peng <yhpeng@cpan.org>


=head1 BUGS/LIMITATIONS

If you have found bugs, please send email to <yhpeng@cpan.org>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Send::Netease


=head1 COPYRIGHT & LICENSE

Copyright 2012 Ken Peng, all rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

