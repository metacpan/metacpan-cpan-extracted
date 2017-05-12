package MarpaX::xPathLike::Actions;
use strict;
use Carp;
use warnings FATAL => 'all';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.201';

sub new(){}
sub _do_token{
    my $arg = $_[1];
    $arg =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character
    return $arg;
}
sub _do_double_quoted {
    my $s = $_[1];
    $s =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character 
    $s =~ s/^"|"$//g;
    $s =~ s/\\("|\\)/$1/g;
    return $s;
}
sub _do_single_quoted {
    my $s = $_[1];
    $s =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character 
    $s =~ s/^'|'$//g;
    $s =~ s/\\('|\\)/$1/g;
    return $s;
}
# sub _do_curly_delimited_string{
#     my $s = $_[1];
#     $s =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character 
#     $s =~ s/^{|}$//g;
#     $s =~ s/\\{/{/g;
#     $s =~ s/\\}/}/g;
#     return $s;    
# }
sub _do_re{
    my $re = $_[2];
    return qr/$re/;
}
sub _do_func{
    my $args =    $_[3] || [];
    return {oper => [$_[1], $args]}
}
sub _do_funcw2args{
    return {oper => [$_[1], $_[3],$_[5]]}
}
sub _do_join{
    return join '', @_[1..$#_];
}
sub _do_group{
    return $_[2]
}
sub _do_unaryOperator{
    return {oper => [@_[1,2]]}
}
sub _do_getValueOperator{
    return {values => $_[1]}
}
sub _do_binaryOperation{
    my $oper =     [$_[2]];
    #$oper =~ s/^\s+|\s+$//g;
    my $args =     [@_[1,3]];
    foreach my $i (0..$#$args){
        if (ref $args->[$i] eq q|HASH| 
            and defined $args->[$i]->{q|oper|} 
            and $args->[$i]->{q|oper|}->[0] eq $oper->[0]){
            my $list = $args->[$i]->{q|oper|};
            push @$oper, @{$list}[1..$#$list];
        }else{
            push @$oper, $args->[$i]; 
        } 
    }
    return {oper => $oper};
}
sub _do_exists{
    return {oper => [q|exists|, $_[1]]}
}
sub _do_stepFilterSubpath(){
    my ($step, $filter, $subpath) = @_[1..3];
    carp q|arg is not a hash ref| unless ref $step eq q|HASH|; 
    @{$step}{qw|filter subpath|} = ($filter,$subpath);
    return $step;
}
sub _do_stepFilter(){
    my ($step, $filter) = @_[1,2];
    carp q|arg is not a hash ref| unless ref $step eq q|HASH|; 
    $step->{filter} = $filter;
    return $step;
}
sub _do_stepSubpath{
    my ($step,$subpath) = @_[1,2];
    carp q|arg is not a hash ref| unless ref $step eq q|HASH|; 
    $step->{subpath} = $subpath;
    return $step;
}
sub _do_path{
    return {paths => $_[1]}    
}
sub _do_pushArgs2array{
    my ($a,$b) = @_[1,3];
    my @array = (@$a,@$b);
    return \@array;
}
sub _do_absolutePath{
    return [{absolute => 1, path => $_[1]}];
}
sub _do_relativePath{
    return [{relative => 1, path => $_[1]}];
}
sub _do_relativePath2{
    return [{relative => 1, path => $_[2]}];
}
sub _do_boolean_filter{ 
    return {boolean => $_[2]}
};
sub _do_mergeFilters{
    my ($filters1, $filters2) = @_[1,2];
    my @filters = (@$filters1, @$filters2);
    return \@filters; 
}
sub _do_index_filter{
    return {indexes => $_[2]}
}
sub _do_index_single{
    return {index => $_[1]}
}
sub _do_index_range{
    return {range => [@_[1,3]]}
}
sub _do_startRange{
    {from => $_[1]}
}
sub _do_endRange{
    {to => $_[2]}
}
sub  _do_vlen{
    return {
            slashslash => $_[1],
            subpath => $_[2]
    };
}
sub _do_descendant{
    return {descendant => $_[1]};    
}
sub _do_descendantArray{
    return {descendantArray => $_[1]};    
}
sub _do_descendantHash{
    return {descendantHash => $_[1]};    
}
sub _do_descendantNamed{
    return {descendantNamed => $_[2]};    
}
sub _do_descendantIndexed{
    return {descendantIndexed => $_[2]};    
}
sub _do_descendantIndexedOrNamed{
    return {descendantIndexedOrNamed => $_[2]};    
}
sub _do_descendantOrSelf{
    return {descendantOrSelf => $_[1]};    
}
sub _do_descendantOrSelfArray{
    return {descendantOrSelfArray => $_[1]};    
}
sub _do_descendantOrSelfHash{
    return {descendantOrSelfHash => $_[1]};    
}
sub _do_descendantOrSelfNamed{
    return {descendantOrSelfNamed => $_[2]};    
}
sub _do_descendantOrSelfIndexed{
    return {descendantOrSelfIndexed => $_[2]};    
}
sub _do_descendantOrSelfIndexedOrNamed{
    return {descendantOrSelfIndexedOrNamed => $_[2]};    
}
sub _do_precedingSibling{
    return {precedingSibling => $_[1]};    
}
sub _do_precedingSiblingArray{
    return {precedingSiblingArray => $_[1]};    
}
sub _do_precedingSiblingHash{
    return {precedingSiblingHash => $_[1]};    
}
sub _do_precedingSiblingNamed{
    return {precedingSiblingNamed => $_[2]};    
}
sub _do_precedingSiblingIndexed{
    return {precedingSiblingIndexed => $_[2]};    
}
sub _do_precedingSiblingIndexedOrNamed{
    return {precedingSiblingIndexedOrNamed => $_[2]};    
}
sub _do_followingSibling{
    return {followingSibling => $_[1]};    
}
sub _do_followingSiblingArray{
    return {followingSiblingArray => $_[1]};    
}
sub _do_followingSiblingHash{
    return {followingSiblingHash => $_[1]};    
}
sub _do_followingSiblingNamed{
    return {followingSiblingNamed => $_[2]};    
}
sub _do_followingSiblingIndexed{
    return {followingSiblingIndexed => $_[2]};    
}
sub _do_followingSiblingIndexedOrNamed{
    return {followingSiblingIndexedOrNamed => $_[2]};    
}
sub _do_child{
    return {child => $_[1]};
}
sub _do_childArray{
    return {childArray => $_[1]};
}
sub _do_childHash{
    return {childHash => $_[1]};
}
sub _do_keyname{
    return {childNamed => $_[1]};    
}
sub _do_array_index{
    return {childIndexed => $_[2]}    
}
sub _do_array_hash_index{
    return {childIndesxedOrNamed => $_[1]}    
}
sub _do_childNamed{
    return {childNamed => $_[2]};
}
sub _do_childIndexed{
    return {childIndexed => $_[2]};
}
sub _do_childIndexedOrNamed{
    return {childIndesxedOrNamed => $_[2]};
}
sub _do_self{
    return {self =>  $_[1]};    
}
sub _do_selfArray{
    return {selfArray =>  $_[1]};    
}
sub _do_selfHash{
    return {selfHash =>  $_[1]};    
}
sub _do_selfNamed{
    return { selfNamed => $_[2]};    
}
sub _do_selfIndexedOrNamed{
    return { selfIndexedOrNamed => $_[2]};    
}
sub _do_selfIndexed{
    return { selfIndexed => $_[2]};    
}
sub _do_parent{
    return {parent => $_[1]};    
}
sub _do_parentArray{
    return {parentArray => $_[1]};    
}
sub _do_parentHash{
    return {parentHash => $_[1]};    
}
sub _do_parentNamed{
    return {parentNamed => $_[2]};
}
sub _do_parentIndexed{
    return {parentIndexed => $_[2]};
}
sub _do_parentIndexedOrNamed{
    return {parentIndexedOrNamed => $_[2]};
}
sub _do_ancestor{
    return {ancestor => $_[1]};
}
sub _do_ancestorArray{
    return {ancestorArray => $_[1]};
}
sub _do_ancestorHash{
    return {ancestorHash => $_[1]};
}
sub _do_ancestorNamed{
    return {ancestorNamed => $_[2]};    
}
sub _do_ancestorIndexed{
    return {ancestorIndexed => $_[2]};    
}
sub _do_ancestorIndexedOrNamed{
    return {ancestorIndexedOrNamed => $_[2]};    
}
sub _do_ancestorOrSelf{
    return {ancestorOrSelf => $_[1]}    
}
sub _do_ancestorOrSelfArray{
    return {ancestorOrSelfArray => $_[1]}    
}
sub _do_ancestorOrSelfHash{
    return {ancestorOrSelfHash => $_[1]}    
}
sub _do_ancestorOrSelfNamed{
    return {ancestorOrSelfNamed => $_[2]}        
}
sub _do_ancestorOrSelfIndexed{
    return {ancestorOrSelfIndexed => $_[2]}        
}
sub _do_ancestorOrSelfIndexedOrNamed{
    return {ancestorOrSelfIndexedOrNamed => $_[2]}        
}
1;
__END__

= pod 

=head1 Actions 

    Actions for Marpa::R2

=head2 new

=cut