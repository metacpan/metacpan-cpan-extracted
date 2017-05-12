#!perl -T
do './t/jstest.pl' or die __DATA__

// Maybe I should combine this file with another script. This file has a 
// ridiculously small number of tests.

plan('tests', 1)

// ===================================================
// 11.14
// ===================================================

/* Test 1 */

ok((function(){run=true}(),6) === 6 && this.run, ',')
