#line 1
package Test::Memory::Cycle;

use strict;
use warnings;

#line 14

our $VERSION = '1.04';

#line 46

use Devel::Cycle qw( find_cycle find_weakened_cycle );
use Test::Builder;

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::memory_cycle_ok'}              = \&memory_cycle_ok;
    *{$caller.'::memory_cycle_exists'}          = \&memory_cycle_exists;

    *{$caller.'::weakened_memory_cycle_ok'}     = \&weakened_memory_cycle_ok;
    *{$caller.'::weakened_memory_cycle_exists'} = \&weakened_memory_cycle_exists;
    *{$caller.'::memory_cycle_exists'}          = \&memory_cycle_exists;

    *{$caller.'::weakened_memory_cycle_ok'}     = \&weakened_memory_cycle_ok;
    *{$caller.'::weakened_memory_cycle_exists'} = \&weakened_memory_cycle_exists;

    $Test->exported_to($caller);
    $Test->plan(@_);

    return;
}

#line 79

sub memory_cycle_ok {
    my $ref = shift;
    my $msg = shift;

    my $cycle_no = 0;
    my @diags;

    # Callback function that is called once for each memory cycle found.
    my $callback = sub {
        my $path = shift;
        $cycle_no++;
        push( @diags, "Cycle #$cycle_no" );
        foreach (@$path) {
            my ($type,$index,$ref,$value) = @$_;

            my $str = 'Unknown! This should never happen!';
            my $refdisp = _ref_shortname( $ref );
            my $valuedisp = _ref_shortname( $value );

            $str = sprintf( '    %s => %s', $refdisp, $valuedisp )               if $type eq 'SCALAR';
            $str = sprintf( '    %s => %s', "${refdisp}->[$index]", $valuedisp ) if $type eq 'ARRAY';
            $str = sprintf( '    %s => %s', "${refdisp}->{$index}", $valuedisp ) if $type eq 'HASH';
            $str = sprintf( '    closure %s => %s', "${refdisp}, $index", $valuedisp ) if $type eq 'CODE';

            push( @diags, $str );
        }
    };

    find_cycle( $ref, $callback );
    my $ok = !$cycle_no;
    $Test->ok( $ok, $msg );
    $Test->diag( join( "\n", @diags, '' ) ) unless $ok;

    return $ok;
} # memory_cycle_ok

#line 121

sub memory_cycle_exists {
    my $ref = shift;
    my $msg = shift;

    my $cycle_no = 0;

    # Callback function that is called once for each memory cycle found.
    my $callback = sub { $cycle_no++ };

    find_cycle( $ref, $callback );
    my $ok = $cycle_no;
    $Test->ok( $ok, $msg );

    return $ok;
} # memory_cycle_exists

#line 145

sub weakened_memory_cycle_ok {
    my $ref = shift;
    my $msg = shift;

    my $cycle_no = 0;
    my @diags;

    # Callback function that is called once for each memory cycle found.
    my $callback = sub {
        my $path = shift;
        $cycle_no++;
        push( @diags, "Cycle #$cycle_no" );
        foreach (@$path) {
            my ($type,$index,$ref,$value,$is_weakened) = @$_;

            my $str = "Unknown! This should never happen!";
            my $refdisp = _ref_shortname( $ref );
            my $valuedisp = _ref_shortname( $value );
            my $weak = $is_weakened ? 'w->' : '';

            $str = sprintf( '    %s%s => %s', $weak, $refdisp, $valuedisp )               if $type eq 'SCALAR';
            $str = sprintf( '    %s%s => %s', $weak, "${refdisp}->[$index]", $valuedisp ) if $type eq 'ARRAY';
            $str = sprintf( '    %s%s => %s', $weak, "${refdisp}->{$index}", $valuedisp ) if $type eq 'HASH';

            push( @diags, $str );
        }
    };

    find_weakened_cycle( $ref, $callback );
    my $ok = !$cycle_no;
    $Test->ok( $ok, $msg );
    $Test->diag( join( "\n", @diags, "" ) ) unless $ok;

    return $ok;
} # weakened_memory_cycle_ok

#line 189

sub weakened_memory_cycle_exists {
    my $ref = shift;
    my $msg = shift;

    my $cycle_no = 0;

    # Callback function that is called once for each memory cycle found.
    my $callback = sub { $cycle_no++ };

    find_weakened_cycle( $ref, $callback );
    my $ok = $cycle_no;
    $Test->ok( $ok, $msg );

    return $ok;
} # weakened_memory_cycle_exists


my %shortnames;
my $new_shortname = "A";

sub _ref_shortname {
    my $ref = shift;
    my $refstr = "$ref";
    my $refdisp = $shortnames{ $refstr };
    if ( !$refdisp ) {
        my $sigil = ref($ref) . " ";
        $sigil = '%' if $sigil eq "HASH ";
        $sigil = '@' if $sigil eq "ARRAY ";
        $sigil = '$' if $sigil eq "REF ";
        $sigil = '&' if $sigil eq "CODE ";
        $refdisp = $shortnames{ $refstr } = $sigil . $new_shortname++;
    }

    return $refdisp;
}

#line 278

1;
