package Mail::Lite::Mbox;

use strict;
use warnings;
use Carp;

use Mail::Lite::Message;
use Mail::Lite::Processor;

# *** PUBLIC ***

# STATIC (%param)
# param: filename, processor, do_parse, handler, debug
sub process_mbox {
    my (%param) = @_;

    $param{debug} ||= 0;

    my $filename = $param{filename};
    open my $fh, '<', $filename or confess "Can't open $filename!\n";

    process_each_message( fh => $fh, %param );

    close $fh;
}

# STATIC (%param)
# param: fh, callback, do_parse?
sub process_each_message {
    my (%param) = @_;

    my $out = '';
    my $fh = $param{fh};

    local $/ = "\n\nFrom";

    $_ = <$fh>;
    $out = substr( $_, 0, -7 );

    while ($_ = <$fh>) {
	_do_process_message( \$out, %param );
	$out = "From ".substr($_, 0, -7);
    }
    _do_process_message( \$out, %param );
}

sub _do_process_message {
    my ($txt_ref, %param) = @_;

    if ($param{processor}) {
	$param{processor}->process(
	    message => ${$txt_ref},
	);
    }
    else {
	if ($param{do_parse}) {
	    my $message = new Mail::Lite::Message( ${$txt_ref} );
	    $param{handler}->( $message );
	}
	else {
	    $param{handler}->( ${$txt_ref} );
	}
    }
}

1;
__END__

=head1 NAME

Mail::Lite::Mbox::Processor - Framework for automated mail processing

=head1 SYNOPSIS

  use Mail::Lite::Mbox::Processor;

  my $matcher1 = new Mail::Lite::Message::Matcher('rules.yaml');
  my $handler_name = $matcher1->process_message( $message );

  my $processor = new MyMessageProcessor;
  my $matcher2 = new Mail::Lite::Message::Matcher('rules.yaml', $processor);
  my $result = $matcher2->process_message( $message );

=head1 DESCRIPTION

Mail::Lite::Message::Matcher is a framework for automated mail processing.
For example you have a mail server and you have a need to process
some types of incoming mail messages automatically.
For example, you can extract automated notifications, invoices,
alerts etc. from your mail flow and perform some tasks
based on content of those messages.

To use this module you have to provide the following:

=over 3

=item configuration file with list of rules

=item Perl code for each rule

=back

=head2 METHODS

An object of this class represents specific message processor,
that can process mail messages one-by-one.

=over 3

=item new( CONFIG_FILE, [PROCESSOR] )

This constructor creates new Mail::Lite::Message::Matcher object.
CONFIG_FILE - string with path to configuration file.
PROCESSOR - instance of processor object.

=item process_message( MESSAGE )

MESSAGE is either plain text rfc822 mesage or already initialized
Mail::Lite::Message::Parser object representing message.
This method finds rule that matches the message and
tries to process message (if message processor is specified).

I.e. if PROCESSOR object is specified (if it was passed to the constructor),
messages will be automatically processed by calling appropriate methods
of this processor object.
If PROCESSOR is not specified, just appropriate rule will be returned
as a result. In the latter case you have to process message yourself
using handler name and message type id from the rule.

=back

=head1 DEPENDENCIES

Depends on:

 <Mail::Lite::Message::Parser> (used as a backend for parsing messages)

 <YAML::Tiny> (used to parser configuraion file)

=head1 AUTHOR

Walery Studennikov, E<lt>despair [at] cpan [dot] orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Walery Studennikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
