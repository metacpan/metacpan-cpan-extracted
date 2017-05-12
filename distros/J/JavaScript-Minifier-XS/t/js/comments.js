/* block comments get removed */

// as do line comments

/* comments containing the word "copyright" are left in, though */
// including line comments, with mixed case cOpYrIgHt

/* block comments placed inline get removed too.  If they function as providing
 * whitespace between things that shouldn't be shoved together, though, they're
 * replaced with some whitespace.
 */
var foo /* remove */ = /* me too */ 3;
var bar = /* and me */ 4;
var replaced_with_ws = foo + /* ws */ +bar;
var also_replaced    = foo - /* ws */ -bar;
var removed_outright = foo + /* me gone */ -bar;
var also_removed     = foo - /* me gone */ +bar;
