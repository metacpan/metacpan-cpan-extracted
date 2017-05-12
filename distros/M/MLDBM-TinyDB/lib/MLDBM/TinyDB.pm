package MLDBM::TinyDB;

use vars qw/$VERSION @ISA @EXPORT_OK/;
$VERSION = '0.20';# 

use strict;
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(db add_common);
use MLDBM qw/SDBM_File Storable/;## change SDBM_File for any other DBM file if you want 
use MLDBM::Serializer::Storable; ## p2x
use Storable qw/dclone/;
use SDBM_File; ## p2x
use Fcntl;
use Carp::Heavy; ## p2x
use Tie::IxHash;
use MLDBM::TinyDB;

our %db;

sub db {
	my $table = shift;
	if (ref($db{$table}) =~ /MLDBM::TinyDB/) {
		return $db{$table};
	} elsif (ref($db{$table}) =~ /ARRAY/) {
		return init(__PACKAGE__,$table, @{ $db{$table} });
	} else {
		return undef;#
	} 
}

##	UNDOCUMENTED
sub free_dbh {
	my $self = shift;
	return (%db = ());
}

sub init {
	my $this = shift;
	my $class = ref($this)||$this;
	my ($table, $tree, $branch, $mode, $perms) = @_;
	my $self = {};
	$self->{TABLE} = $table;

	$mode ||= (O_CREAT|O_RDWR);
	$perms  ||= 0666;
	tie %{$self->{TIEHASH}}, 'MLDBM', $table, $mode, $perms or die $!;
	
	my $proc;## to be processed unless $branch
	unless ($proc = ${$self->{TIEHASH}}{tree}) {
	##	save
		${$self->{TIEHASH}}{tree} = $tree;
		$proc = $tree;
	}	

	return $proc if !defined($proc);	
	
	my %tables;

	unless ($branch) {
		my $clone = dclone($proc);
		set_tables_data(\%tables, $proc);
		my @extfiles = grep !/^$table$/, keys %tables;
		if ( @extfiles>0 ) {
		##	so there is at least one table related
			foreach (@extfiles) {
				$db{$_} = [$clone, $tables{$_} ];
			}
		}
		@{$self->{FLDS}} = @{ $tables{$table}{FLDS} };
		@{$self->{DOWN}} = @{ $tables{$table}{DOWN} };
		$self->{UP} = $tables{$table}{UP};
	} else {
		@{$self->{FLDS}} = @{ $branch->{FLDS} };
		@{$self->{DOWN}} = @{ $branch->{DOWN} };
		$self->{UP} = $branch->{UP};
	}
##	IMPLICITLY ADD FIELD IF EXISTS SUPERIOR TABLE - FIELD IS NOT CONTAINED IN $tree!!!
##	IT'S FOR delete
	unshift(@{$self->{FLDS}}, "nodes") 
		if defined $self->{UP};	
		
	my @numkeys = map {$_, undef}  sort {$a<=>$b} grep /^\d+$/ && $_, keys %{$self->{TIEHASH}};
	$self->{NUMKEYS} = Tie::IxHash->new( @numkeys );

	bless $self, $class;
	$db{$table} = $self;
	return $self;
}

sub set_tables_data {
	my ($tables, $reft, $up) = @_;
	my $first = shift @$reft;	 
	$tables->{$first}{UP} = $up;
	@{$tables->{$first}{DOWN}} = ();
	foreach (@$reft) {
		if (ref($_) =~ /ARRAY/) {
			push(@{$tables->{$first}{FLDS}}, $_->[0]);
		##	array of ref
			push(@{$tables->{$first}{DOWN}}, $tables->{$first}{FLDS}[-1]);
			set_tables_data($tables, $_, $first);
		} else {
			push(@{$tables->{$first}{FLDS}}, $_);
		}
	}
}

## ultility
sub add_common {
	my ($reft, $common) = @_;
	my $first = shift @$reft;
	unshift(@$reft, $first, @$common);
	foreach (@$reft) {
		if (ref($_) =~ /ARRAY/) {
			add_common($_, $common);		
		}
	}
}

sub lsearch {
	my ($self, $criteria, $limit) = @_;
	use locale;## just that line added to sort method
	my @found = ();
	my @spec = $self->{NUMKEYS}->Keys;
	my $str = join "|", @{$self->{FLDS}};
	$str = '$criteria =~ s/(' .  $str . ')/\'$hash{\' . $1 . \'}\'/ge';
	unless (eval $str) {
		warn "eval failed: $@" if $@;
	}
	my %hash = (); ##-
	for(my $i=0; $i<=$#spec; $i++) {
		@hash{ @{$self->{FLDS}} } = @{ ${$self->{TIEHASH}}{$spec[$i]} };
		if (eval $criteria) {
			push(@found, $i);
			last if $limit && ($limit == @found);
		} elsif ($@) {
			warn "eval failed:$@";
		}
	}
	return @found;
}

