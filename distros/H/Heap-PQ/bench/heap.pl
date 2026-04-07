#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:all);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

use Heap::PQ 'import';
use Heap::PQ 'raw';

my $has_array_heap = eval { require Array::Heap; Array::Heap->import(qw(make_heap push_heap pop_heap)); 1 };

# Pure Perl min-heap for baseline comparison
package PureHeap {
    sub new { bless { data => [] }, $_[0] }

    sub push {
        my ($self, $val) = @_;
        push @{$self->{data}}, $val;
        $self->_sift_up($#{$self->{data}});
        return $self;
    }

    sub pop {
        my $self = shift;
        return undef unless @{$self->{data}};
        my $top  = $self->{data}[0];
        my $last = pop @{$self->{data}};
        if (@{$self->{data}}) {
            $self->{data}[0] = $last;
            $self->_sift_down(0);
        }
        return $top;
    }

    sub top   { $_[0]->{data}[0] }
    sub count { scalar @{$_[0]->{data}} }

    sub _sift_up {
        my ($self, $idx) = @_;
        while ($idx > 0) {
            my $parent = int(($idx - 1) / 2);
            last if $self->{data}[$parent] <= $self->{data}[$idx];
            @{$self->{data}}[$parent, $idx] = @{$self->{data}}[$idx, $parent];
            $idx = $parent;
        }
    }

    sub _sift_down {
        my ($self, $idx) = @_;
        my $size = @{$self->{data}};
        while (1) {
            my $left     = 2 * $idx + 1;
            my $right    = 2 * $idx + 2;
            my $smallest = $idx;
            $smallest = $left  if $left  < $size && $self->{data}[$left]  < $self->{data}[$smallest];
            $smallest = $right if $right < $size && $self->{data}[$right] < $self->{data}[$smallest];
            last if $smallest == $idx;
            @{$self->{data}}[$idx, $smallest] = @{$self->{data}}[$smallest, $idx];
            $idx = $smallest;
        }
    }
}

package main;

my @data = map { int(rand(10000)) } 1..1000;

sub head { print "\nTest: $_[0]\n", "-" x 40, "\n" }

# ---- Push 1000 items ----
head("Push 1000 random integers");
{
    my %tests = (
        'Heap::PQ OO'   => sub { my $h = Heap::PQ->new('min'); $h->push($_) for @data },
        'Heap::PQ func' => sub { my $h = Heap::PQ::new('min'); heap_push($h, $_) for @data },
        'Heap::PQ raw'  => sub { my @h; Heap::PQ::push_heap_min(\@h, $_) for @data },
        'Heap::PQ NV'   => sub { my $h = Heap::PQ::new_nv('min'); Heap::PQ::nv::push($h, $_) for @data },
        'Pure Perl'     => sub { my $h = PureHeap->new; $h->push($_) for @data },
    );
    $tests{'Array::Heap'} = sub { my @h; push_heap(\@h, $_) for @data } if $has_array_heap;
    cmpthese(-2, \%tests);
}

# ---- Push then pop all ----
head("Push 1000 then pop all (heapsort)");
{
    my %tests = (
        'Heap::PQ OO'   => sub { my $h = Heap::PQ::new('min'); $h->push($_) for @data; $h->pop while $h->size },
        'Heap::PQ func' => sub { my $h = Heap::PQ::new('min'); heap_push($h, $_) for @data; heap_pop($h) while heap_size($h) },
        'Heap::PQ raw'  => sub { my @h; Heap::PQ::push_heap_min(\@h, $_) for @data; Heap::PQ::pop_heap_min(\@h) while @h },
        'Heap::PQ NV'   => sub { my $h = Heap::PQ::new_nv('min'); Heap::PQ::nv::push($h, $_) for @data; Heap::PQ::nv::pop($h) while Heap::PQ::nv::size($h) },
        'Pure Perl'     => sub { my $h = PureHeap->new; $h->push($_) for @data; $h->pop while $h->count },
    );
    $tests{'Array::Heap'} = sub { my @h; push_heap(\@h, $_) for @data; pop_heap(\@h) while @h } if $has_array_heap;
    cmpthese(-2, \%tests);
}

# ---- Bulk insert ----
head("Bulk insert 1000 items (push_all / make_heap)");
{
    my %tests = (
        'Heap::PQ push_all' => sub { my $h = Heap::PQ::new('min'); $h->push_all(@data) },
        'Heap::PQ make_min' => sub { my @h = @data; Heap::PQ::make_heap_min(\@h) },
        'Pure Perl'         => sub { my $h = PureHeap->new; $h->push($_) for @data },
    );
    $tests{'Array::Heap make'} = sub { my @h = @data; make_heap(\@h) } if $has_array_heap;
    cmpthese(-2, \%tests);
}

# ---- Peek ----
head("Peek 10000 times on pre-built heap of 1000");
{
    my $xs = Heap::PQ::new('min'); $xs->push_all(@data);
    my $pp = PureHeap->new;        $pp->push($_) for @data;

    my %tests = (
        'Heap::PQ OO'   => sub { $xs->peek for 1..10000 },
        'Heap::PQ func' => sub { heap_peek($xs) for 1..10000 },
        'Pure Perl'     => sub { $pp->top for 1..10000 },
    );
    if ($has_array_heap) {
        my @ah = @data; make_heap(\@ah);
        $tests{'Array::Heap'} = sub { my $x = $ah[0] for 1..10000 };
    }
    cmpthese(-2, \%tests);
}

# ---- Mixed push/pop ----
head("Mixed push/pop (priority queue simulation, 500 rounds)");
{
    my %tests = (
        'Heap::PQ OO'   => sub { my $h = Heap::PQ::new('min'); for my $i (0..499) { $h->push($data[$i]); $h->push($data[$i+500]); $h->pop } },
        'Heap::PQ func' => sub { my $h = Heap::PQ::new('min'); for my $i (0..499) { heap_push($h,$data[$i]); heap_push($h,$data[$i+500]); heap_pop($h) } },
        'Pure Perl'     => sub { my $h = PureHeap->new;         for my $i (0..499) { $h->push($data[$i]);  $h->push($data[$i+500]);  $h->pop } },
    );
    $tests{'Array::Heap'} = sub { my @h; for my $i (0..499) { push_heap(\@h,$data[$i]); push_heap(\@h,$data[$i+500]); pop_heap(\@h) } } if $has_array_heap;
    cmpthese(-2, \%tests);
}

