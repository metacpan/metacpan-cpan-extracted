package Hustle::Table;
use version; our $VERSION=version->declare("v0.3.0");

use strict;
use warnings;

use feature "refaliasing";
no warnings "experimental";
use feature "switch";
use feature "state";

use Carp qw<carp croak>;

use Exporter 'import';

our @EXPORT_OK=qw< hustle_add hustle_remove hustle_set_default hustle_reset_counter hustle_prepare_dispatcher >;
our @EXPORT=@EXPORT_OK;

use constant DEBUG=>0;

#constants for entry fields
use enum (qw<matcher_ sub_ label_ count_ ctx_>);

#TODO:
# It's assumed that all matchers take the same amount of time to match. Clearly
# a regex will take more time than a short exact string. A more optimal ordering might
# be achieved if this was measured and incorporated into the ordering.
# 
# Add context field for each entry -	Allow tracing/linking to rest of system
# Return the entry as first item 
# 	Instead of the string that was tested being included in arguments to dispatched code,
# 	a reference to the matching entry should be send instead. To aid in tracing
# 	If the use would like the original string, it can be passed as an additional argument


#Public API
#
sub new {
	my $class=shift//__PACKAGE__;
	my $default=shift//sub {1};
	my $ctx=shift;
	bless [[undef,$default,"default",0,undef]],$class;	#Prefill with default handler
}

#Add and sort according to count/priority
sub add {
	my ($self,@list)=@_;
	my $entry;
	state $id=0;
	my @ids;
	my $rem;
	for my $item (@list){
		given(ref $item){
			when("ARRAY"){
				#warn $item->$*;
				$entry=$item;
				croak "Odd number of test=>dispatch vectors" unless $entry->@* == 5;
			}

			when("HASH"){
				$entry=[$item->@{qw<matcher sub label count cxt>}];
			}

			default {
				if(@list>=4){		#Flat hash/list key pairs passed in sub call
					my %item=@list;
					$entry=[@item{qw<matcher sub label count ctx>}];
					$rem =1;
				}
				elsif(@list==2){
					# matcher=>sub
					$entry=[$list[0],$list[1],undef,undef,undef];
					$rem=1;
				}
				else{
					
				}
			}

		}
		$entry->[label_]=$id++ unless defined $entry->[label_];
		$entry->[count_]= 0 unless defined $entry->[count_];
		croak "target is not a sub reference" unless ref $entry->[sub_] eq "CODE";
		croak "matcher not specified" unless defined $entry->[matcher_];
		#Append the item to the of the list (minus default)
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


#overwrites the default handler.
sub set_default {
	my ($self,$sub,$ctx)=@_;
	my $entry=[undef,$sub,"default",0,$ctx];
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
		#&{$table[$table->@*-1][sub_]}; #Training no dispatching
		
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
	\my @self=shift;	#let sort work in place
	my $default=pop @self;	#prevent default from being sorted
	@self=sort {$b->[count_] <=> $a->[count_]} @self;
	push @self, $default;	#restore default
	1;
}


sub _prepare_online {
        \my @table=shift; #self
        my $d="sub {\n";
	$d.='	my $entry;'."\n";
        $d.='	given (shift) {'."\n";		#Shift out first argument
        for (0..@table-2) {
		#$d.='		$entry=$table['.$_.']'."\n";
		#my $pre='$table['.$_.']';

                $d.='		when (($entry=$table['.$_.'])->[matcher_]){'."\n";
                $d.='			$entry->[count_]++;'."\n";
		$d.="			unshift \@_, \$entry;\n";	#First argument is the match entry
                $d.='			&{$entry->[sub_]};'."\n";
                $d.="		}\n";
        }
        $d.="		default {\n";
        $d.='			$table[$#table][count_]++;'."\n";
	$d.='			unshift @_,$table[$#table];'."\n";	#First argument is the match entry
        $d.='			&{$table[$#table][sub_]};'."\n";
        $d.="		}\n";
        $d.="	}\n}\n";
	#print $d;
        my $s=eval($d);
	$s
	
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
	$d.='my $input=shift @_;'."\n";
	$d.='given($input){
		my $rhit=$cache->{$_};
		if($rhit){
			\my @hit=$rhit;
			#normal case, acutally executes potental regex
			when($hit[matcher_]){
				$hit[count_]++;
				unshift @_, $rhit;
				delete $cache->{$_} if &{$hit[sub_]}; #delete if return is true
				return;

			}
			#if the first case does ot match, its because the cached entry is the default (undef matcher)
			default{
				$hit[count_]++;
				unshift @_, $rhit;
				delete $cache->{$_} if &{$hit[sub_]}; #delete if return is true
				return;
			}
		}
	}';
	$d.="\n".'	my $entry;';
	$d.="\n".'	given ($input) {'."\n";


	for (0..@table-2) {
		#my $pre='$table['.$_.']';

		$d.='		when (($entry=$table['.$_.'])->[matcher_]){'."\n";
		$d.='			$entry->[count_]++;'."\n";
		$d.='			unshift @_, $entry;'."\n";
		$d.='			$cache->{$input}=$entry unless &{$entry->[sub_]};'."\n";
		$d.="			return;\n";
		$d.="		}\n";
	}
	$d.="	}\n";
	$d.='	$entry=$table[$#table];'."\n";
	$d.='	unshift @_, $entry;'."\n";
	$d.='	$cache->{$input}=$entry unless &{$entry->[sub_]};'."\n";
        $d.='	$entry->[count_]++;'."\n";
	$d.="}\n";
	#print $d;
	eval($d);
}


*hustle_add=*add;
*hustle_remove=*remove;
*hustle_set_default=*set_default;
*hustle_reset_counter=*reset_counter;
*hustle_prepare_dispatcher=*prepare_dispatcher;


1;
__END__

