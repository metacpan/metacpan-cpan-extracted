use strict;
use warnings;
use HTTP::Session;
use HTTP::Session::State::Test;
use HTTP::Session::Store::DBM;
use CGI;
use Test::More tests => 1;
use File::Temp;

my $tmp = File::Temp->new(UNLINK => 1);
my $new_session_id;

{
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::Test->new(
            session_id => 'foo',
        ),
        store => HTTP::Session::Store::DBM->new(file => "$tmp"),
        request => CGI->new(),
    );
    $session->set('foo' => 'bar');
    $session->regenerate_session_id();
    $new_session_id = $session->session_id;
}
{
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::Test->new(
            session_id => $new_session_id
        ),
        store => HTTP::Session::Store::DBM->new(file => "$tmp"),
        request => CGI->new(),
    );
    is $session->get('foo'), 'bar';
}
unlink "${tmp}.$_" for qw/pag dir/;
