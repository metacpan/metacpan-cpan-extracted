use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;

use IO::Async::Loop;
use IO::AsyncX::Sendfile;

use Digest::SHA;

my $input = File::Temp::tmpnam;
my $sha1;
{
	END { unlink $input }
	open my $fh, '>', $input or die "could not open data file $input - $!";
	my $digest = Digest::SHA->new('sha1');
	my $data = join '', map chr(rand(256)), 1..1024;
	for(1..2 * 1024) {
		$digest->add($data);
		$fh->print($data) or die $!
	}
	$sha1 = $digest->hexdigest;
	$fh->close or die $!;
}
my $sock_file = File::Temp::tmpnam;
# remove it immediately, since we want to create a socket instead
unlink $sock_file;

my $loop = IO::Async::Loop->new;
my $listener = $loop->listen(
	addr => {
		family => 'unix',
		socktype => 'stream',
		path => $sock_file,
	},
	on_stream => sub {
		my $stream = shift;
		isa_ok($stream, 'IO::Async::Stream');
		$stream->configure(
			on_read => sub {
				my ($self, $buffref, $eof) = @_;
				warn "read from client\n";
				$$buffref = '';
				return 0;
			},
		);
		$loop->add($stream);
		can_ok($stream, 'sendfile');
		$stream->sendfile(
			file => $input,
		)->on_done(sub {
			note "File send complete: @_\n";
			$stream->close;
		});
	}
);
$listener->get;
use Future::Utils qw(fmap0);
is(exception {
	(fmap0 {
		my $f = $loop->new_future;
		$loop->connect(
			addr => {
				family => 'unix',
				socktype => 'stream',
				path => $sock_file,
			},
			on_stream => sub {
				my $stream = shift;
				isa_ok($stream, 'IO::Async::Stream');
				my $total = 0;
				my $digest = Digest::SHA->new('sha1');
				$stream->configure(
					on_read => sub {
						my ($self, $buffref, $eof) = @_;
						$digest->add($$buffref);
						$total += length($$buffref);
						$$buffref = '';
						$f->done($total, $digest->hexdigest) if $eof;
						return 0;
					}
				);
				$loop->add($stream);
			},
			on_resolve_error => sub { die "Cannot resolve - $_[-1]\n"; },
			on_connect_error => sub { die "Cannot connect - $_[0] failed $_[-1]\n"; },
		);
		$f->then(sub {
			my ($total, $hash) = @_;
			is($total, (-s $input), 'total transferred matches input file');
			is($hash, $sha1, 'SHA1 matches input file');
			Future->done
		})
	} concurrent => 4, foreach => [1..32])->get;
}, undef, 'no exception');

unlink $sock_file or die $!;
done_testing;

