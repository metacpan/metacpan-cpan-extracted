package Devel::Monitor::Common;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw();  #Export by default

our %EXPORT_TAGS = ( #Export as groups
    'all' => [ 
        qw(F_ID
	       F_VAR
	       F_IS_CODE
	       F_UNMONITORED
	       
	       printMsg
        )
    ]
);

Exporter::export_ok_tags(    #Export by request (into @EXPORT_OK)
    'all');
    
#Fields
use constant F_ID => '_id';
use constant F_VAR => '_var';
use constant F_IS_CODE => '_isCode';
use constant F_UNMONITORED => '_unmonitored';

sub printMsg {
    my $msg = shift;
    print STDERR $msg;
}

1;