# perl
#$Id$
# 91_func_errors.t
use strict;
use Test::More tests => 176;
use List::Compare::Functional qw(:originals :aliases);
use lib ("./t");
use Test::ListCompareSpecial qw( :seen :func_wrap :arrays :hashes :results );
use IO::CaptureOutput qw( capture );

my @pred = ();
my %seen = ();
my %pred = ();
my @unpred = ();
my (@unique, @complement, @intersection, @union, @symmetric_difference, @bag);
my ($unique_ref, $complement_ref, $intersection_ref, $union_ref,
$symmetric_difference_ref, $bag_ref);
my ($LR, $RL, $eqv, $disj, $return, $vers);
my (@nonintersection, @shared);
my ($nonintersection_ref, $shared_ref);
my ($memb_hash_ref, $memb_arr_ref, @memb_arr);
my ($unique_all_ref, $complement_all_ref);
my @args;

my $error = q{--bad-string};
my %badhash1 = (
    alpha   => 1,
    beta    => q{omega},
);
my %badhash2 = (
    gamma   => 1,
    delta   => q{psi},
);
my $bad_lists_msg = q{If argument is single hash ref, you must have a 'lists' key whose value is an array ref};

I_class_func_tests(\&get_union, q{get_union});
I_class_func_tests(\&get_union_ref, q{get_union_ref});
I_class_func_tests(\&get_intersection, q{get_intersection});
I_class_func_tests(\&get_intersection_ref, q{get_intersection_ref});
I_class_func_tests(\&get_shared, q{get_shared});
I_class_func_tests(\&get_shared_ref, q{get_shared_ref});
I_class_func_tests(\&get_nonintersection, q{get_nonintersection});
I_class_func_tests(\&get_nonintersection_ref, q{get_nonintersection_ref});
I_class_func_tests(\&get_symmetric_difference, q{get_symmetric_difference});
I_class_func_tests(\&get_symmetric_difference_ref,
    q{get_symmetric_difference_ref});
I_class_func_tests(\&get_symdiff, q{get_symdiff});
I_class_func_tests(\&get_symdiff_ref, q{get_symdiff_ref});
I_class_func_tests(\&get_bag, q{get_bag});
I_class_func_tests(\&get_bag_ref, q{get_union_ref});

II_class_func_tests(\&get_unique, q{get_unique});
II_class_func_tests(\&get_unique_ref, q{get_unique_ref});
II_class_func_tests(\&get_complement, q{get_complement});
II_class_func_tests(\&get_complement_ref, q{get_complement_ref});

III_class_func_tests(\&is_LsubsetR, q{is_LsubsetR});
III_class_func_tests(\&is_RsubsetL, q{is_RsubsetL});
III_class_func_tests(\&is_LequivalentR, q{is_LequivalentR});
III_class_func_tests(\&is_LeqvlntR, q{is_LeqvlntR});
III_class_func_tests(\&is_LdisjointR, q{is_LdisjointR});

IV_class_func_tests(\&is_member_which, q{is_member_which});
IV_class_func_tests(\&is_member_which_ref, q{is_member_which_ref});
IV_class_func_tests(\&is_member_any, q{is_member_any});

V_class_func_tests(\&are_members_which, q{are_members_which});
V_class_func_tests(\&are_members_any, q{are_members_any});

