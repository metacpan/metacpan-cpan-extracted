(function() {

var proto = Test.Base.newSubclass('Test.Chicken', 'Test.Base');
// Extensions should go here...

proto.test_template = function(starting_html, params, ending_html, message) {
    this.is(
        $(starting_html).process_template(params).html(),
        ending_html,
        message
    );
}

// This should be in Test.Base but isn't yet:
proto.is_deeply = function() {
    this.builder.is_deeply.apply(this.builder, arguments);
}
// hmm... turns out this isn't even in Test.Builder yet!
// David Wheeler or Ingy need to fix.

proto = Test.Chicken.Filter
// Extensions and filters should go here...

})();


