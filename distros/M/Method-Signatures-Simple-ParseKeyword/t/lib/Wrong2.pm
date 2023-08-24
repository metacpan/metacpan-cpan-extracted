package Wrong2;

use Method::Signatures::Simple::ParseKeyword;
func grub ($me, ~foo, $bar) {
    return "$me . $$bar";
}

1;
