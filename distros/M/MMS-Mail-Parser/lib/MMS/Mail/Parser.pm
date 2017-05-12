package MMS::Mail::Parser;

use warnings;
use strict;

use base "Class::Accessor";

use IO::Wrap;
use IO::File;
use MIME::Parser;

use MMS::Mail::Message;
use MMS::Mail::Parser;
use MMS::Mail::Provider;

#  These are eval'd so the user doesn't have to install all Providers
eval {
  require MMS::Mail::Provider::UKVodafone;
  require MMS::Mail::Provider::UK02;
  require MMS::Mail::Provider::UKOrange;
  require MMS::Mail::Provider::UKTMobile;
  require MMS::Mail::Provider::UKVirgin;
  require MMS::Mail::Provider::UK3;
};

=head1 NAME

MMS::Mail::Parser - A class for parsing MMS (or picture) messages via email.

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

This class takes an MMS message and parses it into two 'standard' formats (an MMS::Mail::Message and MMS::Mail::Message::Parsed) for further use.  It is intended to make parsing MMS messages network/provider agnostic such that a 'standard' object results from parsing, independant of the network/provider it was sent through.

=head2 Code usage example 

This example demonstrates the use of the two stage parse.  The first pass provides an MMS::Mail::Message instance that is then passed through to the C<provider_parse> method that attempts to determine the Network provider the message was sent through and extracts the relevant information and parses it into an MMS::Mail::Message::Parsed instance.

    use MMS::Mail::Parser;
    my $mms = MMS::Mail::Parser->new();
    my $message = $mms->parse(\*STDIN);
    if (defined($message)) {
      my $parsed = $mms->provider_parse;
      print $parsed->header_subject."\n";
    }

=head2 Examples of input

MMS::Mail::Parser has the same input methods as L<MIME::Parser>.

    # Parse from a filehandle:
    $entity = $parser->parse(\*STDIN);

    # Parse an in-memory MIME message: 
    $entity = $parser->parse_data($message);

    # Parse a file based MIME message:
    $entity = $parser->parse_open("/some/file.msg");

    # Parse already-split input (as "deliver" would give it to you):
    $entity = $parser->parse_two("msg.head", "msg.body");

=head2 Examples of parser modification

MMS::Mail::Parser uses MIME::Parser as it's parsing engine.  The MMS::Mail::Parser class creates it's own MIME::Parser instance if one is not passed in via the C<new> or C<mime_parser> methods.  There are a number of reasons for providing your own parser, such as forcing all attachment storage to be done in memory than on disk (providing a speed increase to your application at the cost of memory usage).

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    my $mmsparser = new MMS::Mail::Parser;
    $mmsparser->mime_parser($parser);
    my $message = $mmsparser->parse(\*STDIN);
    if (defined($message)) {
      my $parsed = $mms->provider_parse;
    }

=head2 Examples of error handling

The parser contains an error stack and will ultimately return an undef value from any of the main parse methods if an error occurs.  The last error message can be retreived by calling C<last_error> method.

    my $message = $mmsparser->parse(\*STDIN);
    unless (defined($message)) {
      print STDERR $mmsparser->last_error."\n";
      exit(0);
    }

=head2 Miscellaneous methods

There are a small set of miscellaneous methods available.  The C<output_dir> method is provided so that a new MIME::Parser instance does not have to be created to supply a separate storage directory for parsed attachments (however any attachments created as part of the process are removed when the message is destroyed so the lack of specification of a storage location is not a requirement for small scale message parsing ).

    # Provide debug ouput to STDERR
    $mmsparser->debug(1);

    # Set an output directory for MIME::Parser 
    $mmsparser->output_dir('/tmp');

    # Get/set an array reference to the error stack
    my $errors = $mmsparser->errors;

    # Get/set the MIME::Parser instance used by MMS::Parser
    $mmsparser->mime_parser($parser);

    # Set the characters to be stripped from the returned 
    # MMS::Mail::Message and MMS::Mail::Message::Parsed instances
    $mmsparser->strip_characters("\r\n");

    # Set the regular expression map for accessors
    # Removes trailing EOL chars from subject and body accessors
    my $map = { header_subject => 's/\n$//g',
                header_datetime => 's/\n$//g'
              };
    $mmsparser->cleanse_map($map);

=head2 Tutorial

A tutorial can be accessed at http://www.monkeyhelper.com/2006/02/roll_your_own_flickrpoddr_or_v.html

=head1 METHODS

The following are the top-level methods of MMS::Mail::Parser class.

=head2 Constructor

=over

=item C<new()>

