# Sync-first async execution design

## 1. 目的

async runtimeでも、resolverが実際にpending値を返すまでは同期fast laneと同じ実行コストに
近づける。Promise/Ticketが現れる可能性だけを理由に、同期fieldまでasync frame、pending
entry、scheduler、汎用completionへ載せない。

目標とする制御フロー:

```text
sync VM loop
  ├─ plain value / ready Ticket: 同期completionを続行
  └─ pending Ticket / Promise:
       現在位置をcontinuationへ退避
       subscriberを登録して呼び出し元へ戻る
       settle後にcontinuationをready queueへ積む
       保存した位置からsync VM loopを再開
```

本設計はPromiseの実行時間やI/O待ち時間を短縮するものではない。Houtou内部で同期処理にも
課しているasync対応コストを、実際のsuspension境界へ限定する。

## 2. 現状と問題

現在はrequest開始前にlaneを選択する。`async => 1`または`on_stall`があるrequestは、
resolver結果を調べる前からasync executorへ入る。

sync laneはblock内のopをその場でresolve/completeし、native valueへ格納する。cursor
snapshot、stack field frame、再帰呼び出しは関数が戻るまでに解放できる。

async laneはsuspension後も状態を保持するため、block frameとpending entryをheap上に作り、
resolver結果をpending表現へ変換し、callbackとschedulerでcompletionを再開する。この構造は
本当にpendingなfieldには必要だが、同期値しか返さないfieldも同じ経路を通る。

本質的に必要なasync固有処理は次に限られる。

- pending値を検出した時点の継続状態保存
- Ticket subscriberまたはPromise callbackの登録
- sibling/list itemの未解決数管理
- ready continuationのschedule
- suspensionをまたぐ値、path、frameのownership

request開始時から別executorを使うこと、同期completionをasync表現へ変換すること、
一度もsuspendしないblockにpending machineryを用意することは本質的要件ではない。

## 3. 既存実装から再利用する要素

mutation rootの`gql_runtime_vm_execute_serial_mutation_steps`は、同期opをloopで実行し、
Promiseが現れた時だけ`next_op_index`とframeを保持してcallback後に再開する。query用
continuationはこのモデルを、並行なsibling fieldとlist itemを扱える形へ一般化する。

既存の次の要素も維持する。

- native program、block、op、slot
- native valueとoutcome
- DataLoader Ticketのready同期取得
- async ready queueと再入抑止
- null/non-null、error path、abstract/list completionの共通helper
- `on_stall`によるDataLoader駆動とdeadlock検出

最初からschedulerやpending entryを全面置換しない。新continuationが扱えないshapeは現行async
executorへfallbackし、段階的に対象を増やす。

### 3.1 他言語処理系との対応

この設計は新しい方式ではなく、stackless coroutineをVM executorへ適用するものと整理できる。

- C# async methodは、未完了のawaitableへ到達するまで呼び出し元のthread上で同期実行する。
  awaitableが完了済みなら中断せず値を使う。Houtouのready Ticket fast pathに対応する。
- Kotlin coroutineはCPS変換後の関数が通常値または`COROUTINE_SUSPENDED` markerを返し、
  continuation objectにlocal変数とstate-machine位置を持つ。Houtouのop実行結果を
  completed outcomeまたはpending markerとして返すABIに最も近い。
- Rust `Future::poll`は`Ready(value)`ならそのまま進み、`Pending`なら状態を保持してwake後の
  pollで再開する。Houtouのready queueとblock continuationの関係に近い。
- LLVM coroutine loweringはsuspend pointをまたいでliveな値だけをcoroutine frameへspillし、
  start/resume/destroyへ分割する。continuationの最小状態と破棄関数を決める際のモデルになる。

静的なasync/await言語との主な違いは、suspend可能な構文位置がcompile時に既知なのに対し、
resolver call siteではplain valueとPromise/Ticketのどちらが返るかrequest時まで分からない
点である。これはHoutou固有ではなく、GraphQL.jsなどresolver結果を実行時にthenable判定する
GraphQL executorにも共通する。Houtouでは全blockを事前にcoroutine frame化せず、resolverが
pendingを返した時だけstack上の状態をheap continuationへ昇格する。CPS/state-machine
loweringを動的なlazy promotionとして実装する点が、静的async変換との相違になる。

参考となる一次資料:

