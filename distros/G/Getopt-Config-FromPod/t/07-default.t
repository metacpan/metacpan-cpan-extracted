use Test::More tests => 4;
use Test::Exception;

use_ok 'Getopt::Config::FromPod';

{ 
	my $dat = <<EOF;
\=pod

\=head1

\=over 4

\=item C<-h>

\=for getopt 'h'

\=item C<-v> E<lt>levelE<gt>

\=for getopt 'v:'

\=back
EOF
	open my $fh, '<', \$dat;
	Getopt::Config::FromPod->set_class_default(-file => $fh);
	is(Getopt::Config::FromPod->string(), 'hv:', 'string');
	close $fh;
}

my $expected = [
	'h', 'v:', 
	[ 'server|s=s', "the server to connect to" ],
	[ 'port|p=i',   "the port to connect to", { default => 79 } ],
];
is_deeply(Getopt::Config::FromPod->arrayref(-file => 't/test.pod'), $expected, 'arrayref with external file');

$expected = {
	'-h' => 'help',
	'-f:' => 'filename',
};
Getopt::Config::FromPod->set_class_default(-tag => 'getopts');
is_deeply(Getopt::Config::FromPod->hashref, $expected, 'hashref with default');

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
