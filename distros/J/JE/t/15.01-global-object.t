#!perl -T
do './t/jstest.pl' or die __DATA__

// Let’s make sure that there are no enumerable global properties before
// we create the ‘error’ variable, below:
// 1 test

!function(){
	var fail;
	for(var p in this)
		if(!this[p].forTesting) {
			fail=true;
			break
		}
	ok(!fail, 'unenumerability of global properties')
}()

// ===================================================
// 15.1: The global object
// 2 tests
// ===================================================

error = 0;
try{new this}
catch(e){error=e}
ok(error instanceof TypeError, 'global object has no [[Construct]] method')

error = 0;
try{this()}
catch(e){error=e}
ok(error instanceof TypeError, 'global object is not a function')

