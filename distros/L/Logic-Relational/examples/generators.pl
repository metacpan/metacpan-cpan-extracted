#!/usr/bin/env perl

use v5.38;
use lib ( '../lib', 'lib' );
use Logic::Relational::Syntax;

# Define the Shop program using declarative syntax
logic Shop {

    # We simulate a database table of products in a lexical hash.
    my %product_db = (
        'SKU-100' => { name => 'Coffee Maker', price => 45 },
        'SKU-200' => { name => 'Toaster',      price => 18 },
        'SKU-300' => { name => 'Blender',      price => 29 },
        'SKU-400' => { name => 'Mug',          price => 8 },
    );

    # Register generator on the program
    generator product(3) sub ( $sku, $name, $price ) {
        if ( defined $sku && !ref($sku) ) {

            # SKU is ground (bound) - Perform direct optimized lookup!
            say "   [DB Log] SKU is bound: '$sku'. Performing direct lookup.";
            my $prod = $product_db{$sku};
            my @res  = $prod ? ( [ $sku, $prod->{name}, $prod->{price} ] ) : ();
            return sub { return shift @res };
        }
        else {
            # SKU is a variable (unbound) - Yield all rows (table scan)
            say "   [DB Log] SKU is unbound. Scanning whole database.";
            my @skus = sort keys %product_db;
            return sub {
                return unless @skus;
                my $k = shift @skus;
                return [ $k, $product_db{$k}{name}, $product_db{$k}{price} ];
            };
        }
    };

    # Rule: cheap_item(SKU, Name) :- product(SKU, Name, Price), Price < 20
    rule cheap_item( $sku, $name ) {
        fresh my $price;
        product( $sku, $name, $price );
        guard( [$price], sub ($p) { $p < 20 } );
    }
}

# Define the Streams program using declarative syntax
logic Streams {

    # Generators can yield infinite streams of values on demand!
    generator fibonacci(1) sub ($n) {
        my $fib0 = 0;
        my $fib1 = 1;
        return sub {
            my $curr = $fib0;
            $fib0 = $fib1;
            $fib1 = $curr + $fib1;
            return [$curr];
        };
    };
}

say "=== EXAMPLE 1: Input-Sensitive Database Generator ===";

# Query 1: Lookup a specific SKU (optimized bound path)
say "\n--- Querying Specific SKU-200 (direct lookup) ---";
query Shop::product( 'SKU-200', fresh my $n1, fresh my $p1 )->my $q1;
if ( my $sol = $q1->next ) {
    say "Found: Name = " . $sol->value($n1) . ", Price = \$" . $sol->value($p1);
}

# Query 2: Scan all cheap items (backtracking over generator candidates)
say "\n--- Finding all items under \$20 (table scan + guard backtracking) ---";
query Shop::cheap_item( fresh my $s2, fresh my $n2 )->my $q2;
while ( my $sol = $q2->next ) {
    say "Cheap Item: SKU = "
      . $sol->value($s2)
      . ", Name = "
      . $sol->value($n2);
}

say "\n=== EXAMPLE 2: Infinite Stream Generator (Fibonacci) ===";

# Querying the infinite stream. We limit output in the while loop.
say "--- Querying first 10 Fibonacci numbers (with execution trace) ---";
query Streams::fibonacci( fresh my $fib_val )->my $q3;

# put a trace on it to see what's going on
my $trace_count = 0;
$q3->trace(
    sub ($event) {
        return if $trace_count++ >= 20;
        my $goal_str = $event->goal ? $event->goal->as_string : 'undef';
        say "   [Trace] Event: "
          . sprintf( "%-10s", $event->type )
          . " | Goal: $goal_str";
    }
);

my $count = 0;
while ( my $sol = $q3->next ) {
    last if ++$count > 10;
    say "   => Fibonacci #$count = " . $sol->value($fib_val);
}

say "\n=== Done ===";

