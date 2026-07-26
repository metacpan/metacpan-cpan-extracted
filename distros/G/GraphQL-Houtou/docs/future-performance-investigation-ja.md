# GraphQL::Houtou 次期高速化調査

## 1. 目的

現行の GraphQL::Houtou は、GraphQL AST をリクエストごとに走査する構造から、
schema と operation を事前に native program へ lower し、XS VM 上で実行する構造へ
移行している。

本書では、現行アーキテクチャを前提として、次の大幅な高速化に向けた候補を整理する。

- 現時点の主要なボトルネック
- 変数、引数、resolver、response 構築の内部構造
- JIT、AOT、VM specialization の有効性
- async、parser、validation を含む周辺領域
- 現在の設計を維持した場合の性能上限
- 実装前に行うべき計測と実験

結論を先に述べると、次の主要な高速化対象は VM 命令 dispatch の JIT 化ではない。
現状の大きな天井は次の 3 点である。

1. 変数と引数をリクエストごとに Perl の HV/SV へ変換、coerce する処理
2. resolver を Perl callback として field ごとに呼ぶ境界コスト
3. response を Perl の HV/AV として生成するコスト

## 2. 現行アーキテクチャ

現行実装はすでに次の最適化を備えている。

- query parse と validation の結果を再利用する program cache
- schema field と callback catalog の index 化
- operation の block/op/slot 配列への lowering
- runtime と program を融合した native bundle
- 同期 SV、直接 JSON、async の実行レーン分離
- native value、outcome、writer による中間 HashRef の排除
- built-in scalar の C 側 coercion
- path frame の遅延生成
- Promise::XS に特化した async scheduler

このため、単純な「XS 化」「AST を VM にする」「opcode を整数化する」といった
高速化はすでに実施済みである。

固定 native bundle の同期実行は概ね次の経路を通る。

```text
XSUB 入口
  → request state 初期化
  → block/op loop
      → args HV 生成
      → Perl resolver 呼び出し
      → leaf coercion / child block
      → response HV への格納
  → { data => ... } envelope 生成
```

変数付き operation では、その前後に次の処理が追加される。

```text
variables HV
  → variable ごとの存在確認と SV 複製
  → input coercion
  → prepared variables HV
  → field ごとの dynamic argument materialize
  → argument coercion
  → resolver 用 args HV
```

## 3. ベンチマーク

### 3.1 条件

- 計測日: 2026-07-24
- Apple Silicon
- Perl 5.44
- XS: `-O3`
- `util/execution-benchmark-checkpoint.pl`
- 5 標本の中央値
- resolver の戻り値はリクエストごとに生成
- schema、program、bundle は事前コンパイルして再利用

### 3.2 結果

| ワークロード | throughput |
|---|---:|
| 変数付き nested object | 203,829 req/s |
| 同じ operation の固定 native bundle | 705,151 req/s |
| list of objects | 331,918 req/s |
| 同じ query の固定 native bundle | 627,139 req/s |
| abstract + fragment | 336,097 req/s |
| 同じ query の固定 native bundle | 697,805 req/s |
| list → Perl 構造 → JSON encode | 494,696 req/s |
| list → JSON 直接生成 | 931,786 req/s |

重要な差は次の通りである。

- 変数付き program から固定 bundle: 約 3.46 倍
- Perl response から直接 JSON: 約 1.88 倍
- 固定 bundle の各 query shape: 約 62 万〜71 万 req/s に収束

固定 bundle で object、list、abstract が近い範囲に収束していることから、
query shape 固有の VM 命令より、resolver callback、Perl scalar 操作、response
生成などの共通処理が支配的になり始めていると考えられる。

なお、macOS の sampling profiler による C レベルのサンプリングも試行したが、
プロセス起動と module load の期間を多く取得したため、定量的な hotspot の根拠には
採用していない。本書の判断は、反復ベンチマーク、レーン間差分、実装上の allocation
構造に基づく。

## 4. ボトルネック

### 4.1 変数 preparation

`gql_runtime_vm_prepare_program_variables_sv` は、リクエストごとに新しい HV を作り、
variable definition ごとに次を行う。

- provided variables の名前検索
- 入力 SV の複製
- default value の materialize
- GraphQL input coercion
- coerced HV への格納
- operation が宣言していない追加 variable の複製

単純な `ID!` 変数 1 個であっても、固定 bundle には存在しない request-time 処理が
複数発生する。

### 4.2 dynamic argument specialization

変数 preparation の後、各 field の resolver を呼ぶ直前に、dynamic argument が
再び materialize、coerce され、resolver 用の args HV に格納される。

概念的には次の往復が発生する。

```text
入力 SV
  → prepared variables HV
  → native dynamic value の参照
  → argument SV
  → coerced args HV
  → Perl resolver
```

変数付き nested object が固定 bundle の約 29% の throughput に留まることから、
ここは最重要の改善候補である。

### 4.3 Perl resolver callback

明示 resolver では field ごとに次が必要になる。

- Perl stack の準備
- callback arguments の refcount 操作
- `call_sv`
- `G_EVAL` による例外境界
- return SV の取得
- Promise::XS 判定
- completion と result coercion

resolver 本体が定数を返すだけでも、この境界コストは発生する。query の field 数が
増えると、VM dispatch より callback 回数が支配的になる。

### 4.4 response の HV/AV 化

同期 SV レーンは block ごとに `newHV()` し、field ごとに `hv_store()` する。
list ではさらに AV と item ごとの object HV が必要になる。

直接 JSON レーンでは、同じ block/op loop から出力 SV へ JSON bytes を append
するため、中間 response tree の allocation を回避できる。

同じ固定 list query で直接 JSON が約 1.88 倍高速であることから、HTTP response が
最終的に JSON になる用途では HV/AV 化が大きな天井である。

### 4.5 async scheduler

async レーンでは、VM の field completion に加えて次のコストが発生する。

- Promise::XS の生成
- `then` callback の登録
- resolve/reject callback context
- pending entry
- path frame
- ready queue と frame の再構築
- settle 時の refcount 操作

特に「list 全体を返す promise」より「item ごとに 1 promise」の方が大幅に遅くなる。
async の性能は opcode dispatch より promise 数に左右されやすい。

## 5. 優先度 A: 変数・引数パイプラインの刷新

現在の経路を次のように短縮する。

```text
現状:
入力 SV → coerce 済み HV → dynamic native value → args HV → resolver

候補:
入力 SV → typed request slots → resolver adapter
```

operation compile 時に、variable と argument の対応を固定命令列へ lower する。

```text
ARG_COPY_VAR    dst_arg_slot, variable_slot
ARG_CONST       dst_arg_slot, constant_slot
ARG_DEFAULT     dst_arg_slot, default_slot
ARG_COERCE_ID   dst_arg_slot
ARG_REQUIRED    dst_arg_slot
```

request ごとに固定長 slot 配列を生成し、名前による HV lookup、coerced variables HV、
field ごとの argument definition 探索を排除する。

ただし、従来の Perl resolver ABI が `$args` HashRef を要求する限り、callback 直前の
args HV 生成は残る。そのため resolver ABI を次のように分離する。

- compatibility ABI: 従来の HashRef
- typed native ABI: positional slots または opaque `ArgsView`
- no-args ABI: args、info、type を積まない
- common signature ABI: 使用頻度の高い引数数に特化

特に no-args field では、共有 empty HashRef を渡すだけでなく、callback の引数自体を
減らすことを検討する。

## 6. 優先度 A: resolver 境界の削減

### 6.1 宣言的 resolver

resolver を分類し、callback 不要な field を増やす。

- Hash key の取得
- array index の取得
- constant
- root/context slot の取得
- rename
- accessor method
- 単純な文字列結合
- native function

これらを schema compile 時に resolver opcode へ lower する。

```text
LOAD_HASH_KEY      source, interned_key
LOAD_CONTEXT_SLOT  n
LOAD_CONST         n
CALL_PERL_CV       n
CALL_NATIVE_FN     n
```

default resolver の HashRef key lookup はすでに C 側にあるが、アプリケーションが
同じ操作を明示 resolver で包むと Perl callback が必要になる。宣言的 resolver API
を提供すれば、互換性を保ったまま callback 数を減らせる。

### 6.2 native row/view

親 resolver が毎回 HashRef を作り、その子 field が key lookup する構造では、
executor が高速でもアプリケーション側の HashRef allocation が残る。

より高速な契約として、resolver が次を返せるようにする。

- native row
- packed array
- C struct の opaque view
- slot index で値を取得できる row adapter

この場合、child field は名前検索なしで値を読み、直接 JSON writer へ流せる。

## 7. 優先度 A: JSON レーンの強化

HTTP server の最終出力が JSON なら、Perl response tree は中間生成物である。
可能な経路では `execute_*_to_json` を主経路として扱う。

改善候補:

- PSGI 経路を原則直接 JSON へ寄せる
- field name を `"name":` の形まで compile 時に escape
- scalar 型ごとの emitter function を slot に保存
- block ごとの固定 JSON template
- 出力サイズの予測と `SvGROW`
- list item 用 tight loop
- UTF-8 検証済み native string ABI
- error がない場合の envelope fast path

固定 query は最終的に次の形へ近づけられる。

```text
JSON template literal
  → resolver result
  → type-specific scalar append
  → JSON template literal
```

これは machine code を生成せずに JIT に近い specialization を得る方法である。

## 8. JIT の評価

### 8.1 opcode JIT

現行 VM の opcode は resolve family と completion family の直積で、実質 8 種類である。
block/op は連続配列、slot と callback も index 化されている。

そのため、switch や dispatch を機械語化するだけの JIT は効果が限定的と考えられる。
resolver callback、HV/AV 生成、SV refcount が支配的なら、VM dispatch をゼロコストに
しても全体の改善率は小さい。

また、Perl API を呼ぶ JIT code は次を扱う必要がある。

- interpreter context
- SV refcount と mortal
- save stack
- croak/longjmp 安全性
- Perl version ABI
- W^X と platform ごとの実行コード制約
- sanitizer と debugger

実装、保守、移植性のコストに対して、得られる性能が見合わない可能性が高い。

### 8.2 有望な specialization

JIT 的な最適化を行う場合は、VM 全体ではなく固定 program の次の要素に限定する。

1. block/op の直線化
2. resolver ABI と completion family の定数畳み込み
3. field name、slot、child block の即値化
4. error と Non-Null 処理の cold path 分離
5. JSON template emitter の生成

最初は machine-code JIT ではなく、function pointer 列による executable steps が
安全である。

```c
struct compiled_step {
    resolve_fn resolve;
    complete_fn complete;
    emit_fn emit;
    const slot *slot;
};
```

これにより opcode decode と一部の条件分岐を除去しつつ、LLVM や runtime code
generation への依存を避けられる。

### 8.3 AOT query compiler

persisted query をビルド時に C へ変換し、XS bundle へコンパイルする AOT 方式は、
runtime JIT より本プロジェクトと相性がよい可能性がある。

利点:

- C compiler による inline と定数畳み込み
- production で実行時コード生成が不要
- symbolized profile を取得しやすい
- sanitizer を利用できる
- persisted query と自然に統合できる

ただし、field ごとの Perl resolver callback が残る限り改善幅は限定される。
AOT の価値が大きくなるのは、native/declarative resolver ABI と組み合わせた場合である。

## 9. 内部構造の刷新

### 9.1 request arena

request state、error、path、temporary args、native value を arena からまとめて確保し、
request 終了時に一括解放する。

response HV/SV は request 後も生存し得るため arena に置けないが、直接 JSON レーン
では多くの temporary allocation を arena 化できる。

async レーンにある pool と統合し、同期、非同期で共通の request allocator を
持つことも検討できる。

### 9.2 struct-of-arrays

op/slot の大きな struct から hot loop で必要な field のみを分離する。

```text
opcode[]
slot_index[]
child_block[]
result_name_ptr[]
result_name_len[]
resolver_ptr[]
flags[]
```

cache locality の改善余地はあるが、小さい query では効果が限られる可能性がある。
L1 miss、frontend stall、working set を hardware counter で確認してから採用すべきである。

### 9.3 fused executable bundle

bundle 生成時に、各 op へ次を直接接続する。

- resolver CV
- return type object
- leaf serializer
- abstract dispatch table
- pre-escaped JSON key
- specialized argument plan

現在の runtime callback catalog と schema slot index を経由する間接参照を減らし、
op を実行可能な step に近づける。

### 9.4 speculative error-free lane

通常リクエストでは field error がない。それでも通常ループには promise、error、
path、Non-Null 用の分岐が存在する。

compile 時に program traits を解析する。

- custom scalar なし
- runtime directive なし
- abstract fallback なし
- sync-only resolver
- path frame の遅延生成が可能

条件を満たす block は専用の fast loop で実行し、例外時だけ generic completion へ
deopt する方式を検討する。

## 10. parser と validation

persisted query や program cache hit を前提にすれば、parser と validation は定常的な
request hot path ではない。そのため execution 改善より優先度は低い。

ad-hoc query が主要用途の場合の候補:

- parser AST を全面的に Perl HV/AV 化せず operation compiler が直接消費
- parse、validation、lowering の arena 共有
- field/type name の schema-wide interning
- validation selection graph と execution program の同時構築
- location 情報の遅延 materialize
- negative validation cache
- normalized document hash の早期生成

現行 parser は最終的な AST を Perl の HV/AV として公開するため、この allocation が
parser surface を維持する場合の下限になる。

## 11. async レーン

async では JIT より promise 数と callback allocation の削減を優先する。

候補:

- resolver 単位でなく batch/collection 単位の promise を推奨
- already-resolved promise を callback arm 前に unwrap
- Promise::XS との直接的な settle hook
- callback pair、pending entry、path frame の request arena 化
- list pending を item ごとでなく range/bitmap で管理
- 同期で完了する subtree を async frame へ昇格させない
- async JSON でも native value を最後まで維持

async の最終的な天井は Promise::XS の CV、`then`、refcount、scheduler interaction
になる可能性が高い。

## 12. 性能上限

### 12.1 I/O を含む実アプリケーション

DB や network I/O が主要な latency である場合、executor を 2 倍にしても request
latency はほとんど変わらないことがある。

この場合に重要なのは次である。

- DataLoader の batch 率
- resolver 数
- N+1 query
- response size
- allocation と GC/refcount による tail latency

executor の高速化は、単一 request の latency より CPU 密度と同時実行可能数に効く。

### 12.2 in-memory GraphQL

Perl resolver を field ごとに呼ぶ設計を維持する場合、現在の約 60 万〜90 万 req/s は
すでに高い位置にある。

概算の改善余地:

- 局所的な C 最適化: 5〜20%
- fused op、JSON template、arena: 20〜60%
- typed arguments と specialized callback ABI: 変数付きで 1.5〜3 倍
- callback を減らす declarative/native resolver: query shape 次第で 2 倍以上
- 完全 native resolver と AOT JSON emitter: 現行とは別クラス

100 万〜150 万 req/s 程度は現行設計の延長で狙える可能性がある。それ以上を安定して
狙うには「各 field で Perl callback を呼ぶ」という契約自体を変える必要がある。

## 13. 推奨する実験順序

