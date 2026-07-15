use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_ts($_[0]) }

# ── TS-specific keywords ──────────────────────────────────────────

{
    my $out = hl('interface Foo {}');
    like($out, qr/<span class="esh-k">interface<\/span>/, 'interface keyword');
}

{
    my $out = hl('type Alias = string');
    like($out, qr/<span class="esh-k">type<\/span>/,   'type keyword');
    like($out, qr/<span class="esh-k">string<\/span>/, 'string type keyword');
}

{
    my $out = hl('enum Color { Red }');
    like($out, qr/<span class="esh-k">enum<\/span>/, 'enum keyword');
}

{
    my $out = hl('abstract class Base {}');
    like($out, qr/<span class="esh-k">abstract<\/span>/, 'abstract keyword');
    like($out, qr/<span class="esh-k">class<\/span>/,    'class keyword');
}

{
    my $out = hl('const x: readonly number[] = []');
    like($out, qr/<span class="esh-k">readonly<\/span>/, 'readonly keyword');
    like($out, qr/<span class="esh-k">number<\/span>/,   'number type keyword');
}

{
    my $out = hl('private protected public override');
    like($out, qr/<span class="esh-k">private<\/span>/,  'private keyword');
    like($out, qr/<span class="esh-k">protected<\/span>/,'protected keyword');
    like($out, qr/<span class="esh-k">public<\/span>/,   'public keyword');
    like($out, qr/<span class="esh-k">override<\/span>/, 'override keyword');
}

{
    my $out = hl('declare namespace NS {}');
    like($out, qr/<span class="esh-k">declare<\/span>/,   'declare keyword');
    like($out, qr/<span class="esh-k">namespace<\/span>/, 'namespace keyword');
}

{
    my $out = hl('x as string');
    like($out, qr/<span class="esh-k">as<\/span>/, 'as keyword');
}

{
    my $out = hl('keyof typeof T');
    like($out, qr/<span class="esh-k">keyof<\/span>/,  'keyof keyword');
    like($out, qr/<span class="esh-k">typeof<\/span>/, 'typeof keyword');
}

# ── JS keywords still work ────────────────────────────────────────

{
    my $out = hl('const x = async () => { return await y; }');
    like($out, qr/<span class="esh-k">const<\/span>/,  'const keyword');
    like($out, qr/<span class="esh-k">async<\/span>/,  'async keyword');
    like($out, qr/<span class="esh-k">return<\/span>/, 'return keyword');
    like($out, qr/<span class="esh-k">await<\/span>/,  'await keyword');
}

# ── TS utility type builtins ──────────────────────────────────────

{
    my $out = hl('type P = Partial<Foo>');
    like($out, qr/<span class="esh-b">Partial<\/span>/, 'Partial builtin');
}

{
    my $out = hl('type R = Readonly<Bar>');
    like($out, qr/<span class="esh-b">Readonly<\/span>/, 'Readonly builtin');
}

{
    my $out = hl('type X = NonNullable<T>');
    like($out, qr/<span class="esh-b">NonNullable<\/span>/, 'NonNullable builtin');
}

{
    my $out = hl('type RT = ReturnType<typeof fn>');
    like($out, qr/<span class="esh-b">ReturnType<\/span>/, 'ReturnType builtin');
}

# ── decorators ────────────────────────────────────────────────────

{
    my $out = hl('@Component class App {}');
    like($out, qr/<span class="esh-p">\@Component<\/span>/, '@Component decorator');
}

{
    my $out = hl('@Injectable() class Svc {}');
    like($out, qr/<span class="esh-p">\@Injectable<\/span>/, '@Injectable decorator');
}

# ── strings ───────────────────────────────────────────────────────

{
    my $out = hl('"hello world"');
    like($out, qr/<span class="esh-s">&quot;hello world&quot;<\/span>/, 'double-quoted string');
}

{
    my $out = hl("'single'");
    like($out, qr/<span class="esh-s">'single'<\/span>/, 'single-quoted string');
}

# ── numbers ───────────────────────────────────────────────────────

{
    my $out = hl('42');
    like($out, qr/<span class="esh-n">42<\/span>/, 'integer');
}

{
    my $out = hl('3.14');
    like($out, qr/<span class="esh-n">3\.14<\/span>/, 'float');
}

# ── comments ─────────────────────────────────────────────────────

{
    my $out = hl('// a comment');
    like($out, qr/<span class="esh-c">\/\/ a comment<\/span>/, 'line comment');
}

# ── HTML safety ───────────────────────────────────────────────────

{
    my $out = hl('x < y');
    like($out, qr/&lt;/, 'less-than HTML-escaped');
}

{
    my $out = hl('const s: Array<string> = []');
    like($out, qr/<span class="esh-b">Array<\/span>&lt;/, 'Array builtin followed by HTML-escaped <');
    like($out, qr/&lt;<span class="esh-k">string<\/span>&gt;/, 'generic type param HTML-escaped');
}

# ── partial keyword non-match ─────────────────────────────────────

{
    my $out = hl('interfaces');
    unlike($out, qr/<span class="esh-k">interface<\/span>/, 'interface prefix not highlighted');
}


# ── more TS-specific keywords ─────────────────────────────────────

{
    my $out = hl('infer U');
    like($out, qr/<span class="esh-k">infer<\/span>/, 'infer keyword');
}

