use strict;
use warnings;
use Mail::Sender;
use Test::More;

can_ok('Mail::Sender',
    qw(new _initialize _prepare_addresses _prepare_ESMTP _prepare_headers),
    qw(ClearErrors)
);

# use actual defaults
my $sender = Mail::Sender->new({tls_allowed => 0});
isa_ok($sender, 'Mail::Sender', 'new: Got a proper object instance');

SKIP: {
    skip "No SMTP server set in the default config", 3 unless $sender && $sender->{smtp};

    ok( $sender->{smtpaddr}, "smtpaddr defined");

    my $res = $sender->Connect();
    ok( (ref($res) or $res >=0), "->Connect()")
        or do { diag("Error: $Mail::Sender::Error"); exit};

    ok( ($sender->{'supports'} and ref($sender->{'supports'}) eq 'HASH'), "found out what extensions the server supports");
};

{
    # make a copy
    my $copy = $sender->new({});
    isa_ok($copy, 'Mail::Sender', 'new: got a copy');
    $copy->{to} = 'capoeirab@cpan.org';
    isnt($copy->{to}, $sender->{to}, 'copy and original now differ');
    # make a copy with altered 'to'
    my $copy2 = $copy->new({to=>'capoeirab2@cpan.org'});
    isa_ok($copy2, 'Mail::Sender', 'new: got a copy of the copy');
    is($copy->{to}, 'capoeirab@cpan.org', 'copy to: right value');
    is($copy2->{to}, 'capoeirab2@cpan.org', 'copy2 to: right value');

    # prepare addresses
    my $addresses = ['capoeirab@cpan.org', 'foo@bar.com'];
    $copy->{foo_cc} = $addresses;
    $copy->_prepare_addresses('foo_cc');
    is($copy->{foo_cc}, join(', ',@{$addresses}), '_prepare_addresses: proper result');

    # prepare ESMTP
    my $esmtp = {
        NOTIFY => 'SUCCESS,FAILURE,DELAY',
        RET => 'HDRS',
        ORCPT => 'my.other@address.com',
        ENVID => 'iuhsdfobwoe8t237',
    };
    $copy->{esmtp} = $esmtp;
    $copy->_prepare_ESMTP();
    is($copy->{esmtp}{ORCPT}, 'rfc822;my.other@address.com', '_prepare_ESMTP: proper ORCPT');
    $copy->{esmtp}{ORCPT} = '';
    $copy->_prepare_ESMTP();
    is($copy->{esmtp}{ORCPT}, '', '_prepare_ESMTP: proper ORCPT emptiness');
    $copy->{esmtp}{ORCPT} = ';';
    $copy->_prepare_ESMTP();
    is($copy->{esmtp}{ORCPT}, ';', '_prepare_ESMTP: proper ORCPT semicolon');

    # prepare headers
    $copy->_prepare_headers();
    is($copy->{headers}, undef, '_prepare_headers: properly undef');
    $copy->{headers} = '';
    $copy->_prepare_headers();
    is($copy->{headers}, undef, '_prepare_headers: empty string to undef');
    is($copy->{_headers}, undef, '_prepare_headers: _headers undef');

    my $headers = {'Authorization'=>'Basic foo'};
    $copy->{headers} = $headers;
    $copy->_prepare_headers();
    is_deeply($copy->{headers}, $headers, '_prepare_headers: equal headers');
    is($copy->{_headers}, 'Authorization: Basic foo', '_prepare_headers: _headers string correct');

    $headers = {
        'Authorization'=> join(' ',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo - header too long to be set properly. Maybe you should reconsider',
            'Basic foo ; header too long to be set properly. Maybe you should reconsider',
        ),
    };
    $copy->{headers} = $headers;
    $copy->_prepare_headers();
    is_deeply($copy->{headers}, $headers, '_prepare_headers: too long headers: equal headers');
    like($copy->{_headers}, qr/header too long/, '_prepare_headers: too long headers _headers string correct');

    $copy->{headers} = '';
    $copy->_prepare_headers();
    is($copy->{headers}, undef, '_prepare_headers: properly reset to undef');

    $headers = ['Authorization', 'Basic'];
    $copy->{headers} = $headers;
    $copy->_prepare_headers();
    is_deeply($copy->{headers}, $headers, '_prepare_headers: array ref');
    is($copy->{_headers}, undef, '_prepare_headers: array ref not valid _headers');

    $headers = 'Authorization: Basic';
    $copy->{headers} = $headers;
    $copy->_prepare_headers();
    is($copy->{headers}, $headers, '_prepare_headers: string');
    is($copy->{_headers}, $headers, '_prepare_headers: string');
}

