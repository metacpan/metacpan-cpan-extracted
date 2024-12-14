const https = require('https')
const os = require('os')
// const packageJson = require('../../../package.json')

const address = 'https://dc.services.visualstudio.com/v2/track'

/**
 *
 * @param {any} e
 * @param {string} licenseKey
 */
function sendExceptionToAppInsights(e, licenseKey) {
    return new Promise((resolve, reject) => {
        try {
            const instrumentationKey = '2c751560-90c8-40e9-b5dd-534566514723'
            // const javonetVersion = packageJson.version ? packageJson.version : '2.0.0'
            const javonetVersion = '2.0.0'
            const nodeName = os.hostname()
            const operationName = 'JavonetSdkException'
            const osName = os.platform()
            const callingRuntimeName = 'Nodejs'
            const eventMessage = e.message

            const nowGMT = new Date().toISOString()
            const jsonPayload = JSON.stringify({
                name: 'AppEvents',
                time: nowGMT,
                iKey: instrumentationKey,
                tags: {
                    'ai.application.ver': javonetVersion,
                    'ai.cloud.roleInstance': nodeName,
                    'ai.operation.id': '0',
                    'ai.operation.parentId': '0',
                    'ai.operation.name': operationName,
                    'ai.internal.sdkVersion': 'javonet:' + javonetVersion,
                    'ai.internal.nodeName': nodeName,
                },
                data: {
                    baseType: 'EventData',
                    baseData: {
                        ver: 2,
                        name: eventMessage,
                        properties: {
                            OperatingSystem: osName,
                            LicenseKey: licenseKey,
                            CallingTechnology: callingRuntimeName,
                        },
                    },
                },
            })

            const options = {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': jsonPayload.length,
                },
            }

            const req = https.request(address, options, (res) => {
                console.log('POST Response Code ::', res.statusCode)
                resolve(res.statusCode)
            })

            req.on('error', (error) => {
                console.error(error)
                reject(error)
            })

            req.write(jsonPayload)
            req.end()
        } catch (error) {
            console.error(error)
            reject(error)
        }
    })
}

module.exports = sendExceptionToAppInsights
