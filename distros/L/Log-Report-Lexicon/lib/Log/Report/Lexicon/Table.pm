# This code is part of Perl distribution Log-Report-Lexicon version 1.15.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Lexicon::Table;{
our $VERSION = '1.15';
}


use warnings;
use strict;

use Log::Report 'log-report-lexicon';

#--------------------

sub new(@)  { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($) { $_[0] }

#--------------------

#--------------------

sub msgid($;$)   {panic "not implemented"}
sub msgstr($;$$) {panic "not implemented"}

#--------------------

sub add($)      {panic "not implemented"}


sub translations(;$) {panic "not implemented"}


sub pluralIndex($)
{	my ($self, $count) = @_;
	my $algo = $self->{algo}
		or error __x"there is no Plural-Forms field in the header, but needed";

	$algo->($count);
}


sub setupPluralAlgorithm()
{	my $self  = shift;
	my $forms = $self->header('Plural-Forms') or return;

	my $alg   = $forms =~ m/plural\=([n%!=><\s\d|&?:()]+)/ ? $1 : "n!=1";
	$alg =~ s/\bn\b/(\$_[0])/g;
	my $code  = eval "sub(\$) {$alg}";
	$@ and error __x"invalid plural-form algorithm '{alg}'", alg => $alg;
	$self->{algo}     = $code;

	$self->{nplurals} = $forms =~ m/\bnplurals\=(\d+)/ ? $1 : 2;
	$self;
}


sub nrPlurals() { $_[0]->{nplurals} }


sub header($@)
{	my ($self, $field) = @_;
	my $header = $self->msgid('') or return;
	$header =~ m/^\Q$field\E\:\s*([^\n]*?)\;?\s*$/im ? $1 : undef;
}

1;
