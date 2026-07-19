# XS/C ランタイムのコーディングルール

Houtou.xs / src/*.h を触るときの確認事項。実際に踏んだバグ(deadlock #43、
ASan SEGV #45 ほか)から抽出したルール集で、コードレビュー時のチェック
リストとして使う。各ルールに出典(踏んだバグ)を添えてある。

## 1. 配列の grow とゼロ埋め

**`Renew` は新スロットをゼロ埋めしない。**「count 以降のスロットは空」を
前提に読む consumer がいる配列は、grow 時に必ず旧 capacity から新 capacity
まで NULL 埋めする。

- 新しい grow を書くときは、その配列が **append-only**(count 未満しか
  読まれない)か **sparse**(count を跨いだ index を読み書きする)かを
  確認する。sparse ならゼロ埋め必須。
- 現状 sparse な consumer は `native_list_store_at` だけ。native list の
  items 配列に書き込む grow は全てゼロ埋めが要る。
- 出典: `native_list_push` がゼロ埋めせず、プール再利用された list の
  未初期化スロットを store_at が live child とみなして destroy → wild
  pointer SEGV(#45 の ASan flake。ハッシュシード依存で main でも再現)。

## 2. プールの後片付け契約

プールは 2 種類の契約のどちらかに従う。**どちらの契約か本体にコメントで
明示し、混ぜない。**

- **get で Zero する型**(block_frame / outcome / path_frame):
  プールに入れる**前**に所有リソース(SV の decref、owned 文字列や
  配列の Safefree)を全て解放すること。get 側の Zero はポインタを
  黙って消すので、解放漏れはそのままリークになる。
- **destroy が後片付けする型**(native_value): get は kind_code を
  設定するだけで Zero しない。destroy が「再利用可能な規定状態」
  (count=0、count 未満のスロット NULL、scalar フィールド NULL)まで
  戻す責任を負う。**この型では「count 以降は空」を保つのは書き込み側の
  責任**(ルール 1)。
- 保持配列(block_frame の pending_entries、native_value の names /
  names_borrowed / values / items)は capacity ごと再利用される。
  count 以降に stale データが残るのは仕様なので、そこを読むコードを
  書かない。

## 3. 並列配列は必ず同時に扱う

`names` / `names_borrowed` / `values` のような並列配列は:

- **同時に Renew**(同じ capacity で)
- **同時に初期化**(push 時に全列へ書く)
- **同時に解放**

store/push ヘルパを経由せず配列を直接操作するコードを追加しない。
新しい並列配列を足すときは、既存の grow・destroy・pool 解放・clone の
全経路に列を追加したか grep で確認する(`object.names` などで全 usage を
洗う)。

## 4. borrowed ポインタの生存契約

`borrowed = 1` で保持してよいのは**実行プラン所有の文字列だけ**
(slot->result_name など)。exec state が runtime/program への強参照を
持つため、プラン文字列はリクエストの全ての値・entry より長生きする。
promise が execute 呼び出しを跨いで遅延 settle しても成立する。

- borrowed フラグを新しい場所へ伝播するときは、出所を辿って
  プラン文字列に行き着くことを確認する。
- **entry 所有(savepvn した)文字列を borrowed として値に伝播しては
  いけない**: entry は clear_pending で先に死に、値(values_value)は
  frame resolve まで生きるため dangling になる。
- Perl の HV キー・呼び出し元 SV 由来の文字列は常にコピー(borrowed=0)。

## 5. 配列 index を値で持つコールバック ctx

pending 配列は `process_frame` が再構築し、READY entry の消費で残りの
entry の index が**前詰めされる**。

- entry を参照する長寿命の ctx に index を値で保存する場合、entry 側に
  ctx へのバックポインタを持たせ、**再 push 時に ctx の index を
  retarget** する(`armed_resolve_ctx` / `armed_reject_ctx` の機構)。
- 「settle 時の書き込みが bounds check で黙って捨てられる」形の防御は
  デッドロックを隠すだけなので、値が捨てられる経路には warn を入れるか
  設計で到達不能にする。
- 出典: arm 済み entry の then コールバックが旧 index を持ち続け、
  preresolved promise と loader promise の混在で deadlock(#43)。

## 6. コールバック CV のプール(ペア再利用)

- ペア(resolve/reject)の返却は**発火時のみ**。promise は settle すると
  もう一方の arm を二度と呼ばないことが前提。未発火の CV は従来どおり
  magic free で死ぬ(プールが発火経由でしか増えないので leak しない)。
- **プール返却は XSUB 本体の最後に置き、以降 ctx に触れない**。返却した
  瞬間から別の arm に再利用されうる。
- ctx を複数 CV で共有する場合は `cv_refcnt` で管理し、magic free は
  最後の CV でだけメンバ解放 + Safefree する(二重解放防止)。

## 7. スケジューラの不変条件(async)

- `finalize` は arm を `draining=1` で包む。**arm ループ中に pending
  配列の swap は起きない**前提のコード(entry ポインタの保持など)は
  この不変条件に依存している。ここを変えるときは arm 中の同期 settle
  (preresolved promise)経路を必ず確認。
- 実行中(frame_stack 上)の親 frame を ready queue に入れない
  (resolve_frame の executing-parent ガード)。
- rejection は entry に**直接**届く設計(reject callback が entry へ
  store)。「outcome を返すだけの error callback」を armed entry の
  reject arm に使うと、outcome が破棄済み派生 promise に消えて
  デッドロックする。

## 8. 完了セマンティクスのレーン間パリティ

同じ completion(OBJECT / LIST / ABSTRACT / GENERIC)が **4 実装**ある:
async レーン、sync fast SV レーン、fast JSON レーン、native value
(bundle)レーン(+ legacy sync_now)。仕様上の分岐(null → null、
abstract の型解決前 null チェック、リスト内 null 項目など)は**全レーンに
同じガードが要る**。

- completion の意味論を触るときは `GQL_VM_COMPLETE_*` を grep して
  全レーンの同名分岐を並べ、ガードの有無を突き合わせる。
- 片方のレーンにしかテストがない意味論は「レーンを跨いで同じ入力を
  流す」テスト(t/43 の形)で固定する。実行レーンは
  variables の有無・bundle・to_json で切り替わるため、ユーザ入力次第で
  どのレーンにも到達する。
- 出典: object 完了の undef ガードが async / JSON レーンにだけあり、
  fast SV レーン(variables 付き execute_document)と bundle レーンは
  undef source のまま child block を実行して「全フィールド null の
  偽オブジェクト」を返していた(リスト内 null 項目も同型)。

## 9. 検証手順

- **ヘッダ(src/*.h)を変えたら `rm lib/GraphQL/Houtou.o
  lib/GraphQL/Houtou.c` してから `perl Build`**。Build はヘッダ変更で
  .o を再コンパイルしない。正式なテストは `minil test`。
- メモリ安全に触れる変更は ASan でも回す:
  - Linux(CI 同等): `perl Build.PL --config optimize="-O2 -g
    -fsanitize=address -fno-omit-frame-pointer" --config
    lddlflags="-shared -fsanitize=address"`、実行時に
    `LD_PRELOAD=$(gcc -print-file-name=libasan.so)` +
    `PERL_DESTRUCT_LEVEL=2`。
  - macOS: lddlflags は `-bundle -undefined dynamic_lookup
    -fsanitize=address`、実行時に `DYLD_INSERT_LIBRARIES=<libclang_rt.
    asan_osx_dynamic.dylib>`。**prove 経由は SIP が DYLD 変数を子に
    渡さないので、テストを単体実行するか Linux コンテナを使う。**
- **ASan は `PERL_HASH_SEED` を複数固定して回す**(例: 1〜20)。HV の
  反復順がプールの並びを変え、未初期化読みの発火がシード依存になる。
  CI が「同一コミットで pass と SEGV」を出したら、まずシード起因を疑い
  ローカルでシード掃引して決定化する。
- ASan は**未初期化読みを検出しない**(それは MSan)。fault アドレスに
  `0xbe` の繰り返しパターンが見えたら ASan の malloc fill、つまり
  未初期化ヒープの読み出しを疑う。
- 恒常的なリーク検証は soak(util/soak-test.pl)。プールを増やす変更は
  soak の growth が既知水準(±数百 KB/20k iter)に収まることを確認。
