/**
 * Represents WebSocket connection data.
 */
export class WsConnectionData {
    /**
     * Constructs a new WsConnectionData instance.
     * @param hostname - The hostname of the connection.
     */
    constructor(hostname: string)

    readonly connectionType: any

    /** The hostname of the connection. */
    hostname: any

    /**
     * Serializes the connection data.
     * @returns An array of connection data values.
     */
    serializeConnectionData(): number[]

    /**
     * Checks equality with another WsConnectionData object.
     * @param other - The object to compare with.
     * @returns `true` if equal, otherwise `false`.
     */
    equals(other: any): boolean
}

declare enum RuntimeName {
    Clr = 0,
    Go = 1,
    Jvm = 2,
    Netcore = 3,
    Perl = 4,
    Python = 5,
    Ruby = 6,
    Nodejs = 7,
    Cpp = 8,
}

interface RuntimeChannel {
    type: 'inMemory' | 'tcp' | 'webSocket'
    host?: string
    port?: number
}

interface Runtime {
    name: string
    customOptions: string
    modules: string
    channel: RuntimeChannel
    runtimeName: RuntimeName
}

type Runtimes = {
    [Key in keyof typeof RuntimeName]: Runtime[]
}

export interface ConfigSource {
    [key: string]: any
    licenseKey: string
    runtimes: Partial<Runtimes>
}
