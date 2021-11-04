package main;

use strict;
use warnings;
use utf8;
use open ":std", OUT => ":utf8";
use feature qw(:5.10);

use Carp;
use Test::More;
use Test::Exception;

use Env qw(LC_ALL LC_CTYPE LC_COLLATE LANG);

BEGIN {
    use POSIX ":locale_h";
    my $locale = "en_US.UTF-8";
    if (setlocale(+LC_ALL, $locale)) {
        $LC_ALL = $LC_CTYPE = $LC_COLLATE = $LANG = $locale;
    } else {
        warn "$0: Can't setlocale(LC_ALL, '$locale'): $!";
    }
}

$|++;

my @Pragmata = (
    [ strict      => undef ],
    [ warnings    => undef ],
    [ utf8        => undef ],
    [ open        => [qw(:std OUT :utf8)] ],
    [ feature     => [qw(:5.10)] ],
);

my %Required = map { $_ => 1 } qw(strict warnings utf8 open feature);

sub t::setup::import {
    my($invocant, @args) = @_;
    for my $prag_pair (@args ? @args : @Pragmata) { 
        my($pragma, $imports) = @$prag_pair;
        unless ($Required{$pragma}++) {
            local($@, $!, $^E, $^W, @SIG{<__{DIE,WARN}__>});
            eval qq{require $pragma; 1} || die;
        }
        $pragma->import( $imports ? @$imports : () );
    }
}

use vars qw(@LIBDIRS);

BEGIN {
   @LIBDIRS = qw(lib t/lib);
}

use lib @LIBDIRS;

use FindApp::Test::Unwarned;
use FindApp::Test::Utils ":all";

$SIG{__DIE__} = \&hail_mary;

sub hail_mary {
    return if $^S;
    confess "EXCEPTION CAUGHT: @_";

};

1;