Return a new MMS::Mail::Parser instance. Valid attributes are:

=over

=item C<mime_parser> MIME::Parser

Passed as a hash reference, C<parser> specifies the MIME::Parser instance to use instead of MMS::Mail::Parser creating it's own.

=item C<debug> INTEGER

Passed as a hash reference, C<debug> determines whether debuging information is outputted to standard error (defaults to 0 - no debug output).

=item C<strip_characters> STRING

Passed as a hash reference, C<strip_characters> defines the characters to strip from the MMS::Mail::Message (and MMS::Mail::Message::Parsed) class C<header_*> and C<body_text> properties.

=item C<cleanse_map> HASH REF

Passed as a hash reference, C<cleanse_map> defines regexes (or function references) to apply to instance properties from the MMS::Mail::Message (and MMS::Mail::Message::Parsed) classes.

=back

=back

=head2 Regular Methods

=over

=item C<parse> INSTREAM

Instance method - Returns an MMS::Mail::Message instance by parsing the input stream INSTREAM

=item C<parse_data> DATA 

Instance method - Returns an MMS::Mail::Message instance by parsing the in memory string DATA

=item C<parse_open> EXPR

Instance method - Returns an MMS::Mail::Message instance by parsing the file specified in EXPR

=item C<parse_two> HEADFILE, BODYFILE

Instance method - Returns an MMS::Mail::Message instance by parsing the header and body file specified in HEADFILE and BODYFILE filenames

=item C<provider_parse> MMS::MailMessage

Instance method - Returns an MMS::Mail::Message::Parsed instance by attempting to discover the network provider the message was sent through and parsing with the appropriate MMS::Mail::Provider.  If an MMS::Mail::Message instance is supplied as an argument then the C<provider_parse> method will parse the supplied MMS::Mail::Message instance.  If a provider has been set via the provider method then that parser will be used by the C<provider_parse> method instead of attempting to discover the network provider from the MMS::Mail::Message attributes.

=item C<output_dir> DIRECTORY

Instance method - Returns the C<output_dir> parameter used with the MIME::Parser instance when invoked with no argument supplied.  When an argument is supplied it sets the C<output_dir> property used by the MIME::Parser to the value of the argument supplied.

=item C<mime_parser> MIME::Parser

Instance method - Returns the MIME::Parser instance used by MMS::Mail::Parser (if created) when invoked with no argument supplied.  When an argument is supplied it sets the MIME::Parser instance used by the MMS::Mail::Parser instance to parse messages.

=item C<provider> MMS::Mail::Provider

Instance method - Returns an instance for the currently set provider property when invoked with no argument supplied.  When an argument is supplied it sets the provider to the supplied instance.

=item C<strip_characters> STRING

Instance method - Returns the characters to be stripped from the returned MMS::Mail::Message and MMS::Mail::Message::Parsed instances.  When an argument is supplied it sets the strip characters to the supplied string.

=item C<cleanse_map> HASHREF

Instance method - This method allows a regular expression or subroutine reference to be applied when an accessor sets a value, allowing message values to be cleansed or modified. These accessors are C<header_from>, C<header_to>, C<body_text>, C<header_datetime> and C<header_subject>.

The method expects a hash reference with key values as one of the above public accessor method names and values as a scalar in the form of a regular expression or as a subroutine reference.

=item C<errors>

Instance method - Returns the error stack used by the MMS::Mail::Parser instance as an array reference.

=item C<last_error>

Instance method - Returns the last error from the stack.

=item C<debug> INTEGER

Instance method - Returns a number indicating whether STDERR debugging output is active (1) or not (0).  When an argument is supplied it sets the debug property to that value.

=back

=head1 AUTHOR

Rob Lee, C<< <robl at robl.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mms-mail-parser@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Parser>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 NOTES

Please read the Perl artistic license ('perldoc perlartistic') :

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
    WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES
    OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 ACKNOWLEDGEMENTS

As per usual this module is sprinkled with a little Deb magic.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rob Lee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MMS::Mail::Message>, L<MMS::Mail::Message::Parsed>, L<MMS::Mail::Provider>

=cut

my @Accessors=( "message",
                "mime_parser",
                "debug",
		"errors",
		"output_dir",
		"provider",
		"strip_characters",
		"cleanse_map"
                );

# Class data retrieval
sub _Accessors {
  return \@Accessors;
}

__PACKAGE__->mk_accessors(@{__PACKAGE__->_Accessors});


