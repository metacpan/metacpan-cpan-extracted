package JQ::Lite::Util;

use strict;
use warnings;

use JSON::PP ();
use List::Util qw(sum min max);
use Scalar::Util qw(looks_like_number);
use MIME::Base64 qw(encode_base64 decode_base64);
use Encode qw(encode is_utf8);
use B ();
use JQ::Lite::Expression ();
use JQ::Lite::Error ();

require JQ::Lite::Util::Parsing;
require JQ::Lite::Util::Paths;
require JQ::Lite::Util::Transform;

my $decode_json_impl = \&_decode_json;
{
    no warnings 'redefine';
    *_decode_json = sub {
        my @args = @_;
        my $want_structured = (caller)[0] eq 'JQ::Lite';
        return $decode_json_impl->(@args) unless $want_structured;

        my ($value, $ok, $err);
        {
            local $@;
            $ok = eval {
                $value = $decode_json_impl->(@args);
                1;
            };
            $err = $@;
        }
        return $value if $ok;
        die $err if ref($err) && eval { $err->isa('JQ::Lite::Error') };
        die JQ::Lite::Error::Input->new(message => $err);
    };
}

my $expression_evaluate_impl = \&JQ::Lite::Expression::evaluate;
{
    no warnings 'redefine';
    *JQ::Lite::Expression::evaluate = sub {
        my ($value, $ok, $err);
        {
            local $@;
            $ok = eval {
                $value = [ $expression_evaluate_impl->(@_) ];
                1;
            };
            $err = $@;
        }
        return @{$value} if $ok;
        die $err if ref($err) && eval { $err->isa('JQ::Lite::Error') };
        die JQ::Lite::Error::Evaluation->new(message => $err);
    };
}

1;
