package Mail::Lite::Processor::SplitMsg;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;

use Clone qw/clone/;

sub process {
    my $args_ref = shift;

    my $processor_args = $args_ref->{processor};

    if ( not exists $processor_args->{separator} ) {
	die "not found separator for split";
    }

    my $message	= $args_ref->{input};

    if ( not eval { $message->can('body') } ) { 
	die "first param for split MUST be an message";
    }

    my $message_body = $message->body;
    my ( $begin_with, $end_with ) = ('', '');

    if ( my $begin = $processor_args->{begin} ) {
	$message_body	=~  s/(.*?$begin)//s;
	$begin_with	=   $1 || '';
    }

    if ( my $end = $processor_args->{end} ) {
	$message_body	=~  s/($end.*)//s;
	$end_with	=   $1 || '';
    }

    my @new_messages;

    my $separator = $processor_args->{separator};
    foreach my $message_body_part (split /$separator/, $message_body) {
	my $new_message = clone( $message );

	if ( $args_ref->{emulate} ) {
	    $new_message->{body} = 
		join q{}, $begin_with, $message_body_part, $end_with;
	}
	else {
	    $new_message->{body} = $message_body_part;
	}
	push @new_messages, $new_message;
    }

    ${ $args_ref->{ output } } = \@new_messages;

    ## $params

    return OK;
}



1;
