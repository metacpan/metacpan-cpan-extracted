(function() {

var t = new Test.JSORB();

t.plan(24);

// test simple request
(function() {
    var req = new JSORB.Client.Request ({
        id     : 1,
        method : 'test',
        params : []
    });

    t.is(req.constructor, JSORB.Client.Request, '... this is-a Client.Request');

    t.is(req.id, 1, '... got the expected ID');
    t.is(req.method, 'test', '... got the expected method');
    t.is(req.params.constructor, Array, '... our params is an Array');
    t.is(req.params.length, 0, '... and it is empty');

    t.ok(!req.is_notification(), '... this is not a notification');

    t.is(
        req.as_url(),
        '?jsonrpc=2.0&id=1&method=test&params=%5B%5D',
        '... got the right URL'
    );

    t.is(
        req.as_json(),
        '{"jsonrpc":"2.0","id":1,"method":"test","params":[]}',
        '... got the right JSON string'
    );
})();

// test notification request
(function() {
    var req = new JSORB.Client.Request ({
        method : 'test',
        params : [1, 2, 3]
    });

    t.is(req.constructor, JSORB.Client.Request, '... this is-a Client.Request');

    t.is(req.id, null, '... got the expected ID');
    t.is(req.method, 'test', '... got the expected method');
    t.is(req.params.constructor, Array, '... our params is an Array');
    t.is(req.params.length, 3, '... and it is empty');

    t.ok(req.is_notification(), '... this is not a notification');

    t.is(
        req.as_url(),
        '?jsonrpc=2.0&method=test&params=%5B1%2C2%2C3%5D',
        '... got the right URL'
    );

    t.is(
        req.as_json(),
        '{"jsonrpc":"2.0","id":null,"method":"test","params":[1,2,3]}',
        '... got the right JSON string'
    );
})();

// test request from JSON
(function() {
    var req = new JSORB.Client.Request ('{"jsonrpc":"2.0","id":1,"method":"test","params":[]}');

    t.is(req.constructor, JSORB.Client.Request, '... this is-a Client.Request');

    t.is(req.id, 1, '... got the expected ID');
    t.is(req.method, 'test', '... got the expected method');
    t.is(req.params.constructor, Array, '... our params is an Array');
    t.is(req.params.length, 0, '... and it is empty');

    t.ok(!req.is_notification(), '... this is not a notification');

    t.is(
        req.as_url(),
        '?jsonrpc=2.0&id=1&method=test&params=%5B%5D',
        '... got the right URL'
    );

    t.is(
        req.as_json(),
        '{"jsonrpc":"2.0","id":1,"method":"test","params":[]}',
        '... got the right JSON string'
    );
})();

})();
