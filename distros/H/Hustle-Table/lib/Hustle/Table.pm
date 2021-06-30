package Hustle::Table;
use version; our $VERSION=version->declare("v0.2.2");

use strict;
use warnings;

use feature "refaliasing";
no warnings "experimental";
use feature "switch";
use feature "state";

use Carp qw<carp croak>;


use constant DEBUG=>0;

#constants for entry feilds
use enum (qw<matcher_ sub_ label_ count_>);

#TODO:
# It's assumed that all matchers take the same amount of time to match. Clearly
# a regex will take more time than a short exact string. A more optimal ording might
# be achieved if this was measured and incorperated into the ordering.
#


#Public API
#
sub new {
	my $class=shift//__PACKAGE__;
	bless [[undef,sub {1},"default",0]],$class;	#Prefill with default handler
}

#Add and sort accorind to count/priority
sub add {
	my ($self,@list)=@_;
	my $entry;
	state $id=0;
	my @ids;
	my $rem;
	for my $item (@list){
		given(ref $item){
			when("ARRAY"){
			
				$entry=$item;
				croak "Odd number of test=>dispatch vectors" unless $entry->@* == 4;
			}
			when("HASH"){
				$entry=[$item->@{qw<matcher sub label count>}];
			}
			default {
				my %item=@list;
				$entry=[@item{qw<matcher sub label count>}];
				$rem =1;
			}

		}
		$entry->[label_]=$id++ unless defined $entry->[label_];
		$entry->[count_]= 0 unless defined $entry->[count_];
		croak "target is not a sub refernce" unless ref $entry->[sub_] eq "CODE";
		croak "matcher not specified" unless defined $entry->[matcher_];
		#Append the item to the of the list (minus defaut)
		if(defined $entry->[matcher_]){
			splice @$self, @$self-1,0, $entry;
			push @ids,$entry->[label_];
		}
		else {
			$self->[$self->@*-1]=$entry;
		}
		last if $rem;

	}

	#Reorder according to count/priority
	$self->_reorder;
	if(wantarray){
		return @ids;
	}
	return scalar @ids;
}


#overwrites the default handler. if no
sub set_default {
	my ($self,$sub)=@_;
	my $entry=[undef,$sub,"default",0];
	$self->[@$self-1]=$entry;
}

#TODO:
# handle removal of default better
sub remove {
	my ($self,@labels) =@_;

	my @removed;
	OUTER:
	for my $label (@labels){
		for(0..@$self-2){
			if($self->[$_][label_] eq $label){
				push @removed, splice @$self, $_,1;
				next OUTER;
			}
		}
	}
	return @removed;
}


sub reset_counters {
	\my @t=shift; #self
	for (@t){
		$_->[count_]=0;
	}
}

#TODO: write offline test
sub _prepare_offline {
	my ($table)=@_;	#self
	$table->reset_counters;
	sub {
		#my ($dut)=@_;
		\my @table=$table;
		for my $index (0..@table-2){	#do not process the last element
			given($_[0]){
				when($table[$index][matcher_]){
					$table[$index][count_]++;
					#&{$table[$index][sub_]}; #training ... no dispatching
					if($table[$index][count_]>$table[$index-1][count_]){
						my $temp=$table[$index];
						$table[$index]=$table[$index-1];
						$table[$index-1]=$temp;
					}
					return;
				}
				default {
				}
			}

		}
		#&{$table[$table->@*-1][sub_]}; #Traning no dispatching
		
	}
}

sub prepare_dispatcher{
	my $self=shift;
	my %options=@_;

	$options{type}//="online";
	$options{reorder}//=1;
	$options{reset}//=undef;

	if(defined $options{reorder} and $options{reorder}){
		$self->_reorder;
	}

	if(defined $options{reset} and $options{reset}){
		$self->reset_counters;
	}
	carp("Cache not used. Cache must be undef or a hash ref") and return undef if defined $options{cache} and ref($options{cache}) ne "HASH";

	do {
		given($options{type}){
			$self->_prepare_offline when /^offline$/i;	
			$self->_prepare_online_cached($options{cache}) when /^online/i and ref $options{cache} eq "HASH";
			$self->_prepare_online when /^online/i;

			$self->_prepare_online_cached($options{cache}) when undef; 

			
			default {
				#$self->_prepare_online($options{cache});
				carp "Invalid dispatcher type";
				undef;
			}
		}
	}
}

