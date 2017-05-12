package List::Pairwise;
use 5.006;
use strict;
use warnings;
use Exporter;

use constant USE_LIST_UTIL_VERSION => 0;

our $VERSION = '1.03';

our %EXPORT_TAGS = ( 
	all => [ qw(
		mapp grepp firstp lastp
		map_pairwise grep_pairwise first_pairwise last_pairwise
		pair
	) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

if ($] < 5.019006) {
	# avoid "Name "main::a" used only once" warnings for $a and $b
	*import = sub {
		no strict qw(refs);
		no warnings qw(once void);
		*{caller().'::a'};
		*{caller().'::b'};
		goto &Exporter::import
	}
} else {
	import Exporter 'import'
}

sub _carp_odd {
	[caller(1)]->[3] =~ /([a-z]+)$/;
	warnings::warnif(misc => "Odd number of elements in $1")
}

sub _mapp (&@) {
	my $code = shift;
	_carp_odd if @_&1;

	# Localise $a and $b
	# (borrowed from List-MoreUtils)
	my ($caller_a, $caller_b) = do {
		my $pkg = caller();
		no strict 'refs';
		\*{$pkg.'::a'}, \*{$pkg.'::b'};
	};
	local(*$caller_a, *$caller_b);

	no warnings;

	if (not @_&1) {
		# Even number of elements
		# normal case
		if (wantarray) {
			# list context
			map {(*$caller_a, *$caller_b) = \splice(@_, 0, 2); $code->()} (1..@_/2)
		}
		elsif (defined wantarray) {
			# scalar context
			# count number of returned elements
			my $i=0;
			# force list context with =()= for the count
			$i +=()= $code->() while (*$caller_a, *$caller_b) = \splice(@_, 0, 2);
			$i
		}
		else {
			# void context
			() = $code->() while (*$caller_a, *$caller_b) = \splice(@_, 0, 2);
		}
	}
	else {
		# Odd number of element
		# Same code but last element is an alias to undef
		if (wantarray) {
			map {(*$caller_a, *$caller_b) = $_ ? \splice(@_, 0, 2) : \(shift, undef); $code->()} (1..@_/2, 0)
		}
		elsif (defined wantarray) {
			my $i=0;
			$i +=()= $code->() while (*$caller_a, *$caller_b) = @_==1 ? \(shift, undef) : \splice(@_, 0, 2);
			$i
		}
		else {
			() = $code->() while (*$caller_a, *$caller_b) = @_==1 ? \(shift, undef) : \splice(@_, 0, 2);
		}
	}
}

sub _grepp (&@) {
	my $code = shift;
	_carp_odd if @_&1;

	# Localise $a and $b
	# (borrowed from List-MoreUtils)
	my ($caller_a, $caller_b) = do {
		my $pkg = caller();
		no strict 'refs';
		\*{$pkg.'::a'}, \*{$pkg.'::b'};
	};
	local(*$caller_a, *$caller_b);

	no warnings;

	if (not @_&1) {
		# Even number of elements
		# normal case
		if (wantarray) {
			# list context
			map {(*$caller_a, *$caller_b) = \splice(@_, 0, 2); $code->() ? ($$$caller_a, $$$caller_b) : ()} (1..@_/2)
		}
		elsif (defined wantarray) {
			# scalar context
			# count number of valid *pairs* (not elements)
			my $i=0;
			$code->() && ++$i while (*$caller_a, *$caller_b) = \splice(@_, 0, 2);
			$i
			# Returning the number of valid pairs is more intuitive than
			# the number of elements.
			# We have this equality:
			# (grepp BLOCK LIST) == 1/2 * scalar(my @a = (grepp BLOCK LIST))
		}
		else {
			# void context
			# same as mapp, but evaluates $code in scalar context
			scalar $code->() while (*$caller_a, *$caller_b) = \splice(@_, 0, 2);
		}
	}
	else {
		# Odd number of element
		# Same code but last element is an alias to undef
		if (wantarray) {
			map {(*$caller_a, *$caller_b) = $_ ? \splice(@_, 0, 2) : \(shift, undef); $code->() ? ($$$caller_a, $$$caller_b) : ()} (1..@_/2, 0)
		}
		elsif (defined wantarray) {
			my $i=0;
			$code->() && ++$i while (*$caller_a, *$caller_b) = @_==1 ? \(shift, undef) : \splice(@_, 0, 2);
			$i
		}
		else {
			scalar $code->() while (*$caller_a, *$caller_b) = @_==1 ? \(shift, undef) : \splice(@_, 0, 2);
		}
	}
}

sub _firstp (&@) {
	my $code = shift;
	_carp_odd if @_&1;

	# Localise $a and $b
	# (borrowed from List-MoreUtils)
	my ($caller_a, $caller_b) = do {
		my $pkg = caller();
		no strict 'refs';
		\*{$pkg.'::a'}, \*{$pkg.'::b'};
	};
	local(*$caller_a, *$caller_b);

	no warnings;

	if (not @_&1) {
		# Even number of elements
		# normal case
		$code->() && return wantarray ? ($$$caller_a, $$$caller_b) : 1 while (*$caller_a, *$caller_b) = \splice(@_, 0, 2);
		()
	}
	else {
		# Odd number of element
		# Same code but last element is an alias to undef
		$code->() && return wantarray ? ($$$caller_a, $$$caller_b) : 1 while (*$caller_a, *$caller_b) = @_==1 ? \(shift, undef) : (\splice(@_, 0, 2));
		()
	}
}

sub lastp (&@) {
	my $code = shift;
	_carp_odd if @_&1;

	# Localise $a and $b
	# (borrowed from List-MoreUtils)
	my ($caller_a, $caller_b) = do {
		my $pkg = caller();
		no strict 'refs';
		\*{$pkg.'::a'}, \*{$pkg.'::b'};
	};
	local(*$caller_a, *$caller_b);

	no warnings;

	if (not @_&1) {
		# Even number of elements
		# normal case
		$code->() && return wantarray ? ($$$caller_a, $$$caller_b) : 1 while (*$caller_a, *$caller_b) = @_ ? \splice(@_, -2) : ();
		()
	}
	else {
		# Odd number of element
		# Same code but last element is an alias to undef
		$code->() && return wantarray ? ($$$caller_a, $$$caller_b) : 1 while (*$caller_a, *$caller_b) = @_>=2 ? (\splice(@_, 0, 2)) : @_==1 ? \(shift, undef) : ();
		()
	}
}

sub _pair {
	_carp_odd if @_&1;
	return @_
		? map [ @_[$_*2, $_*2 + 1] ] => 0 .. ($#_>>1)
		: wantarray ? () : 0
	;
}

sub _LU_pair {
	goto \&List::Util::pairs if wantarray;
	_carp_odd if @_&1;
	1+@_>>1
}

#sub truep   (&@) { scalar &grepp(@_)      }
#sub falsep  (&@) { (@_-1)/2 - &grepp(@_)  }
#sub allp    (&@) { (@_-1)/2 == &grepp(@_) }
#sub notallp (&@) { (@_-1)/2 > &grepp(@_)  }
#sub nonep   (&@) { !&firstp(@_)           }
#sub anyp    (&@) { scalar &firstp(@_)     }

# install functions

sub mapp (&@);
sub grepp (&@);
sub firstp (&@);
sub pair;

if (USE_LIST_UTIL_VERSION && eval {require List::Util;1} && $List::Util::VERSION >= USE_LIST_UTIL_VERSION) {
	# print "LIST UTIL\n\n";
	*mapp = \&List::Util::pairmap;
	*grepp = \&List::Util::pairgrep;
	*firstp = \&List::Util::pairfirst;
	*pair = \&_LU_pair;
} else {
	# print "INTERNAL\n\n";
	*mapp = \&_mapp;
	*grepp = \&_grepp;
	*firstp = \&_firstp;
	*pair = \&_pair;
}

# install aliases

sub map_pairwise (&@);
sub grep_pairwise (&@);
sub first_pairwise (&@);
sub last_pairwise (&@);
#sub true_pairwise (&@);
#sub false_pairwise (&@);
#sub all_pairwise (&@);
#sub notall_pairwise (&@);
#sub none_pairwise (&@);
#sub any_pairwise (&@);

*map_pairwise = \&mapp;
*grep_pairwise = \&grepp;
*first_pairwise = \&firstp;
*last_pairwise = \&lastp;
#*true_pairwise = \&truep;
#*false_pairwise = \&falsep;
#*all_pairwise = \&allp;
#*notall_pairwise = \&notallp;
#*none_pairwise = \&nonep;
#*any_pairwise = \&anyp;

1
