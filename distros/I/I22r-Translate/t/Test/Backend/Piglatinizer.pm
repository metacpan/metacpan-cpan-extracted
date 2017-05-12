package Test::Backend::Piglatinizer;
use I22r::Translate::Result;
use Moose::Role;
with 'I22r::Translate::Backend';

# a translator that knows how to translate to
# and from Pig Latin.

# requires an API key ("oink")
# supports a "delay" config param that pauses between
# translations. Helpful to test the timeout settings.

sub config { }
sub can_translate {
    my ($self, $lang1, $lang2) = @_;
    if ($lang1 eq 'pla' || $lang2 eq 'pla') {
	return 1;
    }
    return 0;
}
sub get_translations {
    my ($self, $req) = @_;
    my @translated;
    return unless uc $req->config("API_KEY") eq 'OINK';
    for my $id (keys %{ $req->text }) {
	last if $req->timed_out;
	my $otext = $req->text->{$id};
	my $dest = $req->dest;
	my $text = $otext;
	if ($dest ne $req->src) {
	    $text = "[$dest]" . $text . "[/$dest]";
	}
	$req->results->{$id} =
	    I22r::Translate::Result->new(
		id => $id,
		olang => $req->src,
		lang => $dest,
		otext => $otext,
		text => $text,
#		    source => 'Trivial',
		time => time,
	    );
	push @translated, $id;

    }
    return @translated;
}

1;

