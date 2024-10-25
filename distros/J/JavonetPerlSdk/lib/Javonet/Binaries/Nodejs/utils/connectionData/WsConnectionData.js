const ConnectionType = require('../../utils/ConnectionType');
const IConnectionData = require('./IConnectionData');

class WsConnectionData extends IConnectionData {
    constructor(hostname) {
        super();
        this._hostname = hostname;
        this._connectionType = ConnectionType.WEB_SOCKET;
    }

    get connectionType() {
        return this._connectionType;
    }

    get hostname() {
        return this._hostname;
    }

    set hostname(value) {
        this._hostname = value;
    }

    serializeConnectionData() {
        return [this.connectionType, 0, 0, 0, 0, 0, 0];
    }

    equals(other) {
        return other instanceof WsConnectionData && this._hostname === other.hostname;
    }

}

module.exports = WsConnectionData;