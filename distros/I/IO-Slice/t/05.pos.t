use strict;
use Test::More;
use Test::Exception;
use IO::Slice;
use Fcntl qw< :seek >;
use File::Basename qw< dirname >;
my $dirname = dirname(__FILE__);
my @specs = map { $_->{filename} = "$dirname/$_->{filename}"; $_ }
   @{ do "$dirname/testfile.specs" };

my $spec = $specs[0];
my $sfh = IO::Slice->new($spec);

my $expected = substr $spec->{contents}, 0, 10;
my ($nread, $got);
lives_ok {
   $nread = read $sfh, $got, 10;
} 'read does not blow';

ok defined($nread), 'read bytes led to defined return value';
$nread = '' unless defined $nread;
is $nread, 10, 'number or read characters';
is $got, $expected, 'what has been read';

my $position = tell $sfh;
is $position, 10, 'tell() works';

my $object = tied *$sfh;
my $position_check = $object->pos();
is $position_check, 10, 'pos() works';

seek $sfh, 15, SEEK_SET;
is tell($sfh), 15, 'seek() works';

$expected = substr $spec->{contents}, 15, 5;
$got = '';
$nread = read $sfh, $got, 5;
is $got, $expected, 'read() after seek';
is $object->pos(), 20, 'pos() after read()';
is tell($sfh), 20, 'tell() after read()';

done_testing();