{
    my $out = hl('satisfies Record<string, unknown>');
    like($out, qr/<span class="esh-k">satisfies<\/span>/, 'satisfies keyword');
}

{
    my $out = hl('from "module"');
    like($out, qr/<span class="esh-k">from<\/span>/, 'from keyword');
}

{
    my $out = hl('class A implements B, C {}');
    like($out, qr/<span class="esh-k">implements<\/span>/, 'implements keyword');
}

{
    my $out = hl('module "foo" {}');
    like($out, qr/<span class="esh-k">module<\/span>/, 'module keyword');
}

{
    my $out = hl('x is string');
    like($out, qr/<span class="esh-k">is<\/span>/, 'is keyword (type predicate)');
}

{
    my $out = hl('object never never unique symbol');
    like($out, qr/<span class="esh-k">object<\/span>/, 'object type keyword');
    like($out, qr/<span class="esh-k">never<\/span>/, 'never type keyword');
    like($out, qr/<span class="esh-k">unique<\/span>/, 'unique keyword');
    like($out, qr/<span class="esh-k">symbol<\/span>/, 'symbol type keyword');
}

{
    my $out = hl('asserts x is string');
    like($out, qr/<span class="esh-k">asserts<\/span>/, 'asserts keyword');
}

{
    my $out = hl('bigint');
    like($out, qr/<span class="esh-k">bigint<\/span>/, 'bigint keyword');
}

{
    my $out = hl('boolean any');
    like($out, qr/<span class="esh-k">boolean<\/span>/, 'boolean keyword');
    like($out, qr/<span class="esh-k">any<\/span>/, 'any keyword');
}

{
    my $out = hl('unknown void');
    like($out, qr/<span class="esh-k">unknown<\/span>/, 'unknown keyword');
    like($out, qr/<span class="esh-k">void<\/span>/, 'void keyword (TS context)');
}

# ── more TS builtins (utility types) ─────────────────────────────

{
    my $out = hl('type P = Partial<T>');
    like($out, qr/<span class="esh-b">Partial<\/span>/, 'Partial utility type');
}

{
    my $out = hl('type R = Required<T>');
    like($out, qr/<span class="esh-b">Required<\/span>/, 'Required utility type');
}

{
    my $out = hl('type M = Record<string, number>');
    like($out, qr/<span class="esh-b">Record<\/span>/, 'Record utility type');
}

{
    my $out = hl('type P = Pick<T, "a" | "b">');
    like($out, qr/<span class="esh-b">Pick<\/span>/, 'Pick utility type');
}

{
    my $out = hl('type O = Omit<T, "x">');
    like($out, qr/<span class="esh-b">Omit<\/span>/, 'Omit utility type');
}

{
    my $out = hl('type E = Exclude<T, U>');
    like($out, qr/<span class="esh-b">Exclude<\/span>/, 'Exclude utility type');
}

{
    my $out = hl('type X = Extract<T, U>');
    like($out, qr/<span class="esh-b">Extract<\/span>/, 'Extract utility type');
}

{
    my $out = hl('type N = NonNullable<T>');
    like($out, qr/<span class="esh-b">NonNullable<\/span>/, 'NonNullable utility type');
}

{
    my $out = hl('type P = Parameters<typeof f>');
    like($out, qr/<span class="esh-b">Parameters<\/span>/, 'Parameters utility type');
}

{
    my $out = hl('type A = Awaited<Promise<string>>');
    like($out, qr/<span class="esh-b">Awaited<\/span>/, 'Awaited utility type');
}

# ── more decorators ───────────────────────────────────────────────

{
    my $out = hl('@Injectable({ providedIn: "root" })');
    like($out, qr/<span class="esh-p">\@Injectable<\/span>/, '@Injectable decorator');
}

{
    my $out = hl('@Input() value!: string;');
    like($out, qr/<span class="esh-p">\@Input<\/span>/, '@Input property decorator');
}

{
    my $out = hl('@my_decorator.method');
    like($out, qr/<span class="esh-p">\@my_decorator\.method<\/span>/, 'dotted decorator');
}

# ── JS keywords still work in TS ─────────────────────────────────

{
    my $out = hl('for (const x of arr) { break; continue; }');
    like($out, qr/<span class="esh-k">for<\/span>/,      'for keyword in TS');
    like($out, qr/<span class="esh-k">break<\/span>/,    'break keyword in TS');
    like($out, qr/<span class="esh-k">continue<\/span>/, 'continue keyword in TS');
}

{
    my $out = hl('import { foo } from "./bar"');
    like($out, qr/<span class="esh-k">import<\/span>/, 'import keyword in TS');
}

# ── lang aliases ──────────────────────────────────────────────────

{
    my $out = Eshu->highlight_string('interface X {}', lang => 'typescript');
    like($out, qr/<span class="esh-k">interface<\/span>/, 'lang=typescript dispatches correctly');
}

{
    my $out = Eshu->highlight_string('type A = B', lang => 'tsx');
    like($out, qr/<span class="esh-k">type<\/span>/, 'lang=tsx dispatches correctly');
}

{
    my $out = Eshu->highlight_string('type A = B', lang => 'mts');
    like($out, qr/<span class="esh-k">type<\/span>/, 'lang=mts dispatches correctly');
}

done_testing;
