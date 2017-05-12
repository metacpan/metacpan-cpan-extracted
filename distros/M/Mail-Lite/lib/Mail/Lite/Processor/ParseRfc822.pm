package Mail::Lite::Processor::ParseRfc822;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;


sub process {
    my $args_ref = shift;
    my ( $processor, $messages ) = @$args_ref{ qw/processor input/ };

    ### $messages

    ref $messages eq 'ARRAY'
	or $messages = [ $messages ];

    my @output;

    foreach my $message (@$messages) {
	### $message
	my @lines = split /\n\s*/, $message->body;

	my $parsed = {};

	foreach (@lines) {
	    next unless length;

	    my ($key, $val) = /\s*(.+?):\s+(.+)/;

	    next unless defined $key;

	    $key = lc $key;
	    $key =~ tr/-/_/;

	    unless (exists($parsed->{$key})) {
		$parsed->{$key} = $val;
	    } else {
		if (ref $parsed->{$key} eq 'ARRAY') {
		    push @{$parsed->{$key}}, $val;
		} else {
		    $parsed->{$key} = [ $parsed->{$key}, $val ];
		}
	    }
	}

	push @output, $parsed;
    }

    ${ $args_ref->{ output } } = \@output;


    return OK;
}



1;
