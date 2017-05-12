(function() {

var proto = Test.Base.newSubclass('Test.JSON', 'Test.Base');
// Extensions should go here...


// This should be in Test.Base but isn't yet:
proto.is_deeply = function() {
    this.builder.is_deeply.apply(this.builder, arguments);
}
// hmm... turns out this isn't even in Test.Builder yet!
// David Wheeler or Ingy need to fix.


proto = Test.JSON.Filter
// Extensions and filters should go here...

})();
