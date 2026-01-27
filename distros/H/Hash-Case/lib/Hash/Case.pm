# This code is part of Perl distribution Hash-Case version 1.07.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2002-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Hash::Case;{
our $VERSION = '1.07';
}


use Tie::Hash;  # Tie::StdHash is a hidden package inside this :-(
use base 'Tie::StdHash';

use warnings;
use strict;

use Carp       qw/croak/;

#--------------------

sub TIEHASH(@)
{	my $class = shift;
	my $to    = @_ % 2 ? shift : undef;
	my %opts  = (@_, add => $to);
	(bless {}, $class)->init( \%opts );
}

# Used for case-insensitive hashes which do not need more than
# one hash.
sub native_init($)
{	my ($self, $args) = @_;
	my $add = delete $args->{add};

	   if(!$add)               { ; }
	elsif(ref $add eq 'ARRAY') { $self->addPairs(@$add) }
	elsif(ref $add eq 'HASH')  { $self->addHashData($add)  }
	else { croak "cannot initialize the native hash this way" }

	$self;
}

# Used for case-insensitive hashes which are implemented around
# an existing hash.
sub wrapper_init($)
{	my ($self, $args) = @_;
	my $add = delete $args->{add};

	   if(!$add)               { ; }
	elsif(ref $add eq 'ARRAY') { $self->addPairs(@$add) }
	elsif(ref $add eq 'HASH')  { $self->setHash($add)  }
	else { croak "cannot initialize a wrapping hash this way" }

	$self;
}

#-----------

sub addPairs(@)
{	my $self = shift;
	$self->STORE(shift, shift) while @_;
	$self;
}


sub addHashData($)
{	my ($self, $data) = @_;
	while(my ($k, $v) = each %$data) { $self->STORE($k, $v) }
	$self;
}


sub setHash($)
{	my ($self, $hash) = @_;   # the native implementation is the default.
	%$self = %$hash;
	$self;
}

1;
