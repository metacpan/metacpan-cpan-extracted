#!/usr/bin/env perl

use 5.42.0;

use Path::Tiny;
use JSON;
use Data::Printer;
use TAP::Parser;

my @lines =
  map { s/^(\s*)//; { indent => length($1) / 4, test => $_ } }
  grep { /^\s*(not )?ok/ } path('./results.tap')->lines;

my @tests = ( { test => 'main', subtests => [], indent => -1 } );
my @level = $tests[0];

for my $l (@lines) {
    pop @level while $level[-1]->{indent} >= $l->{indent};

    $level[-1]->{subtests} //= [];
    push $level[-1]->{subtests}->@*, $l;
    push @level,                     $l;
}

print_test($_) for @tests;

sub print_test( $t, $prefix = '' ) {
    my ( $verdict, $name ) =
      $t->{test} =~ /(ok|not ok) \d+ - (.*?)(?: \{)?$/g;
    $name =~ s#t/.*draft[\d-]+/##;
    $prefix = join '|', grep { $_ } $prefix, $name;

    if ( $t->{subtests} ) {
        print_test( $_, $prefix ) for $t->{subtests}->@*;
    }
    else {
        say $prefix unless $verdict eq 'ok';
    }
}

__END__

my @tests = process_subtest( path('./results.tap')->slurp );

print_test($_) for @tests;

sub print_test( $t, $indent = 0 ) {
    say "  " x $indent, $t->[0]->description;
    print_test( $_, $indent + 1 ) for $t->@[ 1 .. $t->$#* ];

}

sub process_subtest($subtest) {
    $subtest =~ /^(\s*)/;
    $subtest =~ s/^$1//mg;

    return () unless $subtest;

    my $parser = TAP::Parser->new( { source => $subtest } );

    my @results;
    while ( my $result = $parser->next ) {
        push @results, $result if $result->is_test or $result->is_unknown;
    }

    my @tests;
    while (@results) {
        my @t = shift @results;
        my $subtest;
        while ( @results and $results[0]->is_unknown ) {
            $subtest .= ( shift @results )->as_string . "\n";
        }
        push @t,     process_subtest($subtest);
        push @tests, \@t;
    }

    return \@tests;

}
