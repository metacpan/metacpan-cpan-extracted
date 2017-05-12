(function() {
if (! window.Foo) Foo = {};

(window.Foo.Bar = function() {}).prototype = {
    greetings: function() {
        alert("My name is Foo.Bar. I live on CPAN.");
    }
}
})();
