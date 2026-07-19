# Persisted Queries

`GraphQL::Houtou` の current mainline では、Persisted Queries は次の 2 形態に分けて考えるのが実務的です。

なお、subscription operation typeを持つprogram／bundle descriptorはload時に
拒否されます。事前コンパイル済みartifactから0.01のsubscription非対応境界を
迂回することはできません。

## 1. 固定クエリ・固定 specialization を native bundle として保持する

変数を request ごとに差し替えない query なら、`compile_native_bundle` または
`compile_native_bundle_descriptor` をそのまま persisted artifact として使えます。

```perl
use GraphQL::Houtou qw(build_native_runtime compile_native_bundle);

my $runtime = build_native_runtime($schema);

my %persisted = (
  hello => compile_native_bundle($schema, '{ hello }'),
);

my $result = $runtime->execute_bundle($persisted{hello});
```

descriptor を保存したい場合は次です。

```perl
my $descriptor = $schema->compile_native_bundle_descriptor('{ hello }');
my $result = $runtime->execute_bundle_descriptor($descriptor);
```

この形は:

- boot 時に native artifact を作れる
- request 時は document parse / lowering を省ける
- native bundle mainline をそのまま使える

ので、最も速い persisted query の形です。

## 2. 変数を request ごとに差し替える query は lowered program を保持する

`compile_native_bundle` は現状、native 実行前に variable / directive specialization を行うため、
**変数を毎 request 差し替える一般的な persisted query** にはそのままだと向きません。

その場合は VM program を persisted artifact として保持し、request 時に native mainline で specialization して実行します。

```perl
my $runtime = build_native_runtime($schema);

my %persisted = (
  greet => $runtime->compile_program(
    'query($name: String){ greet(name: $name) }',
  ),
);

my $result = $runtime->execute_program(
  $persisted{greet},
  variables => { name => 'alice' },
);
```

この形でも次は省けます。

- parse
- operation lowering

request 時に残るのは variable specialization と native 実行です。

## 推奨方針

- **固定 query / 固定 specialization**
  - `compile_native_bundle`
  - `compile_native_bundle_descriptor`
- **変数つき persisted query**
  - `compile_program`
  - `execute_program`

つまり、persisted query の主目的を

- parse/lowering を消す
- native mainline を通す

と考えるなら、現状でも十分に実用可能です。

将来的に variable-bearing query も native descriptor へ直接落とせるようになれば、
この境界はさらに前に進められます。
