package Email::MIME::XMTP;

use vars qw[$VERSION];
$VERSION = '0.42';

use Email::MIME;

# adds XMTP to Email::MIME namespace (pollution?)
package Email::MIME;

use strict;

use Email::MIME::Encodings;
use XML::Parser; #not used yet...

my %namespaces = (
	'rdf'  => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	'rdfs'  => "http://www.w3.org/2000/01/rdf-schema#",
	'xmtp' => "http://www.openhealth.org/xmtp#",
	'thread' => "http://www.w3.org/2001/03/thread#"
	);

=head1 NAME

Email::MIME::XMTP - Extends Email::MIME objects to read and write XMTP

=head1 SYNOPSIS

    use Email::MIME;
    use Email::MIME::XMTP;
    my $mail = Email::MIME->new($text);

    # Email::MIME::XMTP extra methods
    my $xmlstring = $mail->as_XML;

    my $mailer = Email::Simple->new;
    my $mail = $mailer->parseXML( xml => $xmlstring );


=head1 DESCRIPTION

C<Email::MIME::XMTP> extends Email::MIME to read and write XMTP.

Read more about XMTP at http://www.openhealth.org/xmtp/

=head1 METHODS

Methods are the same as the one of Email::MIME. With the addition of
two extra ones for reading (parsing) and writing XMTP format. Plus one
to set the elements/headers XML namespaces and prefixes.

=head2 parseXML

Parse an XML SOURCE containing an XMTP formatted message and return a mail object.

The parseXML method takes any of the following parameters:

               filename
               xml
               ioref

One must be spacefied - it is an error if none is passed.

This uses the familiar hash syntax, so an example might be:

	use Email::MIME::XMTP;
	my $mailer = new Email::MIME::XMTP;

	my $mail = $mailer->parseXML( filename => 'example-mail-xmtp.xml');

The parameters represent a filename, a string containing XML and
an open filehandle ref respectively.

=cut

# TODO
sub parseXML {
	my ( $self, %params ) = @_;

	return
		unless(	exists $params{'xml'} or
			exists $params{'filename'} or
			exists $params{'ioref'} 
			);

	#my $parser = XML::Parser->new( %params );
	#$parser->parse;
	};

sub _init_namespaces {	
	my ($self) = @_;

	$self->{'_XML_namespaces'} = {};

	map {
		$self->{'_XML_namespaces'}->{ $_ } = $namespaces{ $_ };
		} keys %namespaces;
	};

=head2 set_namespace( PREFIX, URI )

Set the XML Namespace PREFIX to URI.

Note a particular XML-Namespace can also be set and transported using 
the special MIME header X-XMTP-xmlns as follows:

 X-XMTP-xmlns-<prefix>: <uri>

And then further referred into the MIME message using a X-XMTP-<prefix>
header like:

 X-XMTP-<prefix>: value

In a multipart message each part can have its scoped namespaces.

=cut

sub set_namespace {	
	my ($self, $prefix, $uri) = @_;

	$self->_init_namespaces()
		unless( exists $self->{'_XML_namespaces'} );

	return
		unless( defined $prefix and
			defined $uri );

	return
		if(	$prefix eq 'rdf'  or
			$prefix eq 'rdfs' or
			$prefix eq 'xmtp' or
			$prefix eq 'thread' );

	$self->{'_XML_namespaces'}->{ $prefix } = $uri;
	};

=head2 as_XML( [@FILTER_HEADERS] )

Returns an XML XMTP representation of a message. Optionally the FILTER_HEADERS array
can be used to restrict the MIME headers to return. In case any special XML
namespace is set, in addition to XMTP; the headers must be listed with their
fully qualified XML QNAME e.g. myprefix:My-Header.

=cut

