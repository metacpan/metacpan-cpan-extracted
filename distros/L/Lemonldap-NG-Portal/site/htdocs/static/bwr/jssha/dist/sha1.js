/**
 * A JavaScript implementation of the SHA family of hashes - defined in FIPS PUB 180-4, FIPS PUB 202,
 * and SP 800-185 - as well as the corresponding HMAC implementation as defined in FIPS PUB 198-1.
 *
 * Copyright 2008-2022 Brian Turek, 1998-2009 Paul Johnston & Contributors
 * Distributed under the BSD License
 * See http://caligatio.github.com/jsSHA/ for more information
 *
 * Two ECMAScript polyfill functions carry the following license:
 *
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED,
 * INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
 * MERCHANTABLITY OR NON-INFRINGEMENT.
 *
 * See the Apache Version 2.0 License for specific language governing permissions and limitations under the License.
 */

(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define(factory) :
    (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.jsSHA = factory());
})(this, (function () { 'use strict';
    var extendStatics = function(d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };

    function __extends(d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    }

    /**
     * Return type for all the *2packed functions
     */
    var b64Tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var arraybuffer_error = "ARRAYBUFFER not supported by this environment";
    var uint8array_error = "UINT8ARRAY not supported by this environment";
    /**
     * Convert a string to an array of words.
     *
     * There is a known bug with an odd number of existing bytes and using a UTF-16 encoding.  However, this function is
     * used such that the existing bytes are always a result of a previous UTF-16 str2packed call and therefore there
     * should never be an odd number of existing bytes.

     * @param str Unicode string to be converted to binary representation.
     * @param utfType The Unicode type to use to encode the source string.
     * @param existingPacked A packed int array of bytes to append the results to.
     * @param existingPackedLen The number of bits in `existingPacked`.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns Hashmap of the packed values.
     */
    function str2packed(str, utfType, existingPacked, existingPackedLen, bigEndianMod) {
        var codePnt, codePntArr, byteCnt = 0, i, j, intOffset, byteOffset, shiftModifier, transposeBytes;
        existingPackedLen = existingPackedLen || 0;
        var packed = existingPacked || [0], existingByteLen = existingPackedLen >>> 3;
        if ("UTF8" === utfType) {
            shiftModifier = bigEndianMod === -1 ? 3 : 0;
            for (i = 0; i < str.length; i += 1) {
                codePnt = str.charCodeAt(i);
                codePntArr = [];
                if (0x80 > codePnt) {
                    codePntArr.push(codePnt);
                }
                else if (0x800 > codePnt) {
                    codePntArr.push(0xc0 | (codePnt >>> 6));
                    codePntArr.push(0x80 | (codePnt & 0x3f));
                }
                else if (0xd800 > codePnt || 0xe000 <= codePnt) {
                    codePntArr.push(0xe0 | (codePnt >>> 12), 0x80 | ((codePnt >>> 6) & 0x3f), 0x80 | (codePnt & 0x3f));
                }
                else {
                    i += 1;
                    codePnt = 0x10000 + (((codePnt & 0x3ff) << 10) | (str.charCodeAt(i) & 0x3ff));
                    codePntArr.push(0xf0 | (codePnt >>> 18), 0x80 | ((codePnt >>> 12) & 0x3f), 0x80 | ((codePnt >>> 6) & 0x3f), 0x80 | (codePnt & 0x3f));
                }
                for (j = 0; j < codePntArr.length; j += 1) {
                    byteOffset = byteCnt + existingByteLen;
                    intOffset = byteOffset >>> 2;
                    while (packed.length <= intOffset) {
                        packed.push(0);
                    }
                    /* Known bug kicks in here */
                    packed[intOffset] |= codePntArr[j] << (8 * (shiftModifier + bigEndianMod * (byteOffset % 4)));
                    byteCnt += 1;
                }
            }
        }
        else {
            /* UTF16BE or UTF16LE */
            shiftModifier = bigEndianMod === -1 ? 2 : 0;
            /* Internally strings are UTF-16BE so transpose bytes under two conditions:
             * need LE and not switching endianness due to SHA-3
             * need BE and switching endianness due to SHA-3 */
            transposeBytes = ("UTF16LE" === utfType && bigEndianMod !== 1) || ("UTF16LE" !== utfType && bigEndianMod === 1);
            for (i = 0; i < str.length; i += 1) {
                codePnt = str.charCodeAt(i);
                if (transposeBytes === true) {
                    j = codePnt & 0xff;
                    codePnt = (j << 8) | (codePnt >>> 8);
                }
                byteOffset = byteCnt + existingByteLen;
                intOffset = byteOffset >>> 2;
                while (packed.length <= intOffset) {
                    packed.push(0);
                }
                packed[intOffset] |= codePnt << (8 * (shiftModifier + bigEndianMod * (byteOffset % 4)));
                byteCnt += 2;
            }
        }
        return { value: packed, binLen: byteCnt * 8 + existingPackedLen };
    }
    /**
     * Convert a hex string to an array of words.
     *
     * @param str Hexadecimal string to be converted to binary representation.
     * @param existingPacked A packed int array of bytes to append the results to.
     * @param existingPackedLen The number of bits in `existingPacked` array.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns Hashmap of the packed values.
     */
    function hex2packed(str, existingPacked, existingPackedLen, bigEndianMod) {
        var i, num, intOffset, byteOffset;
        if (0 !== str.length % 2) {
            throw new Error("String of HEX type must be in byte increments");
        }
        existingPackedLen = existingPackedLen || 0;
        var packed = existingPacked || [0], existingByteLen = existingPackedLen >>> 3, shiftModifier = bigEndianMod === -1 ? 3 : 0;
        for (i = 0; i < str.length; i += 2) {
            num = parseInt(str.substr(i, 2), 16);
            if (!isNaN(num)) {
                byteOffset = (i >>> 1) + existingByteLen;
                intOffset = byteOffset >>> 2;
                while (packed.length <= intOffset) {
                    packed.push(0);
                }
                packed[intOffset] |= num << (8 * (shiftModifier + bigEndianMod * (byteOffset % 4)));
            }
            else {
                throw new Error("String of HEX type contains invalid characters");
            }
        }
        return { value: packed, binLen: str.length * 4 + existingPackedLen };
    }
    /**
     * Convert a string of raw bytes to an array of words.
     *
     * @param str String of raw bytes to be converted to binary representation.
     * @param existingPacked A packed int array of bytes to append the results to.
     * @param existingPackedLen The number of bits in `existingPacked` array.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns Hashmap of the packed values.
     */
    function bytes2packed(str, existingPacked, existingPackedLen, bigEndianMod) {
        var codePnt, i, intOffset, byteOffset;
        existingPackedLen = existingPackedLen || 0;
        var packed = existingPacked || [0], existingByteLen = existingPackedLen >>> 3, shiftModifier = bigEndianMod === -1 ? 3 : 0;
        for (i = 0; i < str.length; i += 1) {
            codePnt = str.charCodeAt(i);
            byteOffset = i + existingByteLen;
            intOffset = byteOffset >>> 2;
            if (packed.length <= intOffset) {
                packed.push(0);
            }
            packed[intOffset] |= codePnt << (8 * (shiftModifier + bigEndianMod * (byteOffset % 4)));
        }
        return { value: packed, binLen: str.length * 8 + existingPackedLen };
    }
    /**
     * Convert a base-64 string to an array of words.
     *
     * @param str Base64-encoded string to be converted to binary representation.
     * @param existingPacked A packed int array of bytes to append the results to.
     * @param existingPackedLen The number of bits in `existingPacked` array.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns Hashmap of the packed values.
     */
    function b642packed(str, existingPacked, existingPackedLen, bigEndianMod) {
        var byteCnt = 0, index, i, j, tmpInt, strPart, intOffset, byteOffset;
        existingPackedLen = existingPackedLen || 0;
        var packed = existingPacked || [0], existingByteLen = existingPackedLen >>> 3, shiftModifier = bigEndianMod === -1 ? 3 : 0, firstEqual = str.indexOf("=");
        if (-1 === str.search(/^[a-zA-Z0-9=+/]+$/)) {
            throw new Error("Invalid character in base-64 string");
        }
        str = str.replace(/=/g, "");
        if (-1 !== firstEqual && firstEqual < str.length) {
            throw new Error("Invalid '=' found in base-64 string");
        }
        for (i = 0; i < str.length; i += 4) {
            strPart = str.substr(i, 4);
            tmpInt = 0;
            for (j = 0; j < strPart.length; j += 1) {
                index = b64Tab.indexOf(strPart.charAt(j));
                tmpInt |= index << (18 - 6 * j);
            }
            for (j = 0; j < strPart.length - 1; j += 1) {
                byteOffset = byteCnt + existingByteLen;
                intOffset = byteOffset >>> 2;
                while (packed.length <= intOffset) {
                    packed.push(0);
                }
                packed[intOffset] |=
                    ((tmpInt >>> (16 - j * 8)) & 0xff) << (8 * (shiftModifier + bigEndianMod * (byteOffset % 4)));
                byteCnt += 1;
            }
        }
        return { value: packed, binLen: byteCnt * 8 + existingPackedLen };
    }
    /**
     * Convert an Uint8Array to an array of words.
     *
     * @param arr Uint8Array to be converted to binary representation.
     * @param existingPacked A packed int array of bytes to append the results to.
     * @param existingPackedLen The number of bits in `existingPacked` array.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns Hashmap of the packed values.
     */
    function uint8array2packed(arr, existingPacked, existingPackedLen, bigEndianMod) {
        var i, intOffset, byteOffset;
        existingPackedLen = existingPackedLen || 0;
        var packed = existingPacked || [0], existingByteLen = existingPackedLen >>> 3, shiftModifier = bigEndianMod === -1 ? 3 : 0;
        for (i = 0; i < arr.length; i += 1) {
            byteOffset = i + existingByteLen;
            intOffset = byteOffset >>> 2;
            if (packed.length <= intOffset) {
                packed.push(0);
            }
            packed[intOffset] |= arr[i] << (8 * (shiftModifier + bigEndianMod * (byteOffset % 4)));
        }
        return { value: packed, binLen: arr.length * 8 + existingPackedLen };
    }
    /**
     * Convert an ArrayBuffer to an array of words
     *
     * @param arr ArrayBuffer to be converted to binary representation.
     * @param existingPacked A packed int array of bytes to append the results to.
     * @param existingPackedLen The number of bits in `existingPacked` array.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns Hashmap of the packed values.
     */
    function arraybuffer2packed(arr, existingPacked, existingPackedLen, bigEndianMod) {
        return uint8array2packed(new Uint8Array(arr), existingPacked, existingPackedLen, bigEndianMod);
    }
    /**
     * Function that takes an input format and UTF encoding and returns the appropriate function used to convert the input.
     *
     * @param format The format of the input to be converted
     * @param utfType The string encoding to use for TEXT inputs.
     * @param bigEndianMod Modifier for whether hash function is big or small endian
     * @returns Function that will convert an input to a packed int array.
     */
    function getStrConverter(format, utfType, bigEndianMod
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    ) {
        /* Validate encoding */
        switch (utfType) {
            case "UTF8":
            /* Fallthrough */
            case "UTF16BE":
            /* Fallthrough */
            case "UTF16LE":
                /* Fallthrough */
                break;
            default:
                throw new Error("encoding must be UTF8, UTF16BE, or UTF16LE");
        }
        /* Map inputFormat to the appropriate converter */
        switch (format) {
            case "HEX":
                /**
                 * @param str String of hexadecimal bytes to be converted to binary representation.
                 * @param existingPacked A packed int array of bytes to append the results to.
                 * @param existingPackedLen The number of bits in `existingPacked` array.
                 * @returns Hashmap of the packed values.
                 */
                return function (str, existingBin, existingBinLen) {
                    return hex2packed(str, existingBin, existingBinLen, bigEndianMod);
                };
            case "TEXT":
                /**
                 * @param str Unicode string to be converted to binary representation.
                 * @param existingPacked A packed int array of bytes to append the results to.
                 * @param existingPackedLen The number of bits in `existingPacked` array.
                 * @returns Hashmap of the packed values.
                 */
                return function (str, existingBin, existingBinLen) {
                    return str2packed(str, utfType, existingBin, existingBinLen, bigEndianMod);
                };
            case "B64":
                /**
                 * @param str Base64-encoded string to be converted to binary representation.
                 * @param existingPacked A packed int array of bytes to append the results to.
                 * @param existingPackedLen The number of bits in `existingPacked` array.
                 * @returns Hashmap of the packed values.
                 */
                return function (str, existingBin, existingBinLen) {
                    return b642packed(str, existingBin, existingBinLen, bigEndianMod);
                };
            case "BYTES":
                /**
                 * @param str String of raw bytes to be converted to binary representation.
                 * @param existingPacked A packed int array of bytes to append the results to.
                 * @param existingPackedLen The number of bits in `existingPacked` array.
                 * @returns Hashmap of the packed values.
                 */
                return function (str, existingBin, existingBinLen) {
                    return bytes2packed(str, existingBin, existingBinLen, bigEndianMod);
                };
            case "ARRAYBUFFER":
                try {
                    new ArrayBuffer(0);
                }
                catch (ignore) {
                    throw new Error(arraybuffer_error);
                }
                /**
                 * @param arr ArrayBuffer to be converted to binary representation.
                 * @param existingPacked A packed int array of bytes to append the results to.
                 * @param existingPackedLen The number of bits in `existingPacked` array.
                 * @returns Hashmap of the packed values.
                 */
                return function (arr, existingBin, existingBinLen) {
                    return arraybuffer2packed(arr, existingBin, existingBinLen, bigEndianMod);
                };
            case "UINT8ARRAY":
                try {
                    new Uint8Array(0);
                }
                catch (ignore) {
                    throw new Error(uint8array_error);
                }
                /**
                 * @param arr Uint8Array to be converted to binary representation.
                 * @param existingPacked A packed int array of bytes to append the results to.
                 * @param existingPackedLen The number of bits in `existingPacked` array.
                 * @returns Hashmap of the packed values.
                 */
                return function (arr, existingBin, existingBinLen) {
                    return uint8array2packed(arr, existingBin, existingBinLen, bigEndianMod);
                };
            default:
                throw new Error("format must be HEX, TEXT, B64, BYTES, ARRAYBUFFER, or UINT8ARRAY");
        }
    }
    /**
     * Convert an array of words to a hexadecimal string.
     *
     * toString() won't work here because it removes preceding zeros (e.g. 0x00000001.toString === "1" rather than
     * "00000001" and 0.toString(16) === "0" rather than "00").
     *
     * @param packed Array of integers to be converted.
     * @param outputLength Length of output in bits.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @param formatOpts Hashmap containing validated output formatting options.
     * @returns Hexadecimal representation of `packed`.
     */
    function packed2hex(packed, outputLength, bigEndianMod, formatOpts) {
        var hex_tab = "0123456789abcdef";
        var str = "", i, srcByte;
        var length = outputLength / 8, shiftModifier = bigEndianMod === -1 ? 3 : 0;
        for (i = 0; i < length; i += 1) {
            /* The below is more than a byte but it gets taken care of later */
            srcByte = packed[i >>> 2] >>> (8 * (shiftModifier + bigEndianMod * (i % 4)));
            str += hex_tab.charAt((srcByte >>> 4) & 0xf) + hex_tab.charAt(srcByte & 0xf);
        }
        return formatOpts["outputUpper"] ? str.toUpperCase() : str;
    }
    /**
     * Convert an array of words to a base-64 string.
     *
     * @param packed Array of integers to be converted.
     * @param outputLength Length of output in bits.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @param formatOpts Hashmap containing validated output formatting options.
     * @returns Base64-encoded representation of `packed`.
     */
    function packed2b64(packed, outputLength, bigEndianMod, formatOpts) {
        var str = "", i, j, triplet, int1, int2;
        var length = outputLength / 8, shiftModifier = bigEndianMod === -1 ? 3 : 0;
        for (i = 0; i < length; i += 3) {
            int1 = i + 1 < length ? packed[(i + 1) >>> 2] : 0;
            int2 = i + 2 < length ? packed[(i + 2) >>> 2] : 0;
            triplet =
                (((packed[i >>> 2] >>> (8 * (shiftModifier + bigEndianMod * (i % 4)))) & 0xff) << 16) |
                    (((int1 >>> (8 * (shiftModifier + bigEndianMod * ((i + 1) % 4)))) & 0xff) << 8) |
                    ((int2 >>> (8 * (shiftModifier + bigEndianMod * ((i + 2) % 4)))) & 0xff);
            for (j = 0; j < 4; j += 1) {
                if (i * 8 + j * 6 <= outputLength) {
                    str += b64Tab.charAt((triplet >>> (6 * (3 - j))) & 0x3f);
                }
                else {
                    str += formatOpts["b64Pad"];
                }
            }
        }
        return str;
    }
    /**
     * Convert an array of words to raw bytes string.
     *
     * @param packed Array of integers to be converted.
     * @param outputLength Length of output in bits.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns Raw bytes representation of `packed`.
     */
    function packed2bytes(packed, outputLength, bigEndianMod) {
        var str = "", i, srcByte;
        var length = outputLength / 8, shiftModifier = bigEndianMod === -1 ? 3 : 0;
        for (i = 0; i < length; i += 1) {
            srcByte = (packed[i >>> 2] >>> (8 * (shiftModifier + bigEndianMod * (i % 4)))) & 0xff;
            str += String.fromCharCode(srcByte);
        }
        return str;
    }
    /**
     * Convert an array of words to an ArrayBuffer.
     *
     * @param packed Array of integers to be converted.
     * @param outputLength Length of output in bits.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns An ArrayBuffer containing bytes from `packed.
     */
    function packed2arraybuffer(packed, outputLength, bigEndianMod) {
        var i;
        var length = outputLength / 8, retVal = new ArrayBuffer(length), arrView = new Uint8Array(retVal), shiftModifier = bigEndianMod === -1 ? 3 : 0;
        for (i = 0; i < length; i += 1) {
            arrView[i] = (packed[i >>> 2] >>> (8 * (shiftModifier + bigEndianMod * (i % 4)))) & 0xff;
        }
        return retVal;
    }
    /**
     * Convert an array of words to an Uint8Array.
     *
     * @param packed Array of integers to be converted.
     * @param outputLength Length of output in bits.
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @returns An Uint8Array containing bytes from `packed.
     */
    function packed2uint8array(packed, outputLength, bigEndianMod) {
        var i;
        var length = outputLength / 8, shiftModifier = bigEndianMod === -1 ? 3 : 0, retVal = new Uint8Array(length);
        for (i = 0; i < length; i += 1) {
            retVal[i] = (packed[i >>> 2] >>> (8 * (shiftModifier + bigEndianMod * (i % 4)))) & 0xff;
        }
        return retVal;
    }
    /* eslint-disable-next-line @typescript-eslint/no-explicit-any */
    function getOutputConverter(format, outputBinLen, bigEndianMod, outputOptions) {
        switch (format) {
            case "HEX":
                return function (binarray) {
                    return packed2hex(binarray, outputBinLen, bigEndianMod, outputOptions);
                };
            case "B64":
                return function (binarray) {
                    return packed2b64(binarray, outputBinLen, bigEndianMod, outputOptions);
                };
            case "BYTES":
                return function (binarray) {
                    return packed2bytes(binarray, outputBinLen, bigEndianMod);
                };
            case "ARRAYBUFFER":
                try {
                    /* Need to test ArrayBuffer support */
                    new ArrayBuffer(0);
                }
                catch (ignore) {
                    throw new Error(arraybuffer_error);
                }
                return function (binarray) {
                    return packed2arraybuffer(binarray, outputBinLen, bigEndianMod);
                };
            case "UINT8ARRAY":
                try {
                    /* Need to test Uint8Array support */
                    new Uint8Array(0);
                }
                catch (ignore) {
                    throw new Error(uint8array_error);
                }
                return function (binarray) {
                    return packed2uint8array(binarray, outputBinLen, bigEndianMod);
                };
            default:
                throw new Error("format must be HEX, B64, BYTES, ARRAYBUFFER, or UINT8ARRAY");
        }
    }

    var TWO_PWR_32 = 4294967296;
    var sha_variant_error = "Chosen SHA variant is not supported";
    var mac_rounds_error = "Cannot set numRounds with MAC";
    /**
     * Validate hash list containing output formatting options, ensuring presence of every option or adding the default
     * value.
     *
     * @param options Hashmap of output formatting options from user.
     * @returns Validated hashmap containing output formatting options.
     */
    function getOutputOpts(options) {
        var retVal = { outputUpper: false, b64Pad: "=", outputLen: -1 }, outputOptions = options || {}, lenErrstr = "Output length must be a multiple of 8";
        retVal["outputUpper"] = outputOptions["outputUpper"] || false;
        if (outputOptions["b64Pad"]) {
            retVal["b64Pad"] = outputOptions["b64Pad"];
        }
        if (outputOptions["outputLen"]) {
            if (outputOptions["outputLen"] % 8 !== 0) {
                throw new Error(lenErrstr);
            }
            retVal["outputLen"] = outputOptions["outputLen"];
        }
        else if (outputOptions["shakeLen"]) {
            if (outputOptions["shakeLen"] % 8 !== 0) {
                throw new Error(lenErrstr);
            }
            retVal["outputLen"] = outputOptions["shakeLen"];
        }
        if ("boolean" !== typeof retVal["outputUpper"]) {
            throw new Error("Invalid outputUpper formatting option");
        }
        if ("string" !== typeof retVal["b64Pad"]) {
            throw new Error("Invalid b64Pad formatting option");
        }
        return retVal;
    }
    /**
     * Parses an external constructor object and returns a packed number, if possible.
     *
     * @param key The human-friendly key name to prefix any errors with
     * @param value The input value object to parse
     * @param bigEndianMod Modifier for whether hash function is big or small endian.
     * @param fallback Fallback value if `value` is undefined.  If not present and `value` is undefined, an Error is thrown
     */
    function parseInputOption(key, value, bigEndianMod, fallback) {
        var errStr = key + " must include a value and format";
        if (!value) {
            if (!fallback) {
                throw new Error(errStr);
            }
            return fallback;
        }
        if (typeof value["value"] === "undefined" || !value["format"]) {
            throw new Error(errStr);
        }
        return getStrConverter(value["format"], 
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore - the value of encoding gets value checked by getStrConverter
        value["encoding"] || "UTF8", bigEndianMod)(value["value"]);
    }
    var jsSHABase = /** @class */ (function () {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        function jsSHABase(variant, inputFormat, options) {
            var inputOptions = options || {};
            this.inputFormat = inputFormat;
            this.utfType = inputOptions["encoding"] || "UTF8";
            this.numRounds = inputOptions["numRounds"] || 1;
            /* eslint-disable-next-line @typescript-eslint/ban-ts-comment */
            // @ts-ignore - The spec actually says ToString is called on the first parseInt argument so it's OK to use it here
            // to check if an arugment is an integer. This cheat would break if it's used to get the value of the argument.
            if (isNaN(this.numRounds) || this.numRounds !== parseInt(this.numRounds, 10) || 1 > this.numRounds) {
                throw new Error("numRounds must a integer >= 1");
            }
            this.shaVariant = variant;
            this.remainder = [];
            this.remainderLen = 0;
            this.updateCalled = false;
            this.processedLen = 0;
            this.macKeySet = false;
            this.keyWithIPad = [];
            this.keyWithOPad = [];
        }
        /**
         * Hashes as many blocks as possible.  Stores the rest for either a future update or getHash call.
         *
         * @param srcString The input to be hashed.
         * @returns A reference to the object.
         */
        jsSHABase.prototype.update = function (srcString) {
            var i, updateProcessedLen = 0;
            var variantBlockIntInc = this.variantBlockSize >>> 5, convertRet = this.converterFunc(srcString, this.remainder, this.remainderLen), chunkBinLen = convertRet["binLen"], chunk = convertRet["value"], chunkIntLen = chunkBinLen >>> 5;
            for (i = 0; i < chunkIntLen; i += variantBlockIntInc) {
                if (updateProcessedLen + this.variantBlockSize <= chunkBinLen) {
                    this.intermediateState = this.roundFunc(chunk.slice(i, i + variantBlockIntInc), this.intermediateState);
                    updateProcessedLen += this.variantBlockSize;
                }
            }
            this.processedLen += updateProcessedLen;
            this.remainder = chunk.slice(updateProcessedLen >>> 5);
            this.remainderLen = chunkBinLen % this.variantBlockSize;
            this.updateCalled = true;
            return this;
        };
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        jsSHABase.prototype.getHash = function (format, options) {
            var i, finalizedState, outputBinLen = this.outputBinLen;
            var outputOptions = getOutputOpts(options);
            if (this.isVariableLen) {
                if (outputOptions["outputLen"] === -1) {
                    throw new Error("Output length must be specified in options");
                }
                outputBinLen = outputOptions["outputLen"];
            }
            var formatFunc = getOutputConverter(format, outputBinLen, this.bigEndianMod, outputOptions);
            if (this.macKeySet && this.getMAC) {
                return formatFunc(this.getMAC(outputOptions));
            }
            finalizedState = this.finalizeFunc(this.remainder.slice(), this.remainderLen, this.processedLen, this.stateCloneFunc(this.intermediateState), outputBinLen);
            for (i = 1; i < this.numRounds; i += 1) {
                /* Need to mask out bits that should be zero due to output not being a multiple of 32 */
                if (this.isVariableLen && outputBinLen % 32 !== 0) {
                    finalizedState[finalizedState.length - 1] &= 0x00ffffff >>> (24 - (outputBinLen % 32));
                }
                finalizedState = this.finalizeFunc(finalizedState, outputBinLen, 0, this.newStateFunc(this.shaVariant), outputBinLen);
            }
            return formatFunc(finalizedState);
        };
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        jsSHABase.prototype.setHMACKey = function (key, inputFormat, options) {
            if (!this.HMACSupported) {
                throw new Error("Variant does not support HMAC");
            }
            if (this.updateCalled) {
                throw new Error("Cannot set MAC key after calling update");
            }
            var keyOptions = options || {}, keyConverterFunc = getStrConverter(inputFormat, keyOptions["encoding"] || "UTF8", this.bigEndianMod);
            this._setHMACKey(keyConverterFunc(key));
        };
        /**
         * Internal function that sets the MAC key.
         *
         * @param key The packed MAC key to use
         */
        jsSHABase.prototype._setHMACKey = function (key) {
            var blockByteSize = this.variantBlockSize >>> 3, lastArrayIndex = blockByteSize / 4 - 1;
            var i;
            if (this.numRounds !== 1) {
                throw new Error(mac_rounds_error);
            }
            if (this.macKeySet) {
                throw new Error("MAC key already set");
            }
            /* Figure out what to do with the key based on its size relative to
             * the hash's block size */
            if (blockByteSize < key["binLen"] / 8) {
                key["value"] = this.finalizeFunc(key["value"], key["binLen"], 0, this.newStateFunc(this.shaVariant), this.outputBinLen);
            }
            while (key["value"].length <= lastArrayIndex) {
                key["value"].push(0);
            }
            /* Create ipad and opad */
            for (i = 0; i <= lastArrayIndex; i += 1) {
                this.keyWithIPad[i] = key["value"][i] ^ 0x36363636;
                this.keyWithOPad[i] = key["value"][i] ^ 0x5c5c5c5c;
            }
            this.intermediateState = this.roundFunc(this.keyWithIPad, this.intermediateState);
            this.processedLen = this.variantBlockSize;
            this.macKeySet = true;
        };
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        jsSHABase.prototype.getHMAC = function (format, options) {
            var outputOptions = getOutputOpts(options), formatFunc = getOutputConverter(format, this.outputBinLen, this.bigEndianMod, outputOptions);
            return formatFunc(this._getHMAC());
        };
        /**
         * Internal function that returns the "raw" HMAC
         */
        jsSHABase.prototype._getHMAC = function () {
            var finalizedState;
            if (!this.macKeySet) {
                throw new Error("Cannot call getHMAC without first setting MAC key");
            }
            var firstHash = this.finalizeFunc(this.remainder.slice(), this.remainderLen, this.processedLen, this.stateCloneFunc(this.intermediateState), this.outputBinLen);
            finalizedState = this.roundFunc(this.keyWithOPad, this.newStateFunc(this.shaVariant));
            finalizedState = this.finalizeFunc(firstHash, this.outputBinLen, this.variantBlockSize, finalizedState, this.outputBinLen);
            return finalizedState;
        };
        return jsSHABase;
    }());

    /*
     * Note 1: All the functions in this file guarantee only that the bottom 32-bits of the return value are correct.
     * JavaScript is flakey when it comes to bit operations and a '1' in the highest order bit of a 32-bit number causes
     * it to be interpreted as a negative number per two's complement.
     *
     * Note 2: Per the ECMAScript spec, all JavaScript operations mask the shift amount by 0x1F.  This results in weird
     * cases like 1 << 32 == 1 and 1 << 33 === 1 << 1 === 2
     */
    /**
     * The 32-bit implementation of circular rotate left.
     *
     * @param x The 32-bit integer argument.
     * @param n The number of bits to shift.
     * @returns `x` shifted left circularly by `n` bits
     */
    function rotl_32(x, n) {
        return (x << n) | (x >>> (32 - n));
    }
    /**
     * The 32-bit implementation of the NIST specified Parity function.
     *
     * @param x The first 32-bit integer argument.
     * @param y The second 32-bit integer argument.
     * @param z The third 32-bit integer argument.
     * @returns The NIST specified output of the function.
     */
    function parity_32(x, y, z) {
        return x ^ y ^ z;
    }
    /**
     * The 32-bit implementation of the NIST specified Ch function.
     *
     * @param x The first 32-bit integer argument.
     * @param y The second 32-bit integer argument.
     * @param z The third 32-bit integer argument.
     * @returns The NIST specified output of the function.
     */
    function ch_32(x, y, z) {
        return (x & y) ^ (~x & z);
    }
    /**
     * The 32-bit implementation of the NIST specified Maj function.
     *
     * @param x The first 32-bit integer argument.
     * @param y The second 32-bit integer argument.
     * @param z The third 32-bit integer argument.
     * @returns The NIST specified output of the function.
     */
    function maj_32(x, y, z) {
        return (x & y) ^ (x & z) ^ (y & z);
    }
    /**
     * Add two 32-bit integers.
     *
     * This uses 16-bit operations internally to work around sign problems due to JavaScript's lack of uint32 support.
     *
     * @param a The first 32-bit integer argument to be added.
     * @param b The second 32-bit integer argument to be added.
     * @returns The sum of `a` + `b`.
     */
    function safeAdd_32_2(a, b) {
        var lsw = (a & 0xffff) + (b & 0xffff), msw = (a >>> 16) + (b >>> 16) + (lsw >>> 16);
        return ((msw & 0xffff) << 16) | (lsw & 0xffff);
    }
    /**
     * Add five 32-bit integers.
     *
     * This uses 16-bit operations internally to work around sign problems due to JavaScript's lack of uint32 support.
     *
     * @param a The first 32-bit integer argument to be added.
     * @param b The second 32-bit integer argument to be added.
     * @param c The third 32-bit integer argument to be added.
     * @param d The fourth 32-bit integer argument to be added.
     * @param e The fifth 32-bit integer argument to be added.
     * @returns The sum of `a` + `b` + `c` + `d` + `e`.
     */
    function safeAdd_32_5(a, b, c, d, e) {
        var lsw = (a & 0xffff) + (b & 0xffff) + (c & 0xffff) + (d & 0xffff) + (e & 0xffff), msw = (a >>> 16) + (b >>> 16) + (c >>> 16) + (d >>> 16) + (e >>> 16) + (lsw >>> 16);
        return ((msw & 0xffff) << 16) | (lsw & 0xffff);
    }

    /**
     * Gets the state values for the specified SHA variant.
     *
     * @param _variant: Unused
     * @returns The initial state values.
     */
    function getNewState(_variant) {
        return [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0];
    }
    /**
     * Performs a round of SHA-1 hashing over a 512-byte block.  This clobbers `H`.
     *
     * @param block The binary array representation of the block to hash.
     * @param H The intermediate H values from a previous round.
     * @returns The resulting H values.
     */
    function roundSHA1(block, H) {
        var a, b, c, d, e, T, t;
        var W = [];
        a = H[0];
        b = H[1];
        c = H[2];
        d = H[3];
        e = H[4];
        for (t = 0; t < 80; t += 1) {
            if (t < 16) {
                W[t] = block[t];
            }
            else {
                W[t] = rotl_32(W[t - 3] ^ W[t - 8] ^ W[t - 14] ^ W[t - 16], 1);
            }
            if (t < 20) {
                T = safeAdd_32_5(rotl_32(a, 5), ch_32(b, c, d), e, 0x5a827999, W[t]);
            }
            else if (t < 40) {
                T = safeAdd_32_5(rotl_32(a, 5), parity_32(b, c, d), e, 0x6ed9eba1, W[t]);
            }
            else if (t < 60) {
                T = safeAdd_32_5(rotl_32(a, 5), maj_32(b, c, d), e, 0x8f1bbcdc, W[t]);
            }
            else {
                T = safeAdd_32_5(rotl_32(a, 5), parity_32(b, c, d), e, 0xca62c1d6, W[t]);
            }
            e = d;
            d = c;
            c = rotl_32(b, 30);
            b = a;
            a = T;
        }
        H[0] = safeAdd_32_2(a, H[0]);
        H[1] = safeAdd_32_2(b, H[1]);
        H[2] = safeAdd_32_2(c, H[2]);
        H[3] = safeAdd_32_2(d, H[3]);
        H[4] = safeAdd_32_2(e, H[4]);
        return H;
    }
    /**
     * Finalizes the SHA-1 hash.  This clobbers `remainder` and `H`.
     *
     * @param remainder Any leftover unprocessed packed ints that still need to be processed.
     * @param remainderBinLen The number of bits in `remainder`.
     * @param processedBinLen The number of bits already processed.
     * @param H The intermediate H values from a previous round.
     * @returns The array of integers representing the SHA-1 hash of message.
     */
    function finalizeSHA1(remainder, remainderBinLen, processedBinLen, H) {
        var i;
        /* The 65 addition is a hack but it works.  The correct number is
              actually 72 (64 + 8) but the below math fails if
              remainderBinLen + 72 % 512 = 0. Since remainderBinLen % 8 = 0,
              "shorting" the addition is OK. */
        var offset = (((remainderBinLen + 65) >>> 9) << 4) + 15, totalLen = remainderBinLen + processedBinLen;
        while (remainder.length <= offset) {
            remainder.push(0);
        }
        /* Append '1' at the end of the binary string */
        remainder[remainderBinLen >>> 5] |= 0x80 << (24 - (remainderBinLen % 32));
        /* Append length of binary string in the position such that the new
         * length is a multiple of 512.  Logic does not work for even multiples
         * of 512 but there can never be even multiples of 512. JavaScript
         * numbers are limited to 2^53 so it's "safe" to treat the totalLen as
         * a 64-bit integer. */
        remainder[offset] = totalLen & 0xffffffff;
        /* Bitwise operators treat the operand as a 32-bit number so need to
         * use hacky division and round to get access to upper 32-ish bits */
        remainder[offset - 1] = (totalLen / TWO_PWR_32) | 0;
        /* This will always be at least 1 full chunk */
        for (i = 0; i < remainder.length; i += 16) {
            H = roundSHA1(remainder.slice(i, i + 16), H);
        }
        return H;
    }
    var jsSHA = /** @class */ (function (_super) {
        __extends(jsSHA, _super);
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        function jsSHA(variant, inputFormat, options) {
            var _this = this;
            if ("SHA-1" !== variant) {
                throw new Error(sha_variant_error);
            }
            _this = _super.call(this, variant, inputFormat, options) || this;
            var resolvedOptions = options || {};
            _this.HMACSupported = true;
            // eslint-disable-next-line @typescript-eslint/unbound-method
            _this.getMAC = _this._getHMAC;
            _this.bigEndianMod = -1;
            _this.converterFunc = getStrConverter(_this.inputFormat, _this.utfType, _this.bigEndianMod);
            _this.roundFunc = roundSHA1;
            _this.stateCloneFunc = function (state) {
                return state.slice();
            };
            _this.newStateFunc = getNewState;
            _this.finalizeFunc = finalizeSHA1;
            _this.intermediateState = getNewState();
            _this.variantBlockSize = 512;
            _this.outputBinLen = 160;
            _this.isVariableLen = false;
            if (resolvedOptions["hmacKey"]) {
                _this._setHMACKey(parseInputOption("hmacKey", resolvedOptions["hmacKey"], _this.bigEndianMod));
            }
            return _this;
        }
        return jsSHA;
    }(jsSHABase));

    return jsSHA;

}));
