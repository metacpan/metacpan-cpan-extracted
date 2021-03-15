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

use Test::LeakTrace qw/ no_leaks_ok /;
use Test::More ('import' => [qw/ done_testing is use_ok /]);

BEGIN { use_ok('List::Helpers::XS') };

List::Helpers::XS->import(':all');

my @list = ( 0 .. 9 );

shuffle(\@list);
is( scalar(@list), 10, "Checking the list size after shuffling" );

List::Helpers::XS::shuffle(@list);
is( scalar(@list), 10, "Checking the list size after shuffling" );

random_slice_void(\@list, 3);
is( scalar(@list), 3, "Checking the list size after slicing in void context" );

@list = ( 0 .. 9 );

my $slice = random_slice(\@list, 3);
is( scalar(@list), 10, "Checking the list size after slicing" );
is( scalar(@$slice), 3, "Checking the slice size" );

undef(@list);
undef($slice);

# tied lists

my @t_list;
tie(@t_list, "Test::TiedArray");
push(@t_list, ( 0 .. 9 ) );

shuffle(\@t_list);
is( scalar(@t_list), 10, "Checking the size of tied list after shuffling" );

List::Helpers::XS::shuffle(@t_list);
is( scalar(@t_list), 10, "Checking the size of tied list after shuffling" );

random_slice_void(\@t_list, 5);
is( scalar(@t_list), 5, "Checking the size of tied list after slicing in void context" );

push(@t_list, (11 .. 15));

my $t_slice = random_slice(\@t_list, 4);
is( scalar(@t_list), 15, "Checking the size of tied after slicing" );
is( scalar(@$t_slice), 4, "Checking the size of tied slice" );

undef(@t_list);
undef($t_slice);

# check for memory leaks
no_leaks_ok {

    @list = ( 0 .. 9 );

    shuffle(\@list);
    List::Helpers::XS::shuffle(@list);
        
    random_slice_void(\@list, 3);

    @list = ( 0 .. 9 );
    
    $slice = random_slice_void(\@list, 5);

    # tied array

    @t_list = ();
    tie(@t_list, "Test::TiedArray");

    push(@t_list, ( 0 .. 2 ) );

    shuffle(\@t_list);
    List::Helpers::XS::shuffle(@t_list);

    random_slice_void(\@t_list, 1);

    undef(@t_list);
} 'no memory leaks';

done_testing();

1;
__END__
