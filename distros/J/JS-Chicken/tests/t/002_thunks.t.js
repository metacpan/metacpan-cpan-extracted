(function() {

var t = new Test.Chicken();

t.plan(4);

var testObj = {
    test_property : 2,
    test_method   : function () { return "The Number 2" }
};

t.test_template(
    '<div><p class="one"></p><p class="two"></p></div>',
    { 
        '.one' : "ONE", 
        '.two' : "TWO",        
    },
    '<p class="one">ONE</p><p class="two">TWO</p>',
    '... multiple subsitution in one'
);

t.test_template(
    '<div><p class="one"></p><p class="two"></p></div>',
    { 
        '.one' : "ONE", 
        '.two' : new Chicken.Thunk(function () { return "GOT TWO!" }),        
    },
    '<p class="one">ONE</p><p class="two">GOT TWO!</p>',
    '... multiple subsitution (one regular one thunk) in one'
);

t.test_template(
    '<div><p class="one"></p><p class="two"></p></div>',
    { 
        '.one' : "ONE", 
        '.two' : new Chicken.PropertyThunk(testObj, 'test_property'),        
    },
    '<p class="one">ONE</p><p class="two">2</p>',
    '... multiple subsitution (one regular one property thunk) in one'
);

t.test_template(
    '<div><p class="one"></p><p class="two"></p></div>',
    { 
        '.one' : "ONE", 
        '.two' : new Chicken.MethodThunk(testObj, 'test_method'),        
    },
    '<p class="one">ONE</p><p class="two">The Number 2</p>',
    '... multiple subsitution (one regular one method thunk) in one'
);

})();