- [C# Task-based asynchronous pattern](https://learn.microsoft.com/en-us/dotnet/standard/asynchronous-programming-patterns/consuming-the-task-based-asynchronous-pattern)
- [Kotlin language specification: asynchronous programming with coroutines](https://kotlinlang.org/spec/asynchronous-programming-with-coroutines.html)
- [Rust Reference: await expressions](https://doc.rust-lang.org/reference/expressions/await-expr.html)
- [LLVM coroutine lowering](https://llvm.org/docs/Coroutines.html)

## 4. Continuationの最小状態

query block continuationはC stackを保存しない。再開に必要な明示状態だけを所有する。

```text
continuation
  state handle
  native program/block
  next op index
  source
  base path
  output/native block frame
  parent continuation + destination slot
  unresolved count
  pending slots[]
  resume state
```

pending slotはfieldごとの汎用resolve/reject CVを必須にしない。Houtou Ticketはslotへ直接値または
errorを格納できる。外部Promiseはadapter callbackから同じslotを更新する。

continuationはblock単位とする。sibling fieldが複数pendingでも、最後のslotがsettleした時だけ
block continuationをready queueへ一度積む。

## 5. 実行規則

### 5.1 通常実行

blockを同期loopで進める。plain valueとready Ticketは同期laneと同じcompletionを使用する。
blockが一度もsuspendしなければcontinuation、callback、deferredを作らない。

### 5.2 最初のpending

最初のpendingを検出した時点で、stack上のblock状態をheap continuationへ昇格する。現在までの
native outputを移し、pending fieldのdestination、path、completion metadataをslotへ保存する。

queryの残りのsibling opsは起動を続け、同じcontinuationへpending slotを追加する。これにより
GraphQL queryの並行性を維持する。mutation rootは既存どおり次のopを起動せず逐次再開する。

### 5.3 再開

pending slotのsettlementでは値の格納と`unresolved`の減算だけを行う。0になったcontinuationを
ready queueへ積み、drain側でcompletionを行う。subscriber callback内で再帰的にblockを
完走させない。

settled値をcompletionした結果、新しいpending child block/list itemが現れた場合は同じ
continuationを再度suspendできる。すべて同期ならsync loopへ戻り、そのままblockを完走する。

## 6. Ownershipと安全性

- continuationがsource、path、parent、output frameを明示的に所有する
- subscriberはcontinuation全体ではなくpending slotの安定した識別子を参照する
- slot配列の再配置後にraw pointerをsubscriberへ保持しない
- abandoned requestはexec stateからcontinuation treeを一括解放できる
- callback例外は現在のfield pathを持つerror outcomeへ変換する
- settle中のreentrancyではready queueへ積むだけとし、同じcontinuationを二重drainしない
- Promise/Ticketがself-resolutionまたは複数settleしてもslotを二重完成しない

request arenaはcontinuationの形と破棄規則が固まった後に導入する。最初の実装では既存の
refcountとframe poolを使い、性能差とownershipを独立に検証する。

## 7. 段階移行

1. sync/asyncで重複するop loopとresolve/completion境界をhelperへ抽出する
2. query rootで一度もpendingが出ないblockをsync loopで完走させる
3. root blockのpending field 1個をcontinuationとして中断・再開する
4. 複数sibling pendingをblock continuationへ集約する
5. resolved plain-hash objectのchild blockをsync loopで完走させる
6. object listのitem continuationを集約する
7. abstract、nested list、non-null propagationを新経路へ広げる
8. generic Promise adapterをTicket slotと同じ再開形式へ統合する
9. coverageと性能が揃った範囲から旧async frame処理を削除する
10. allocationが再び上位ならrequest arenaを導入する

各段階はfallback可能な独立PRとし、先に旧経路を削除しない。

## 8. 性能基準

比較対象は同じnative program、resolver、変数、出力形式を使う`strict_sync`とasync runtime。

- Promise/Ticketなしのasync runtime: sync比95%以上
- ready Ticket: sync比90%以上
- DataLoader dispatch 1回、その後同期child fields: sync比80%以上
- 対象workloadで最低5%改善
- generic Promise、repeated、primed、errorで2%以上の安定退行を出さない

width 1、10、20、100、unique/repeated/primed/cold、SV/JSONを測る。loader単体の改善だけでは
採用せず、GraphQL end-to-endを主指標にする。

## 9. ここまでの経緯

async高速化では、最初にPromise処理そのものとGraphQL executor内部のどちらが支配的かを
切り分けた。Promise::XSをTicketへ置き換える案、TicketをXS実装してPerl callback層をなくす案、
ready値を`AWAIT_IS_READY`/`AWAIT_GET`で同期取得する案を試した。

TicketはDataLoader内部のready cache entryには有効だった。一方、GraphQL request全体では
Ticket用のsubscription、settlement、Promise adapterと、既存Promise::XS経路の二系統を維持
する必要がある。Promise/Ticketの種類を変えるだけでは、async executorがrequest開始時から
作るexec state、frame、pending entry、callback、outcomeを除去できない。このためTicketを
request全体の非同期表現にする案は、性能差に対して実装・保守コストが大きいと判断した。

その後の計測で、同期resolverを含むasync runtimeも最初からasync executorへ入ることが主要な
固定費だと分かった。asyncとsyncの経路が異なる理由は、resolverがpending値を返した後も
source、path、出力先、次のopを保持する必要があるためである。ただし、その状態保持は実際に
pending値が現れるまで必要ない。ここから「async executorを軽量化する」より「sync executorを
開始点にして、pending時だけcontinuationへ昇格する」方針へ移った。

他言語処理系との比較では、この方式をHoutou固有の発明とは扱わないことにした。C#の完了済み
awaitable、Kotlinの`COROUTINE_SUSPENDED`、Rustの`Poll::Ready/Pending`、LLVM coroutineの
frame loweringと同型である。GraphQL固有の点はresolver call siteがsuspend候補だとcompile時に
分かっても、そのresolverがplain valueとPromiseのどちらを返すかはrequest時まで確定しない
ことである。したがってresolver call siteを動的なpromotion境界にする。

## 10. 現在までの実装

`perf/sync-first-continuation`ブランチでは、次の順番で実装した。

1. 本文書でsync-firstの状態遷移、ownership、段階移行を定義した。
2. fast lane stateへ`fast_lane_can_suspend`と`fast_lane_suspended_sv`を追加した。
3. Promiseを検出したresolverは、suspensionが許可されたlaneではPromiseの所有権をsuspension
   channelへ移し、block loopを安全にunwindできるようにした。strict sync laneのcroak動作は
   維持した。
4. settled値を受け取りresolverを再実行せずcompletionだけを行う
   `gql_runtime_vm_complete_resolved_current_fast_sv`を抽出した。
5. SV出力、rootが単一field、runtime directiveなし、nullableなgeneric leafという限定条件で
   root continuationを実装した。
6. Promiseが呼出し中にsettleする場合は完成したresponseを同期的に回収し、本当にpendingなら
   Promise callbackが保存したblock/op/slotからcompletionを再開するようにした。
7. resolve/reject callback、runtime、program、schema、root、context、prepared variablesの
   ownershipをmagic destructorへ集約した。

対応するコミットは次のとおり。

- `7a05e7f` `Document sync-first execution design`
- `a891f37` `Add fast lane suspension channel`
- `6170274` `Extract fast lane resume boundary`
- `4ca673a` `Resume pending root leaf fields`
- `94ce5ec` `Benchmark pre-resolved async leaves`

追加した回帰テストは、pre-resolved Promiseが同期responseになること、pending Promiseが
settle後にresponseへなること、suspend前とresume後を通じてresolverが一度しか呼ばれないことを
確認する。この時点で全486テストとXS ownership lintが通っていた。

8. GraphQL::HoutouはPSGI前提の同期Webアプリであり、Promise::XS/Ticketは実行時間の
   重畳ではなくDataLoaderバッチ解決のためだけに存在するという前提を踏まえ、汎用
   Promise::XSサポートより実際の主要トリガーであるDataLoader Ticketの統合を優先した
   (詳細は`docs/future-performance-investigation-ja.md`の§14.16)。
   `gql_runtime_vm_fast_lane_guard_promise_sv`にTicket認識を追加し、fulfilled/rejected
   なTicketはsuspension channelに触れず即座に値/errorへ展開する。genuinely pendingな
   Ticketのみ、Perlメソッド`then`経由ではなく`gql_runtime_vm_subscribe_dataloader_ticket`
   を直接呼ぶ経路へ合流させ、`Promise::XS::deferred()`を合成してAPI互換
   (`_settle_result`が見る`isa('Promise::XS::Promise')`契約)を保った。
9. 本節の次ステップ1に挙げていたresolve/reject継続ctxの共有を実施した。
   `gql_runtime_vm_pending_callback_ctx_t`と同じ`cv_refcnt`パターンを移植し、
   1 suspendあたりのctx確保を2回から1回(`newSVsv`は12回から6回)へ減らした。

追加した回帰テストは、単一root leaf fieldがfulfilled/pending/rejected Ticketをそれぞれ
返す3ケース、strict syncレーンでpending Ticketも引き続きactionableなcroakになること、
200回のpending Ticket駆動継続を連続実行してもframeがリークしないことを確認する。
現時点で全489テストとXS ownership lintが通る。

10. §13(旧稿)step 6として、settle callbackのresume経路を既存の汎用async executorの
    `block_frame_t` + scheduler(`enqueue_frame`/`drain`/`process_frame`/`resolve_frame`)
    へ委譲する試作を行った(詳細・計測値は`docs/future-performance-investigation-ja.md`
    §14.17)。正しさは検証できた(300件の独立したroot leaf継続が1回のDataLoader batch
    dispatchで一括settleするstress testも含めASanでクリーン)が、settleのたびに
    `exec_state_handle_t`/heap writer/block_frameを確保しnative_value_t経由の
    往復変換を追加するコストが、Promise::XS pre-resolvedケースで-7.0%、Ticket
    pending(on_stall経由)ケースで-2.6%の実測retreatとして現れた。「正しさの検証が
    目的」というPhase 2自身の位置づけに対して無視できない規模だったため、ユーザーの
    判断でこの試作は単独採用せず、複数sibling pending fieldへの拡張(旧稿の
    step 3-5、後述の複数siblingサポート)を実装する段階まで延期した。単一fieldの
    resumeはsettle_svによる直接構築(item 5-9の状態)へ戻している。副産物として
    見つかった`gql_runtime_vm_native_value_t`のUTF8フラグ欠落バグ(resolverが返した
    Unicode文字列がPromise/Ticket経由でこの型を通ると、rootリーフに限らず既存の
    汎用async executor全体でUTF8フラグが失われていた)の修正は、Phase 2の採否とは
    独立に価値があるため採用した。

11. §13(旧稿)step 3/5として、rootが複数のnullable scalar/enum leaf siblingを
    持つ場合への拡張を実装した(詳細は`docs/future-performance-investigation-ja.md`
    §14.18)。eligibility guardをop_count==1からop_count>=1へ緩和し、ブロック内の
    **全op**が既存の単一field条件を満たすことを要求、さらに「bundle上のop_countが
    native_program上のop_countと一致する」というblock単位のチェックを追加した
    (静的directiveでの部分的なop削除がbundle/native_program間のop_indexズレを
    起こしうるため)。suspendしたsiblingは既存の`GQL_VM_PENDING_PROMISE_(GENERIC|
    RESOLVED)_VALUE_SV`entryとしてpushし、最初のsuspend時にのみ実
    `exec_state_handle_t`/`block_frame_t`へ遅延promotionした上で、汎用async
    executor自身のroot frame finalizeが使っている`gql_runtime_vm_block_frame_finalize_sv`
    (arm前に`async_scheduler_draining`を立てる、という既存のreentrancy-safeな
    idiomを内包する)へそのまま委譲する設計とした。専用のctx/callback型は新設して
    いない。単一fieldの場合(Phase 2で退行が出た形)は引き続きitem 5-9の軽量な
    直接構築方式を使う。

    正しさは複数sibling同時pending・reject混在・pre-resolved Promise::XSと
    pending Ticketの混在(arm中の同期settleを経由)・50件の独立requestが1バッチで
    settle・non-null/directive/静的prune各fallback、で確認し、全492テスト・49
    ファイル個別実行でのASan(複数hash seed)がクリーン。全同期の場合は
    sync runtimeと完全に同速(sync-first原則は維持)。ただし、旧executorへの
    fallbackに対する測定可能な性能改善は確認できなかった(§14.18参照 —
    promotion時の`data_hv`→`native_value_t`一括変換コストが、fast laneでの
    安価な resolver 呼び出しの利益を相殺していると見られる)。ユーザーの判断で、
    正しさ・将来の最適化の土台としての価値を優先しこのまま採用した。

13. §13(旧稿)step 3として、§11で挙げたroot plain-leaf list field
    (`[String]`, `[Int!]`等、object/abstract itemを持たないもの)への拡張を
    実装した(詳細は`docs/future-performance-investigation-ja.md`§14.20)。
    eligibility guardへ`GQL_VM_COMPLETE_LIST`(かつ`abstract_child_count == 0`)
    を追加し、resolverが返したlist自体がpendingな場合(field-level、既存の
    Promise/Ticket suspension channelがそのまま扱う)に加えて、resolverが
    同期的にarrayを返したがitem内にPromise/genuinely pendingなTicketが
    混じっている場合(item-level、新規)も検出できるようにした。

    §11で記録したとおりfield-levelとitem-levelの分離はできない(resolverを
    二度呼ぶことになりexactly-once保証を破るため)。そのため、
    `gql_runtime_vm_complete_current_list_fast_sv`のitemループの前に
    `fast_lane_can_suspend`時のみ動くpre-scanを追加し、genuinely pendingな
    itemが1個でもあれば生のarray参照を新設フィールド
    `fast_lane_list_pending_source_sv`へ退避してitemのleaf coercionを
    一切行わずに返すようにした。呼び出し元のper-opループはこのフィールドを
    見て、既存の`gql_runtime_vm_exec_state_complete_current_native_async_sv`
    (Layer 1: item単位のsettle callback、Layer 2:
    `gql_runtime_vm_list_pending_handle_sv`によるitem集約)へ生のarrayを
    そのまま委譲し、item-level pending専用のロジックは新設していない。
    実`exec_state_handle_t`の構築(Phase 3ではloop終了後にのみ行っていた)は、
    field-level/item-levelどちらのpendingが先に判明してもloop内の最初に
    必要になった瞬間まで前倒しし、1回だけ構築して使い回す設計とした。

    正しさはgenuinely pendingなitemの単体・複数同時(同一バッチ)・sync
    siblingとの共存・field-level pendingとitem-level pendingの共存・item
    個別rejectがそのitemのみをnullにすること(§11相当の境界)・
    `[String!]`でのitem-level non-null違反・object list itemが引き続き
    旧経路へfallbackすること、で確認し、全494テスト(新規回帰6subtest追加)、
    200回のitem-level list pending promotionのリークストレスがクリーン。
    ただし、genuinely pendingなitemが実際に発生するケースでの旧executorへの
    fallbackに対する測定可能な性能改善は確認できなかった(Phase 3と同型の
    結末 — pendingがあれば結局同じ実handle+two-layer機構を構築するため)。
    改善が確認できたのは、DataLoader/Promiseを一切使わない全同期list
    resolverのケースで、Phase 4適用前はasync runtimeがLISTの
    unconditional ineligibleにより旧executor経由の固定費(-6〜7%)を
    払っていたのが、Phase 4適用後はsync runtimeとほぼ同速になった点のみ。
    ASanは当初この環境で`t/00_compile.t`自体が完了しない現象に遭遇したが、
    原因は`DYLD_INSERT_LIBRARIES`に指定していたnix store配下のASan
    ランタイムとこのmacOSバージョンの非互換(init中の自己デッドロック、
    詳細は`docs/future-performance-investigation-ja.md`§14.20)で、
    ビルドに使ったApple clangと同じツールチェイン由来のASanランタイムへ
    差し替えて解消した。差し替え後、49ファイル個別実行・`PERL_HASH_SEED`
    5点のフルスイープで全245実行がクリーンであることを確認した。

14. §13(旧稿)step 4として、object/abstract itemを持つroot list field
    (`benchmark_async_preresolved`が対象とする形)への拡張を実装した
    (詳細は`docs/future-performance-investigation-ja.md`§14.21)。対象は
    item自身のchild block(abstractなら取りうる全member block)が
    「flat」なもの(全fieldがGENERIC/plain-leaf LISTのみ、runtime
    directive無し、ただしnon-nullは許可)に限定し、item fieldがさらに
    object/abstractを持つ場合(2階層ネスト)はスコープ外として既存経路へ
    fallbackさせ続ける。

    調査で、item内で先に同期解決したsibling fieldがある状態で後続fieldが
    suspendすると、既存の`gql_runtime_vm_execute_block_fast_sv`(1つでも
    suspendしたらブロック全体を破棄してNULLを返す設計)をそのまま
    汎用executorへfallbackさせる形では、既に解決済みだったsibling
    resolverが二重に呼ばれてしまう(exactly-once違反)ことが判明した。
    ユーザーの判断で、正しい形(exactly-onceを完全に守る形)で実装する
    ことを選択した。

    Phase 3/4のroot専用sync-firstループ(`gql_runtime_vm_execute_root_block_fast_multi_sv`)
    を`parent_path_frame`引数付きの汎用版(`gql_runtime_vm_execute_block_fast_multi_sv`)
    へ一般化し、item自身のchild blockでも使えるようにした。item内で
    suspendが起きた場合、その場でitem専用のframeを
    `gql_runtime_vm_block_frame_finalize_sv`のmode 2(既存の汎用executor
    がper-item object dispatchで使っているのと同じモード)で即座に
    finalizeし、結果のPromise::XSを既存のLayer 2
    (`gql_runtime_vm_list_pending_handle_sv`)へそのまま渡す設計とした
    (Layer 1を新設する必要はない)。

    実装過程で、既存テストが検出した2件のバグ(一般化したループが
    `state->block/op/slot`等の保存・復元を欠いていた、field-level
    suspensionのpayload_kind選択が参照実装の`complete_code==GENERIC`
    チェックを欠いていた)と、手動検証で発見した1件のバグ(field-level
    suspension分岐がstate_svを構築しないため、item wrapperがNULL
    ハンドルでfinalizeを呼んでしまう)を修正した。正しさは全同期・
    item内でのsibling exactly-once(呼び出し回数で確認)・self_nulled
    (先にsuspendしたsiblingがある状態でのnon-null違反)・複数item
    同時suspend・abstract(union)item・ネストしたobject fieldの
    fallback、で確認し、全496テスト、200回のリークストレス、49ファイル
    個別実行・`PERL_HASH_SEED`5点でのASanがクリーン。genuinely pendingな
    itemが実際に発生するケースでの性能改善は確認できなかった(Phase 3/4
    と同型)一方、全同期object listのケースではasync runtimeの固定費
    (-14〜17%)が解消しsync runtimeとほぼ同速になった。

15. 本節item 14でスコープ外とした「item fieldがさらにobject/abstractを
    持つ場合(2階層以上のネスト)」への対応を実装した(詳細は
    `docs/future-performance-investigation-ja.md`§14.22)。調査の結果、
    object/abstract fieldの子selection set実行に使われていた
    `gql_runtime_vm_execute_child_block_fast_sv`は、item 14で作った
    安全なラッパー(`gql_runtime_vm_execute_list_item_child_block_fast_sv`、
    本節item 15で`gql_runtime_vm_execute_safe_child_block_fast_sv`へ
    改名)と全く同じ契約の薄いラッパーだったため、そのまま置き換えられた。
    かつ、この置き換え先の呼び出し元は当時のeligibility guardの下では
    到達不可能だったため、eligibility guardを緩和するまでは副作用ゼロの
    変更として先に着手できた。`gql_runtime_vm_fast_lane_list_item_block_is_eligible`
    を`depth`引数付きで自分自身を再帰呼び出しする形へ変更し
    (`GQL_VM_FAST_LANE_MAX_NESTING_DEPTH`=16の防御的な再帰深さ上限付き
    — 循環スキーマではなくスタック安全のため。blockはスキーマの型
    グラフでなくクエリdocumentのselection setツリーごとに生成されるため
    循環の心配は無い)、任意の深さのnestingへ対応した。

    実装過程で3件のバグを見つけて修正した: (1) 一般化したループの
    error_sv処理が`state->null_carries_error`を一度もセットしていなかった
    (item 14までnon-nullがdead codeだったため無害だったが、item/object
    child blockでliveになったことで二重エラーとして表面化、既存テストが
    検出)、(2) object/abstract field自身のcompletionが本物の
    `Promise::XS`を生成するケースを検出する手段が per-op ループに
    無かった(手動検証で生のPromise::XSオブジェクトがレスポンスに漏れる
    形で発覚、新しいpending entryチャンネルとして追加)、(3) その修正が
    `gql_runtime_vm_ensure_fast_lane_state_sv`の呼び出しを忘れており、
    block_frame_tがitemごとにリークするバグ(どのテストも検出せず、
    一時的なfprintfトレースで発見)。

    正しさは全同期2階層ネスト・2階層下のsuspendでitem自身のsiblingが
    二重呼び出しされないこと・真の3階層再帰・nested fieldのnon-null違反
    がそのfieldのみをnullにすること・abstractの途中混在・再帰深さ上限
    超過時の安全なfallback、で確認し、全498テスト、200回(item1つあたり
    3 frame)のリークストレス、49ファイル個別実行・ASanがクリーン。
    genuinely pendingなfieldが実際に発生するケースでの性能改善は確認
    できなかった(誤差程度、Phase 3/4/14と同型)一方、全同期2階層ネスト
    のケースではasync runtimeの固定費(-23%)が解消しsync runtimeと
    ほぼ同速になった。

16. §13(旧稿)item 5に残っていた最後の未着手項目「単一(list以外の)
    root object fieldへの対応」を実装した(詳細は
    `docs/future-performance-investigation-ja.md`§14.23)。root op
    eligibility loopが`complete_code`を`GENERIC`/`LIST`のみに制限して
    いたのを`OBJECT`/`ABSTRACT`も許可するよう緩和し、子blockを
    item 15の再帰eligibility関数で検証するだけで済んだ(実行側は
    item 14/15で既に汎用化済みのため無変更)。

    単一root object fieldが初めてfast lane経由でdeadlock/on_stall放棄
    シナリオに到達したことで、item 14/15の対応範囲では気づけなかった
    2つの既存バグが表面化した: (1) fast root continuationのmulti-op
    pathが返すgenuinely pendingなpromiseに、Perl側driverがdeadlock時に
    exec_stateの参照循環を断ち切るためのmagicが一度も付与されていな
    かった(item 13の複数sibling root path導入以来ずっと存在していた
    欠落)。(2) OBJECT/ABSTRACT fieldの子blockがsuspendした際に返す
    bridging Promise::XSへ、deadlock cancellationが辿り着けなかった。

    (2)の応急修正(bridging promiseへ子frameの生ポインタをmagicで
    付与)を入れた直後にベンチマークを取ったところ、item 13〜15とは
    異なり**明確な退行(-15〜20%)**が確認された。原因は、item 15の
    「子blockがsuspendしたら必ず新しいPromise::XSを1つ生成する」設計
    (list item集約向けには合理的)を、list item集約を必要としない
    単一fieldの文脈でも使ったため、1回のsuspendに2階層分の
    deferred/promise pairを積み重ねていたこと。汎用executorは元々、
    生のframe同士を直結する`GQL_VM_PENDING_BLOCK_FRAME_PTR`
    (`gql_runtime_vm_push_pending_block_frame`)という既存の軽量機構で
    同じ形を実現しており、Promise::XSを一切生成しない。ユーザーの
    判断で退行を許容せず、`gql_runtime_vm_execute_safe_child_block_fast_sv`
    に`want_promise`引数を追加し、list item呼び出し箇所のみPromise::XS
    生成モードを残し、それ以外の全呼び出し箇所(root含む)を生の
    block-frame handleモードへ切り替える再設計を同じフェーズ内で実施。
    これにより(2)の応急修正(magic付与)は不要になり削除した
    (`GQL_VM_PENDING_BLOCK_FRAME_PTR`は`cancel_frame_tree`が既に
    正しく辿れるため)。

    再設計の実装中、新チャンネルの`gql_runtime_vm_ensure_fast_lane_state_sv`
    呼び出しを条件分岐の中だけに置いてしまうitem 15のバグ(3)と全く
    同型の失敗を再び埋め込み、2階層ネストの初回リクエストで即座に
    Perlレベルの破損エラーとして検出、fprintfトレースで特定・修正した。

    退行は再設計で完全に解消し(suspendケースは旧executor比100〜101%、
    退行も改善もなし)、全同期ケースの固定費解消(+21〜24%)は維持
    された。全500テスト、200回のリークストレス、49ファイル個別実行・
    ASan(応急修正版・再設計版どちらも)がクリーン。`GQL_VM_PENDING_LIST_PENDING_PTR`
    (list fieldの複数item集約ハンドル)に対する同種のdeadlock
    cancellation未対応は、今回の対応範囲外として記録した。

17. Perl呼び出し境界の高速パス化(item 16直後のコミット、
    `gql_runtime_vm_call_ticket_callback`がPromise::XS/Ticket用の
    resolve/reject callbackを呼ぶ際、既知の自前XS関数であることを
    `CvXSUB(cv)`の関数ポインタ比較で検出し、`call_sv`のPerl汎用呼び出し
    規約を丸ごとスキップする)では、suspendケースが増やす約6箇所の
    Perl呼び出し境界のうち1箇所しか対象にできず、ベンチマークでは
    測定誤差の範囲を超える改善を確認できなかった。

    そこでsample(macOS標準CPUサンプリングプロファイラ)でsuspendケースを
    全同期ケースと比較し内訳分解したところ、「scheduler自体の構築・
    drain」(exec_state_handle_t/block_frame_t/Promise::XS)が約2.5
    tick/1kと最小カテゴリだった一方、その中核である**応答用Promise::XS
    の生成・`.then()`登録・同期解決の往復**は、on_stallで同期的に
    完結するPSGIアプリでは「真の非同期」に一切使われておらず、単に
    C↔Perl間の値受け渡し手段として使われているだけと判明した。
    on_stallのドライブ(`_settle_result`、`NativeRuntime.pm`)自体を
    Perl側からC側へ移し、この往復を丸ごと省く、より抜本的な変更に
    着手した(詳細は`docs/future-performance-investigation-ja.md`
    §14.24)。

    `gql_runtime_vm_block_frame_finalize_sv`に「応答フレームであっても
    Promise::XSを一切作らない」モード3を追加(既存の`completed_response_sv`
    直接stash分岐を再利用)。fast lane(item 11〜16が広げてきたeligibility)
    が対象shapeを扱える場合、on_stallをC側から`G_EVAL`付きで直接呼ぶ
    駆動ループ(`gql_runtime_vm_drive_with_on_stall_sv`)がこのモード3の
    frameを完了まで駆動し、Promise::XSを一度も生成しない。fast laneが
    対象外のshape(runtime directives・再帰深さ上限超過・json_mode)は
    従来のgeneric executor+`_settle_result`のまま。Phase 2由来の単一op
    直接resumeショートカットは、この新機構を知らない独自の軽量継続
    (別のPromise::XS経路)を持つため、on_stallのC駆動時は常にスキップ
    してmulti-opパスを使う設計にした。

    検証中に2つの既存バグ(Phase 8由来の退行ではなく、Phase 8以前の
    ビルドでも同じシナリオで同じ個数が再現することを確認済み)を発見:
    (1) `_settle_result`はon_stallが「進捗0を返す」場合のみ`cancel_pending_response_xs`
    を呼んでおり、on_stall自身が`die`すると呼び出し式から直接die が
    飛び出しcancel漏れとなる(単純なPromise::XSがpendingな場合、
    Phase 8の新経路はこれを解消する)。(2) ただしDataLoaderの`Ticket`
    がpendingな場合は、Ticket自身のsubscriberリストがDataLoaderの
    `_queue`経由で生き続けるため、同じcancelでも3 frame相当のリークが
    残る(未修正、今後の課題として記録)。

    `t/59_on_stall_native_drive.t`を新規追加(全同期・DataLoaderネスト
    suspend・resolver/batch/on_stall die・stall検出・複数loader・200回
    リークストレス・上記2件の既知バグを固定するsubtest)。全510テスト、
    50ファイル個別実行・ASanがクリーン。ベンチマーク(`async_single_root_object_field`、
    複数回計測)でsuspendケースが**+20〜25%改善**(旧executor比
    106,103〜108,195 req/sからPhase 8の127,099〜132,923 req/sへ)し、
    Phase 3〜7で続いていた「suspendケースは改善なし」という結末を
    初めて破った。ただし`async_nested_object_list_item_field`
    (item数2/5/10)で見ると、item数が増えるほど改善幅は縮小し
    (+11%→+2.7%→-3%、誤差程度)、Phase 8が削減するのはリクエスト
    あたり固定のコストであり、item数が増えるとitemごとの決着コストが
    支配的になるため相対的寄与が薄まるという解釈で一貫している。

18. item 17末尾のwide list fan-out縮小を`sample`で調査した(詳細は
    `docs/future-performance-investigation-ja.md` §14.25)。width 2/5/10
    でasync/sync比がほぼ一定(41〜43%)と分かり、固定cost(≈4µs)+
    item毎cost(≈2.3µs)の線形分解で説明できる、正常なスケーリングだと
    確認した。item毎costの対策としてDataLoader::Ticket表現の再設計と
    field単位のバッチresolver API(`resolve_many`)を検討したが、前者は
    §14.10/14.12で既に試作・却下済みの再挑戦になり、後者はGraphQL
    エコシステムに前例がなくDataLoaderと概念が重複するため、どちらも
    見送った。

    代わりに「resolverをN回呼ぶこと自体の効率化」を検討し、引数を持つ
    resolverが`call_cb5_nonfatal`の5番目の引数として`$info`を毎回
    新規構築している(`$info`を一度も参照しない場合でも)ことを特定
    した。3個の内部文字列(`field_name_pv`等)はコンパイル済みnative
    programから常に借用しているだけと確認し複製をやめ、
    `gql_runtime_vm_lazy_info_t`構造体自体を既存のblock_frame/
    path_frame/outcome/native_valueと同じ形でpool化した(blessed
    handle SV自体はresolverが保持し続ける可能性があるためpool化せず、
    構造体だけをpool化)。git worktreeでの前後比較(インターリーブ4回)
    で引数ありresolverが平均46,776→50,023 req/sへ**約+7%**改善し、
    全4回で同じ向きだった。引数なしresolverには影響しない、Phase 3〜9
    と同じ「1桁%クラス」の改善で、抜本的な改善ではない。

19. item 17末尾で今後の課題として残した2件(DataLoader Ticketが
    genuinely pendingなままキャンセルされるとリークする件と、fast lane
    非対応shapeのfallbackがPhase 8の恩恵を受けない件)にPhase 9として
    対応した(詳細は`docs/future-performance-investigation-ja.md`
    §14.26)。

    リークの方は、`gql_runtime_vm_cancel_frame_tree`がpending entryの
    `armed_resolve_ctx`を一切見ていなかったことが原因。新設した
    `gql_runtime_vm_pending_callback_ctx_disarm`(通常決着時の
    `pending_callback_pair_recycle`と同じ`state_sv`/`frame`参照破棄を
    行うが、CVペアをプールへ戻さない版)を`cancel_frame_tree`から呼ぶ
    ようにした。CVをプールへ戻さない理由は、キャンセル後もTicket自体は
    DataLoaderの`_queue`から参照が続く可能性があり、後で万一dispatch
    されると同じCVが発火してしまうため - プールに戻していると
    無関係な別リクエストがそのCVを再利用している可能性があり被害が
    及ぶ。`t/59_on_stall_native_drive.t`末尾の「既知のリークとして
    固定した」2 subtestを、他と同じ0/0を要求する形に書き換えた。

    fallbackの方は、generic executor自体(`exec_state_execute_block_async_path_sv`)
    には手を入れず、それが返す本物のPromise::XSを`gql_runtime_vm_drive_promise_with_on_stall_sv`
    がC側で`.then()`登録して駆動する形にした。generic executorは複数の
    呼び出し元に共有されており、`finalize_sv`のモード3をそこまで通す
    変更は対象範囲の狭さに対してリスクが大きいと判断したため。
    ベンチマーク(`async_fallback_runtime_directive`)では誤差の範囲内
    (112,065〜116,693 req/sで前後差なし)で、Phase 3〜7と同じ「改善
    なしだが正しさ・保守性の観点で妥当」という結果だった - generic
    executor自体のコストが支配的で、外側のPromise::XS往復を削っても
    寄与が薄いというPhase 8の考察と整合する。

    開発中、ローカルASan(Apple clang由来のランタイムを
    `DYLD_INSERT_LIBRARIES`で明示指定)で実際のheap-use-after-freeを
    発見・修正した: settle-capture ctxをresolve/reject CVペアの
    refcountだけで共有していたところ、Promise::XSがarmを発火させた
    直後に両方のCV参照を一括解放する実装のため、駆動ループ自身が
    まだ`ctx->settled`を読もうとしている最中にctxが破棄されていた。
    ctxのrefcountに駆動ループ自身の持ち分を追加(CV2つ+呼び出し元1の
    3口に)し、読み終えた後に明示的に解放するよう修正した。
    この不具合はheap allocatorのレイアウト依存で発現有無が変わり、
    `minil test`(50ファイルをそれぞれ独立プロセスで実行)では毎回
    再現するのに、単発の`perl`/`prove`実行では再現しない、という
    形で最初に気づいた。

20. 「async経路は調査し尽くした」という結論に対しユーザーから具体的な
    再検証を受け、Phase 7(item 16)がobject/abstract child fieldに
    導入した「Promise::XSを作らない生frame直結」がlist itemにだけ
    適用されていない点を確認し、Phase 11として拡張した(詳細は
    `docs/future-performance-investigation-ja.md` §14.27)。list item
    呼び出し箇所を`want_promise=0`に変更し、`list_pending_t`へ
    `pending_child_frames[]`を追加、`block_frame_t`へ`parent_list_pending`/
    `parent_list_index`(既存の`parent_frame`と排他的な別種の親)を追加、
    `resolve_frame`と`cancel_frame_tree`の両方に対応する分岐を追加した。

    開発中、`t/54_frame_leak_regression.t`の`debug_frame_live_counts_xs()`
    カウンタ(ASanではなく)で2件の実リークを発見・修正した。どちらも
    「child frameが持つべき2つの参照(link自身の分+creation分)のうち
    1つしか解放していない」という同じ形の見落としで、既存の
    `parent_frame`分岐(`store_outcome_ptr`内で1回・末尾で1回、計2回
    `free_block_frame`を呼ぶ)や`BLOCK_FRAME_PTR`のcancel処理
    (`clear_pending`自身の処理から2回目をタダで得られる)と同じ構造を
    見落としていた。

    計測で一度誤りを報告した: 最初`git worktree`比較なしに単発実行を
    セッション前半の数値と単純比較し「+40%超」と報告したが、これは
    Phase 10自身が確立した「別プロセス起動を交互に行い環境ドリフトを
    抑える」手法を怠った結果だった。正しくインターリーブして再測定
    すると、`async_nested_object_list_item_field`のwidth=10で前後差なし
    (誤差範囲内)。`sample`で確認すると、適用前のビルドですら
    `Promise::XS`関連関数はプロファイルにほぼ出現せず、除去した
    仕組みはこのbenchmark shapeで元々コストの小さい部分だったと分かった。
    Phase 9のfallback駆動化と同じ「正しさの面では妥当だが測定可能な
    改善なし」という結果で、correctness面の価値を理由に採用した。

## 11. 試行から分かった境界条件

root fieldが1個で`child_block_index == -1`という条件だけでは、leaf continuationとして安全では
ない。listはchild blockを持たなくても、各itemがPromiseの場合やabstract item completionを
持つ場合がある。最初の試作でlistまで同じ経路へ入れたところ、Star Wars/DataLoaderとunion
searchのitemがnullになり、batchも起動しなかった。

この退行は、root resolverのPromiseがsettleしたことと、その戻り値のlist全体が同期completion
可能であることを同一視したために起きた。list内のpending itemは新しいsuspension pointであり、
root continuationからitem continuationまたは既存async schedulerへ部分昇格する必要がある。
現在は`complete_code == GQL_VM_COMPLETE_GENERIC`へ限定してlistを従来経路へfallbackしている。

もう一つの境界はpre-resolved Promiseである。Promise::XSの`then`はcallbackをその場で実行しても
derived Promiseを返す。そのderived Promiseをそのままpublic APIへ返すと、従来はHashRefだった
pre-resolved requestがPromiseへ変わる。callback pairと共有する小さなsettlement stateを使い、
`then`登録中にresponseまで完成した場合はderived Promiseを破棄して同期responseを返すことで
API互換を維持した。

## 12. 現在の性能

既存の`async_preresolved`はrootがobject listなので、現在の限定continuationには入らない。
計測値は次のとおりで、変更前とほぼ同等である。

```text
async items SV   27.9k/s
async SV         64.5k/s
async JSON       66.0k/s
sync JSON        96.8k/s
sync SV         101.2k/s
```

root leaf専用の`async_preresolved_leaf` benchmarkを追加した。変数を使うresolverが
pre-resolved Promise::XSを返すcaseである。

```text
async leaf SV   274.9k/s
sync leaf SV    414.4k/s
```

現在のasync leafはsync leafの約66%である。汎用async exec stateを作らずに正しく
suspend/resumeできる足場はできたが、sync同等という目標には未到達である。残る固定費の候補は
Promise::XSの`then`、resolve/reject CV、continuation contextと所有SVの割当である。

Ticket統合(本節8, 9)後の5標本中央値は次のとおり(詳細は
`docs/future-performance-investigation-ja.md`の§14.16)。

```text
sync leaf                      412.9k/s (100%)
async leaf (Promise::XS, 既存)  277.7k/s (67.3%)
async leaf (Ticket ready, 新規) 321.5k/s (77.9%)
async leaf (Ticket pending, 新規, on_stall経由) 139.5k/s (33.8%)
```

Ticket readyはPromise::XS pre-resolvedに対して約+15.8%改善した。Promise::XSの`then()`が
既に決着したpromiseに対しても呼び出しごとにderived promise objectを生成するのに対し、
fulfilled Ticketの認識はsuspension channelにもderived objectにも触れず値を直接返すためである。

## 13. 次に進める順序

1. ~~resolve/rejectが別々に保持しているroot continuation contextを共有し、所有SVのrefcount操作と
   heap allocationを減らす。~~ 実施済み(本節9)。
2. leaf benchmarkをallocation profileと合わせて測り、Promise::XS自体の下限とHoutou側の固定費を
   分離する。
3. ~~settled root listを走査し、全itemがplainならfast completion、pending itemが1個でもあれば
   item continuationまたは既存async schedulerへ部分昇格する境界を作る。~~ **plain leaf list
   (object/abstract item除く)に限定して実施済み**(本節item 13)。
4. ~~`async_preresolved`のroot object listへ適用し、sync比と旧async比を測る。~~
   **item自身のchild blockがflat(runtime directive無し)なものに限定して
   実施済み**(本節item 14)。**item fieldが持つ2階層以上の
   object/abstractネストも本節item 15で対応済み**(任意の深さ、防御的な
   再帰深さ上限16付き)。
5. ~~nullable leaf/listでownershipが固まってからnon-null propagation、runtime directives、
   object child block、複数root siblingへ対象を広げる。~~ **複数root siblingは実施済み**
   (leafに限定、本節item 11)。**非rootのnon-null propagationはitem自身の
   field(任意の深さ)に限りitem 14/15で実施済み**(runtime directivesは
   引き続き未着手、混在時はfallback)。**単一(list以外の)root object field
   への対応も本節item 16で実施済み**(deadlock cancellationの2つの既存
   バグを発見・修正し、退行を許容せずPromise::XSブリッジの再設計まで
   実施した上での完了)。
6. ~~Promise callback内でcompletionを再帰実行する形はroot単一fieldに限定し、複数siblingへ
   広げる段階ではready queueへ統合してreentrancyを防ぐ。~~ 実施済み(本節item 10で単独試作、
   item 11で複数sibling実装に組み込んだ形で採用)。

GraphQL::HoutouはPSGI前提の同期Webアプリで、実際にsuspendが起きる主因はDataLoader
バッチ解決(Ticket)であり、任意のresolverが返す汎用Promise::XSは相対的に稀なケースである。
そのため上記の順序に加えて、DataLoader Ticketの認識・直接subscribe・継続ctx統合(本節8, 9)を
先行させた。

6は単独で試作・計測した段階(本節item 10、詳細は`docs/future-performance-investigation-ja.md`
§14.17)では、settleごとの`exec_state_handle_t`/heap writer/block_frame確保と
native_value_t往復変換のコストがPromise::XS pre-resolvedで-7.0%、Ticket pendingで-2.6%の
実測retreatとなり、単独採用するには重すぎると判断して延期した。宣言通り、5(複数root
sibling、leafに限定)を実装する段階(本節item 11)で6のblock_frame_t/scheduler委譲を
組み込んだところ、全同期ケースはsync runtimeと完全に同速(退行なし)だったが、
suspendが起きるケースでも旧executorへのfallバックに対する**測定可能な改善は
確認できなかった**(§14.18)。1つの`block_frame_t`確保コストをsibling数で償却できる
という見込みは外れ、promotion時の`data_hv`→`native_value_t`一括変換コストが
fast laneでの安価なresolver呼び出しの利益を相殺していると見られる。ユーザーの
判断で、正しさ・将来の最適化の土台としての価値を優先しこのまま採用した。

次に性能改善を狙うなら、`data_hv`を経由したPerl SVの一括変換をなくし、fast lane
ループ中に解決済みsiblingを直接`native_value_t`へ書き込む設計へ作り直す必要がある。

12. 上記の宿題を実施した(詳細は`docs/future-performance-investigation-ja.md`
    §14.19)。ブロックループの返り値を`data_hv`のRVから、呼び出し側が確保した
    `SV **resolved_values`配列(op位置でindexし、解決済みの値を直接格納)へ変更。
    `frame`が作られなかった(全同期)場合のみループ後に`data_hv`を組み立て、
    `frame`が作られた場合はdata_hvを一切経由せず`resolved_values[]`から直接
    `frame->values_value`へ書き込む(plan所有のフィールド名をborrowedで渡すため、
    従来`gql_runtime_vm_native_value_from_sv`が行っていた名前の二重コピーも
    なくなった)。5標本中央値で、旧executorへのfallback比 width 5で+2.1%、
    width 10で+1.6%の改善を確認(width 2はほぼ横ばい)。全492テスト、ASan
    (49ファイル個別実行・複数hash seed)、unicode文字列siblingのUTF8保持、
    promotionありなしを混ぜた1000回のリーク検証で確認済み。

13. 3の宿題を、object/abstract itemを持たないplain leaf listに限定して実施した
    (詳細は`docs/future-performance-investigation-ja.md`§14.20、本節item 13)。
    genuinely pendingなitemが実際に発生するケースでの旧executorへのfallbackに
    対する測定可能な性能改善は確認できなかった(6と同型の結末)一方、
    DataLoader/Promiseを一切使わない全同期list resolverでは、async runtimeが
    従来LISTを問答無用でfallbackしていた分の固定費(-6〜7%)が解消し、sync
    runtimeとほぼ同速になった。object/abstract itemを持つlist(4)は引き続き
    スコープ外。

旧async executorはfallbackとして残す。対象shapeが明示的に判定でき、correctnessと性能の両方を
満たした範囲だけをsync-first経路へ移す。
