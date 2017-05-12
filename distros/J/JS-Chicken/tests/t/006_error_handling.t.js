(function() {

var t = new Test.Chicken();

t.plan(4);

Chicken.set_error_handler(function () {})

t.test_template(
    '<div><p>Boo</p></div>',
    { 
        'ul > li:first'        : "One",
        'ul > li:nth-child(3)' : "Three"
    },
    '<p>Boo</p>',
    '... complex selectors'
);

var errors = []; 
Chicken.set_error_handler(function (e) { errors.push(e) })

t.test_template(
    '<div><p>Boo</p></div>',
    { 
        'ul > li:first'        : "One",
        'ul > li:nth-child(3)' : "Three"
    },
    '<p>Boo</p>',
    '... complex selectors'
);

t.is(errors[0], "Could not find selector 'ul > li:first' in <p>Boo</p>", '... got the error we expected');
t.is(errors[1], "Could not find selector 'ul > li:nth-child(3)' in <p>Boo</p>", '... got the error we expected');


})();