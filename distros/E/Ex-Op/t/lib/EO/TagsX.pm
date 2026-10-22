package EO::TagsX;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT      = qw(a1 &a2 $sa);
our @EXPORT_OK   = qw(b1 b2 is_x is_y _priv @arr %hsh risky risky2 c1);
our %EXPORT_TAGS = (
    both  => [qw(a1 b1)],
    is    => [qw(is_x is_y)],
    vars  => [qw($sa @arr %hsh)],
    empty => [],
    nonok => [qw(notlisted)],
);
our @EXPORT_FAIL = qw(risky risky2);
our @FAILED;

sub export_fail {
    my $class = shift;
    push @FAILED, [@_];
    return grep { $_ eq 'risky' || $_ eq '&risky' } @_;
}

sub a1 { 'a1' } sub a2 { 'a2' } sub b1 { 'b1' } sub b2 { 'b2' } sub c1 { 'c1' }
sub is_x { 'is_x' } sub is_y { 'is_y' } sub _priv { '_priv' }
sub risky { 'risky' } sub risky2 { 'risky2' }

our $sa  = 'sa';
our @arr = (1);
our %hsh = (k => 1);

1;
