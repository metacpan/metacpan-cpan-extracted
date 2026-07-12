use strict;
use warnings;
use Test::More tests => 11;
use Eshu;

# Redux-style reducer
{
    my $in = <<'END';
function todosReducer(state = [], action) {
switch (action.type) {
case 'ADD_TODO':
return [
...state,
{ id: Date.now(), text: action.text, done: false },
];
case 'TOGGLE_TODO':
return state.map((todo) =>
todo.id === action.id
? { ...todo, done: !todo.done }
: todo
);
case 'REMOVE_TODO':
return state.filter((todo) => todo.id !== action.id);
default:
return state;
}
}
END
    my $exp = <<'END';
function todosReducer(state = [], action) {
	switch (action.type) {
		case 'ADD_TODO':
			return [
				...state,
				{ id: Date.now(), text: action.text, done: false },
			];
		case 'TOGGLE_TODO':
			return state.map((todo) =>
				todo.id === action.id
				? { ...todo, done: !todo.done }
				: todo
			);
		case 'REMOVE_TODO':
			return state.filter((todo) => todo.id !== action.id);
		default:
			return state;
	}
}
END
    is(Eshu->indent_js($in), $exp, 'JS: Redux-style reducer with switch/case');
}

# Event emitter class
{
    my $in = <<'END';
class EventEmitter {
#listeners = new Map();

on(event, fn) {
if (!this.#listeners.has(event)) {
this.#listeners.set(event, []);
}
this.#listeners.get(event).push(fn);
return this;
}

off(event, fn) {
const list = this.#listeners.get(event) ?? [];
this.#listeners.set(event, list.filter((f) => f !== fn));
return this;
}

emit(event, ...args) {
const list = this.#listeners.get(event) ?? [];
for (const fn of list) {
try {
fn(...args);
} catch (err) {
console.error(`Listener error on "${event}":`, err);
}
}
return this;
}

once(event, fn) {
const wrapper = (...args) => {
this.off(event, wrapper);
fn(...args);
};
return this.on(event, wrapper);
}
}
END
    my $exp = <<'END';
class EventEmitter {
	#listeners = new Map();

	on(event, fn) {
		if (!this.#listeners.has(event)) {
			this.#listeners.set(event, []);
		}
		this.#listeners.get(event).push(fn);
		return this;
	}

	off(event, fn) {
		const list = this.#listeners.get(event) ?? [];
		this.#listeners.set(event, list.filter((f) => f !== fn));
		return this;
	}

	emit(event, ...args) {
		const list = this.#listeners.get(event) ?? [];
		for (const fn of list) {
			try {
				fn(...args);
			} catch (err) {
				console.error(`Listener error on "${event}":`, err);
			}
		}
		return this;
	}

	once(event, fn) {
		const wrapper = (...args) => {
			this.off(event, wrapper);
			fn(...args);
		};
		return this.on(event, wrapper);
	}
}
END
    is(Eshu->indent_js($in), $exp, 'JS: EventEmitter class with private Map and try/catch');
}

# Middleware chain (Express-style)
{
    my $in = <<'END';
function compose(...middlewares) {
return function composed(ctx, next) {
let index = -1;
function dispatch(i) {
if (i <= index) return Promise.reject(new Error('next() called multiple times'));
index = i;
const fn = i === middlewares.length ? next : middlewares[i];
if (!fn) return Promise.resolve();
try {
return Promise.resolve(fn(ctx, () => dispatch(i + 1)));
} catch (err) {
return Promise.reject(err);
}
}
return dispatch(0);
};
}
END
    my $exp = <<'END';
function compose(...middlewares) {
	return function composed(ctx, next) {
		let index = -1;
		function dispatch(i) {
			if (i <= index) return Promise.reject(new Error('next() called multiple times'));
			index = i;
			const fn = i === middlewares.length ? next : middlewares[i];
			if (!fn) return Promise.resolve();
			try {
				return Promise.resolve(fn(ctx, () => dispatch(i + 1)));
			} catch (err) {
				return Promise.reject(err);
			}
		}
		return dispatch(0);
	};
}
END
    is(Eshu->indent_js($in), $exp, 'JS: middleware compose with nested closures');
}

# Observable/reactive pattern
{
    my $in = <<'END';
function createStore(reducer, initialState) {
let state = initialState;
const subscribers = new Set();

return {
getState() {
return state;
},
dispatch(action) {
state = reducer(state, action);
for (const sub of subscribers) {
sub(state);
}
},
subscribe(fn) {
subscribers.add(fn);
return () => subscribers.delete(fn);
},
};
}
END
    my $exp = <<'END';
function createStore(reducer, initialState) {
	let state = initialState;
	const subscribers = new Set();

	return {
		getState() {
			return state;
		},
		dispatch(action) {
			state = reducer(state, action);
			for (const sub of subscribers) {
				sub(state);
			}
		},
		subscribe(fn) {
			subscribers.add(fn);
			return () => subscribers.delete(fn);
		},
	};
}
END
    is(Eshu->indent_js($in), $exp, 'JS: store factory with object shorthand methods');
}

