use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

BEGIN {
    use_ok 'Digest' || BAIL_OUT("Can't use Digest");
    use_ok 'Digest::Bcrypt' || BAIL_OUT("Can't use Digest::Bcrypt");
};
can_ok('Digest::Bcrypt', qw(new add bcrypt_b64digest clone cost hexdigest salt settings digest reset));
my $salt   = "   known salt   ";
my $settings = '$2a$20$GA.eY03tb02ea0DqbA.eG.';

{ # new instance, no params
    my $db = try {
        Digest::Bcrypt->new();
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: no params');
}

{ # new instance, empty hashref
    my $db = try {
        Digest::Bcrypt->new({});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: empty hashref');
}

{ # new instance, cost as hash
    my $db = try {
        Digest::Bcrypt->new(cost => 20);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with cost 20');
    is($db->cost(), 20, 'cost: correct value of 20');
}

{ # new instance, cost as hashref
    my $db = try {
        Digest::Bcrypt->new({cost => 20});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with cost 20');
    is($db->cost(), 20, 'cost: correct value of 20');
}

{ # new instance, salt as hash
    my $db = try {
        Digest::Bcrypt->new(salt => $salt);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with salt');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, salt as hashref
    my $db = try {
        Digest::Bcrypt->new({salt => $salt});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with salt');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, settings as hash
    my $db = try {
        Digest::Bcrypt->new(settings => $settings);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with settings');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, settings as hashref
    my $db = try {
        Digest::Bcrypt->new({settings => $settings});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with settings');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, cost and salt as hash
    my $db = try {
        Digest::Bcrypt->new(cost=>20, salt => $salt);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with cost and salt');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, cost and salt as hashref
    my $db = try {
        Digest::Bcrypt->new({cost =>20, salt => $salt});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with cost and salt');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, cost and salt and settings as hash
    my $db = try {
        Digest::Bcrypt->new(cost=>22, salt => '                ', settings => $settings);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with cost and salt and settings');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, cost and salt and settings hashref
    my $db = try {
        Digest::Bcrypt->new({cost =>22, salt => '                ', settings => $settings});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with cost and salt and settings');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, empty string
    my $db = try {
        Digest::Bcrypt->new('');
    } catch {
        return "Couldn't create instance: $_";
    };
    like($db, qr/^Couldn't create instance:/, 'new: failed with empty string');
}

{ # new instance, undef value
    my $db = try {
        Digest::Bcrypt->new(undef);
    } catch {
        return "Couldn't create instance: $_";
    };
    like($db, qr/^Couldn't create instance:/, 'new: failed with undef value');
}

{ # new instance, deal with cost
    my $err = try {
        my $db = Digest::Bcrypt->new();
        $db->cost(20);
        is($db->cost(), 20, 'cost: properly set to 20');
        $db->cost(undef);
        is($db->cost(), undef, 'cost: properly set to undef');
        return '';
    } catch {
        return "Error: $_";
    };
    is($err, '', 'cost: no errors trapped');
}

{ # new instance, deal with salt
    my $err = try {
        my $db = Digest::Bcrypt->new();
        $db->salt($salt);
        is($db->salt(), $salt, 'salt: properly set to 20');
        $db->salt(undef);
        is($db->salt(), undef, 'salt: properly set to undef');
        return '';
    } catch {
        return "Error: $_";
    };
    is($err, '', 'salt: no errors trapped');
}


{ # new instance, no params
    my $db = try {
        Digest->new('Bcrypt');
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: no params');
}

{ # new instance, empty hashref
    my $db = try {
        Digest->new('Bcrypt',{});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: empty hashref');
}

{ # new instance, cost as hash
    my $db = try {
        Digest->new('Bcrypt', cost => 20);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with cost 20');
    is($db->cost(), 20, 'cost: correct value of 20');
}

{ # new instance, cost as hashref
    my $db = try {
        Digest->new('Bcrypt', {cost => 20});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with cost 20');
    is($db->cost(), 20, 'cost: correct value of 20');
}

{ # new instance, salt as hash
    my $db = try {
        Digest->new('Bcrypt', salt => $salt);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with salt');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, salt as hashref
    my $db = try {
        Digest->new('Bcrypt', {salt => $salt});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with salt');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, settings as hash
    my $db = try {
        Digest->new('Bcrypt', settings => $settings);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with settings');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, settings as hashref
    my $db = try {
        Digest->new('Bcrypt', {settings => $settings});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with settings');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, cost and salt as hash
    my $db = try {
        Digest->new('Bcrypt', cost=>20, salt => $salt);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with cost and salt');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, cost and salt as hashref
    my $db = try {
        Digest->new('Bcrypt', {cost =>20, salt => $salt});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with cost and salt');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
}

{ # new instance, cost and salt and settings as hash
    my $db = try {
        Digest->new('Bcrypt', cost=>22, salt => '                ', settings => $settings);
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hash with cost and salt and settings');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, cost and salt and settings as hashref
    my $db = try {
        Digest->new('Bcrypt', {cost=>22, salt => '                ', settings => $settings});
    } catch {
        return "Couldn't create instance: $_";
    };
    isa_ok($db, 'Digest::Bcrypt', 'new: hashref with cost and salt and settings');
    is($db->cost(), 20, 'cost: correct value');
    is($db->salt(), $salt, 'salt: correct value');
    is($db->settings(), $settings, 'settings: correct value');
}

{ # new instance, empty string
    my $db = try {
        Digest->new('Bcrypt', '');
    } catch {
        return "Couldn't create instance: $_";
    };
    like($db, qr/^Couldn't create instance:/, 'new: failed with empty string');
}

{ # new instance, undef value
    my $db = try {
        Digest->new('Bcrypt', undef);
    } catch {
        return "Couldn't create instance: $_";
    };
    like($db, qr/^Couldn't create instance:/, 'new: failed with undef value');
}

{ # new instance, deal with cost
    my $err = try {
        my $db = Digest->new('Bcrypt');
        $db->cost(20);
        is($db->cost(), 20, 'cost: properly set to 20');
        $db->cost(undef);
        is($db->cost(), undef, 'cost: properly set to undef');
        return '';
    } catch {
        return "Error: $_";
    };
    is($err, '', 'cost: no errors trapped');
}

{ # new instance, deal with salt
    my $err = try {
        my $db = Digest->new('Bcrypt');
        $db->salt($salt);
        is($db->salt(), $salt, 'salt: properly set to 20');
        $db->salt(undef);
        is($db->salt(), undef, 'salt: properly set to undef');
        return '';
    } catch {
        return "Error: $_";
    };
    is($err, '', 'salt: no errors trapped');
}

done_testing();
