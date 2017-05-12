/*
version 1.024

requires:
http://jquery.com/
localeTextDomainOOExpandBabelFishLoc (if plugged)
localeTextDomainOOExpandGettext (if plugged)
localeTextDomainOOExpandGettextDomainAndCategory (if plugged)
localeTextDomainOOExpandGettextLoc (if plugged)
localeTextDomainOOExpandGettextLocDomainAndCategory (if plugged)
localeTextDomainOOUtilJoinSplitLexiconKeys
*/

// constructor
function localeTextDomainOO(argMap) {
    this.plugins  = argMap['plugins'];
    this.language = argMap['language'];
    this.domain   = argMap['domain']   === undefined ? '' : argMap['domain'];
    this.category = argMap['category'] === undefined ? '' : argMap['category'];
    this.project  = argMap['project'];
    this.filter   = argMap['filter'];
    this.logger   = argMap['logger'];
    this.lexicon  = argMap['lexicon'] || {};

    var self = this;
    jQuery.map(
        jQuery.map(
            self.lexicon,
            function (element,index) { return index }
        ),
        function (language, index) {
            var header = self.lexicon[language][''];
            var pluralFormula = header['plural'].replace(/\sor\s/g, ' || ');
            var code = 'return +(' + pluralFormula + ');';
            header['plural_code'] = new Function('n', code);
        }
    );

    if ( this.plugins ) {
        jQuery.each(
            this.plugins,
            function (index, plugin) {
                // N? __ d? c? n? p? x?
                if ( plugin === 'localeTextDomainOOExpandGettext' ) {
                    this.localeUtilsPlaceholderNamed = new localeUtilsPlaceholderNamed();
                    localeTextDomainOOExpandGettext(this);
                }
                if ( plugin === 'localeTextDomainOOExpandGettextDomainAndCategory' ) {
                    this.localeUtilsPlaceholderNamed = new localeUtilsPlaceholderNamed();
                    localeTextDomainOOExpandGettext(this);
                    localeTextDomainOOExpandGettextDomainAndCategory(this);
                }
                // N? loc_ d? c? n? p? x?
                if ( plugin === 'localeTextDomainOOExpandGettextLoc' ) {
                    this.localeUtilsPlaceholderNamed = new localeUtilsPlaceholderNamed();
                    localeTextDomainOOExpandGettextLoc(this);
                }
                if ( plugin === 'localeTextDomainOOExpandGettextLocDomainAndCategory' ) {
                    this.localeUtilsPlaceholderNamed = new localeUtilsPlaceholderNamed();
                    localeTextDomainOOExpandGettextLoc(this);
                    localeTextDomainOOExpandGettextLocDomainAndCategory(this);
                }
                // N? loc_b p?
                if ( plugin === 'localeTextDomainOOExpandBabelFishLoc' ) {
                    this.localeUtilsPlaceholderBabelFish = new localeUtilsPlaceholderBabelFish();
                    localeTextDomainOOExpandBabelFishLoc(this);
                }
            }
        );
    }

    var sprintf = function(template, args) {
        return template.replace(
            /%s/g,
            function() {
                return args.shift();
            }
        );
    }

    // method
    this.translate = function(msgctxt, msgid, msgid_plural, count, is_n, plural_callback) {
        var keyUtil = new localeTextDomainOOUtilJoinSplitLexiconKeys();
        var lexiconKey = keyUtil.joinLexiconKey({
            'language' : this.language,
            'domain'   : this.domain,
            'category' : this.category,
            'project'  : this.project
        });
        var lexicon = this.lexicon[lexiconKey] || {};

        var msgKey = keyUtil.joinMessageKey({
            'msgctxt'      : msgctxt,
            'msgid'        : msgid,
            'msgid_plural' : msgid_plural
        });
        if (plural_callback) {
            var plural_code = lexicon['']
                ? lexicon['']['plural_code']
                : undefined;
            if ( ! plural_code ) {
                throw 'Plural-Forms not found in lexicon "' + lexiconKey + '"';
            }
            plural_callback(plural_code);
        }
        else if (is_n) {
            var plural_code = lexicon['']
                ? lexicon['']['plural_code']
                : undefined;
            if ( ! plural_code ) {
                throw 'Plural-Forms not found in lexicon "' + lexiconKey + '"';
            }
            var index = plural_code(count);
            var msgstr_plural = lexicon[msgKey] && lexicon[msgKey]['msgstr_plural']
                ? lexicon[msgKey]['msgstr_plural'][index]
                : undefined;
            if ( ! msgstr_plural ) { // fallback
                msgstr_plural = index
                    ? msgid_plural
                    : msgid;
                var text = lexicon
                    ? 'Using lexicon "' + lexiconKey + '".'
                    : 'Lexicon "' + lexiconKey + '" not found.';
                this.language !== 'i-default'
                    && this.logger
                    && this.logger(
                        sprintf(
                            '%s msgstr_plural not found for for msgctxt=%s, msgid=%s, msgid_plural=%s.',
                            [
                                text,
                                ( msgctxt      === undefined ? 'undefined' : '"' + msgctxt + '"' ),
                                ( msgid        === undefined ? 'undefined' : '"' + msgid + '"' ),
                                ( msgid_plural === undefined ? 'undefined' : '"' + msgid_plural + '"' )
                            ]
                        ),
                        {
                            object: this,
                            type  : 'warn',
                            event : 'translation,fallback'
                        }
                    );
            }
            return msgstr_plural;
        }

        var msgstr = lexicon[msgKey]
            ? lexicon[msgKey]['msgstr']
            : undefined;
        if ( ! msgstr ) { // fallback
            msgstr = msgid;
            var text = lexicon
                ? 'Using lexicon "' + lexiconKey + '".'
                : 'Lexicon "' + lexiconKey + '" not found.';
            this.language !== 'i-default'
                && this.logger
                && this.logger(
                    sprintf(
                        '%s msgstr not found for msgctxt=%s, msgid=%s.',
                        [
                            text,
                            ( msgctxt === undefined ? 'undefined' : '"' + msgctxt + '"' ),
                            ( msgid   === undefined ? 'undefined' : '"' + msgid + '"' )
                        ]
                    ),
                    {
                        object : this,
                        type   : 'warn',
                        event  : 'translation,fallback'
                    }
                );
        }
        return msgstr;
    };

    return;
}
