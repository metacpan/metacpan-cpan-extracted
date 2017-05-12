package Devel::TrackObjects;
use strict;
use warnings;
use Scalar::Util 'weaken';
use overload;

our $VERSION = '0.600';

my @weak_objects; # List of weak objects incl file + line
my @conditions;   # which objects to track, set by import
my $is_redefined; # flag if already redefined
my $old_bless;    # bless sub before redefining

my $debug;        # enable internal debugging
my $verbose;      # detailed output instead of compact
my $with_tstamp;  # prefix output with timestamp
my $with_size;    # with size of objects
my $with_sizediff; # track changes in size
my $no_end;       # no show tracked at END


############################################################################
# redefined CORE::GLOBAL::bless if restrictions are given
# which classes should get tracked
############################################################################
sub import {
	shift;
	my @opt;
	while (@_) {
		local $_ = shift;
		if ( ! ref && m{^-(\w+)$} ) {
			push @opt,$1;
		} elsif ( $_ eq 'track_object' ) {
			# export function
			my ($pkg) = caller();
			no strict 'refs';
			*{"${pkg}::track_object"} = \&track_object;
		} elsif ( ! ref && m{^/} ) {
			# assume uncompiled regex
			my $rx = eval "qr$_";
			die $@ if $@;
			push @conditions,$rx;
		} else {
			push @conditions,$_
		}
	}
	for(@opt) {
		if ( $_ eq 'debug' ) {
			$debug = 1;
		} elsif ( $_ eq 'verbose' ) {
			$verbose = 1;
		} elsif ( $_ eq 'timestamp' ) {
			$with_tstamp = 1;
		} elsif ( $_ eq 'noend' ) {
			$no_end = 1;
		} elsif ( $_ eq 'size' ) {
			# need Devel::Size;
			$with_size = eval { require Devel::Size }
				or die "need Devel::Size installed for '-size' option"
		} elsif ( $_ eq 'sizediff' ) {
			$with_sizediff = 1;
			push @opt,'size' if ! $with_size;
		} else {
			die "unknown option $_";
		}
	}
	_redefine_bless() if @conditions;
}

############################################################################
# show everything tracked at the end
############################################################################
sub END {
	$no_end && return;
	__PACKAGE__->show_tracked() if $is_redefined;
	1;
}


############################################################################
# depending on $verbose show detailed or compact version
############################################################################
sub show_tracked {
	return $verbose
		? show_tracked_detailed(@_)
		: show_tracked_compact(@_);
}

############################################################################
# show what's still used. If I want something back give reference to
# \@weak_objects, else print myself to STDERR
############################################################################
sub show_tracked_detailed {
	shift;
	my $prefix = shift || '';
	_remove_destroyed();
	if ( defined wantarray ) {
		return \@weak_objects;
	} else {
		if ( @weak_objects ) {
			my (%s,%l);
			print STDERR "LEAK$prefix "
				. ($with_tstamp ? localtime().' ' :'' ) . " >> \n";
			for my $o ( sort { 
				overload::StrVal($a->[0]) cmp overload::StrVal($b->[0]) 
				} @weak_objects ) {
				my $line = '-- ';
				if ( $with_size ) {
					my $size = Devel::Size::size($o->[0]);
					my $total_size = Devel::Size::total_size($o->[0]);
					if ( $with_sizediff ) {
						$line .= sprintf("size=%d/%+d/%+d ",$size,
							$size-($o->[6]||0),$size-($o->[4]||0));
						$line .= sprintf("%d/%+d/%+d ", $total_size,
							$total_size-($o->[7]||0),$total_size-($o->[5]||0));
						$o->[4] = $size if ! defined $o->[4];
						$o->[5] = $total_size if ! defined $o->[5];
						$o->[6] = $size;
						$o->[7] = $total_size;
					} else {
						$line .= "size=$size total=$total_size ";
					}
				}
				$line .= sprintf "%s | %s:%s%s\n", 
					overload::StrVal($o->[0]),$o->[1],$o->[2],
					defined($o->[3]) ? " $o->[3]":'';
				print STDERR $line;
			}
			print STDERR "LEAK$prefix --\n";
		} else {
			print STDERR "LEAK$prefix "
				. ($with_tstamp ? localtime().' ' :'' ) . " >> empty --\n";
		}
	}
}

############################################################################
# show tracked objects in compact form, e.g. only counter for each class
############################################################################
sub show_tracked_compact {
	shift;
	my $prefix = shift || '';
	_remove_destroyed();
	my %count4class;
	foreach my $o (@weak_objects) {
		( $count4class{ ref($o->[0]) } ||= 0 )++;
	}
	if ( defined wantarray ) {
		return %count4class ? \%count4class : undef
	}

	my $msg = "LEAK$prefix >> ";
	if ( %count4class ) {
		foreach ( sort keys %count4class ) {
			$msg .= $_.'='.$count4class{$_}.' ';
		}
	} else {
		$msg .= "empty "
	}
	$msg .= "--\n";
	print STDERR $msg;
}

############################################################################
# bless object and track it, if it matches @condition
############################################################################
sub _bless_and_track($;$) {
	my ($pkg,$filename,$line) = caller();
	my $class = $_[1] || $pkg;

	if (ref($_[0])) {
	    # unregister
	    @weak_objects = grep { $_->[0] && $_->[0] != $_[0] } @weak_objects;
	}
	my $object = $old_bless ? $old_bless->( $_[0],$class) : CORE::bless( $_[0],$class );

	my $track = 0;
	if ( @conditions ) {
		foreach my $c ( @conditions ) {
			if ( ! ref($c) ) {
				$track = 1,last if $c eq $pkg or $c eq $class;
			} elsif ( UNIVERSAL::isa($c,'Regexp' )) {
				$track = 1,last if $pkg =~m{$c} or $class =~m{$c};
			} elsif ( UNIVERSAL::isa($c,'CODE' )) {
				$track = 1,last if $c->($pkg) or $c->($class);
			}
		}
	} else {
		$track = 1;
	}
	_register( $object,$filename,$line ) if $track;

	return $object;
}

