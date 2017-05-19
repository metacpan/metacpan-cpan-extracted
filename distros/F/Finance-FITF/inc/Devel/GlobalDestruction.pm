#line 1
#!/usr/bin/perl

package Devel::GlobalDestruction;

use strict;
use warnings;

use XSLoader;

our $VERSION = '0.03';

use Sub::Exporter -setup => {
	exports => [ qw(in_global_destruction) ],
	groups  => { default => [ -all ] },
};

if ($] >= 5.013007) {
    eval 'sub in_global_destruction () { ${^GLOBAL_PHASE} eq q[DESTRUCT] }';
}
else {
    XSLoader::load(__PACKAGE__, $VERSION);
}

__PACKAGE__

__END__

#line 90