1. field 数、list 長、resolver 種別、args 数、variables 深度を変えた benchmark matrix を作る
2. variable preparation、argument specialization、resolver、completion、emit に C 内計測を入れる
3. typed request slots を試作し、変数付き nested case だけで効果を確認する
4. JSON key の pre-escape と block template を試す
5. fused executable step で VM dispatch 除去の実益を測る
6. native/declarative resolver を 1 種類だけ導入して callback 境界の上限を測る
7. その結果を基に AOT/JIT の採否を決める

最初の成功指標は次が妥当である。

- 変数付き nested object: 約 20 万 req/s から 40 万 req/s 以上
- 固定 bundle の直接 JSON: 約 93 万 req/s から 120 万 req/s 以上

JIT は目的ではなく、計測によって VM dispatch が十分大きな割合を占めると確認できた
場合にのみ採用する。現時点では、変数/引数の typed slots、resolver callback の削減、
JSON template 化の方が高い効果を期待できる。

## 14. 実装チェックポイント: prepared variable の直接利用

2026-07-24 に、typed request slots へ進む前の第一段階として、直接 variable reference
を argument に渡す経路から二度目の input coercion を除去した。

GraphQL の実行モデルでは、variable は variable definition に従う
`CoerceVariableValues` で一度 coerce され、argument はその prepared value を参照する。
従来実装は、prepared variables HV から値を materialize した後、field の argument
definition に対して同じ値をもう一度 coerce していた。

今回の fast path は次の条件に限定している。

- dynamic argument payload の値全体が単一の variable reference
- prepared variables HV に対象 variable が存在する
- prepared value が null ではない

list/input-object literal の一部に variable が含まれる場合は、外側の literal 全体を
argument type に従って coerce する必要があるため従来経路を維持する。

null も従来経路へ戻す。validation を明示的に迂回した実行では、nullable variable を
Non-Null argument へ渡す不正を argument coercion が検出する必要があるためである。

custom scalar の `parse_value` が直接 variable argument で一度だけ呼ばれる回帰テストを
追加した。全 49 test files、470 tests が成功している。

最終確認の 3 標本中央値:

| ワークロード | 変更前 | 変更後 | 改善 |
|---|---:|---:|---:|
| nested variable object | 203,829 req/s | 238,432 req/s | +17.0% |
| fresh variables per request | 196,383 req/s | 231,849 req/s | +18.1% |

先行する 5 標本ではそれぞれ 243,926 req/s、232,943 req/s だった。測定揺れを考慮しても、
二重 coercion の除去には約 17〜20% の改善があり、変数/引数パイプラインが主要な
最適化対象であるという仮説を支持する。

次の段階では、prepared variables HV と名前 lookup 自体を固定長 typed slots へ
置き換え、argument plan から slot index で参照できる構造を検討する。

続く小変更として、provided variables HV が保持している raw SV を variable coercion
へ渡す際の `newSVsv` を除去した。coercion 中は入力 HV が raw SV を所有し続け、
coercion 結果は別の owned SV になるため、入力の複製は不要である。

この変更後の 3 標本中央値は nested variable object が 243,926 req/s、fresh variables
が 236,302 req/s だった。直前の保守的な 3 標本から約 2%、最初の基準からはそれぞれ
約 19.7%、20.3% の改善となった。

### 14.1 Variable preparation と同期実行の融合

次に、variable-invariant program の同期 SV/JSON レーンについて、variable preparation
と実行を 1 回の XSUB 呼び出しへ融合した。

従来経路:

```text
Perl
  → prepare_variables XSUB
  → prepared variables HV を Perl へ返す
  → execute program XSUB
  → sync fast lane
```

新経路:

```text
Perl
  → fused prepare-and-execute XSUB
      → prepared variables HV
      → sync fast lane
```

prepared variables HV は fused XSUB 内の request-local temporary となり、Perl 側へ
一度返して再び XS へ渡す必要がなくなった。runtime directive または
variable-dependent directive guard により program specialization が必要な場合は、
従来経路を維持する。

5 標本中央値:

| ワークロード | 最初の基準 | 融合後 | 改善 |
|---|---:|---:|---:|
| nested variable object | 203,829 req/s | 324,585 req/s | +59.2% |
| fresh variables per request | 196,383 req/s | 307,680 req/s | +56.7% |

直前の raw SV clone 除去後との比較でも、それぞれ約 33.1%、30.2% 改善した。

同期 JSON レーンにも同じ融合入口を追加した。変数を持たない list-of-objects の
`execute_document_to_json` でも、prepared empty HV の Perl 往復が消える。

3 標本中央値:

| ワークロード | 変更前 | 融合後 | 改善 |
|---|---:|---:|---:|
| `execute_document_to_json` | 359,102 req/s | 411,560 req/s | +14.6% |

この結果から、typed slots の前段階として、request hot path を複数の XSUB に分割せず
coercion、argument materialization、execution、emit を単一 native request scope に
維持すること自体が重要であると分かる。

### 14.2 Variable name の compile-time slot binding

native dynamic value が持つ variable name を、native program load 時に
`variable_defs` の index へ bind するようにした。融合同期レーンでは coerce 済み
variable value を同じ順序の request-local slot 配列にも記録し、直接 variable
argument は次のように参照する。

```text
従来: argument payload → variable name → prepared HV の hv_fetch
現在: argument payload → variable index → prepared slots[index]
```

8 variables 以下の一般的な operation では slot 配列を XSUB の C stack 上に置き、
request-time heap allocationを追加しない。8 variables を超える operation と、
descriptor-only/unbound value は従来の名前 lookup へ戻る。

nullable variable が未指定の場合、slot は null pointer のままになる。このケースを
`undef` value として安全に従来の argument coercion へ戻す必要がある。初回の全テストで
この条件が canonical pagination query の crash として検出され、slot pointer と
格納 value の両方を検査する deopt guard を追加した。

5 標本中央値:

| ワークロード | XSUB 融合後 | slot index 導入後 | 改善 |
|---|---:|---:|---:|
| nested variable object | 324,585 req/s | 329,244 req/s | +1.4% |
| fresh variables per request | 307,680 req/s | 310,597 req/s | +0.9% |

1 variable、1 dynamic argument の小さい query では lookup が 1 回しかないため改善は
小さい。複数 field が同じ variable を参照する query では request preparation 1 回に
対して field ごとの名前 lookup を除去できるため、相対効果が大きくなると予想される。

### 14.3 採用しなかった単一 HV lookup

variable preparation は、provided variables に対して `hv_exists` を行った後、同じkeyを
`hv_fetch`している。これを単一の`hv_fetch`へ置き換える実験を行った。

5標本中央値はnested variable objectが327,680 req/s、fresh variablesが
308,163 req/sで、直前の329,244 req/s、310,597 req/sを上回らなかった。差は
0.5〜0.8%で測定ノイズの範囲だが、改善を実証できない変更は採用せずrevertした。

prepared variables HVそのものの遅延化には、次の3要素を同時に導入する必要がある。

- slot valueを所有するrequest-scoped AVまたはarena
- generic resolverが`info->{variable_values}`を要求した時の遅延HV materialize
- nested input literal、runtime directive、unbound descriptorの名前lookup deopt

空HashRefのglobal共有は、resolverによる変更が別requestへ漏れるため採用しない。

### 14.4 Slot-only owner と遅延 compatibility HV

融合同期レーンで、8 variables 以下のoperationはprepared variables HVを一次表現に
使わず、request-scoped AVをslot valueのownerとして使うようにした。

```text
provided variables HV
  → variable coercion
  → request AV owns coerced SVs
  → stack slots[index] borrows each SV
  → direct variable arguments
```

通常のnative resolverと直接variable argumentだけで完走する場合、coerce済みvariables
HashRefは生成されない。次の場合だけ、programのvariable definition、slot values、
provided variablesから従来互換のHashRefを遅延構築する。

- generic resolverがlazy infoを受け取る
- resolverが`info->{variable_values}`をmaterializeする
- input object/list literal内部にvariable referenceがある
- unbound variable valueが名前lookupを必要とする

未宣言のprovided variableも従来どおりcompatibility HVへコピーする。これにより
`info->{variable_values}`の既存契約を維持しつつ、native fast pathではHV allocationを
回避できる。

追加した回帰テスト:

- generic resolverの`variable_values`にcoerce済み値と追加variableが見える
- input object literal内部のvariableがfallback HVから解決される
- missing nullable variable、custom scalar、request errorの既存テスト

5標本中央値:

| ワークロード | slot index導入後 | slot-only owner導入後 | 改善 |
|---|---:|---:|---:|
| nested variable object | 329,244 req/s | 337,313 req/s | +2.5% |
| fresh variables per request | 310,597 req/s | 323,567 req/s | +4.2% |

最初の基準との比較では、それぞれ約65.5%、64.8%の改善となった。

変数を持たない`execute_document_to_json`は410,526 req/sで、直前の411,560 req/sと
同等だった。空HVと空AVのallocation差はこのqueryでは支配的でない。

### 14.5 引数なし resolver の専用 ABI

引数を宣言しない field 向けに、opt-in の
`resolver_mode => 'native_no_args'`を追加した。通常のnative resolverは
`($source, $args, $context, $return_type)`を受け取るが、このABIは
`($source, $context, $return_type)`を受け取る。同期SV、同期JSON、asyncの各レーンで
空args HashRefの取得とcallback stackへのpushを省く。

`util/resolver-abi-benchmark.pl`で、同じcompiled programを従来native ABIと比較した。
2秒測定:

| query幅 | native | native_no_args | 改善 |
|---:|---:|---:|---:|
| 1 field | 800,148 req/s | 827,076 req/s | +3% |
| 10 fields | 333,577 req/s | 372,754 req/s | +12% |
| 25 fields | 162,292 req/s | 186,535 req/s | +15% |

field数に比例してcallback境界の固定費が積み上がるため、幅の広いqueryでは明確に効く。
誤ったABI利用を防ぐため、argumentを宣言したfieldへの指定はruntime graph compile時に
拒否する。

positional argument ABIも候補だが、可変個数のPerl callback stack構築、default値と
argument定義順の固定、descriptor互換性を新たな公開契約として持つ必要がある。
今回のbranchで改善が実証できた引数なしABIとは独立に評価できるため、このPRには
含めず別実験とする。

### 14.6 採用しなかった汎用 positional resolver ABI

別branchで`($source, @argument_values, $context, $return_type)`というopt-in ABIを
試作した。argument値はcompact schema定義の安定順序で渡し、variable、default値、
同期実行まで実装した。

最初の実装は既存args HashRefをpositional値へ展開したため、通常native ABIより
1〜5%遅かった。次にstatic argument payloadを定義順のAVとして一度だけcacheし、
request時にはHashRefを経由せずcallback stackへ積むようにしたが、それでも次の結果に
なった。

| query幅 | nativeとの差 |
|---:|---:|
| 1 field、2 arguments | -1% |
| 10 fields、2 arguments | -2% |
| 25 fields、2 arguments | -3% |

固定4引数のnative callbackに対し、汎用positional ABIはfieldごとにargument定義を走査し、
可変個数のPerl stack entryを積む。その固定費がresolver内のHash lookup削減を上回った。
公開ABIとdescriptor codeを増やす根拠がないため実装はrevertした。

次に試すなら汎用positionalではなく、引数が1個だけのfield専用ABIに限定する。これは
既存native callbackと同じ固定4引数callを使いながら、args HashRefの生成とresolver内の
Hash lookupを同時に除去できる。

### 14.7 1引数専用 resolver ABI

`resolver_mode => 'native_one_arg'`を追加し、argumentを1個だけ宣言するfieldのresolverを
`($source, $value, $context, $return_type)`で呼ぶようにした。汎用positional ABIと違い、
既存native resolverと同じ固定4引数callbackを使う。

static argumentはnative payloadから値を直接cacheする。dynamic argumentはargument
HashRefを生成せず、coerce済みvariable slotを直接参照する。direct variableでない
input literal、default、nullのcoercionも単一値のまま行う。

2秒測定:

| workload | nativeとの差 |
|---|---:|
| 1 field、1 dynamic argument | +3% |
| 10 fields、1 dynamic argument | +18〜19% |
| 25 fields、1 dynamic argument | +25% |
| 1〜25 fields、1 static argument | 0〜+2% |

static argumentでは既存native ABIもcached HashRefを共有するため差は小さい。一方、
dynamic queryではfieldごとのHashRef allocationとHash lookupが消え、同じvariableを
複数fieldが使うほど改善が大きくなる。

### 14.8 ゼロ引数 object accessor

blessed source objectの単純なaccessor向けに、fieldへ
`accessor => 'method_name'`を宣言できるようにした。通常のdefault method resolverは
graphql-perl互換のため`($args, $context, $info)`をmethodへ渡すが、accessor契約は
ゼロ引数methodとしてsource objectだけをinvocantにして呼ぶ。args HashRef、lazy info、
別resolver coderefを生成しない。GraphQL field名とmethod名が異なるrenameにも使える。

2秒測定:

| object field数 | default method比 |
|---:|---:|
| 1 | +10% |
| 10 | +48% |
| 25 | +65% |

object fieldごとにgeneric args/info準備を省けるため、幅が広いほど効果が大きい。
GraphQL argumentsを宣言するfield、context/infoを必要とするmethod、DataLoaderや権限判定を
行うfieldは通常resolverを使う。`accessor`と`resolve`の同時指定はschema compile時に
拒否する。

accessor導入後にもfieldごとの`gv_fetchmethod_autoload`が残っていたため、runtime slotへ
直前のsource stashとmethod GVを1件cacheした。stashが変わるsubclass切替と
`PL_sub_generation`の変更時はmethod resolutionをやり直す。CVそのものではなくGVを
保持することで、同一GV上のmethod再定義も次回callで新しいCVへ追従する。

accessor単体のthroughputは、1 fieldで約1%、10 fieldsで約5%、25 fieldsで約8%
追加改善した。subclass切替と実行中のmethod再定義を回帰テストに含めた。

### 14.9 DataLoader resolver境界

DataLoaderの1 batch requestをloader単体とGraphQL実行全体に分けて測定した。
`dispatch`時のqueue全体`splice`除去、default identity `cache_key` callback除去、
`on_stall_for`の最終empty dispatch round省略をそれぞれ試したが、いずれも改善せず
約1〜2%低下したためrevertした。deferred Promise生成とsettleが支配的で、Perl配列や
小callbackの削減は全体throughputへ反映されない。

一方、GraphQL argumentsを持たないDataLoader resolverをgeneric ABIから
`fast_resolve_no_args`へ変更すると、1 keyで約4%、10 keysで約7%、25 keysで約6%
改善した。list itemごとのargs HashRefとlazy info生成を省けるためである。

pre-resolved Promise workloadでもasync SV laneはsync SV laneの約56%のthroughputだった。
Promise::XSはsettled valueを公開APIから同期取得できないため、executorはpre-resolved
Promiseにも`then` callback、pending entry、scheduler処理を必要とする。これ以上の大幅な
改善にはPromise::XSとの専用連携、またはDataLoaderがexecutorへnative pending handleを
返す内部契約が必要であり、小さなruntime変更とは別のアーキテクチャ課題になる。

### 14.10 DataLoader専用ticketの試作と不採用

