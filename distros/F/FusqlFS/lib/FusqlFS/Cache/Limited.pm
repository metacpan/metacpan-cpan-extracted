use strict;
use 5.010;

package FusqlFS::Cache::Limited;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Cache::Base';

=head1 NAME

FusqlFS::Cache::Limited - FusqlFS limited cache strategy implementation

=head1 SYNOPSIS

    use FusqlFS::Cache::Limited;

    our %cache;
    tie %cache, 'FusqlFS::Cache::Limited', 10000;

=head1 DESCRIPTION

This is a limited by items number cache strategy implementation. This class is
not to be used directly.

This cache strategy accepts single `threshold' parameter which must be integer
greater than zero and determines maximum number of items to be stored in cache.

This cache strategy tries to keep memory usage low enough by limiting number of
cache items. If on cache write number of items in cache exceeds given
threshold, cache cleanup is forced, striving to decrease cached items number
down to threshold plus 1/8 of total current number of items. So number of cache
items varies between I<(7/8)*threshold> and I<threshold> in fact. It does
cleanup this way to avoid cleanup situations appearance too often.

The cleanup process chooses items to remove quite cleverly: this class keeps
items usage statistics and cleanup process uses this statistics to remove least
used items first. It makes cleanup and cache hit try processes a little slower,
but speeds up cache performance in whole, as resulting hit/miss ratio is
better, than in case of naive cleanup algorithm.

This cache strategy is good if you are going to mount database with a lot
number of records and you have memory issues because of this, as it focuses on
keeping overall number of cached items low enough. If you need to mount
database with moderate number of large records, like records with huge blob or
text fields, you might consider using L<FusqlFS::Cache::File> strategy.

I also recommend setting threshold for this cache strategy to at least 3/4 of
total objects in your database (including all tables, sequences, views, data
rows etc.), which will bring you about 60% cache hits (~45% for 1/2 and ~56%
for 2/3). But this is just a basic recommendation based on educated guess and
some tests with "entry" names generated with normally distributed random
generator. Experiment is your best advisor in this case.

=head1 SEE ALSO

=over

=item *

L<FusqlFS::Cache> and L<FusqlFS::Cache::Base> about FusqlFS cache strategies.

=item *

L<FusqlFS::Entry> for file system entry structure description.

=item *

L<perltie> about object tie()ing in perl.

=back

=cut

=begin testing

#!noinst

ok FusqlFS::Cache::Limited->is_needed(10), 'Limited cache is needed';
ok !FusqlFS::Cache::Limited->is_needed(0), 'Limited cache isn\'t needed';

=end testing
=cut
sub is_needed
{
    return $_[1] > 0;
}

=begin testing

my %cache;
isa_ok tie(%cache, 'FusqlFS::Cache::Limited', 10), 'FusqlFS::Cache::Limited', 'Limited cache tied';

ok !scalar(%cache), 'Cache is empty';

foreach my $n (1..10)
{
    $cache{'test'.$n} = 'value'.$n;
}

ok scalar(%cache), 'Cache is not empty';

foreach my $n (1..10)
{
    ok exists($cache{'test'.$n}), 'Entry '.$n.' exists';
    is $cache{'test'.$n}, 'value'.$n, 'Entry '.$n.' is intact';
}

ok exists($cache{'test10'}), 'Element exists before deletion';
delete $cache{'test10'};
ok !exists($cache{'test10'}), 'Deleted element doesn\'t exist';
is $cache{'test10'}, undef, 'Deleted element is undefined';

%cache = ();

ok !scalar(%cache), 'Cache is empty after cleanup';

foreach my $n (1..1000)
{
    $cache{'test'.$n} = 'value'.$n;
    foreach my $m (1..1000-$n)
    {
        my $x = $cache{'test'.$n};
    }
}

ok exists($cache{'test1'}), 'Most used element exists';
is $cache{'test1'}, 'value1', 'Most used element is intact';
ok !exists($cache{'test999'}), 'Least used element doesn\'t exist';
is $cache{'test999'}, undef, 'Least used element undefined';
cmp_ok length(keys %cache), '<=', 10, 'Number of items in cache doesn\'t exceed given threshold';

while (my ($key, $val) = each %cache)
{
    like $key, qr/^test[0-9]+$/, 'Iterate: key is '.$key.' intact';
    like $val, qr/^value[0-9]+$/, 'Iterate: value is '.$val.' intact';
    is substr($key, 4), substr($val, 5), 'Iterate: key matches value';
}

=end testing
=cut
sub TIEHASH
{
    my $class = shift;
    my $threshold = shift;

    # real hash, hits count, total count, threshold, cleanups count
    my $self = [ {}, {}, 0, 0+$threshold, 0 ];

    bless $self, $class;
}

sub FETCH
{
    my ($self, $key) = @_;
    return unless exists $self->[0]->{$key};
    $self->[1]->{$key}++;
    return $self->[0]->{$key};
}

sub STORE
{
    my ($self, $key, $value) = @_;
    $self->cleanup() if $self->[2] > $self->[3];
    $self->[2]++ unless exists $self->[0]->{$key};
    $self->[0]->{$key} = $value;
    $self->[1]->{$key} = 1;
}

sub DELETE
{
    my ($self, $key) = @_;
    $self->[2]-- if exists $self->[0]->{$key};
    delete $self->[0]->{$key};
    delete $self->[1]->{$key};
}

sub CLEAR
{
    my ($self)= @_;
    $self->[0] = {};
    $self->[1] = {};
    $self->[2] = 0;
}

sub EXISTS
{
    my ($self, $key) = @_;
    return exists $self->[0]->{$key};
}

sub FIRSTKEY
{
    my ($self) = @_;
    my $_ = keys %{$self->[0]};
    each %{$self->[0]};
}

sub NEXTKEY
{
    my ($self, $lastkey) = @_;
    return each %{$self->[0]};
}

sub SCALAR
{
    my ($self) = @_;
    return scalar(%{$self->[0]});
}

sub cleanup
{
    my ($self) = @_;
    my $del_num = $self->[2] - $self->[3] + ($self->[2] >> 3);
    #carp "cleanup: remove $del_num out from $self->[2], threshold is $self->[3]";
    #$self->[5]++;
    my @keys = sort { $self->[1]->{$a} <=> $self->[1]->{$b} } keys %{$self->[1]};

    #carp "top 10 least used keys: ", join(", ", @keys[0..9]);
    #carp "top 10 least counts: ", join(", ", @{$self->[1]}{@keys[0..9]});
    #carp "top 10 most used keys: ", join(", ", @keys[-10..-1]);
    #carp "top 10 most counts: ", join(", ", @{$self->[1]}{@keys[-10..-1]});

    $self->[2] -= $del_num;
    #carp "calculated total: $self->[2]";
    #carp "before cleanup: ", scalar(keys(%{$self->[0]}));

    @keys = @keys[0..$del_num-1];
    delete @{$self->[0]}{@keys};
    delete @{$self->[1]}{@keys};

    #carp "after cleanup: ", scalar(keys(%{$self->[0]}));
}

1;

