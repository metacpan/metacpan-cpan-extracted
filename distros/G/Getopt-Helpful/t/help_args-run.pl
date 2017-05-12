use Getopt::Helpful;
my $hopt = Getopt::Helpful->new(
	usage => 'perl CALLER',
	['this', \$this, '', 'this is this'],
	['that', \$that, '', 'that is that'],
	'+help'
	);
$hopt->Get();
