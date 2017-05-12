use Test::More tests => 5;
use Test::Exception;

use_ok 'Getopt::Config::FromPod';

my $p;
lives_ok { $p = Getopt::Config::FromPod->new(-tag => 'getopts'); } 'create';

{ 
	my $dat = <<EOF;
\=pod

\=head1

\=over 4

\=item C<-h>

\=for getopts 'h'

\=item C<-v> E<lt>levelE<gt>

\=for getopts 'v:'

\=back
EOF
	open my $fh, '<', \$dat;
	is($p->string(-file => $fh), 'hv:', 'string');
	close $fh;
}

my $expected = [
	'h', 'v:', 
	[ 'server|s=s', "the server to connect to" ],
	[ 'port|p=i',   "the port to connect to", { default => 79 } ],
];
is_deeply($p->arrayref(-file => 't/test2.pod'), $expected, 'arrayref with external file');

$expected = {
	'-h' => 'help',
	'-f:' => 'filename',
};
is_deeply($p->hashref, $expected, 'hashref with default');

__END__

=head1 OPTIONS

=head2 C<-h>

=for getopts '-h', 'help'

=head1 REQUIRED ARGS

=over 4

=item C<-f> E<lt>fileE<gt>

=begin getopts

'-f:', 'filename'

=end getopts

=back
