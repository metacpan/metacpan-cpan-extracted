use strict;
use warnings;
use Test::More;
use t::lib::Test::Emailesque;

sub can_email {
    my $t = Test::Emailesque->new;
    ok $t->test_function($_[0]),     'Emailesque::email(...) ok';
    ok $t->test_method($_[0]),       'Emailesque->new->send(...) ok';
    ok $t->test_construction($_[0]), 'Emailesque->new(...)->send() ok';
}

can_email {
    to      => 'recipient@nowhere.example.net',
    from    => 'sender@emailesque.example.com',
    subject => 'This is strange',
    message => 'You will never receive this',
};

done_testing;
