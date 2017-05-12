(function() {

var t = new Test.Chicken();

t.plan(10);

(function () {

var template = $('<div><table><tr><td></td></tr></table></div>')

var collection = new Chicken.Collection({
    'row_selector' : 'tr',
});

template.process_template({ 'table' : collection });

t.is(
    template.html(),
    '<table><tbody></tbody></table>',
    '... got the right html before doing anything'
);

collection.append_values([ { 'td' : 2 } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>2</td></tr></tbody></table>',
    '... got the right html after appending'
);

collection.prepend_values([ { 'td' : 1 } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>',
    '... got the right html after prepending'
);

collection.prepend_values([ { 'td' : '0' } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>0</td></tr><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>',
    '... got the right html after prepending'
);

collection.append_values([ { 'td' : 3 } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>0</td></tr><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr></tbody></table>',
    '... got the right html after appending'
);

})();

(function () {
var template = $('<div><table><tr><td></td></tr></table></div>')

var collection = new Chicken.Collection({
    'row_selector' : 'tr',
});

collection.initialize(template, 'table');

t.is(
    template.html(),
    '<table><tbody></tbody></table>',
    '... got the right html before doing anything'
);

collection.append_values([ { 'td' : 2 } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>2</td></tr></tbody></table>',
    '... got the right html after appending'
);

collection.prepend_values([ { 'td' : 1 } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>',
    '... got the right html after prepending'
);

collection.prepend_values([ { 'td' : '0' } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>0</td></tr><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>',
    '... got the right html after prepending'
);

collection.append_values([ { 'td' : 3 } ]);

t.is(
    template.html(),
    '<table><tbody><tr><td>0</td></tr><tr><td>1</td></tr><tr><td>2</td></tr><tr><td>3</td></tr></tbody></table>',
    '... got the right html after appending'
);

})();

})();
