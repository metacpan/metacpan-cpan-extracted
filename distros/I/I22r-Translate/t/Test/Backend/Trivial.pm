package Test::Backend::Trivial;
use Moose::Role;
#use I22r::Translate::Request;
use I22r::Translate::Result;
with 'I22r::Translate::Backend';

sub can_translate { 1 }
sub get_translations {
    my ($self, $req) = @_;
    for my $id (keys %{ $req->text }) {
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
    }
    return keys %{$req->results};
}

1;

