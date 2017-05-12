#!/usr/bin/perl -w
use strict;

# DO NOT COPY THESE TWO LINES UNLESS YOU UNDERSTAND WHAT THEY DO.
# ... AND EVEN THEN DON'T COPY THEM!
# use strict;
{
    no warnings;
    *strict::import = sub { $^H };
}

use Test::More tests => 5;

my $nomock;
my $mock;

BEGIN {
    eval "use Test::MockObject";
    $nomock = $@;

    unless ($nomock) {
        $mock = Test::MockObject->new();
        $mock->fake_module('Win32::OLE');
        $mock->fake_new('Win32::OLE');
    }
}

use lib qw(./t/fake);
use_ok('Test::MockObject');

use_ok("Mail::Outlook");

use Win32::OLE::Const 'Microsoft::Outlook';

$mock->mock( 'GetNameSpace',    sub { return undef } );
$mock->mock( 'GetActiveObject', sub { die "Forced Failure" } );
my $outlook = Mail::Outlook->new();
is( $outlook, undef, "Mail::Outlook object not created" );

$mock->mock( 'GetActiveObject', sub { return undef } );
$outlook = Mail::Outlook->new();
is( $outlook, undef, "Mail::Outlook object not created this time either." );

$outlook = Mail::Outlook->new();
is( $outlook, undef, "Mail::Outlook object still not created." );
