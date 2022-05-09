# $Id: multi-word-compiler.t,v 1.3 2008/02/07 14:16:39 drhyde Exp $

use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

use Test::More;

plan tests => 1;

use Config;
BEGIN {
    eval 'use Mock::Config;';
    warnings->unimport('redefine') if $] >= 5.006;
    unless(defined($ActivePerl::VERSION) && $Config{cc} =~ /\bgcc\b/) {
        if (!$Mock::Config::VERSION) {
            plan skip_all => "XSConfig is readonly"
                if $Config{usecperl} or exists &Config::KEYS;
            *Config::STORE = sub { $_[0]->{$_[1]} = $_[2] }
        }
    }
}

my $fake_cc = qq{"$^X" $Config{cc}};
if ($Mock::Config::VERSION) {
    Mock::Config->import(cc => $fake_cc);
}
elsif (defined($ActivePerl::VERSION) && $Config{cc} =~ /\bgcc\b/) {
    my $obj = tied %Config::Config;
    $obj->{cc} = $fake_cc;
}
else {
    eval { $Config{cc} = $fake_cc; }
}

SKIP: {
    skip "Couldn't update %Config", 1 if $@ =~ /%Config::Config is read-only/;
    eval "use Devel::CheckLib";
    is $@, "", "Good multi-word compiler is OK";
}