{
    # clear all defaults
    %Mail::Sender::default = ();

    my $s = Mail::Sender->new({tls_allowed => 0});
    isa_ok($s, 'Mail::Sender', 'new: no defaults, proper instance');
    is($s->{tls_allowed}, 0, 'tls_allowed: set correctly');

    $s = Mail::Sender->new({tls_allowed => 1});
    isa_ok($s, 'Mail::Sender', 'new: no defaults, proper instance');
    is($s->{tls_allowed}, 1, 'tls_allowed: set correctly');

    $s = Mail::Sender->new();
    isa_ok($s, 'Mail::Sender', 'new: no defaults, proper instance');
    is($s->{port}, 25, 'port: set correctly');

    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: empty hashref, proper instance');
    is($s->{port}, 25, 'port: set correctly');

    $s = Mail::Sender->new([]);
    isa_ok($s, 'Mail::Sender', 'new: empty arrayref, proper instance');
    is($s->{port}, 25, 'port: set correctly');
}

{
    # set specific defaults
    my $s;

    %Mail::Sender::default = (port=>23);
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: port default');
    is($s->{port}, 23, 'port: set correctly');

    $Mail::Sender::default{replyto} = 'capoeirab@cpan.org';
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: replyto default');
    is($s->{replyto}, 'capoeirab@cpan.org', 'replyto: set correctly');
    is($s->{reply}, 'capoeirab@cpan.org', 'reply: set correctly');

    $Mail::Sender::default{reply} = 'capoeirab@cpan.org';
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: reply default');
    is($s->{replyto}, 'capoeirab@cpan.org', 'replyto: set correctly');
    is($s->{reply}, 'capoeirab@cpan.org', 'reply: set correctly');

    $s = Mail::Sender->new({port=>undef});
    isa_ok($s, 'Mail::Sender', 'new: port passed undef');
    is($s->{port}, undef, 'port: properly undef');

    $Mail::Sender::default{replyaddr} = 'capoeirab@cpan.org';
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: replyaddr default');
    is($s->{replyaddr}, 'capoeirab@cpan.org', 'replyaddr: set correctly');

    %Mail::Sender::default = ();

    $Mail::Sender::default{to} = 'capoeirab@cpan.org';
    $Mail::Sender::default{cc} = 'capoeirab@cpan.org';
    $Mail::Sender::default{bcc} = 'capoeirab@cpan.org';
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: to,cc,bcc default');
    is($s->{to}, 'capoeirab@cpan.org', 'to: set correctly');
    is($s->{cc}, 'capoeirab@cpan.org', 'cc: set correctly');
    is($s->{bcc}, 'capoeirab@cpan.org', 'bcc: set correctly');

    $Mail::Sender::default{headers} = '';
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: headers default');
    is($s->{headers}, undef, 'headers: set correctly');

    $Mail::Sender::default{smtp} = '  foo.ba,r.com  ';
    $s = Mail::Sender->new({});
    is($s, -1, 'new: invalid smtp resulting in error code');

    $Mail::Sender::default{smtp} = 'localhost';
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: smtp localhost default');
    is($s->{smtp}, 'localhost', 'smtp: set correctly');
    ok($s->{smtpaddr}, 'smtpaddr: set correctly');

    my $esmtp = {
        NOTIFY => 'SUCCESS,FAILURE,DELAY',
        RET => 'HDRS',
        ORCPT => 'my.other@address.com',
        ENVID => 'iuhsdfobwoe8t237',
    };
    $Mail::Sender::default{esmtp} = $esmtp;
    $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: esmtp default');
    is($s->{esmtp}{ORCPT}, 'rfc822;my.other@address.com', 'esmtp: proper ORCPT');

}

{
    # clear errors
    %Mail::Sender::default = ();
    my $s = Mail::Sender->new({});
    isa_ok($s, 'Mail::Sender', 'new: about to ClearErrors');
    $Mail::Sender::Error = 'foo';
    $s->{'error'} = 'stuff';
    $s->{'error_msg'} = 'things';
    $s->ClearErrors();
    is($s->{error}, undef, 'ClearErrors: error attribute undef');
    is($s->{error_msg}, undef, 'ClearErrors: error_msg attribute undef');
    is($Mail::Sender::Error, undef, 'ClearErrors: Error global undef');
}

done_testing();
