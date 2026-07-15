use strict;
use warnings;
use Test::More;
use Eshu;

sub js { Eshu->indent_js($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple function
{
	my $code = <<'END';
function add(a, b) {
	return a + b;
}
END
	is(js($code), $code, 'JS: simple function');
}

# 2. arrow function
{
	my $code = <<'END';
const multiply = (a, b) => a * b;

const square = (x) => {
	return x * x;
};
END
	is(js($code), $code, 'JS: arrow functions');
}

# 3. ES6 class
{
	my $code = <<'END';
class Animal {
	constructor(name, sound) {
		this.name  = name;
		this.sound = sound;
	}

	speak() {
		console.log(`${this.name} says ${this.sound}`);
	}

	toString() {
		return `Animal(${this.name})`;
	}
}
END
	is(js($code), $code, 'JS: ES6 class');
}

# 4. class inheritance
{
	my $code = <<'END';
class Dog extends Animal {
	constructor(name) {
		super(name, 'woof');
		this.tricks = [];
	}

	learn(trick) {
		this.tricks.push(trick);
	}

	perform() {
		if (this.tricks.length === 0) {
			console.log(`${this.name} knows no tricks.`);
			return;
		}
		console.log(`${this.name} can: ${this.tricks.join(', ')}`);
	}
}
END
	is(js($code), $code, 'JS: class inheritance');
}

# 5. async/await
{
	my $code = <<'END';
async function fetchUser(id) {
	try {
		const response = await fetch(`/api/users/${id}`);
		if (!response.ok) {
			throw new Error(`HTTP ${response.status}`);
		}
		const data = await response.json();
		return data;
	} catch (error) {
		console.error('fetchUser failed:', error);
		throw error;
	}
}
END
	is(js($code), $code, 'JS: async/await with error handling');
}

# 6. Promise chain
{
	my $code = <<'END';
function loadConfig(path) {
	return fetch(path)
	.then((res) => {
		if (!res.ok) {
			throw new Error(`Failed to load config: ${res.status}`);
		}
		return res.json();
	})
	.then((data) => {
		validate(data);
		return data;
	})
	.catch((err) => {
		console.error('Config error:', err);
		return null;
	});
}
END
	is(js($code), $code, 'JS: Promise chain');
}

# 7. destructuring
{
	my $code = <<'END';
function processUser({ id, name, email, role = 'user' }) {
	const { firstName, lastName } = parseName(name);
	return {
		id,
		firstName,
		lastName,
		email: email.toLowerCase(),
		role,
	};
}
END
	is(js($code), $code, 'JS: object destructuring');
}

# 8. array methods chain
{
	my $code = <<'END';
function getActiveUserEmails(users) {
	return users
	.filter((u) => u.active)
	.map((u) => u.email.toLowerCase())
	.sort()
	.filter((email, index, arr) => arr.indexOf(email) === index);
}
END
	is(js($code), $code, 'JS: array method chain');
}

# 9. generator function
{
	my $code = <<'END';
function* range(start, end, step = 1) {
	for (let i = start; i < end; i += step) {
		yield i;
	}
}

function* zip(...iterables) {
	const iters = iterables.map((it) => it[Symbol.iterator]());
	while (true) {
		const results = iters.map((it) => it.next());
		if (results.some((r) => r.done)) {
			return;
		}
		yield results.map((r) => r.value);
	}
}
END
	is(js($code), $code, 'JS: generator functions');
}

# 10. EventEmitter
{
	my $code = <<'END';
class EventEmitter {
	constructor() {
		this._listeners = new Map();
	}

	on(event, fn) {
		if (!this._listeners.has(event)) {
			this._listeners.set(event, new Set());
		}
		this._listeners.get(event).add(fn);
		return () => this.off(event, fn);
	}

	off(event, fn) {
		this._listeners.get(event)?.delete(fn);
	}

	emit(event, ...args) {
		this._listeners.get(event)?.forEach((fn) => fn(...args));
	}
}
END
	is(js($code), $code, 'JS: EventEmitter class');
}

# 11. Proxy / Reflect
{
	my $code = <<'END';
function makeReadonly(obj) {
	return new Proxy(obj, {
		set(target, prop, value) {
			throw new TypeError(`Cannot set property '${prop}': object is readonly`);
		},
		deleteProperty(target, prop) {
			throw new TypeError(`Cannot delete property '${prop}': object is readonly`);
		},
		get(target, prop, receiver) {
			const val = Reflect.get(target, prop, receiver);
			if (typeof val === 'object' && val !== null) {
				return makeReadonly(val);
			}
			return val;
		},
	});
}
END
	is(js($code), $code, 'JS: Proxy readonly wrapper');
}

# 12. WeakMap cache
{
	my $code = <<'END';
const cache = new WeakMap();

function memoize(fn) {
	return function (...args) {
		if (!cache.has(this)) {
			cache.set(this, new Map());
		}
		const map = cache.get(this);
		const key = JSON.stringify(args);
		if (!map.has(key)) {
			map.set(key, fn.apply(this, args));
		}
		return map.get(key);
	};
}
END
	is(js($code), $code, 'JS: WeakMap memoize');
}

# 13. reduce
{
	my $code = <<'END';
function groupBy(array, keyFn) {
	return array.reduce((acc, item) => {
		const key = keyFn(item);
		if (!acc[key]) {
			acc[key] = [];
		}
		acc[key].push(item);
		return acc;
	}, {});
}
END
	is(js($code), $code, 'JS: groupBy with reduce');
}

# 14. async generator
{
	my $code = <<'END';
async function* paginate(fetchPage, params = {}) {
	let page = 1;
	while (true) {
		const data = await fetchPage({ ...params, page });
		yield data.items;
		if (!data.hasNextPage) {
			break;
		}
		page++;
	}
}
END
	is(js($code), $code, 'JS: async generator for pagination');
}

# 15. module pattern (CommonJS)
{
	my $code = <<'END';
'use strict';

const path = require('path');
const fs   = require('fs');

function readJSON(filePath) {
	const abs  = path.resolve(filePath);
	const text = fs.readFileSync(abs, 'utf8');
	return JSON.parse(text);
}

function writeJSON(filePath, data, indent = 2) {
	const abs  = path.resolve(filePath);
	const text = JSON.stringify(data, null, indent) + '\n';
	fs.writeFileSync(abs, text, 'utf8');
}

module.exports = { readJSON, writeJSON };
END
	is(js($code), $code, 'JS: CommonJS module');
}

# 16. ES module
{
	my $code = <<'END';
export const VERSION = '1.0.0';

export function clamp(value, min, max) {
	return Math.max(min, Math.min(max, value));
}

export function lerp(a, b, t) {
	return a + (b - a) * t;
}

export default class Vector2 {
	constructor(x = 0, y = 0) {
		this.x = x;
		this.y = y;
	}

	add(other) {
		return new Vector2(this.x + other.x, this.y + other.y);
	}

	scale(factor) {
		return new Vector2(this.x * factor, this.y * factor);
	}
}
END
	is(js($code), $code, 'JS: ES module exports');
}

# 17. Symbol iterator
{
	my $code = <<'END';
class Range {
	constructor(start, end) {
		this.start = start;
		this.end   = end;
	}

	[Symbol.iterator]() {
		let current = this.start;
		const end   = this.end;
		return {
			next() {
				if (current <= end) {
					return { value: current++, done: false };
				}
				return { value: undefined, done: true };
			},
		};
	}
}
END
	is(js($code), $code, 'JS: Symbol.iterator');
}

# 18. worker dispatch
{
	my $code = <<'END';
const handlers = {
	add:    ({ a, b }) => a + b,
	sub:    ({ a, b }) => a - b,
	mul:    ({ a, b }) => a * b,
	div:    ({ a, b }) => b !== 0 ? a / b : null,
};

self.addEventListener('message', ({ data: { type, payload } }) => {
	const handler = handlers[type];
	if (!handler) {
		self.postMessage({ error: `Unknown message type: ${type}` });
		return;
	}
	try {
		const result = handler(payload);
		self.postMessage({ result });
	} catch (error) {
		self.postMessage({ error: error.message });
	}
});
END
	is(js($code), $code, 'JS: worker message dispatch');
}

# 19. Observable (simplified RxJS-like)
{
	my $code = <<'END';
class Observable {
	constructor(subscribe) {
		this._subscribe = subscribe;
	}

	subscribe(observer) {
		return this._subscribe(observer);
	}

	map(fn) {
		return new Observable((observer) => {
			return this.subscribe({
				next: (v) => observer.next(fn(v)),
				error: (e) => observer.error(e),
				complete: () => observer.complete(),
			});
		});
	}

	filter(pred) {
		return new Observable((observer) => {
			return this.subscribe({
				next: (v) => pred(v) && observer.next(v),
				error: (e) => observer.error(e),
				complete: () => observer.complete(),
			});
		});
	}
}
END
	is(js($code), $code, 'JS: Observable with map/filter');
}

# 20. tagged template literal
{
	my $code = <<'END';
function sql(strings, ...values) {
	let query  = '';
	const params = [];
	strings.forEach((str, i) => {
		query += str;
		if (i < values.length) {
			params.push(values[i]);
			query += `$${params.length}`;
		}
	});
	return { query, params };
}
END
	is(js($code), $code, 'JS: tagged template literal for SQL');
}

# 21. private class fields
{
	my $code = <<'END';
class Counter {
	#count = 0;
	#step;

	constructor(step = 1) {
		this.#step = step;
	}

	increment() {
		this.#count += this.#step;
	}

	decrement() {
		this.#count -= this.#step;
	}

	get value() {
		return this.#count;
	}

	reset() {
		this.#count = 0;
	}
}
END
	is(js($code), $code, 'JS: private class fields');
}

# 22. optional chaining and nullish coalescing
{
	my $code = <<'END';
function getUserDisplayName(user) {
	return user?.profile?.displayName
	?? user?.name
	?? user?.email?.split('@')[0]
	?? 'Anonymous';
}

function getNestedValue(obj, ...keys) {
	return keys.reduce((acc, key) => acc?.[key], obj) ?? null;
}
END
	is(js($code), $code, 'JS: optional chaining and nullish coalescing');
}

# 23. debounce/throttle
{
	my $code = <<'END';
function debounce(fn, delay) {
	let timer;
	return function (...args) {
		clearTimeout(timer);
		timer = setTimeout(() => fn.apply(this, args), delay);
	};
}

function throttle(fn, interval) {
	let last = 0;
	return function (...args) {
		const now = Date.now();
		if (now - last >= interval) {
			last = now;
			return fn.apply(this, args);
		}
	};
}
END
	is(js($code), $code, 'JS: debounce and throttle');
}

# 24. Linked list
{
	my $code = <<'END';
class LinkedList {
	#head = null;
	#size = 0;

	push(value) {
		this.#head = { value, next: this.#head };
		this.#size++;
	}

	pop() {
		if (!this.#head) {
			return undefined;
		}
		const { value } = this.#head;
		this.#head = this.#head.next;
		this.#size--;
		return value;
	}

	get size() {
		return this.#size;
	}

	[Symbol.iterator]() {
		let node = this.#head;
		return {
			next() {
				if (!node) {
					return { done: true };
				}
				const value = node.value;
				node = node.next;
				return { value, done: false };
			},
		};
	}
}
END
	is(js($code), $code, 'JS: linked list with iterator');
}

# 25. LRU cache
{
	my $code = <<'END';
class LRUCache {
	#capacity;
	#cache = new Map();

	constructor(capacity) {
		this.#capacity = capacity;
	}

	get(key) {
		if (!this.#cache.has(key)) {
			return -1;
		}
		const value = this.#cache.get(key);
		this.#cache.delete(key);
		this.#cache.set(key, value);
		return value;
	}

	put(key, value) {
		this.#cache.delete(key);
		if (this.#cache.size >= this.#capacity) {
			this.#cache.delete(this.#cache.keys().next().value);
		}
		this.#cache.set(key, value);
	}
}
END
	is(js($code), $code, 'JS: LRU cache with Map');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
function factorial(n) {
if (n <= 1) {
return 1;
}
return n * factorial(n - 1);
}
END
	my $exp = <<'END';
function factorial(n) {
	if (n <= 1) {
		return 1;
	}
	return n * factorial(n - 1);
}
END
	is(js($in), $exp, 'JS: unindented factorial normalised');
}

# 27
{
	my $in = <<'END';
function binarySearch(arr, target) {
let lo = 0, hi = arr.length - 1;
while (lo <= hi) {
const mid = (lo + hi) >> 1;
if (arr[mid] === target) {
return mid;
} else if (arr[mid] < target) {
lo = mid + 1;
} else {
hi = mid - 1;
}
}
return -1;
}
END
	my $exp = <<'END';
function binarySearch(arr, target) {
	let lo = 0, hi = arr.length - 1;
	while (lo <= hi) {
		const mid = (lo + hi) >> 1;
		if (arr[mid] === target) {
			return mid;
		} else if (arr[mid] < target) {
			lo = mid + 1;
		} else {
			hi = mid - 1;
		}
	}
	return -1;
}
END
	is(js($in), $exp, 'JS: unindented binary search normalised');
}

# 28
{
	my $in = <<'END';
class Stack {
constructor() {
this._items = [];
}
push(item) {
this._items.push(item);
}
pop() {
if (this.isEmpty()) {
throw new Error('Stack underflow');
}
return this._items.pop();
}
peek() {
return this._items[this._items.length - 1];
}
isEmpty() {
return this._items.length === 0;
}
}
END
	my $exp = <<'END';
class Stack {
	constructor() {
		this._items = [];
	}
	push(item) {
		this._items.push(item);
	}
	pop() {
		if (this.isEmpty()) {
			throw new Error('Stack underflow');
		}
		return this._items.pop();
	}
	peek() {
		return this._items[this._items.length - 1];
	}
	isEmpty() {
		return this._items.length === 0;
	}
}
END
	is(js($in), $exp, 'JS: unindented Stack class normalised');
}

# 29
{
	my $in = <<'END';
function mergeSort(arr) {
if (arr.length <= 1) {
return arr;
}
const mid = Math.floor(arr.length / 2);
const left = mergeSort(arr.slice(0, mid));
const right = mergeSort(arr.slice(mid));
return merge(left, right);
}
function merge(a, b) {
const out = [];
let i = 0, j = 0;
while (i < a.length && j < b.length) {
if (a[i] <= b[j]) {
out.push(a[i++]);
} else {
out.push(b[j++]);
}
}
return out.concat(a.slice(i)).concat(b.slice(j));
}
END
	my $exp = <<'END';
function mergeSort(arr) {
	if (arr.length <= 1) {
		return arr;
	}
	const mid = Math.floor(arr.length / 2);
	const left = mergeSort(arr.slice(0, mid));
	const right = mergeSort(arr.slice(mid));
	return merge(left, right);
}
function merge(a, b) {
	const out = [];
	let i = 0, j = 0;
	while (i < a.length && j < b.length) {
		if (a[i] <= b[j]) {
			out.push(a[i++]);
		} else {
			out.push(b[j++]);
		}
	}
	return out.concat(a.slice(i)).concat(b.slice(j));
}
END
	is(js($in), $exp, 'JS: unindented merge sort normalised');
}

# 30
{
	my $in = <<'END';
async function retry(fn, { attempts = 3, delay = 1000, backoff = 2 } = {}) {
let lastError;
for (let i = 0; i < attempts; i++) {
try {
return await fn();
} catch (err) {
lastError = err;
if (i < attempts - 1) {
await new Promise((r) => setTimeout(r, delay * Math.pow(backoff, i)));
}
}
}
throw lastError;
}
END
	my $exp = <<'END';
async function retry(fn, { attempts = 3, delay = 1000, backoff = 2 } = {}) {
	let lastError;
	for (let i = 0; i < attempts; i++) {
		try {
			return await fn();
		} catch (err) {
			lastError = err;
			if (i < attempts - 1) {
				await new Promise((r) => setTimeout(r, delay * Math.pow(backoff, i)));
			}
		}
	}
	throw lastError;
}
END
	is(js($in), $exp, 'JS: unindented retry normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	"const pipe=(...fns)=>x=>fns.reduce((v,f)=>f(v),x);\nconst compose=(...fns)=>x=>fns.reduceRight((v,f)=>f(v),x);\n",
	"function deepEqual(a,b){\nif(a===b)return true;\nif(typeof a!=='object'||typeof b!=='object'||!a||!b)return false;\nconst ka=Object.keys(a),kb=Object.keys(b);\nif(ka.length!==kb.length)return false;\nreturn ka.every(k=>deepEqual(a[k],b[k]));\n}\n",
	"class PubSub{\nconstructor(){this.topics=new Map()}\nsubscribe(topic,fn){if(!this.topics.has(topic))this.topics.set(topic,[]);this.topics.get(topic).push(fn);return()=>this.unsubscribe(topic,fn)}\nunsubscribe(topic,fn){const fns=this.topics.get(topic)||[];this.topics.set(topic,fns.filter(f=>f!==fn))}\npublish(topic,...args){(this.topics.get(topic)||[]).forEach(fn=>fn(...args))}\n}\n",
	"function chunk(arr,size){\nconst out=[];\nfor(let i=0;i<arr.length;i+=size){\nout.push(arr.slice(i,i+size));\n}\nreturn out;\n}\n",
	"function flatten(arr,depth=1){\nreturn depth>0\n?arr.reduce((acc,v)=>acc.concat(Array.isArray(v)?flatten(v,depth-1):v),[])\n:[...arr];\n}\n",
	"function once(fn){\nlet called=false,result;\nreturn function(...args){\nif(!called){called=true;result=fn.apply(this,args);}\nreturn result;\n};\n}\n",
	"function curry(fn){\nreturn function curried(...args){\nif(args.length>=fn.length){\nreturn fn.apply(this,args);\n}\nreturn function(...moreArgs){\nreturn curried.apply(this,args.concat(moreArgs));\n};\n};\n}\n",
	"function* fibonacci(){\nlet[a,b]=[0,1];\nwhile(true){\nyield a;\n[a,b]=[b,a+b];\n}\n}\n",
	"const createStore=(reducer,initial)=>{\nlet state=initial;\nconst listeners=[];\nreturn{\ngetState:()=>state,\ndispatch(action){\nstate=reducer(state,action);\nlisteners.forEach(l=>l(state));\n},\nsubscribe(fn){\nlisteners.push(fn);\nreturn()=>listeners.splice(listeners.indexOf(fn),1);\n},\n};\n};\n",
	"function dfs(graph,start,visited=new Set()){\nvisited.add(start);\nfor(const neighbor of graph[start]||[]){\nif(!visited.has(neighbor)){\ndfs(graph,neighbor,visited);\n}\n}\nreturn visited;\n}\n",
	"function topsort(graph){\nconst visited=new Set(),order=[];\nfunction visit(node){\nif(visited.has(node))return;\nvisited.add(node);\nfor(const dep of graph[node]||[])visit(dep);\norder.push(node);\n}\nObject.keys(graph).forEach(visit);\nreturn order.reverse();\n}\n",
	"class Deque{\nconstructor(){this._data=[];this._offset=0}\npushFront(v){this._data.unshift(v)}\npushBack(v){this._data.push(v)}\npopFront(){return this._data.shift()}\npopBack(){return this._data.pop()}\nget size(){return this._data.length}\n}\n",
	"async function withTimeout(promise,ms){\nconst timeout=new Promise((_,reject)=>setTimeout(()=>reject(new Error('timeout')),ms));\nreturn Promise.race([promise,timeout]);\n}\n",
	"function interpolate(template,vars){\nreturn template.replace(/\\{\\{(\\w+)\\}\\}/g,(_,k)=>vars[k]??`{{\${k}}}`);\n}\n",
	"const trampoline=fn=>function(...args){\nlet result=fn(...args);\nwhile(typeof result==='function')result=result();\nreturn result;\n};\n",
) {
	my $once = js($snippet);
	is(js($once), $once, 'JS: snippet idempotent');
}

done_testing;
