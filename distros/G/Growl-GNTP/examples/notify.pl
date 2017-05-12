use strict;
use warnings;
use lib qw/lib/;
use Growl::GNTP;

binmode STDOUT, ':encoding(cp932)' if $^O eq 'MSWin32';

my $growl = Growl::GNTP->new(
    AppName  => "my perl app",
    Password => $ENV{'GROWL_PASSWORD'} || '',
    #Debug => 1,
);

$growl->register([
    { Name => "foo", },
    { Name => "bar", },
]);

$growl->notify(
    Name => "foo",
    Title => "おうっふー おうっふー1",
    Message => "大事な事なので\n2回言いました",
    Icon => "http://mattn.kaoriya.net/images/logo.png",
    CallbackContext => "oops1!",
    CallbackContextType => "foo",
    CallbackFunction => sub {
        my ($result, $type, $context) = @_;
        print "$result: $context ($type)\n";
    },
);
$growl->notify(
    Name => "foo",
    Title => "おうっふー おうっふー2",
    Message => "大事な事なので\n2回言いました",
    Icon => "http://mattn.kaoriya.net/images/logo.png",
    CallbackContext => "oops2!",
    CallbackContextType => "foo",
    CallbackFunction => sub {
        my ($result, $type, $context) = @_;
        print "$result: $context ($type)\n";
    },
);
$growl->notify(
    Name => "foo",
    Title => "おうっふー おうっふー3",
    Message => "大事な事なので\n2回言いました",
    Icon => "http://mattn.kaoriya.net/images/logo.png",
    CallbackContext => "oops3!",
    CallbackContextType => "foo",
    CallbackFunction => sub {
        my ($result, $type, $context) = @_;
        print "$result: $context ($type)\n";
    },
);

$growl->wait(1);

$growl->notify(
    Name => "foo",
    Title => "おうっふー おうっふー4",
    Message => "大事な事なので\n2回言いました",
    Icon => "http://mattn.kaoriya.net/images/logo.png",
    CallbackContext => "oops4!",
    CallbackContextType => "foo",
    CallbackFunction => sub {
        my ($result, $type, $context) = @_;
        print "$result: $context ($type)\n";
    },
);

$growl->wait(1);
