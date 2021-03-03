# build and eval the code to efficiently merge several iterators in one iterator
package Iterator::Merger;
use strict;
use warnings;
use Carp;
use base 'Exporter';

our $VERSION = '0.62';

use constant DEBUG => 0;

our @EXPORT_OK = qw(
	imerge
	imerge_num
	imerge_raw
);

our %EXPORT_TAGS = ( 
	all => \@EXPORT_OK
);

use constant HAS_ARRAY_HEAP  => eval "use Array::Heap;1";

our $Max_generate;

unless (defined $Max_generate) {
	$Max_generate = HAS_ARRAY_HEAP ? 9 : 12; # 10 => ~30KiB to eval (doubles each increment)
}

my %Generator_cache;

*imerge_raw = eval q!
	# try to use the defined-or operator
	sub {
		my @ites = @_ or return sub {};
		if (@ites==1) {
			my $ite = shift;
			return ref($ite) eq 'GLOB' ? sub {scalar <$ite>} : sub {scalar &$ite};
		}
		for (@ites) {
			if (ref($_) eq 'GLOB') {
				my $fh = $_;
				$_ = sub {<$fh>}
			}
		}
		croak "arguments must be CODE references or filehandles" if grep {ref($_) ne 'CODE'} @ites;
		my $ite = shift(@ites);
		sub {
			&$ite // do {
				{ # block for redo
					$ite = shift(@ites) || return;
					&$ite // redo
				}
			}
		}
	}
! || eval q!
	# default to use defined() and a temporary variable
	sub {
		my @ites = @_ or return sub {};
		if (@ites==1) {
			my $ite = shift;
			return ref($ite) eq 'GLOB' ? sub {scalar <$ite>} : sub {scalar &$ite};
		}
		for (@ites) {
			if (ref($_) eq 'GLOB') {
				my $fh = $_;
				$_ = sub {<$fh>}
			}
		}
		croak "arguments must be CODE references or filehandles" if grep {ref($_) ne 'CODE'} @ites;
		my $ite = shift(@ites);
		sub {
			my $next = &$ite;
			until (defined $next) {
				$ite = shift(@ites) || return;
				$next = &$ite;
			}
			$next
		}
	}
! || die $@;

sub imerge {
	_imerge(1, \@_)
}

sub imerge_num {
	_imerge(0, \@_)
}

sub _imerge {
	my ($lex, $iterators) = @_;
	my $nb = @$iterators;
	
	croak "arguments must be CODE references or filehandles" if grep {ref($_) !~ /^CODE$|^GLOB$/} @$iterators;
	
	if ($nb==0) {
		return sub {undef};
	}
	elsif ($nb==1) {
		#return $iterators->[0];
		# ensure scalar context
		my $ite = $iterators->[0];
		return ref($ite) eq 'GLOB' ? sub {scalar <$ite>} : sub {scalar &$ite};
	}
	elsif ($nb <= $Max_generate) {
		DEBUG && warn "generate";
		if ($nb == grep {ref($_) eq 'GLOB'} @$iterators) {
			# only globs
			my $code = $Generator_cache{$nb, $lex, 1} ||= _merger_generator($nb, $lex, 1);
			return $code->(@$iterators);
		} else {
			for (@$iterators) {
				if (ref($_) eq 'GLOB') { 
					my $fh = $_;
					$_ = sub {<$fh>}
				}
			}
			my $code = $Generator_cache{$nb, $lex, 0} ||= _merger_generator($nb, $lex, 0);
			return $code->(@$iterators);
		}
	}
	else {
		# no generation, giveup on some ultimate optim: lets turn all GLOBs to CODEs...
		for (@$iterators) {
			if (ref($_) eq 'GLOB') { 
				my $fh = $_;
				$_ = sub {<$fh>}
			}
		}
		if (HAS_ARRAY_HEAP) {
			DEBUG && warn "heap";
			# general case, use a heap
			my @heap;
			# cannot take references to *_heap_lex and *_heap functions,
			# due to prototype problems...
			if ($lex) {
				for my $ite (@$iterators) {
					my $val = &$ite;
					Array::Heap::push_heap_lex(@heap, [$val, $ite]) if defined $val;
				}
				return sub {
					my $data = Array::Heap::pop_heap_lex(@heap) || return undef;
					my $min = $data->[0];
					if ( defined($data->[0] = $data->[1]->()) ) {
						Array::Heap::push_heap_lex(@heap, $data);
					}
					$min
				};
			}
			else {
				for my $ite (@$iterators) {
					my $val = &$ite;
					Array::Heap::push_heap(@heap, [$val, $ite]) if defined $val;
				}
				return sub {
					my $data = Array::Heap::pop_heap(@heap) || return undef;
					my $min = $data->[0];
					if ( defined($data->[0] = $data->[1]->()) ) {
						Array::Heap::push_heap(@heap, $data);
					}
					$min
				};
			}
		}
		else {
			DEBUG && warn "brutal";
			# no heap available, lets be dirty
			my @values = map {scalar &$_} @$iterators;
	#		warn "values: ", join(", ", map {length($_)?1:0} @values), "\n";
			if ($lex) {
				return sub {
					my $i=-1;
					my $min;
					my $min_i;
					for (@values) {
						++$i;
						if (defined and ((not defined $min) or ($_ lt $min))) {
							$min = $_;
							$min_i = $i;
						}
					}
					$values[$min_i] = $iterators->[$min_i]->() if defined $min_i;
	#				warn "value is ", (length($min)?1:0), " from $min_i";
					$min
				};
			}
			else {
				return sub {
					my $i=-1;
					my $min;
					my $min_i;
					for (@values) {
						++$i;
						if (defined and ((not defined $min) or ($_ < $min))) {
							$min = $_;
							$min_i = $i;
						}
					}
					$values[$min_i] = $iterators->[$min_i]->() if defined $min_i;
					$min
				};
			}
		}
	}
}

sub _merger_generator {
	my ($nb, $lex, $globs) = @_;
	my $str = "no warnings;sub{";
	$str .= "my(". join(',', map {"\$i$_"} 1..$nb). ")=\@_;";
	$str .= $globs ? "my\$n$_=<\$i$_>;" : "my\$n$_=&\$i$_;" for 1..$nb;
	$str .= "my\$r;sub{";
	my $cmp = $lex ? ' lt' : '<';
	$str .= _cmp($cmp, $globs, 1..$nb);
	$str .= ";\$r}}";

	# $str =~ s/;/;\n/g;
	# $str =~ s/\$/ \$/g;
	# $str =~ s/{/ {\n/g;
	# $str =~ s/}/ }\n/g;
	# warn "\n\n$str\n\n";
	
	eval($str) || die "$@ in $str"
}

# recursive comparison expression building
sub _cmp {
	my ($cmp, $globs, $i, $j) = splice(@_, 0, 4);
	return $globs ? "(\$r=\$n$i,\$n$i=<\$i$i>)" : "(\$r=\$n$i,\$n$i=&\$i$i)" unless defined $j;
	"(!defined\$n$j||defined\$n$i&&\$n$i$cmp\$n$j)?". _cmp($cmp, $globs, $i, @_). ":". _cmp($cmp, $globs, $j, @_)
}

1