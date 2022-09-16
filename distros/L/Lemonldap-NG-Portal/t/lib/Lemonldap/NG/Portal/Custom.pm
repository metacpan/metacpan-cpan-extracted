package Lemonldap::NG::Portal::Custom;

sub empty {
    return '';
}

sub undefined {
    return undef;
}

sub test_uc {
    return uc( $_[0] . '_' . $_[1] );
}

1;
