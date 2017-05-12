# (c)2000 Matthew MacKenzie <matt@xmlglobal.com>
# License: Artistic or LGPL, your choice.

package Mail::XML;
use strict;
use Mail::Internet;
use XML::Writer;
use IO::Scalar;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter Mail::Internet);
$VERSION = '0.03';

sub toXML {
	my ($self) = shift;
	my $head = $self->head() || croak;
	my $body = $self->body() || croak;
	
	my $data = "";
	my $hdl = new IO::Scalar(\$data);
	my $w = new XML::Writer(OUTPUT => $hdl);
	$w->xmlDecl("ISO-8859-1");
	$w->comment("Mail::XML version " . $VERSION);
	$w->startTag("Message");
	$w->startTag("Head");
	foreach my $tag ($head->tags()) {
		chomp(my $c = $head->get($tag));
		if ($tag =~ m!From\s!) {
			$tag = "MTA_From";
		}
		$w->startTag($tag);
		$w->characters($c);
		$w->endTag($tag);
	}
	$w->endTag("Head");
	$w->startTag("Body");

	foreach (@$body) {
		$w->characters($_);
	}
	$w->endTag("Body");
	$w->endTag("Message");
	$w->end();
	$hdl->close();
	return $data;
}

1;
__END__

=head1 NAME

Mail::XML - Adds a toXML() method to Mail::Internet.

=head1 SYNOPSIS

  use Mail::XML;
  my $mi = new Mail::XML(\@message);
  print $mi->toXML();

=head1 DESCRIPTION

All that this module does is provide a toXML() method to Mail::Internet.  For all intents and
purposes, Mail::XML is Mail::Internet plus toXML(), so you are best off reading the Mail::Internet
manpage :)

=head1 WHY??

I had some messy scripts which took messages from a mailing list and archived them in XML.  When it
came time to maintain my messy scripts, I was lost, so I started using Mail::Internet and just supplying
my own toXML() method.  This module is an evolution of all of that :)

=head1 FUTURE PLANS

I plan on doing something useful with MIME attachments, supplying a toMIME() function.  Ideas and
contributions are welcome.
 
=head1 AUTHOR

Matthew MacKenzie <matt@xmlglobal.com>

=head1 SEE ALSO

Mail::Internet

=cut
