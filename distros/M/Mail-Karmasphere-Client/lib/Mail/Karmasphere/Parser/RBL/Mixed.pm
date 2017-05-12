package Mail::Karmasphere::Parser::RBL::Mixed;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::RBL::Base';
use Mail::Karmasphere::Parser::Record;

sub _streams { qw(ip4 domain) }

sub my_format { "rbl.mixed" } # if the source table's "magic" field is rbl.mixed, this module deals with it.

sub tweaks {
    my $self = shift;
    my $identity = shift;
    # if it's a domain identity, we output to the domain stream.
    # if it's an ip4 identity, we output to the ip4 stream.
    my $type = Mail::Karmasphere::Parser::Record::guess_identity_type($identity);
    my $stream;
    if ($type eq "ip4") {
	$stream = 0;
	# in an rbl.mixed input file, we'll find things like "4.3.2.1".
	# we want to return "1.2.3.4".
	$identity = join ".", reverse split /\./, $identity;
    }
    elsif ($type eq "domain") {
	$stream = 1;
    }
    else {
	$self->warning("guessed type=$type for identity=$identity, skipping.");
	return;
    }

    return ($type, $stream, $identity);
}


1;
