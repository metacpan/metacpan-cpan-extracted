package List::Permutor::Repeat;
 
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
 
require Exporter;
 
@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.01';
 
sub new {
    my $class = shift;
    my $items = [ @_ ];
    bless [ $items, [ (0) x scalar(@$items) ] ], $class;
}
 
sub reset {
    my $self = shift;
    my $items = $self->[0];
    $self->[1] = [ (0) x scalar(@$items) ];
    1;          # No useful return value
}
 
sub peek {
    my $self = shift;
    my $items = $self->[0];
    my $rv = $self->[1];
    @$items[ @$rv ];
}
 
sub next {
    my $self = shift;
    my $items = $self->[0];
    my $rv = $self->[1];     
    return unless @$rv;

    my @next=@$rv;
    my @tail= pop @next;

    while(1){
        if($tail[0]<$#$items){ ## +1
            $tail[0]++;
            $self->[1] = [ @next, @tail ];
            last;
        }elsif(! @next){  ## is max
            $self->[1] = [];
            last;
        }else{   ## this item -> 1 , next item +1
            $tail[0]=0;
            my $n = pop @next;
            unshift @tail, $n;
        }
    }
    return @$items[ @$rv ];
}
 
1;
=pod
=encoding utf8

=head1 NAME
 
List::Permutor::Repeat - Process all possible repeat permutations of a list

组合数学，可重复排列
 
=head1 SYNOPSIS
 
  use List::Permutor::Repeat;
  my $perm = new List::Permutor::Repeat qw/ a b /;
  while (my @set = $perm->next) {
      print @set, "\n";
  }

  #aa
  #ab
  #ba
  #bb
 
=head1 DESCRIPTION

This is repeat permutation. 

Not repeat elem permutation see Tom Phoenix's L<List::Permutor>.
 
=head1 METHODS
 
=over 4
 
=item new LIST

初始化，传入一个数组
 
Returns a permutor for the given items.
 
=item next

取出下一个可重复的排列
 
Returns a list of the items in the next permutation. 

for example, the repeat permutations of (1..5) 
    first:  (1, 1, 1, 1, 1)
     last:  (5, 5, 5, 5, 5)
 
=item peek

取回当前的排列
 
Returns the list of items which would be returned by next() 

=item reset

重置排列，从头开始
 
Resets the iterator to the start. 
 
=back
 
=head1 AUTHOR
 
Abby Pan <abbypan@gmail.com>

The object oriented interface/method is taken from Tom Phoenix's L<List::Permutor>.
 
=cut
