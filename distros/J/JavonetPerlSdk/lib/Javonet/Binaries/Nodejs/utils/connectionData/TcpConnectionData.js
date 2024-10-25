const dns = require('dns');
const ConnectionType = require('../../utils/ConnectionType');
const IConnectionData = require("./IConnectionData");

class TcpConnectionData extends IConnectionData{

    constructor(hostname, port) {
        super();
        this._port = port;
        this._hostname = hostname;
        this._connectionType = ConnectionType.TCP;
        if (hostname === "localhost") {
            this.ipAddress = "127.0.0.1";
        } else {
            this.ipAddress = this.resolveIpAddress(hostname);
        }
    }

    get connectionType() {
        return this._connectionType;
    }

    get hostname() {
        return this._hostname;
    }

    equals(other) {
        if (other instanceof TcpConnectionData) {
            return this.ipAddress === other.ipAddress && this._port === other._port;
        }
        return false;
    }

    resolveIpAddress(hostname) {
        // Check if the input is an IP address
        const ipPattern = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/;
        if (ipPattern.test(hostname)) {
            // If it's an IP address, return it directly
            return hostname;
        } else {
            // If it's not an IP address, try to resolve it as a hostname
            return dns.resolve4(hostname, (err, addresses) => {
                if (err) {
                    console.error(err);
                    return null;
                }
                return addresses[0];
            });
        }
    }

    serializeConnectionData() {
        let result = [this.connectionType];
        result = result.concat(this.#getAddressBytes());
        result = result.concat(this.#getPortBytes());
        return result;
    }

    #getAddressBytes() {
        return this.ipAddress.split('.').map(Number);
    }

    #getPortBytes() {
        return [this._port & 0xFF, this._port >> 8];
    }
    
}

module.exports = TcpConnectionData;