# Async iterator / pagination
{
    my $in = <<'END';
async function* paginate(url, options = {}) {
const { pageSize = 20, maxPages = Infinity } = options;
let page = 1;
let hasMore = true;

while (hasMore && page <= maxPages) {
const resp = await fetch(`${url}?page=${page}&size=${pageSize}`);
if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
const data = await resp.json();
yield data.items;
hasMore = data.hasNextPage;
page++;
}
}

async function fetchAll(url) {
const all = [];
for await (const page of paginate(url, { pageSize: 50 })) {
all.push(...page);
}
return all;
}
END
    my $exp = <<'END';
async function* paginate(url, options = {}) {
	const { pageSize = 20, maxPages = Infinity } = options;
	let page = 1;
	let hasMore = true;

	while (hasMore && page <= maxPages) {
		const resp = await fetch(`${url}?page=${page}&size=${pageSize}`);
		if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
		const data = await resp.json();
		yield data.items;
		hasMore = data.hasNextPage;
		page++;
	}
}

async function fetchAll(url) {
	const all = [];
	for await (const page of paginate(url, { pageSize: 50 })) {
		all.push(...page);
	}
	return all;
}
END
    is(Eshu->indent_js($in), $exp, 'JS: async generator with for-await pagination');
}

# WeakRef / FinalizationRegistry pattern
{
    my $in = <<'END';
class Cache {
#store = new Map();
#registry = new FinalizationRegistry((key) => {
this.#store.delete(key);
});

set(key, value) {
const ref = new WeakRef(value);
this.#store.set(key, ref);
this.#registry.register(value, key);
}

get(key) {
const ref = this.#store.get(key);
if (!ref) return undefined;
const val = ref.deref();
if (val === undefined) {
this.#store.delete(key);
}
return val;
}

has(key) {
return this.get(key) !== undefined;
}
}
END
    my $exp = <<'END';
class Cache {
	#store = new Map();
	#registry = new FinalizationRegistry((key) => {
		this.#store.delete(key);
	});

	set(key, value) {
		const ref = new WeakRef(value);
		this.#store.set(key, ref);
		this.#registry.register(value, key);
	}

	get(key) {
		const ref = this.#store.get(key);
		if (!ref) return undefined;
		const val = ref.deref();
		if (val === undefined) {
			this.#store.delete(key);
		}
		return val;
	}

	has(key) {
		return this.get(key) !== undefined;
	}
}
END
    is(Eshu->indent_js($in), $exp, 'JS: WeakRef cache with FinalizationRegistry callback');
}

# CommonJS module pattern
{
    my $in = <<'END';
'use strict';

const path = require('path');
const fs   = require('fs');

const DEFAULT_OPTS = {
encoding: 'utf8',
recursive: false,
filter: null,
};

function readDir(dir, opts) {
opts = Object.assign({}, DEFAULT_OPTS, opts);
const results = [];

function walk(current) {
const entries = fs.readdirSync(current, { withFileTypes: true });
for (const entry of entries) {
const full = path.join(current, entry.name);
if (entry.isDirectory()) {
if (opts.recursive) walk(full);
} else {
if (!opts.filter || opts.filter(entry.name)) {
results.push(full);
}
}
}
}

walk(dir);
return results;
}

module.exports = { readDir };
END
    my $exp = <<'END';
'use strict';

const path = require('path');
const fs   = require('fs');

const DEFAULT_OPTS = {
	encoding: 'utf8',
	recursive: false,
	filter: null,
};

function readDir(dir, opts) {
	opts = Object.assign({}, DEFAULT_OPTS, opts);
	const results = [];

	function walk(current) {
		const entries = fs.readdirSync(current, { withFileTypes: true });
		for (const entry of entries) {
			const full = path.join(current, entry.name);
			if (entry.isDirectory()) {
				if (opts.recursive) walk(full);
			} else {
				if (!opts.filter || opts.filter(entry.name)) {
					results.push(full);
				}
			}
		}
	}

	walk(dir);
	return results;
}

module.exports = { readDir };
END
    is(Eshu->indent_js($in), $exp, 'JS: CommonJS module with recursive directory walk');
}

