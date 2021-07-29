package Lemonldap::NG::Handler::Main::SharedVariables;

our $VERSION = '2.0.12';

# Since handler has no instance but only static classes, this module provides
# classes properties with accessors

package Lemonldap::NG::Handler::Main;

use strict;

BEGIN {
# Thread shared properties (if threads are available: needs to be loaded elsewhere)
    our $_tshv = {
        tsv         => {},
        cfgNum      => 0,
        cfgDate     => 0,
        lastCheck   => 0,
        checkTime   => 600,
        confAcc     => {},
        logger      => {},
        userLogger  => {},
        lmConf      => {},
        localConfig => {},
    };

    # Current sessions properties
    our $_v = { data => {}, dataUpdate => {}, };

    # Thread shared accessors
    foreach ( keys %$_tshv ) {
        eval " sub $_ {
            my \$v = \$_[1];
            \$_tshv->{$_} = \$v if (defined \$v);
            return \$_tshv->{$_};
        }";
        die $@ if ($@);
    }

    # Current session accessors
    eval "threads::shared::share(\$_tshv);";
    foreach ( keys %$_v ) {
        eval " sub $_ {
            my \$v = \$_[1];
            \$_v->{$_} = \$v if (\$v);
            return \$_v->{$_};
        }";
        die $@ if ($@);
    }
}

1;
