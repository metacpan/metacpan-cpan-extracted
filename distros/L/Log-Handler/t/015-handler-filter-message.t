use strict;
use warnings;
#use Test::More tests => 8;
use Test::More tests => 7;
use Log::Handler;

# Comment out "string 2" becaus ValidatePP.pm is unable to handle
# regexes on some perl versions! That is strange, but not a problem
# of Log::Handler.

my %STRING = (
    'string 1' => 0,
#    'string 2' => 0,
    'string 3' => 0,
    'string 4' => 0,
    'string 5' => 0,
);

ok(1, 'use');

my $log = Log::Handler->new();

ok(2, 'new');

$log->add(
    forward => {
        forward_to => \&check,
        maxlevel   => 6,
        filter_message => 'string 1$',
    }
);

#$log->add(
#    forward => {
#        forward_to => \&check,
#        maxlevel   => 6,
#        filter_message => qr/STRING\s2$/i,
#    }
#);

$log->add(
    forward => {
        forward_to => \&check,
        maxlevel   => 6,
        filter_message => sub { shift->{message} =~ /string\s3$/ },
    }
);

$log->add(
    forward => {
        forward_to => \&check,
        maxlevel   => 6,
        filter_message => {
            match1    => 'foo',
            match2    => qr/bar/,
            match3    => '(?:string\s4|string\s5)',
            condition => '(!match1 && !match2) && match3',
        }
    }
);

ok(3, 'add');

sub check {
    my $m = shift;
    if ($m->{message} =~ /(string\s\d+)/) {
        if (exists $STRING{$1}) {
            $STRING{$1}++;
        } else {
            die "unexpected message $m->{message}";
        }
    }
}

$log->info('string 1');
#$log->info('string 2');
$log->info('string 3');
$log->info('string 4');
$log->info('string 5');

$log->info('string 1 foo');
#$log->info('string 2 foo');
$log->info('string 3 foo');
$log->info('string 4 foo');
$log->info('string 5 bar');

while ( my ($k, $v) = each %STRING ) {
    ok($v == 1, "checking if $k match (hits:$v)");
}
