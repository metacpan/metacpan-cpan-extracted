package MailBot::UUEncode;

@ISA = qw(MIME::Decoder);
use strict;

sub decode_it {
    die "decoding not implemented";
}

sub encode_it {
    my ($self, $in, $out) = @_;
    my $string = "";

    my ($buf, $nread) = ('', 0);
    while ($nread = $in->read($buf, 4096)) {
	$string .= $buf;
    }
    defined($nread) or return undef;      # check for error

    my $string = pack('u',$string);

    # jfj note filename and content-type

    $string = "\nYour file has been uuencoded:\n\n" .
	"begin 644 myfile\n" . $string . " \nend\n";

    $out->print($string);
    1;
}

1;
