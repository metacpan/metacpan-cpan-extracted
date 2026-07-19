# Module Map

この文書は、`lib/GraphQL/Houtou` 配下の現行 mainline を、責務ごとに短く把握するための索引です。

## Public Surface

- `GraphQL::Houtou`
  - 最小の公開入口
  - `parse`
  - `parse_with_options`
  - `execute`
  - `execute_native`
- `GraphQL::Houtou::Schema`
  - schema root object
  - runtime graph / program / native bundle の compile 入口
- `GraphQL::Houtou::Validation`
  - validation の最小 facade
  - 公開面は `validate` のみ
- `GraphQL::Houtou::XS::VM`
  - bootstrapped native bundle / native runtime の低レベル entrypoints

判断:

- `Validation` は public に残す
- `Native` も public に残す
- ただし両方とも facade の面積はこれ以上広げない

## Runtime Mainline

- `GraphQL::Houtou::Runtime::SchemaGraph`
  - boot-time compiled schema graph
  - root block / slot catalog / dispatch index の owner
  - program compile / descriptor emit / public `execute_program` entrypoint の owner
  - public `inflate_program` は `NativeProgram` handle を返す
- `GraphQL::Houtou::Runtime::OperationCompiler`
  - document から `VMProgram` を lower する
- `GraphQL::Houtou::Runtime::VMCompiler`
  - lowered `VMProgram` の lower / inflate
  - public mainline ではなく internal inflate/debug 用
  - native compact struct 自体の owner ではない
- `GraphQL::Houtou::Runtime::NativeRuntime`
  - native specialization と native execute の owner
  - execution lane selection と native fast path 実行の owner
- `GraphQL::Houtou::Runtime::ExecState`
  - promise/runtime path の thin facade
  - active path は `NativeProgram` 前提
  - Perl 側に残すのは `new/build_for_program/run_program` の最小 surface

## Runtime State Objects

以下は Perl module file ではなく、XS が提供する opaque handle package です。

- `Cursor`
  - 現在の block / op / slot
  - XS opaque handle
- `BlockFrame`
  - block-local result and pending state
  - XS opaque handle
- `FieldFrame`
  - field-local execution state
  - XS opaque handle
- `Outcome`
  - kind-first のランタイムオブジェクト
  - XS opaque handle
- `Writer`
  - outcome から response payload を構築
  - XS opaque handle
- `LazyInfo`
  - info の lazy materialization
- `PathFrame`
  - path の lazy materialization
  - XS opaque handle
- `ErrorRecord`
  - error payload の record
- `InputCoercion`
  - active path の variable preparation facade
  - coercion loop 自体は `native_program_prepare_variables_xs(...)` が owner

## Runtime Artifacts

- `SchemaBlock`
  - schema graph 側 block
- `Slot`
  - field metadata / dispatch metadata
- `VMProgram`
  - lowered program
- `VMBlock`
  - lowered block
- `VMOp`
  - lowered op

判断:

- `VMProgram` / `VMBlock` / `VMOp` / `Slot` は internal lowering / inflate / debug 用
- public / active runtime path は `NativeProgram` を一次通貨に使う

## Type System

- `GraphQL::Houtou::Type`
  - type base
- `Type::Object`
- `Type::Interface`
- `Type::Union`
- `Type::InputObject`
- `Type::Scalar`
- `Type::Enum`
- `Type::List`
- `Type::NonNull`
- `Directive`
- `Introspection`

補助:

- `GraphQL::Houtou::Internal::TypeSupport`
  - type constructor helper
- `GraphQL::Houtou::Role::*`
  - marker role と最小 helper

## Parser Internals

parser compatibility は mainline 要件ではありませんが、最小 parser surface を支える内部実装は残しています。

- `GraphQL::Houtou::XS::Parser`
  - parser XS facade と lazy helper の Perl 側補助
- `src/parser_ast_runtime.h`
  - AST runtime helper
- `src/parser_ir_runtime.h`
  - IR materialization helper
- `src/parser_graphqlperl_runtime.h`
  - graphql-perl dialect parser runtime
- `src/parser_shared_ast.h`
  - shared AST helper

判断:

- parser compatibility は mainline 要件ではない
- ただし parser public surface 自体は残す
- したがって parser internals は削除対象ではなく、runtime mainline から切り離して維持する

## 関連文書

- 全体のデータフロー: `architecture-overview.md`
- opcode と実データ layout: `vm-internals-ja.md`
- parser内部: `parser-internals.md`
