use strict;
use warnings;
use Test::More;
use Eshu;

sub ts { Eshu->indent_ts($_[0], indent_char => ' ', indent_width => 4) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. basic interface
{
    my $code = <<'END';
interface User {
    id: number;
    name: string;
    email: string;
    role?: 'admin' | 'user' | 'guest';
}
END
    is(ts($code), $code, 'TS: basic interface');
}

# 2. generic function
{
    my $code = <<'END';
function identity<T>(value: T): T {
    return value;
}

function first<T>(arr: T[]): T | undefined {
    return arr[0];
}
END
    is(ts($code), $code, 'TS: generic functions');
}

# 3. class with interface
{
    my $code = <<'END';
class UserService implements Repository<User> {
    private users: Map<number, User> = new Map();

    findById(id: number): User | undefined {
        return this.users.get(id);
    }

    save(user: User): void {
        this.users.set(user.id, user);
    }

    delete(id: number): boolean {
        return this.users.delete(id);
    }
}
END
    is(ts($code), $code, 'TS: class implementing interface');
}

# 4. enum
{
    my $code = <<'END';
enum Direction {
    Up    = 'UP',
    Down  = 'DOWN',
    Left  = 'LEFT',
    Right = 'RIGHT',
}

function move(dir: Direction): string {
    switch (dir) {
        case Direction.Up:    return 'moved up';
        case Direction.Down:  return 'moved down';
        case Direction.Left:  return 'moved left';
        case Direction.Right: return 'moved right';
    }
}
END
    is(ts($code), $code, 'TS: enum and switch');
}

# 5. mapped type
{
    my $code = <<'END';
type Readonly<T> = {
    readonly [K in keyof T]: T[K];
};

type Optional<T> = {
    [K in keyof T]?: T[K];
};

type Nullable<T> = {
    [K in keyof T]: T[K] | null;
};
END
    is(ts($code), $code, 'TS: mapped types');
}

# 6. conditional type
{
    my $code = <<'END';
type IsArray<T> = T extends unknown[] ? true : false;
type Flatten<T> = T extends (infer U)[] ? U : T;

type UnwrapPromise<T> = T extends Promise<infer U>
? UnwrapPromise<U>
: T;
END
    is(ts($code), $code, 'TS: conditional types');
}

# 7. utility types
{
    my $code = <<'END';
interface Config {
    host: string;
    port: number;
    debug: boolean;
    timeout: number;
}

type PartialConfig = Partial<Config>;
type RequiredConfig = Required<Config>;
type PickNetwork = Pick<Config, 'host' | 'port'>;
type OmitDebug = Omit<Config, 'debug'>;
type ReadonlyConfig = Readonly<Config>;
END
    is(ts($code), $code, 'TS: utility types');
}

# 8. discriminated union
{
    my $code = <<'END';
type Result<T, E = Error> =
| { success: true;  value: T }
| { success: false; error: E };

function parseJSON<T>(text: string): Result<T, SyntaxError> {
    try {
        return { success: true, value: JSON.parse(text) as T };
    } catch (e) {
        return { success: false, error: e as SyntaxError };
    }
}
END
    is(ts($code), $code, 'TS: discriminated union Result type');
}

# 9. decorator
{
    my $code = <<'END';
function log(target: any, key: string, descriptor: PropertyDescriptor) {
    const original = descriptor.value;
    descriptor.value = function (...args: unknown[]) {
        console.log(`${key} called with`, args);
        const result = original.apply(this, args);
        console.log(`${key} returned`, result);
        return result;
    };
    return descriptor;
}

class Calculator {
    @log
    add(a: number, b: number): number {
        return a + b;
    }
}
END
    is(ts($code), $code, 'TS: method decorator');
}

# 10. type guard
{
    my $code = <<'END';
interface Cat {
    meow(): void;
}

interface Dog {
    bark(): void;
}

function isCat(animal: Cat | Dog): animal is Cat {
    return 'meow' in animal;
}

function makeNoise(animal: Cat | Dog): void {
    if (isCat(animal)) {
        animal.meow();
    } else {
        animal.bark();
    }
}
END
    is(ts($code), $code, 'TS: type guard');
}

# 11. async service class
{
    my $code = <<'END';
class ApiClient {
    private baseUrl: string;
    private headers: Record<string, string>;

    constructor(baseUrl: string, token?: string) {
        this.baseUrl  = baseUrl;
        this.headers  = { 'Content-Type': 'application/json' };
        if (token) {
            this.headers['Authorization'] = `Bearer ${token}`;
        }
    }

    async get<T>(path: string): Promise<T> {
        const res = await fetch(`${this.baseUrl}${path}`, {
                headers: this.headers,
            });
        if (!res.ok) {
            throw new Error(`GET ${path}: ${res.status}`);
        }
        return res.json() as Promise<T>;
    }

    async post<T>(path: string, body: unknown): Promise<T> {
        const res = await fetch(`${this.baseUrl}${path}`, {
                method: 'POST',
                headers: this.headers,
                body: JSON.stringify(body),
            });
        if (!res.ok) {
            throw new Error(`POST ${path}: ${res.status}`);
        }
        return res.json() as Promise<T>;
    }
}
END
    is(ts($code), $code, 'TS: async API client class');
}

# 12. generic repository pattern
{
    my $code = <<'END';
interface Repository<T, ID = number> {
    findById(id: ID): Promise<T | null>;
    findAll(): Promise<T[]>;
    save(entity: T): Promise<T>;
    delete(id: ID): Promise<void>;
}

class InMemoryRepo<T extends { id: number }> implements Repository<T> {
    private store = new Map<number, T>();

    async findById(id: number): Promise<T | null> {
        return this.store.get(id) ?? null;
    }

    async findAll(): Promise<T[]> {
        return Array.from(this.store.values());
    }

    async save(entity: T): Promise<T> {
        this.store.set(entity.id, entity);
        return entity;
    }

    async delete(id: number): Promise<void> {
        this.store.delete(id);
    }
}
END
    is(ts($code), $code, 'TS: generic in-memory repository');
}

# 13. readonly tuple
{
    my $code = <<'END';
type RGB = readonly [number, number, number];
type Point2D = readonly [number, number];

function addVectors(a: Point2D, b: Point2D): Point2D {
    return [a[0] + b[0], a[1] + b[1]];
}

function blendColors(a: RGB, b: RGB, t: number): RGB {
    return [
        Math.round(a[0] + (b[0] - a[0]) * t),
        Math.round(a[1] + (b[1] - a[1]) * t),
        Math.round(a[2] + (b[2] - a[2]) * t),
    ];
}
END
    is(ts($code), $code, 'TS: readonly tuples');
}

# 14. namespace
{
    my $code = <<'END';
namespace Validation {
    export interface Validator<T> {
        validate(value: unknown): value is T;
        message: string;
    }

    export function isString(v: unknown): v is string {
        return typeof v === 'string';
    }

    export function isNumber(v: unknown): v is number {
        return typeof v === 'number' && !isNaN(v);
    }
}
END
    is(ts($code), $code, 'TS: namespace');
}

# 15. overloaded function
{
    my $code = <<'END';
function format(value: string): string;
function format(value: number, decimals?: number): string;
function format(value: Date, locale?: string): string;
function format(value: string | number | Date, extra?: number | string): string {
    if (typeof value === 'string') {
        return value.trim();
    }
    if (typeof value === 'number') {
        return value.toFixed(extra as number ?? 2);
    }
    return (value as Date).toLocaleDateString(extra as string);
}
END
    is(ts($code), $code, 'TS: function overloads');
}

# 16. template literal type
{
    my $code = <<'END';
type EventName = 'click' | 'focus' | 'blur';
type HandlerName = `on${Capitalize<EventName>}`;

type CSSUnit = 'px' | 'rem' | 'em' | '%';
type CSSValue = `${number}${CSSUnit}`;

type EventMap = {
    [K in EventName as `on${Capitalize<K>}`]: (event: Event) => void;
};
END
    is(ts($code), $code, 'TS: template literal types');
}

# 17. abstract class
{
    my $code = <<'END';
abstract class Shape {
    abstract area(): number;
    abstract perimeter(): number;

    describe(): string {
        return `area=${this.area().toFixed(2)}, perimeter=${this.perimeter().toFixed(2)}`;
    }
}

class Rectangle extends Shape {
    constructor(private width: number, private height: number) {
        super();
    }

    area(): number {
        return this.width * this.height;
    }

    perimeter(): number {
        return 2 * (this.width + this.height);
    }
}
END
    is(ts($code), $code, 'TS: abstract class');
}

# 18. infer keyword
{
    my $code = <<'END';
type ReturnType<T extends (...args: any[]) => any> =
T extends (...args: any[]) => infer R ? R : never;

type Parameters<T extends (...args: any[]) => any> =
T extends (...args: infer P) => any ? P : never;

type PromiseType<T> = T extends Promise<infer U> ? U : T;
END
    is(ts($code), $code, 'TS: infer keyword in conditional types');
}

# 19. readonly class properties
{
    my $code = <<'END';
class Config {
    readonly host: string;
    readonly port: number;
    readonly debug: boolean;

    constructor({ host = 'localhost', port = 3000, debug = false } = {}) {
        this.host  = host;
        this.port  = port;
        this.debug = debug;
    }

    withPort(port: number): Config {
        return new Config({ ...this, port });
    }
}
END
    is(ts($code), $code, 'TS: readonly class properties');
}

# 20. satisfies operator
{
    my $code = <<'END';
const routes = {
    home:    '/',
    users:   '/users',
    profile: '/users/:id',
} satisfies Record<string, string>;

type RouteKey = keyof typeof routes;

function navigate(to: RouteKey): void {
    window.location.href = routes[to];
}
END
    is(ts($code), $code, 'TS: satisfies operator');
}

# 21. using keyword (resource management)
{
    my $code = <<'END';
class TempFile implements Disposable {
    readonly path: string;

    constructor(prefix: string) {
        this.path = `/tmp/${prefix}-${Date.now()}`;
        fs.writeFileSync(this.path, '');
    }

    [Symbol.dispose]() {
        try {
            fs.unlinkSync(this.path);
        } catch {
            // ignore
        }
    }
}
END
    is(ts($code), $code, 'TS: Disposable with Symbol.dispose');
}

# 22. accessor keyword
{
    my $code = <<'END';
class Circle {
    accessor #radius: number;

    constructor(radius: number) {
        if (radius < 0) {
            throw new RangeError('Radius must be non-negative');
        }
        this.#radius = radius;
    }

    get diameter(): number {
        return this.#radius * 2;
    }

    get area(): number {
        return Math.PI * this.#radius ** 2;
    }
}
END
    is(ts($code), $code, 'TS: accessor keyword');
}

# 23. intersection type
{
    my $code = <<'END';
type Serializable = {
    serialize(): string;
};

type Timestamped = {
    createdAt: Date;
    updatedAt: Date;
};

type TimestampedEntity<T> = T & Timestamped;
type SerializableEntity<T> = T & Serializable & Timestamped;
END
    is(ts($code), $code, 'TS: intersection types');
}

# 24. readonly array
{
    my $code = <<'END';
function sortedInsert(arr: readonly number[], value: number): number[] {
    const copy = [...arr];
    let lo = 0;
    let hi = copy.length;
    while (lo < hi) {
        const mid = (lo + hi) >>> 1;
        if (copy[mid] < value) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    copy.splice(lo, 0, value);
    return copy;
}
END
    is(ts($code), $code, 'TS: readonly array parameter');
}

# 25. symbol unique
{
    my $code = <<'END';
const BRAND = Symbol('brand');
type Brand<T, B> = T & { [BRAND]: B };

type UserId = Brand<number, 'UserId'>;
type PostId = Brand<number, 'PostId'>;

function getUserById(id: UserId): Promise<User> {
    return db.users.findById(id as number);
}

function asUserId(n: number): UserId {
    return n as UserId;
}
END
    is(ts($code), $code, 'TS: branded types with Symbol');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
function greet(name: string): string {
if (!name) {
return 'Hello, stranger!';
}
return `Hello, ${name}!`;
}
END
    my $exp = <<'END';
function greet(name: string): string {
    if (!name) {
        return 'Hello, stranger!';
    }
    return `Hello, ${name}!`;
}
END
    is(ts($in), $exp, 'TS: unindented typed function normalised');
}

# 27
{
    my $in = <<'END';
class EventBus<T extends Record<string, unknown[]>> {
private listeners = new Map<keyof T, Set<Function>>();
on<K extends keyof T>(event: K, fn: (...args: T[K]) => void): () => void {
if (!this.listeners.has(event)) this.listeners.set(event, new Set());
this.listeners.get(event)!.add(fn);
return () => this.listeners.get(event)?.delete(fn);
}
emit<K extends keyof T>(event: K, ...args: T[K]): void {
this.listeners.get(event)?.forEach((fn) => fn(...args));
}
}
END
    my $exp = <<'END';
class EventBus<T extends Record<string, unknown[]>> {
    private listeners = new Map<keyof T, Set<Function>>();
    on<K extends keyof T>(event: K, fn: (...args: T[K]) => void): () => void {
        if (!this.listeners.has(event)) this.listeners.set(event, new Set());
        this.listeners.get(event)!.add(fn);
        return () => this.listeners.get(event)?.delete(fn);
    }
    emit<K extends keyof T>(event: K, ...args: T[K]): void {
        this.listeners.get(event)?.forEach((fn) => fn(...args));
    }
}
END
    is(ts($in), $exp, 'TS: unindented EventBus class normalised');
}

# 28
{
    my $in = <<'END';
type DeepReadonly<T> = {
readonly [K in keyof T]: T[K] extends object
? DeepReadonly<T[K]>
: T[K];
};
END
    my $exp = <<'END';
type DeepReadonly<T> = {
    readonly [K in keyof T]: T[K] extends object
    ? DeepReadonly<T[K]>
    : T[K];
};
END
    is(ts($in), $exp, 'TS: unindented DeepReadonly normalised');
}

# 29
{
    my $in = <<'END';
async function withRetry<T>(fn: () => Promise<T>, n: number): Promise<T> {
let last: unknown;
for (let i = 0; i < n; i++) {
try {
return await fn();
} catch (e) {
last = e;
}
}
throw last;
}
END
    my $exp = <<'END';
async function withRetry<T>(fn: () => Promise<T>, n: number): Promise<T> {
    let last: unknown;
    for (let i = 0; i < n; i++) {
        try {
            return await fn();
        } catch (e) {
            last = e;
        }
    }
    throw last;
}
END
    is(ts($in), $exp, 'TS: unindented withRetry normalised');
}

# 30
{
    my $in = <<'END';
function zip<A, B>(a: A[], b: B[]): [A, B][] {
const n = Math.min(a.length, b.length);
return Array.from({ length: n }, (_, i) => [a[i], b[i]]);
}
END
    my $exp = <<'END';
function zip<A, B>(a: A[], b: B[]): [A, B][] {
    const n = Math.min(a.length, b.length);
    return Array.from({ length: n }, (_, i) => [a[i], b[i]]);
}
END
    is(ts($in), $exp, 'TS: unindented zip normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "type Prettify<T>={[K in keyof T]:T[K]} & {};\ntype Merge<A,B>=Prettify<Omit<A,keyof B>&B>;\n",
    "function assertNever(x:never):never{\nthrow new Error('Unexpected value: '+x);\n}\n",
    "class Singleton{\nprivate static instance:Singleton;\nprivate constructor(){}\nstatic getInstance():Singleton{\nif(!Singleton.instance)Singleton.instance=new Singleton();\nreturn Singleton.instance;\n}\n}\n",
    "type Path<T,K extends keyof T=keyof T>=K extends string\n?T[K] extends Record<string,unknown>\n?K|`\${K}.\${Path<T[K]>}`\n:K\n:never;\n",
    "function createReducer<S,A extends{type:string}>(initial:S,handlers:Partial<{[T in A['type']]:( s:S,a:Extract<A,{type:T}>)=>S}>){\nreturn function reducer(state:S=initial,action:A):S{\nconst handler=handlers[action.type as A['type']];\nreturn handler?handler(state,action as any):state;\n};\n}\n",
    "function pipe<A>(a:A):A;\nfunction pipe<A,B>(a:A,ab:(a:A)=>B):B;\nfunction pipe<A,B,C>(a:A,ab:(a:A)=>B,bc:(b:B)=>C):C;\nfunction pipe(a:unknown,...fns:((x:unknown)=>unknown)[]):unknown{\nreturn fns.reduce((v,f)=>f(v),a);\n}\n",
    "type UnionToIntersection<U>=( U extends unknown?(x:U)=>void:never) extends (x:infer I)=>void?I:never;\ntype LastInUnion<U>=UnionToIntersection<U extends unknown?()=>U:never> extends ()=>infer L?L:never;\n",
    "const schema={\nname:(v:unknown):v is string=>typeof v==='string',\nage:(v:unknown):v is number=>typeof v==='number'&&v>=0,\nemail:(v:unknown):v is string=>typeof v==='string'&&v.includes('@'),\n} as const;\ntype SchemaOf<T extends Record<string,(v:unknown)=>v is any>>={\n[K in keyof T]:T[K] extends (v:unknown)=>v is infer U?U:never;\n};\n",
    "class Observable<T>{\nprivate subs:Set<(v:T)=>void>=new Set();\nsubscribe(fn:(v:T)=>void){this.subs.add(fn);return()=>this.subs.delete(fn)}\nnext(v:T){this.subs.forEach(fn=>fn(v))}\nmap<U>(fn:(v:T)=>U):Observable<U>{\nconst out=new Observable<U>();\nthis.subscribe(v=>out.next(fn(v)));\nreturn out;\n}\n}\n",
    "type Builder<T>={[K in keyof T]-?:(v:T[K])=>Builder<T>}&{build():T};\nfunction createBuilder<T>(defaults:Partial<T>={}):Builder<T>{\nconst data={...defaults} as T;\nreturn new Proxy({build:()=>({...data})},{get(_,k:string){if(k==='build')return()=>({...data});return(v:unknown)=>{(data as any)[k]=v;return proxy;};}}) as Builder<T>;\nconst proxy=createBuilder<T>(defaults);return proxy;\n}\n",
) {
    my $once = ts($snippet);
    is(ts($once), $once, 'TS: snippet idempotent');
}

done_testing;
