const os = require('os');
const process = require('process');

class RuntimeLogger {
    static notLoggedYet = true;

    static getRuntimeInfo() {
        try {
            return `JavaScript Managed Runtime Info:\n` +
                `Node.js Version: ${process.version}\n` +
                `OS Version: ${os.type()} ${os.release()}\n` +
                `Process Architecture: ${os.arch()}\n` +
                `Current Directory: ${process.cwd()}\n`;
        } catch (e) {
            return "JavaScript Managed Runtime Info: Error while fetching runtime info";
        }
    }

    static printRuntimeInfo() {
        if (this.notLoggedYet) {
            console.log(this.getRuntimeInfo());
            this.notLoggedYet = false;
        }
    }
}

module.exports = RuntimeLogger;