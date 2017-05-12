#!/usr/bin/perl -w
use strict;

use Test::More tests => 1;

use Devel::Platform::Info;
my $info = Devel::Platform::Info->new();
my $data = $info->get_info();

diag("OS: $^O");

if($data->{error}) {
    diag('error returned: ' . $data->{error});
    delete $data->{error};
}

isnt($data,undef);

if($data) {
    diag('.. source => ');
    diag("   .. $_ => " . (defined $data->{source}{$_} ? display_key($data->{source}{$_}) : ''))   for(sort keys %{$data->{source}});

    diag(".. $_ => " . (defined $data->{$_} ? $data->{$_} : ''))   for(grep {!/source/} keys %$data);
}

sub display_key {
	my $value = shift;

	if(ref $value eq 'ARRAY') {
		return join ', ', @$value;
	}
	return $value;
}
