use strict;
use warnings;
use Log::Sigil qw( swarn swarn2 );
use Test::More tests => 6;
use Test::Output;

my @warnings;
$SIG{__WARN__} = sub {
    chomp( my $swarn = join q{ }, @_ );
    push @warnings, $swarn;
};

package Foo;
use Log::Sigil qw( swarn );

our $foo = sub {
    swarn( "foo" );
    swarn( "bar" );
};

sub new { bless { }, shift }

sub bar {
    swarn( "foo" );
    swarn( "bar" );
}

sub call { shift->{foo}->( @_ ) }

package main;
$Foo::foo->( );

is( $warnings[0], "+++ foo by t/07-package.t[17]: Foo::__ANON__::31" );
is( $warnings[1], "+++ bar by t/07-package.t[18]: Foo::__ANON__::31" );

Foo::bar( );
is( $warnings[2], "!!! foo by t/07-package.t[24]: Foo::bar" );
is( $warnings[3], "!!! bar by t/07-package.t[25]: Foo::bar" );

my $o = Foo->new;
$o->{foo} = sub {
    swarn2( "foo" );
    swarn2( "bar" );
};
$o->call;

# note: the line no. is not anon sub, it is pointed at call sub.
is( $warnings[4], q{@@@ foo by t/07-package.t[42]: main::__ANON__::28} );
is( $warnings[5], q{@@@ bar by t/07-package.t[43]: main::__ANON__::28} );
