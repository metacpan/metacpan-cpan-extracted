# $Id: bad-single-word-compiler.t,v 1.2 2008/02/07 14:16:39 drhyde Exp $

use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

use Test::More;

plan tests => 1;

use Config;
BEGIN {
    eval 'use Mock::Config;';
    warnings->unimport('redefine') if $] >= 5.006;
    unless (defined($ActivePerl::VERSION) && $Config{cc} =~ /\bgcc\b/) {
        if (!$Mock::Config::VERSION) {
            plan skip_all => "XSConfig is readonly"
                if $Config{usecperl} or exists &Config::KEYS;
            *Config::STORE = sub { $_[0]->{$_[1]} = $_[2] }
        }
    }
}

if ($Mock::Config::VERSION) {
    Mock::Config->import(cc => "flibbertigibbet");
}
elsif (defined($ActivePerl::VERSION) && $Config{cc} =~ /\bgcc\b/) {
    my $obj = tied %Config::Config;
    $obj->{cc} = "flibbertigibbet";
}
else {
    eval { $Config{cc} = 'flibbertigibbet' };
}

SKIP: {
    skip "Couldn't update %Config", 1 if $@ =~ /%Config::Config is read-only/;
    eval "use Devel::CheckLib";
    ok($@ =~ /^Couldn't find your C compiler/, "Bad single-word compiler is not OK");
}
