package MAGIC;

use strict;
use warnings;

use DynaLoader;
BEGIN {
    our $VERSION = '0.01';

    our @ISA;
    local @ISA;
    @ISA = 'DynaLoader';
    __PACKAGE__->bootstrap;
}

sub TIESCALAR {
    my ( $class ) = @_;
    bless do { \ my $scalar }, $class;
}
sub FETCH   { push @::MAGIC, [FETCH=>${$_[0]}]; ${$_[0]}         }
sub STORE   { push @::MAGIC, [STORE=>${$_[0]},$_[1]]; ${$_[0]} = $_[1] }
sub UNTIE {}
sub DESTROY {}

1;

__END__

=head1 NAME

MAGIC - Test class for use by Judy

