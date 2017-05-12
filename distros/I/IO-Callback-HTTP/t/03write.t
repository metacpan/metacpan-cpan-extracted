=head1 PURPOSE

Tests that IO::Callback::HTTP can be used as a write filehandle.

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

my $fh = IO::Callback::HTTP::->new(
	'>',
	$server->uri.'echo',
	success => \&success,
);

if (eval "use IO::Detect; 1")
{
	ok($fh->IO::Detect::is_filehandle, '$fh detected as a file handle');
}
else
{
	ok(1, 'dummy');
}

sub success
{
	like(
		shift->decoded_content,
		qr{^PUT /echo HTTP/1.[01]}i,
		'first line seems fine',
	);
}

my $fh2 = IO::Callback::HTTP::->new(
	'>',
	POST(
		$server->uri.'echo',
		Content_Type => 'text/plain',
	),
	success => \&success2,
);

sub success2
{
	my $x = shift;
	
	like(
		$x->decoded_content,
		qr{^POST /echo HTTP/1.[01]}i,
		'first line seems fine',
	);

	like(
		$x->decoded_content,
		qr{Hello World}i,
		'got body content',
	);
}

print $fh 'Hello World';
print $fh2 'Hello World';
close $fh;
close $fh2;

done_testing;
