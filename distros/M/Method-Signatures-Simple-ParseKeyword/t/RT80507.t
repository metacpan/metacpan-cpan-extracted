use strict;
use warnings;

use Method::Signatures::Simple::ParseKeyword;
use Test::More;

{
    my $uniq = 0;

    method fresh_name() {
        $self->prefix . $uniq++
    }
}

method prefix() {
    $self->{prefix}
}

my $o = bless {prefix => "foo_" }, main::;
is $o->fresh_name, 'foo_0';
is $o->prefix, "foo_";
is __LINE__, 22;

done_testing;
__END__
