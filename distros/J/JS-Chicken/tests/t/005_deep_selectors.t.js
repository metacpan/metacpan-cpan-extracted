(function() {

var t = new Test.Chicken();

t.plan(2);

t.test_template(
    '<div><ul><li>...</li><li>...</li><li>...</li><li>...</li></ul></div>',
    { 
        'ul > li:first'        : "One",
        'ul > li:nth-child(3)' : "Three"
    },
    '<ul><li>One</li><li>...</li><li>Three</li><li>...</li></ul>',
    '... complex selectors'
);

t.test_template(
    '<div><ul><li>...</li><li>...</li><li>...</li><li>...</li></ul></div>',
    { 
        'ul > li:even' : "Even",
        'ul > li:odd'  : "Odd"
    },
    '<ul><li>Even</li><li>Odd</li><li>Even</li><li>Odd</li></ul>',
    '... (more) complex selectors'
);

})();