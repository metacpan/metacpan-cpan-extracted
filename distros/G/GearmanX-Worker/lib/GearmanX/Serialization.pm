package GearmanX::Serialization;

use Storable qw(nfreeze thaw);


sub _serialize {
    my $p = shift;
    my $m = shift || 'storable';
    die "serialization '$m' not yet supported" unless $m eq 'storable';

    if (ref ($p) eq 'ARRAY') {                                                       # one parameter, but a reference => freeze the list
	return 'A'.nfreeze $p;
    } elsif (ref ($p) eq 'HASH') {                                                   # one parameter, but a reference => freeze the list
	return 'H'.nfreeze $p;
    } else {                                                                             # there is only one scalar, leave that
	return $p;
    }
}

sub _deserialize {
    my $s = shift;
    my $m = shift || 'storable';
    die "serialization '$m' not yet supported" unless $m eq 'storable';

    if ($$s =~ /^A(.*)/s) {
	return thaw ($1);                                                                  # take the whole list
    } elsif ($$s =~ /^H(.*)/s) {
	return thaw ($1);                                                                  # take the whole hash
    } else {
	return $$s;                                                                        # only take the scalar
    }
}

"against all gods";
