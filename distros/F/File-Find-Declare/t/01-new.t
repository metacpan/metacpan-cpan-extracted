use strict;
use warnings;
use File::Find::Declare;
use Test::More tests => 45;
use Test::Exception;

my $sp;
my $fff;

$sp = {};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    like => 'foo*',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    like => qr/foo.*/,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    like => ['foo*'],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    like => ['foo*', qr/foo.*/],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    like => ['foo*', [qr/foo.*/]],
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';

$sp = {
    unlike => 'foo*',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    unlike => qr/foo.*/,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    unlike => ['foo*', qr/foo.*/],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    ext => '.foo',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    ext => ['.foo', '.bar'],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    ext => qr/\.foo/,
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';

$sp = {
    subs => sub { $_[0] =~ m/foo.bar/ },
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    subs => [ sub { $_[0] =~ m/foo/ }, sub { $_[0] =~ m/bar/ } ],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    subs => qr/foo/,
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';

$sp = {
    dirs => 'foo',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    dirs => ['foo', 'bar'],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    dirs => \@INC,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    dirs => [[['foo']]],
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';

$sp = {
    size => 1024,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    size => "1024",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    size => ">1024",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    size => ">=1024",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    size => "<1024",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    size => "<=1024",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    size => "1024K",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    size => "foo",
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';

$sp = {
    changed => ">2001-10-12",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    modified => ">2001-10-12",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    accessed => ">2001-10-12",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    recurse => 0,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    recurse => 1,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    is => 'readable',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    is => ['readable', 'r_readable'],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    is => 'foo',
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';

$sp = {
    isnt => 'readable',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    isnt => ['readable', 'r_readable'],
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    isnt => 'foo',
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';

$sp = {
    owner => 'foo',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    owner => 1,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    group => 'foo',
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    group => 1,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    perms => 755,
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    perms => "rwxrw-r--",
};
lives_ok { $fff = File::Find::Declare->new($sp) } 'Should not die';

$sp = {
    perms => "foo",
};
dies_ok { $fff = File::Find::Declare->new($sp) } 'Dies with invalid spec';
