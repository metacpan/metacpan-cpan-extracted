use strict;
use Test::More;
use Eixo::Zone::Artifact;
use Eixo::Zone::Resume;

my $a = Eixo::Zone::Artifact->new;

my $resume  = Eixo::Zone::Resume->new;

$resume->addArtifact($a);

is(	ref($resume->getArtifacts(type=>'Eixo::Zone::Artifact')), 

	"Eixo::Zone::Artifact",

	"Artifacts can be retrieved"

);

done_testing;