通常のWebアプリで多い「variables付きquery + DataLoader + `on_stall`」を次の対象とした。
Houtouの`on_stall`経路はevent loopを駆動する一般的な非同期I/Oではなく、resolverが
返したpending値を記録し、DataLoaderをbatch dispatchしてから同期的に実行を再開する。
このため、DataLoader経路では汎用Promiseを専用pending ticketへ置き換えられるという
仮説を立てた。

最初に、20件のobject list（各3 fields）を同一queryとvariablesで実行し、sync値、
root resolverがpre-resolved Promiseを1個返す場合、list itemごとにpre-resolved
Promiseを返す場合を比較した。

| workload | throughput | sync比 |
|---|---:|---:|
| sync SV | 106,190 req/s | 100% |
| root Promise | 59,582 req/s | 56% |
| 20 item Promises | 27,927 req/s | 26% |

Promise数に応じて差が拡大するため、当初はdeferred/Promise生成と`then`連鎖が最大要因と
考えた。そこで`perf/dataloader-pending-tickets` branchで、DataLoaderの`load()`が
Promise::XSではなく専用ticketを返し、executorがticketをpending値として認識する試作を
行った。cache、prime、load_many、per-key reject、object/list completion、公開`then()`
互換まで接続し、DataLoaderとPromise fallbackのfocused testを通した。

Perl HashRefとclosureで実装した最初のticketは、10 keysのGraphQL実行でmainより約10%
遅かった。Promise::XSがC実装であるのに対し、ticketの生成・subscribe・settleをPerlで
再実装したことが原因だった。次にticketの生成とsettleをXSへ移し、executorから
subscribeする際のPerl method callも省いた。

同じ`util/dataloader-benchmark.pl`をmainと試作branchで比較した結果:

| workload | main Promise::XS | XS ticket | 差 |
|---|---:|---:|---:|
| loader単体、10 keys | 121,963 req/s | 139,634 req/s | +14.5% |
| GraphQL、1 key、fast resolver | 127,296 req/s | 121,963 req/s | -4.2% |
| GraphQL、10 keys、fast resolver | 30,072 req/s | 30,629 req/s | +1.9% |
| GraphQL、25 keys、fast resolver | 13,273 req/s | 13,389 req/s | +0.9% |

ticketはloader単体ではdeferred/Promise生成を減らしたが、GraphQL実行全体では改善が
約1〜2%に縮み、1 keyでは逆に低下した。したがってsync/async差を支配しているのは
Promise object生成そのものではなく、Houtou側のfieldごとのpending entry、resolve/reject
callback、path/outcome保持、ready判定、scheduler enqueue/drain、completion再開である。

一方、ticketを正式採用すると次の契約をPromise::XSと二重に保守する必要がある。

- resolve/reject、複数subscriber、callback例外、chain flattening
- cache、prime、load_manyとper-key error
- object/list/abstract completionとNon-Null伝播
- request cancellation、未解決ticket破棄、XS handleの所有権
- Promise resolverとticket resolverが混在する場合のscheduler semantics

GraphQL全体で約1〜2%という効果では、このメンテナンスコストとリーク・意味論差異の
リスクに見合わない。ticket試作はcommitせず全変更を破棄し、Promise::XSを単一のpending
契約として維持することにした。

次の改善対象はPromise APIの置換ではなくasync scheduler内部とする。具体的には、
DataLoader dispatch中はsettled entryへ値だけを書き込み、Promiseごとにschedulerを
再入させず、dispatch終了後にready frameを一括enqueue/drainする。さらに同一blockの
completionをまとめ、Promiseが返るまでの同期区間をsync fast lane相当にfuseできるかを
別branchで検証する。

### 14.11 scheduler一括drainとsettled Promise取得の検証

DataLoaderの`on_stall`実行中はschedulerのdrainを抑止し、dispatch完了後にready frameを
一括drainする試作を行った。nested loader、error、deadlock、frame leakのfocused testは
通過したが、1/10/25 keysのthroughputはいずれもmainと同等か僅かに低下した。

既存実装は各Promise callbackでentryへ値を書き込むものの、frameの
`pending_unresolved`が0になる最後のsettleまでready queueへ積まず、drain中の再入も
`async_scheduler_draining`で抑止している。したがって「DataLoaderがN promisesをresolve
するとschedulerがN回再入する」という仮説は誤りだった。外側からbatch区間を通知する
APIだけが増え、実行回数を減らさないため試作をrevertした。

Promise::XSのstashにはFuture::AsyncAwait互換名の`AWAIT_IS_READY`と`AWAIT_GET`も見える。
pre-resolved Promiseを同期取得できればpending machineryを省略できると考えたが、
インストール済みPromise::XSでこれらをPromise objectへ直接呼ぶとプロセスがsegfaultした。
Promise::XS::Promiseの文書にも同期取得APIとして記載されておらず、Houtouから利用できる
安全な公開契約ではない。

25 keys DataLoader実行をmacOS `sample`で5秒計測すると、Promise::XS deferred生成そのもの
より、次が上位に現れた。

- `Perl_call_sv`によるresolverおよびpending callback境界
- `gql_runtime_vm_exec_state_execute_current_op_async_sv`
- recursiveな`gql_runtime_vm_exec_state_execute_block_async_path_sv`
- `gql_runtime_vm_async_scheduler_process_frame`
- native valueのmaterialize/destroy/store
- pending callback、frame arm/finalize、leaf serialization

root Promise解決後のobject listでは大半のchild fieldsが同期値なのに、すべてasyncの
frame/outcome/completion経路を通る。Promise生成やdrain回数の局所最適化ではなく、
Promiseが現れないblockまたはblock内の同期区間をfused executionへ載せることが、残る
sync/async差に対する次の主要候補である。

### 14.12 XS await ticketの再検証

Promise::XSの非公開`AWAIT_*`を呼ぶのではなく、Houtou所有のDataLoader ticketに安全な
`AWAIT_IS_READY`と`AWAIT_GET`をXS APIとして実装した。ticketはpending、fulfilled、
rejectedの3状態を持ち、複数subscriberへの通知、callback例外のrejection化、callbackが
返したticketのflatten、公開`then()`からPromise::XSへの互換bridgeを提供する。

最初の版ではticketの生成とsettleだけをXS化し、派生ticketと継続合成をPerlの
`_subscribe`に残した。この版はmainに対してunique keysで約18%、同一pending keyの共有で
約23%遅かった。Promise生成を省いても、fieldごとにPerl method、`eval`、派生ticket、
返り値判定、resolve/reject再配送を追加したためである。

継続合成をXSへ移し、executorのpending entryをarmする共通経路では派生ticketを作らず、
既存のresolve/reject callbackをticketへ直接登録した。10 fieldsのGraphQL実行をmainの
Promise::XS版と比較した結果:

| workload | main Promise::XS | XS ticket | 差 |
|---|---:|---:|---:|
| unique pending keys、fast resolver | 29,094 req/s | 31,150 req/s | +7.1% |
| repeated pending key、fast resolver | 34,673 req/s | 35,725 req/s | +3.0% |
| primed keys、fast resolver | 32,504 req/s | 63,140 req/s | +94.2% |
| loader単体、10 unique keys | 121,963 req/s | 143,712 req/s | +17.8% |

ready ticketはresolver直後に値またはerrorへ展開され、pending entry、callback、schedulerを
作らない。pending ticketもPromise::XSの汎用chainを経由せず、executor callbackへ直接
通知する。これによりpending workloadの退行を解消しつつ、cache hitとprimeで大きな改善を
得た。Promise::XSは一般resolverが返すPromiseとticketの公開`then()`互換bridgeとして残す。

### 14.13 今後のasync高速化候補

Promise::XSの非公開`AWAIT_*`を同期取得APIとして利用する案は、安全な契約ではなく実測でも
成立しなかった。以降はHoutouが所有するTicketとasync scheduler内部を主な対象とし、外部
resolverが返す本当にpendingなPromiseだけをPromise::XS経路へ残す。

優先順位は次の通り。

1. **Ticket settlementとfield completionの直結**
   Ticket subscriberにblock、op、slot、result path、親frameのpending entryを持たせ、
   settle時にschedulerの汎用再開処理を経ずcompletionを実行する。DataLoaderが返すplain
   hash objectでは、settleからnative object格納までを一続きにできる可能性がある。
2. **Ticket subscriberとpending entryの一体化**
   fieldごとに生成するresolve/reject CV、callback context、subscriber pairを専用C structへ
   まとめる。Ticketからpending entryを直接更新し、Perl callback境界と小オブジェクト生成を
   削減する。
3. **Ticket本体のC struct化**
   現在のblessed AVが持つstate、value、subscriber配列を専用C structへ移す。`av_fetch`と
   callback pair用AV/RVを減らせる一方、request cancellation、循環参照、未解決Ticket破棄の
   ownership監査が必要なため独立した変更として扱う。
4. **DataLoader queue/cacheのnative化**
   `load`時のcache lookup、`[key, ticket]`生成、queue push、dispatch時の`splice`と`map`を
   native loader handleへ移す。loader単体への効果は大きい可能性があるが、GraphQL全体では
   batch関数とresolverの比率も併せて測る。
5. **batch単位のscheduler連携**
   Ticket batchのsettlement中は値とready stateだけを更新し、batch末尾で一度だけschedulerへ
   通知する。ただし既存schedulerは最後のpendingが解決するまでframeをenqueueせず、drain再入も
   抑止済みである。単純な一括drain通知は過去に効果がなかったため、subscriber/pending entryの
   一体化と組み合わせてcallback生成や走査自体を削減できる場合にのみ再検証する。
6. **native valueへの直接settlement**
   実行planとselectionが確定しているexecutor内部subscriberに限り、plain hashをPerlの
   completion中間表現へ戻さずnative objectへ変換する。汎用Ticket APIには型やselectionを
   持ち込まず、executor固有の最適化として隔離する。

小さい変更から進める場合は、batch settlementのPerl/XS反復境界を減らした後、
Ticket subscriberからpending entryを直接更新する構造を試す。その実測を基にTicket本体や
DataLoader全体のnative化へ進むか判断する。

### 14.14 pending直結とDataLoader load missの検証

Ticket subscriberからexecutorのpending entryを直接更新し、fieldごとのresolve/reject CVを
省く試作を行った。20 unique keysではGraphQL実行が約3%改善した一方、repeated/primedでは
最大約4%退行し、subscriberのreentrancy対応とownership管理も大幅に増えた。汎用callback
経路を置き換えるだけでは採用基準に届かないため、この試作は破棄した。

次にDataLoaderのcache miss時に行うTicket生成、`[key, ticket]`生成、queue push、cache storeを
一つのXS呼び出しへまとめた。cache hit判定はPerlに残し、既定のidentity `cache_key` callbackも
省略した。20 keysの測定では、`cache => 0`のloader単体が約25%、GraphQL実行が約5--7%改善した。
通常のcache有効・全key missではloader単体が約4%、GraphQL実行が約3%改善し、repeated hitは
概ね同等だった。DataLoader全体をC handle化せず、hotなmiss処理だけを移す小さい変更でも効果が
得られるため、dispatchのnative化は別の変更として評価する。

### 14.15 DataLoader dispatch制御のXS統合

DataLoaderの公開APIとPerl hash構造を維持したまま、`dispatch`内のqueue chunk抽出、key配列生成、
batch callbackの例外捕捉、戻り値検証、Ticket settlementを一つのXS呼び出しへまとめた。
batch callback自体と、callback実行中に次のloadを新しいqueueへ積むstall契約はPerl側のまま
維持している。

20 keysのmain比較ではloader単体がaccess patternにより約4--9%、GraphQL実行が約1--3%
改善した。100 unique keysではloader単体が約5%、GraphQL実行は同等から約1%改善だった。
幅が増えるほどGraphQL executor自体の比率が高くなるため全体効果は薄まるが、例外、per-key
error、`max_batch_size` chunkingを含む既存契約を変えず、すべてのdispatchで通るPerl/XS境界と
一時配列操作を削減できる。

### 14.16 sync-first root-leaf継続へのDataLoader Ticket統合

GraphQL::HoutouはPSGI前提の同期Webアプリであり、Promise::XSとDataLoader Ticketは
実行時間の重畳ではなくDataLoaderバッチ解決のためだけに存在する。したがって
`docs/sync-first-execution-design-ja.md`で進めているroot-leaf継続の次段階は、汎用
Promise::XSサポートより実際の主要トリガーであるDataLoader Ticketを先に統合する方が
優先度が高いと判断した。

`gql_runtime_vm_fast_lane_guard_promise_sv`にDataLoader Ticket認識を追加した。
resolverの戻り値がTicketで、かつ既にfulfilled/rejected状態(`_dispatch_queue`の
バッチ処理やcache hitで既に決着している場合)であれば、suspension channelへ触れずに
その場で値/errorへ展開する。genuinely pending(state 0)のTicketのみ、従来の
Promise::XSと同じsuspend-or-croak経路に合流する。

genuinely pendingなTicketについては、`gql_runtime_vm_try_execute_fast_root_continuation_sv`
から`gql_runtime_vm_call_then_promise_xs_sv`(Perlメソッド`then`経由)ではなく、
`arm_frame`が既に使っている`gql_runtime_vm_subscribe_dataloader_ticket`をTicketへ
直接呼ぶようにした。Promise::XSの`_settle_result`契約(`isa('Promise::XS::Promise')`
判定)を壊さないよう、この分岐でのみ`Promise::XS::deferred()`を合成し、settle
callbackがそれを`resolve`する側効果を持つ(callbackがG_VOID|G_DISCARD呼び出しに
なるTicket subscriberから呼ばれた場合、戻り値そのものは読まれないため)。

続けて、design docの §13 が次段階として明記していたresolve/reject継続ctxの統合を
行った。従来はsuspendのたびに`gql_runtime_vm_fast_root_continuation_ctx_t`を
resolve用・reject用に個別に2回確保していた(それぞれ6個の`newSVsv`を含む)。
`gql_runtime_vm_pending_callback_ctx_t`が既に使っている`cv_refcnt`パターンを移植し、
1回の`Newxz` + 6回の`newSVsv`で済むようにした。resolve/rejectの2つのXSUBは、ctxに
フラグを持たせず、どちらのXSエントリポイント(`..._resolve_callback`/
`..._reject_callback`)でCVが作られたかで区別する。

回帰テストは`t/39_fast_lane_promise_fallback.t`に、単一のnullable root leaf field
がfulfilled Ticket・pending Ticket(on_stall経由)・rejected Ticketをそれぞれ返す
3ケースと、strict syncレーンでpending Ticketが引き続きactionableなcroakになることを
追加した。`t/54_frame_leak_regression.t`には、200回のpending Ticket駆動root-leaf
継続を連続実行してもblock/path frameがリークしないことを確認するstress testを
追加した。全489 testが成功している。

`util/execution-benchmark.pl`の`benchmark_async_preresolved_leaf`にTicket-ready
(loaderを外側で一度だけprimeし、resolverはcache hitのみ行う)とTicket-pending
(on_stall経由)の2バリアントを追加した。5標本中央値:

| ワークロード | throughput | sync比 |
|---|---:|---:|
| sync leaf | 412,967 req/s | 100% |
| async leaf (Promise::XS pre-resolved、既存) | 277,737 req/s | 67.3% |
| async leaf (Ticket ready、新規) | 321,551 req/s | 77.9% |
| async leaf (Ticket pending、on_stall経由、新規) | 139,515 req/s | 33.8% |

