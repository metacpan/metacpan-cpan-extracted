/*
version 0.003

requires:
http://jquery.com/
*/

// constructor
function localeUtilsPlaceholderBabelFish(argMap) {
    var modifierCode;
    if (argMap && argMap.modifierCode) {
        modifierCode = argMap.modifierCode;
    }
    else {
        modifierCode = function(value, attr) {
            if ( attr && attr.match(/\bhtml\b/) ) {
                var encodeMap = {
                    '<' : '&lt;',
                    '>' : '&gt;',
                    '&' : '&amp;',
                    '"' : '&quot;'
                };
                value = value.replace(
                    /([<>&\\"])/g,
                    function(match, chr) {
                        return encodeMap[chr];
                    }
                );
            }
            return value;
        };
    }
    this.modifierCode = function() {
        return modifierCode;
    }

    function keyRegex(replaceMap) {
        if ( ! replaceMap ) {
            return '';
        }

        return jQuery
            .map(
                replaceMap,
                function(value, key) {
                    return key.replace(/\W/g, '\\$&');
                }
            )
            .join('|');
    }

    function simpleReplace(text, replaceMap, keyRegexPart) {
        var placeholderRegex = new RegExp(
            '\\\\(\\#)' +                  // escaped #
            '|' +
            '\\#\\{' +                     // #{
                '(' + keyRegexPart + ')' + // name
                '(?:' +
                    '[ ]*' + ':' +         // :
                    '(' + '[^}]+' + ')' +  // attr
                ')?' +
            '\\}',                         // }
            'g'
        );

        return text.replace(
            placeholderRegex,
            function(match, escaped, name, attr) {
                if ( escaped ) {
                    return '\\#';
                }
                return modifierCode(replaceMap[name], attr);
            }
        );
    }

    function replaceInner (inner, count) {
        inner = inner.replace(/\\\|/g, '\0');
        var plurals = inner.split('|');
        var pluralForm = localeUtilsPlaceholderBabelFish.prototype.pluralCode(count);
        var normalPlurals  = [];
        var specialPlurals = [];
        jQuery.each(
            plurals,
            function (index, plural) {
                plural = plural.replace(/\0/g, '\\|');
                var result = plural.match(/^[=](\d+)\s+(.*)$/);
                if (result) {
                    specialPlurals.push([ result[1], result[2] ]);
                }
                else {
                    normalPlurals.push(plural);
                }
            }
        );

        var text;
        jQuery.each(
            specialPlurals,
            function (index, pair) {
                if ( pair[0] == count ) {
                    text = pair[1];
                }
            }
        );
        if ( text ) {
            return text;
        }

        var minIndex = Math.min( pluralForm, normalPlurals.length - 1 );

        return normalPlurals[minIndex];
    }

    function pluralReplace(text, replaceMap, keyRegexPart) {
        var placeholderRegex = new RegExp(
            '\\\\(\\()' +                   // escaped (
            '|' +
            '\\(\\(' +                      // ((
            '(.*?)' +                       // inner
            '\\)\\)' +                      // ))
            '(?:' +
                ':' +                       // :
                '(' + keyRegexPart + ')' +  // name
            ')?',
            'g'
        );

        return text.replace(
            placeholderRegex,
            function(match, escaped, inner, name) {
                if ( escaped ) {
                    return escaped;
                }
                var value = name
                    ? replaceMap[name]
                    : replaceMap['count'];
                return value !== undefined // undefined check because of number 0
                    ? replaceInner(inner, value)
                    : match;
            }
        );
    }

    this.expandBabelFish = function(text, replaceMap) {
        if ( ! text ) {
            return text;
        }
        // undefined check because of no placeholders -> no replaceMap parameter
        if ( replaceMap !== undefined && typeof replaceMap !== 'object' ) {
            replaceMap = { 'count' : replaceMap };
        }
        var keyRegexPart = keyRegex(replaceMap);
        if ( keyRegexPart !== '' ) {
            text = simpleReplace(text, replaceMap, keyRegexPart);
            text = pluralReplace(text, replaceMap, keyRegexPart);
        }
        text = text.replace(/\\/g, '');

        return text;
    };

    return;
}
