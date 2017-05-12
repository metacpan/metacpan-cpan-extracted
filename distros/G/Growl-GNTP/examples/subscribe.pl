use strict;
use warnings;
use lib qw/lib/;
use Growl::GNTP;
use Encode;

binmode STDOUT, ':encoding(cp932)' if $^O eq 'MSWin32';

my $growl = Growl::GNTP->new(
    AppName => "my perl app",
    Password => $ENV{'GROWL_PASSWORD'} || '',
    #Debug => 1,
);

$growl->subscribe(
    Port => 23054,
    CallbackFunction => sub {
        my ($Title, $Message) = @_;
        print decode_utf8($Title),",",decode_utf8($Message),"\n";
    },
);
