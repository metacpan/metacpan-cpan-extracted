# Execution Benchmark

## Purpose

実行系の主系が runtime / VM / native bundle に移ったため、
execution benchmark の評価軸もそれに合わせる。

この benchmark が見るものは次の 2 系統です。

- `cached runtime (perl)`
  - 起動時に runtime と program を compile した後、Perl VM で実行する
- `cached native bundle`
  - 起動時に native runtime / native bundle まで compile した後、native VM を実行する

重要なのは、resolver の戻り値そのものではなく **実行計画の再利用** を測ることです。
そのため旧 execution mainline の比較は主系から外しました。

## Drivers

- `util/execution-benchmark.pl`
- `util/execution-benchmark-checkpoint.pl`
- `util/profile-execution-target.pl`

## Measurement Setup

典型的な使い方:

```sh
perl util/execution-benchmark.pl --count=-3

# checkpoint 向けの繰り返し実行
perl util/execution-benchmark-checkpoint.pl --repeat=5 --count=-3
```

単独 target の profiling / 実行確認:

```sh
perl util/profile-execution-target.pl \
  --case nested_variable_object \
  --target houtou_runtime_cached_perl \
  --iterations 300

perl util/profile-execution-target.pl \
  --case nested_variable_object \
  --target houtou_runtime_native_bundle \
  --iterations 300
```

## Compared Targets

現在の benchmark script が比較する target は次です。

- `upstream_string`
- `upstream_ast`
- `houtou_runtime_cached_perl`
- `houtou_runtime_native_bundle`

promise case では native bundle を使わず、Perl runtime を比較対象に残します。

## Notes

- benchmark script は repo checkout の `lib/` を優先し、必要なら `blib/arch` の XS を併用します。
- native benchmark を回す前には、repo root の `./Build build` で local XS artifact を更新してください。
- これを忘れると、Perl 側 lowering は最新でも native bundle 実行だけ古い XS を読むため、
  `__typename` や slot index の mismatch を benchmark failure として誤検出します。
- `util/execution-benchmark-checkpoint.pl` の既定 mode も
  - `houtou_runtime_cached_perl`
  - `houtou_runtime_native_bundle`
  に切り替わっています。

## Interpretation

いま重視するのは micro-opt の上下ではなく、次の 3 点です。

1. cached runtime が upstream を安定して上回るか
2. cached native bundle が cached runtime より十分前に出るか
3. nested / list / abstract の 3 系統で極端な regress がないか

つまり、評価対象は
**「旧 executor より何 % 速いか」ではなく、runtime の control plane と native data plane の分離が実利を生んでいるか**
です。