sub as_XML {	
	my ( $self, @filter_headers ) = @_;

	my $xml  = "<?xml version='1.0' encoding='UTF-8' ?>\n";

	my @parts =  $self->parts; #take one part for the moment

	# be sure the first part is the message itself - then its multi-parts eventually
	unshift @parts, $self
		unless($#parts==0);

	# NOTE: we do primite nesting - and do not recurse over parts - is that what MIME spec says? nested multipart??!?
	my $i = 1;
	foreach my $part ( @parts ) {
		# well we should recurse to nested parts here too...

		$part->_init_namespaces()
			unless( exists $part->{'_XML_namespaces'} );

		# restore namespaces unless specified explicitly (correct how is done?)
		map {
			# we check special MIME (hacked!) headers
			# NOTE: not sure that mail filters/firewalls will let these through :-(
			my $header = $_;
			if( $header =~ m/^X-XMTP-xmlns-(.+)/ ) {
				my $prefix = $1;
				my @vals = grep {defined $_ } map {
						my $h = Encode::decode('MIME-Q', $self->header( $_ ));
						$h = Encode::decode_utf8( $h )
							unless( Encode::is_utf8( $h ) );
						$h;
					} @{ $part->{head}->{ $header } };
				my $uri = pop @vals; #always take the last header to allow override
				$uri =~ s/^\s*//;
				$uri =~ s/\s*$//;
				$part->set_namespace( $prefix, $uri )
					unless( exists $part->{'_XML_namespaces'}->{ $prefix } );
				};
		} keys %{$part->{head}};

		unless( $i == 1 ) {
			# inherit any namespace from top part unless set differently
			map {
				$part->set_namespace( $_, $self->{'_XML_namespaces'}->{ $_ } )
					unless( exists $part->{'_XML_namespaces'}->{ $_ } );
				} sort keys %{ $self->{'_XML_namespaces'} };
			};

		my $about =  Encode::decode('MIME-Q', $part->header( "Message-Id" ) );
		$about = Encode::decode_utf8( $about )
			unless( Encode::is_utf8( $about ) );   
		if($about) {
			$about =~ m/<([^>]+)>/;
			$about = "mid:" . $1;
			$about = $part->xml_escape( $about );
			};

		unless($i==1) {
			next
				unless(	( $#filter_headers < 0 ) ||
					( grep /^xmtp:Body-Multipart$/, @filter_headers ) );

			# fix XMTP bug - proper RDF striped nesting
			$xml    .= "\n".("   " x $i)."<xmtp:Body-Multipart>"
				if( $self->content_type =~ m/^\s*multipart/ );
			};

		$xml    .= "\n".("   " x $i)."<xmtp:Message";
		map {
			$xml    .= "\n".("   " x $i)."xmlns:". $_ ."='".$part->xml_escape( $part->{'_XML_namespaces'}->{ $_ } )."'";
			} sort keys %{ $part->{'_XML_namespaces'} };
		$xml    .= "\n".("   " x $i)."rdf:about='$about'"
			if($about);
		$xml    .= ">";

		my $body = $part->xml_escape( $part->_XMLbodyEncode() )
			if(	( $#filter_headers < 0 ) ||
				( grep /^xmtp:Body$/, @filter_headers ) );

		# need to UTF-8 encode headers then, if possible (otheriwise it will print invalid XML and warn the user!)
		$xml    .= $part->_headers_as_XML( $i, @filter_headers );

		$xml    .= "\n".("      " x $i)."<xmtp:Body>". $body ."</xmtp:Body>"
			if($body);

		# add special ones to the generated our just to make the generated XML more RDF-ish
		# NOTE: we do not actually need to have these headers into the MIME message itself due
 		#       we just map some special headers to some RDF meaningful ones.
		#
		# Add simple email threading using Annotea thread schema
		# see http://www.w3.org/2001/03/thread
		
		# add rdfs:seeAlso to each 'References' header
		my @seeAlso;
		if( exists $part->{head}->{ 'References' } ) {
			@seeAlso = map { split /\s+/; } grep { defined $_ } map {
				my $h = Encode::decode('MIME-Q', $self->header( $_ ));
				$h = Encode::decode_utf8( $h )
					unless( Encode::is_utf8( $h ) );
				$h;
				} @{ $part->{head}->{ 'References' } };
			my $i=0;
			foreach my $seeAlso ( @seeAlso ) { # first is the root of the thread - last is the in-reply-to
				$seeAlso =~ m/<([^>]+)>/;
				$seeAlso = "mid:" . $1;
				$seeAlso = $part->xml_escape( $seeAlso );
				$xml    .= "\n".("      " x $i)."<rdfs:seeAlso rdf:resource='$seeAlso' />";
				$xml    .= "\n".("      " x $i)."<thread:root rdf:resource='$seeAlso' />"
					if($i==0);
				$xml    .= "\n".("      " x $i)."<thread:inReplyTo rdf:resource='$seeAlso' />"
					if($i==$#seeAlso);
				$i++;
				};
			};

		# make the xmtp:Message of type thread:Reply if a reply
		$xml    .= "\n".("      " x $i)."<rdf:type rdf:resource='".$self->{'_XML_namespaces'}->{ 'thread' }."Reply' />"
			if( exists $part->{head}->{ 'In-Reply-To' } );

		unless($i==1) {
			$xml .= "\n".("   " x $i)."</xmtp:Message>";

			# fix XMTP bug - proper RDF striped nesting
			$xml    .= "\n".("   " x $i)."</xmtp:Body-Multipart>"
				if( $self->content_type =~ m/^\s*multipart/ );
			};
		
		$i++;
		};

	$xml .= "\n</xmtp:Message>";

	#print STDERR $xml;

	return $xml;
	};

# convert body to UTF-8 and encode it if necessary
sub _XMLbodyEncode {
	my ( $self ) = @_;
	
	my $body = $self->{body};
		
	my $cte = $self->header("Content-Transfer-Encoding");

	if(	$cte ne 'base64' and
		$cte ne 'quoted-printable' ) {
		# NOTE: we do not further check $cte here...

		# need to UTF-8 encode it then, if possible (otheriwise it will print invalid XML and warn the user!)
		if( eval { require Encode } ) {
			eval {

			# default to UTF-8 if no charset set - correct? what the RFC really says here? I guess force US-ASCII
			# NOTE: due that US-ASCII is covered by UTF-8 it should be safe enough here - and assuming a client/MTA
			#       will add proper charset="...somthing..." to their Content-Type header otherwise

			# both the following decode() set the internal Perl UTF-8 flag (see man Encode)
			if( $self->content_type =~ m/charset=([^;]+);?\s*/mi ) {
				$body = Encode::decode( $1, $body );
			} else {
				$body = Encode::decode_utf8( $body )
					unless( Encode::is_utf8( $body ) );
				};
			};

			# set Content-Type charset to UTF-8 for the output XML message
			my $ct = $self->content_type;
			$self->header_set( 'Content-Type', $ct )
				if( $ct =~ s/charset=([^;]+)(;?\s*)/charset=UTF-8$2/mi );

			# we do not update Content-Transfer-Encoding to 8bit - correct?
			$self->header_set( 'Content-Transfer-Encoding', '8bit' );
		} else {
			#warn "XMTP message xmtp:body not UTF-8 encoded. The Encode module is missing in your Perl installation.\n";
			};

		# force base64 encoding due we do not make any euristics on Content-Type or Content-Transfer-Encoding yet
		if(	$cte eq 'binary' or
			(	defined $self->content_type and
				$self->content_type ne '' and
				$self->content_type !~ m/text/i and
				$self->content_type !~ m/^\s*multipart/i ) ) {
			# set Content-Transfer-Encoding header to base64 if not there
			$body = Email::MIME::Encodings::encode( base64 => $body );

			$self->header_set( 'Content-Transfer-Encoding', 'base64' );
			};
		};

	return $body;
	};

sub _headers_as_XML {
	my ( $self, $i, @filter_headers ) = @_;

	my @order = @{$self->{order}};
	my %head = %{$self->{head}};
	my $stuff = "";

	# a valid XML tag
	my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
	my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
	my $Name = "(?:$NameStrt)(?:$NameChar)*";

	while (keys %head) {
		my $thing = shift @order;
		next unless exists $head{$thing}; # We have already dealt with it

		my @hds = map {
                        ( Encode::is_utf8( $_ ) ) ? $_ : Encode::decode_utf8( $_ );
		} map {
			Encode::decode('MIME-Q', $_ );
		} $self->header( $thing ); # be sure Email::MIME decode headers to UTF-8 for me

		if( eval { require Encode } ) {
                        eval {
                                @hds = map {
					# the following set the internal Perl UTF-8 flag (see man Encode)
					( Encode::is_utf8( $_ ) ) ? $_ : Encode::decode_utf8( $_ );
					} @hds;
                                };
                } else {
                        #warn "XMTP message header/s not UTF-8 encoded. The Encode module is missing in your Perl installation.\n";
                        };

		$stuff .= $self->_header_as_XML($thing, \@hds, $i)
			if(	( $thing =~ m/^$Name$/o ) && #skip non-XML tag alike headers
				(	( $#filter_headers < 0 ) ||
					( grep /^$thing$/, @filter_headers ) ) );

		delete $head{$thing};
		};
	return $stuff;
	};

sub _header_as_XML {
	my ($self, $field, $data, $i) = @_;
	my @stuff = @$data;
	# Ignore "empty" headers
	return '' unless @stuff = grep { defined $_ } @stuff;

	my $xml;
	foreach ( @stuff ) {
		my $ff = $_;
		my @parts = split(/\s*;\s/, $ff );
		# check if we really have a a MIME headers parameter/s list
		foreach (@parts) {
			my $p = $_; #copy
			$p =~ s/^\s*//;
			$p =~ s/\s*$//;
			if( my @ss = split(/\s*=\s*/, $p ) ) {
				# check each parameter
				my $stop=0;
				foreach my $sp ( @ss ) {
					$sp =~ s/^\s*//;
					$sp =~ s/\s*$//;
					if(	( not ( $sp =~ m/^["']/ and # not a literal - correct?
							$sp =~ m/["']$/  ) ) and
						$sp =~ m/\s+/ ) { #wrong then
						$stop=1;
						last;
						};
					};
				if($stop) {
					(@parts) = shift @parts;
					last;
					};
			} elsif( $p =~ m/\s+/ ) { # wrong then
				(@parts) = shift @parts;
				last;
				};
			};

		# skip special ones
		next
			if( $field =~ m/^X-XMTP-xmlns-/ );

		my $prefix;
		$field =~ s/^X-XMTP-(.+)-(.+)$/$2/;
		if($1) {
			if( exists $self->{'_XML_namespaces'}->{ $1 } ) {
				$prefix = $1;
			} else {
				next; # skip unknown fields
				};
		} else {
			$prefix = 'xmtp';
			};
	
		if($#parts == 0 ) {
			$ff = "\n".("      " x $i)."<".$self->xml_escape( $prefix ).":".$self->xml_escape( $field ).
							">". $self->xml_escape( $ff ) . "</".$self->xml_escape( $prefix ).":".$self->xml_escape( $field ).">";
		} else {
			# rdf:parseType="Resource"
			$ff = "\n".("      " x $i)."<".$self->xml_escape( $prefix ).":".$self->xml_escape( $field )." rdf:parseType='Resource'>";
			foreach my $part ( @parts ) {
				my $subfield;
				my $subvalue;
				my @subparts = split(/\s*=\s*/, $part );
				if( $#subparts == 0 ) {
					$subfield = "rdf:value"; # right - but we can have at most ONE rdf:value is that true for MIME headers parameters??
					$subvalue = $subparts[0];
				} else {
					$subfield = $prefix.':' . shift @subparts;
					$subvalue = shift @subparts;
					# trim value
					$subvalue =~ s/^\s*["']//gm;
					$subvalue =~ s/["']\s*$//gm;
					};

				$ff .= "\n".("         " x $i)."<".$self->xml_escape( $subfield ).">". $self->xml_escape( $subvalue ) . "</".$self->xml_escape( $subfield ).">";
				};
			$ff .= "\n".("      " x $i)."</". $self->xml_escape( $prefix ).":".$self->xml_escape( $field ).">";
			};

		$xml .= $ff;
		};

	return $xml;
	};

sub xml_escape {
	my $self = shift;
	my $text  = shift;

        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        foreach (@_) {
                croak "xml_escape: '$_' isn't a single character" if length($_) > 1;

                if ($_ eq '>') {
                        $text =~ s/>/\&gt;/g;
                } elsif ($_ eq '"') {
                        $text =~ s/\"/\&quot;/g;
                } elsif ($_ eq "'") {
                        $text =~ s/\'/\&apos;/g;
                } else {
                        my $rep = '&#' . sprintf('x%X', ord($_)) . ';';
                        if (/\W/) {
                                my $ptrn = "\\$_";
                                $text =~ s/$ptrn/$rep/g;
                        } else {
                                $text =~ s/$_/$rep/g;
                                };
                        };
                };
        return $text;
        };

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 All rights reserved Asemantics S.r.l

(see LICENSE file coming with this distribution)

=head1 AUTHOR

Alberto Reggiori <alberto(at)asemantics.com>

=head1 Email::MIME COPYRIGHT AND LICENSE

Copyright 2004 by Casey West

Copyright 2003 by Simon Cozens

=head1 SEE ALSO

XMTP http://www.openhealth.org/xmtp/

Perl Email Project, http://pep.kwiki.org .

=cut
