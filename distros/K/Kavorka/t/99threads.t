=pod

=encoding utf-8

=head1 PURPOSE

Check that Kavorka can be used on threaded Perls. Doesn't test any
actual functionality under threading; merely that Kavorka can be
loaded, and threads can be created.

=head1 AUTHOR

Aaron James Trevena E<lt>teejay@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Aaron James Trevena.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Config;
BEGIN {
	plan skip_all => "your perl does not support ithreads"
		unless $Config{useithreads};
};

use threads;

{
	package ThreadedExample;
	use Kavorka;
	use Moo;
	method foo {
		return { '$self' => $self, '@_' => \@_ };
	}
}

my $subref = sub {
	my $id = shift;
	note("id:$id");
	return $id;
};

my @threads;
my @idents = qw/bar1 bar2 bar3 bar4 bar5 bar6/;
foreach my $foo_id (@idents)
{
	push @threads, threads->create($subref, $foo_id);
}

my @results;
for my $thread (@threads) {
	note("joining thread $thread");
	push @results, $thread->join;
}

is_deeply(
	[ sort @results ],
	[ sort @idents ],
	'expected return values',
);

done_testing;
