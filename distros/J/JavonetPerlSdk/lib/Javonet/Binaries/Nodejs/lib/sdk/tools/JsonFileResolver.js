const fs = require('fs')

function hasOwnProperty(obj, key) {
    return Object.prototype.hasOwnProperty.call(obj, key)
}

class JsonFileResolver {
    constructor(path) {
        this.path = path
        try {
            const data = fs.readFileSync(this.path, 'utf8')
            this.jsonObject = JSON.parse(data)
            // eslint-disable-next-line no-unused-vars
        } catch (err) {
            throw new Error(
                `Configuration file ${this.path} not found. Please check your configuration file.`
            )
        }
    }
    getLicenseKey() {
        if (!hasOwnProperty(this.jsonObject, 'licenseKey')) {
            throw new Error(
                'License key not found in configuration file. Please check your configuration file.'
            )
        }
        return this.jsonObject.licenseKey
    }

    getRuntimes() {
        return this.jsonObject.runtimes
    }

    getRuntime(runtimeName, configName) {
        const runtimes = this.getRuntimes()
        if (hasOwnProperty(runtimes, runtimeName)) {
            const runtime = runtimes[runtimeName]
            if (Array.isArray(runtime)) {
                for (let item of runtime) {
                    if (item.name === configName) {
                        return item
                    }
                }
            } else if (runtime.name === configName) {
                return runtime
            }
        }
        throw new Error(
            `Runtime config ${configName} not found in configuration file for runtime ${runtimeName}. Please check your configuration file.`
        )
    }

    getChannel(runtimeName, configName) {
        const runtime = this.getRuntime(runtimeName, configName)
        if (!hasOwnProperty(runtime, 'channel')) {
            throw new Error(
                `Channel key not found in configuration file for config ${configName}. Please check your configuration file.`
            )
        }
        return runtime.channel
    }

    getChannelType(runtimeName, configName) {
        const channel = this.getChannel(runtimeName, configName)
        if (!hasOwnProperty(channel, 'type')) {
            throw new Error(
                `Channel type not found in configuration file for config ${configName}. Please check your configuration file.`
            )
        }
        return channel.type
    }

    getChannelHost(runtimeName, configName) {
        const channel = this.getChannel(runtimeName, configName)
        if (!hasOwnProperty(channel, 'host')) {
            throw new Error(
                `Channel host not found in configuration file for config ${configName}. Please check your configuration file.`
            )
        }
        return channel.host
    }

    getChannelPort(runtimeName, configName) {
        const channel = this.getChannel(runtimeName, configName)
        if (!hasOwnProperty(channel, 'port')) {
            throw new Error(
                `Channel port not found in configuration file for config ${configName}. Please check your configuration file.`
            )
        }
        return channel.port
    }

    getModules(runtimeName, configName) {
        const runtime = this.getRuntime(runtimeName, configName)
        if (hasOwnProperty(runtime, 'modules')) {
            return runtime.modules
        }
        return ''
    }
}

module.exports = JsonFileResolver
