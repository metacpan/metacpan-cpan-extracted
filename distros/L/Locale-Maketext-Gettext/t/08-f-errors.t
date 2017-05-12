#! /usr/bin/perl -w
# Test suite on the functional interface for the behavior when something goes wrong
# Copyright (c) 2003-2008 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 39 }

use Encode qw();
use FindBin;
use File::Basename qw(basename);
use File::Spec::Functions qw(catdir catfile);
use lib $FindBin::Bin;
use vars qw($THIS_FILE $LOCALEDIR $r);
$THIS_FILE = basename($0);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
sub find_system_mo();

# find_system_mo: Find a safe system MO to be tested
sub find_system_mo() {
    local ($_, %_);
    my %cands;
    use Locale::Maketext::Gettext::Functions;
    # Find all the system MO files
    %cands = qw();
    foreach my $dir (@Locale::Maketext::Gettext::Functions::SYSTEM_LOCALEDIRS) {
        my ($DH, @langs);
        next unless -d $dir;
        
        @langs = qw();
        opendir $DH, $dir               or die "$THIS_FILE: $dir: $!";
        while (defined($_ = readdir $DH)) {
            my $dir1;
            $dir1 = catfile($dir, $_, "LC_MESSAGES");
            push @langs, $_ if -d $dir1 && -r $dir1;
        }
        closedir $DH                    or die "$THIS_FILE: $dir: $!";
        
        foreach my $lang (sort @langs) {
            my $dir1;
            $dir1 = catfile($dir, $lang, "LC_MESSAGES");
            opendir $DH, $dir1          or die "$THIS_FILE: $dir1: $!";
            while (defined($_ = readdir $DH)) {
                my ($file, $domain);
                $file = catfile($dir1, $_);
                next unless -f $file && -r $file && /^(.+)\.mo$/;
                $domain = $1;
                $cands{$file} = [$lang, $domain];
            }
            closedir $DH                or die "$THIS_FILE: $dir1: $!";
        }
    }
    # Check each MO file, from the newest
    foreach my $file (sort { (stat $b)[9] <=> (stat $a)[9] } keys %cands) {
        my ($FH, $size, $content, $charset, $lang, $domain);
        $size = (stat $file)[7];
        open $FH, $file                 or die "$THIS_FILE: $file: $!";
        read $FH, $content, $size       or die "$THIS_FILE: $file: $!";
        close $FH                       or die "$THIS_FILE: $file: $!";
        next unless $content =~ /Project-Id-Version:/;
        next unless $content =~ /\s+charset=([^\n]+)/;
        $charset = $1;
        next unless defined Encode::resolve_alias($charset);
        # OK. We take this one
        ($lang, $domain) = @{$cands{$file}};
        $lang = lc $lang;
        $lang =~ s/_/-/g;
        $lang = "i-default" if $lang eq "c";
        return ($lang, $domain);
    }
    # Not found
    return (undef, undef);
}

# When something goes wrong
use vars qw($dir $domain $lang $skip);
# GNU gettext never fails!
# bindtextdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    $_ = bindtextdomain("test");
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, undef);

# textdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    $_ = textdomain;
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, undef);

# No text domain claimed yet
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    $_ = __("Hello, world!");
    return 1;
};
# 5
ok($r, 1);
# 6
ok($_, "Hello, world!");

# Non-existing LOCALEDIR
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", "/dev/null");
    textdomain("test");
    $_ = __("Hello, world!");
    return 1;
};
# 7
ok($r, 1);
# 8
ok($_, "Hello, world!");

# Not-registered DOMAIN
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    textdomain("not_registered");
    $_ = __("Hello, world!");
    return 1;
};
# 9
ok($r, 1);
# 10
ok($_, "Hello, world!");

# PO file not exists
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("no_such_domain", $LOCALEDIR);
    textdomain("no_such_domain");
    $_ = __("Hello, world!");
    return 1;
};
# 11
ok($r, 1);
# 12
ok($_, "Hello, world!");

# PO file invalid
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("bad", $LOCALEDIR);
    textdomain("bad");
    $_ = __("Hello, world!");
    return 1;
};
# 13
ok($r, 1);
# 14
ok($_, "Hello, world!");

# No such message
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    @_ = qw();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_[0] = __("[*,_1,non-existing message,non-existing messages]", 1);
    $_[1] = __("[*,_1,non-existing message,non-existing messages]", 3);
    $_[2] = pmaketext("Menu|View|", "[*,_1,non-existing message,non-existing messages]", 1);
    $_[3] = pmaketext("Menu|View|", "[*,_1,non-existing message,non-existing messages]", 3);
    $_[4] = pmaketext("Menu|None|", "Hello, world!");
    return 1;
};
# 15
ok($r, 1);
# 16
ok($_[0], "1 non-existing message");
# 17
ok($_[1], "3 non-existing messages");
# 18
ok($_[2], "1 non-existing message");
# 19
ok($_[3], "3 non-existing messages");
# 20
ok($_[4], "Hello, world!");

# get_handle before textdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    get_handle("en");
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    $_ = __("Hello, world!");
    return 1;
};
# 21
ok($r, 1);
# 22
ok($_, "Hiya :)");

# bindtextdomain after textdomain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    get_handle("en");
    textdomain("test2");
    bindtextdomain("test2", $LOCALEDIR);
    $_ = __("Every story has a happy ending.");
    return 1;
};
# 23
ok($r, 1);
# 24
ok($_, "Pray it.");

# multibyte keys
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("zh-tw");
    key_encoding("Big5");
    $_ = maketext("（未設定）");
    return 1;
};
# 25
ok($r, 1);
# 26
ok($_, "（未設定）");

$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", "/dev/null");
    textdomain("test");
    get_handle("zh-tw");
    key_encoding("Big5");
    $_ = maketext("（未設定）");
    return 1;
};
# 27
ok($r, 1);
# 28
ok($_, "（未設定）");

# Maketext before and after binding text domain
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    __("Hello, world!");
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = __("Hello, world!");
    return 1;
};
# 29
ok($r, 1);
# 30
ok($_, "Hiya :)");

# Switch to a domain that is not binded yet
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    get_handle("en");
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    textdomain("test2");
    $_ = __("Hello, world!");
    return 1;
};
# 31
ok($r, 1);
# 32
ok($_, "Hello, world!");

# N_: different context - string to array
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    @_ = N_("Hello, world!");
    return 1;
};
# 33
ok($r, 1);
# 34
ok($_[0], "Hello, world!");
# 35
ok($_[1], undef);

# N_: different context - array to string
$r = eval {
    use Locale::Maketext::Gettext::Functions;
    Locale::Maketext::Gettext::Functions::_reset();
    bindtextdomain("test", $LOCALEDIR);
    textdomain("test");
    get_handle("en");
    $_ = N_("Hello, world!", "Cool!", "Big watermelon");
    return 1;
};
# 36
ok($r, 1);
# 37
ok($_, "Hello, world!");

# Search system locale directories
($lang, $domain) = find_system_mo;
$skip = defined $domain? 0: 1;
$r = eval {
    return if $skip;
    use Locale::Maketext::Gettext::Functions;
    textdomain($domain);
    get_handle($lang);
    $_ = maketext("");
    # Skip if $Lexicon{""} does not exists
    $skip = 1 if $_ eq "";
    return 1;
};
# 38
skip($skip, $r, 1, $@);
# 39
skip($skip, $_, qr/Project-Id-Version:/);
