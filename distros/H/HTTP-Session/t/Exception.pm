use strict;
use warnings;
use utf8;

package t::Exception;
use Exporter;
use base qw/Exporter/;

our @EXPORT = qw/throws_ok lives_ok/;

sub throws_ok(&$) {
    eval { $_[0]->() };
    ::like($@, $_[1]);
}

sub lives_ok(&;$) {
    eval { $_[0]->() };
    ::ok(!$@, $_[1]);
}

1;

