/* RT#80598; regexps containing an escaped "/" should not be treated as comments */
function foo(url) {
    return ( /\// ).test( url );
}
