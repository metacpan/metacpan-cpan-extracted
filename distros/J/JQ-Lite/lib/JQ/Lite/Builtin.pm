package JQ::Lite::Builtin;

use strict;
use warnings;

use JQ::Lite::Builtin::Aggregate ();
use JQ::Lite::Builtin::Array ();
use JQ::Lite::Builtin::Encoding ();
use JQ::Lite::Builtin::Math ();
use JQ::Lite::Builtin::Object ();
use JQ::Lite::Builtin::String ();
use JQ::Lite::Builtin::Type ();

my $REGISTRY;

sub _registry {
    return $REGISTRY if $REGISTRY;

    my %registry;
    my @patterns;
    my $register = sub {
        my ($names, $handler) = @_;
        if (ref($names) eq 'Regexp') {
            push @patterns, [$names, $handler];
            return;
        }
        $names = [$names] unless ref($names) eq 'ARRAY';
        for my $name (@{$names}) {
            die "duplicate built-in registration: $name" if exists $registry{$name};
            $registry{$name} = $handler;
        }
    };

    $_->register($register) for qw(
        JQ::Lite::Builtin::Array
        JQ::Lite::Builtin::Object
        JQ::Lite::Builtin::String
        JQ::Lite::Builtin::Math
        JQ::Lite::Builtin::Aggregate
        JQ::Lite::Builtin::Encoding
        JQ::Lite::Builtin::Type
    );

    $REGISTRY = { exact => \%registry, patterns => \@patterns };
    return $REGISTRY;
}

sub dispatch {
    my ($class, $owner, $name, $inputs) = @_;
    my $registry = _registry();
    my $handler = $registry->{exact}{$name};
    return (1, $handler->($owner, $inputs)) if $handler;

    for my $entry (@{ $registry->{patterns} }) {
        my ($pattern, $pattern_handler) = @{$entry};
        if (my @captures = ($name =~ $pattern)) {
            return (1, $pattern_handler->($owner, $inputs, @captures));
        }
    }
    return (0, []);
}

sub registered_names {
    return sort keys %{ _registry()->{exact} };
}

1;