Ticket readyはPromise::XS pre-resolvedに対して約+15.8%改善した。これは
Promise::XSの`then()`が既に決着したpromiseに対しても呼び出しごとにderived promise
objectを生成するのに対し、fulfilled Ticketの認識はsuspension channelにもderived
objectにも触れず値を直接返すためである。Ticket pendingは新しい計測対象であり、
before値は存在しない(旧来この形状のroot leafは全て汎用async executorを通っていた)。
on_stallの駆動ループ自体(Perl側`_settle_result`のwhileループ)のコストが支配的で
あるため、sync比は約34%に留まる。

`util/dataloader-benchmark.pl --scenario execution`(root がobject listで今回の
root-leaf継続の対象外)をPhase 1適用前後でstash比較したところ、unique/primed/repeated
のいずれも数%以内の揺らぎに収まり、全resolver呼び出し箇所に追加したTicket判定
(`gql_runtime_vm_sv_is_dataloader_ticket`、stashポインタ比較のみ)による広範な
退行は見られなかった。

次段階は、design docの§13 step 6が指摘する「Promise callback内で再帰的に完了処理を
行う現在のresume方式をready queueへの統合に置き換える」作業であり、これは複数
sibling pending fieldへ対象を広げる前の前提条件として扱う(`_dispatch_queue`が
1つのCループでbatch内の複数Ticketを続けてsettleするため、現在の直接再帰方式は
sibling数に比例したC stack再帰になり得る)。

### 14.17 resume経路のscheduler統合を試作し、性能退行のため延期(Phase 2)

design doc §13 step 6の実施として、settle callback(`gql_runtime_vm_fast_root_continuation_settle_sv`)
がresponseを直接組み立てる代わりに、既存の汎用async executorが使っている
`gql_runtime_vm_block_frame_t` + scheduler(`enqueue_frame`/`drain`/`process_frame`/
`resolve_frame`)へ委譲する試作を行った。settleごとに最小限の`exec_state_handle_t`
(`native_program`と`writer`のみ実質的に使う、他フィールドはゼロのまま既存の
`ExecState::DESTROY`がNULL安全に解放する)と1エントリの`block_frame_t`を確保し、
完了済みの値を`GQL_VM_PENDING_PROMISE_SV`としてpushしてdrainに委ねることで、
汎用実行レーンと完全に同じ完了経路(response envelope組み立てを含む)を通した。

`util/execution-benchmark.pl`の同一シナリオを共有する300件の独立したrootリーフ継続を
1回の`DataLoader->dispatch`で一括settleするstress test(新規、恒久化はしていない)で
正しさを確認し、ASan(hash seed 1/5/12)でもクリーンだった。

性能面では、Ticket readyケース(suspendせず即決着するため元々settle_svを一切通らない)は
無変化だったが、settle_svを実際に通るケースで実測の退行が出た。5標本中央値:

| ワークロード | Phase 1 (直接構築) | Phase 2試作 (scheduler経由) | 差 |
|---|---:|---:|---:|
| async leaf (Promise::XS pre-resolved) | 277,737 req/s | 258,195 req/s | -7.0% |
| async leaf (Ticket pending, on_stall経由) | 139,515 req/s | 135,886 req/s | -2.6% |
| async leaf (Ticket ready) | 321,551 req/s | 326,123 req/s | ±0(settle_svを通らない) |

settleのたびに`exec_state_handle_t`・heap writer・block_frameを確保し、さらに
Perl SV → native_value_t → Perl SVの往復変換を経由するコストが、直接
`hv_store`+`gql_runtime_vm_fast_response_sv`で組み立てる場合に対して測定可能な
オーバーヘッドとして現れた。

この試作の副産物として、`gql_runtime_vm_native_value_t`のscalar表現に
UTF8フラグを保持するフィールドがなく、resolverが返したUnicode文字列がこの
往復変換を経由すると(promise/ticket経由のフィールド全般、rootリーフに限らず)
UTF8フラグが失われるという、既存の汎用async executorに元々存在していた
バグを発見した(`gql_runtime_vm_native_value_t.scalar_pv_is_utf8`を追加し、
constructor/destroy/materialize/cloneの4箇所で一貫して扱うよう修正)。これは
Phase 2の成否とは独立に価値のある修正であり、Phase 2自体は延期したが
このUTF8修正は採用した。

性能退行が「正しさの検証が目的」というPhase 2自身の位置づけに対して無視できない
規模だったため、ユーザーの判断でPhase 2を単独採用せず、Phase 3(複数sibling
pending fieldへの拡張)を実装する段階まで延期することにした。単一fieldの場合は
Phase 1の軽量な直接構築方式を維持し、block_frame_t/scheduler経由のresumeは
実際に複数sibling を扱う必要が生じた時点で導入する。settle_svの実装は
Phase 1cの状態(直接`hv_store`+`gql_runtime_vm_fast_response_sv`)へ戻した。

### 14.18 複数sibling root fieldへの拡張(Phase 3)

design docの§13 step 3/5、および§7の段階移行計画に沿って、rootの selection set が
「nullableなscalar/enum leafが複数個」の場合に対応する fast root continuation の
拡張を実装した(`perf/sync-first-continuation`ブランチ)。

**eligibility guardの緩和**: `block->op_count != 1`の弾きを`op_count >= 1`へ緩和し、
ブロック内の**全op**が既存の単一条件(GENERIC completion、runtime directiveなし、
nullable、child blockなし)を満たすことを要求する。1つでも満たさないopがあれば
block全体を旧executorへfallbackする。

**重要な発見: bundle上のop_indexはnative_program(生の未剪定プログラム)上の
op_indexと常に一致するとは限らない。** `gql_runtime_vm_prepare_cached_bundle_in_place`
は、静的に評価可能な`@skip`/`@include`directive(`has_directives &&
directives_mode_code == GQL_VM_ARGS_STATIC`)を持つopについて、条件がfalseなら
そのopをbundleの`ops[]`配列から削除する。これにより、削除されたopより後ろにある
opは(それ自身がdirectiveを一切持たなくても)bundle上でインデックスがズレる。
fast laneはbundle上のopを列挙する一方、`gql_runtime_vm_exec_state_complete_async_sv`
は`s->native_program->blocks[block_index]->ops[op_index]`という生のprogramを
直接インデックスするため、この2つの空間が食い違うと誤ったopを参照しうる。対策として
eligibility guardに「このblockで`bundle_block->op_count ==
native_program->blocks[block_index].op_count`である」というblock単位のチェックを
追加した(削除は常にop_countを減らす方向にしか働かないため、この一致は「1つも
削除されていない」ことの十分条件になる)。

なお実験的に検証したところ、今回のeligibility(全op が GENERIC completion 限定)の
下では、`gql_runtime_vm_exec_state_complete_async_sv`は実際には`slot`を
`entry->slot_index`という独立したパラメータ経由で参照しており(`op->slot_index`
経由ではない)、かつ完了処理自体は`slot`の返り値型情報のみに依存するため、この
チェックを外してもテストケースでは可視の破損は再現しなかった(候補となる全opが
同じcomplete_code=GENERICを共有するため)。ただし、これは今回の限定的な
eligibilityがたまたま`op`自身のフィールドに依存しないために表面化しないだけで、
将来complete_codeの制限を緩めるような拡張が`op`の内容に依存するようになった場合に
静かな破損を生みかねないため、コストがほぼゼロの防御的チェックとして維持した。

**既存の汎用scheduler機構をそのまま再利用**: suspendしたopは
`gql_runtime_vm_slot_leaf_kind(...)`が`GQL_VM_LEAF_NONE`(組み込みでないcustom
scalar)かどうかで`GQL_VM_PENDING_PROMISE_GENERIC_VALUE_SV`または
`GQL_VM_PENDING_PROMISE_RESOLVED_VALUE_SV`を選び(`gql_runtime_vm_then_complete_current_sv`
の判定をそのまま踏襲)、`gql_runtime_vm_block_frame_push_pending_pvn_with_meta`で
push する。最初のsuspend時にのみ遅延的に`block_frame_t`と実`exec_state_handle_t`
(実entry pointが使うのと同じ構成: `gql_runtime_vm_new_cursor_struct_for_program`
+ `gql_runtime_vm_new_writer_struct` + `gql_runtime_vm_new_exec_state_handle_sv`)を
確保し、ループを継続する。ループ終了後、`data_hv`に溜まった同期解決済みsiblingを
`gql_runtime_vm_native_value_from_sv`で一括変換して`frame->values_value`へ差し込み、
`gql_runtime_vm_block_frame_finalize_sv`(汎用async executor自身のroot frame
finalizeが使っているのと同じ関数)へ委譲する。専用のctx/callback型は新設していない。

**reentrancy上の重要な発見**: `gql_runtime_vm_block_frame_finalize_sv`は、arm前に
`exec_state->async_scheduler_draining = 1`を立ててから`arm_frame`を呼び、arm後に
元へ戻す、という既存のidiomを使っている。これは、arm中にsiblingの1つが
(Promise::XSの`then()`が同期的にcallbackを呼ぶ場合のように)同期的にsettleし、
その結果`pending_unresolved`が0になった際、settleコールバック自身が
`enqueue_frame`+`drain`を呼んで`process_frame`を再入的に実行してしまうと、
`arm_frame`のループが**まだ回っている最中に**`frame->pending_entries`配列が
`process_frame`によって作り直され(古い配列は`Safefree`される)、`arm_frame`が
保持している古いエントリへのポインタがダングリングになる、という重大な
reentrancy事故を防ぐためのものである。もしこのidiomを踏襲せず`arm_frame`を
裸で呼んでいたら、複数siblingが同一バッチで同期settleするケース(Case B:
pre-resolved Promise::XSとpending Ticketの混在)で発生しうる、検出困難な
use-after-free になっていた可能性が高い。既存の汎用executorがすでにこの問題を
解決済みだったため、車輪の再発明を避けてそのまま再利用した。

**検証**: 正しさは以下のシナリオで手動・自動双方で確認した — 複数siblingが同一
DataLoaderバッチでpending → 一括settle、rejectしたsiblingが他の健全なsiblingを
巻き込まないこと、pre-resolved Promise::XSとpending Ticketの混在(arm中の同期
settleを経由する経路)、50件の独立したrequestが1回のbatch dispatchで settle、
non-null/runtime directive/静的prune各条件でのfallback。全492テスト、49ファイル
個別実行でのASan(複数hash seed)がクリーン。全同期の場合(async runtimeでも
全fieldが同期解決)はsync runtimeと完全に同速(実測差ゼロ)であり、「全同期なら
一切課税しない」というsync-first原則は維持されている。

**性能**: `benchmark_async_multi_leaf`(width 2/5/10、末尾1個がDataLoader
Ticket pending)で、Phase 3導入前(常に旧executorへfallback)と導入後を
git stash比較したところ、**測定可能な改善は見られなかった**(width 2:
122.5k→124.3k req/s、width 5: 100.0k→100.0k req/s、width 10: 78.2k→75.2k req/s、
いずれも誤差範囲)。分析の結果、新経路は「suspendしていないsiblingをfast lane
で安く解決する」利点がある一方、promotion時に`data_hv`全体を
`gql_runtime_vm_native_value_from_sv`で一括変換するコストが新たに発生し、
両者がほぼ相殺していると考えられる。exec_state_handle_t/writer/frame/arm/drainの
固定コストは旧経路と共通(`gql_runtime_vm_block_frame_finalize_sv`を再利用して
いるため)であり、これが支配的である可能性が高い。

Phase 2の「退行」とは異なり「退行はないが改善もない」結果だったが、ユーザーの
判断で正しさ・将来の最適化の土台としての価値を優先し、そのまま採用することにした。
次に性能改善を狙うなら、`data_hv`を経由したPerl SVの一括変換を避け、fast lane
ループ中に解決済みsiblingを直接`native_value_t`へ書き込む設計へ作り直す必要が
ある(promotionが起きるまでは何も確保しないというsync-first原則を保ったまま、
promotion後のperl SV往復自体をなくす設計が要る)。

### 14.19 data_hv往復の除去(§14.18の宿題を実施)

§14.18末尾で指摘した最適化を実装した。`gql_runtime_vm_execute_root_block_fast_multi_sv`
の返り値を`SV *`(RVラップされた`data_hv`)から`void`へ変更し、呼び出し側が
`Newxz`した`block->op_count`要素の`SV **resolved_values`配列へ、op位置をindexとして
解決済みの値を直接書き込む方式にした(suspendしたop・`should_execute_current_op_fast`
でskipされたopはNULLのまま)。data_hvの構築は呼び出し側(`gql_runtime_vm_try_execute_fast_root_continuation_sv`)
がこの配列を見て初めて行う:

- `frame == NULL`(全同期): `resolved_values[]`から`data_hv`を構築し、従来通り
  `gql_runtime_vm_fast_response_sv`へ渡す。1 hv_store/fieldという回数は変わらず、
  単に「ループ中に都度」から「ループ後に一括」へタイミングが変わっただけなので、
  全同期ケースのコストは変化しない(sync-first原則を維持)。
- `frame != NULL`(1つ以上promotion): `data_hv`を一切経由せず、`resolved_values[]`
  から直接`gql_runtime_vm_native_object_store(frame->values_value, slot->result_name,
  /*borrowed=*/1, gql_runtime_vm_new_native_value_scalar(...))`を呼ぶ。

従来の`gql_runtime_vm_native_value_from_sv(data_rv)`(HVの汎用変換)は、
`hv_iterinit`/`hv_iternext`によるtraversalに加えて、`gql_runtime_vm_native_object_store`
呼び出し時に`name_borrowed=0`を渡すため**フィールド名を再度savepvでコピーしていた**
(元々`hv_store`で1回コピー済みの名前を、変換時にもう1回コピーする二重コピーになって
いた)。今回の変更では、fast lane側がすでに知っている`slot->result_name`(plan所有の
borrowed文字列)をそのまま`borrowed=1`で渡すため、このコピーが完全になくなる。

5標本中央値(`benchmark_async_multi_leaf`、旧来のfallback、すなわちPhase 3導入前の
基準との比較):

| width | 旧executor(fallback) | Phase 3(§14.18時点) | 今回(data_hv除去後) |
|---|---:|---:|---:|
| 2 | 122,528 req/s (100%) | 124,254 req/s (101.4%) | 121,963 req/s (99.5%) |
| 5 | 100,014 req/s (100%) | 100,019 req/s (100.0%) | 102,128 req/s (102.1%) |
| 10 | 78,196 req/s (100%) | 75,156 req/s (95.9%) | 79,481 req/s (101.6%) |

width 5・10では旧fallbackに対して初めて明確な(誤差を超えた)改善が確認できた。
widthが大きいほど改善幅が伸びる(width 2はほぼ横ばい、10で+1.6pt)のは、削減した
コストがフィールド数に比例するfixed costだからで、想定通りの傾向である。width 2では
`Newxz`/`Safefree`した配列自体の確保コストが、削減できたコピー1回分の利益とほぼ
相殺していると見られる。

正しさは既存の全492テストに加え、unicode文字列siblingがUTF8フラグを保持したまま
この新しい直接経路を通ることを確認する手動検証、500回のpromotionあり実行+500回の
全同期実行を混ぜたリーク検証、49ファイル個別実行でのASan(複数hash seed)で
確認した。

