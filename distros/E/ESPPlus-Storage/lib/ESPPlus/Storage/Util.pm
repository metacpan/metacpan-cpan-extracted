package ESPPlus::Storage::Util;
use 5.006;
use strict;
use warnings;
use Carp 'confess';

use base 'Exporter';
use vars '@EXPORT';

@EXPORT = 'attribute_builder';

sub attribute_builder {
    my $method_base = shift;
    my $read_only   = shift;

    my $package = caller;
    my $method_full = $package . '::' . $method_base;
    
    {
	no warnings 'redefine';
	if ( $read_only ) {
	    eval qq[
		    sub $method_full {
			\$_[0]->{'$method_base'};
		    }
		    ];
	} else {
	    eval qq[
		    sub $method_full {
			my \$self = shift;
			return \@_
			    ? (\$self->{'$method_base'} = shift)
			    : \$self->{'$method_base'};
		    }
		    ];
	}
    }
    confess( $@ ) if $@;
}

1;
