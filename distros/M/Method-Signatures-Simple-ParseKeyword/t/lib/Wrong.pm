package Wrong;

use Method::Signatures::Simple::ParseKeyword;
method new {
    bless {}, $self;
}
method grub ($me, @foo, $bar) {
    return "$me . $$bar";
}

1;