### 14.20 root plain-leaf list fieldへの拡張(Phase 4)

§11で挙げた境界(「listはchild blockを持たなくても各itemがPromiseの場合がある」)へ
対応した。対象は`op->complete_code == GQL_VM_COMPLETE_LIST`かつ`child_block_index < 0`
かつ`abstract_child_count == 0`の、object/abstract要素を持たないplain leaf list
(`[String]`, `[Int!]`等)のみ。eligibility guardの他の条件(directive無し、
nullable、bundle/native_program op_count一致)は既存のまま流用した。

**item-level pendingの検出とfield-level pendingの分離不可能性。** §11で記録した
とおり、resolverが返したlist全体をitem単位で検査するまでは、item内にpromise/Ticket
が混じっているか分からない。かつ一度resolverを呼んだ後は「この形状は未対応」と
判明しても旧async executorへやり直すことはできない(exactly-once保証を破る)。
したがって、item-level pendingの対応をfield-level pendingの対応と同時に実装する
必要があった。

**実装。** `gql_runtime_vm_complete_current_list_fast_sv`の先頭(itemループの前)に
`state->fast_lane_can_suspend`時のみ動くpre-scanを追加した。array中の各itemを見て、
Promise::XSまたはgenuinely pendingなDataLoader Ticket(state 0)が1個でもあれば、
生の(未completionの)array参照を新設フィールド`state->fast_lane_list_pending_source_sv`
へ退避し、即座にplaceholderを返す(この時点でitemのleaf coercionは一切行わない)。
1個も無ければ、従来のitemループをそのまま通す。既存のitemループ自体もTicket認識を
追加し(fulfilled/rejectedをPromise::XSと同様に扱う)、strict syncレーンでの
deferred croakが従来の「Promise::XSのみ検出」だった漏れを塞いだ。

呼び出し元`gql_runtime_vm_execute_root_block_fast_multi_sv`のper-opループは、
`fast_lane_suspended_sv`(field-level、既存)に加えて`fast_lane_list_pending_source_sv`
(item-level、新規)も見るようにした。item-level pendingを検出した場合、
Phase 3で「ループ終了後にのみ」構築していた実`exec_state_handle_t`
(`gql_runtime_vm_new_exec_state_handle_sv`+`gql_runtime_vm_new_cursor_struct_for_program`)
を、新設ヘルパ`gql_runtime_vm_ensure_root_fast_multi_promoted_sv`経由でループ**内**の
最初に必要になった瞬間まで前倒しし(field-level/item-levelどちらが先でも1回だけ
構築、以降のiterationは使い回す)、既存の`gql_runtime_vm_exec_state_complete_current_native_async_sv`
のGQL_VM_COMPLETE_LISTケースへ生のarrayをそのまま渡して委譲する。このケースは
既存のtwo-layer機構(Layer 1: `gql_runtime_vm_new_list_item_child_callback_sv`+
`gql_runtime_vm_call_then_promise_for_state_sv`によるitem単位のsettle callback、
Layer 2: `gql_runtime_vm_list_pending_handle_sv`によるitem集約+owner frame通知)を
そのまま使うため、item-level pending専用のロジックを新たに書く必要はなかった。
返ってきたlist_pendingは既存の`gql_runtime_vm_push_pending_list_pending`で
frameのpending entryとして登録する(`GQL_VM_PENDING_LIST_PENDING_PTR`、既存の
scheduler側処理がそのまま扱える)。

呼び出し元の末尾(ループ後、`frame`が非NULLなら実handleを構築していた箇所)も、
ループ内で既にpromotion済みなら`state_sv`を再利用し、二重構築を避けるよう変更した。

単一op(`block->op_count == 1`)の直接構築レーン(Phase 1c/2で確立した、単一
leaf field専用の軽量パス)は、単一opがLIST型の場合は使わず複数op用の共有ループへ
フォールスルーするよう条件を追加した(`op->complete_code == GQL_VM_COMPLETE_GENERIC`
の場合のみ直接構築レーンに入る)。単一list opのitem-level pendingは複数opの場合と
同じ実handle構築が必要で、直接構築レーンにその機構を複製する意味がないため。

**計測。** `benchmark_async_leaf_list`(新規、単一root list field、item全部が
同じDataLoaderバッチでgenuinely pending)を追加し、旧executor(Phase 4導入前、
LISTは常にineligibleでfallback)と比較した。5標本中央値:

| width | 旧executor(fallback) | Phase 4 |
|---|---:|---:|
| 2 | 75,502 req/s (100%) | 73,215 req/s (97.0%) |
| 5 | 47,117 req/s (100%) | 46,072 req/s (97.8%) |
| 10 | 28,976 req/s (100%) | 28,572 req/s (98.6%) |

誤差(実行間で±5〜8%程度のばれ)の範囲内で、明確な改善は確認できなかった
(Phase 3と同じ結末)。理由も同型: item-level pendingが1件でもあれば結局
Phase 4も旧経路もほぼ同じ実`exec_state_handle_t`+two-layer機構を構築するため、
「pendingが起きるケース」では削減できるコストがほとんど無い。

一方、sync-firstの主眼である**全item同期解決のケース**(DataLoader/Promiseを
一切使わないlist resolver)では、async runtimeが従来LISTを問答無用でfallback
していたぶんの差が消えることを確認した(`--case`に含めない手動ベンチマーク、
単一root list field・5要素・全item同期):

| | 旧executor(fallback) | Phase 4 |
|---|---:|---:|
| sync runtime | 160,776 req/s (100%) | 163,063〜165,257 req/s (101〜103%) |
| async runtime | 150,367 req/s (93.5%) | 162,049〜164,622 req/s (100〜102%) |

Phase 4適用前はasync runtimeがsync runtimeに対して-6〜7%の固定費を払っていた
(list opが常にineligibleで実handle経由になるため)。Phase 4適用後はほぼ同速
(sync-first原則どおり、全同期なら実handleを一切構築しない)。pendingが起きる
ケースでの退行は確認できなかった一方、改善もこの「全同期list」ケースに限られる。

**正しさの検証。** §11の回帰と同じ領域のため通常以上に慎重に検証した。
t/39_fast_lane_promise_fallback.tへ6subtestを追加:全item同一batch pending、
sync siblingとlist pendingの共存、field-level pendingとitem-level pendingの
共存、item個別rejectがそのitemのみをnullにすること(§11相当の境界)、
`[String!]`でitem-level non-null違反がlist全体をnullにしlist自身は
nullable field としてnullになること、object list itemが引き続き旧経路へ
fallbackすること。t/54_frame_leak_regression.tへ200回のitem-level list
pending promotionのリークストレスを追加。全494テストが通過し、
`debug_frame_live_counts_xs()`でblock_frame/path_frameとも0を確認した。

**ASan環境問題の原因判明と解消。** 当初、この環境でXS moduleロード自体
(`t/00_compile.t`)がPhase 4の変更と無関係にstash前後どちらのビルドでも
数分規模で完了しない(catastrophically遅い)現象に遭遇した。`sample`で
スタックを採取したところ、`__asan::AsanInitFromRtl()`の初期化中に
`dyld_shared_cache_iterate_text_swift`経由で`_Block_copy`が呼ばれ、
そこから再度mallocへ入り`AsanInitFromRtl()`を再入する形で
`StaticSpinMutex::LockSlow()`上で自己デッドロックしていた
(`/bin/echo`など他の実行ファイルでは踏まない、Perlバイナリ特有の
init順序で顕在化)。原因は`DYLD_INSERT_LIBRARIES`に指定していた
nix store配下の`libclang_rt.asan_osx_dynamic.dylib`(compiler-rt-libc-21.1.8)
が、このmacOSバージョン(26.5.2、dyldの実装)と組み合わせたときに
非互換だったこと。ビルド自体は`cc`(Apple clangバージョン21、
`/usr/bin/cc`、Xcode Command Line Tools由来)で行っていたため、
**同じバージョンのApple clang付属のASanランタイム**
(`/Library/Developer/CommandLineTools/usr/lib/clang/21/lib/darwin/
libclang_rt.asan_osx_dynamic.dylib`)に差し替えたところ、
デッドロックは再現せず、`t/00_compile.t`は0.1秒台で完了した。
コンパイラとASanランタイムのバージョンを揃える(同じツールチェイン由来の
ものを使う)のが要点で、`DYLD_INSERT_LIBRARIES`に無関係なビルドの
ASanランタイムを指定しないこと、というのがこの環境固有の教訓である。

この置き換え後、49ファイル個別実行・`PERL_HASH_SEED`5点(1, 7, 42, 99,
12345)のフルスイープを実施し、全245実行がクリーン(異常終了・ASan報告
なし)であることを確認した。

### 14.21 root object/abstract list fieldへの拡張(Phase 5)

§13 item 4(`benchmark_async_preresolved`が対象とする形、object/abstract
item を持つ root list)へ対応した。対象は Phase 4 と同様「item の child
block(abstract の場合は取りうる全 member block)自体が flat」なものに
限定する: item 自身の各フィールドは `GQL_VM_COMPLETE_GENERIC` または
`GQL_VM_COMPLETE_LIST`(かつそのLISTもplain leaf)のみで、runtime
directive無し、**ただし non-null(`return_type_kind_code == 8`)は許可**
(Phase 4までのroot opでは禁止していたが、item自身のfieldでは後述の
sync-first パターンが正しく処理できることを確認済み)。item の
フィールドがさらに object/abstract を持つ場合(2階層目のネスト)は
今回もスコープ外とし、既存の(exactly-once未対応な)経路へ従来通り
fallbackさせる。

**調査で発見した重大な設計課題(exactly-once違反のリスク)。**
`gql_runtime_vm_complete_current_list_fast_sv`のobject/abstract item
分岐は、各itemを`gql_runtime_vm_execute_block_fast_sv`(child block全般で
共有される「1つでもsuspendしたらブロック全体を破棄してNULLを返す」設計)
へ委譲していた。item のchild blockに複数フィールドがある場合(例:
`{ name, team }`)、`name`がcustom resolverで同期解決した**後**に`team`が
suspendすると、この設計ではブロック全体を破棄してNULLを返す。これを
そのまま汎用executorへfallbackしてやり直すと、既に解決済みだった`name`
のresolverが二重に呼ばれる(exactly-once保証違反)。加えて、
`gql_runtime_vm_complete_current_list_fast_sv`の呼び出し側はこのNULLを
「non-null違反による自己null化」と誤認するバグも同時に発見した
(`state->fast_lane_suspended_sv`を一切チェックしていなかったため)。
Phase 4時点ではeligibility guardが`child_block_index >= 0`を全面的に
弾いていたため、この分岐が`fast_lane_can_suspend == 1`で到達すること
自体がなく、出荷済みコードにこのバグは表面化していなかった。

ユーザーの判断で、正しい形(exactly-onceを完全に守る形)で実装する
ことを選択した。

**設計: child blockにもlazy block-frame promotionを拡張する。** Phase
3/4でroot block用に作った「全opを実行し、どれかがsuspendしたらその時点で
初めて実`block_frame_t`/`exec_state_handle_t`を構築し、既に解決済みの
siblingは保持したまま、suspendしたopだけpending entryとして登録する」
というsync-firstパターン(`gql_runtime_vm_execute_root_block_fast_multi_sv`)
を、root block専用から任意の(non-root)child blockでも使える形へ
一般化した(`gql_runtime_vm_execute_block_fast_multi_sv`、
`parent_path_frame`引数を追加、non-null propagationハンドリングも追加
— root blockでは既存のeligibility guardによりdead codeのまま)。

item自身のchild blockでsuspendが起きた場合、その場で
`gql_runtime_vm_block_frame_finalize_sv(frame, PROMISE_XS, writer,
state_sv, /*return_pending_handle=*/2)`を呼ぶ。このmode 2は既存の汎用
async executorのper-item object分岐(`gql_runtime_vm_exec_state_execute_block_async_path_sv`
の"mode 2"、`deferred_resolves_response`が0のケース)と全く同じ経路で、
`pending_count == 0`ならその場でnative outcomeを、`pending_count > 0`
なら本物の`Promise::XS`を返す。この結果を`gql_runtime_vm_list_pending_handle_sv`
(Layer 2)へそのまま渡せば、Layer 1を新規に書かずに既存のitem集約機構が
そのまま機能する(finalize mode 2が既に「item 1個分のPromise::XS」を
作っているため、Layer 2の既存のpromise検出がそのまま働く)。

state_sv/実handleは、Phase 4で作ったroot専用のヘルパを、request全体で
共有される`state->fast_lane_root_state_sv`フィールド経由の汎用ヘルパ
(`gql_runtime_vm_ensure_fast_lane_state_sv`)へ一般化した。これにより、
root自身のfield-level suspensionと、item内部で深くネストした suspension
のどちらが先に発生しても、同じ1つのhandleを再利用できる。

**実装中に発見・修正した2つのバグ(いずれも既存テストが検出)。**

1. 一般化した`gql_runtime_vm_execute_block_fast_multi_sv`は、
   `gql_runtime_vm_execute_block_fast_sv`が行っている
   `state->block/op/slot/block_index/op_index`の保存・復元を行っていな
   かった(root専用だった頃はroot自身がstateの唯一の所有者だったため
   不要だった)。item自身のchild block処理がこれらを書き換えたまま
   呼び出し元(list opの処理)へ戻るため、呼び出し元が直後に参照する
   `state->slot->item_non_null`等が誤った値になる。t/50_nonnull_propagation.t
   の既存回帰テストが直ちに検出した。`gql_runtime_vm_execute_block_fast_sv`
   と同じsave/restore規律を追加して修正。
2. field-level suspension(`state->fast_lane_suspended_sv`)時の
   payload_kind選択が、参照実装(`gql_runtime_vm_then_complete_current_sv`)
   にある`complete_code == GQL_VM_COMPLETE_GENERIC`チェックを欠いていた
   (Phase 3/4で simplified した際に落とした)。Phase 4までは対象が常に
   plain leaf listだったため`leaf_kind == NONE`が真になることがなく
   偶然正しく動いていたが、Phase 5でobject listが対象になると、
   object list自体がfield-level promiseの場合に誤ったpayload_kind
   (完了処理を素通りする`GENERIC_VALUE_SV`)を選んでしまう。手動検証
   (t/16_runtime_promise.tの既存テストで表面化)で発見し、参照実装通りの
   条件へ修正。
3. さらに、field-level suspension分岐がstate_sv(実handle)を構築せずに
   root呼び出し元の末尾へ委ねる設計だったため、item wrapperがその場で
   `block_frame_finalize_sv`を呼ぼうとするとNULLハンドルを渡すことになる
   バグも見つかった(独自の手動smoke testで発見、既存テストでは未検出)。
   frame構築と同時にstate_svも構築するよう修正(root側のコストは
   変わらない、同じタイミングで両方作るだけ)。

**正しさの検証。** t/39_fast_lane_promise_fallback.tへ6subtest追加:
全item同期(promotionなし)、item内で先に同期解決したsiblingが後続の
suspendで二重呼び出しされないこと(呼び出し回数で確認)、self_nulled
(先にsuspendしたsiblingがある状態でnon-null違反が起きてitem全体がnull
になること)、複数itemが同一batchで同時suspend、abstract(union)item
のmember選択+suspend、item内のネストしたobject fieldが引き続き
fallbackすること(スコープ外の否定テスト)。t/54_frame_leak_regression.t
へ200回のitem child block promotionのリークストレスを追加。全496
テスト、49ファイル個別実行・`PERL_HASH_SEED`5点でのASanがクリーン。

