use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Dotenv;

for my $env ( glob 't/env/*.env' ) {
    ( my $pl = $env ) =~ s/\.env$/\.pl/;
    next unless -e $pl;
    my %expected = eval Path::Tiny->new($pl)->slurp_utf8;

    # parse
    my $got = Dotenv->parse($env);
    is_deeply( $got, \%expected, "$env (parse)" );

    # load (changes %ENV)
    my %env = ( %expected, local %ENV = %ENV );
    Dotenv->load( $env );
    is_deeply( \%ENV, \%env, "$env (load)" );
}

done_testing;
