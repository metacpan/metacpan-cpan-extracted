package Email::Send::YYClouds;

use 5.006;
use strict;
use warnings;
use utf8;
use MIME::Lite;
use Encode qw(encode encode_utf8);


=encoding utf8

=head1 NAME

Email::Send::YYClouds - Send email using any smtp relay server

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

    use Email::Send::YYClouds;
    use utf8;

    my $msg = Email::Send::YYClouds->new();
    $msg->send(recepient => ['user@yy.com','user@163.com'],
               sender => 'foo@bar.com',
               smtprelay => 'localhost',
               subject => '测试邮件',
               body => '<p>这是一封测试邮件。</p><p>欢迎来到perl的世界！</p>',
          );


=head1 SUBROUTINES/METHODS

=head2 new
    
    $msg = Email::Send::YYClouds->new();
    $msg = Email::Send::YYClouds->new(debug=>1);  # with debug open

=cut

sub new {

    my $class = shift;
    my %args = @_;
    my $debug = $args{'debug'};

    $debug = 0 unless defined $debug;
    bless { debug=>$debug },$class;
}

=head2 send

    $msg->send(recepient => [a list of recepients],
               sender => 'foo@bar.com',
               smtprelay => 'relay_server',
               subject => $subject,
               body => $body,
          );


recepient - a list of email addresses for receiving message.

sender - from what address the message was sent.

smtprelay - relay server for smtp session, default to localhost.

subject - email subject, which can be either Chinese or non-Chinese.

body - message body, which can be either Chinese or non-Chinese. default with HTML type.

Please notice: you must have smtp realy server to approve the sending action.

Otherwise you will get error:

    SMTP recipient() command failed: 
    5.7.1 <xxx@yy.com>: Relay access denied

Contact the sysops to authorize it.

=cut

sub send {

    my $self = shift;
    my %args = @_;

    my $recepient = $args{'recepient'};
    my $sender = $args{'sender'};
    my $subject = $args{'subject'};
    my $body = $args{'body'};

    my $smtprelay = $args{'smtprelay'} || 'localhost';
    my $to_address = join ',',@$recepient;


    my $msg = MIME::Lite->new (
        From => $sender,
        To =>  $to_address,
        Subject => encode( 'MIME-Header', $subject ),
        Data    => encode_utf8($body),
        Encoding => 'base64',
    ) or die "create container failed: $!";

    $msg->attr( 'content-type' => 'text/html; charset=utf-8' );

    $msg->send(  'smtp',
                 $smtprelay,
                 Debug => $self->{debug}
              );
}


=head1 AUTHOR

Ken Peng, C<< <yhpeng at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-send-yyclouds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Send-YYClouds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Send::YYClouds


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Send-YYClouds>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Send-YYClouds>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Send-YYClouds>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Send-YYClouds/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ken Peng.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Email::Send::YYClouds
