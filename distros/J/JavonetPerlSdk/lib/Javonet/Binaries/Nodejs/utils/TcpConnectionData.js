const dns = require('dns');

class TcpConnectionData {

    constructor(hostname, port) {
        this.port = port;
        if (hostname === "localhost") {
            this.ipAddress = "127.0.0.1";
        } else {
            this.ipAddress = this.resolveIpAddress(hostname);
        }
    }

    equals(other) {
        if (other instanceof TcpConnectionData) {
            return this.ipAddress === other.ipAddress && this.port === other.port;
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

    getAddressBytes() {
        return this.ipAddress.split('.').map(Number);
    }

    getPortBytes() {
        return [this.port & 0xFF, this.port >> 8];
    }
    
}

module.exports = TcpConnectionData;