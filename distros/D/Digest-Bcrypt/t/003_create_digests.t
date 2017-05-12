use strict;
use warnings;

use Digest;
use Digest::Bcrypt;
use Test::More;
use Try::Tiny qw( try catch );

my $secret = "Super Secret Squirrel";
my $salt   = "   known salt   ";
my $cost   = 1;

# Object is reset after each hash is generated
my $direct = Digest::Bcrypt->new;
isa_ok($direct, 'Digest::Bcrypt', 'new: direct dist use syntax');
my $indirect = Digest->new('Bcrypt');
isa_ok($direct, 'Digest::Bcrypt', 'new: indirect dist use via Digest');

{ # direct binary
    my $res = try {
        $direct->add($secret);
        is($direct->{_buffer}, $secret, 'direct binary: buffer set correctly');
        $direct->salt($salt);
        is($direct->salt(), $salt, 'direct binary: salt set correctly');
        $direct->cost($cost);
        is($direct->cost(), '01', 'direct binary: cost set correctly');
        ok($direct->digest, "Creates Binary Digest");
        return '';
    } catch { return "Error: $_" };
    is($res, '', 'direct binary: no errors trapped');
    is($direct->{_buffer}, '', 'direct binary: buffer emptied after');
    is($direct->salt(), undef, 'direct binary: salt emptied after');
    is($direct->cost(), undef, 'direct binary: cost empted after');
}

{ # direct hex
    my $res = try {
        $direct->add($secret);
        is($direct->{_buffer}, $secret, 'direct hex: buffer set correctly');
        $direct->salt($salt);
        is($direct->salt(), $salt, 'direct hex: salt set correctly');
        $direct->cost($cost);
        is($direct->cost(), '01', 'direct hex: cost set correctly');
        return $direct->hexdigest;
    } catch { return "Error: $_" };
    is($res, '7ca73fd67f694324bcad7b0910093ff8ef9e8c564e2297', "direct hex: proper value");
    is($direct->{_buffer}, '', 'direct hex: buffer emptied after');
    is($direct->salt(), undef, 'direct hex: salt emptied after');
    is($direct->cost(), undef, 'direct hex: cost empted after');
}

{ # direct b64
    my $res = try {
        $direct->add($secret);
        is($direct->{_buffer}, $secret, 'direct b64: buffer set correctly');
        $direct->salt($salt);
        is($direct->salt(), $salt, 'direct b64: salt set correctly');
        $direct->cost($cost);
        is($direct->cost(), '01', 'direct b64: cost set correctly');
        return $direct->b64digest;
    } catch { return "Error: $_" };
    is($res, 'fKc/1n9pQyS8rXsJEAk/+O+ejFZOIpc', "direct b64: proper value");
    is($direct->{_buffer}, '', 'direct b64: buffer emptied after');
    is($direct->salt(), undef, 'direct b64: salt emptied after');
    is($direct->cost(), undef, 'direct b64: cost empted after');
}

{ # direct bcrypt_b64
    my $res = try {
        $direct->add($secret);
        is($direct->{_buffer}, $secret, 'direct bcrypt_b64: buffer set correctly');
        $direct->salt($salt);
        is($direct->salt(), $salt, 'direct bcrypt_b64: salt set correctly');
        $direct->cost($cost);
        is($direct->cost(), '01', 'direct bcrypt_b64: cost set correctly');
        return $direct->bcrypt_b64digest;
    } catch { return "Error: $_" };
    is($res, 'dIa9zl7nOwQ6pVqHC.i98M8chDXMGna', "direct bcrypt_b64: proper value");
    is($direct->{_buffer}, '', 'direct bcrypt_b64: buffer emptied after');
    is($direct->salt(), undef, 'direct bcrypt_b64: salt emptied after');
    is($direct->cost(), undef, 'direct bcrypt_b64: cost empted after');
}

{ # indirect binary
    my $res = try {
        $indirect->add($secret);
        is($indirect->{_buffer}, $secret, 'indirect binary: buffer set correctly');
        $indirect->salt($salt);
        is($indirect->salt(), $salt, 'indirect binary: salt set correctly');
        $indirect->cost($cost);
        is($indirect->cost(), '01', 'indirect binary: cost set correctly');
        ok($indirect->digest, "indirect binary: digest created");
        return '';
    } catch { return "Error: $_" };
    is($res, '', 'indirect binary: no errors trapped');
    is($indirect->{_buffer}, '', 'indirect binary: buffer emptied after');
    is($indirect->salt(), undef, 'indirect binary: salt emptied after');
    is($indirect->cost(), undef, 'indirect binary: cost empted after');
}

{ # indirect hex
    my $res = try {
        $indirect->add($secret);
        is($indirect->{_buffer}, $secret, 'indirect hex: buffer set correctly');
        $indirect->salt($salt);
        is($indirect->salt(), $salt, 'indirect hex: salt set correctly');
        $indirect->cost($cost);
        is($indirect->cost(), '01', 'indirect hex: cost set correctly');
        return $indirect->hexdigest;
    } catch { return "Error: $_" };
    is($res, '7ca73fd67f694324bcad7b0910093ff8ef9e8c564e2297', "indirect hex: proper value");
    is($indirect->{_buffer}, '', 'indirect hex: buffer emptied after');
    is($indirect->salt(), undef, 'indirect hex: salt emptied after');
    is($indirect->cost(), undef, 'indirect hex: cost empted after');
}

{ # indirect b64
    my $res = try {
        $indirect->add($secret);
        is($indirect->{_buffer}, $secret, 'indirect b64: buffer set correctly');
        $indirect->salt($salt);
        is($indirect->salt(), $salt, 'indirect b64: salt set correctly');
        $indirect->cost($cost);
        is($indirect->cost(), '01', 'indirect b64: cost set correctly');
        return $indirect->b64digest;
    } catch { return "Error: $_" };
    is($res, 'fKc/1n9pQyS8rXsJEAk/+O+ejFZOIpc', "indirect b64: proper value");
    is($indirect->{_buffer}, '', 'indirect b64: buffer emptied after');
    is($indirect->salt(), undef, 'indirect b64: salt emptied after');
    is($indirect->cost(), undef, 'indirect b64: cost empted after');
}

{ # indirect bcrypt_b64
    my $res = try {
        $indirect->add($secret);
        is($indirect->{_buffer}, $secret, 'indirect bcrypt_b64: buffer set correctly');
        $indirect->salt($salt);
        is($indirect->salt(), $salt, 'indirect bcrypt_b64: salt set correctly');
        $indirect->cost($cost);
        is($indirect->cost(), '01', 'indirect bcrypt_b64: cost set correctly');
        return $indirect->bcrypt_b64digest;
    } catch { return "Error: $_" };
    is($res, 'dIa9zl7nOwQ6pVqHC.i98M8chDXMGna', "indirect bcrypt_b64: proper value");
    is($indirect->{_buffer}, '', 'indirect bcrypt_b64: buffer emptied after');
    is($indirect->salt(), undef, 'indirect bcrypt_b64: salt emptied after');
    is($indirect->cost(), undef, 'indirect bcrypt_b64: cost empted after');
}

done_testing();
