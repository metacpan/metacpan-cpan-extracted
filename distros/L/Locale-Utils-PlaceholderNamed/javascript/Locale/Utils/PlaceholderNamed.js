/*
version 0.007

requires:
http://jquery.com/
*/

// constructor
function localeUtilsPlaceholderNamed(argMap) {
    if (argMap) {
        this.modifierCode = argMap.modifierCode;
    }

    this.expandNamed = function(text, replaceMap) {
        if ( text === undefined ) {
            return text;
        }
        if ( replaceMap === undefined ) {
            return text;
        }
        var keyRegexPart
            = jQuery.map(
                replaceMap,
                function(value, key) {
                    return key.replace(/\W/g, '\\$&');
                }
            )
            .join('|');
        if ( keyRegexPart === '') {
            return text;
        }

        var placeholderRegex = new RegExp(
            '\\{' +
                '(' + keyRegexPart + ')' + // name
                '(?:' +
                    '[ ]*' + ':' +         // :
                    '(' + '[^}]+' + ')' +  // attr
                ')?' +
            '\\}',
            'g'
        );
        var modifierCode
            = this.modifierCode
            || function(value, attr) {
                return value;
            };

        return text.replace(
            placeholderRegex,
            function(match, name, attr) {
                var value = replaceMap[name];

                if ( attr !== undefined ) {
                    value = modifierCode(value, attr);
                    if ( value === undefined ) {
                        throw 'modifierCode returns nothing or undefined';
                    }
                }

                return value;
            }
        );
    };

    return;
}
