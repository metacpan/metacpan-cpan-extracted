# Copyrights 2002-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Hash::Case.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Hash::Case;
use vars '$VERSION';
$VERSION = '1.03';


use warnings;
use strict;

use Tie::Hash;  # contains Tie::StdHash
use base 'Tie::StdHash';

use Log::Report 'hash-case';


sub TIEHASH(@)
{   my $class = shift;
    my $to    = @_ % 2 ? shift : undef;
    my %opts  = (@_, add => $to);
    (bless {}, $class)->init( \%opts );
}

# Used for case-insensitive hashes which do not need more than
# one hash.
sub native_init($)
{   my ($self, $args) = @_;
    my $add = delete $args->{add};

       if(!$add)               { ; }
    elsif(ref $add eq 'ARRAY') { $self->addPairs(@$add) }
    elsif(ref $add eq 'HASH')  { $self->addHashData($add)  }
    else { error "cannot initialize the native hash this way" }

    $self;
}

# Used for case-insensitive hashes which are implemented around
# an existing hash.
sub wrapper_init($)
{   my ($self, $args) = @_;
    my $add = delete $args->{add};

       if(!$add)               { ; }
    elsif(ref $add eq 'ARRAY') { $self->addPairs(@$add) }
    elsif(ref $add eq 'HASH')  { $self->setHash($add)  }
    else { error "cannot initialize a wrapping hash this way" }

    $self;
}


sub addPairs(@)
{   my $self = shift;
    $self->STORE(shift, shift) while @_;
    $self;
}


sub addHashData($)
{   my ($self, $data) = @_;
    while(my ($k, $v) = each %$data) { $self->STORE($k, $v) }
    $self;
}


sub setHash($)
{   my ($self, $hash) = @_;   # the native implementation is the default.
    %$self = %$hash;
    $self;
}

1;
