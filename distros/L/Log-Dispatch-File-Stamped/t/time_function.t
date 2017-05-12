use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use File::Basename 'fileparse';
use POSIX 'strftime';
use Log::Dispatch::File::Stamped;

my @localtime = (localtime);
my @gmtime = (gmtime);

note 'localtime: ', join(' ', @localtime);
note 'gmtime:    ', join(' ', @gmtime);

my %args = (
    min_level => 'debug',
    close_after_write => 1, # prevents file creation until first use
    filename => 'foo.log',
    stamp_fmt => '%Y%m%d%H',
);

{
    my $logger = Log::Dispatch::File::Stamped->new(%args);
    my ($basename, $path) = fileparse($logger->{filename});
    is(
        $basename,
        strftime('foo-' . $args{stamp_fmt} . '.log', @localtime),
        'localtime is used by default',
    );
}

{
    my $logger = Log::Dispatch::File::Stamped->new(%args, time_function => 'localtime');
    my ($basename, $path) = fileparse($logger->{filename});
    is(
        $basename,
        strftime('foo-' . $args{stamp_fmt} . '.log', @localtime),
        'localtime is used by request',
    );
}

{
    my $logger = Log::Dispatch::File::Stamped->new(%args, time_function => 'gmtime');
    my ($basename, $path) = fileparse($logger->{filename});
    is(
        $basename,
        strftime('foo-' . $args{stamp_fmt} . '.log', @gmtime),
        'gmtime is used by request',
    );
}

{
    like(
        exception { Log::Dispatch::File::Stamped->new(%args, time_function => 'ethertime') },
        qr/time_function.*ethertime/,
        'no support for anything but localtime, gmtime',
    );
}

done_testing;