############################################################################
sub track_object {
	my ($object,$info) = @_;
	my (undef,$filename,$line) = caller();
	_register( $object,$filename,$line,$info );
}

############################################################################
# redefine bless unless it's already redefined
############################################################################
sub _redefine_bless {
	return if $is_redefined;

	# take redefined variant if exists
	$old_bless = \&CORE::CLOBAL::bless;
	eval { $old_bless->( {}, __PACKAGE__ ) };
	$old_bless = undef if $@;

	# redefine 'bless'
	no warnings 'once';
	*CORE::GLOBAL::bless = \&_bless_and_track;
	$is_redefined = 1;
}


############################################################################
# register object, called from _bless_and_track
############################################################################
sub _register {
	my ($ref,$fname,$line,$info) = @_;
	warn "TrackObjects: register ".overload::StrVal($ref).
		" $fname:$line ".(defined($info) ? $info:'' )."\n" 
		if $debug;
	#0: referenz
	#1: file name
	#2: line in file
	#3: info message
	#4: initial size
	#5: initial total_size
	#6: last size
	#7: last total_size
	push @weak_objects, [ $ref,$fname,$line,$info ];
	weaken( $weak_objects[-1][0] );
}

############################################################################
# eliminate destroyed objects, eg where the weak ref is undef
############################################################################
sub _remove_destroyed {
	@weak_objects = grep { defined( $_->[0] ) } @weak_objects;
}


1;

__END__

=head1 NAME

Devel::TrackObjects - Track use of objects

=head1 SYNOPSIS

=over 4

=item cmdline

 perl -MDevel::TrackObjects=/^IO::/ server.pl

=item inside

 use Devel::TrackObjects qr/^IO::/;
 use Devel::TrackObjects '-verbose','track_object';
 use Devel::TrackObjects '-size','-sizediff','-timestamp';
 use IO::Socket;
 ...
 my $sock = IO::Socket::INET->new...
 ...
 my $foreign = get_some_object_from_xs();
 track_object( $foreign, "This was created in XS" );
 ...
 Devel::TrackObjects->show_tracked;

=back

=head1 DESCRIPTION

Devel::TrackObjects redefines C<bless> and thus tracks
the creation of objects by putting weak references to the
object into a list. It can be specified which classes
to track.

At the end of the program it will print out infos about the
still existing objects (probably leaking). The same info
can be print out during the run using L<show_tracked>.

=head1 IMPORTANT

The Module must be loaded as early as possible, because it
cannot redefine B<bless> in already loaded modules. See L<import>
how to load it so that it redefines B<bless>.

=head1 METHODS

The following class methods are defined.

=over 4

=item import ( COND|OPTIONS )

Called from B<use>.

COND is a list of conditions. A condition is either a regex used
as a match for a classname, a string used to match the class with
exactly this name or a reference to a subroutine, which gets called
to decide if the class should get tracked (must return TRUE).

Special is if the condition is C</regex/>. In this case it will
be compiled as a regex. This is used, because on the perl cmdline
one cannot enter compiled regex.

If the item is a string starting with "-" it will be interpreted
as an option. Valid options are:

=over 8

=item -verbose

Output from L<show_tracked> will be more verbose, e.g it will use
L<show_tracked_detailed> instead of L<show_tracked_compact>.

=item -timestamp

Includes timestamp in messages.

=item -size

Includes size of objects in detailed output.
Needs Devel::Size installed.

=item -sizediff

Includes size and difference in size to last output and first output.

=item -noend

Don't show remaining tracked objects at B<END>.

=item -debug

Will switch an internal debugging.

=back

If conditions are given it will redefine C<CORE::GLOBAL::bless>
unless it was already redefined by this module.

That means you do not pay a performance penalty if you just
include the module, only if conditions are given it will redefine
B<bless>.

=item track_object( OBJECT, [ INFO ] )

This tracks the given OBJECT manually.
This can be used in cases, where one only wants to track single objects
and not all objects for a given class or if the object was created outside
of perl and thus could not be tracked automatically.

If an additional INFO string is given it will be saved and shown from
B<show_tracked>.

=item show_tracked ( [ PREFIX ] )

If B<-verbose> was set in L<import> it will call L<show_tracked_detailed>,
otherwise L<show_tracked_compact>.

This method will be called at B<END> unless B<-noend> was specified
in L<import>.

=item show_tracked_compact ( [ PREFIX ] )

Will create a hash containing all tracked classes and
the current object count for the class.

If the caller wants to get something in return it will
return a reference to this hash, otherwise it will print
out the information in a single line to STDERR starting
with C<"LEAK$PREFIX">.

=item show_tracked_detailed ( [ PREFIX ] )

If the caller wants something in return it will give it a reference to an
array containing array-refs with C<< [ REF,FILE,LINE ] >>, where REF is the
weak reference to the object, FILE and LINE the file name and line number,
where the object was blessed.

If the calling context is void it will print these information to STDERR.
The first line will start with C<"LEAK$PREFIX"> and the last one ends with
C<"LEAK$PREFIX">.
Each line in between has the information about one object, including the
stringification of REF, FILE and LINE of creation.

If option C<-size> was given it will include the size and total_size of the
object (see L<Devel::Size> for meaning of C<size> and C<total_size>).
If option C<-sizediff> was given it will also add the difference of size
between the last call and the first call.

=back

=head1 COPYRIGHT

Steffen Ullrich Steffen_Ullrich-at-genua-dot-de
