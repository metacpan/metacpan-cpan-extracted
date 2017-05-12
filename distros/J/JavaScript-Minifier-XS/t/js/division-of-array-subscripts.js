/*
 * Division of an array subscript should NOT be treated as opening a regexp,
 * but should be treated as division.
 */
function foo() {
    var bar = someArray[2]/2;
}
function bar() {
    foo(); // this / is not a regexp close, its just part of a line comment
}
