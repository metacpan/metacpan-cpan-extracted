# Getopt::EX::Config Migration MCP Server

PerlスクリプトのGetopt::EX::Config移行を支援するMCPサーバーです。

## 概要

このMCPサーバーは、従来のGetopt::LongやGetopt::EXを使用したPerlコードを、より現代的なGetopt::EX::Config形式に移行するための自動化支援ツールです。

## 機能

### 1. コード解析 (`analyze_getopt_usage`)

Perlコードを解析し、移行に必要な情報を抽出します。

**検出項目:**
- use文の種類（Getopt::Long、Getopt::EX、Getopt::EX::Config）
- GetOptions呼び出しパターンと詳細なオプション仕様解析
- 既存のset/setopt関数
- %optハッシュの使用状況
- **オプション分類:**
  - モジュール固有オプション（移行に適している可能性が高い）
  - コマンド共通オプション（help、versionなど - 競合の可能性）
  - 曖昧なオプション（手動レビューが必要）
- 変数マッピングとオプション型
- 移行の複雑度評価

**出力例:**
```
=== 現状分析 ===
🟡 移行難易度: 中程度
✓ Getopt::Longを使用中
✓ 既存のset/setopt関数を検出
✓ GetOptions呼び出しを1箇所で検出
🎯 モジュール固有オプション: 2個 (debug, width)
⚠ コマンド共通オプション: 1個 (help)
❓ 曖昧なオプション: 1個 (name)

=== 移行手順 ===
1. use文の変更:
   use Getopt::EX::Config qw(config set);

2. 設定オブジェクトの作成:
   my $config = Getopt::EX::Config->new(
       # モジュール固有オプションのデフォルト値
       debug => 0,
       width => 80,
   );
```

### 2. 移行コード生成 (`suggest_config_migration`)

現在のPerlコードを基に、Getopt::EX::Config形式への移行コード例を自動生成します。

**生成される内容:**
- 適切なuse文
- オプション型に基づくインテリジェントなデフォルト値を持つConfigオブジェクト
- モジュール固有オプションを対象としたfinalize関数の実装
- 型に基づいたデフォルト値の推測（文字列、整数、真偽値、配列、ハッシュ）
- **コマンド共通オプションについての競合警告**
- **段階的移行の推奨事項**

**生成例:**
```perl
# Getopt::EX::Config移行版
use Getopt::EX::Config qw(config set);

my $config = Getopt::EX::Config->new(
    # モジュール固有オプションのデフォルト値
    debug => 0,
    width => 80,
);

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with($argv,
        # モジュール固有オプションのみ:
        "debug!",
        "width=i",
    );
}

# ⚠ 注意: 'help'オプションはコマンドレベルのhelpとの競合を避けるため除外
```

### 3. 移行パターン集 (`show_migration_patterns`)

一般的な移行パターンとベストプラクティスを表示します。

**含まれる内容:**
- 基本的な移行パターン
- 設定方法の選択肢
- Boolean値の扱い
- 成功事例
- よくある注意点

### 4. 段階的移行計画 (`generate_staged_migration_plan`)

リスク許容度とコードの複雑さに基づいて、ステップバイステップの移行計画を生成します。

**リスクレベル:**
- **Conservative（保守的）**: 段階的移行による最小限のリスクアプローチ
- **Moderate（中程度）**: バランス型アプローチ（推奨）
- **Aggressive（積極的）**: 効率的な完全置換

**計画の特徴:**
- オプション解析に基づくリスク評価
- 段階的な移行フェーズ
- 競合解決戦略
- テストチェックポイント
- コマンド共通オプションの特別対応

## 使用方法

### Claude Codeでの使用

Claude Codeが自動的にMCPツールを認識し、適切なタイミングで呼び出します。

```
ユーザー: "このPerlファイルをGetopt::EX::Configに移行したい"
↓
Claude Code が自動的に analyze_getopt_usage を呼び出し
↓ 
移行ガイダンスと具体的なコード例を提供
```

### スタンドアロンでの使用

```bash
# MCPサーバーとして起動
python3 getopt_ex_migrator.py

# JSON-RPCプロトコルで通信
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "analyze_getopt_usage", "arguments": {"file_content": "use Getopt::Long;..."}}}' | python3 getopt_ex_migrator.py
```

## 技術仕様

### 依存関係

```python
# 必要なPythonパッケージ
from mcp.server import Server
from mcp.types import Tool, TextContent
```