**計測。** `benchmark_async_object_list_item_field`(新規、単一root
object-list field、各itemが1同期field+1 DataLoader-Ticket-pending
fieldを持つ)を追加し、旧executor(Phase 5導入前)と比較した(5標本
中央値):

| width | 旧executor(fallback) | Phase 5 |
|---|---:|---:|
| 2 | 69,433 req/s (100%) | 71,411 req/s (102.8%) |
| 5 | 41,080 req/s (100%) | 42,829 req/s (104.3%) |
| 10 | 25,000 req/s (100%) | 26,064 req/s (104.3%) |

誤差の範囲内で、Phase 3/4と同型の結末(itemが実際にsuspendするケース
では、旧経路も新経路も結局同じ実`exec_state_handle_t`+two-layer機構を
構築するため、削減できるコストがほとんど無い)。一方、DataLoader/Promise
を一切使わない全同期object listのケースでは、Phase 4と同様の改善を
確認した(単一root object-list field・5要素・全item同期、`--case`に
含めない手動ベンチマーク):

| | 旧executor(fallback) | Phase 5 |
|---|---:|---:|
| sync runtime | 138,223〜138,866 req/s (100%) | 138,223〜139,515 req/s (100〜101%) |
| async runtime | 119,037 req/s (85.6〜86%) | 138,866〜141,499 req/s (100〜102%) |

Phase 5適用前はasync runtimeがLISTの`child_block_index >= 0`
unconditional ineligibleにより旧executor経由の固定費(-14〜17%)を
払っていたのが、Phase 5適用後はsync runtimeとほぼ同速になった。

### 14.22 list itemの2階層以上のobject/abstractネストへの拡張(Phase 6)

Phase 5はlist itemの子selection setが「flat」(GENERIC/plain leaf LIST
のみ)であることを要求し、item field がさらに object/abstract を持つ場合
(2階層目のネスト、例: `{ posts { author { name } } }`)はスコープ外だった。
Phase 6はこの制限を外し、任意の深さのネストへ対応した。

**調査で判明した重要な事実(Phase 5より低リスク)。**
object/abstract fieldの子selection set実行に使われていた
`gql_runtime_vm_execute_child_block_fast_sv`は、単にpath_frameの管理を
した上で`gql_runtime_vm_execute_block_fast_sv`(Phase 5がlist item向けに
置き換えた、まさに同じ「1つでもsuspendしたらブロック全体を破棄」関数)
へ委譲しているだけの薄いラッパーだった。返り値の形も同じ契約のため、
Phase 5で作った安全なラッパー(`gql_runtime_vm_execute_list_item_child_block_fast_sv`、
Phase 6で`gql_runtime_vm_execute_safe_child_block_fast_sv`へ改名)を
そのまま使い回せた。また、`gql_runtime_vm_complete_current_object_fast_sv`
/`_abstract_fast_sv`(このラッパーの唯一の呼び出し元)は、Phase 5時点では
`fast_lane_can_suspend == 1`の下で到達不可能(root自身のeligibility guard
とPhase 5のeligibility関数がどちらも`complete_code == OBJECT/ABSTRACT`を
無条件に弾いていたため)だったので、この呼び出し箇所を置き換える変更は
eligibility guardを緩和するまでは副作用ゼロだった。循環スキーマ
(`Character.friends: [Character]`等)による無限再帰の心配も、block が
スキーマの型グラフではなくクエリdocumentのselection setツリーごとに
生成される(循環クエリはvalidationで既に弾かれる)ため杞憂と確認できた。

**実装。**
1. `gql_runtime_vm_execute_list_item_child_block_fast_sv`を
   `gql_runtime_vm_execute_safe_child_block_fast_sv`へ改名し、
   `complete_current_object_fast_sv`/`_abstract_fast_sv`の2箇所の
   呼び出しをこれに置き換え(元の`gql_runtime_vm_execute_child_block_fast_sv`
   は不要になり削除)。
2. `gql_runtime_vm_fast_lane_list_item_block_is_eligible`に`depth`引数を
   追加し、`op->child_block_index`/`op->abstract_child_indexes[]`を
   見つけたら自分自身を再帰呼び出しするよう変更(`GQL_VM_FAST_LANE_MAX_NESTING_DEPTH`
   =16の防御的な再帰深さ上限付き、正しさのためではなくスタック安全の
   ため)。

**実装中に発見・修正した3つのバグ(いずれもテストまたは手動検証で検出)。**

1. 一般化した`gql_runtime_vm_execute_block_fast_multi_sv`のerror_sv処理が
   `state->null_carries_error`を一度もセットしていなかった(参照実装には
   ある)。root blockでは non-null が dead code だったため無害だったが、
   Phase 5/6でitem/object child blockのnon-nullがliveになったことで、
   coercion失敗した非null fieldが「coercionエラー」と「non-null違反」の
   二重エラーを出す形で表面化した。t/50_nonnull_propagation.tの既存テスト
   が直ちに検出。
2. object/abstract field自身の completion(resolverではなく)が
   本物の`Promise::XS`を生成するケース(item内のnested fieldが
   suspendした場合)を、`execute_block_fast_multi_sv`の per-op ループが
   検出する手段がなかった(既存の3チャンネルはどれもこのケースを
   想定していなかった)。手動検証で、settle前の生のPromise::XSオブジェクト
   がそのままレスポンスに漏れる形で発覚。`GENERIC_VALUE_SV`
   (再completion不要、mode 2のfinalizeが既に最終値へmaterialize済み)
   として新しいpending entryを push するよう修正。
3. 上記の修正が`gql_runtime_vm_ensure_fast_lane_state_sv`の呼び出しを
   忘れていたため、`state_sv`がNULLのままfinalizeへ渡り、
   `block_frame_finalize_sv`が実handleを使う正しい経路ではなく
   legacyのno-exec_stateフォールバック経路を静かに通ってしまい、
   item1つにつきblock_frame_tが1つリークするバグを埋め込んだ
   (どのテストも検出せず、`gql_runtime_vm_new_block_frame_struct`/
   `gql_runtime_vm_free_block_frame`/`arm_frame`への一時的なfprintf
   トレースで発見)。

**正しさの検証。** t/39_fast_lane_promise_fallback.tへ6subtest追加:
全同期2階層ネスト、item自身のsiblingが2階層下のnested fieldのsuspendで
二重呼び出しされないこと(呼び出し回数で確認)、3階層ネスト(2階層固定
実装ではなく真の再帰であることの確認)、nested field自身のnon-null違反が
そのfieldのみをnullにしitem levelのsiblingは無傷であること、
abstract(union)がネストの途中に混じるケース、再帰深さ上限を1段超えた
クエリが安全にfallbackすること。t/54_frame_leak_regression.tへ
200回(item1つあたり3 frame: root/item/nested field)のリークストレスを
追加。全498テスト、49ファイル個別実行・`PERL_HASH_SEED`5点でのASanが
クリーン。

**計測。** `benchmark_async_nested_object_list_item_field`(新規)を
追加し、旧executor(Phase 6導入前)と比較した(5標本中央値):

| width | 旧executor(fallback) | Phase 6 |
|---|---:|---:|
| 2 | 60,982 req/s (100%) | 56,627 req/s (92.9%) |
| 5 | 34,553 req/s (100%) | 31,355 req/s (90.7%) |
| 10 | 20,286 req/s (100%) | 18,097 req/s (89.2%) |

Phase 3/4/5と同型の結末で、genuinely pendingなfieldが実際に発生する
ケースでの明確な改善は確認できなかった(誤差を超えたわずかな悪化さえ
見られるが、旧経路も新経路も結局同じ実handle+two-layer機構を構築する
ため大差ないと解釈)。一方、DataLoader/Promiseを一切使わない
全同期2階層ネストのケースでは、Phase 4/5と同様の改善を確認した
(単一root object-list field・5要素・2階層ネスト全同期、`--case`に
含めない手動ベンチマーク):

| | 旧executor(fallback) | Phase 6 |
|---|---:|---:|
| sync runtime | 122,528〜126,118 req/s (100%) | 122,528〜125,431 req/s (100%) |
| async runtime | 97,740 req/s (77.5〜80%) | 123,098〜127,077 req/s (100〜101%) |

Phase 6適用前はasync runtimeが2階層ネストのobject/abstract fieldにより
旧executor経由の固定費(-23%)を払っていたのが、Phase 6適用後はsync
runtimeとほぼ同速になった。

### 14.23 単一(list以外の)root object/abstract fieldへの拡張(Phase 7)

§13 item 5に残っていた最後の未着手項目。`gql_runtime_vm_try_execute_fast_root_continuation_sv`
のroot op eligibility loopは、rootの各opの`complete_code`を
`GQL_VM_COMPLETE_GENERIC`と`GQL_VM_COMPLETE_LIST`のみに制限しており、
`{ user { name } }`のような単一のobject root field(complete_code ==
`GQL_VM_COMPLETE_OBJECT`)やinterface/union root field(`COMPLETE_ABSTRACT`)
は無条件にfallbackしていた。実行側(`gql_runtime_vm_execute_block_fast_multi_sv`)
はPhase 5/6で既にOBJECT/ABSTRACT opを汎用的に扱えるようになっていたため、
eligibility loopの拡張(`GENERIC`/`LIST`に加えて`OBJECT`/`ABSTRACT`を許可し、
子blockを`gql_runtime_vm_fast_lane_list_item_block_is_eligible`で再帰検証)
だけで済むと見込んだ。

**発見1: 2つの真正な、既存コードに潜んでいたバグ。** 単一root object field
が初めてfast lane経由でdeadlock/on_stall放棄シナリオに到達したことで、
以下2つの、Phase 3〜6では到達不可能だったため誰も気づいていなかったバグが
表面化した(いずれも`t/54_frame_leak_regression.t`の既存subtest
`'deadlocked stall releases the pending frames'`の`{ inner { hang } }`
ケースが直ちに検出):

1. `gql_runtime_vm_try_execute_fast_root_continuation_sv`のmulti-op path
   が返す、genuinely pendingなpromiseに、`gql_runtime_vm_attach_response_state_magic`
   が一度も呼ばれていなかった。このmagicはPerl側driverがdeadlocked stall
   時にexec_stateの参照循環を断ち切るために必須(生成側の
   `gql_runtime_vm_execute_native_program_auto_impl_sv`だけが呼んでいた)。
   Phase 3で複数sibling root pathを導入して以来ずっと存在していた欠落で、
   単一root object fieldの`{ inner { hang } }`という組み合わせで初めて
   deadlock経路に到達したことで露呈した。
2. `gql_runtime_vm_cancel_frame_tree`は`GQL_VM_PENDING_BLOCK_FRAME_PTR`
   payloadの子しか辿れず、OBJECT/ABSTRACT fieldの子blockがPromise::XSで
   ラップされて返ってくる(§14.22参照)場合、そのPromise::XSがcancel時に
   子フレームへ辿り着けなかった。応急処置として、bridging promiseに
   子フレームの生ポインタをmagicで付与する仕組み
   (`gql_runtime_vm_attach_child_frame_magic`)を追加したが、後述の
   §14.23の再設計でこの仕組み自体が不要になり削除した。

**発見2: ベンチマークで初の明確な退行。** 修正後、`{ user { name team {
name } } }`(単一root object field、nested fieldがDataLoader pending)の
ベンチマークを実施したところ、Phase 3〜6の「genuinely pendingケースでの
改善なし」という結末とは異なり、**明確な退行(-15〜20%)**が確認された:

| | 旧executor(fallback) | Phase 7(最初の実装) |
|---|---:|---:|
| suspendケース | 104,050〜111,004 req/s (100%) | 83,627〜91,330 req/s (79〜82%) |
| 全同期ケース(async runtime) | 232,411〜235,636 req/s (100%) | 281,040〜286,903 req/s (121〜124%) |

原因を調査した結果、Phase 6の「OBJECT/ABSTRACT fieldの子blockが
suspendしたら必ず新しいPromise::XSを1つ生成して親に返す」設計
(list item集約が「Promise形の値」を要求するため合理的だった)が、
list item集約を必要としない単一fieldの文脈では、1回のsuspendに対し
2階層分のPromise::XS/deferred pairを積み重ねる無駄なオーバーヘッドに
なっていたためと判明した。汎用(旧)executorは、`gql_runtime_vm_then_complete_current_sv`
のコメントが示す通り、ネストしたobject fieldの子blockが持つ子blockが
再度suspendしても、生のフレーム同士を直接連結する`GQL_VM_PENDING_BLOCK_FRAME_PTR`
という既存の軽量機構(`gql_runtime_vm_push_pending_block_frame`/
`gql_runtime_vm_consume_current_result_now`)を使っており、ユーザーの
resolverが返した実際のpromise/Ticket以外には一切新しいPromise::XS
オブジェクトを作らない。

**再設計。** ユーザーの判断で、退行を許容せずPhase 7の中でこの根本原因
まで修正した。`gql_runtime_vm_execute_safe_child_block_fast_sv`に
`want_promise`引数を追加し、`gql_runtime_vm_block_frame_finalize_sv`の
モード選択に反映: list item呼び出し箇所(Layer 2集約が本当に
Promise::XS形の値を必要とする唯一の箇所)は`want_promise=1`
(mode 2、従来通り)のまま、それ以外の全呼び出し箇所(`complete_current_object_fast_sv`
/`_abstract_fast_sv`、深さやroot/nestedを問わない全てのplain object/
abstract field)は`want_promise=0`(mode 1、生のblock-frame handle)に
変更。`execute_block_fast_multi_sv`の該当チャンネルも、Promise::XS検出
から`gql_runtime_vm_is_block_frame_value_sv`検出+`gql_runtime_vm_push_pending_block_frame`
呼び出しへ置き換え、汎用executorの`gql_runtime_vm_consume_current_result_now`
と全く同じ経路を辿らせた。これにより発見1の(2)で追加した
`attach_child_frame_magic`機構は不要になり削除した
(`GQL_VM_PENDING_BLOCK_FRAME_PTR`は`cancel_frame_tree`が既に正しく
辿れるため)。

**実装中に発見・修正したバグ(再設計版)。** 新チャンネルで
`gql_runtime_vm_ensure_fast_lane_state_sv`の呼び出しを「settled
immediately」の条件分岐の中だけに置いてしまい(§14.22のバグ3と全く
同型の失敗)、child_frameが実際にpending(通常ケース)のときは
`*state_sv_out`がNULLのまま返る不具合を埋め込んだ。呼び出し元の
`execute_safe_child_block_fast_sv`がNULLの`state_sv`で`finalize_sv`を
呼ぶと、legacyのno-exec_stateフォールバック経路(本来使うべき実handle
の経路ではない)へ静かに迂回してしまい、2階層ネストの初回リクエストで
即座に`Bizarre copy of ARRAY in subroutine entry`というPerlレベルの
破損エラーで検出された。`gql_runtime_vm_new_block_frame_struct`/
`gql_runtime_vm_free_block_frame`/`gql_runtime_vm_async_scheduler_resolve_frame`
への一時的なfprintfトレース(frame pointerとrefcountを記録)で、
finalizeが`return_pending_handle=0(legacy)`相当の経路を取っていたこと
を特定し、`ensure_fast_lane_state_sv`を他の全チャンネルと同様に
無条件呼び出しへ修正して解消。全デバッグ計装はコミット前に除去した。