sub new {

  my $type = shift;
  my $self = SUPER::new $type( {@_} );

  # Set defaults
  unless (defined $self->get('debug')) {
    $self->set('debug',0);
  }
  unless (defined $self->get('mime_parser')) {
    $self->set('mime_parser',undef);
  }
  unless (defined $self->get('strip_characters')) {
    $self->set('strip_characters',undef);
  }
  unless (defined $self->get('cleanse_map')) {
    $self->set('cleanse_map',undef);
  }
  unless (defined $self->get('message')) {
    $self->set('message',undef);
  }
  $self->set('errors',[]);

  return $self;

}

sub parse {

  my $self = shift;
  my $in = wraphandle(shift);

  print STDERR "Starting to parse\n" if ($self->debug);
  return $self->_parse($in);
}

sub parse_data {

  my $self = shift;
  my $in = shift;

  print STDERR "Starting to parse string\n" if ($self->debug);
  return $self->_parse($in);
}

sub parse_open {
    my $self = shift;
    my $opendata = shift;

    my $in = IO::File->new($opendata) || $self->_add_error("Could not open file - $opendata");
    return $self->_parse($in);
}

sub parse_two {
    my $self = shift;
    my $headfile = shift;
    my $bodyfile = shift;

    my @lines;
    foreach ($headfile, $bodyfile) {
        open IN, "<$_" || $self->_add_error("Could not open file - $_");
        push @lines, <IN>;
        close IN;
    }
    return $self->parse_data(\@lines);
}

sub _parse {

  my $self = shift;
  my $in = shift;

  # Set up a default parser
  unless (defined $self->mime_parser) {
    my $parser = new MIME::Parser;
    $parser->ignore_errors(1);
    $self->mime_parser($parser);
  }

  if (defined $self->output_dir) {
    $self->mime_parser->output_dir($self->output_dir);
  }

  unless (defined $self->mime_parser) {
    $self->_add_error("Failed to create parser");
    return undef;
  }

  print STDERR "Created MIME::Parser\n" if ($self->debug);

  my $message = new MMS::Mail::Message;
  if (defined $self->strip_characters) {
    $message->strip_characters($self->strip_characters);
  }
  if (defined $self->cleanse_map) {
    $message->cleanse_map($self->cleanse_map);
  }
  $self->message($message);

  print STDERR "Created MMS::Mail::Message\n" if ($self->debug);

  my $parsed = eval { $self->mime_parser->parse($in) };
  if (defined $@ && $@) {
    $self->_add_error($@);
  }
  unless ($self->_recurse_message($parsed)) {
    $self->_add_error("Failed to parse message");
    return undef;
  }

  print STDERR "Parsed message\n" if ($self->debug);

  unless ($self->message->is_valid) {
    $self->_add_error("Parsed message is not valid");
    print STDERR "Parsed message is not valid\n" if ($self->debug);
    return undef;
  }

  print STDERR "Parsed message is valid\n" if ($self->debug);

  return $self->message;

}

sub _recurse_message {

  my $self = shift;
  my $mime = shift;

  unless (defined($mime)) {
    $self->_add_error("No mime message supplied");
    return 0;
  }

  print STDERR "Parsing MIME Message\n" if ($self->debug);

  my $header = $mime->head;
  unless (defined($self->message->header_from)) {
    $self->message->header_datetime($header->get('Date'));
    $self->message->header_from($header->get('From'));
    $self->message->header_to($header->get('To'));
    $self->message->header_subject($header->get('Subject'));
    my $received = $header->get('Received', 0);
    if ($received=~m/\[(.+)\.(.+)\.(.+)\.(.+)\]/) {
      $self->message->header_received_from(join(".",$1,$2,$3,$4));
    }
    print STDERR "Parsed Headers\n" if ($self->debug);
  }

  my @multiparts;

  if($mime->parts == 0) {
    $self->message->body_text($mime->bodyhandle->as_string);
    print STDERR "No parts to MIME mail - grabbing header text\n" if ($self->debug);
    $mime->bodyhandle->purge;
  }

  print STDERR "Recursing through message parts\n" if ($self->debug);
  foreach my $part ($mime->parts) {
        my $bh = $part->bodyhandle;

        print STDERR "Message contains ".$part->mime_type."\n" if ($self->debug);

        if ($part->mime_type eq 'text/plain') {
          # Compile a complete body text and add to attachments for later
          # parsing by Provider class
          if (defined($self->message->body_text())) {
            $self->message->body_text(($self->message->body_text()) . $bh->as_string);
          } else {
            $self->message->body_text($bh->as_string);
          }
          print STDERR "Adding attachment to stack\n" if ($self->debug);
          $self->message->add_attachment($part);
          next;
        }

        if ($part->mime_type =~ /multipart/) {
          print STDERR "Adding multipart to stack for later processing\n" if ($self->debug);
          push @multiparts, $part;
          next;
        } else {
          print STDERR "Adding attachment to stack\n" if ($self->debug);
          $self->message->add_attachment($part);
        }

    }
    # Loop through multiparts
    print STDERR "Preparing to loop through multipart stack\n" if ($self->debug);
    foreach my $multi (@multiparts) {
      return $self->_recurse_message($multi);
    }

    return 1;

}

