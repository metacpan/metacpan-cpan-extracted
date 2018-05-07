var test = require('test');
try {
    require('bogus');
    test.assert(0, 'require throws error when module missing');
} catch (exception) {
    test.assert(1, 'require throws error when module missing');
}
test.print('DONE', 'info');
