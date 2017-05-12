use strict;
use warnings;

use Test::More tests => 3;

use Email::MIME::Kit::Bulk::Command;

use lib 't/lib';
use MyTestEmail;

$Email::MIME::Kit::Bulk::VERSION ||= "0.0";

my %args = ( 
    kit  => 'examples/eg.mkit',
    from => 'me@here.com',
    quiet => 1,
    targets => [],
);

my $bulk = Email::MIME::Kit::Bulk->new(
    %args,
);

subtest "specify everything" => sub {
    my $target = Email::MIME::Kit::Bulk::Target->new(
        from => 'me@foo.com',
        to => 'one@foo.com',
        cc => [ 'two@foo.com', 'three@foo.com' ],
        bcc => [ 'three@foo.com', 'four@foo.com' ],
        language => 'en',
        template_params => {
            superlative => 'Wicked',
        },
    );

    my $email = $bulk->assemble_mime_kit( $target );

    test_email $email => {
        from => 'me@foo.com',
        to => 'one@foo.com',
        cc => 'two@foo.com, three@foo.com',
    };
};

subtest "no from" => sub {
    my $target = Email::MIME::Kit::Bulk::Target->new(
        to => 'one@foo.com',
        cc => [ 'two@foo.com', 'three@foo.com' ],
        bcc => [ 'three@foo.com', 'four@foo.com' ],
        language => 'en',
        template_params => {
            superlative => 'Wicked',
        },
    );

    my $email = $bulk->assemble_mime_kit( $target );

    test_email $email => {
        from => 'me@here.com',
        to => 'one@foo.com',
        cc => 'two@foo.com, three@foo.com',
    };

};

subtest "no cc or bcc" => sub {
    my $target = Email::MIME::Kit::Bulk::Target->new(
        to => 'one@foo.com',
        language => 'en',
        template_params => {
            superlative => 'Wicked',
        },
    );

    my $email = $bulk->assemble_mime_kit( $target );

    test_email $email => {
        from => 'me@here.com',
        to => 'one@foo.com',
        cc => sub { @_ == 0 },
    };

};

