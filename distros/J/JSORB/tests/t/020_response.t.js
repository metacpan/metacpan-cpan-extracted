(function() {

var t = new Test.JSORB();

t.plan(43);

// test simple response
(function() {
    var resp = new JSORB.Client.Response ({
        id     : 1,
        result : 'test',
    });
    
    t.is(resp.constructor, JSORB.Client.Response, '... this is-a Client.Response');    

    t.is(resp.id, 1, '... got the expected ID');
    t.is(resp.result, 'test', '... got the expected result');

    t.ok(!resp.has_error(), '... this does not have an error');

    t.is(
        resp.as_json(),
        '{"id":1,"result":"test","error":null}',
        '... got the right JSON string'
    );
})();

// test simple response
(function() {
    var resp = new JSORB.Client.Response ({
        id     : 1,
        result : ['test',1,2,3],
    });
    
    t.is(resp.constructor, JSORB.Client.Response, '... this is-a Client.Response');        

    t.is(resp.id, 1, '... got the expected ID');
    t.is(resp.result[0], 'test', '... got the expected result');
    t.is(resp.result[1], 1, '... got the expected result');
    t.is(resp.result[2], 2, '... got the expected result');
    t.is(resp.result[3], 3, '... got the expected result');            

    t.ok(!resp.has_error(), '... this does not have an error');

    t.is(
        resp.as_json(),
        '{"id":1,"result":["test",1,2,3],"error":null}',
        '... got the right JSON string'
    );
})();

// test simple response from json
(function() {
    var resp = new JSORB.Client.Response ('{"id":1,"result":"test","error":null}');

    t.is(resp.constructor, JSORB.Client.Response, '... this is-a Client.Response');        

    t.is(resp.id, 1, '... got the expected ID');
    t.is(resp.result, 'test', '... got the expected result');

    t.ok(!resp.has_error(), '... this does not have an error');

    t.is(
        resp.as_json(),
        '{"id":1,"result":"test","error":null}',
        '... got the right JSON string'
    );
})();

// test simple response w/ error
(function() {
    var resp = new JSORB.Client.Response ({
        id    : 1,
        error : {}
    });
    
    t.is(resp.constructor, JSORB.Client.Response, '... this is-a Client.Response');            

    t.is(resp.id, 1, '... got the expected ID');
    t.is(resp.result, null, '... got the expected result');

    t.ok(resp.has_error(), '... this does not have an error');
    
    t.is(resp.error.constructor, JSORB.Client.Error, '... this is-a Client.Error');            
    
    t.is(resp.error.code, 1, '... got the right default code');
    t.is(resp.error.message, 'An error has occured', '... got the right default message');    

    t.is(
        resp.as_json(),
        '{"id":1,"error":{"code":1,"message":"An error has occured","data":{}}}',
        '... got the right JSON string'
    );
})();

// test simple response w/ error from json
(function() {
    var resp = new JSORB.Client.Response (
        '{"id":1,"error":{"code":1,"message":"An error has occured","data":{}}}'
    );
    
    t.is(resp.constructor, JSORB.Client.Response, '... this is-a Client.Response');            

    t.is(resp.id, 1, '... got the expected ID');
    t.is(resp.result, null, '... got the expected result');

    t.ok(resp.has_error(), '... this does not have an error');
    
    t.is(resp.error.constructor, JSORB.Client.Error, '... this is-a Client.Error');                
    
    t.is(resp.error.code, 1, '... got the right default code');
    t.is(resp.error.message, 'An error has occured', '... got the right default message');    

    t.is(
        resp.as_json(),
        '{"id":1,"error":{"code":1,"message":"An error has occured","data":{}}}',
        '... got the right JSON string'
    );
})();

// test simple response w/ error
(function() {
    var resp = new JSORB.Client.Response ({
        id    : 1,
        error : {
            code    : 10,
            message : "Error has occured, everone run!",
            data    : { foo : "bar" }
        }
    });
    
    t.is(resp.constructor, JSORB.Client.Response, '... this is-a Client.Response');            

    t.is(resp.id, 1, '... got the expected ID');
    t.is(resp.result, null, '... got the expected result');

    t.ok(resp.has_error(), '... this does not have an error');
    
    t.is(resp.error.constructor, JSORB.Client.Error, '... this is-a Client.Error');                
    
    t.is(resp.error.code, 10, '... got the right code');
    t.is(resp.error.message, 'Error has occured, everone run!', '... got the right message');    
    t.is(resp.error.data.foo, 'bar', '... got the right data');

    t.is(
        resp.as_json(),
        '{"id":1,"error":{"code":10,"message":"Error has occured, everone run!","data":{"foo":"bar"}}}',
        '... got the right JSON string'
    );
})();


})();
