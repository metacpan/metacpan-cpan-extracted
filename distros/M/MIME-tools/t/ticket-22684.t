#!/usr/bin/perl
use Test::More tests => 3;
use MIME::Decoder;
use IO::File;

# Ticket 22684 - use select() for IO multiplexing (to prevent filter() deadlock)

SKIP: {
	skip "Need Proc::ProcessTable for this test", 3 unless eval "use Proc::ProcessTable; 1;";

require MIME::Decoder::Gzip64;
install MIME::Decoder::Gzip64 'x-gzip64';

my $input_data = '';
for(1..(1024 * 512)) {
	$input_data .= chr(int(rand(256)));
}
my $input_fh   = IO::File->new(\$input_data, '<:scalar');

my $output_data = '';
my $output_fh   = IO::File->new(\$output_data, '>:scalar');

my $decoder = MIME::Decoder->new('x-gzip64');
eval {
	local $SIG{ALRM} = sub { die 'timeout' };
	alarm(20);
	$decoder->encode( $input_fh, $output_fh );
	alarm(0);
};
my $error = '';
my $bad_kids = 0;
if( $@ ) {
	$error = $@; 

	my $pt = Proc::ProcessTable->new();
	my @children = grep { $_->ppid == $$ } @{$pt->table()};
	foreach my $c (@children) {
		diag('Killing wayward child '. $c->pid . ' (' . $c->cmndline . ')');
		kill('TERM', $c->pid);
		$bad_kids++;
	}
}

# If we didn't deadlock, we should complete in a timely manner and produce
# output.  MIME-encoded gzipped randomness should be nearly as large, if not
# larger, than the input data.
unlike( $error, qr/^timeout/, '->encode completed within 20s');
is( $bad_kids, 0, 'No wayward gzip children');
cmp_ok( length($output_data), '>=', 400_000, 'Output data was generated');

}
