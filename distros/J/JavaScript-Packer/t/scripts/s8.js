function ( blah ) {
    var     arg = x;
    var arg2    = y;

    var CONCAT_ARGUMENTS_BUGGY = (function() {
        return [].concat(arguments)[0][0] !== 1;
    })( 1, do_somthing(do_something_else( arg, arg2 ), arg) );

    if (CONCAT_ARGUMENTS_BUGGY) arrayProto.concat = concat;
}