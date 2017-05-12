package Test::Backend::Reverser;
use I22r::Translate::Result;
use Moose::Role;
with 'I22r::Translate::Backend';

my $THR_avail = eval "use Time::HiRes; 1";

# a translator that reverses each word and reverses the 
# order of words


# supports a "delay" config param that pauses between
# translations. Helpful to test the timeout settings.

sub can_translate {
    my ($self, $lang1, $lang2) = @_;
    return 1;
}

sub get_translations {
    my ($self, $req) = @_;
    my @translated;
    for my $id (keys %{ $req->text }) {
	last if $req->timed_out;
	my $otext = $req->otext->{$id};
	my $dest = $req->dest;
	my $text = $req->text->{$id};

	$text =~ s/(\w+)/reverse $1/ge;
	my @text = split /(\s+)/, $text;
	$text = join '', reverse @text;

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
	if ($req->config("delay")) {
	    my $delay = $req->config("delay");
	    if ($THR_avail) {
		require Time::HiRes;
		Time::HiRes::sleep( $delay );
	    } else {
		sleep int($delay) || 1;
	    }
	}

    }
    return @translated;
}

1;

