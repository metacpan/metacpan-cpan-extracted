# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.
package Ham::Callsign::Display::Format;

use Ham::Callsign::Base;
use Ham::Callsign;
use Data::Dumper;
our @ISA = qw(Ham::Callsign::Base);

use strict;

sub sprint {
    my ($self, $callsigns, $format) = @_;
    $format .= "\n" if ($format);
    $format = $self->{'format'}  . "\n" if (!$format && $self->{'format'});
    if (!$format) {
	$format = "%{3.3:FromDB}: %{1:operator_class} %{-8.8:thecallsign} %{first_name} %{last_name} => %{qth}\n"
    }

    my $output = "";

    # this allows array refs to be given with multiple calls...
    foreach my $callsign (@$callsigns) {
	my $localformat = $self->{$callsign->{'FromDB'} . "format"} . "\n"
	  if (exists($self->{$callsign->{'FromDB'} . "format"}));
	$output .= format_to_string($localformat || $format, $callsign);
    }
    return $output;
}

sub display {
    my $self = shift;
    print $self->sprint(@_);
}

sub format_to_string {
    my ($format, $callsign) = @_;
    my @args;

    # changes strings like %{NUM:STRING} into sprintf statement arguments
    while ($format =~ s/\%{(?:(-?[\.\d]+):|)([^\%]+)}/"%" . ($1 || "") . "s"/e) {
	my $arg;
	if (defined($callsign->{$2})) {
	    $arg = $callsign->{$2};
	} else {
	    $arg = "";
	}
	push @args, "$arg";
    }
    return sprintf($format, @args);
}
