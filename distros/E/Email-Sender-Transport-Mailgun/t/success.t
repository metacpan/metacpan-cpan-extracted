use strict;
use Test::More;
use Test::Fatal;
use Test::Differences;

use DateTime;
use Email::Sender::Transport::Mailgun;

{
    no warnings 'redefine';
    *HTTP::Tiny::request = \&mock_request;
}

my @requests;

my $proto   = 'http';
my $host    = 'mailgun.example.com';
my $api_key = 'abcdef';
my $domain  = 'test.example.com';
my $id      = '<return value>';

my %envelope = (
    from => 'sender@test.example.com',
    to   => 'recipient@test.example.com',
);

my $message = <<END_MESSAGE;
From: $envelope{from}
To: $envelope{to}
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

--
sender
END_MESSAGE

my $when = DateTime->new(
    year => 2066,
    month => 12,
    day => 31,
    hour => 23,
    minute => 59,
    second => 59,
    time_zone => 'UTC',
);

my $campaign = [qw( campaign1 campaign2 )];
my $tag      = [qw( tag1 tag2 tag3 )];

my $transport = Email::Sender::Transport::Mailgun->new(
    api_key  => $api_key,
    domain   => $domain,
    base_uri => "$proto://$host",
    campaign => $campaign,
    tag      => join(', ', @$tag),
    tracking_clicks => 'htmlonly',
    deliverytime => $when,
);

my $result;
is(exception { $result = $transport->send($message, \%envelope) },
    undef, 'Mail sent ok');

is(@requests, 1, 'HTTP request performed');
isa_ok($result, 'Email::Sender::Success::MailgunSuccess', 'Return value');
is($result->id, $id, 'Return id correct');

my $req = shift @requests;
is($req->{method}, 'POST', 'POST method');
is($req->{uri}, "$proto://api:$api_key\@$host/$domain/messages.mime", 'URI ok');
like($req->{data}->{headers}->{'content-type'}, qr{^multipart/form-data},
        'Used multipart/form-data');

sub body {
    return (@_ > 1) ?  [ map { body($_) } @_ ] : { body => $_[0] };
}

eq_or_diff($req->{form}, {
    message => {
        body => $message,
        filename => 'message.mime',
    },
    to                  => body($envelope{to}),
    'o:tag'             => body(@$tag),
    'o:campaign'        => body(@$campaign),
    'o:deliverytime'    => body('Fri, 31 Dec 2066 23:59:59 +0000'),
    'o:tracking-clicks' => body('htmlonly'),
}, 'Message format as expected');

done_testing;

sub mock_request {
    my ($self, $method, $uri, $data) = @_;

    push(@requests, {
        method => $method,
        uri    => $uri,
        data   => $data,
        form   => parse_form($data->{content}),
    });

    return { success => 1, content => qq({"id":"$id"}) };
}

sub parse_form {
    my ($form) = @_;

    my ($boundary, $data) = split(/\r\n/, $form, 2);

    my %form;
    for my $chunk (split("\r\n$boundary", $data)) {
        next if ($chunk eq "--\r\n");
        my ($header, $body) = split(/\r\n\r\n/, $chunk, 2);

        my $section = { body => $body };

        while ($header =~ /\s(\S+)="(.*?)"/g) {
            $section->{$1} = $2;
        }

        my $key = delete $section->{name};
        if (exists $form{$key}) {
            if (ref $form{$key} ne 'ARRAY') {
                $form{$key} = [ $form{$key} ];
            }
            push(@{ $form{$key} }, $section);
        }
        else {
            $form{$key} = $section;
        }
    }

    return \%form;
}