sub search {
	my ($self, $criteria, $limit) = @_;
	my @found = ();
	my @spec = $self->{NUMKEYS}->Keys;
	my $str = join "|", @{$self->{FLDS}};
	$str = '$criteria =~ s/(' .  $str . ')/\'$hash{\' . $1 . \'}\'/ge';
	unless (eval $str) {
		warn "eval failed: $@" if $@;
	}
	my %hash = (); ##-
	for(my $i=0; $i<=$#spec; $i++) {
		@hash{ @{$self->{FLDS}} } = @{ ${$self->{TIEHASH}}{$spec[$i]} };
		if (eval $criteria) {
			push(@found, $i);
			last if $limit && ($limit == @found);
		} elsif ($@) {
			warn "eval failed:$@";
		}
	}
	return @found;
}

sub lsort {
	my ($self, $sform) = @_;
	use locale;## just that line added to sort method
	my $str;
	my @spec = $self->{NUMKEYS}->Keys;
	my $not = join "|", @{$self->{DOWN}}, 'nodes';
	my @allowed = grep !/^$not$/, @{$self->{FLDS}};
	my $allowed = join "|", @allowed;
	my @reg = ();
	my @sorted = ();
	my %conv = ('ab'=>0, 'ba'=>1, 'cmp'=>0, '<=>'=>1);
	$str = 'while ($sform =~ s/^(\w*)\s*(\(?)\s*([ab])\s*\(\s*('.$allowed.')\s*\)\s*(\)?)\s*(cmp|\<\=\>)\s*(\1)\s*(\2)\s*([ab])\s*\(\s*(\4)\s*\)\s*(\5)\s*(?:\|\|)?//){ push(@reg,[$1, $3, $4, $6, $9, ($conv{qq/$3$9/}<<1)|$conv{$6}]) if ($3 ne $9) && !$conv{$4}++; }';
	eval $str;
	die "eval failed: $@" if $@;
	if (@reg == 0) { 
		return @sorted;
	}
	my @keys = map { $_->[2] } @reg;
	my @indices = k2i($self->{FLDS},[@keys]);
	my @ex = grep $_->[0], @reg;
	for(my $i=0; $i<=$#spec; $i++) {
		 push(@sorted, [$i, @{ ${$self->{TIEHASH}}{$spec[$i]} }[@indices]]);
	}
	if (@ex == 0 && @keys == 1) {
		@sorted = sort {$a->[1] cmp $b->[1]} @sorted if $reg[0]->[5] == 0; 
		@sorted = sort {$b->[1] cmp $a->[1]} @sorted if $reg[0]->[5] == 2; 
		@sorted = sort {$a->[1] <=> $b->[1]} @sorted if $reg[0]->[5] == 1; 
		@sorted = sort {$b->[1] <=> $a->[1]} @sorted if $reg[0]->[5] == 3; 
	} elsif (@ex == 0 && @keys == 2) {
		@sorted = sort {$a->[1] cmp $b->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 0;
		@sorted = sort {$a->[1] cmp $b->[1]||
				$b->[2] cmp $a->[2]} @sorted
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 2;
		@sorted = sort {$a->[1] cmp $b->[1]||
				$a->[2] <=> $b->[2]} @sorted
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 1;
		@sorted = sort {$a->[1] cmp $b->[1]||
				$b->[2] <=> $a->[2]} @sorted
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 3;
	
		@sorted = sort {$b->[1] cmp $a->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 0;
		@sorted = sort {$b->[1] cmp $a->[1]||
				$b->[2] cmp $a->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 2;
		@sorted = sort {$b->[1] cmp $a->[1]||
				$a->[2] <=> $b->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 1;
		@sorted = sort {$b->[1] cmp $a->[1]||
				$b->[2] <=> $a->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 3;

		@sorted = sort {$a->[1] <=> $b->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 0;
		@sorted = sort {$a->[1] <=> $b->[1]||
				$b->[2] cmp $a->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 2;
		@sorted = sort {$a->[1] <=> $b->[1]||
				$a->[2] <=> $b->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 1;
		@sorted = sort {$a->[1] <=> $b->[1]||
				$b->[2] <=> $a->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 3;

		@sorted = sort {$b->[1] <=> $a->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 0;
		@sorted = sort {$b->[1] <=> $a->[1]||
				$b->[2] cmp $a->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 2;
		@sorted = sort {$b->[1] <=> $a->[1]||
				$a->[2] <=> $b->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 1;
		@sorted = sort {$b->[1] <=> $a->[1]||
				$b->[2] <=> $a->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 3;
	} else {
		undef $sform;
		my $i = 1;
		foreach my $e (@reg) {
			$sform .= $e->[0] if $e->[0];
			$sform .= '$'.$e->[1].'->['.$i.']'.$e->[3];
			$sform .= " $e->[0] " if $e->[0];
			$sform .= '$'.$e->[4].'->['.$i.']';
			$sform .= '||';	
			$i++;
		}
		chop $sform;
		chop $sform;
		#print "\$sform:$sform";
		@sorted = sort { eval $sform }  @sorted;
	}
	return @sorted;
}

sub sort {
	my ($self, $sform) = @_;
	my $str;
	my @spec = $self->{NUMKEYS}->Keys;
	my $not = join "|", @{$self->{DOWN}}, 'nodes';
	my @allowed = grep !/^$not$/, @{$self->{FLDS}};
	my $allowed = join "|", @allowed;
	my @reg = ();
	my @sorted = ();
	my %conv = ('ab'=>0, 'ba'=>1, 'cmp'=>0, '<=>'=>1);
	$str = 'while ($sform =~ s/^(\w*)\s*(\(?)\s*([ab])\s*\(\s*('.$allowed.')\s*\)\s*(\)?)\s*(cmp|\<\=\>)\s*(\1)\s*(\2)\s*([ab])\s*\(\s*(\4)\s*\)\s*(\5)\s*(?:\|\|)?//){ push(@reg,[$1, $3, $4, $6, $9, ($conv{qq/$3$9/}<<1)|$conv{$6}]) if ($3 ne $9) && !$conv{$4}++; }';
	eval $str;
	die "eval failed: $@" if $@;
	if (@reg == 0) { 
		return @sorted;
	}
	my @keys = map { $_->[2] } @reg;
	my @indices = k2i($self->{FLDS},[@keys]);
	my @ex = grep $_->[0], @reg;
	for(my $i=0; $i<=$#spec; $i++) {
		 push(@sorted, [$i, @{ ${$self->{TIEHASH}}{$spec[$i]} }[@indices]]);
	}
	if (@ex == 0 && @keys == 1) {
		@sorted = sort {$a->[1] cmp $b->[1]} @sorted if $reg[0]->[5] == 0; 
		@sorted = sort {$b->[1] cmp $a->[1]} @sorted if $reg[0]->[5] == 2; 
		@sorted = sort {$a->[1] <=> $b->[1]} @sorted if $reg[0]->[5] == 1; 
		@sorted = sort {$b->[1] <=> $a->[1]} @sorted if $reg[0]->[5] == 3; 
	} elsif (@ex == 0 && @keys == 2) {
		@sorted = sort {$a->[1] cmp $b->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 0;
		@sorted = sort {$a->[1] cmp $b->[1]||
				$b->[2] cmp $a->[2]} @sorted
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 2;
		@sorted = sort {$a->[1] cmp $b->[1]||
				$a->[2] <=> $b->[2]} @sorted
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 1;
		@sorted = sort {$a->[1] cmp $b->[1]||
				$b->[2] <=> $a->[2]} @sorted
			if $reg[0]->[5] == 0 && $reg[1]->[5] == 3;
	
		@sorted = sort {$b->[1] cmp $a->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 0;
		@sorted = sort {$b->[1] cmp $a->[1]||
				$b->[2] cmp $a->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 2;
		@sorted = sort {$b->[1] cmp $a->[1]||
				$a->[2] <=> $b->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 1;
		@sorted = sort {$b->[1] cmp $a->[1]||
				$b->[2] <=> $a->[2]} @sorted 
			if $reg[0]->[5] == 2 && $reg[1]->[5] == 3;

		@sorted = sort {$a->[1] <=> $b->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 0;
		@sorted = sort {$a->[1] <=> $b->[1]||
				$b->[2] cmp $a->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 2;
		@sorted = sort {$a->[1] <=> $b->[1]||
				$a->[2] <=> $b->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 1;
		@sorted = sort {$a->[1] <=> $b->[1]||
				$b->[2] <=> $a->[2]} @sorted 
			if $reg[0]->[5] == 1 && $reg[1]->[5] == 3;

		@sorted = sort {$b->[1] <=> $a->[1]||
				$a->[2] cmp $b->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 0;
		@sorted = sort {$b->[1] <=> $a->[1]||
				$b->[2] cmp $a->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 2;
		@sorted = sort {$b->[1] <=> $a->[1]||
				$a->[2] <=> $b->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 1;
		@sorted = sort {$b->[1] <=> $a->[1]||
				$b->[2] <=> $a->[2]} @sorted 
			if $reg[0]->[5] == 3 && $reg[1]->[5] == 3;
	} else {
		undef $sform;
		my $i = 1;
		foreach my $e (@reg) {
			$sform .= $e->[0] if $e->[0];
			$sform .= '$'.$e->[1].'->['.$i.']'.$e->[3];
			$sform .= " $e->[0] " if $e->[0];
			$sform .= '$'.$e->[4].'->['.$i.']';
			$sform .= '||';	
			$i++;
		}
		chop $sform;
		chop $sform;
		#print "\$sform:$sform";
		@sorted = sort { eval $sform }  @sorted;
	}
	return @sorted;
}

sub _get_recs {
## 	ext:true - get external values, false - don't
	my ($self, $ext, @list) = @_;
	my @indices = (); 
	my $ret = [];

	@list = grep /^\-?\d+$/, @list;
	
	@list = $self->{NUMKEYS}->Indices($self->{NUMKEYS}->Keys) if @list == 0;

	my @spec = $self->{NUMKEYS}->Keys( @list );

	if ( defined($self->{UP}) ) {
		if (ref($db{$self->{UP}}) =~ /ARRAY/) {
			init(__PACKAGE__, $self->{UP}, @{ $db{$self->{UP}} });
		}
		die "hash element \"$self->{UP}\" exists while superior table object doesn't" 
			unless defined $db{$self->{UP}};
	}

	my @down = @{$self->{DOWN}};#0.17
	for(my $i=0; $i<=$#spec; $i++) {
		if (defined $spec[$i]) {
			my $href = {}; ##-
			@{$href}{ @{$self->{FLDS}} } = @{ ${$self->{TIEHASH}}{$spec[$i]} };	
			##+ 0.09
			if ( exists($href->{nodes}) ) {## && defined($href->{nodes})
				if (defined $db{$self->{UP}}) {
					my @temp = unpack "n*", $href->{nodes};
					shift @temp;
					$href->{nodes} = [@temp];
					@{$href->{nodes}} = grep defined($_), $db{$self->{UP}}->{NUMKEYS}->Indices( @{$href->{nodes}} )
						if @temp>0;
				} else {
					die "hash element \"nodes\" exists and isn't empty while superior table object doesn't exist";
				}
			} ##+ 0.09
			foreach my $e (@down) {#0.17
				my @temp = unpack "n*", $href->{$e};
				shift @temp;
				$href->{$e} = [@temp];
				if (@temp) {
					if (ref($db{$e}) =~ /ARRAY/) {
						init(__PACKAGE__, $e, @{ $db{$e} });
					}
					@{$href->{$e}} = grep defined($_), $db{$e}->{NUMKEYS}->Indices( @{$href->{$e}} );
					if ($ext && @{$href->{$e}}>0) {
						 @{$href->{$e}} = _get_recs($db{$e}, $ext, @{$href->{$e}}); 
					}
				}	
			}
			push(@$ret, $href);
			push(@indices, $list[$i]);
		}
	}
	return wantarray?($ret, @indices):$ret;
}

##	obj->get_recs(-1); obj->get_recs; obj->get_recs(0,3,5);
##	get extended records data 
sub get_ext_recs {
	my ($self, @list) = @_;
	return _get_recs($self,1,@list);
}

##	obj->get_recs(-1); obj->get_recs; obj->get_recs(0,3,5);
##	get records data
sub get_recs {
	my ($self, @list) = @_;
	return _get_recs($self,0,@list);
}

##	obj->set_recs(to); append
##	obj->set_recs(to, -1); obj->set_recs(to, 1,3,5); override
##	if LIST supplied it sets every existed element for list
##	if LIST not supplied it sets every element supplied
sub set_recs {
	my ($self, $to, @list) = @_;
##	you should check wheter it is non-duplicate elements list 
	my @set = ();

	@list = grep /^\-?\d+$/,@list;#+0.12
	if (@list == 0) {
		my $next = $self->{NUMKEYS}->Length;
		@list = ($next..$next+$#{$to});
	}
	my @spec = $self->{NUMKEYS}->Keys( @list );
	
	if ( defined($self->{UP}) ) {
		if (ref($db{$self->{UP}}) =~ /ARRAY/) {
			init(__PACKAGE__, $self->{UP}, @{ $db{$self->{UP}} });
		}
		die "hash element \"$self->{UP}\" exists while superior table object doesn't" 
			unless defined $db{$self->{UP}};
	}

	my %ext_set;
	my %ext_del;
	my ($created, $updated) = k2i($self->{FLDS},[qw/created updated/]);

	for(my $i=0; $i<@spec; $i++) {
		my $aref = [];
		if (defined $to->[$i]) {
			if (!defined $spec[$i]) {
				my ($last) = $self->{NUMKEYS}->Keys(-1);
				$last = 0 unless defined $last;
				my $last_index = $self->{NUMKEYS}->Length-1;
				$spec[$i] = $last+($list[$i]<1?0:$list[$i])-$last_index;
				##print "\$last+(\$list[\$i]<1?0:\$list[\$i])-\$last_index\n";
				##print $last,"\+",($list[$i]<1?0:$list[$i]),"\-",$last_index,"\n";
				foreach ($last+1..$spec[$i]-1) {
				## AUTOVIVIFICATION IF GAP!!!
					${ $self->{TIEHASH} }{$_} = [];
					$self->{NUMKEYS}->Push($_=>undef);
				}
				$self->{NUMKEYS}->Push($spec[$i]=>undef);
				$to->[$i]->{created} = time if defined $created;
				$to->[$i]->{updated} = undef if defined $updated;#?
				## $to->[$i]->{nodes} = undef if exists $to->[$i]->{nodes};#?
				#print "not defined created:$to->[$i]->{created} updated:$to->[$i]->{updated}\n"
			} else {
				if (@{$self->{DOWN}}) {
				##	CLEAN external "nodes"
					my $href = {};##+
					@{$href}{ @{$self->{FLDS}} } = @{ ${$self->{TIEHASH}}{$spec[$i]} };##+
					foreach my $e (@{$self->{DOWN}}) {
						if ( defined($href->{$e}) ) {
							my @temp = unpack "n*", $href->{$e};
							shift @temp;
							foreach my $el ( @temp ) {
								push(@{ $ext_del{$e} }, [ $el, $spec[$i] ]);
							}
						}
					}
				}
				$to->[$i]->{updated} = time if defined $updated;
				#print "defined created:$to->[$i]->{created} updated:$to->[$i]->{updated}\n"
			}
			if (@{$self->{DOWN}}) {
				foreach my $e (@{$self->{DOWN}}) {
					my @temp;
					if (!defined($to->[$i]->{$e})) {
					##	implictly accept 'undef'				

					##	array of indices of external record
					} elsif (ref($to->[$i]->{$e}) =~ /ARRAY/) {
						shift @{ $to->[$i]->{$e} }
							if ref($to->[$i]->{$e}->[0]) =~ /ARRAY/;

						if (ref($db{$e}) =~ /ARRAY/) {
							init(__PACKAGE__, $e, @{ $db{$e} });
						}	

						if (defined $db{$e}) {
						##	get numkeys of supplied indices
							@temp = $db{$e}->{NUMKEYS}->Keys( @{$to->[$i]->{$e}} );#0.12
						} else {
							die "hash element \"$e\" exists and isn't empty while superior table object doesn't exist";
						}

						foreach my $el ( @temp ) {
						##	external record numkey, record numkey
							push(@{ $ext_set{$e} }, [ $el, $spec[$i] ]);
						}
					} else {
						die "hash $e element should be array ref!!!";
					}
					#push(@temp, 0) if @temp==0;
					@temp = grep $_, @temp;
					unshift(@temp,0);
					$to->[$i]->{$e} = pack "n*", @temp;
				}
			}
			##+ 0.09
			if (defined $self->{UP}) {
				my @temp;
				if (!defined($to->[$i]->{nodes})) {
				## implicitly accept 'undef' 
				} elsif ( ref($to->[$i]->{nodes}) =~ /ARRAY/ ) { 
					@temp = $db{$self->{UP}}->{NUMKEYS}->Keys( @{$to->[$i]->{nodes}} );
				} else {
					die "hash \"nodes\" element should be array ref!!!";
				}
				@temp = grep $_, @temp;
				unshift(@temp,0);
				$to->[$i]->{nodes} = pack "n*", @temp;
			} ##+ 0.09
			@$aref = @{$to->[$i]}{ @{$self->{FLDS}} };
		} else {
			last;
		}
		${ $self->{TIEHASH} }{$spec[$i]} = $aref; 
		push(@set, $list[$i]);
	}

	ch_nodes(\%ext_del, 1); ## DELETE
	ch_nodes(\%ext_set);    ## SET
##	RETURNS ARRAY OF ROW ELEMENT INDICES
	return @set;
}

##	DELETE OR SET
sub ch_nodes {
	my ($href, $what) = @_;
	ch_field($href, $what, "nodes");
}

##	DELETE OR SET
sub ch_field {
	my $href = shift;
	my $what = shift; ## false - SET, true - DELETE
	my $field = shift;
	my @files = keys %$href;
	if (@files>0) {
		foreach my $f (@files) {
			if (ref($db{$f}) =~ /ARRAY/) {
				init(__PACKAGE__, $f, @{ $db{$f} });
			}
			my $idx = k2i($db{$f}->{FLDS},[$field]); 
			foreach my $el ( @{$href->{$f}} ) {
				my $temp = ${ $db{$f}->{TIEHASH} }{$el->[0]};
				my @temp = unpack "n*", $temp->[$idx];
				@temp = grep $_!=$el->[1], @temp 
						if $what;	## DELETE
				push(@temp, $el->[1])
						unless $what;	## SET
				@temp = grep /^\d+/ && $_, @temp;##+0.11
				unshift(@temp, 0);
				$temp->[$idx] = pack "n*", @temp;
				${ $db{$f}->{TIEHASH} }{$el->[0]} = $temp;
			}
		}
	}
}

sub delete {
	my ($self, @list) = @_;
	my  @indices; ##+$aref

	@list = grep /^\-?\d+$/, @list;#+0.12

	@list = $self->{NUMKEYS}->Indices($self->{NUMKEYS}->Keys) if @list == 0;

	my @spec = $self->{NUMKEYS}->Keys( @list );

	my %up_del;
	my %down_del;

	for(my $i=0; $i<@spec; $i++) {
		if (defined $spec[$i]) {
			my $href = {}; ##-
			@{$href}{ @{$self->{FLDS}} } = @{ ${$self->{TIEHASH}}{$spec[$i]} };	
			if (defined $self->{UP}) {
				if ( exists($href->{nodes}) ) {#&& defined($href->{nodes})
				##	fetch numkeys from pack'ed read structure
					my @temp = unpack "n*", $href->{nodes};
					shift @temp;
					$href->{nodes} = [@temp];
					foreach my $el ( @{$href->{nodes}} ) {
				##	external records indentification keys, key to delete 
						push(@{ $up_del{$self->{UP}} }, [ $el, $spec[$i] ]);
					}
				}
			}
			if (@{$self->{DOWN}}) {
			##	CLEAN "nodes"
				foreach my $e (@{$self->{DOWN}}) {
					my @temp = ();
					if (defined $db{$e}) {
						@temp = unpack "n*", $href->{$e};
						shift @temp;
					} else {
						die "hash element \"$e\" exists while superior table object doesn't";
					}
					foreach my $el ( @temp ) {
						push(@{ $down_del{$e} }, [ $el, $spec[$i] ]); 
					}
				}
			}
			delete ${$self->{TIEHASH}}{$spec[$i]}; ## DELETE	
			$self->{NUMKEYS}->Delete( $spec[$i] ); ## 0.12 
			push(@indices, $list[$i]);
		}
	}
	ch_field(\%up_del, 1, $self->{TABLE}); ## DELETE 
	ch_nodes(\%down_del, 1); ## DELETE
	return @indices;
}

sub key2idx {
	my ($self, @args) = @_;
	return k2i($self->{NUMKEYS},\@args);
}

sub k2i {
	my ($keys, $args) = @_;
	my %conv = ();
	@conv{ @$keys } = (0..$#{$keys});
	return wantarray ? @conv{@$args} : $conv{$args->[0]};	
}

sub idx2key {
	my ($self, @indices) = @_;
	return grep /^\d+/ && $_, @{$self->{NUMKEYS}}[@indices];
}

sub table {
	my $self = shift;
	return $self->{TABLE};
}

sub flds {
	my $self = shift;
	return @{$self->{FLDS}};
}

sub up {
	my $self = shift;
	return $self->{UP};
}

sub down {
	my $self = shift;
	return @{$self->{DOWN}};
}

sub numkeys {
	my $self = shift;
	return $self->{NUMKEYS}->Keys;
}

sub last {
	my $self = shift;
	return $self->{NUMKEYS}->Length-1;
}

sub name {
	my $self = shift;
	if (@_) {
		$self->{NAME} = shift;
	}
	return $self->{NAME};
}

1;
__END__
=head1 NAME

MLDBM::TinyDB - create and mainpulate structured MLDBM tied hash references 

=head1 SYNOPSIS

	use MLDBM::TinyDB;
	## or
	use MLDBM::TinyDB qw/db add_common/;

	@common = qw/created updated/; ## optional

	$tree = [TABLE, FIELDS_LIST,
			[TABLE1, FIELDS_LIST1,
				[TABLE2, FIELDS_LIST2],
				...
			],
			...
		]; 

	MLDBM::TinyDB::add_common($tree,\@common); ## optional
	## or
	add_common($tree,\@common);

	%obj = ();
	$obj{TABLE} = MLDBM::TinyDB->init(TABLE, $tree);
	## or
	$obj{TABLE} = 
		MLDBM::TinyDB->init(TABLE, $tree, undef, $mode, $perms);
	## or 
	$obj{TABLE} = MLDBM::TinyDB->init(TABLE); ## NEVER FIRST TIME

	@down = $obj{TABLE}->down; ## TABLE1

	$obj{TABLE1} = MLDBM::TinyDB::db(TABLE1);
	## or
	$obj{TABLE1} = db(TABLE1);

	$table = $obj{TABLE}->table; ## TABLE

	@down = $obj{TABLE1}->down; ## TABLE2

	$obj{TABLE2} = MLDBM::TinyDB::db(TABLE2);
	## or
	$obj{TABLE2} = db(TABLE2);

	@set_recs_indices = 
		$obj{TABLEn}->set_recs(ARRAYREF_TO_HASHREF,[LIST]);

	$up = $obj{TABLE2}->up; ## TABLE1
	
	$aref_of_href = $obj{TABLE}->get_ext_recs; 
	## or
	($aref_of_href, @get_recs_indices) = $obj{TABLE}->get_ext_recs;

	$aref_of_href1 = $obj{TABLE}->get_recs; ## NOT THE SAME AS ABOVE
	## or
	($aref_of_href1, @get_recs_indices1) =  $obj{TABLE}->get_recs;

	@indices_of_recs_found = $obj{TABLE}->search($criteria, [$limit]);
	@indices_of_recs_found = $obj{TABLE}->lsearch($criteria, [$limit]);
	
	@indices_and_sort_field_values = $obj{TABLE}->sort($sort_formula_string);
	@indices_and_sort_field_values = $obj{TABLE}->lsort($sort_formula_string);
	
	$obj{TABLEn}->delete([LIST]); 
	$obj{TABLEn}->last;


=head1 DESCRIPTION

MLDBM::TinyDB is MLDBM based module. It allows to create/manipulate data structure 
of related tables = more-then-flatfile-database. The main idea is to create array 
reference which will reflect database structure. The first scalar value in the array 
is table name, next ones are fields names - if the array contains array reference 
it denotes interior (related) table where first scalar value is that table name 
(in that case the record will contain the field of the same name as interior table) 
and the next ones are fields names and so on... If database structure isn't written on disk 
then that structure is fetched from the array reference and written to disk. 
Object is always built from disk structures. To define record you may use any field 
name except "nodes" which is restricted field name and shouldn't be specified 
explicitly. C<created> and C<updated> fields are handled 
internally - if they are specified then: 1)on I<append record> operation C<time> 
function value is set to C<created> record field 2)on I<write to existing record> 
operation C<time> function value is set to C<updated> record field. Data I<get from> 
and I<set to> records are in form of I<array reference to hash references> where hash 
keys are fields names. The fields names that are interior tables names contain array 
references. That array store indices (similar to array indices) identifying particular 
records. Those fields MUST be set to proper values before write records C<set_recs> operation. 

=head2 UTILITY

=over 4

=item MLDBM::TinyDB::add_common

=item add_common

Utility sub - allow to arbitrary fields names set (except C<nodes>) i.e. 
C<created, updated, blahblah> to be added just after first element (name of table) to all 
(sub-)arrays pointed by C<$tree> data structure. It's not exported by deafult. 

=back
 
=head2 CONSTRUCTOR(S) 

=over 4

=item init

This method creates database structure according to passed array reference C<$tree> 
(which defines hierarchical structure of related tables) if the structure doesn't exist 
on disk - in that case you may change default mode C<O_CREAT|O_RDWR> or perms C<0666> 
if you specify them. Afterwards C<init> read these structures and builds object from them.

=item MLDBM::TinyDB::db

=item db

Returns object reference of interior TABLE. If underlying database structure
doesn't exist on disk then it's created. Returns C<undef> on failure. Must be invoked 
after C<init>. It's not exported by default. 

=back

=head2 METHODS

The following methods may be applied to object references returned by both C<init> and
C<MLDBM::TinyDB::db> CONSTRUCTORS

=item flds

Returns array of all fields names of record on which operate object.

=item last

Returns last record's index or -1 if there are no records.

=item down

Returns fields names that are also interior tables names or empty array otherwise.

=item up

Returns field name of superior table or C<undef> otherwise.

=item set_recs

Takes as first argument array reference to hash references and writes it as data records 
according to indices list if supplied or at the end of table otherwise. 
Each array element represents record data. If LIST is supplied then method 
writes at most as much array elements as LIST counts. If LIST is NOT supplied 
then it writes all array elements. May cause autovivification effect 
- it will add records if there is a gap between last record's index (see:C<last>) 
and supplied index of unexisted record. i.e. while last index (1) if supplied (3) 
then it will add (2, 3) records. Returns array of written records indices.

=item get_ext_recs

Gets record's data specified by indices list (or all records if list is not supplied)
and returns array reference to hash references plus got records indices list. If record 
field name is the same as interior table name then corresponding hash value will contain 
array reference - first element of the array will be other array reference to hash 
refrences (if one of that hash keys contain name of interior table then that hash 
value will be appropriate array reference and so on) and the rest of elements will be 
list of corresponding external records indices.

=item get_recs

Gets data records specified by indices list or all records if list is not supplied and 
returns array reference to hash references plus got records indices list. If any 
record field name is the same as interior table then corresponding hash value will contain 
array reference - the array will contain external records indices.

=item search

=item lsearch

Searches records in table in order to find ones that match supplied criteria,
returns array of indices of those records. The criteria is a string which may contain something like i.e. 
C<< field_name  > 1000 && (field_name1 =~ /PATTERN/ || field_name2 lt $string) >> or i.e.
C<defined(field_name)> meaning you can construct criteria string similar to
perl expressions. IMPORTANT: The use of fields names that are interior tables names  
(SEE: C<down> method) will take no effect. Second (optional) argument is $limit, 
which defines what number of record indices matching the criteria should be at most returned.
C<lsearch> differs from C<search> method in one way - it uses C<locale> pragma -
it uses system locale settings in string comparison/matching operations.

=item sort 

=item lsort

Sort the all records of table associated with object according to C<$sort_formula_string> which
must be specified. Returns array of array references, where each pointed array contains 
as first element index of record followed by sorted fields values in order they appear in 
C<$sort_formula_string>. Sort formula string is similar to perl sort function BLOCK 
i.e. C<< a(field_name) <=> b(field_name) >> - in this case C<field_name> value will be 
second element of each pointed array C<< a(field_name1) cmp b(field_name1)||length a(field_test2) <=> length b(field_test2) >>
- in this case C<field_name1> and C<field_name2> value will be second and third
element of each pointed array. If empty array is returned then something went wrong.
C<lsort> differs from C<sort> method in one way - it uses C<locale> pragma - it sorts
lexically in system locale sorting order.

=item delete

Deletes records of specified indices or all records if no arguments. If for record to
be deleted exists field C<nodes> and it contains array of numeric values then those values 
are indices identifying particular external table records and data in these external records 
pointing to that deleting record will be deleted too. 
 
=item table 

Returns TABLE associated with object.

=item name

Sets/gets name of object.

=head1 EXAMPLE1

	## DEFINE
	perl -e"use MLDBM::TinyDB;$tree=[qw/f a b/];$it=MLDBM::TinyDB->init(q/f/,$tree);"
	## ADD
	perl -e"use MLDBM::TinyDB;$it=MLDBM::TinyDB->init(q/f/);$it->set_recs([{a=>11,b=>12},{a=>12,b=>13}]);"
	## GET
	perl -e"use MLDBM::TinyDB;$it=MLDBM::TinyDB->init(q/f/);$g=$it->get_recs;for(@$g){print qq/@{[%$_]}\n/}"

=head1 EXAMPLE2

	use MLDBM::TinyDB qw/db add_common/;

	@common = qw/created updated/; ## option

	$tree = [qw/table1 field1/,
			[qw/table2 field2/,[qw/table3 field31 field32/]]
		]; 

	add_common($tree,\@common); ## option

	%obj = ();
	$obj{table1} = MLDBM::TinyDB->init("table1", $tree);
	$obj{table2} = db("table2");
	$obj{table3} = db("table3");

	@x = qw/green blue yellow black red/;
	@y = (1, undef, 3, 5, 2);
	for(my $i = 0; $i<@x; $i++) {
		my $href;
		$href->{field31} = $x[$i];
		$href->{field32} = $y[$i];
		push(@$aref, $href);
	}

	## NOTE: order of follownig statements is crucial to set all information 
	## needed about relations between these records

	@set = $obj{table3}->set_recs($aref); ## append three records 
	print "@set\n";

	@indices_and_sort_field_values = $obj{table3}->sort('a(field31) cmp b(field31)');
	foreach (@indices_and_sort_field_values) {
		print "@$_\n";
	}

	@found = $obj{table3}->search('length(field31)>4||!defined(field32)', 3);
	print "@found\n";# 0 1 2

	$href->{table3} = [@set]; ## store indices of those records
	$href->{field2} = "22222";
	@set = $obj{table2}->set_recs([$href]);

	$href->{table2} = [@set];
	$href->{field1} = "11111";
	$obj{table1}->set_recs([$href]);

	$aref1 = $obj{table1}->get_ext_recs; ## get everything 
	
	use Data::Dumper;
	print Dumper($aref1);
	
	$obj{table3}->delete(0, -1); ## first and last record

	$aref2 = $obj{table2}->get_ext_recs; ##
	print Dumper($aref2);

	@flds = $obj{table3}->flds;
	print "@flds\n";

=head1 CAVEATS

Slow, slow, slow.

=head1 AUTHOR

Darek Adamkiewicz E<lt>d.adamkiewicz@i7.com.plE<gt>

=head1 COPYRIGHT

Copyright (c) Darek Adamkiewicz. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please feel free to e-mail me if it concerns this module.

=head1 VERSION

Version 0.20  27 NOV 2002

=head1 SEE ALSO

MLDBM, SDBM_File, Storable

=cut
