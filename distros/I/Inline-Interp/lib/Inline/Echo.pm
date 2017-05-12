package Inline::Echo;

$VERSION = '0.01';

require Inline;
require Inline::Interp;

@ISA = qw(Inline Inline::Interp);

use strict;
use Carp;

sub register {
	return {
		language => 'Echo',
		aliases => ['Echo', 'echo'],
		type => 'interpreted',
		suffix => 'echo',
	};
}

sub do_load {
	my ($funcs, $code) = @_;

	while($code =~ m/function(\s+)([a-z0-9_]+)(\s*){(.*?)}/isg){
		Inline::Interp::add_func($funcs, $2, $4);
	}
}

sub load {
	Inline::Interp::load(@_);
}

sub do_run {
	my ($code, $io) = @_;

	Inline::Interp::output_char($io, $_) for split //, $code;
}

1;

__END__

=head1 NAME

Inline::Echo - A demo module using Inline::Interp

=head1 SYNOPSIS

  require Inline::Echo;

  use Inline 'Echo' => 'function hello{hello world}';

  # prints "hello world"
  &hello;

=head1 DESCRIPTION

This module is a demonstration of how to use Inline::Interp and is used
for testing Inline::Interp. It creates functions that echo their contents
using the IO layer.

=head1 AUTHOR

Copyright (C) 2003, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<Inline>
L<Inline::Interp>

=cut
