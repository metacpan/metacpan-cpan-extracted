package Email::ARF::Hotmail;

use 5.010;
use strict;
use warnings;
use Email::ARF::Report;
use Email::MIME;
use Regexp::Common qw/net/;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Email::ARF::Hotmail ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.12';
$VERSION = eval $VERSION;

use constant HOTMAIL_SENDER => 'staff@hotmail.com';

sub _is_hotmail_report {
  my $parsed = shift;
  foreach my $field (('X-Original-Sender', 'Sender', 'From')) {
	my $val = $parsed->header($field);
	if (defined $val) {
		$val =~ s/^\<//;
		$val =~ s/\>$//;
	}

	if (defined($val) and $val eq HOTMAIL_SENDER) {
	  return 1;
	}
  }

  return 0;
}

sub create_report {
	my $class = shift;
	my $message = shift;

	my $parsed = Email::MIME->new($message);
	
	if (_is_hotmail_report($parsed)) {
	  # Get the original email and strip off all the extra header bits
	  my $part = ($parsed->parts)[0];
	  my $orig_email = $part->body;
	  my $hotmail_headers;
	  if ($orig_email =~ /Received: /) {
		$orig_email =~ s/^(.*?)\n(Received: )/$2/s;
		$hotmail_headers = Email::Simple::Header->new($1);
	  } else {
		$hotmail_headers = Email::Simple::Header->new($orig_email);
	  }

	  my $description = "An email abuse report from hotmail";
	  my %fields;
	  $fields{"Feedback-Type"} = "abuse";
	  $fields{"User-Agent"} = "Email::ARF::Hotmail-conversion";
	  $fields{"Version"} = "0.1";

	  my $subject = $parsed->header("Subject");

	  my $source_ip;

	  if ($subject =~ /complaint about message from ($RE{net}{IPv4})$/) {
		$source_ip = $1;
	  } else {
		die "Couldn't match subject: " . $subject;
	  }

	  $fields{"Source-IP"} = $source_ip;
 
	  my $or = $hotmail_headers->header('X-HmXmrOriginalRecipient');

	  if ($or) {
		$fields{'Original-Rcpt-To'} = $or;
	  }
	  
	  my $original_email = Email::MIME->new($orig_email);
	  
	  return Email::ARF::Report->create(
										original_email => $original_email,
										description => $description,
										fields => \%fields
									   );
	  
	} else {
	  die "Not a hotmail abuse report";
	}
  }

1;
__END__
=head1 NAME

Email::ARF::Hotmail - Perl extension for Hotmail Abuse reports

=head1 SYNOPSIS

  use Email::ARF::Hotmail;

  my $report = Email::ARF::Hotmail->create_report($message);

=head1 DESCRIPTION

This is a perl module to process Hotmail abuse reports (which are not in ARF) and generate
Email::ARF::Report objects.

=head1 METHODS

=head2 create_report

  my $report = Email::ARF::Hotmail->create_report($message);

Creates an Email::ARF::Report object or dies with an error if the message
cannot be parsed as a hotmail abuse report.

=head1 BUGS

Something weird is going on with encoding of the original email. For the
moment, you may need to decode it from quoted printable.

=head1 SEE ALSO

* Email::ARF::Report

* http://postmaster.live.com/Services.aspx

=head1 AUTHOR

Michael Stevens, E<lt>mstevens@etla.orgE<gt>

Also with contributions from Mark Zealey E<lt>mark.zealey@webfusion.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Michael Stevens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
