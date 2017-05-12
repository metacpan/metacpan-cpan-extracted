#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use IO::String;
use File::Temp qw(tempfile);

#######################
# TESTING starts here #
#######################
use Test::More tests => 8;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Driver::Example';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

can_ok($obj, 'parse');
can_ok($obj, 'set_options');
can_ok($obj, 'debug_on');
can_ok($obj, 'debug_off');
can_ok($obj, 'debug_msg');

################################
# We define some parsing input #
# and also how the result      #
# should look like             #
################################
my %in ; # parsing input
my %out; # parsing result

# 1
$in{minimal} = <<'HEREDOC';
!h! Goethe: An die Erwählte
! ! Frisch gewagt ist schon gewonnen,
!i! Halb ist schon mein Werk vollbracht!
! ! Sterne leuchten mir wie Sonnen,
!b! Nur dem Feigen ist es Nacht.
HEREDOC

$out{minimal} = <<'HEREDOC';
<h1>Goethe: An die Erw&auml;hlte</h1>
Frisch gewagt ist schon gewonnen,<br />
<i>Halb ist schon mein Werk vollbracht!</i><br />
Sterne leuchten mir wie Sonnen,<br />
<b>Nur dem Feigen ist es Nacht.</b><br />
HEREDOC

#################################################
# Now we parse the input and compare the result #
# with what we expected...                      #
#################################################
for my $key (keys %in) {
    # we reset the parser, because the <mbp:pagebreak /> (see Parser-code)
    my $obj = $module->new();

    #$obj->debug_on(sub {print $_[0] . "\n"});

    my $res = $obj->parse($in{$key});
    is($res, $out{$key}, "converting -> $key");
}

########
# done #
########
1;

