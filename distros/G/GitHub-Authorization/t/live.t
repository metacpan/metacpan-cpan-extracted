use strict;
use warnings;

use Test::More;
use GitHub::Authorization ':all';

{
    # ensure we have what we need for live tests
    my @errors;
    do { push @errors, "$_ not set" unless $ENV{$_} }
        for qw{ GH_PASSWORD GH_USERID };

    plan skip_all => "Required environment not set: @errors"
        if @errors;
}

my ($user, $pass) = @ENV{qw{ GH_USERID GH_PASSWORD }};

my $note   = 'test! ' . localtime;
my $scopes = [ 'public_repo' ];

my $ret = GitHub::Authorization::get_gh_token(
    user     => $user,
    password => $pass,
    scopes   => [ 'public_repo' ],
    note     => $note,
);

# if we'd died, well, then that'd be pretty obvious.

is ref $ret, 'HASH', '$ret is a hashref';
is $ret->{note}, $note, 'note is correct';
is_deeply $ret->{scopes}, $scopes, 'scopes are correct';


done_testing;
