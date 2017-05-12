(function() {

var t = new Test.JSORB();

t.plan(17);

var __ajax_calls__ = [];

// mock our AJAX calls ..
JSORB.Util.do_ajax_call = function (options) {
    __ajax_calls__.push(options)
};

(function() {
    var c = new JSORB.Client ('http://localhost/');

    t.is(c.constructor, JSORB.Client, '... this is-a Client');            

    t.is(c.base_url, 'http://localhost/', '... got the right base url');
    t.is(c.base_namespace, null, '... got the right base namespace (null)');
    t.is(c.message_count, 0, '... got the right message count');    
    
    var req = c.new_request({
        method : '/test/this/module',
        params : []
    });
    
    t.is(req.constructor, JSORB.Client.Request, '... this is-a Client.Request');
    
    t.is(req.id, null, '... got the expected (null) ID');
    t.is(req.method, '/test/this/module', '... got the right method');
    t.is(req.params.constructor, Array, '... our params is an Array');
    t.is(req.params.length, 0, '... and it is empty');    
    
    c.call(
        req, 
        function (result) {
            t.is(result, 'HELLO', '... got the right response')
        }, 
        function (error) {
            t.is(error.message, 'WTF', '... got the right error')            
        }
    );

    t.is(c.message_count, 1, '... got the right message count');    

    t.is(req.id, 1, '... got the expected ID');
    
    var call = __ajax_calls__.pop();
    
    t.is(call.url, req.as_url(c.base_url), '... the URL is the same');
    t.is(call.dataType, 'text', '... the expected data-type');
    t.is(call.success.constructor, Function, '... the success callback');
    t.is(call.error.constructor, Function, '... the error callback');    
    
    // call the success & error handlers 
    // and let the callbacks above
    // do some additional checking
    
    call.success({
        id     : 1,
        result : 'HELLO'
    }, 200);
    
    call.success({
        id    : 1,
        error : {
            message : "WTF",
            code    : 1
        }
    }, 200);    
    
})();

})();
