package Mail::Abuse::Incident::Normalize;

require 5.005_62;

use Carp;
use strict;
use warnings;
use MIME::Parser;
use HTML::Parser;

use base 'Mail::Abuse::Incident';

				# The code below should be in a single line

our $VERSION = do { my @r = (q$Revision: 1.11 $ =~ /\d+/g); sprintf " %d."."%03d" x $#r, @r };

=pod

=head1 NAME

Mail::Abuse::Incident::Normalize - Filter the text of a report within an Email

=head1 SYNOPSIS

  use Mail::Abuse::Report;
  use Mail::Abuse::Incident::Normalize;
  my $i = new Mail::Abuse::Incident::Normalize;
  my $report = new Mail::Abuse::Report (incidents => [$i] );

=head1 DESCRIPTION

This class handles various important tasks related with recognizing an
abuse report. The specific tassks are:

=over

=item *

Parse the headers and the body of the email message

=item *

Provide a translation from HTML to text if no suitable part is
included in the original report

=item *

When a report has been forwarded or quoted multiple times, this class
removes the indications at the beginning and left-hand side (E<gt>).

=back

The parser based on this class must be the first in the list of
parsers passed to the report object, so that all parser that need its
services can access them automatically.

The following new keys are created into the corresponding report after
running this class. These are:

=over

=item B<header>

A C<Mail::Header> object with the header of the message.

=item B<body>

Contains a reference to the body of the message, as a single scalar or
string.

=item B<normalized>

Set to the scalar C<Mail::Abuse::Incident::Normalize> to indicate that
this class did the normalization.

=item B<tz>

The guessed timezone from the message. This might come from matching
it in the body of the message, from the Date header or from other
sources. This should be used as a "last-resort hint" by other Incident
parsers.

=back

The following method is implemented bu this class:

=over

=item C<parse($report)>

Pushes incidents into the given report, based on parsing of the text
in the report itself.

It must return a list of objects of the same class, with the incident data
(IP address, timestamp and other information) filled.

=cut

sub parse
{
    my $self	= shift;
    my $rep	= shift;

				# Phase 0 - Build the parser we'll
				# be using this time. We do so with
				# closures, so that they can reach
				# $rep w/o black magic

    my $p = HTML::Parser->new
	(
	 api_version => 3,
	 default_h		=> [ "" ],
	 start_h => [ sub {  $ {$rep->body} .= 
				 "[IMG " . 
				     ($_[1]->{alt} || $_[1]->{src} || 'n/a') . 
					 "]\n" 
					     if $_[0] && $_[0] eq 'img';
			 }, "tagname, attr" ],
	 text_h => [ sub { $ {$rep->body} .= shift; }, "dtext" ],
	 ) or return;
    
    $p->ignore_elements(qw(script style));
    $p->strict_comment(1);

    $self->html_parser($p);

    my $parser = new MIME::Parser;
    return unless $parser;

    $parser->ignore_errors(1);
    $parser->decode_headers(1);
    $parser->extract_nested_messages(1);
    $parser->extract_uuencode(1);

				# Phase 1 - Decode and find a suitable
				# part containing the message text.
				# Store its headers and body

    my $e = eval { $parser->parse_data($rep->text); };

    if ($@ or !$e)
    {
	$parser->filer->purge;
	return;
    }

    my $text;
    $rep->header($e->head);
    $rep->body(\$text);

    my $decoded_body = ($self->decode_parts($rep, 'any', $e) || '');
    $rep->body(\$decoded_body) if $decoded_body;

    $rep->normalized(ref $self);
    $self->html_parser(undef);
    $parser->filer->purge;

    return unless $rep->body and $ {$rep->body};

				# Phase 2 - This might be actually a
				# reply of forward. Remove any
				# indications from the message body

    $ {$rep->body} =~ s/
	^(([\t ]|[^\w\s])*	# 0 or more non-space, non-word chars
	  [^\w\s]+		# followed by one or more non-space, non-words
	  )+			# repeated one or more times,
	 [\t ]*			# followed by zero or more spaces.
	//xmsg;

				# Phase 3 - Try to recognize a
				# timezone in the body. If this fails,
				# try at the Date: header. Finally,
				# use UTC as the guess 

    # These timezones were taken w/o permission from Time::Zone.
    # Thanks to the authors anyway :)

    my %Zones =
	(
	 "GMT"	=> '+0000',	# Greenwich Mean
	 "UT"	=> '+0000',	# Universal (Coordinated)
	 "UTC"	=> '+0000',
	 "WET"	=> '+0000',	# Western European
	 "WAT"	=> '-0100',	# West Africa
	 "AT"	=> '-0200',	# Azores
	 "FNT" 	=> '-0200',	# Brazil Time (Extreme East)
	 "BRT"	=> '-0300',	# Brazil Time (East Standard)
	 "MNT"	=> '-0400',	# Brazil Time (West Standard)
	 "EWT"	=> '-0400',	# U.S. Eastern War Time
	 "AST"	=> '-0400',	# Atlantic Standard
	 "VET"	=> '-0400',	# Venezuela Standard Time
	 "EST"	=> '-0500',	# Eastern Standard
	 "ACT"	=> '-0500',	# Brazil Time (Extreme West - Acre)
	 "CST"	=> '-0600',	# Central Standard
	 "MST"	=> '-0700',	# Mountain Standard
	 "PST"	=> '-0800',	# Pacific Standard
	 "YST"	=> '-0900',	# Yukon Standard
	 "HST"	=> '-1000',	# Hawaii Standard
	 "CAT"	=> '-1000',	# Central Alaska
	 "AHST"	=> '-1000',	# Alaska-Hawaii Standard
	 "NT"	=> '-1100',	# Nome
	 "IDLW"	=> '-1200',	# International Date Line West
	 "CET"	=> '+0100',	# Central European
	 "MEZ"	=> '+0100',	# Central European (German)
	 "ECT"	=> '+0100',	# Central European (French)
	 "MET"	=> '+0100',	# Middle European
	 "MEWT"	=> '+0100',	# Middle European Winter
	 "SWT"	=> '+0100',	# Swedish Winter
	 "SET"	=> '+0100',	# Seychelles
	 "FWT"	=> '+0100',	# French Winter
	 "EET"	=> '+0200',	# Eastern Europe, USSR Zone 1
	 "UKR"	=> '+0200',	# Ukraine
	 "BT"	=> '+0300',	# Baghdad, USSR Zone 2
	 "IT"	=> '+0330',	# Iran
	 "ZP4"	=> '+0400',	# USSR Zone 3
	 "ZP5"	=> '+0500',	# USSR Zone 4
	 "IST"	=> '+0530',	# Indian Standard 
	 "ZP6"	=> '+0600',	# USSR Zone 5
	 "WST"	=> '+0800',	# West Australian Standard
	 "HKT"	=> '+0800',	# Hong Kong
	 "CCT"	=> '+0800',	# China Coast, USSR Zone 7
	 "JST"	=> '+0900',	# Japan Standard, USSR Zone 8
	 "KST"	=> '+0900',	# Korean Standard
	 "CAST"	=> '+0930',	# Central Australian Standard 
	 "EAST"	=> '+1000',	# Eastern Australian Standard
	 "GST"	=> '+1000',	# Guam Standard, USSR Zone 9
	 "NZT"	=> '+1200',	# New Zealand
	 "NZST"	=> '+1200',	# New Zealand Standard
	 "IDLE"	=> '+1200',	# International Date Line East
	 );

    # In the following matches, we'll attempt to use the inverted
    # message to avoid mistaking a timezone in a forwarded header for
    # our target timestamp...

    my $rev = join "\n", reverse split /\n/, $ {$rep->body};

				# Step 3a - Try to locate a numeric
				# timezone in the format [+-]\d\d:?\d\d

#    warn "Body: ${$rep->body}\n*********************\n";
#    warn "Rev: $rev\n******************\n";

    if ($rev =~ m!([-+]\d\d:?\d\d)!ms) 
    {
	$rep->tz($1);
    }

				# Step 3b - If failed, try to locate the
				# longest timezone posssible

    unless ($rep->tz)
    {
	my $zone = '';

	for my $tz ( sort keys %Zones )
	{
	    next if length($tz) < length($zone);
	    next unless ($rev =~ m/\W ${tz} \W /msx
			 or $rev =~ m/^ ${tz} \W /msx
			 or $rev =~ m/\W ${tz} $ /msx
			 or $rev =~ m/^ ${tz} $ /msx);
#	    warn "*** Zone $tz matched\n";
	    $zone = $tz;
	}

	$rep->tz($Zones{$zone}) if $zone;
    }

				# Step 3c - If failed, declare UTC

    $rep->tz('UTC') unless defined $rep->tz;

    return; 
}

sub decode_parts
{
    my $self	= shift;
    my $rep	= shift;
    my $type	= shift;
    my $e	= shift;

    if (my @parts = $e->parts)
    {
	my $r = '';
	$r .= ($self->decode_parts($rep, $type, $_) || '') for @parts;
	return $r;
    }
    elsif (my $body = $e->bodyhandle)
    {
	my $mime = $e->head->mime_type;
	if (grep { $mime eq $_ } qw(text/plain message/rfc822))
	{
	    return $body->as_string;
	}
	elsif ($type eq 'any' and $mime eq 'text/html')
	{
	    my $b = $body->as_string;
	    $self->html_parser->parse($b);
	    return $ {$rep->body};
	}
    }
    return;			# False by default
}

__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.2 with options

  -ACOXcfkn
	Mail::Abuse
	-v
	0.01

=back


=head1 LICENSE AND WARRANTY

This code and all accompanying software comes with NO WARRANTY. You
use it at your own risk.

This code and all accompanying software can be used freely under the
same terms as Perl itself.

=head1 AUTHOR

Luis E. Muñoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1).

=cut

