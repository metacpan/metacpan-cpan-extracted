package Test::TiedArray;

use utf8;
use strict;
use warnings;

sub STORE {
    my ($self, $key, $value) = @_;
    return $self->{data}[$key] = $value;
}

sub PUSH {
    my ($self, @values) = @_;
    push(@{$self->{data}}, @values);
    $self->STORESIZE(scalar(@{$self->{data} // []}));
}

sub TIEARRAY {
    my ($class, @list) = @_;
    my $self = bless({data => []}, $class);
    return $self;
}

sub FETCHSIZE {
    my ($self) = @_;
    return $self->{count} // 0;
}

sub STORESIZE {
    my ($self, $count) = @_;
    return ($self->{count} = $count);
}

sub FETCH {
    my ($self, $index) = @_;
    return($self->{data}->[$index]);
}

sub DELETE {
    my ($self, $key) = @_;
    return splice(@{$self->{data}}, $key, 1);
}

sub CLEAR {
    my ($self) = @_;
    return($self->{data} = []);
}

sub DESTROY {
    my ($self) = @_;
    delete(@{$self}{qw/data count/});
    return;
}

1;

package main;

use utf8;
use strict;
use warnings;
# use Config ();
# my $config_args = $Config::Config{config_args} // ''
# if ($config_args !~ m/usethreads/) {

use Test::LeakTrace qw/ no_leaks_ok /;
use Test::More ('import' => [qw/ done_testing is ok use_ok fail /]);

BEGIN { use_ok('List::Helpers::XS') };

List::Helpers::XS->import(':all');

sub check_shuffled_array;
sub check_even_distribution;

check_even_distribution();

my @list = ( 0 .. 9 );

shuffle(\@list);
is( scalar(@list), 10, "Checking the list size after shuffling" );

check_shuffled_array( [0 .. 9], \@list);

List::Helpers::XS::shuffle(@list);
is( scalar(@list), 10, "Checking the list size after shuffling" );

@list = ( 0 .. 9 );

my $slice = random_slice(\@list, 3);
is( scalar(@list), 10, "Checking the list size after slicing" );
is( scalar(@$slice), 3, "Checking the slice size" );

my @list2 = (0..4);
my @list3 = (20..27);
my @list4 = (40..45);
shuffle_multi(\@list2, undef, \@list3, \@list4);

is( scalar(@list2), 5, "Checking the size of list2 after multi-array shuffling" );
is( scalar(@list3), 8, "Checking the size of list3 after multi-array shuffling" );
is( scalar(@list4), 6, "Checking the size of list4 after multi-array shuffling" );

check_shuffled_array( [0 .. 4], \@list2);
check_shuffled_array( [20 .. 27], \@list3);
check_shuffled_array( [40 .. 45], \@list4);

undef(@list2);
undef(@list3);
undef(@list4);
undef(@list);
undef($slice);

# tied lists
my @t_list;
my $t_slice;

tie(@t_list, "Test::TiedArray");
push(@t_list, ( 0 .. 9 ) );

shuffle(\@t_list);
is( scalar(@t_list), 10, "Checking the size of tied list after shuffling" );
check_shuffled_array( [0 .. 9], \@t_list);

List::Helpers::XS::shuffle(@t_list);
is( scalar(@t_list), 10, "Checking the size of tied list after shuffling" );

push(@t_list, (11 .. 15));

$t_slice = random_slice(\@t_list, 4);
is( scalar(@t_list), 15, "Checking the size of tied after slicing" );
is( scalar(@$t_slice), 4, "Checking the size of tied slice" );

undef(@t_list);
undef($t_slice);

# check for memory leaks
no_leaks_ok {

    @list = ( 0 .. 9 );

    shuffle(\@list);
    List::Helpers::XS::shuffle(@list);
        
    @list = ( 0 .. 9 );
    
    @list2 = (0..4);
    @list3 = (20..27);
    @list4 = (40..45);
    shuffle_multi(\@list2, undef, \@list3, \@list4);

    # tied array

    @t_list = ();
    tie(@t_list, "Test::TiedArray");

    push(@t_list, ( 0 .. 2 ) );

    shuffle(\@t_list);
    List::Helpers::XS::shuffle(@t_list);

    undef(@t_list);
} 'no memory leaks';

done_testing();

# ====

sub check_shuffled_array {
    my ($orig, $shuffled) = @_;
    my $is_shuffled = 0;
    is(scalar($orig->@*), scalar($shuffled->@*), "Comparing the size of original and shuffled arrays");
    for my $i (0 .. $#{$orig}) {
        my $orig_val = $orig->[$i];
        my $shuffled_val = $shuffled->[$i];
        if ($orig_val != $shuffled_val) {
            $is_shuffled = 1;
            last;
        }
    }
    ok($is_shuffled, "Checking that array is shuffled");
}

sub check_even_distribution {

    my $cnt = 1_000_000;
    my @stat;
    for(1 .. $cnt) {
        my $arr = [0..9];
        shuffle($arr);
        for my $i (0 .. 9) {
            $stat[ $i ]->[ $arr->[ $i ] ]++;
        }
    }

    CHECK_EVEN_DISTRIBUTION:
    for my $i (0 .. 9) {
        for my $value (0 .. 9) {
            my $share = $stat[ $i ]->[ $value ] / $cnt;
            if ($share == 0) {
                fail("Failed to check even distribution");
                last CHECK_EVEN_DISTRIBUTION;
            }
            #printf "%.2f;", ($stat[ $pos ]->[ $digit ] / $cnt) * 100;
        }
        #print "\n";
    }
}

1;
__END__