#
#Private API
#
sub _reorder{
	\my @self=shift;	#let sort work inplace
	my $default=pop @self;	#prevent default from being sorted
	@self=sort {$b->[count_] <=> $a->[count_]} @self;
	push @self, $default;	#restor default
	1;
}


sub _prepare_online {
        \my @table=shift; #self
        my $d="sub {\n";
        #$d.='my ($dut)=@_;'."\n";
        $d.=' given ($_[0]) {'."\n";
        for (0..@table-2) {
                my $pre='$table['.$_.']';

                $d.='when ('.$pre."[matcher_]){\n";
                $d.=$pre."[count_]++;\n";
                $d.='&{'.$pre.'[sub_]};'."\n";
                $d.="}\n";
        }
        $d.="default {\n";
        $d.='$table[$#table][count_]++;'."\n";
        $d.='&{$table[$#table][sub_]};'."\n";
        $d.="}\n";
        $d.="}\n}\n";
        eval($d);
}

sub _prepare_goto_online {
        \my @table=shift; #self
        my $d="sub {\n";
        #$d.='my ($dut)=@_;'."\n";
        $d.=' given ($_[0]) {'."\n";
        for (0..@table-2) {
                my $pre='$table['.$_.']';

                $d.='when ('.$pre."[matcher_]){\n";
                $d.=$pre."[count_]++;\n";
                $d.='goto '.$pre.'[sub_];'."\n";
                $d.="}\n";
        }
        $d.="default {\n";
        $d.='$table[$#table][count_]++;'."\n";
        $d.='goto $table[$#table][sub_];'."\n";
        $d.="}\n";
        $d.="}\n}\n";
        eval($d);
}

sub _prepare_online_2 {
        \my @table=shift; #self
        my $d="sub {\n";
        #$d.='my ($dut)=@_;'."\n";
	$d.= 'my $tmp;'."\n";
        $d.=' given ($_[0]) {'."\n";
        for (0..@table-2) {
                my $pre='$table['.$_.']';
		$d.='$tmp='.$pre.";\n";
                $d.='when ($tmp->[matcher_]){'."\n";
                $d.='$tmp->[count_]++;'."\n";
                $d.='&{$tmp->[sub_]};'."\n";
                $d.="}\n";
        }
        $d.="default {\n";
        $d.='$table[$#table][count_]++;'."\n";
        $d.='&{$table[$#table][sub_]};'."\n";
        $d.="}\n";
        $d.="}\n}\n";
        eval($d);
}

sub _prepare_online_cached {
	\my @table=shift; #self
	my $cache=shift;
	if(ref $cache ne "HASH"){
		carp "Cache provided isn't a hash. Using internal cache with no size limits";
		$cache={};
	}

	
	my $d="sub {\n";
	#$d.='my ($dut)=@_;'."\n";
	$d.='
	given( $_[0]){
		my $hit=$cache->{$_};
		if(defined $hit){
			#normal case, acutally executes potental regex
			when($hit->[matcher_]){
				$hit->[count_]++;
				delete $cache->{$_} if &{$hit->[sub_]}; #delete if return is true
				return;

			}
			#if the first case does ot match, its because the cached entry is the default (undef matcher)
			#when(!defined $hit->[matcher_]){	#default case, test for defined
			default{
				$hit->[count_]++;
				delete $cache->{$_} if &{$hit->[sub_]}; #delete if return is true
				return;
			}
		}
	}';
			
	$d.="\n".' given ($_[0]) {'."\n";


	for (0..@table-2) {
		my $pre='$table['.$_.']';

		$d.='when ('.$pre."[matcher_]){\n";
		$d.=$pre."[count_]++;\n";
		$d.='$cache->{$_[0]}='."$pre unless &{$pre".'[sub_]};'."\n";
		$d.="return;\n}\n";
	}
	$d.="}\n";
	$d.='$cache->{$_[0]}=$table[$#table] unless &{$table[$#table][sub_]};'."\n";
        $d.='$table[$#table][count_]++;'."\n";
	$d.="}\n";
	eval($d);
}



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

