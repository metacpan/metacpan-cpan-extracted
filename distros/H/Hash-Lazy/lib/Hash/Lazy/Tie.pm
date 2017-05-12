package Hash::Lazy::Tie;
use strict;
use warnings;

BEGIN {
    require Tie::Hash;
    our @ISA = qw(Tie::ExtraHash);
}

use Carp qw(confess);
use self;

use constant USAGE   => 'my %h; tie %h, "Hash::Lazy::Tie", $builder, \%h;';

use constant STORAGE => 0;
use constant BUILDER => 1;
use constant TIED    => 2;

sub TIEHASH {
    my ($builder, $tied) = @args;

    confess "The use of Hash::Lazy::Tie requires passing the hash variable that it's tying to. Usage: " . USAGE
        unless defined($tied);

    return bless [{}, $builder, $tied], $self;
}

sub FETCH {
    my ($key) = @args;

    return $self->[STORAGE]{$key} if exists $self->[STORAGE]{$key};

    my $ret = $self->[BUILDER]->($self->[TIED], $key);
    $self->[STORAGE]{$key} = $ret unless exists $self->[STORAGE]{$key};
    return $self->[STORAGE]{$key};
}

1;
