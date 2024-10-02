const Command = require('../../utils/Command')
const Type = require('../../utils/Type')
const StringEncodingMode = require('../../utils/StringEncodingMode')
const {TextDecoder} = require("util");

class TypeDeserializer {
    static deserializeCommand(encodedCommand) {
        return new Command(encodedCommand[0], encodedCommand[1], [])
    }

    static deserializeString(stringEncodingMode, encodedString) {
        switch (stringEncodingMode) {
            case StringEncodingMode.ASCII:
                return String.fromCharCode(...encodedString)
            case StringEncodingMode.UTF8:
                let decoder = new TextDecoder('UTF-8');
                return decoder.decode(new Uint8Array(encodedString))
            case StringEncodingMode.UTF16:
                let str = "";
                let newBuffer = new Uint8Array(encodedString)
                for (let i = 0; i < newBuffer.length; i++) {
                    newBuffer[i] = encodedString[i]
                }
                for (let i = 0; i < encodedString.length; i = i + 2) {
                    str += String.fromCharCode(newBuffer[i] + 256 * newBuffer[i + 1])
                }
                return str;
            case StringEncodingMode.UTF32:
                throw "Type utf32-encoded string not supported in JavaScript"
            default:
                throw "Unknown string encoding - not supported in JavaScript";
        }
    }

    static deserializeInt(encodedInt) {
        return (
            (encodedInt[0] & 0xFF)
            | ((encodedInt[1] & 0xFF) << 8)
            | ((encodedInt[2] & 0xFF) << 16)
            | ((encodedInt[3] & 0xFF) << 24)
        )
    }

    static deserializeBool(encodedBool) {
        return encodedBool[0] === 1
    }

    static deserializeFloat(encodedFloat) {
        return Buffer.from(encodedFloat).readFloatLE()
    }

    static deserializeByte(encodedByte) {
        return Buffer.from(encodedByte).readUint8()
    }

    static deserializeChar(encodedChar) {
        return Buffer.from(encodedChar).readUint8()
    }

    static deserializeLongLong(encodedLongLong) {
        return Buffer.from(encodedLongLong).readBigInt64LE()
    }

    static deserializeDouble(encodedDouble) {
        return Buffer.from(encodedDouble).readDoubleLE()
    }

    static deserializeULLong(encodedULLong) {
        return Buffer.from(encodedULLong).readBigUInt64LE()
    }

    static deserializeUInt(encodedUInt) {
        return Buffer.from(encodedUInt).readUIntLE(0, 4)
    }

    static deserializeNull(encodedNull) {
        return null;
    }
}

module.exports = TypeDeserializer
