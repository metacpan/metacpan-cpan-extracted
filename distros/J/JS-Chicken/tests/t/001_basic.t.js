(function() {

var t = new Test.Chicken();

t.plan(6);

t.test_template(
    '<div>Hello <span>Nobody</span></div>',
    { 'span' : "World" },
    'Hello <span>World</span>',
    '... simple hello world subsitution'
);

t.test_template(
    '<div>Hello <span id="who">Nobody</span></div>',
    { '#who' : "World" },
    'Hello <span id="who">World</span>',
    '... simple hello world subsitution using id selectors'
);

t.test_template(
    '<div>Hello <span class="who">Nobody</span></div>',
    { '.who' : "World" },
    'Hello <span class="who">World</span>',
    '... simple hello world subsitution using class selectors'
);

t.test_template(
    '<div>Hello <span class="who">Nobody</span> and welcome to my <p class="who"></p></div>',
    { '.who' : "World" },
    'Hello <span class="who">World</span> and welcome to my <p class="who">World</p>',
    '... multiple subsitutions using class selectors'
);

t.test_template(
    '<div>Hello <a href="#">Nobody</a></div>',
    {
        'a' : function (tmpl, selector) {
            var target = tmpl.find(selector);
            target.attr({ href : 'http://www.world.com' });
            target.html("World")
        }
    },
    'Hello <a href="http://www.world.com">World</a>',
    '... simple hello world with callback'
);

t.test_template(
    '<div>Hello <a href="#">Nobody</a></div>',
    {
        'a' : new Chicken.Callback(function (tmpl, selector) {
            var target = tmpl.find(selector);
            target.attr({ href : 'http://www.world.com' });
            target.html("World")
        })
    },
    'Hello <a href="http://www.world.com">World</a>',
    '... simple hello world with callback'
);

})();
