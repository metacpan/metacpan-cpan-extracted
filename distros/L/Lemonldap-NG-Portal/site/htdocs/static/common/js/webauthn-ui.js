/*! webauthn-ui library (C) 2018 - 2020 Thomas Bleeker (www.madwizard.org) - MIT license */

(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
    typeof define === 'function' && define.amd ? define(['exports'], factory) :
    (global = typeof globalThis !== 'undefined' ? globalThis : global || self, factory(global.WebAuthnUI = {}));
}(this, (function (exports) { 'use strict';

    /* Microsoft tslib 0BSD licensed */
    /* global Reflect, Promise */

    var extendStatics = function(d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };

    function __extends(d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    }

    function __awaiter(thisArg, _arguments, P, generator) {
        function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
        return new (P || (P = Promise))(function (resolve, reject) {
            function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
            function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
            function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
            step((generator = generator.apply(thisArg, _arguments || [])).next());
        });
    }

    function __generator(thisArg, body) {
        var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
        return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
        function verb(n) { return function (v) { return step([n, v]); }; }
        function step(op) {
            if (f) throw new TypeError("Generator is already executing.");
            while (_) try {
                if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
                if (y = 0, t) op = [op[0] & 2, t.value];
                switch (op[0]) {
                    case 0: case 1: t = op; break;
                    case 4: _.label++; return { value: op[1], done: false };
                    case 5: _.label++; y = op[1]; op = [0]; continue;
                    case 7: op = _.ops.pop(); _.trys.pop(); continue;
                    default:
                        if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                        if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                        if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                        if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                        if (t[2]) _.ops.pop();
                        _.trys.pop(); continue;
                }
                op = body.call(thisArg, _);
            } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
            if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
        }
    }

    function waitReadyState(alreadyDone, eventDispatcher, eventName) {
        if (alreadyDone) {
            return Promise.resolve();
        }
        return new Promise(function (resolve) {
            var readyFunc = function () {
                eventDispatcher.removeEventListener(eventName, readyFunc);
                resolve();
            };
            eventDispatcher.addEventListener(eventName, readyFunc);
        });
    }
    function ready() {
        return waitReadyState(document.readyState !== 'loading', document, 'DOMContentLoaded');
    }
    function loaded() {
        return waitReadyState(document.readyState === 'complete', window, 'load');
    }

    var WebAuthnError = /** @class */ (function (_super) {
        __extends(WebAuthnError, _super);
        function WebAuthnError(name, message, innerError) {
            var _newTarget = this.constructor;
            var _this = _super.call(this, "WebAuthnUI error: " + (message !== undefined ? message : name)) || this;
            Object.setPrototypeOf(_this, _newTarget.prototype); // restore prototype chain
            _this.name = name;
            _this.innerError = innerError;
            return _this;
        }
        WebAuthnError.fromError = function (error) {
            var type = 'unknown';
            var message;
            if (error instanceof DOMException) {
                var map = {
                    NotAllowedError: 'dom-not-allowed',
                    SecurityError: 'dom-security',
                    NotSupportedError: 'dom-not-supported',
                    AbortError: 'dom-abort',
                    InvalidStateError: 'dom-invalid-state',
                };
                type = map[error.name] || 'dom-unknown';
                message = type;
            }
            else {
                message = "unknown (" + error.toString() + ")";
            }
            return new WebAuthnError(type, message, error instanceof Error ? error : undefined);
        };
        return WebAuthnError;
    }(Error));

    function encode(arraybuffer) {
        var buffer = new Uint8Array(arraybuffer);
        var binary = '';
        for (var i_1 = 0; i_1 < buffer.length; i_1++) {
            binary += String.fromCharCode(buffer[i_1]);
        }
        var encoded = window.btoa(binary);
        var i = encoded.length - 1;
        while (i > 0 && encoded[i] === '=') {
            i--;
        }
        encoded = encoded.substr(0, i + 1);
        encoded = encoded.replace(/\+/g, '-').replace(/\//g, '_');
        return encoded;
    }
    function decode(base64) {
        var converted = base64.replace(/-/g, '+').replace(/_/g, '/');
        switch (converted.length % 4) {
            case 2:
                converted += '==';
                break;
            case 3:
                converted += '=';
                break;
            case 1:
                throw new WebAuthnError('parse-error');
        }
        var bin = window.atob(converted);
        var buffer = new Uint8Array(bin.length);
        for (var i = 0; i < bin.length; i++) {
            buffer[i] = bin.charCodeAt(i);
        }
        return buffer;
    }

    function map(src, mapper) {
        var dest = {};
        var keys = Object.keys(mapper);
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i];
            var action = mapper[k];
            var val = src[k];
            if (val !== undefined) {
                if (action === 0 /* Copy */) {
                    dest[k] = val;
                }
                else if (action === 1 /* Base64Decode */) {
                    dest[k] = val === null ? null : decode(val);
                }
                else if (action === 2 /* Base64Encode */) {
                    dest[k] = val === null ? null : encode(val);
                }
                else if (typeof action === 'object') {
                    dest[k] = map(val, action);
                }
                else {
                    dest[k] = action(val);
                }
            }
        }
        return dest;
    }
    function arrayMap(mapper) {
        return function (src) {
            var dest = [];
            for (var i = 0; i < src.length; i++) {
                dest[i] = map(src[i], mapper);
            }
            return dest;
        };
    }
    function getCredentialDescListMap() {
        return arrayMap({
            type: 0 /* Copy */,
            id: 1 /* Base64Decode */,
            transports: 0 /* Copy */,
        });
    }
    function addExtensionOutputs(dest, pkc) {
        var clientExtensionResults = pkc.getClientExtensionResults();
        if (Object.keys(clientExtensionResults).length > 0) {
            dest.clientExtensionResults = map(clientExtensionResults, {
                appid: 0 /* Copy */,
            });
        }
    }
    var Converter = /** @class */ (function () {
        function Converter() {
        }
        Converter.convertCreationOptions = function (options) {
            return map(options, {
                rp: 0 /* Copy */,
                user: {
                    id: 1 /* Base64Decode */,
                    name: 0 /* Copy */,
                    displayName: 0 /* Copy */,
                    icon: 0 /* Copy */,
                },
                challenge: 1 /* Base64Decode */,
                pubKeyCredParams: 0 /* Copy */,
                timeout: 0 /* Copy */,
                excludeCredentials: getCredentialDescListMap(),
                authenticatorSelection: 0 /* Copy */,
                attestation: 0 /* Copy */,
                extensions: {
                    appid: 0 /* Copy */,
                },
            });
        };
        Converter.convertCreationResponse = function (pkc) {
            var response = map(pkc, {
                type: 0 /* Copy */,
                id: 0 /* Copy */,
                rawId: 2 /* Base64Encode */,
                response: {
                    clientDataJSON: 2 /* Base64Encode */,
                    attestationObject: 2 /* Base64Encode */,
                },
            });
            addExtensionOutputs(response, pkc);
            return response;
        };
        Converter.convertRequestOptions = function (options) {
            return map(options, {
                challenge: 1 /* Base64Decode */,
                timeout: 0 /* Copy */,
                rpId: 0 /* Copy */,
                allowCredentials: getCredentialDescListMap(),
                userVerification: 0 /* Copy */,
                extensions: {
                    appid: 0 /* Copy */,
                },
            });
        };
        Converter.convertRequestResponse = function (pkc) {
            var response = map(pkc, {
                type: 0 /* Copy */,
                id: 0 /* Copy */,
                rawId: 2 /* Base64Encode */,
                response: {
                    clientDataJSON: 2 /* Base64Encode */,
                    authenticatorData: 2 /* Base64Encode */,
                    signature: 2 /* Base64Encode */,
                    userHandle: 2 /* Base64Encode */,
                },
            });
            addExtensionOutputs(response, pkc);
            return response;
        };
        return Converter;
    }());

    var loadEvents = { loaded: loaded, ready: ready };
    function elementSelector(selector) {
        var items;
        if (typeof selector === 'string') {
            items = document.querySelectorAll(selector);
        }
        else {
            items = [selector];
        }
        return items;
    }
    var WebAuthnUI = /** @class */ (function () {
        function WebAuthnUI() {
        }
        WebAuthnUI.isSupported = function () {
            return typeof window.PublicKeyCredential !== 'undefined';
        };
        WebAuthnUI.isUVPASupported = function () {
            return __awaiter(this, void 0, void 0, function () {
                return __generator(this, function (_a) {
                    if (this.isSupported()) {
                        return [2 /*return*/, window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()];
                    }
                    return [2 /*return*/, false];
                });
            });
        };
        WebAuthnUI.checkSupport = function () {
            if (!WebAuthnUI.isSupported()) {
                throw new WebAuthnError('unsupported');
            }
        };
        WebAuthnUI.createCredential = function (options) {
            return __awaiter(this, void 0, void 0, function () {
                var request, credential, e_1;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            WebAuthnUI.checkSupport();
                            request = {
                                publicKey: Converter.convertCreationOptions(options),
                            };
                            _a.label = 1;
                        case 1:
                            _a.trys.push([1, 3, , 4]);
                            return [4 /*yield*/, navigator.credentials.create(request)];
                        case 2:
                            credential = (_a.sent());
                            return [3 /*break*/, 4];
                        case 3:
                            e_1 = _a.sent();
                            throw WebAuthnError.fromError(e_1);
                        case 4: return [2 /*return*/, Converter.convertCreationResponse(credential)];
                    }
                });
            });
        };
        WebAuthnUI.getCredential = function (options) {
            return __awaiter(this, void 0, void 0, function () {
                var request, credential, e_2;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            WebAuthnUI.checkSupport();
                            request = {
                                publicKey: Converter.convertRequestOptions(options),
                            };
                            _a.label = 1;
                        case 1:
                            _a.trys.push([1, 3, , 4]);
                            return [4 /*yield*/, navigator.credentials.get(request)];
                        case 2:
                            credential = (_a.sent());
                            return [3 /*break*/, 4];
                        case 3:
                            e_2 = _a.sent();
                            throw WebAuthnError.fromError(e_2);
                        case 4: return [2 /*return*/, Converter.convertRequestResponse(credential)];
                    }
                });
            });
        };
        WebAuthnUI.setFeatureCssClasses = function (selector) {
            return __awaiter(this, void 0, void 0, function () {
                var items, applyClass;
                return __generator(this, function (_a) {
                    items = elementSelector(selector);
                    applyClass = function (cls) {
                        for (var i = 0; i < items.length; i++) {
                            items[i].classList.add(cls);
                        }
                    };
                    applyClass("webauthn-" + (WebAuthnUI.isSupported() ? '' : 'un') + "supported");
                    return [2 /*return*/, WebAuthnUI.isUVPASupported().then(function (available) {
                            applyClass("webauthn-uvpa-" + (available ? '' : 'un') + "supported");
                        })];
                });
            });
        };
        WebAuthnUI.loadConfig = function (config) {
            return __awaiter(this, void 0, void 0, function () {
                var field, el, submit, response, newField;
                var _this = this;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: 
                        // Wait for DOM ready
                        return [4 /*yield*/, ready()];
                        case 1:
                            // Wait for DOM ready
                            _a.sent();
                            field = config.formField;
                            if (typeof field === 'string') {
                                el = document.querySelector(field);
                                if (el === null) {
                                    throw new WebAuthnError('bad-config', 'Could not find formField.');
                                }
                                field = el;
                            }
                            if (!(field instanceof HTMLInputElement || field instanceof HTMLTextAreaElement)) {
                                throw new WebAuthnError('bad-config', 'formField does not refer to an input element.');
                            }
                            submit = config.submitForm !== false;
                            if (!this.isSupported() && config.postUnsupportedImmediately === true) {
                                response = { status: 'failed', error: 'unsupported' };
                                this.setForm(field, response, submit);
                                return [2 /*return*/, response];
                            }
                            newField = field;
                            return [2 /*return*/, new Promise(function (resolve) {
                                    var trigger = config.trigger;
                                    var resolved = false;
                                    if (trigger.event === 'click') {
                                        var targets = elementSelector(config.trigger.element);
                                        var handler = function () { return __awaiter(_this, void 0, void 0, function () {
                                            var response;
                                            return __generator(this, function (_a) {
                                                switch (_a.label) {
                                                    case 0: return [4 /*yield*/, this.runAutoConfig(config)];
                                                    case 1:
                                                        response = _a.sent();
                                                        this.setForm(newField, response, submit);
                                                        if (!resolved) {
                                                            resolved = true;
                                                            resolve(response);
                                                        }
                                                        return [2 /*return*/];
                                                }
                                            });
                                        }); };
                                        for (var i = 0; i < targets.length; i++) {
                                            targets[i].addEventListener('click', handler);
                                        }
                                    }
                                    else {
                                        throw new WebAuthnError('bad-config');
                                    }
                                })];
                    }
                });
            });
        };
        WebAuthnUI.startConfig = function (config) {
            return __awaiter(this, void 0, void 0, function () {
                var credential;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            if (!(config.type === 'get')) return [3 /*break*/, 2];
                            return [4 /*yield*/, this.getCredential(config.request)];
                        case 1:
                            credential = _a.sent();
                            return [3 /*break*/, 5];
                        case 2:
                            if (!(config.type === 'create')) return [3 /*break*/, 4];
                            return [4 /*yield*/, this.createCredential(config.request)];
                        case 3:
                            credential = _a.sent();
                            return [3 /*break*/, 5];
                        case 4: throw new WebAuthnError('bad-config', "Invalid config.type " + config.type);
                        case 5: return [2 /*return*/, {
                                status: 'ok',
                                credential: credential,
                            }];
                    }
                });
            });
        };
        WebAuthnUI.runAutoConfig = function (config) {
            return __awaiter(this, void 0, void 0, function () {
                var response, e_3, waError;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            _a.trys.push([0, 2, , 3]);
                            return [4 /*yield*/, this.startConfig(config)];
                        case 1:
                            response = _a.sent();
                            return [3 /*break*/, 3];
                        case 2:
                            e_3 = _a.sent();
                            waError = (e_3 instanceof WebAuthnError);
                            if (config.debug === true) {
                                console.error(e_3); // eslint-disable-line no-console
                                if (waError && e_3.innerError) {
                                    console.error(e_3.innerError); // eslint-disable-line no-console
                                }
                            }
                            response = {
                                status: 'failed',
                                error: (waError ? e_3.name : WebAuthnError.fromError(e_3).name),
                            };
                            return [3 /*break*/, 3];
                        case 3: return [2 /*return*/, response];
                    }
                });
            });
        };
        WebAuthnUI.setForm = function (field, response, submit) {
            field.value = JSON.stringify(response);
            if (submit && field.form) {
                field.form.submit();
            }
        };
        WebAuthnUI.autoConfig = function () {
            return __awaiter(this, void 0, void 0, function () {
                var promises, list, i, el, isScript, rawJson, json;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            promises = [];
                            list = document.querySelectorAll('input[data-webauthn],textarea[data-webauthn],script[data-webauthn]');
                            for (i = 0; i < list.length; i++) {
                                el = list[i];
                                isScript = el.tagName === 'SCRIPT';
                                if (isScript && el.type !== 'application/json') {
                                    throw new WebAuthnError('bad-config', 'Expecting application/json script with data-webauthn');
                                }
                                rawJson = isScript ? el.textContent : (el).getAttribute('data-webauthn');
                                if (rawJson === null) {
                                    throw new WebAuthnError('bad-config', 'Missing JSON in data-webauthn');
                                }
                                json = void 0;
                                try {
                                    json = JSON.parse(rawJson);
                                }
                                catch (e) {
                                    throw new WebAuthnError('bad-config', 'invalid JSON in data-webauthn on element');
                                }
                                if (!isScript && json.formField === undefined) {
                                    json.formField = el;
                                }
                                promises.push(this.loadConfig(json));
                            }
                            return [4 /*yield*/, Promise.all(promises)];
                        case 1:
                            _a.sent();
                            return [2 /*return*/];
                    }
                });
            });
        };
        WebAuthnUI.inProgress = false;
        return WebAuthnUI;
    }());
    function auto() {
        return __awaiter(this, void 0, void 0, function () {
            var list, i;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, ready()];
                    case 1:
                        _a.sent();
                        list = document.querySelectorAll('.webauthn-detect');
                        for (i = 0; i < list.length; i++) {
                            WebAuthnUI.setFeatureCssClasses(list[i]);
                        }
                        return [2 /*return*/, WebAuthnUI.autoConfig()];
                }
            });
        });
    }
    var autoPromise = auto().catch(function (e) {
        if (console && console.error) { // eslint-disable-line no-console
            console.error(e); // eslint-disable-line no-console
        }
    });

    exports.WebAuthnError = WebAuthnError;
    exports.WebAuthnUI = WebAuthnUI;
    exports.autoPromise = autoPromise;
    exports.loadEvents = loadEvents;

    Object.defineProperty(exports, '__esModule', { value: true });

})));
