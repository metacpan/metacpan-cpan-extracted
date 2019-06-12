use strict;
use warnings;

use Capture::Tiny 'capture_stderr';
use Path::Tiny qw( path );
use Module::Runtime qw( require_module );
use Test::FailWarnings -allow_deps => 1;
use Test::Fatal qw( exception );
use Test::More;
use LWP::UserAgent;
use WWW::Mechanize;

use LWP::ConsoleLogger::Everywhere;

my $url = 'file://' . path('t/test-data/foo.html')->absolute;

my $lwp  = LWP::UserAgent->new( cookie_jar => {} );
my $mech = WWW::Mechanize->new( autocheck  => 0 );

my ( $mojo, $mojo_based );
if ( require_module('Mojo::UserAgent') ) {
    $mojo = Mojo::UserAgent->new;

    {
        # we need this to test with agents that are subclassing Mojo::UA
        package Foo::Mojobased;
        main::require_module('Mojo::Base');
        Mojo::Base->import('Mojo::UserAgent');

        sub new {
            my $class = shift;
            my $self  = $class->SUPER::new(@_);
            return $self;
        }
    }
    package main;

    $mojo_based = Foo::Mojobased->new;
}

foreach my $ua ( $lwp, $mech, $mojo, $mojo_based ) {
    my $stderr = capture_stderr sub {
        is(
            exception {
                $ua->get($url);
            },
            undef,
            'Same package: GETing with ' . ref($ua) . ' lives'
        );
    };
    ok $stderr, '... and there was a dump';
}

{
    package Foo::Bar;

    our $lwp  = LWP::UserAgent->new( cookie_jar => {} );
    our $mech = WWW::Mechanize->new( autocheck  => 0 );

    our ( $mua, $mua_based );
    if ($mojo) {
        $mua       = Mojo::UserAgent->new;
        $mua_based = Foo::Mojobased->new;
    }
}

package main;

foreach my $ua (
    $Foo::Bar::lwp, $Foo::Bar::mech, $Foo::Bar::mua,
    $Foo::Bar::mua_based
) {
    next unless $ua;    # skip mojo if it's not installed

    my $stderr = capture_stderr sub {
        is(
            exception {
                $ua->get($url);
            },
            undef,
            'Different package: GETing with ' . ref($ua) . ' lives'
        );
    };
    diag $stderr;
    ok $stderr, '... and there was a dump';
}

is(
    (
        grep { $_->isa('LWP::ConsoleLogger') }
            @{ LWP::ConsoleLogger::Everywhere->loggers }
    ),
    4 + defined($mojo) + defined($mojo_based) + defined($Foo::Bar::mua)
        + defined($Foo::Bar::mua_based),
    'all loggers are stored'
);

is(
    exception {
        LWP::ConsoleLogger::Everywhere->set( dump_content => 0 );
    },
    undef,
    'changing settings on all loggers at once lives'
);

is(
    (
        grep { $_->dump_content == 0 }
            @{ LWP::ConsoleLogger::Everywhere->loggers }
    ),
    4 + defined($mojo) + defined($mojo_based) + defined($Foo::Bar::mua)
        + defined($Foo::Bar::mua_based),
    '... and all loggers have been changed'
);

done_testing();
