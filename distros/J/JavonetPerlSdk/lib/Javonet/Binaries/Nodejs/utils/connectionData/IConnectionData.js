const ConnectionType = require('../../utils/ConnectionType');

class IConnectionData {
    get connectionType() {
        throw new Error('You have to implement the method connectionType!');
    }

    get hostname() {
        throw new Error('You have to implement the method hostname!');
    }

    serializeConnectionData() {
        throw new Error('You have to implement the method serializeConnectionData!');
    }
}

module.exports = IConnectionData;