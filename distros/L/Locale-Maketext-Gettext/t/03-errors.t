#! /usr/bin/perl -w
# Test suite for the behavior when something goes wrong
# Copyright (c) 2003-2009 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 29 }

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
        my ($DH, @locales);
        next unless -d $dir;
        
        @locales = qw();
        opendir $DH, $dir               or die "$THIS_FILE: $dir: $!";
        while (defined($_ = readdir $DH)) {
            my $dir1;
            $dir1 = catfile($dir, $_, "LC_MESSAGES");
            push @locales, $_ if -d $dir1 && -r $dir1
                && /^(?:en|zh_tw|zh_cn)$/i;
        }
        closedir $DH                    or die "$THIS_FILE: $dir: $!";
        
        foreach my $loc (sort @locales) {
            my $dir1;
            $dir1 = catfile($dir, $loc, "LC_MESSAGES");
            opendir $DH, $dir1          or die "$THIS_FILE: $dir1: $!";
            while (defined($_ = readdir $DH)) {
                my ($file, $domain);
                $file = catfile($dir1, $_);
                next unless -f $file && -r $file && /^(.+)\.mo$/;
                $domain = $1;
                $cands{$file} = [$loc, $domain];
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
        # Only take files whose meta information does not have special characters
        # that might be considered as code by Locale::Maketext
        next unless $content =~ /Project-Id-Version:([^\n\0\[\]~]+\n)+\0/;
        # Only take files that resolve to a valid character set
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
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_ = $_->bindtextdomain("test");
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_, undef);

# textdomain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_ = $_->textdomain;
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_, undef);

# No text domain claimed yet
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 5
ok($r, 1);
# 6
ok($_, "Hello, world!");

# Non-existing LOCALEDIR
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", "/dev/null");
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 7
ok($r, 1);
# 8
ok($_, "Hello, world!");

# Not-registered DOMAIN
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->textdomain("not_registered");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 9
ok($r, 1);
# 10
ok($_, "Hello, world!");

# PO file not exists
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("no_such_domain", $LOCALEDIR);
    $_->textdomain("no_such_domain");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 11
ok($r, 1);
# 12
ok($_, "Hello, world!");

# PO file invalid
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("bad", $LOCALEDIR);
    $_->textdomain("bad");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 13
ok($r, 1);
# 14
ok($_, "Hello, world!");

# No such message
$r = eval {
    require T_L10N;
    @_ = qw();
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_[0] = $_->maketext("[*,_1,non-existing message,non-existing messages]", 1);
    $_[1] = $_->maketext("[*,_1,non-existing message,non-existing messages]", 3);
    $_[2] = $_->pmaketext("Menu|View|", "[*,_1,non-existing message,non-existing messages]", 1);
    $_[3] = $_->pmaketext("Menu|View|", "[*,_1,non-existing message,non-existing messages]", 3);
    $_[4] = $_->pmaketext("Menu|None|", "Hello, world!");
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

# die_for_lookup_failures
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->die_for_lookup_failures(1);
    $_ = $_->maketext("non-existing message");
    return 1;
};
# To be refined - to know that we failed at maketext()
# was ok($@, qr/maketext doesn't know how to say/);
# 21
ok($r, undef);

# multibyte keys
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_->key_encoding("Big5");
    $_ = $_->maketext("（未設定）");
    return 1;
};
# 22
ok($r, 1);
# 23
ok($_, "（未設定）");

$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("zh-tw");
    $_->bindtextdomain("test", "/dev/null");
    $_->textdomain("test");
    $_->key_encoding("Big5");
    $_ = $_->maketext("（未設定）");
    return 1;
};
# 24
ok($r, 1);
# 25
ok($_, "（未設定）");

# Call maketext before and after binding text domain
$r = eval {
    require T_L10N;
    $_ = T_L10N->get_handle("en");
    $_->maketext("Hello, world!");
    $_->bindtextdomain("test", $LOCALEDIR);
    $_->textdomain("test");
    $_ = $_->maketext("Hello, world!");
    return 1;
};
# 26
ok($r, 1);
# 27
ok($_, "Hiya :)");

# Search system locale directories
($lang, $domain) = find_system_mo;
$skip = defined $domain? 0: 1;
$r = eval {
    return if $skip;
    require T_L10N;
    $_ = T_L10N->get_handle($lang);
    $_->textdomain($domain);
    print "OK 1111\n";
    $_ = $_->maketext("");
    # Skip if $Lexicon{""} does not exists
    $skip = 1 if $_ eq "";
    return 1;
};
# 28
skip($skip, $r, 1);
# 29
skip($skip, $_, qr/Project-Id-Version:/);
