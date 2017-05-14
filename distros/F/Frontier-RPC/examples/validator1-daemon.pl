#
# Copyright (C) 2000 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: validator1-daemon.pl,v 1.4 2000/06/01 16:19:35 kmacleod Exp $
#

use Frontier::Daemon;

sub arrayOfStructsTest {
    my $array = shift;
    my $curly_sum = 0;
    for my $struct (@$array) {
	$curly_sum += $struct->{'curly'};
    }

    return $curly_sum;
}

sub easyStructTest {
    my $struct = shift;
    return $struct->{'moe'} + $struct->{'larry'} + $struct->{'curly'};
}

sub echoStructTest {
    return shift;
}

sub manyTypesTest {
    return [@_];
}

sub moderateSizeArrayCheck {
    my $array = shift;
    return join('', $array->[0], $array->[-1]);
}

sub nestedStructTest {
    my $calendar = shift;
    my $april_1_2000 = $calendar->{'2000'}{'04'}{'01'};
    return ($april_1_2000->{'moe'} + $april_1_2000->{'larry'}
	    + $april_1_2000->{'curly'});
}

sub simpleStructReturnTest {
    my $number = shift;

    return { times10 => $number * 10,
	     times100 => $number * 100,
	     times1000 => $number * 1000 };
}

new Frontier::Daemon
    LocalPort => 8000,
    methods => {
	'validator1.arrayOfStructsTest'     => \&arrayOfStructsTest,
	'validator1.easyStructTest'         => \&easyStructTest,
	'validator1.echoStructTest'         => \&echoStructTest,
	'validator1.manyTypesTest'          => \&manyTypesTest,
	'validator1.moderateSizeArrayCheck' => \&moderateSizeArrayCheck,
	'validator1.nestedStructTest'       => \&nestedStructTest,
	'validator1.simpleStructReturnTest' => \&simpleStructReturnTest,
    };