### 解析エンジン

高度な正規表現ベースのパターンマッチングにより、以下のPerlコード要素を検出：

- `use Getopt::Long`（qw()インポートを含む）
- `use Getopt::EX`（qw()インポートを含む）
- `use Getopt::EX::Config`
- `GetOptions()` / `GetOptionsFromArray()` と詳細なオプション解析
- 型検出機能付きオプション仕様（文字列、整数、真偽値、配列、ハッシュ）
- 変数マッピング（`"option" => \$variable`）
- `sub set` / `sub setopt`
- `$config->deal_with()`
- `%opt` ハッシュの使用パターン
- **競合検出のためのオプション分類パターン**

### 複雑度評価

移行の複雑さを以下の基準で評価：

- 🟢 **簡単** (score ≤ 2): 基本的なGetOptions使用
- 🟡 **中程度** (score ≤ 4): set関数や複数オプションあり
- 🔴 **複雑** (score ≥ 5): 多数のオプション、複雑な構造、またはモジュール固有オプションが多い

**追加要因:**
- 検出されたモジュール固有オプションの数
- コマンド共通オプションの存在（競合リスクを増加）
- 複数行にまたがる複雑なGetOptions呼び出し
- 様々な型を持つ複数のオプション仕様

## 主要機能

### アンダースコア-ダッシュ変換対応

Getopt::EX::Configの`$REPLACE_UNDERSCORE`機能に対応し、オプション名のアンダースコア（`long_lc`）がダッシュ（`--long-lc`）にも自動対応することを説明に含めます。

### 後方互換性の説明

移行後も既存の`::set`記法が継続利用可能であることを明記し、段階的な移行をサポートします。

### 実例ベースのガイダンス

App::Greple::pwなど実際の移行成功例を参考として提供し、実用的なガイダンスを提供します。

## 実用例

### 移行前のコード（従来のモジュール設定）

```perl
package App::Greple::example;

our %opt = (
    debug => 0,
    width => 80,
    color => 'auto',
);

sub set {
    my %arg = @_;
    while (my($key, $val) = each %arg) {
        $opt{$key} = $val;
    }
}

# モジュール全体で設定を使用
sub process {
    print "Debug mode\n" if $opt{debug};
    format_output($opt{width});
}
```

### 移行後のコード（Getopt::EX::Config）

```perl
package App::Greple::example;
use Getopt::EX::Config qw(config set);

my $config = Getopt::EX::Config->new(
    debug => 0,
    width => 80,
    color => 'auto',
);

sub finalize {
    our($mod, $argv) = @_;
    $config->deal_with($argv,
        "debug!",
        "width=i", 
        "color=s",
    );
}

# モジュール全体で設定を使用
sub process {
    print "Debug mode\n" if $config->{debug};
    format_output($config->{width});
}
```

### モジュール設定方法

```bash
# 従来方式（::set関数）
myapp -Mmodule::set=debug=1,width=120

# Configインターフェース方式
myapp -Mmodule::config=debug=1,width=120

# モジュール専用オプション（deal_with実装が必要）
myapp -Mmodule --debug --width=120 -- 通常の引数
```

**重要なポイント:** この移行は純粋に**モジュール内部の設定**に関するものです。モジュールはユーザーがその動作を設定する方法がより柔軟になり、後方互換性も保持されます。

## エラーハンドリング

- 空のファイル内容に対する適切なエラーメッセージ
- 未知のツール名に対するエラー処理
- 解析エラー時の詳細な例外情報

## 開発・テスト

### テスト実行

```bash
# 基本機能テスト
python3 -c "
import sys; sys.path.append('.')
from getopt_ex_migrator import GetoptAnalyzer, MigrationGuide
analyzer = GetoptAnalyzer()
result = analyzer.analyze_code('use Getopt::Long;')
print('✓ Test passed' if result['use_getopt_long'] else '✗ Test failed')
"
```

### 実際の移行事例

このMCPサーバーは、`Getopt-EX-i18n`モジュールの`lib/Getopt/EX/i18n.pm`ファイルの移行で実際に使用され、成功しています。

## ライセンス

このMCPサーバーは、Getopt::EX::Configと同じライセンス条件の下で提供されます。

## 貢献

バグ報告や機能追加の提案は、プロジェクトのIssueとして報告してください。

---

*このMCPサーバーにより、PerlモジュールのGetopt::EX::Config移行が大幅に簡素化され、一貫した品質の移行が可能になります。*