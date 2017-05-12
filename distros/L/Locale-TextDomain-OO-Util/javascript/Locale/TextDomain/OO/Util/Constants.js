/*
verstion 2.003

requires:
*/

// constructor
function localeTextDomainOOUtilConstants() {
    this.lexiconKeySeparator = function() {
        return ':';
    };

    this.pluralSeparator = function() {
        return '{PLURAL_SEPARATOR}';
    };

    this.msgKeySeparator = function() {
        return '{MSG_KEY_SEPARATOR}';
    };
}
