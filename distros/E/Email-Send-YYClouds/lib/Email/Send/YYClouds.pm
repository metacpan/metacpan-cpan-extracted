package Email::Send::YYClouds;

use 5.006;
use strict;
use warnings;
use utf8;
use MIME::Lite;
use MIME::Words qw(encode_mimewords);

=encoding utf8

=head1 NAME

Email::Send::YYClouds - Send email using YYClouds' smtp server

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Email::Send::YYClouds;

    my $msg = Email::Send::YYClouds->new();
    $msg->send(recepient => ['user@yy.com','user@163.com'],
               subject => '测试邮件',
               body => '<p>这是一封测试邮件</p><p>Just a test message for you</p>',
               is_html => 1,
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
               subject => $subject,
               body => $body,
               is_html => $boolean,
          );

Default sender should always be noreply@yyclouds.com, you can't change it.

recepient - a list of email addresses for receiving message.

subject - email subject, which can be either Chinese or non-Chinese.

body - message body, which can be either Chinese or non-Chinese.

is_html - default 0, it must be set to 1 if this is a html message.

Please notice: Only when MTA relay has authorized the sender host from where you can send messages.

Otherwise you will get error:

    SMTP recipient() command failed: 
    5.7.1 <xxx@yy.com>: Relay access denied

Contact the sysops to authorize it.

=cut

sub send {

    my $self = shift;
    my %args = @_;

    my $recepient = $args{'recepient'};
    my $subject = $args{'subject'};
    my $body = $args{'body'};
    my $is_html = $args{'is_html'};
    $is_html = 0 unless defined $is_html;

    my $type = $is_html ? "text/html" : "text/plain";
    my $to_address = join ',',@$recepient;
    my $encoded_subject = encode_mimewords($subject,'Charset','UTF-8');

    my $msg = MIME::Lite->new (
        From => 'noreply@yyclouds.com',
        To =>  $to_address,
        Subject => $encoded_subject,
        Type     => $type,
        Data     => $body,
        Encoding => 'base64',
    ) or die "create container failed: $!";

    $msg->attr('content-type.charset' => 'UTF-8');
    $msg->send(  'smtp',
                 'smtp.game.yy.com',
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
