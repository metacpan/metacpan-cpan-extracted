#!/usr/bin/env perl

# Creation date: 2007-04-08 20:50:44
# Authors: don

use strict;
use Test;

# main
{
    plan tests => 6;
    
    use JSON::DWIW;

    my $magic_scalar;
    tie $magic_scalar, 'DummyTiedScalar';
    my %magic_hash;
    tie %magic_hash, 'DummyTiedHash';
    my @magic_array;
    tie @magic_array, 'DummyTiedArray';

    my $data;
    my $str;

    $str = JSON::DWIW->to_json($magic_scalar);
    ok($str eq '"fetched_val"');
    
    $data = { var2 => $magic_scalar };
    $str = JSON::DWIW->to_json($data);
    ok($str eq '{"var2":"fetched_val"}');

    $str = JSON::DWIW->to_json(\%magic_hash);
    ok($str eq '{"var1":"val1"}');

    $data = { magic_hash => \%magic_hash };
    $str = JSON::DWIW->to_json($data);
    ok($str eq '{"magic_hash":{"var1":"val1"}}');

    $str = JSON::DWIW->to_json(\@magic_array);
    ok($str eq '[1,2,3,4]' or $str eq '["1","2","3","4"]');
    
    $data = { magic_array => \@magic_array };
    $str = JSON::DWIW->to_json($data);
    ok($str eq '{"magic_array":[1,2,3,4]}' or $str eq '{"magic_array":["1","2","3","4"]}');
    
}

exit 0;

###############################################################################
# Subroutines

{   package DummyTiedScalar;

    sub new {
        my $proto = shift;
        my $scalar;
        return bless \$scalar, ref($proto) || $proto;
    }

    sub TIESCALAR {
        my $proto = shift;
        return $proto->new(@_);
    }

    sub FETCH {
        my $self = shift;
        return 'fetched_val';
    }

    sub STORE {
        return;
    }

}

{   package DummyTiedHash;

    sub new {
        my $proto = shift;
        return bless { data => { var1 => 'val1' } }, ref($proto) || $proto;
    }

    sub TIEHASH {
        my $proto = shift;
        return $proto->new(@_);
    }

    sub FETCH {
        my $self = shift;
        my $key = shift;

        return $self->{data}{$key};
    }

    sub STORE {
        my ($self, $key, $value) = @_;

        $self->{data}{$key} = $value;

        return $value;
    }

    sub DELETE {
        my $self = shift;
        my $key = shift;

        delete $self->{data}{$key};
    }

    sub FIRSTKEY {
        my $self = shift;
        my $a = keys %{$self->{data}};
        return each %{$self->{data}};
    }

    sub NEXTKEY {
        my $self = shift;
        my $last_key = shift;
        return each %{$self->{data}};
    }
}

{   package DummyTiedArray;

    sub new {
        my $proto = shift;

        return bless { data => [ 1, 2, 3, 4 ] }, ref($proto) || $proto;
    }

    sub TIEARRAY {
        my $proto = shift;
        return $proto->new(@_);
    }

    sub FETCH {
        my $self = shift;
        my $index = shift;

        return $self->{data}[$index];
    }

    sub STORE {
        my ($self, $index, $value) = @_;

        $self->{data}[$index] = $value;
    }

    sub FETCHSIZE {
        my $self = shift;
        return scalar @{$self->{data}};
    }

    sub STORESIZE {
        my $self = shift;
        my $count = shift;

        return $count;
    }

    sub UNTIE {

    }
    
}