sub I_class_func_tests {
    my $sub = shift;
    my $name = shift;
    my @results;
    # Assume we have access to imported globals such as @a0, %h1, etc.

    eval { @results = $sub->( { key => 'value' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for bad single hash ref");
    
    eval { @results = $sub->( { lists => 'not a reference' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for bad single hash ref");
    
    eval { @results = $sub->( $error, [ \@a0, \@a1 ] ); };
    like($@, qr/^'$error' must be an array ref/,
        "$name:  Got expected error message for bad non-ref argument");
    
    eval { @results = $sub->( '-u', $error, [ \@a0, \@a1 ] ); };
    like($@, qr/^'$error' must be an array ref/,
        "$name:  Got expected error message for bad non-ref argument");
    
    eval { @results = $sub->( [ \%h0, \@a1 ] ); };
    like($@,
        qr/Arguments must be either all array references or all hash references/,
        "$name:  Got expected error message for mixing array refs and hash refs");
    
    eval { @results = $sub->( [ \%badhash1, \%badhash2 ] ); };
    like($@,
        qr/Values in a 'seen-hash' must be numeric/s,
        "$name:  Got expected error message for bad seen-hash");
    like($@,
        qr/Key:\s+beta\s+Value:\s+omega/s,
        "$name:  Got expected error message for bad seen-hash");
}

sub II_class_func_tests {
    my $sub = shift;
    my $name = shift;
    I_class_func_tests($sub, $name);
    my @results;
    eval { @results = $sub->( $error, [ \@a0, \@a1 ], [2], [3] ); };
    like($@, qr/Subroutine call requires 1 or 2 references as arguments/,
        "$name:  Got expected error message for wrong number of arguments");

    eval { @results = $sub->( $error, [ \%h0, \%h1 ], [2], [3] ); };
    like($@, qr/Subroutine call requires 1 or 2 references as arguments/,
        "$name:  Got expected error message for wrong number of arguments");
}

sub III_class_func_tests {
    my $sub = shift;
    my $name = shift;
    my $result;
    # Assume we have access to imported globals such as @a0, %h1, etc.

    eval { $result = $sub->( { key => 'value' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for bad single hash ref");

    eval { $result = $sub->( { lists => 'not a reference' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for bad single hash ref");
    
    my $i = 2;
    eval { $result = $sub->( [ \@a0, \@a1 ], [ $i, 0 ] ); };
    like($@, qr/No element in index position $i in list of list references passed as first argument to function/,
        "$name:  Got expected error message for non-existent index position");

    eval { $result = $sub->( [ \@a0, \@a1 ], [ $i ] ); };
    like($@, qr/Must provide index positions corresponding to two lists/,
        "$name:  Got expected error message for non-existent index position");
}
    
sub IV_class_func_tests {
    my $sub = shift;
    my $name = shift;
    my @results;
    # Assume we have access to imported globals such as @a0, %h1, etc.

    eval { @results = $sub->( { item  => 'value' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for single hash ref lacking 'lists' key");

    eval { @results = $sub->( { lists => 'not a reference' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for bad single hash ref");
    
    eval { @results = $sub->( { lists  => [ \@a0, \@a1 ] } ); };
    like($@, qr/^If argument is single hash ref, you must have an 'item' key/,
        "$name:  Got expected error message for single hash ref lacking 'item' key");

    eval { @results = $sub->( [ \@a0, \@a1 ] ); };
    like($@, qr/^Subroutine call requires 2 references as arguments/,
        "$name:  Got expected error message for lack of second argument");
}

sub V_class_func_tests {
    my $sub = shift;
    my $name = shift;
    my $result;
    # Assume we have access to imported globals such as @a0, %h1, etc.

    eval { $result = $sub->( { items  => 'value' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for single hash ref lacking 'lists' key");

    eval { $result = $sub->( { lists => 'not a reference' } ); };
    like($@, qr/^$bad_lists_msg/,
        "$name:  Got expected error message for bad single hash ref");
    
    eval { $result = $sub->( { lists  => [ \@a0, \@a1 ] } ); };
    like($@, qr/^If argument is single hash ref, you must have an 'items' key/,
        "$name:  Got expected error message for single hash ref lacking 'items' key");
    
    eval { $result = $sub->( {
        lists  => [ \@a0, \@a1 ],
        items  => 'not a reference',
    } ); };
    like($@, qr/^If argument is single hash ref, you must have an 'items' key/,
        "$name:  Got expected error message for single hash ref with improper 'items' key");

    eval { $result = $sub->( [ \@a0, \@a1 ] ); };
    like($@, qr/^Subroutine call requires 2 references as arguments/,
        "$name:  Got expected error message for lack of second argument");
}
