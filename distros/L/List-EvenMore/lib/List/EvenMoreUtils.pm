
package List::EvenMoreUtils;

use strict;
use warnings;
require Exporter;
use Carp qw(confess);

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(
	do_sublist
	keys_to_regex
	list_to_text
	partial_ordering_differs
	list_difference_position
	initial_sublist_match
	longer_list
	repeatable_list_shuffler
);

our $VERSION = 0.11;

sub do_sublist(&&@)
{
	my $selector = shift;
	my $actor = shift;

	my @order;
	my %buckets;

	for (@_) {
		my $bucket = &$selector;
		if ($buckets{$bucket}) {
			push(@{$buckets{$bucket}}, $_);
		} else {
			push(@order, $bucket);
			$buckets{$bucket} = [ $_ ];
		}
	}
	my @ret;
	for my $sublist (@buckets{@order}) {
		push(@ret, $actor->(@$sublist));
	}
	return @ret;
}

sub keys_to_regex
{
	my (%hash) = @_;
	my $s = join('|', map { "\Q$_\E" } sort keys %hash);
	return qr/(?:$s)/;
}

sub list_to_text
{
	my ($last, @rest) = reverse @_;
	return $last unless @rest;
	return join(", ", reverse @rest) . " and " . $last;
}

#
# name = \@list
#
sub partial_ordering_differs
{
	my (%lists) = @_;

	my %positions;
	for my $list (keys %lists) {
		my $c = 1;
		$positions{$list} = { map { $_ => $c++ } @{$lists{$list}} };
	}
		
	my %done;
	for my $one (keys %lists) {
		for my $two (keys %lists) {
			next if $done{$one}{$two}++;
			next if $done{$two}{$one}++;

			my @common = grep { exists $positions{$two}{$_} } @{$lists{$one}};

			next unless @common;

			my @onekeys = sort { $positions{$one}{$a} <=> $positions{$one}{$b} } @common;
			my @twokeys = sort { $positions{$two}{$a} <=> $positions{$two}{$b} } @common;

			my $after;
			while (@onekeys) {
				next if $onekeys[0] eq $twokeys[0];
				if ($after) {
					return "Item '$onekeys[0]' in $one needs to come after '$after' since it does so in $two";
				} else {
					return "Item '$onekeys[0]' in $one needs to come before '$onekeys[1]' since it does so in $two";
				}
			} continue {
				$after = shift @onekeys;
				shift @twokeys;
			}
		}
	}
	return undef;
}

#
# A return value of 1 means the first elements are
# different.
#

sub list_difference_position(\@\@)
{
	my ($a, $b, $start) = @_;
	$start ||= 0;
	for my $i ($start..$#$a) {
		if (defined($a->[$i])) {
			return $i+1 unless defined $b->[$i];
			return $i+1 unless $a->[$i] eq $b->[$i];
		} else {
			return $i+1 if defined $b->[$i];
		}
	}
	if ($#$a < $#$b) {
		return $#$a+2;
	} elsif ($#$b < $#$a) {
		return $#$b+2;
	} else {
		return undef;
	}
}

sub initial_sublist_match(\@\@)
{
	my ($a, $b) = @_;
	for my $i (0..$#$a) {
		return 1 if $i > $#$b;
		if (defined($a->[$i])) {
			return 0 unless defined $b->[$i];
			return 0 unless $a->[$i] eq $b->[$i];
		} else {
			return 0 if defined $b->[$i];
		}
	}
	return 1;
}

sub longer_list(\@\@)
{
	my ($a, $b) = @_;
	return $a if $#$a > $#$b;
	return $b;
}


#
# Determanistic pseudo-random list shuffler
#
sub repeatable_list_shuffler
{
	my ($seed) = @_;
	my $previous = 0;
	require String::CRC;
	return sub {
		my (@list) = @_;
		my %ret;
		for my $l (@list) {
			$previous++;
			my $pos = String::CRC::crc($previous.($l || '').$seed, 32);
			redo if exists $ret{$pos};
			$ret{$pos} = $l;
		}
		return map { $ret{$_} } sort { $a <=> $b } keys %ret;
	};
}


1;

__END__

=head1 NAME

 List::EvenMoreUtils - Array manipulation functions

=head1 SYNOPSIS

 use List::EvenMoreUtils qw(partial_ordering_differs);
 use List::EvenMoreUtils qw(list_difference_position);
 use List::EvenMoreUtils qw(keys_to_regex);
 use List::EvenMoreUtils qw(list_to_text);
 use List::EvenMoreUtils qw(initial_sublist_match);
 use List::EvenMoreUtils qw(longer_list);
 use List::EvenMoreUtils qw(repeatable_list_shuffler);

 $difference = partial_ordering_differs( 
	name_of_list1 => \@list1, 
	name_of_list2 => \@list2,
 )
 

 $diffpos = list_difference_position(@list1, @list2);

 $regex = keys_to_regex(%hash);

 printf "We gave apples to %s.\n", list_to_text(@people);

 print "unequal\n" if initial_sublist_match(@list1, @list2);

 $longer = longer_list(@list1, @list2);

=head1 FUNCTIONS

=head2 C<do_sublist(&selector,&actor,@list)>

Use &selector on each item of @list to group the items into
sublists.  Call &actor on each sublist.

 @urls = (qw(
	http://foo.com/ 
	http://foo.com/xy/
	http://bar.com/xy/
 ));
 do_sublist(
	sub {
		m{^http://([^/]+)};
		return $1;
	},
	sub {
		my $u = $_[0];
		$u =~ m{^(http://([^/]+))};
		print "paths for $2 = ".join(" ", map { substr($_, length($1)) } @_)."\n";
	},
	@urls
 )

=head2 C<keys_to_regex(%hash)>

Returns a regex that matches the keys of the hash.
This isn't really a list utility, so I hope you'll forgive me.

 %x = (
	Hope => 1,
	April => 7,
	Jane => 8,
 );
 my $re = keys_to_regex(%hash);
 print "match\n" if $name =~ /^$re$/;

=head2 C<list_to_text>

This add commas and C<and> to lists to make them parse well in English.

 print list_to_text("Jane", "Ellen");

Gives you:

 Jane and Ellen

=head3 partial_ordering_differs

Given multiple lists, make sure that to the extent they have the same
elements, the elements are in the same order in all the lists.

If all the lists have the same ordering of their elements, then the
return value is C<undef>.   If there is a difference in ordering, then
the return value is an English description of the difference.  For example:

 Item 'Fred' in list1 needs to come after 'Jane' since it does so in list2.

=head3 list_difference_position

Compare two lists.   Report the 1-based index position where the lists are 
first different from each other.  

Returns C<undef> if the lists are identical.

If one list is the start of the other list, returns the size of the smaller
of the two lists + 1.

=head3 initial_sublist_match

Compare two lists.  If the two lists have the same number of
elements, compare them.  Returns 1 if they are the same.  If one of the
lists is shorter than the other, then compare the shorter list to a
sublist of the longer list that matches the shorter's length.  If they're
the same, returns 1.  Otherwise returns 0.

=head3 longer_list

Compare two lists.  Return a reference to the longer list.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