**計測(再設計後)。**

| | 旧executor(fallback) | Phase 7(再設計後) |
|---|---:|---:|
| suspendケース | 104,050〜111,004 req/s (100%) | 104,371〜110,828 req/s (100〜101%) |
| 全同期ケース(async runtime) | 232,411〜235,636 req/s (100%) | 284,802〜287,545 req/s (121〜124%) |

退行が完全に解消し、全同期ケースの固定費解消(+21〜24%)はそのまま
維持された。suspendケースはPhase 3〜6と同じ「改善なし、退行もなし」
という結末に落ち着いた。

**検証。** `t/39_fast_lane_promise_fallback.t`へ6subtest追加(全同期、
exactly-once、non-null伝播、abstract union dispatch、Phase 6機構の
再利用によるネスト併用)。`t/54_frame_leak_regression.t`へ200回の
リークストレスを追加。既存の`'deadlocked stall releases the pending
frames'`/`'stall without on_stall releases the pending frames'`
subtestが、単一root object fieldの`{ inner { hang } }`ケースを新たに
fast lane経由でカバーするようになった。全500テスト、49ファイル個別
実行・`PERL_HASH_SEED`5点でのASan(再設計の前後どちらも)がクリーン。

**残課題(今回の対応範囲外として記録)。** `gql_runtime_vm_cancel_frame_tree`
は`GQL_VM_PENDING_LIST_PENDING_PTR`(list fieldの複数item集約ハンドル)
には未対応で、genuinely pendingなlist itemを含むリクエストがdeadlock/
on_stall放棄された場合、list_pending構造体配下の個々のitem frameへは
辿り着けない。今回のPhase 7の作業範囲では発見1の(1)(2)と全く同型・
同規模の話だが、list fieldの`GQL_VM_PENDING_LIST_PENDING_PTR`という
別のpayload種別に対する話であり、範囲外として次の課題に送る。

### 14.24 on_stallドライブをC側へ移し、レスポンス用Promise::XSを省略する(Phase 8)

`gql_runtime_vm_call_ticket_callback`の高速パス化(直前のコミット)後に
ベンチマークを取ったところ、対象がsuspendケースで増える約6箇所の
Perl呼び出し境界のうち1箇所に過ぎなかったため、測定誤差の範囲を超える
改善は確認できなかった。そこでsample(macOS標準のCPUサンプリング
プロファイラ)でsuspendケースをall-syncケースと比較し1000イテレーション
あたりのtick数へ正規化して内訳分解したところ、以下の内訳が判明した:

| カテゴリ | 追加コスト(tick/1k) |
|---|---:|
| Perl subコール境界(entersub/call_sv/runops) | 約13 |
| Perlの一時SV/CV後始末(sv_free2/sv_clear/free_tmps/leave_scope) | 約6 |
| DataLoader/Ticket決着の呼び出し連鎖 | 約3.7 |
| scheduler自体の構築・drain(exec_state_handle_t/block_frame_t/Promise::XS) | 約2.5 |

このうち「scheduler自体の構築・drain」の中核である、レスポンス用
Promise::XSの生成・`.then()`登録・同期解決という往復を丸ごと省く、
より抜本的な変更に着手した。

**発見: `finalize_sv`には既に「Promise::XSを一切作らない」経路が
存在した。** `gql_runtime_vm_async_scheduler_resolve_frame`の応答フレーム
(親を持たない)ケースには、`frame->deferred_sv`がNULLなら
`s->completed_response_sv`へ直接値を置く分岐が既にあった(元々は
「armだけで全pendingが即座に解決した」ケース向け)。`finalize_sv`の
`return_promise`計算式は応答フレームでは常にtrueに固定されていたため、
新モード(`return_pending_handle == 3`)を追加してこれを常にfalseに
できるようにするだけで、genuinely pendingなticketが後から解決される
場合にも同じ経路で完了できるようになった。

**実装。**
1. `finalize_sv`にモード3を追加(既存呼び出しへの影響ゼロを確認)。
2. `gql_runtime_vm_cancel_pending_response_sv`を、promiseのmagicを
   unwrapする前段と、`exec_state_handle_t`を直接受け取る本体
   (`gql_runtime_vm_cancel_exec_state_sv`)に分離(純粋なリファクタ、
   挙動変更なし)。
3. `gql_runtime_vm_try_execute_fast_root_continuation_sv`に
   `on_stall_sv`引数を追加。非NULLの場合、Phase 2の単一op直接resume
   ショートカット(このメカニズムを知らない独自のPromise::XS継続を
   構築するため)をスキップして常にmulti-opパスを使い、最後の
   `finalize_sv`呼び出しをモード3にする。genuinely pendingのまま
   返ってきた場合、新しい駆動ループ(`gql_runtime_vm_drive_with_on_stall_sv`)
   へ入る。
4. 駆動ループは`gql_runtime_vm_call_on_stall_once`でon_stallを
   `G_EVAL`付きの`call_sv`(このファイル全域のユーザーコールバック
   呼び出しと同じ確立されたイディオム)で直接呼び、
   `exec_state->completed_response_sv`をポーリングする。die()を
   捕捉した場合・進捗0の場合はどちらも`cancel_exec_state_sv`で
   キャンセルしてから`croak_sv`/`croak`し、`_settle_result`と
   全く同じ文言・契約を再現する。
5. 新しいXSエントリポイント`execute_native_program_auto_with_on_stall_xs`
   (実体は`gql_runtime_vm_execute_native_program_auto_with_on_stall_sv`)
   を追加。fast laneが対象shapeを扱えない場合(runtime directives・
   再帰深さ上限超過・json_modeなど)は、既存のgeneric executorへ
   完全に無変更でfall backする(そちらは引き続き本物のPromise::XSを
   返し、Perl側`_settle_result`が今まで通り駆動する)。
6. `NativeRuntime.pm`の`execute_program`のon_stall分岐を新エントリ
   ポイント呼び出しへ変更。`_settle_result`自体は変更せず、その戻り値を
   そのまま通す(`_settle_result`の1行目が「promiseでなければ即返す」
   ため、fast laneが完全に駆動し終えた結果でもgeneric executorが返した
   本物のpromiseでもそのまま正しく動作する)。

**単一op直接resumeショートカットとの関係。** これはPhase 2由来の
純粋な性能ショートカット(block_frame_t/exec_state_handle_tを一切
使わない)で、正しさの要件ではないため、`on_stall_sv`が与えられた
場合は常にスキップし、multi-opパス経由にする方針とした
(スコープを大幅に削減できた)。

**発見(検証中に判明した2つの既存バグ)。**

1. `_settle_result`(`NativeRuntime.pm`)は`on_stall`が「進捗0を返す」
   ケースでのみ`cancel_pending_response_xs`を呼んでいた。`on_stall`
   自身が`die`した場合、`$on_stall->()`呼び出し式から直接die が
   飛び出すため、cancel呼び出しへ到達せず、応答側の参照循環
   (exec_state → armed callback → promise → exec_state)がリークして
   いた。Phase 8以前のビルドでも同じシナリオで同じ個数(3 frame)が
   リークすることを確認済み(既存のバグで、Phase 8による退行ではない)。
   Phase 8の新経路は`G_EVAL`でdie を捕捉してから`cancel_exec_state_sv`
   を呼ぶため、**単純なPromise::XS(生のresolverの戻り値)がpendingな
   場合はこの問題を解消する**(0/0を確認)。
2. ただし、**DataLoaderの`Ticket`がpendingな場合は同じシナリオでも
   3 frameのリークが残る**ことが判明した。`Ticket`は
   `gql_runtime_vm_subscribe_dataloader_ticket`でsubscribeされると、
   自分のsubscriberリストへresolve/reject callbackペアを追加するが、
   このTicket自体はDataLoaderの`_queue`から参照され続けており
   (`dispatch`が呼ばれるまで消えない)、`cancel_exec_state_sv`は
   この参照経路を辿れない。on_stallの死・stall検出のどちらでも
   同じ形で再現し、Phase 8以前のビルドでも全く同じ個数がリークする
   ことを確認済み(退行ではないが、修正もしていない、既知の別課題)。

**検証。** `t/59_on_stall_native_drive.t`を新規追加: 全同期リクエスト
(on_stallが一度も呼ばれないこと)、DataLoaderネスト suspend の正常解決、
resolver die・batch関数die(いずれもfield errorへ変換され例外にならない
ことを確認)・on_stall自身のdie(生のPromise::XSがpendingな場合は
クリーン)、stall検出(同上)、複数loaderをまたぐ`on_stall_for`、200回
リークストレス、そして上記の既知バグ2件を「現状のまま固定した」
専用subtest(必ずファイル末尾に配置 - リークが以降の全subtestの
ゼロフレーム前提を壊すため)。全510テスト、50ファイル個別実行・
`PERL_HASH_SEED`5点でのASanがクリーン。

**計測。** `async_single_root_object_field`(6標本中央値、複数回計測):

| | 旧executor(`_settle_result`+Promise::XS) | Phase 8(C駆動) |
|---|---:|---:|
| suspendケース | 106,103〜108,195 req/s (100%) | 127,099〜132,923 req/s (120〜125%) |

単一nested fieldのケースで**+20〜25%の明確な改善**を確認した
(これまでのPhase 3〜7が軒並み「改善なし」だったのとは対照的)。
一方、`async_nested_object_list_item_field`(Phase 6のroot list field、
item数を2/5/10で変えたベンチマーク)で同様に比較すると:

| width | 旧executor | Phase 8 |
|---|---:|---:|
| 2 | 58,813 req/s | 65,433 req/s (+11%) |
| 5 | 34,230 req/s | 35,144 req/s (+2.7%、誤差程度) |
| 10 | 20,002 req/s | 19,402 req/s (-3%、誤差程度〜横ばい)|

item数が増えるほど改善幅が縮小し、10件では誤差程度になる。Phase 8が
削減するのは**リクエストあたり固定のコスト**(応答用Promise::XS
1個分の構築・登録・解決)であり、item数が増えるとリクエスト全体の
処理時間がitemごとの決着コストで支配的になるため、固定costの
相対的な寄与が薄まるという解釈で一貫している。

**スコープ。** 今回はfast lane(Phase 3〜7がeligibilityを広げてきた
形)が対象shapeを扱える場合に限定した。fast laneが対象外のshape
(runtime directives・再帰深さ上限超過・json_mode)は、引き続き
従来のgeneric executor+`_settle_result`経由のまま
(このphaseの恩恵を受けない)。

### 14.25 LazyInfo($info)構造体のpool化(Phase 10)

Phase 8完了後、wide list fan-outで改善幅が縮小する件を`sample`で調査
した。width 2/5/10でasync/sync比を計測したところ、比率はほぼ一定
(41〜43%)で、固定cost(≈4µs)+item毎cost(≈2.3µs)という線形分解が
成り立った。widthが増えるほど改善幅が縮む現象は、Phase 8/9が削った
「リクエスト固定cost」がitem毎costに対して相対的に薄まるだけの、
正常なスケーリングだと確認した。

item毎costの内訳として、まずDataLoader::Ticketの表現見直し(pooled
C handle化)を検討したが、§14.10/§14.12で既に同種の試作・検証済み
(「支配的なのはTicket生成ではなくpending entry/callback/scheduler
機構」という結論)であり、リーフフレーム内訳(`Perl_sv_clear`/
`Perl_hv_common`/`_xzm_free`等の汎用Perlランタイムコストが上位で、
Ticket生成関数は少数)も同じ結論を裏付けたため見送った。次に
field単位のバッチresolver API(`resolve_many`)を検討したが、GraphQL
エコシステムに前例がなくDataLoaderと概念が重複し、per-item
error/non-null伝播の意味論が破綻しやすいため設計として見送った。

その後「resolverをN回呼ぶこと自体を効率化できないか」を検討し、
具体的な残りの一手を1件発見した。resolverが引数を持つ場合、
`gql_runtime_vm_call_cb5_nonfatal`(5引数ABI)の5番目の引数として
`GraphQL::Houtou::Runtime::LazyInfo`ハンドルを**resolverが`$info`を
一度も参照しない場合でも毎回**新規構築していた。構築のたびに
`gql_runtime_vm_lazy_info_t`を`Newxz`、8個の`SvREFCNT_inc`、3個の
文字列複製(`gql_runtime_vm_copy_cstr`によるNewx+Copy)、blessed
handle SVの生成を行い、破棄時にすべて逆再生する。引数なし/1引数
resolverは`call_cb3_nonfatal`/`call_cb4_nonfatal`を使い、そもそも
`$info`を作らない(このためこのセッションの他のベンチマークの多くは
偶然この最適化の恩恵を既に受けていた)。

引数あり/なしresolverのみを変えた同一width=10の同期ベンチマークで
この差を単離すると:

```
                   Rate dynamic_args_sv      no_args_sv
dynamic_args_sv 48260/s              --             -9%
no_args_sv      52919/s             10%              --
```

約9〜10%の一貫した差が出た。3個の文字列複製先(`field_name_pv`/
`parent_type_name_pv`/`return_type_name_pv`)はいずれも
`slot->field_name`/`block->type_name`/`slot->return_type_name`という
コンパイル済みnative program(スキーマ)由来の、リクエストより長生き
する不変文字列だと確認できたため、複製せず借用するだけに変更(対応
する`Safefree`も削除)。さらに`gql_runtime_vm_lazy_info_t`構造体自体を
`gql_runtime_vm_block_frame_pool_get`/`_path_frame_pool_get`/
`_outcome_pool_get`/`_native_value_pool_get`(`src/vm_runtime.h`)と
全く同じ形(capを持つfree-listで構造体メモリを使い回す)でpool化し、
`Newxz`/`Safefree`のアロケータchurnを除去した。参照カウント(refcount)
の意味論は一切変更していない。blessed handle SV自体(resolverの`@_`
へ直接渡され、resolverが保持し続ける可能性がある)はpool化していない
- 保持されたまま使い回すと別呼び出しの情報にすり替わる危険がある
ため、構造体だけをpool化し、handle SVは従来通り毎回新規生成する。

**検証。** `t/15_runtime_execute.t`の既存subtest(`$info`の
field_name/parent_type/return_type/path/context_value/variable_values
を検証)がそのまま正しさの網になる。加えて、30 item分のargsあり
resolver呼び出しを行い、各呼び出しの`$info`(field_name/parent_type/
path)が正しくその呼び出しに紐付いている(pool再利用による汚染が
ないか)ことを確認する新規subtestと、`t/54_frame_leak_regression.t`
の`assert_no_live_frames`へ新設した`lazy_info`カウンタの0確認
(既存の全subtestに自動適用)、200回の混在ストレス(正常決着/
resolver dieを混ぜる)subtestを追加した。全512テスト・ASan
(5 hash seed)・Perl 5.24(Docker)がクリーン。

**計測。** git worktreeでPhase 10適用前(main)と適用後を並べ、
`dynamic_args_sv`のみをインターリーブして4回計測(同一プロセス内の
相対比較ではなく、別プロセス起動を交互に行うことで環境ドリフトの
影響を抑える狙い):

