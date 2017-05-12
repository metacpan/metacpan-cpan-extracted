#!/usr/bin/perl -w

package Lingua::Phonology::Segment::Tier;

use strict;
use warnings;
use warnings::register;
use Lingua::Phonology::Common;

our $VERSION = 0.11;

sub err ($) { _err($_[0]) if warnings::enabled() };

sub new {
	my $proto = shift;

    # When called as an object method, return a regular segment
    return $proto->[0]->new(@_) if ref $proto;

	return err "No segments given for pseudo-segment" if not @_;
    for (@_) {
        _is_seg $_ or return;
    }
	bless \@_, $proto;
}


# all_values() always returns the value C<< ( PSEUDO => 1 ) >>. This is mostly
# just useful to help Lingua::Phonology::Rules, so that it doesn't think that
# pseudo-segments are blank.

sub all_values {
	return ( PSEUDO => 1 );
}

# This method ensures that we pass method calls to all encapsulated segs, but
# only return if all segs returned the same thing
our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
    my $method = $AUTOLOAD;
	$method =~ s/.*:://;

	# Pass everything through to the segments
	my ($return, $disagree);
	for (@$self) {
        no warnings 'uninitialized';

        # Return value from current member of $self
		my $this;

		# The following blocks ensure that we provide the proper context to the
		# method calls

        # Array context
		if (wantarray) {
			$this = [ $_->$method(@_) ];
            next if $disagree;

			if (not $return) {
				$return = $this;
			}
            # Check that we're the same for every element of the returned list
			else {
				if (@$this != @$return) {
					$disagree = 1;
				}

				else {
					for (0 .. $#{$this}) {
						if ($this->[$_] ne $return->[$_]) {
							$disagree = 1;
							last;
						}
					}
				}
			}
		}

        # Scalar context
		elsif (defined wantarray) {
			$this = $_->$method(@_);
            next if $disagree;

			if (not defined $return) {
				$return = $this;
			}
			else {
				$disagree = 1 if $return ne $this;
			}
		}

        # Void context
		else {
			$_->$method(@_);
		}

	}

	return if $disagree;
	return @$return if wantarray;
	return $return;
} 

# Don't pass on DESTROY
sub DESTROY {}

1;
