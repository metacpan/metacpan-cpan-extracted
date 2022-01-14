use v5.10;
use strict;
use warnings;

package Meta {

    sub new {
        return bless {}, __PACKAGE__;
    }
   sub AUTOLOAD {
        return Meta::Void->new;
    }
}

package Meta::Void {
    sub new {
        bless [], __PACKAGE__;
    }

    sub AUTOLOAD {
        return __PACKAGE__->new(  );
    }
}

Meta->new;
