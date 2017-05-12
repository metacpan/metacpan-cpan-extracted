package Mail::Lite::Processor::Filter;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;

use Clone qw/clone/;

sub process {
    my $args_ref = shift;
    
    my $message		= $args_ref->{input	};
    my $processor_args	= $args_ref->{processor	};

    #@$input == 1 or die "incorrect parameters for filter";

    #my $message = $params->[0];

    eval { $message->can('body') } or die "incorrect message";

    $message	= clone( $message );
    my $mbody	= $message->body;

    foreach my $filter ( @{ $processor_args->{filters} } ) {
	if ( ref $filter eq 'ARRAY' ) {
	    $mbody =~ s/$filter->[0]/$filter->[1]/g;
	} else {
	    $mbody =~ s/$filter//g;
	}
    }

    $message->{body} = $mbody;

    ${ $args_ref->{ output } } = $message;

    return OK;
}



1;
