package Hustle::Table;
use version; our $VERSION=version->declare("v0.5.1");

use strict;
use warnings;

use Template::Plex;

use feature "refaliasing";
no warnings "experimental";
use feature "state";

use Carp qw<carp croak>;



use constant DEBUG=>0;

#constants for entry fields
use enum (qw<matcher_ value_ type_ default_>);

#Public API
#
sub new {
	my $class=shift//__PACKAGE__;
	my $default=shift//undef;
	bless [[undef,$default, "exact",1]],$class;	#Prefill with default handler
}

sub add {
	my ($self,@list)=@_;
	my $entry;
	my $rem;
	for my $item (@list){
		for(ref $item){
			if(/ARRAY/){
				#warn $item->$*;
				$entry=$item;
				croak "Incorrect number of items in dispatch vector. Should be 3" unless $entry->@* == 3;
			}

			elsif(/HASH/){
				$entry=[$item->@{qw<matcher value type>}];
			}

			else{
				if(@list>=4){		#Flat hash/list key pairs passed in sub call
					my %item=@list;
					$entry=[@item{qw<matcher value type>}];
					$rem =1;
				}
				elsif(@list==2){	#Flat list of matcher and sub. Assume regex
					# matcher=>sub
					$entry=[$list[0],$list[1],undef];
					$rem=1;
				}
				else{
					
				}
			}

		}

		croak "matcher not specified" unless defined $entry->[matcher_];

		if(defined $entry->[matcher_]){
			#Append to the end of the normal matching list 
			splice @$self, @$self-1,0, $entry;
		}
		else {
			#No matcher, thus this used as the default
			$self->set_default($entry->[value_]);
			#$self->[$self->@*-1]=$entry;
		}
		last if $rem;
	}
}


#overwrites the default handler.
sub set_default {
	my ($self,$sub)=@_;
	my $entry=[undef,$sub,"exact",1];
	$self->[@$self-1]=$entry;
}



sub prepare_dispatcher{
	my $self=shift;
	my %options=@_;
	my $cache=$options{cache}//{};
	$self->_prepare_online_cached($cache);
}

#
#Private API
#

sub _prepare_online_cached {
	my $table=shift; #self
	my $cache=shift;
	if(ref $cache ne "HASH"){
		carp "Cache provided isn't a hash. Using internal cache with no size limits";
		$cache={};
	}

	#\$entry=\$table->[$index];
	#\$matcher=\$entry->[Hustle::Table::matcher_];
	my $sub_template=
	'	 
	@{[do {
		my $do_capture;
		my $d="if";
		for($item->[Hustle::Table::type_]){
                        if(ref($item->[Hustle::Table::matcher_]) eq "Regexp"){
			#$d.=\'($input=~m{\' . $item->[Hustle::Table::matcher_] .\'})\';
				$d.=\'($input=~$table->[\'. $index .\'][Hustle::Table::matcher_] )\';
				$do_capture=1;
                        }
                        elsif(/exact/){
				$d.=\'($input eq "\'. $item->[Hustle::Table::matcher_]. \'")\';
                        }
                        elsif(/begin/){
                                $d.=\'(index($input, "\' . $item->[Hustle::Table::matcher_]. \'")==0)\';
                        }
                        elsif(/end/){
                                $d.=\'(index(reverse($input), reverse("\'. $item->[Hustle::Table::matcher_].\'"))==0)\';
                        }
                        elsif(/numeric/){
                                $d.=\'(\' . $item->[Hustle::Table::matcher_] . \'== $input)\';
                        }
                        else{
                                #assume a regex
				$item->[Hustle::Table::matcher_]=qr{$item->[Hustle::Table::matcher_]};
				$item->[Hustle::Table::type_]=undef;
				$do_capture=1;
				$d.=\'($input=~m{\' . $item->[Hustle::Table::matcher_].\'})\';
                        }
		}
		$d.=\'{ \';

		$d.=\'$entry=$table->[\'.$index.\'];\';
		$d.=\' $cache->{$input}=$entry;\';

		if($do_capture){
			$d.=\' return $entry,[@{^CAPTURE}];\'; 
		}	
		else {
			$d.=\' return $entry,[];\'; 

		}


		$d.=\'}\';
		$d;
	}]}
	';

	my $template=
	' sub {
		my \$input=shift;
		my \$rhit=\$cache->{\$input};
		my \$entry;
		if(\$rhit){
			\\\my \@hit=\$rhit;
			#normal case, acutally executes potental regex
			unless(\$hit[Hustle::Table::type_]){
				if(\$input=~ \$hit[Hustle::Table::matcher_]){
                                        return \$rhit, [\@{^CAPTURE}];

				}
			}
			else{
				#string or number
				return \$rhit,[];
			}
		}

		@{[do {
			my $index=0;
			my $base={index=>0, item=>undef};

			my $sub=plex [$sub], $base;
			map {
				$base->{index}=$_;
				$base->{item}=$table->[$_];
				my $s=$sub->render;
				$s;
			} 0..$table->@*-2;
		}]}

		\$entry=\$table->[\@\$table-1];
		\$cache->{\$input}=\$entry;
	} ';

	my $top_level=plex [$template],{table=>$table, cache=>$cache, sub=>$sub_template};
	my $s=$top_level->render;

	#my $line=1;
	#print map $_."\n", split "\n", $s;
	my $ss=eval $s;
	#print $@;
	$ss;
}

1;
__END__

