package JavaScript::V8x::TestMoreish::JS;

use strict;
use warnings;

sub TestMoreish {
    <<'_END_'
if (! _TestMoreish)
    var _TestMoreish = {};

(function(){ 

    var _TM = _TestMoreish;

	_TM._ok = function( ok, name ) {
        _TestMoreish_ok( ok, name );
    }

	_TM._diag = function( diag ) {
        _TestMoreish_diag( diag );
    }

    _TM._gotExpectedFailure = function( got, expected, name, _error ) {
        
        var error = _error + 
            "\nGot: " + got + " (" + (typeof got) + ")"  +
            "\nExpected: " + expected + " (" + (typeof expected) + ")";

        return { name: name, error: error };
    };

    _TM._gotFailure = function( got, _error ) {

        var error = _error + 
            "\nGot: " + got + " (" + (typeof got) + ")";

        return { name: name, error: error };
    }


    _TM.test = {
    
        areEqual: function( got, expected ) { return got == expected; },
        areNotEqual: function( got, expected ) { return got != expected; },
        areSame: function( got, expected ) { return got === expected; },
        areNotSame: function( got, expected ) { return got !== expected; },
        
        isTrue: function( got ) { return got === true; },
        isFalse: function( got ) { return got === false; },

        isString: function( got ) { return typeof got === 'string'; },
        isValue: function( got ) { return this.isObject( got ) || this.isString( got ) || this.isNumber( got ) || this.isBoolean( got ); },
        isObject: function( got ) { return (got && (typeof got === 'object' || this.isFunction( got ))) || false; },
        isNumber: function( got ) { return typeof got === 'number' && isFinite( got ); },
        isBoolean: function( got ) { return typeof got === 'boolean'; },
        isFunction: function( got ) { return (typeof got === 'function') || Object.prototype.toString.apply( got ) === '[object Function]'; },

        like: function( got, match ) {
            if (this.isString( match )) match = new RegExp( match );
            return this.isValue( got ) && this.isString( got ) && got.match( match );
        }
    };

    _TM._areEqual = function( got, expected, name ) {
        return this.test.areEqual( got, expected ) ?  { name: name } :
            this._gotExpectedFailure( got, expected, name, "Value is not equal" );
    };

    _TM._areNotEqual = function( got, expected, name ) {
        return this.test.areNotEqual( got, expected ) ?  { name: name } :
            this._gotExpectedFailure( got, expected, name, "Value is equal" );
    };

    _TM._areSame = function( got, expected, name ) {
        return this.test.areSame( got, expected ) ?  { name: name } :
            this._gotExpectedFailure( got, expected, name, "Value is not same" );
    };

    _TM._areNotSame = function( got, expected, name ) {
        return this.test.areNotSame( got, expected ) ?  { name: name } :
            this._gotExpectedFailure( got, expected, name, "Value is same" );
    };

    _TM._isTrue = function( got, name ) {
        return this.test.isTrue( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not true" );
    };

    _TM._isFalse = function( got, name ) {
        return this.test.isFalse( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not false" );
    };

    _TM._isString = function( got, name ) {
        return this.test.isString( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not a string" );
    };

    _TM._isValue = function( got, name ) {
        return this.test.isValue( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not a value" );
    };
    
    _TM._isObject = function( got, name ) {
        return this.test.isNumber( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not an object" );
    };

    _TM._isNumber = function( got, name ) {
        return this.test.isNumber( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not a number" );
    };
    
    _TM._isBoolean = function( got, name ) {
        return this.test.isBoolean( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not a boolean" );
    };
    
    _TM._isFunction = function( got, name ) {
        return this.test.isFunction( got ) ?  { name: name } :
            this._gotFailure( got, name, "Value was not a function" );
    };
    
    _TM._like = function( got, match, name ) {
        return this.test.like( got, match ) ?  { name: name } :
            this._gotExpectedFailure( got, match, name, "Value does not match regular expression" );
    };
	
    _TM._fail = function( name ) {
        return { name: name, error: "Failure" };
    };

//    _formatMessage : function (customMessage /*:String*/, defaultMessage /*:String*/) /*:String*/ {

//        var message = customMessage;
//        if (YAHOO.lang.isString(customMessage) && customMessage.length > 0){
//            return YAHOO.lang.substitute(customMessage, { message: defaultMessage });
//        } else {
//            return defaultMessage;
//        }        
//    },

//    getMessage : function () /*:String*/ {
//        return this.message + "\nExpected: " + this.expected + " (" + (typeof this.expected) + ")"  +
//            "\nActual:" + this.actual + " (" + (typeof this.actual) + ")";
//    }

    var _installTest = function( test ) {
		return function() {
            var tester = this['_' + test];
            var result = tester.apply( this, arguments );
            this._ok( result.error ? 0 : 1, result.name );
            if ( result.error ) {
                this._diag( result.error );
            }
            return result.error ? 0 : 1;
        };
    }

    // Public API

    _TM.diag = function() { this._diag.apply( this, arguments ) };

    var _test = [
        'areEqual',
        'areNotEqual',
        'areSame',
        'areNotSame',

        'isTrue',
        'isFalse',

        'isBoolean',
        'isFunction',
        'isNumber',
        'isObject',
        'isString',

        'like',

        'fail',
//        'isTypeOf',
//        'isArray',
//        'isInstanceOf',
//        'isNaN',
//        'isNotNaN',
//        'isNull',
//        'isNotNull',
//        'isUndefined',
//        'isNotUndefined'
    ];

    for (var ii = 0; ii < _test.length; ii++) {
        var name = _test[ii];
        _TM[name] = _installTest( name );
    }

})();

//    //-------------------------------------------------------------------------
//    // Boolean Assertion Methods
//    //-------------------------------------------------------------------------    
//    
//    /**
//     * Asserts that a value is false. This uses the triple equals sign
//     * so no type cohersion may occur.
//     * @param {Object} actual The actual value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isFalse
//     * @static
//     */
//    isFalse : function (actual /*:Boolean*/, message /*:String*/) {
//        if (false !== actual) {
//            throw new YAHOO.util.ComparisonFailure(this._formatMessage(message, "Value should be false."), false, actual);
//        }
//    },
//    
//    /**
//     * Asserts that a value is true. This uses the triple equals sign
//     * so no type cohersion may occur.
//     * @param {Object} actual The actual value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isTrue
//     * @static
//     */
//    isTrue : function (actual /*:Boolean*/, message /*:String*/) /*:Void*/ {
//        if (true !== actual) {
//            throw new YAHOO.util.ComparisonFailure(this._formatMessage(message, "Value should be true."), true, actual);
//        }

//    },
//    
//    //-------------------------------------------------------------------------
//    // Special Value Assertion Methods
//    //-------------------------------------------------------------------------    
//    
//    /**
//     * Asserts that a value is not a number.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isNaN
//     * @static
//     */
//    isNaN : function (actual /*:Object*/, message /*:String*/) /*:Void*/{
//        if (!isNaN(actual)){
//            throw new YAHOO.util.ComparisonFailure(this._formatMessage(message, "Value should be NaN."), NaN, actual);
//        }    
//    },
//    
//    /**
//     * Asserts that a value is not the special NaN value.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isNotNaN
//     * @static
//     */
//    isNotNaN : function (actual /*:Object*/, message /*:String*/) /*:Void*/{
//        if (isNaN(actual)){
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Values should not be NaN."), NaN);
//        }    
//    },
//    
//    /**
//     * Asserts that a value is not null. This uses the triple equals sign
//     * so no type cohersion may occur.
//     * @param {Object} actual The actual value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isNotNull
//     * @static
//     */
//    isNotNull : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (YAHOO.lang.isNull(actual)) {
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Values should not be null."), null);
//        }
//    },

//    /**
//     * Asserts that a value is not undefined. This uses the triple equals sign
//     * so no type cohersion may occur.
//     * @param {Object} actual The actual value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isNotUndefined
//     * @static
//     */
//    isNotUndefined : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (YAHOO.lang.isUndefined(actual)) {
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Value should not be undefined."), undefined);
//        }
//    },

//    /**
//     * Asserts that a value is null. This uses the triple equals sign
//     * so no type cohersion may occur.
//     * @param {Object} actual The actual value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isNull
//     * @static
//     */
//    isNull : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isNull(actual)) {
//            throw new YAHOO.util.ComparisonFailure(this._formatMessage(message, "Value should be null."), null, actual);
//        }
//    },
//        
//    /**
//     * Asserts that a value is undefined. This uses the triple equals sign
//     * so no type cohersion may occur.
//     * @param {Object} actual The actual value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isUndefined
//     * @static
//     */
//    isUndefined : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isUndefined(actual)) {
//            throw new YAHOO.util.ComparisonFailure(this._formatMessage(message, "Value should be undefined."), undefined, actual);
//        }
//    },    
//    
//    //--------------------------------------------------------------------------
//    // Instance Assertion Methods
//    //--------------------------------------------------------------------------    
//   
//    /**
//     * Asserts that a value is an array.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isArray
//     * @static
//     */
//    isArray : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isArray(actual)){
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Value should be an array."), actual);
//        }    
//    },
//   
//    /**
//     * Asserts that a value is a Boolean.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isBoolean
//     * @static
//     */
//    isBoolean : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isBoolean(actual)){
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Value should be a Boolean."), actual);
//        }    
//    },
//   
//    /**
//     * Asserts that a value is a function.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isFunction
//     * @static
//     */
//    isFunction : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isFunction(actual)){
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Value should be a function."), actual);
//        }    
//    },
//   
//    /**
//     * Asserts that a value is an instance of a particular object. This may return
//     * incorrect results when comparing objects from one frame to constructors in
//     * another frame. For best results, don't use in a cross-frame manner.
//     * @param {Function} expected The function that the object should be an instance of.
//     * @param {Object} actual The object to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isInstanceOf
//     * @static
//     */
//    isInstanceOf : function (expected /*:Function*/, actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!(actual instanceof expected)){
//            throw new YAHOO.util.ComparisonFailure(this._formatMessage(message, "Value isn't an instance of expected type."), expected, actual);
//        }
//    },
//    
//    /**
//     * Asserts that a value is a number.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isNumber
//     * @static
//     */
//    isNumber : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isNumber(actual)){
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Value should be a number."), actual);
//        }    
//    },    
//    
//    /**
//     * Asserts that a value is an object.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isObject
//     * @static
//     */
//    isObject : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isObject(actual)){
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Value should be an object."), actual);
//        }
//    },
//    
//    /**
//     * Asserts that a value is a string.
//     * @param {Object} actual The value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isString
//     * @static
//     */
//    isString : function (actual /*:Object*/, message /*:String*/) /*:Void*/ {
//        if (!YAHOO.lang.isString(actual)){
//            throw new YAHOO.util.UnexpectedValue(this._formatMessage(message, "Value should be a string."), actual);
//        }
//    },
//    
//    /**
//     * Asserts that a value is of a particular type. 
//     * @param {String} expectedType The expected type of the variable.
//     * @param {Object} actualValue The actual value to test.
//     * @param {String} message (Optional) The message to display if the assertion fails.
//     * @method isTypeOf
//     * @static
//     */
//    isTypeOf : function (expected /*:String*/, actual /*:Object*/, message /*:String*/) /*:Void*/{
//        if (typeof actual != expected){
//            throw new YAHOO.util.ComparisonFailure(this._formatMessage(message, "Value should be of type " + expected + "."), expected, typeof actual);
//        }
//    }

_END_
}

1;
