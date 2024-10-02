const Command = require('../../utils/Command')
const Type = require('../../utils/Type')
const StringEncodingMode = require('../../utils/StringEncodingMode')

const util = require('util');
let encoder = new util.TextEncoder();

class TypeSerializer {

    static encodePrimitive(payload_item) {
        if (payload_item === null) {
            return TypeSerializer.serializeNull()
        }
        if (payload_item instanceof Command) {
            return TypeSerializer.serializeCommand(payload_item)
        } else if (typeof (payload_item) === 'number' || payload_item instanceof Number) {
            if (Number.isInteger(payload_item)) {
                return TypeSerializer.serializeInt(payload_item)
            } else {
                return TypeSerializer.serializeDouble(payload_item)
            }
        } else if (typeof (payload_item) === 'string' || payload_item instanceof String) {
            return TypeSerializer.serializeString(payload_item)
        } else if (typeof (payload_item) === 'boolean' || payload_item instanceof Boolean) {
            return TypeSerializer.serializeBool(payload_item)
        } else {
            throw 'Unknown type - not supported in JavaScript'
        }
    }

    static serializeCommand(command) {
        const buffer = Buffer.alloc(7)
        buffer.writeUInt8(Type.JAVONET_COMMAND, 0)
        buffer.fill(Buffer.from(this.serializeIntValue(command.payload.length)), 1, 5)
        buffer.writeUInt8(command.runtime, 5)
        buffer.writeUInt8(command.commandType, 6)
        return buffer
    }

    static serializeString(string_value) {
        let bytes = encoder.encode(string_value)
        const buffer = Buffer.alloc(6 + bytes.length)
        buffer.writeUInt8(Type.JAVONET_STRING, 0)
        buffer.writeUInt8(StringEncodingMode.UTF8, 1)
        buffer.fill(Buffer.from(this.serializeIntValue(bytes.length)), 2, 6)
        buffer.fill(Buffer.from(bytes), 6, 6 + bytes.length)
        return buffer
    }

    static serializeInt(int_value) {
        const buffer = Buffer.alloc(6)
        buffer.writeUInt8(Type.JAVONET_INTEGER, 0)
        buffer.writeUInt8(4, 1)
        buffer.writeInt32LE(int_value, 2)
        return buffer
    }

    static serializeBool(bool_value) {
        const buffer = Buffer.alloc(3)
        buffer.writeUInt8(Type.JAVONET_BOOLEAN, 0)
        buffer.writeUInt8(1, 1)
        buffer.writeUInt8(bool_value ? 1 : 0, 2)
        return buffer
    }

    static serializeFloat(float_value) {
        const buffer = Buffer.alloc(6)
        buffer.writeUInt8(Type.JAVONET_FLOAT, 0)
        buffer.writeUInt8(4, 1)
        buffer.writeFloatLE(float_value, 2)
        return buffer
    }

    static serializeByte(byte_value) {
        const buffer = Buffer.alloc(3)
        buffer.writeUInt8(Type.JAVONET_BYTE, 0)
        buffer.writeUInt8(1, 1)
        buffer.writeUInt8(byte_value, 2)
        return buffer
    }

    static serializeChar(char_value) {
        const buffer = Buffer.alloc(3)
        buffer.writeUInt8(Type.JAVONET_CHAR, 0)
        buffer.writeUInt8(1, 1)
        buffer.writeUInt8(char_value, 2)
        return buffer
    }

    static serializeLongLong(longlong_value) {
        const buffer = Buffer.alloc(10)
        buffer.writeUInt8(Type.JAVONET_LONG_LONG, 0)
        buffer.writeUInt8(8, 1)
        buffer.writeBigInt64LE(BigInt(longlong_value), 2)
        return buffer
    }

    static serializeDouble(double_value) {
        const buffer = Buffer.alloc(10)
        buffer.writeUInt8(Type.JAVONET_DOUBLE, 0)
        buffer.writeUInt8(8, 1)
        buffer.writeDoubleLE(double_value, 2)
        return buffer
    }

    static serializeULLong(ullong_value) {
        const buffer = Buffer.alloc(10)
        buffer.writeUInt8(Type.JAVONET_UNSIGNED_LONG_LONG, 0)
        buffer.writeUInt8(8, 1)
        buffer.writeBigUInt64LE(ullong_value, 2)
        return buffer
    }

    static serializeUInt(uint_value) {
        const buffer = Buffer.alloc(6)
        buffer.writeUInt8(Type.JAVONET_UNSIGNED_INTEGER, 0)
        buffer.writeUInt8(4, 1)
        buffer.writeUInt32LE(uint_value, 2)
        return buffer
    }

    static serializeNull() {
        const buffer = Buffer.alloc(3)
        buffer.writeUInt8(Type.JAVONET_NULL, 0)
        buffer.writeUInt8(1, 1)
        buffer.writeUInt8(0, 2)
        return buffer
    }

    static serializeIntValue(int_value) {
        const buffer = Buffer.alloc(4)
        buffer.writeInt32LE(int_value, 0)
        return buffer
    }
}

module.exports = TypeSerializer