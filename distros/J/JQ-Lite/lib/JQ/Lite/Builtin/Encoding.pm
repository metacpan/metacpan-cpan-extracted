package JQ::Lite::Builtin::Encoding;

use strict;
use warnings;

use JQ::Lite::Util ();

sub register {
    my ($class, $register) = @_;

    my %builtins = (
        '@json'    => \&JQ::Lite::Util::_apply_tojson,
        '@csv'     => \&JQ::Lite::Util::_apply_csv,
        '@tsv'     => \&JQ::Lite::Util::_apply_tsv,
        '@base64'  => \&JQ::Lite::Util::_apply_base64,
        '@base64d' => \&JQ::Lite::Util::_apply_base64d,
        '@uri'     => \&JQ::Lite::Util::_apply_uri,
    );
    for my $name (sort keys %builtins) {
        my $function = $builtins{$name};
        $register->([$name, "$name()"], sub {
            my ($owner, $inputs) = @_;
            return [ map { $function->($_) } @{$inputs} ];
        });
    }
}

1;
