package t::Util;
use strict;
use warnings;
use utf8;
use Docopt;
use boolean;
use Test::More;
use Data::Dumper;

use parent qw(Exporter);

our @EXPORT = qw(transform Option Argument Command Optional Either Required OneOrMore OptionsShortcut Tokens None True False is_deeply_ex);

sub transform { goto &Docopt::transform }

sub Option { Docopt::Option->new(@_) }
sub Argument { Docopt::Argument->new(@_) }
sub Command { Docopt::Command->new(@_) }

sub Optional { Docopt::Optional->new(\@_) }
sub Either { Docopt::Either->new(\@_) }
sub Required { Docopt::Required->new(\@_) }
sub OneOrMore { Docopt::OneOrMore->new(\@_) }
sub OptionsShortcut() { Docopt::OptionsShortcut->new(\@_) }

sub Tokens { Docopt::Tokens->new(\@_) }

sub None() { undef }
sub True() { true }
sub False() { false }

sub is_deeply_ex {
    my ($got, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    local $Data::Dumper::Purity=0;
    local $Data::Dumper::Terse=1;
    local $Data::Dumper::Deepcopy=1;
    local $Data::Dumper::Sortkeys=1;
    is_deeply(
        $got,
        $expected,
    ) or diag Dumper($got, $expected);
}

1;

