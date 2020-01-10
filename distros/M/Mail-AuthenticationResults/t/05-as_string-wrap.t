#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $InputARHeader = 'test.example.com; foo=bar string1=string string2=string string3=string string4=string string5=string string6=string';

subtest 'No folding' => sub{
    my $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader );
    my $Parsed = $Parser->parsed();
    $Parsed->set_indent_style( 'none' );
    is( $Parsed->as_string(), $InputARHeader, 'stringifies ok' );
};

subtest 'Set folding' => sub{
    my $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader );
    my $Parsed = $Parser->parsed();
    is( $Parsed->fold_at(), undef, 'Fold at starts undefined' );
    lives_ok( sub{ $Parsed->set_fold_at( 5 ); }, 'set_fold_at lives' );
    is( $Parsed->fold_at(), 5, 'Fold at has been set' );
    is( $Parsed->force_fold_at(), undef, 'Force fold at starts undefined' );
    lives_ok( sub{ $Parsed->set_force_fold_at( 800 ); }, 'set_force_fold_at lives' );
    is( $Parsed->force_fold_at(), 800, 'Force fold at has been set' );
};

subtest 'Extra Short folding' => sub{
    my $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader );
    my $Parsed = $Parser->parsed();
    $Parsed->set_fold_at( 18 );
    $Parsed->set_indent_style( 'entry' );
    my $OutputARHeader = 'test.example.com;
    foo=bar
      string1=
      string
      string2=
      string
      string3=
      string
      string4=
      string
      string5=
      string
      string6=
      string';
    is( $Parsed->as_string(), $OutputARHeader, 'stringifies ok' );
};

subtest 'Short folding' => sub{
    my $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader );
    my $Parsed = $Parser->parsed();
    $Parsed->set_fold_at( 21 );
    $Parsed->set_indent_style( 'entry' );
    my $OutputARHeader = 'test.example.com;
    foo=bar
      string1=string
      string2=string
      string3=string
      string4=string
      string5=string
      string6=string';
    is( $Parsed->as_string(), $OutputARHeader, 'stringifies ok' );
};

subtest 'Longer folding' => sub{
    my $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader );
    my $Parsed = $Parser->parsed();
    $Parsed->set_fold_at( 40 );
    $Parsed->set_indent_style( 'entry' );
    my $OutputARHeader = 'test.example.com;
    foo=bar string1=string
      string2=string string3=string
      string4=string string5=string
      string6=string';
    is( $Parsed->as_string(), $OutputARHeader, 'stringifies ok' );
};

# Force fold at is not currently implemented

done_testing();

