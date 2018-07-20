use strict;

use Test::More;
use HTTP::Exception;

# double checking synonym for status_message and message

my $e = HTTP::Exception->new(404, status_message => 'Nothing here');
is  $e->status_message, 'Nothing here', 'status message with H::E + new ';
is  $e->message,        'Nothing here', 'message with H::E + new ';

my $e1 = HTTP::Exception->new(404, message => 'Nothing here');
is  $e1->status_message, 'Nothing here', 'status message with H::E + new ';
is  $e1->message,        'Nothing here', 'message with H::E + new ';

my $e2 = HTTP::Exception::404->new(status_message => 'Nothing here');
is  $e2->status_message, 'Nothing here', 'status message with H::E::404 + new';
is  $e2->message,        'Nothing here', 'message with H::E::404 + new';

my $e21 = HTTP::Exception::404->new(message => 'Nothing here');
is  $e21->status_message, 'Nothing here', 'status message with H::E::404 + new';
is  $e21->message,        'Nothing here', 'message with H::E::404 + new';

my $e3 = HTTP::Exception::NOT_FOUND->new(status_message => 'Nothing here');
is  $e3->status_message, 'Nothing here', 'status message with H::E::NOT_FOUND + new';
is  $e3->message,        'Nothing here', 'message with H::E::NOT_FOUND + new';

my $e31 = HTTP::Exception::NOT_FOUND->new(message => 'Nothing here');
is  $e31->status_message, 'Nothing here', 'status message with H::E::NOT_FOUND + new';
is  $e31->message,        'Nothing here', 'message with H::E::NOT_FOUND + new';

my $e4 = HTTP::Exception::404->new();
$e4->status_message('Nothing here too');
is $e4->status_message, 'Nothing here too', 'status_message set after ->new';
is $e4->message,        'Nothing here too', 'message set after ->new';
$e4->message('Nothing here');
is $e4->status_message, 'Nothing here', 'status_message set after ->new';
is $e4->message,        'Nothing here', 'message set after ->new';

my @tests = (
    sub { $e4->throw;                                                          },
    sub { HTTP::Exception->throw(404, status_message => 'Nothing here');       },
    sub { HTTP::Exception::404->throw(status_message => 'Nothing here');       },
    sub { HTTP::Exception::NOT_FOUND->throw(status_message => 'Nothing here'); },
    sub { HTTP::Exception->throw(404, message => 'Nothing here');       },
    sub { HTTP::Exception::404->throw(message => 'Nothing here');       },
    sub { HTTP::Exception::NOT_FOUND->throw(message => 'Nothing here'); },
);

for my $test (@tests) {
    eval { $test->() };
    my $e5 = HTTP::Exception->caught;
    my $e6 = HTTP::Exception::4XX->caught;
    my $e7 = HTTP::Exception::404->caught;
    my $e8 = HTTP::Exception::NOT_FOUND->caught;
    my $e9 = Exception::Class->caught;

    for my $accessor (qw~status_message message~) {
        is  $e5->$accessor, 'Nothing here', "$accessor with H::E";
        is  $e6->$accessor, 'Nothing here', "$accessor with H::E::4XX";
        is  $e7->$accessor, 'Nothing here', "$accessor with H::E::404";
        is  $e8->$accessor, 'Nothing here', "$accessor with H::E::NOT_FOUND";
        is  $e9->$accessor, 'Nothing here', "$accessor with Exception::Class";
    }
}

done_testing;