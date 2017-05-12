package ex::implements;

use strict;
no strict 'refs';

require 5.6.0;

my %IMPLEMENTS = ();


sub import {
    my $class = shift;
    my $pkg = caller(0);

    foreach my $interface (@_) {
        next if $pkg->isa($interface);
        no strict 'refs';
        push @{"$pkg\::ISA"}, $interface;
        unless (exists $::{"$interface\::"}{"VERSION"}) {
            eval "require $interface";
            # Only ignore "Can't locate" errors from our eval require.
            # Other fatals must be reported
            die if $@ && $@ !~ /^Can\'t locate .*? at \(eval /;
            unless (%{"$interface\::"}) {
                require Carp;
                Carp::croak("Interface package \"$interface\" is empty.\n",
                            "\t(Perhaps you need to 'use' the module ",
                            "which defines that package first.)");
            }
            $ {"$interface\::VERSION"} = "-1, set by implements.pm"
                unless exists $::{"$interface\::"}{"VERSION"};
        }
        $IMPLEMENTS{$pkg}{$interface} = undef;
    }
}

CHECK {
    my $error_count = 0;
    foreach my $pkg (keys %IMPLEMENTS) {
        foreach my $interface (keys %{$IMPLEMENTS{$pkg}}) {
            my @unimplemented =
                grep {! $pkg->can($_)}
                    keys %{"$interface\::__METHOD"};
            if (@unimplemented) {
                warn("$pkg\: Method",
                     (@unimplemented == 1 ? " '$unimplemented[0]'\n\tis " :
                      ("s '",
                       join("', '", @unimplemented[0 .. $#unimplemented-1]),
                       "' and '$unimplemented[-1]'\n\tare ")),
                     "missing for interface $interface\n");
                $error_count++;
            }
        }
    }
    exit(1) if $error_count;
}

1;
