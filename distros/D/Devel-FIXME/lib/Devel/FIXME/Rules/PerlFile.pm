#!/usr/bin/perl

package Devel::FIXME::Rules::PerlFile;
use base qw/Devel::FIXME/;

use Devel::FIXME qw/:constants/;

my @rules;
my $rulesfile;

BEGIN {
	my $base = $ENV{FIXME_RULEFILE} || "/.fixme/rules.pl";
	$rulesfile = $ENV{HOME} . $base;
}

sub rules {
	my $self = shift;

	if (!@rules){
		if (!$ENV{FIXME_NOFILTER} and -f $rulesfile){
			@rules = @{ require $rulesfile };
		} else {
			@rules = ( sub { return SHOUT } );
		}
	}

	return @rules;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Devel::FIXME::Rules::PerlFile - Support for rules stored as perl code in a file.

=head1 SYNOPSIS

	% vim ~/.fixme/rules.pl

=head1 DESCRIPTION

The file in the L<SYNOPSIS>, or the file specified by the C<FIXME_RULEFILE>
environment variable, needs to return an array reference, containing code
references.

These code references are the rules that are applied as methods on the fixme
object.

=head1 EXAMPLE

This is a really silly rules file, but it does show what you can do:

	[
		sub {
			my $self = shift;
			# discard any file that is writable (assume not checked in to SCM)
			return DROP unless -w $self->{file};
		},
		sub {
			my $self = shift;
			# any FIXME's in my dir are warned about
			return SHOUT if $self->{file} =~ m!my/src/dir/!;
		},
	];

The fixme object contains some fields. See L<Devel::FIXME>'s implementation.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICNESE

	Copyright (c) 2004 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Devel::FIXME>
