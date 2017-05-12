package MyStripScripts;

use strict;
use warnings FATAL => 'all';

use HTML::StripScripts::Parser();
our @ISA = qw(HTML::StripScripts::Parser);


### Override declaration handling

sub input_declaration {
    my ($self,$text) = @_;

    ## Add code to parse and check declaration ###

    $self->output($text);
}

1;
