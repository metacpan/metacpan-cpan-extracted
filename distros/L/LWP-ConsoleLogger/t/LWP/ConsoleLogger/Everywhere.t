use strict;
use warnings;
use version;

use Capture::Tiny   qw( capture_stderr );
use HTTP::Tiny      ();
use LWP::UserAgent  ();
use Module::Runtime qw( require_module );
use Path::Tiny      qw( path );
use Plack::Loader   ();
use Test::TCP;
use Test::Warnings;
use Test::Fatal qw( exception );
use Test::More import => [qw( diag done_testing is like ok skip )];
use Try::Tiny      qw( catch try );
use WWW::Mechanize ();

use LWP::ConsoleLogger::Everywhere ();

my $url = 'file://' . path('t/test-data/foo.html')->absolute;

my $lwp  = LWP::UserAgent->new( cookie_jar => {} );
my $mech = WWW::Mechanize->new( autocheck  => 0 );

my @agents = ( $lwp, $mech );

my ( $mojo, $mojo_based );
try {
    require_module('Mojo::UserAgent');
    require_module('Mojolicious');

    if ( version->parse($Mojolicious::VERSION) < 7.13 ) {
        die "Mojo version $Mojolicious::VERSION is too low";
    }

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
    push @agents, $mojo, $mojo_based;
}
catch {
SKIP: {
        diag $_ if $_ =~ m{too low};
        skip 'Mojolicious not installed', 1;
    }
};

foreach my $ua (@agents) {
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

# HTTP::Tiny support: creating an instance should register a new logger.
my $before_http_tiny = scalar @{ LWP::ConsoleLogger::Everywhere->loggers };
my $http_tiny        = HTTP::Tiny->new;
is(
    scalar @{ LWP::ConsoleLogger::Everywhere->loggers },
    $before_http_tiny + 1,
    'HTTP::Tiny->new registers a new logger'
);

test_tcp(
    client => sub {
        my $port   = shift;
        my $url    = "http://127.0.0.1:$port/";
        my $stderr = capture_stderr sub {
            $http_tiny->get($url);
        };
        ok $stderr, 'HTTP::Tiny request produced a dump';
        like $stderr, qr{200}, '... and it mentions the status';
    },
    server => sub {
        my $port = shift;
        Plack::Loader->auto( port => $port, host => '127.0.0.1' )
            ->run(
            sub { [ 200, [ 'Content-Type' => 'text/plain' ], ['ok'] ] } );
    },
);

is(
    (
        grep { $_->isa('LWP::ConsoleLogger') }
            @{ LWP::ConsoleLogger::Everywhere->loggers }
    ),
    5 + defined($mojo) + defined($mojo_based) + defined($Foo::Bar::mua)
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
    5 + defined($mojo) + defined($mojo_based) + defined($Foo::Bar::mua)
        + defined($Foo::Bar::mua_based),
    '... and all loggers have been changed'
);

done_testing();
