package Inline::Nouse;

$VERSION = '0.04';

require Inline;
require Inline::Interp;
require Language::Nouse;

@ISA = qw(Inline Inline::Interp);

use strict;
use Carp;

my $g_io;

sub register {
	return {
		language => 'nouse',
		aliases => ['Nouse', 'nouse'],
		type => 'interpreted',
		suffix => 'ns',
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

sub get_char {
	return Inline::Interp::input_char($g_io);
}

sub put_char {
	my ($out) = @_;
	Inline::Interp::output_char($g_io, $out);
}

sub do_run {
	my ($code, $io) = @_;

	$g_io = $io;

	my $interp = new Language::Nouse;
	$interp->load_linenoise($code);
	$interp->set_get(\&get_char);
	$interp->set_put(\&put_char);

	$interp->run();
}

1;

__END__

=head1 NAME

Inline::Nouse - An Inline.pm interpreter for the Nouse language

=head1 SYNOPSIS

  use Inline 'Nouse' => 'function hello { #r<a>z+x>y^y+z>c>z>t:4+z#0^f>z>0?z^0+z>z+9<x#1+z:3>w>z#r+i^0>c>z>0 }';

  # prints "hello world"
  &hello;

=head1 DESCRIPTION

This module allows Nouse subs to be used directly within perl.
For more usage information, see L<Inline::Interp> and
L<Language::Nouse>, on which this module is based.

=head1 AUTHOR

Copyright (C) 2003, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<Inline>

L<Inline::Interp>

L<Language::Nouse>

L<http://code.iamcal.com/docs/nouse.html>

=cut