| round | 適用前 | 適用後 |
|---|---:|---:|
| 1 | 47,168 req/s | 50,146 req/s |
| 2 | 46,693 req/s | 50,561 req/s |
| 3 | 46,548 req/s | 49,304 req/s |
| 4 | 46,693 req/s | 50,082 req/s |

平均46,776→50,023 req/sで**約+7%**、全4回で同じ向きの改善を確認した。
`async_nested_object_list_item_field`(引数なしresolver、width 2/5/10)
は回帰なし。

**スコープと限界。** これは引数を持つresolverにのみ効く、Phase 3〜9
と同じ「1桁%クラス」の改善であり、抜本的な改善ではない。Perlが
resolverクロージャをN回呼ぶという本質コスト(entersub/eval scope/
sv_clear)自体は変わらない。field単位のバッチresolver APIは
GraphQLのAPIとして筋が悪いと判断し見送ったため、この方向での
「抜本的な一手」は現時点で見つかっていない。

### 14.26 Ticketキャンセル時リークの修正とgeneric executor fallbackへのon_stallドライブ拡張(Phase 9)

Phase 8で見つけた2件の既存課題(§14.24末尾)を先に片付けてから、
今後のasync経路高速化(§14.13系)の検討に戻る、という順で着手した。

**課題1の修正: DataLoader Ticketキャンセル時のリーク。**

原因は次の通りだった。`gql_runtime_vm_async_scheduler_arm_frame`が
pending entryをarmする際、`entry->armed_resolve_ctx`と
`entry->armed_reject_ctx`の両方に同じ`pair_ctx`
(`gql_runtime_vm_new_pending_callback_pair`が返すctx)を格納する。
通常の決着ではどちらかのarmが発火し
`gql_runtime_vm_pending_callback_pair_recycle`がctxの
`state_sv`/`frame`参照を破棄するが、`gql_runtime_vm_cancel_frame_tree`
はこれまで`armed_resolve_ctx`を一切見ておらず、キャンセル時にはこの
2参照が破棄されないままだった。生のPromise::XSはリクエスト内部に
閉じているため実害がない(Phase 8の`G_EVAL`捕捉で解消済み)一方、
DataLoaderの`Ticket`は`gql_runtime_vm_subscribe_dataloader_ticket`
経由で自分のsubscriberリストへ同じresolve/reject callbackペアを
追加しており、Ticket自体はDataLoaderの`_queue`から参照が続くため、
`cancel_exec_state_sv`側から辿れる経路が存在しなかった。

`pending_callback_pair_recycle`をそのままキャンセル時にも呼べない
理由: この関数はCVペアを次回再利用のためプールへ戻す。だが
キャンセルされたTicketは(settleされていない=state==0のまま)
DataLoaderの`_queue`に生き続ける可能性があり、後になって万一
dispatchされれば同じCVペアが発火してしまう。プールに戻していると
そのCVは既に別の無関係なリクエストに再利用されている可能性があり、
発火時にその無関係なリクエストのframeを破壊しかねない。そこで
`gql_runtime_vm_pending_callback_ctx_disarm`を新設し、
`state_sv`/`frame`参照の破棄はrecycleと同じだがCVプールへは戻さない
ようにした(CV自体は「二度と有効な処理をしない」まま生き続けるだけの
小さく無害な残留物になる - 各callback XSUBは元々`ctx->state_sv`/
`ctx->frame`がNULLなら早期return する設計のため)。`cancel_frame_tree`
のpending entryループへ、`armed_resolve_ctx`が非NULLなら
disarmを呼ぶ処理を追加した。

`t/59_on_stall_native_drive.t`の末尾に「既知のリークとして固定した」
2 subtestを、他のsubtestと同じ`assert_no_live_frames`で0/0を要求する
形に書き換え、ファイル末尾固定という制約も撤廃した(通常のsubtestと
同じ位置に戻した)。全510テスト・ASan(5 hash seed)・200イテレーション
の混在ストレス(通常決着/on_stall die/stall検出をランダムに混ぜる)
がクリーン。Perl 5.24(Docker)でも再検証済み。

**課題2の対応: generic executor fallbackもC側でon_stallドライブする。**

Phase 8はfast laneが対象shapeを扱える場合限定だった。fast lane非対応
shape(runtime directives・再帰深さ上限超過)は、`execute_native_program_auto_with_on_stall_sv`
のfallback分岐が`execute_native_program_auto_impl_sv`をそのまま
(`on_stall_sv`を渡さず)呼んでおり、genuinely pendingなら本物の
Promise::XSを返してPerl側`_settle_result`が駆動していた。

**設計判断: generic executor自体には手を入れない。**
`gql_runtime_vm_exec_state_execute_block_async_path_sv`はmutationの
直列実行や通常のネスト実行など複数の呼び出し元に共有されており、
`finalize_sv`のモード3をそこまで通す変更は対象範囲の狭さ(fast lane
非対応shapeのみ)に対してリスクが大きい。そこで generic executor
自身は変更せず(今まで通り本物のPromise::XSを内部で構築する)、
「誰がそのpromiseを消費するか」だけを変えた: `gql_runtime_vm_drive_promise_with_on_stall_sv`
がC側で`.then()`を直接登録し、Perlの`_settle_result`へ渡す代わりに
その場でon_stallを駆動する。generic executor内部は変わらず本物の
Promise::XSを作るため、fast laneほどの削減(Promise::XS生成自体の
省略)にはならず、外側のPerlレベル`.then()`登録+whileループの往復
だけを省く形になる。

**実装。**
1. `gql_runtime_vm_settle_capture_ctx_t`(`value`/`settled`/`cv_refcnt`)
   と、それを共有するresolve/reject CVペア
   (`gql_runtime_vm_new_settle_capture_pair`)を追加。`settled`は
   0=未決着・1=resolve・2=reject。
2. `execute_native_program_auto_with_on_stall_sv`のfallback分岐:
   `execute_native_program_auto_impl_sv`の戻り値に応答magic
   (`gql_runtime_vm_response_state_magic_vtbl`)が付いていれば
   (genuinely pendingの目印)、`gql_runtime_vm_drive_promise_with_on_stall_sv`
   へ渡して駆動する。付いていなければ(既に完了している)そのまま
   返す。
3. 駆動ループは`gql_runtime_vm_call_then_promise_xs_sv`で`.then()`を
   登録した後、`gql_runtime_vm_call_on_stall_once`(Phase 8と共通)で
   on_stallを呼び、`ctx->settled`をポーリングする。進捗0なら
   `gql_runtime_vm_cancel_pending_response_sv`(既存の
   `_settle_result`と同じキャンセル関数)を呼んでからcroak。
   `_settle_result`と同じ文言・契約を維持。

**開発中に発見・修正した実バグ(use-after-free)。**
最初の実装では`ctx->cv_refcnt`をresolve/reject CVの2つ分だけで
初期化していた。ASan(ローカル、Apple clang 21のASanランタイムを
`DYLD_INSERT_LIBRARIES`で明示指定)で検証したところ、
`heap-use-after-free`が`gql_runtime_vm_drive_promise_with_on_stall_sv`
の`while (!ctx->settled)`条件式で発生した。原因はPromise::XSの
`then()`実装が、どちらかのarmを発火させた直後に**両方の**保持していた
callback参照を一括で解放すること: 呼び出し元(このドライブ関数)が
`.then()`登録直後に自分の参照を`SvREFCNT_dec`していたため、
CV側の参照だけが最後の1本になっており、発火直後にCVが即座に破棄され
`ctx`(cv_refcnt経由で共有)もその場で`Safefree`されてしまっていた -
数フレーム上の呼び出し元がまだ`ctx->settled`を読もうとしている
最中に。修正として`cv_refcnt`の初期値を3(resolve CV・reject CV・
呼び出し元自身の3口分)にし、呼び出し元はctxを読み終えた後
(正常決着・reject・stall検出によるcroak、いずれの経路でも)明示的に
自分の持ち分を`gql_runtime_vm_settle_capture_ctx_release`で解放する
よう変更した。CIのASan(gcc/Linux)はheap corruptionを検出するはずの
レイヤーだが、この不具合はheap allocatorのレイアウトに依存して
発現有無が変わる類のもので(`minil test`のように毎回別プロセスの
Perlを起動する経路では再現し、単発の`perl`/`prove`実行では再現しない、
という形で最初に気づいた)、ローカルでのASan検証(Apple clang由来の
ランタイムを明示指定)が実際に有効だったケース。

**検証。** `t/59_on_stall_native_drive.t`へ5 subtestを追加:
runtime directiveでfallbackを強制するケース(正常決着)、再帰深さ
上限を1超えるケース(正常決着)、fallback経由のresolver/batch die
(field errorへの変換)、fallback中のon_stall自身のdie、fallback中の
stall検出。全515テスト・ASan(5 hash seed、上記use-after-free修正後は
クリーン)・300イテレーションの混在ストレス(正常決着/on_stall die/
stall検出/reject伝播をランダムに混ぜる)がクリーン。Perl 5.24
(Docker)でも再検証済み。

**計測。** `async_fallback_runtime_directive`(runtime directiveで
fallbackを強制、nested fieldがDataLoader Ticket pending、count=-3で
複数回計測):

| | 旧経路(fallback+`_settle_result`) | Phase 9(fallbackをC駆動) |
|---|---:|---:|
| suspendケース | 112,065〜114,473 req/s | 113,400〜116,693 req/s |

誤差の範囲内で、測定可能な改善は確認できなかった。generic executor
自体のリクエストあたりコスト(fast lane非対応shapeなので相対的に
重い)が支配的で、外側のPromise::XS `.then()`登録+whileループという
比較的小さい固定コストを削っても全体に対する寄与が薄い、という
Phase 8の考察(§14.24末尾のitem数依存の解釈)と整合する結果。
Phase 3〜7と同じ「改善なしだが正しさ・保守性の観点で妥当」という
カテゴリの変更。

### 14.27 list itemのraw frame直結(Phase 7の仕組みをlistへ拡張、Phase 11)

「async経路は調査し尽くした」という本セッションの結論に対し、ユーザー
から具体的な再検証を受けた。`lib/GraphQL/Houtou.xs:9567`付近のコメントと
`src/vm_runtime.h`の`gql_runtime_vm_list_pending_t`定義を確認したところ、
指摘は正確だった: `gql_runtime_vm_execute_safe_child_block_fast_sv`は
`want_promise`引数で`finalize_sv`のモードを切り替えており、非list
のobject/abstract child field(Phase 7、`want_promise=0`→モード1)は
suspend時に生のblock_frame_tハンドルを返し
`gql_runtime_vm_push_pending_block_frame`で親へ直結できる一方、list
item(`want_promise=1`→モード2)だけは常にPromise::XSを強制構築して
`gql_runtime_vm_list_pending_handle_sv`が`.then()`で購読していた。

**実装。** list item呼び出し箇所を`want_promise=0`に変更。
`gql_runtime_vm_list_pending_t`に`pending_child_frames[]`(list_pendingの
各slotに対応する、まだ決着していない生のchild frameへのポインタ配列)
を追加し、`gql_runtime_vm_block_frame_t`に`parent_list_pending`/
`parent_list_index`(既存の`parent_frame`/`parent_entry_index`と排他的な
別種の親)を追加。新設した`gql_runtime_vm_list_pending_link_child_frame`
が生frameをlist_pendingのslotへ直結し、
`gql_runtime_vm_async_scheduler_resolve_frame`に`parent_list_pending`分岐
を追加してPromise::XS/SV往復なしにnative valueを直接list_pendingへ
書き込むようにした。`gql_runtime_vm_cancel_frame_tree`にも
`GQL_VM_PENDING_LIST_PENDING_PTR`分岐を追加し、`pending_child_frames[]`
を辿ってabandoned requestでも生frameを正しく解放するようにした。

**開発中に発見・修正した実バグ(リーク2件)。** どちらもASanではなく
`t/54_frame_leak_regression.t`の`debug_frame_live_counts_xs()`カウンタで
発見した。(1) `resolve_frame`の新分岐は最初`free_block_frame`を1回しか
呼んでおらず、child frameが持つべき2つの参照(linkが取った分と、生成時
からのcreation分)のうち1つしか解放していなかった - 既存の
`parent_frame`分岐が`gql_runtime_vm_async_pending_entry_store_outcome_ptr`
内で1回、明示的に末尾でもう1回、計2回`free_block_frame`を呼んでいるのと
同じ構造が必要だった。参照カウントの値を`fprintf(stderr, ...)`で一時的に
出力し、非list(既存・正常動作)のケースと比較して原因を特定した。(2)
`cancel_frame_tree`の新分岐にも同じ問題があった - 既存の
`BLOCK_FRAME_PTR`分岐は`clear_pending`自身の処理から2回目の解放を
「タダで」得られるが、`pending_child_frames[]`は`clear_pending`から見えない
別の配列のため、2回の解放を両方とも自分で行う必要があった。

**検証。** `t/54_frame_leak_regression.t`へ2 subtestを追加: 生frame直結
されたlist itemがpendingなままrequestがabandonされるケース(on_stall
die・stall検出のいずれも)が0/0になることを確認するsubtestと、同期item・
Ticket直接購読のleaf item・生frame直結itemを1 requestに混在させて
正しく決着することを確認するsubtest。既存のPhase 5/6/7テスト一式
(非null伝播、abstract member dispatch、error record、混在sibling)は
無変更のまま全て通過。全519テスト・ASan(5 hash seed)・Perl 5.24
(Docker)がクリーン。

**計測(訂正を含む)。** 最初`git worktree`比較なしに、単発実行の数値を
本セッション前半(Phase 10検証時)の数値と単純比較し、「width=10で
+40%超」という誤った改善を報告してしまった。Phase 10自体が
「別プロセス起動を交互に行うことで環境ドリフトの影響を抑える」ために
確立した手法を、自分で怠った結果である。`git worktree`でPhase 11適用前
(main)を用意し正しくインターリーブして再測定したところ、
`async_nested_object_list_item_field`のwidth=10で適用前
約30,200〜31,000 req/s、適用後約30,000〜30,900 req/sとなり、**実質的な
改善は確認できなかった**。

`sample`で原因を確認したところ、**適用前のビルドですら`Promise::XS`/
`xspr_*`関連の関数は5秒間のプロファイルにほぼ出現しない**(0〜6サンプル
程度)。除去したPromise::XS生成+`.then()`登録+SV往復の仕組みは、この
benchmark shapeにおいて元々全体コストに占める割合が小さく、削っても
測定可能な差にならなかったということである。適用後のプロファイルでは
該当シンボルが完全に消えており、狙った通りの経路変更ができていることは
確認できるが、体感できる速度改善には繋がらなかった。

**結論。** Phase 9のfallback駆動化と同じ「正しさ・設計上の妥当性はあるが
測定可能な改善なし」というカテゴリの変更。ユーザーの指摘通り
「async経路は調査し尽くした」は言い過ぎだったが、この具体的な実装が
実際に効果を持つかは実装して測るまで分からなかった - 「効かなければ
それはそれで頭打ちの証拠になる」というユーザー自身の見立て通りの結果
になった。correctness面の価値(Phase 7の仕組みの一貫した適用、
Promise::XS依存の削減)を理由に採用する。
