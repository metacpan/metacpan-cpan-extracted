=head1 PURPOSE

Tests that IO::Callback::HTTP can be used as a read filehandle.

=head1 CAVEATS

This test is skipped on MSWin32 because current versions of
L<Test::HTTP::Server> do not support that platform. Nevertheless,
L<IO::Callback::HTTP> is I<believed> to work on MSWin32.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008008;
use strict;

use lib "lib";
use lib "t/lib";

use Test::More;

BEGIN {
	plan skip_all => 'Test::HTTP::Server does not run on Windows'
		if $^O eq 'MSWin32'
};

use Test::HTTP::Server;
use HTTP::Request::Common qw(POST);
use IO::Callback::HTTP;

my $server = Test::HTTP::Server::->new;

my $fh = IO::Callback::HTTP::->new('<', $server->uri.'echo');

if (eval "use IO::Detect; 1")
{
	ok($fh->IO::Detect::is_filehandle, '$fh detected as a file handle');
}
else
{
	ok(1, 'dummy');
}

like(
	scalar <$fh>,
	qr{^GET /echo HTTP/1.[01]}i,
	'first line seems fine',
);

my $fh2 = IO::Callback::HTTP::->new('<', POST(
	$server->uri.'echo',
	Here_It_Is => 'Oh Yeah',
));

like(
	scalar <$fh2>,
	qr{^POST /echo HTTP/1.[01]}i,
	'first line seems fine',
);

my $found_it;
while (<$fh2>) { $found_it++ if m{Here-It-Is}i };

is($found_it => 1, 'another lines seems fine');

sub Test::HTTP::Server::Request::not_found {
	my $self = shift;
	$self->{out_code} = '404 Not Found';
	'Not found';
}

my $fh3 = IO::Callback::HTTP::->new(
	'<',
	POST( $server->uri.'not_found' ),
	failure => 'croak',
);

my $data = eval { <$fh3> };
like(
	$@,
	qr{HTTP POST request for \<\S+not_found\> failed: 404 Not Found},
	'failure callback works',
);
is(
	$! + 0,
	Errno::EIO + 0,
	'sets $! correctly',
);

done_testing;
