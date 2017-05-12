# Mail::MboxParser - object-oriented access to UNIX-mailboxes
# Convertable.pm   - allow altering of mail for multiple purposes
#
# Copyright (C) 2001  Tassilo v. Parseval
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Version: $Id: Convertable.pm,v 1.6 2002/02/21 09:06:15 parkerpine Exp $

package Mail::MboxParser::Mail::Convertable;

require 5.004;

use Carp;

use strict;
use base qw(Exporter);
use vars qw($VERSION @EXPORT @ISA $AUTOLOAD); 
$VERSION 	= "0.06";
@EXPORT  	= qw();
@ISA	 	= qw(Mail::MboxParser::Base Mail::MboxParser::Mail);

sub init(@) {	
	my ($self, $ent, @args) = @_;
	$self->{TOP_ENTITY}	    = $ent;
	$self;
}

sub delete_from_header(@) { 
    my $self = shift;
    $self->{TOP_ENTITY}->head->delete($_) for @_; 
}

sub add_to_header(@) { 	
	my ($self, $what) = (shift, shift);

	if (not ref $what) {
		croak <<EOC;
Error: First argument to add_to_header must be a reference to a list with 
two elements.
EOC
	}
	my %args = @_;
	my $index;
	$args{where} = 'BEHIND' if not exists $args{where};
	if ($args{where} eq 'BEFORE') { $index = 0 }
	if ($args{where} eq 'BEHIND') { $index = -1 }
	
	$self->{TOP_ENTITY}->head->add(@{$what});
}

sub replace_in_header($$) {
	if (@_ != 3) {
		croak <<EOC;
Error: replace_in_headers() needs two arguments.
EOC
	}
	shift->{TOP_ENTITY}->head->replace(shift, shift);
}



1;

__END__

=head1 NAME

Mail::MboxParser::Mail::Convertable - convert mail for sending etc.

=head1 SYNOPSIS

    use Mail::MboxParser;

    [...]
    
    # $msg is a Mail::MboxParser::Mail-object
    my $mail = $msg->make_convertable; 

    $mail->delete_from_header('date', 'message-id');
    $mail->replace_in_header('to', 'john.doe@foobar.com');
    $mail->add_to_header( ['cc', 'john.does.brother@foobar.com'],
                          where => 'BEHIND' );
    $mail->send('sendmail');
    

=head1 DESCRIPTION

This class adds means to convert an email object into something that could be send via SMTP, NNTP or dumped to a file or filehandle. Therefore, methods are provided that change the structure of an email which includes adding and removing of header-fields, MIME-parts etc and transforming them into objects of related modules.

Currently, only basic manipulation of the header and sending using Mail::Mailer is provided. More is to come soon.

This class works non-destructive. You first create a Convertable-object and do any modifications on this while the Mail-object from which it was derived will not be touched.

=head1 METHODS

=over 4

=item delete_from_header(header-fields)

Given a list of header-field names, these fields will be removed from the header. If you want to re-send a message, you could for instance remove the cc-field cause otherwise the message would be carbon-copied to the addresses listed in the cc-field.

=item add_to_header(array-ref)

=item add_to_header(array-ref, where => 'BEFORE' | 'BEHIND')

add_to_header() takes a reference to a two-element list whose first element specifies the header-field to add or to add to while the second elements specifies the data that should be added. 'where' specifies whether to add at the beginning or at the end of the header. Defaults to 'BEHIND' if not given.

=item replace_in_header(header-field, new_data)

First element must be the header-field to be replaced while the second argument must be a string indicating what will be the new content of the header-field.

=item send(command, args)

Literally inherited from Mail::Internet. Commands can be "mail" (using the UNIX-mail program), "sendmail" (using a configured sendmail or compatible MTA like exim), "smtp" (for using Net::SMTP) and "test" which will only display what would be sent using /bin/echo. Additional arguments will be passed on to Mail::Mailer->new() which is in fact what Mail::Internet->send() uses.

For more details, see L<Mail::Mailer>

=back 

=head1 VERSION

This is version 0.55.

=head1 AUTHOR AND COPYRIGHT

Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>

Copyright (c)  2001-2005 Tassilo von Parseval.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mail::Internet>, L<Mail::Mailer>

