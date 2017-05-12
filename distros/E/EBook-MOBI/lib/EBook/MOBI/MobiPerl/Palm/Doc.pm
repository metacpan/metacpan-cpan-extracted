# Palm::Doc.pm
#
# Palm::PDB helper for handling Palm Doc databases
#
# Copyright (C) 2004 Christophe Beauregard
#
# $Id: Doc.pm,v 1.19 2005/05/12 01:36:49 cpb Exp $

use strict;

package EBook::MOBI::MobiPerl::Palm::Doc;

use EBook::MOBI::MobiPerl::Palm::PDB;
use EBook::MOBI::MobiPerl::Palm::Raw();
use vars qw( $VERSION @ISA );

$VERSION = do { my @r = (q$Revision: 1.19 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@ISA = qw( EBook::MOBI::MobiPerl::Palm::Raw );

use constant DOC_UNCOMPRESSED => scalar 1;
use constant DOC_COMPRESSED => scalar 2;
use constant DOC_RECSIZE => scalar 4096;

=head1 NAME

Palm::Doc - Handler for Palm Doc books

=head1 SYNOPSIS

use Palm::Doc;

=head1 DESCRIPTION

Helper for reading and writing Palm Doc books. The interface is based on
L<Palm::ZText> since it just makes sense. However, because of the nature
of these databases, record-level processing is just a Bad Idea. Use
the C<text> and C<textfile> calls rather than do direct access of the
C<@records> array.

=head1 EXAMPLES

Convert a text file to a .pdb:

	use Palm::Doc;
	my $doc = new Palm::Doc;
	$doc->textfile( $ARGV[0] );
	$doc->Write( $ARGV[0] . ".pdb" );

Convert an HTML file to a .prc:

	use HTML::TreeBuilder;
	use HTML::FormatText;
	use Palm::Doc;

	my $tree = HTML::TreeBuilder->new_from_file( $ARGV[0] );
	my $formatter = HTML::FormatText->new( leftmargin => 0, rightmargin => 80 );
	my $doc = new Palm::Doc;
	$doc->{attributes}{resource} = 1;
	$doc->text( $formatter->format( $tree ) );
	$doc->Write( $ARGV[0] . ".prc" );

=cut
#'

sub import
{
	&EBook::MOBI::MobiPerl::Palm::PDB::RegisterPDBHandlers( __PACKAGE__, [ "REAd", "TEXt" ], );
	&EBook::MOBI::MobiPerl::Palm::PDB::RegisterPRCHandlers( __PACKAGE__, [ "REAd", "TEXt" ], );
	&EBook::MOBI::MobiPerl::Palm::PDB::RegisterPDBHandlers( __PACKAGE__, [ "MOBI", "BOOK" ], );
	&EBook::MOBI::MobiPerl::Palm::PDB::RegisterPRCHandlers( __PACKAGE__, [ "MOBI", "BOOK" ], );
}

=head2 new

	$doc = new Palm::Doc;

Create a new Doc object. By default, it's not a resource database. Setting
C<$self->{attributes}{resource}> to C<1> before any manipulations will
cause it to become a resource database.

=cut

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->{'creator'} = 'REAd';
	$self->{'type'} = 'TEXt';

	$self->{attributes}{resource} = 0;

	$self->{appinfo} = undef;
	$self->{sort} = undef;
	$self->{records} = [];

	return $self;
}

# determine if the given (raw) record is a Doc header record and fill in the
# record with appropriate fields if it is.
sub _parse_headerrec($) {
	my $record = shift;
	return undef unless exists $record->{'data'};

	# Doc header is minimum of 16 bytes
	return undef if length $record->{'data'} < 16;

	my ($version,$spare,$ulen, $records, $recsize, $position)
		= unpack( 'n n N n n N', $record->{'data'} );

    # BEGIN: BORIS DAEPPEN JULY 2012
    # ***********************
    # This code just prints stuff... which is what I don't like
    # One should not print to stderr just for fun!
    # so this is why I put this out of work...

	#my $h = sprintf ("%x", $version);
	#print STDERR "Version: $version - $h - ";
	#if ($version == DOC_COMPRESSED) {
	    #print STDERR " DOC_COMPRESSED\n";
	#}
	#if ($version == DOC_UNCOMPRESSED) {
	    #print STDERR " DOC_UNCOMPRESSED\n";
	#}
	#if ($version != DOC_UNCOMPRESSED and $version != DOC_COMPRESSED) {
	    #print STDERR " probably HUFFDIC_COMPRESSED - CANNOT BE DECOMPRESSED!!!\n";
	#}
    # ***********************
    # END: BORIS DAEPPEN JULY 2012

	# the header is followed by a list of record sizes. We don't use
	# this since we can guess the sizes pretty easily by looking at
	# the actual records.

	# According to the spec, $version is either 1 (uncompressed)
	# or 2 (compress), while spare is always zero. AportisDoc supposedly sets
	# spare to something else, so screw AportisDoc.
	return undef if $version != DOC_UNCOMPRESSED and $version != DOC_COMPRESSED;
	return undef if $spare != 0;

	$record->{'version'} = $version;
	$record->{'length'} = $ulen;
	$record->{'records'} = $records;
	$record->{'recsize'} = $recsize;
	$record->{'position'} = $position;

	return $record;
}

sub _compress_record($$) {
	my ($version,$in) = @_;
	return $in if $version == DOC_UNCOMPRESSED;

	my $out = '';

	my $lin = length $in;
	my $i = 0;
	while( $i < $lin ) {
		# See http://patb.dyndns.org/Programming/PilotDoc.htm for the code type
		# taxonomy.

		# Try type B compression first.
		# If the next 3 to 10 bytes are already in the compressed buffer, we can
		# encode them into a 2 byte sequence. Don't bother too close to the ends,
		# however... Makes the boundary conditions simpler.
		if( $i > 10 and $lin - $i > 10 ) {
			my $chunk = '';
			my $match = -1;

			# the preamble is what'll be in the decoders output buffer.
			my $preamble = substr( $in, 0, $i );
			for( my $j = 10; $j >= 3; $j -- ) {
				$chunk = substr( $in, $i, $j );	# grab next $j characters
				$match = rindex( $preamble, $chunk );	# in the output?

				# type B code has a 2047 byte sliding window, so matches have to be
				# within that range to be useful
				last if $match >= 0 and ($i - $match) <= 2047;
				$match = -1;
			}

			my $n = length $chunk;
			if( $match >= 0 and $n <= 10 and $n >= 3 ) {
				my $m = $i - $match;

				# first 2 bits are 10, next 11 are offset, next 3 are length-3
				$out .= pack( "n", 0x8000 + (($m<<3)&0x3ff8) + ($n-3) );

				$i += $n;

				next;
			}
		}
		
		my $ch = substr( $in, $i ++, 1 );
		my $och = ord($ch);

		# Try type C compression.
		if( $i+1 < $lin and $ch eq ' ' ) {
			my $nch = substr( $in, $i, 1 );
			my $onch = ord($nch);

			if( $onch >= 0x40 and $onch < 0x80 ) {
				# space plus ASCII character compression
				$out .= chr($onch ^ 0x80);
				$i ++;

				next;
			}
		} 

		if( $och == 0 or ($och >= 9 and $och < 0x80) ) {
			# pass through
			$out .= $ch;
		} else {
			# type A code. This is essentially an 'escape' like '\\' in strings.
			# For efficiency, it's best to encode as long a sequence as
			# possible with one copy. This might seem like it would cause us to miss
			# out on a type B sequence, but in actuality keeping long binary strings
			# together improves the likelyhood of a later type B sequence than 
			# interspersing them with x01's.

			my $next = substr($in,$i - 1);
			if( $next =~ /([\x01-\x08\x80-\xff]{1,8})/o ) {
				my $binseq = $1;
				$out .= chr(length $binseq);
				$out .= $binseq;
				$i += length( $binseq ) - 1;	# first char, $ch, is already counted
			}
		}
	}

	return $out;
}

# algorithm taken from makedoc7.cpp with reference to
# http://patb.dyndns.org/Programming/PilotDoc.htm and
# http://www.pyrite.org/doc_format.html
sub _decompress_record($$) {
	my ($version,$in) = @_;
	return $in if $version == DOC_UNCOMPRESSED;

	my $out = '';

	my $lin = length $in;
	my $i = 0;
	while( $i < $lin ) {
		my $ch = substr( $in, $i ++, 1 );
		my $och = ord($ch);

		if( $och >= 1 and $och <= 8 ) {
			# copy this many bytes... basically a way to 'escape' data
			$out .= substr( $in, $i, $och );
			$i += $och;
		} elsif( $och < 0x80 ) {
			# pass through 0, 9-0x7f
			$out .= $ch;
		} elsif( $och >= 0xc0 ) {
			# 0xc0-0xff are 'space' plus ASCII char
			$out .= ' ';
			$out .= chr($och ^ 0x80);
		} else {
			# 0x80-0xbf is sequence from already decompressed buffer
			my $nch = substr( $in, $i ++, 1 );
			$och = ($och << 8) + ord($nch);
			my $m = ($och & 0x3fff) >> 3;
			my $n = ($och & 0x7) + 3;

			# This isn't very perl-like, but a simple
			# substr($out,$lo-$m,$n) doesn't work.
			my $lo = length $out;
			for( my $j = 0; $j < $n; $j ++, $lo ++ ) {
				die "bad Doc compression" unless ($lo-$m) >= 0;
				$out .= substr( $out, $lo-$m, 1 );
			}
		}
	}

	return $out;
}

sub Write {
	my $self = shift;

	my $prc = $self->{attributes}{resource};
	my $recs = $prc ? $self->{'resources'} : $self->{'records'};
	my $header = $recs->[0];
	unless( defined _parse_headerrec($header) ) {
		die "@_: Doesn't appear to be a correct book...";
	}

	$self->SUPER::Write(@_);
}

=head2 text

	$text = $doc->text;

Return the contents of the Doc database.

	$text = $doc->text( @text );

Set the contents of the Doc book to the specified arguments. All the list arguments
will simply be concatenated together.

=cut

sub text {
	my $self = shift;

	my $body = '';
	my $prc = $self->{attributes}{resource};

	if( @_ > 0 ) {
		$body = join( '', @_ );

		my $version = DOC_COMPRESSED;

		$self->{'records'} = [];
		$self->{'resources'} = [];

		# first record is the header
		my $header = $prc ? $self->append_Resource() : $self->append_Record();
		$header->{'version'} = $version;
		$header->{'length'} = 0;
		$header->{'records'} = 0;
		$header->{'recsize'} = DOC_RECSIZE;

		# break the document into record-sized chunks
		for( my $i = 0; $i < length($body); $i += DOC_RECSIZE ) {
			my $record = $prc ? $self->append_Resource : $self->append_Record;
			my $chunk = substr($body,$i,DOC_RECSIZE);
			$record->{'data'} = _compress_record( $version, $chunk );

			$header->{'records'} ++;
			$header->{'length'} += length $body;
		}

		$header->{'recsize'} = $header->{'length'}
			if $header->{'length'} < DOC_RECSIZE;

		# pack up the header
		$header->{'data'} = pack( 'n xx N n n N',
			$header->{'version'}, $header->{'length'},
			$header->{'records'}, $header->{'recsize'}, 0 );

	} elsif( defined wantarray ) {

	    my $recs = $prc ? $self->{'resources'} : $self->{'records'};

	    my $header = $recs->[0];
	    if( defined _parse_headerrec($header) ) {
		# a proper Doc file should be fine, but if it's not Doc
		# compression like some Mobi docs seem to be we want to
		# bail early. Otherwise we end up with a huge stream of
		# substr() errors and we _still_ don't get any content.
		eval {
		    sub min { return ($_[0]<$_[1]) ? $_[0] : $_[1] }
		    my $maxi = min($#$recs, $header->{'records'});
		    for( my $i = 1; $i <= $maxi; $i ++ ) {
			my $data = $recs->[$i]->{'data'};
			my $len = length($data);
			my $overlap = "";
			if ($self->{multibyteoverlap}) {
			    my $c = chop $data;
			    print STDERR "I:$i - $len - ", int($c), "\n";
			    my $n = $c & 7;
			    foreach (0..$n-1) {
				$overlap = (chop $data) . $overlap;
			    }
			}
			
			$body .= _decompress_record( $header->{'version'},
						     $data );
			$body .= $overlap;
		    }
		};
		return undef if $@;
	    }
	}

	return $body;
}

=head2 textfile

	$doc->textfile( "README.txt" );

Set the contents of the Doc to the contents of the file and sets the name of the PDB to
the specified filename.

=cut

sub textfile($$) {
	my ($self, $filename) = @_;

	open IN, "< $filename" or return undef;
	binmode IN;
	$self->text( '', <IN> );
	close IN;

	$self->{'name'} = $filename;
}

1;
__END__

=head1 BUGS

Bookmarks are unsupported. I've never had any use for them.

Output databases are always compressed and there's no option to
disable compression.  I consider this a feature, to be honest.

=head2 Note On Character Sets

L<Palm::Doc> doesn't do anything with character sets. This might be a bug,
depending on how you feel about this kind of thing, but the reality is that
we're generally converting between text and Doc files, neither of which are
real great at telling us what encoding we're supposed to use.

My understanding of PalmOS character sets is that Doc books should be
encoded in either Windows Code Page 1252 or, for Japanese, 932. Actually,
the PalmOS encoding is a small variation on those. In practice, ISO 8859-1
works okay for western languages which is real nice because L<Encode>
doesn't know about the PalmOS stuff. 

This gist of all this is that when you're creating a L<Palm::Doc>, you may
need to do something along the lines of:

	use Encode 'from_to';

	my $text = read_my_text();
	from_to( $text, $charset, 'iso-8859-1' ) unless $charset =~ /8859-1$/;
	my $doc = new Palm::Doc();
	$doc->text( $text );

And when you're reading a L<Palm::Doc> and you care about the character
set, you're pretty much going to have to guess the encoding and act
appropriately:

	use Encode 'decode';
	my $doc = new Palm::PDB;
	$doc->Load( $pdbname );
	my $text = decode("iso-8859-1", $doc->text());

=head1 AUTHOR

Christophe Beauregard E<lt>cpb@cpan.orgE<gt>

=head1 SEE ALSO

L<Palm::PDB>

L<Palm::ZText>

makedoc

L<http://www.pyrite.org/doc_format.html>

L<http://patb.dyndns.org/Programming/PilotDoc.htm>

L<Palm::PalmDoc> is another CPAN module for handling Doc databases,
but doesn't use L<Palm::PDB> and doesn't handle reading Docs.

L<http://www.df.lth.se/~triad/krad/recode/palm.html> for details on PalmOS
text encoding

=cut
