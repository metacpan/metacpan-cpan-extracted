#! /usr/bin/perl -w
# Test suite on the maketext script
# Copyright (c) 2003-2007 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use 5.008;
use strict;
use warnings;
use Test;

BEGIN { plan tests => 10 }

use FindBin;
use File::Spec::Functions qw(catdir catfile updir);
use lib $FindBin::Bin;
use vars qw($LOCALEDIR $r $maketext);
$LOCALEDIR = catdir($FindBin::Bin, "locale");
$maketext = catdir($FindBin::Bin, updir, "blib", "script", "maketext");

# The maketext script
# Ordinary text unchanged
$r = eval {
    delete $ENV{"LANG"};
    delete $ENV{"LANGUAGE"};
    delete $ENV{"TEXTDOMAINDIR"};
    delete $ENV{"TEXTDOMAIN"};
    @_ = `"$maketext" "Hello, world!"`;
    return 1;
};
# 1
ok($r, 1);
# 2
ok($_[0], "Hello, world!");

# Specify the text domain by the -d argument
# English
$r = eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    delete $ENV{"TEXTDOMAIN"};
    @_ = `"$maketext" -d test "Hello, world!"`;
    return 1;
};
# 3
ok($r, 1);
# 4
ok($_[0], "Hiya :)");

# Specify the text domain by the environment variable
# English
$r = eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `"$maketext" "Hello, world!"`;
    return 1;
};
# 5
ok($r, 1);
# 6
ok($_[0], "Hiya :)");

# The -s argument
$r = eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `"$maketext" -s "Hello, world!"`;
    return 1;
};
# 7
ok($r, 1);
# 8
ok($_[0], "Hiya :)\n");

# Maketext
$r = eval {
    $ENV{"LANG"} = "C";
    $ENV{"LANGUAGE"} = "C";
    $ENV{"TEXTDOMAINDIR"} = $LOCALEDIR;
    $ENV{"TEXTDOMAIN"} = "test";
    @_ = `"$maketext" -s "[*,_1,directory,directories]" 5`;
    return 1;
};
# 9
ok($r, 1);
# 10
ok($_[0], "5 directories\n");