sub _decipher {

  my $self = shift;

  unless (defined($self->message)) {
    $self->_add_error("No MMS mail message supplied");
    return undef;
  }

  if (defined($self->provider)) {
    my $message;
    #eval( 'require '.$self->provider.';'.'$message='.$self->provider.'::parse($self->{message})');
    $message = $self->provider->parse($self->message);

    unless (defined $message) {
      print STDERR "Failed to parse message with custom Provider Object\n" if ($self->debug);
      if (defined($@) && $@) {
        $self->_add_error($@);
      }
    }

    return $message;
  }

  # NOTE : This section could be replaced by config file and dispatcher
  # TODO : Add more error and debug output
  #
  # We eval here as it is possible the Provider classes are not installed
  #

  if ($self->message->header_from =~ /vodafone.co.uk$/) {
    print STDERR "UKVodafone message type detected\n" if ($self->debug);
    my $provider = eval { new MMS::Mail::Provider::UKVodafone };
    if (defined($@) && $@) { return undef; }
    $self->provider($provider);
    return $provider->parse($self->message);
  } elsif ($self->message->header_from =~ /mediamessaging.o2.co.uk/) {
    print STDERR "UK02 message type detected\n" if ($self->debug);
    my $provider = eval { new MMS::Mail::Provider::UK02 };
    if (defined($@) && $@) { return undef; }
    $self->provider($provider);
    return $provider->parse($self->message);
  } elsif ($self->message->header_from =~ /orangemms.net$/ || $self->message->header_from =~ /orange.net$/) {
    print STDERR "UKOrange message type detected\n" if ($self->debug);
    my $provider = eval { new MMS::Mail::Provider::UKOrange };
    if (defined($@) && $@) { return undef; }
    $self->provider($provider);
    return $provider->parse($self->message);
  } elsif ($self->message->header_from =~ /t-mobile.co.uk/) {
    print STDERR "T-Mobile message type detected\n" if ($self->debug);
    my $provider = eval { new MMS::Mail::Provider::UKTMobile };
    if (defined($@) && $@) { return undef; }
    $self->provider($provider);
    return $provider->parse($self->message);
  } elsif ($self->message->header_from =~ /virginmobilemessaging.co.uk/) {
    print STDERR "Virgin message type detected\n" if ($self->debug);
    my $provider = eval { new MMS::Mail::Provider::UKVirgin };
    if (defined($@) && $@) { return undef; }
    $self->provider($provider);
    return $provider->parse($self->message);
  } elsif ($self->message->header_from =~ /mms.three.co.uk/) {
    print STDERR "3 message type detected\n" if ($self->debug);
    my $provider = eval { new MMS::Mail::Provider::UK3 };
    if (defined($@) && $@) { return undef; }
    $self->provider($provider);
    return $provider->parse($self->message);
  } else {
    print STDERR "No message type detected using base provider\n" if ($self->debug);
    my $provider = new MMS::Mail::Provider;
    $self->provider($provider);
    return $provider->parse($self->message);
  }

}

sub provider_parse {

  my $self = shift;
  my $message = shift;
  
  if (defined($message)) {
    $self->message($message);
  }

  unless (defined($self->message)) {
    $self->_add_error("No MMS::Message available to parse");
    print STDERR "No MMS::Message available to parse\n" if ($self->debug);
    return undef;
  }

  my $mms = $self->_decipher;

  unless (defined $mms) {
    $self->_add_error("Could not parse");
    print STDERR "No MMS::Message::Parsed was returned by Provider\n" if ($self->debug);
    return undef;
  }

  print STDERR "Returning MMS::Mail::Message::Parsed\n" if ($self->debug);

  return $mms;
}

sub _add_error {

  my $self = shift;
  my $error = shift;

  unless (defined $error) {
    return 0;
  }
  push @{$self->errors}, $error;

  return 1;
}

sub last_error {

  my $self = shift;

  if (@{$self->errors} > 0) {
    return ((pop @{$self->errors})."\n");
  } else {
    return undef;
  }

}

1; # End of MMS::Mail::Parser
