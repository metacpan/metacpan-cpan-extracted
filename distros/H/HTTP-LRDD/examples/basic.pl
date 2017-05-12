use Data::Dumper;
use HTTP::LRDD;
use RDF::TrineX::Functions -shortcuts;

my $lrdd = HTTP::LRDD->new;
my $output = {};
foreach my $uri (qw(acct:bradfitz@gmail.com acct:chris@chrisvannoy.com mailto:chris@chrisvannoy.com))
{
	warn "URI: $uri";
	my @r    = $lrdd->discover($uri);
	$output->{$uri}->{'descriptors'} = \@r;
	foreach my $d (@r)
	{
		my $model = $lrdd->parse($d);
		if ($model)
		{
			push @{$output->{$uri}->{'statement_counts'}}, $model->count_statements;
			# push @{$output->{$uri}->{'graphs'}}, $model->string;
		}
		else
		{
			push @{$output->{$uri}->{'statement_counts'}}, -1;
			# push @{$output->{$uri}->{'graphs'}}, '#';
		}
	}
}

print Dumper( $output );

# XRD::Parser::hostmeta - check HTTPS before HTTP.
