package Dist::Surveyor::DB_File;

use strict;
use warnings;
use Storable qw(freeze thaw);

our $VERSION = '0.023';

our @ISA;
if    (eval { require DB_File;   1; }) {
    @ISA = ('DB_File');

}
elsif (eval { require SDBM_File; 1; }) {
    @ISA = ('SDBM_File');
}
else {
    die "Need either DB_file or SDBM_File installed to run";
}

# DB_File can store only strings as values, and not Perl structures
# this small wrapper fixes the problem

sub STORE {
    my ($self, $key, $val) = @_;
    $self->SUPER::STORE($key, freeze($val));
}

sub FETCH {
    my ($self, $key) = @_;
    my $val = $self->SUPER::FETCH($key);
    return thaw($val);
}

return 1;
