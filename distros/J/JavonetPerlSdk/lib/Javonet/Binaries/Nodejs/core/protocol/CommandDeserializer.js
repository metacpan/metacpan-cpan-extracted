const TypeDeserializer = require("./TypeDeserializer")
const Command = require("../../utils/Command")
const Type = require("../../utils/Type")
const StringEncodingMode = require("../../utils/StringEncodingMode")


class CommandDeserializer {
    constructor(buffer) {
        this.buffer = buffer
        this.command = new Command(
            buffer[0],
            buffer[10],
            []
        )
        this.position = 11
    }

    deserialize() {
        while (!this.isAtEnd()) {
            this.command = this.command.addArgToPayload((this.readObject(this.buffer[this.position])))
        }
        return this.command
    }

    isAtEnd() {
        return this.position === this.buffer.length
    }

    readObject(typeNum) {
        let type = Object.entries(Type).find(entry => entry[1] === typeNum)[0]
        switch (type) {
            case 'JAVONET_COMMAND':
                return this.readCommand()
            case 'JAVONET_STRING':
                return this.readString()
            case 'JAVONET_INTEGER':
                return this.readInt()
            case 'JAVONET_BOOLEAN':
                return this.readBool();
            case 'JAVONET_FLOAT':
                return this.readFloat();
            case 'JAVONET_BYTE':
                return this.readByte();
            case 'JAVONET_CHAR':
                return this.readChar();
            case 'JAVONET_LONG_LONG':
                return this.readLongLong();
            case 'JAVONET_DOUBLE':
                return this.readDouble();
            case 'JAVONET_UNSIGNED_LONG_LONG':
                return this.readUllong
            case 'JAVONET_UNSIGNED_INTEGER':
                return this.readUInt()
            case 'JAVONET_NULL':
                return this.readNull()
            default:
                throw 'Unknown type - not supported in JavaScript'
        }
    }

    readCommand() {
        let p = this.position
        let numberOfElementsInPayload = TypeDeserializer.deserializeInt(this.buffer.slice(p + 1, p + 5))
        let runtime = this.buffer[p + 5]
        let type = this.buffer[p + 6]
        this.position += 7
        let command = new Command(runtime, type, [])
        return this.readCommandRecursively(numberOfElementsInPayload, command)
    }

    readCommandRecursively(numberOfElementsInPayloadLeft, cmd) {
        if (numberOfElementsInPayloadLeft === 0) return cmd
        let p = this.position
        cmd = cmd.addArgToPayload(this.readObject(this.buffer[p]))
        return this.readCommandRecursively(numberOfElementsInPayloadLeft - 1, cmd)
    }

    readString() {
        let p = this.position
        let stringEncodingMode = this.buffer[p + 1]
        let size = TypeDeserializer.deserializeInt(this.buffer.slice(p + 2, p + 6))
        this.position += 6
        p = this.position
        this.position += size
        return TypeDeserializer.deserializeString(stringEncodingMode, this.buffer.slice(p, p + size))

    }

    readInt() {
        let size = 4
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeInt(this.buffer.slice(p, p + size))
    }

    readBool() {
        let size = 1
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeBool(this.buffer.slice(p, p + size))
    }

    readFloat() {
        let size = 4
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeFloat(this.buffer.slice(p, p + size))
    }

    readByte() {
        let size = 1
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeByte(this.buffer.slice(p, p + size))
    }

    readChar() {
        let size = 1
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeChar(this.buffer.slice(p, p + size))
    }

    readLongLong() {
        let size = 8
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeLongLong(this.buffer.slice(p, p + size))
    }

    readDouble() {
        let size = 8
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeDouble(this.buffer.slice(p, p + size))
    }

    readUllong() {
        let size = 8
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeULLong(this.buffer.slice(p, p + size))
    }

    readUInt() {
        let size = 4
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeUInt(this.buffer.slice(p, p + size))
    }

    readNull() {
        let size = 1
        this.position += 2
        let p = this.position
        this.position += size
        return TypeDeserializer.deserializeNull()
    }
}

module.exports = CommandDeserializer