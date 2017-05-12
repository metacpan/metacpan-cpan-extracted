/* comments placed directly before a regex should be skipped, instead of being
 * used to determine whether the leading '/' of the regexp is actually for
 * division or not.
 *
 * when its not working correctly, the regexes are parsed as division and that
 * causes the quote matching to get bungled up.
 */

var foo = [
    // trick the engine into thinking we end in an array[]
    /^'/,

    // this *should* be parsed as a comment, not a literal
    /^"/,

    // isn't this the line with the closing apostrophe in it?
    /foo/
    ];
