#!/usr/bin/env perl -T

use strict;

use Time::HiRes 'sleep';
use Test::More tests => 2;

# For debugging only
# use Data::Dumper;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

BEGIN {
    our $VERSION = '2.02';
    use_ok('Graphics::Framebuffer');
}

my $b  = "\e[34m";
my $bb = "\e[94m";
my $g  = "\e[32m";
my $gg = "\e[92m";
my $r  = "\e[31m";
my $rr = "\e[91m";
my $rs = "\e[0m";
my $c  = "\e[36m";
my $bk = "\e[40m";
my $y  = "\e[33m";

diag("\r ");
diag("\r$b" . q{   #####\    } . $rs);
diag("\r$b" . q{  ##  __##\  } . $rs);
diag("\r$b" . q{  ## /  \__| } . $rs );
diag("\r$b" . q{  ## |####\  } . $rs );
diag("\r$b" . q{  ## |\_## | } . $rs );
diag("\r$b" . q{  ## |  ## | } . $rs );
diag("\r$b" . q{  \######  | } . $rs );
diag("\r$b" . q{   \______/  } . $rs );
sleep .3;
diag("\r \e[8A\e[11C$g" , q{ ########\  } . $rs);
diag("\r \e[11C$g"      . q{  ##  ____\ } . $rs);
diag("\r \e[11C$g"      . q{  ## |      } . $rs);
diag("\r \e[11C$g"      . q{  #####\    } . $rs);
diag("\r \e[11C$g"      . q{  ##  __|   } . $rs);
diag("\r \e[11C$g"      . q{  ## |      } . $rs);
diag("\r \e[11C$g"      . q{  ## |      } . $rs);
diag("\r \e[11C$g"      . q{  \__|      } . $rs);
sleep .3;
diag("\r \e[8A\e[22C$r" . q{ #######\   } . $rs);
diag("\r \e[22C$r"      . q{ ##  __##\  } . $rs);
diag("\r \e[22C$r"      . q{ ## |  ## | } . $rs);
diag("\r \e[22C$r"      . q{ #######\ | } . $rs);
diag("\r \e[22C$r"      . q{ ##  __##\  } . $rs);
diag("\r \e[22C$r"      . q{ ## |  ## | } . $rs);
diag("\r \e[22C$r"      . q{ #######  | } . $rs);
diag("\r \e[22C$r"      . q{ \_______/  } . $rs);
sleep .3;

diag("\r$c$bk" .                                     q{  _______        _   _              } . $rs);
diag("\r$c$bk" .                                     q{ |__   __|      | | (_)             } . $rs);
diag("\r$c$bk" .                                     q{    | | ___  ___| |_ _ _ __   __ _  } . $rs);
diag("\r$c$bk" .                                     q{    | |/ _ \/ __| __| | '_ \ / _` | } . $rs);
diag("\r$c$bk" .                                     q{    | |  __/\__ \ |_| | | | | (_| | } . $rs);
diag("\r$c$bk" .                                     q{    |_|\___||___/\__|_|_| |_|\__, | } . $rs);
diag("\r$c$bk" .                                     q{                              __/ | } . $rs);
diag("\r$y$bk" . q{   Graphics::Framebuffer } . $c . q{    |___/  } . $rs);
diag("\r ");

our $F = Graphics::Framebuffer->new('RESET' => 0, 'SPLASH' => 0);
isa_ok($F,'Graphics::Framebuffer');

$F->acceleration(0);
$F->splash(2);

$F->acceleration(1);
$F->splash(2);
exit(0);
