/*
version 2.003

requires:
http://jquery.com/
localeTextDomainOOUtilConstants
*/

// constructor
function localeTextDomainOOUtilJoinSplitLexiconKeys () {
    this.joinLexiconKey = function(argMap) {
        var lexiconKeySeparator
            = new localeTextDomainOOUtilConstants().lexiconKeySeparator();
        var lexiconKey = [
            (
                argMap.language === undefined
                ? 'i-default'
                : argMap.language.length
                ? argMap.language
                : 'i-default'
            ),
            ( argMap.category === undefined ? '' : argMap.category ),
            ( argMap.domain   === undefined ? '' : argMap.domain   )
        ].join(lexiconKeySeparator);
        lexiconKey +=
            argMap.project === undefined
            ? ''
            : lexiconKeySeparator + argMap.project;
        if ( argMap.project !== undefined ) {
            lexiconKey += lexiconKeySeparator + argMap.project;
        }

        return lexiconKey;
    };

    this.joinMessageKey = function(argMap) {
        var constants = new localeTextDomainOOUtilConstants();
        var messageKey
            = (
                argMap.msgid === undefined
                ? ''
                : argMap.msgid
            )
            + (
                ( argMap.msgid_plural !== undefined && argMap.msgid_plural.length )
                ? constants.pluralSeparator() + argMap.msgid_plural
                : ''
            )
            + (
                ( argMap.msgctxt !== undefined && argMap.msgctxt.length )
                ? constants.msgKeySeparator() + argMap.msgctxt
                : ''
            );

        return messageKey;
    };
}
