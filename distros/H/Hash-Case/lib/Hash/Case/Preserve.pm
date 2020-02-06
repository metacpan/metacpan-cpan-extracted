# Copyrights 2002-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Hash::Case.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Hash::Case::Preserve;
use vars '$VERSION';
$VERSION = '1.05';

use base 'Hash::Case';

use strict;
use warnings;
use Carp 'croak';


sub init($)
{   my ($self, $args) = @_;

    $self->{HCP_data} = {};
    $self->{HCP_keys} = {};

    my $keep = $args->{keep} || 'LAST';
    if($keep eq 'LAST')     { $self->{HCP_update} = 1 }
    elsif($keep eq 'FIRST') { $self->{HCP_update} = 0 }
    else
    {   croak "use 'FIRST' or 'LAST' with the option keep";
    }

    $self->SUPER::native_init($args);
}

# Maintain two hashes within this object: one to store the values, and
# one to preserve the casing.  The main object also stores the options.
# The data is kept under lower cased keys.

sub FETCH($) { $_[0]->{HCP_data}{lc $_[1]} }

sub STORE($$)
{   my ($self, $key, $value) = @_;
    my $lckey = lc $key;

    $self->{HCP_keys}{$lckey} = $key
        if $self->{HCP_update} || !exists $self->{HCP_keys}{$lckey};

    $self->{HCP_data}{$lckey} = $value;
}

sub FIRSTKEY
{   my $self = shift;
    my $a = scalar keys %{$self->{HCP_keys}};
    $self->NEXTKEY;
}

sub NEXTKEY($)
{   my $self = shift;
    if(my ($k, $v) = each %{$self->{HCP_keys}})
    {    return wantarray ? ($v, $self->{HCP_data}{$k}) : $v;
    }
    else { return () }
}

sub EXISTS($) { exists $_[0]->{HCP_data}{lc $_[1]} }

sub DELETE($)
{   my $lckey = lc $_[1];
    delete $_[0]->{HCP_keys}{$lckey};
    delete $_[0]->{HCP_data}{$lckey};
}

sub CLEAR()
{   %{$_[0]->{HCP_data}} = ();
    %{$_[0]->{HCP_keys}} = ();
}

1;
