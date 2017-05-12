(function() {

var t = new Test.JSON();

t.plan(4);

var have1 = JSON.parse('["foo", "bar"]');
var want1 = ["foo", "bar"];

// t.is_deeply(have1, want1, 'JSON.parse(array) works');
// Turns out is_deeply not implemented yet :(

t.is(have1.length, 2, 'Parsed array has 2 elems');
t.is(have1[0], 'foo', 'First array elem is "foo"');
t.is(have1[1], 'bar', 'Second array elem is "bar"');

var have2 = JSON.stringify({foo: "bar", baz: "quux"});
var want2 = '{"foo":"bar","baz":"quux"}';

t.is(have2, want2, 'JSON.stringify(object) works');

})();