# TypeScript-style interface comment block + type guards
{
    my $in = <<'END';
// Type guard helpers for runtime validation

function isString(val) {
return typeof val === 'string';
}

function isRecord(val) {
return val !== null && typeof val === 'object' && !Array.isArray(val);
}

function validateConfig(raw) {
if (!isRecord(raw)) throw new TypeError('config must be an object');
const { host, port, tls = false } = raw;
if (!isString(host) || host.length === 0) {
throw new TypeError('config.host must be a non-empty string');
}
if (typeof port !== 'number' || port < 1 || port > 65535) {
throw new RangeError(`config.port must be 1-65535, got ${port}`);
}
return { host, port: Math.floor(port), tls: Boolean(tls) };
}
END
    my $exp = <<'END';
// Type guard helpers for runtime validation

function isString(val) {
	return typeof val === 'string';
}

function isRecord(val) {
	return val !== null && typeof val === 'object' && !Array.isArray(val);
}

function validateConfig(raw) {
	if (!isRecord(raw)) throw new TypeError('config must be an object');
	const { host, port, tls = false } = raw;
	if (!isString(host) || host.length === 0) {
		throw new TypeError('config.host must be a non-empty string');
	}
	if (typeof port !== 'number' || port < 1 || port > 65535) {
		throw new RangeError(`config.port must be 1-65535, got ${port}`);
	}
	return { host, port: Math.floor(port), tls: Boolean(tls) };
}
END
    is(Eshu->indent_js($in), $exp, 'JS: type guard functions with destructuring and template literals');
}

# Worker thread message handler pattern
{
    my $in = <<'END';
const { parentPort, workerData } = require('worker_threads');

const handlers = {
ping(data) {
return { type: 'pong', ts: Date.now() };
},
process(data) {
const { items } = data;
const results = items.map((item) => {
try {
return { ok: true,  value: transform(item) };
} catch (err) {
return { ok: false, error: err.message };
}
});
return { type: 'result', results };
},
};

parentPort.on('message', (msg) => {
const handler = handlers[msg.type];
if (!handler) {
parentPort.postMessage({ type: 'error', message: `Unknown: ${msg.type}` });
return;
}
try {
const reply = handler(msg.data);
parentPort.postMessage(reply);
} catch (err) {
parentPort.postMessage({ type: 'error', message: err.message });
}
});
END
    my $exp = <<'END';
const { parentPort, workerData } = require('worker_threads');

const handlers = {
	ping(data) {
		return { type: 'pong', ts: Date.now() };
	},
	process(data) {
		const { items } = data;
		const results = items.map((item) => {
			try {
				return { ok: true,  value: transform(item) };
			} catch (err) {
				return { ok: false, error: err.message };
			}
		});
		return { type: 'result', results };
	},
};

parentPort.on('message', (msg) => {
	const handler = handlers[msg.type];
	if (!handler) {
		parentPort.postMessage({ type: 'error', message: `Unknown: ${msg.type}` });
		return;
	}
	try {
		const reply = handler(msg.data);
		parentPort.postMessage(reply);
	} catch (err) {
		parentPort.postMessage({ type: 'error', message: err.message });
	}
});
END
    is(Eshu->indent_js($in), $exp, 'JS: worker_threads message dispatch with try/catch');
}

# Proxy / Reflect traps
{
    my $in = <<'END';
function createReadOnlyProxy(target) {
return new Proxy(target, {
set(obj, prop, value) {
throw new TypeError(`Cannot set property "${String(prop)}" on read-only object`);
},
deleteProperty(obj, prop) {
throw new TypeError(`Cannot delete property "${String(prop)}" on read-only object`);
},
defineProperty(obj, prop, descriptor) {
throw new TypeError(`Cannot define property "${String(prop)}" on read-only object`);
},
get(obj, prop, receiver) {
const val = Reflect.get(obj, prop, receiver);
if (val !== null && typeof val === 'object') {
return createReadOnlyProxy(val);
}
return val;
},
});
}
END
    my $exp = <<'END';
function createReadOnlyProxy(target) {
	return new Proxy(target, {
		set(obj, prop, value) {
			throw new TypeError(`Cannot set property "${String(prop)}" on read-only object`);
		},
		deleteProperty(obj, prop) {
			throw new TypeError(`Cannot delete property "${String(prop)}" on read-only object`);
		},
		defineProperty(obj, prop, descriptor) {
			throw new TypeError(`Cannot define property "${String(prop)}" on read-only object`);
		},
		get(obj, prop, receiver) {
			const val = Reflect.get(obj, prop, receiver);
			if (val !== null && typeof val === 'object') {
				return createReadOnlyProxy(val);
			}
			return val;
		},
	});
}
END
    is(Eshu->indent_js($in), $exp, 'JS: Proxy with Reflect traps and recursive wrapping');
}

# Idempotency across JS patterns
{
    my @srcs = (
        "const f = async () => {\nconst x = await fetch('/api');\nreturn x.json();\n};\n",
        "class A {\nconstructor() {\nthis.x = 1;\n}\nmethod() {\nif (this.x) {\nreturn true;\n}\n}\n}\n",
        "const obj = {\na: 1,\nb: {\nc: 2,\nd: [3, 4],\n},\n};\n",
    );
    my $ok = 1;
    for my $src (@srcs) {
        my $once  = Eshu->indent_js($src);
        my $twice = Eshu->indent_js($once);
        $ok = 0 unless $once eq $twice;
    }
    ok($ok, 'JS: realworld snippets are idempotent');
}
