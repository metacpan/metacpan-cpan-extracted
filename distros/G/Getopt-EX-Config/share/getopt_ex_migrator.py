#!/usr/bin/env python3
"""
Getopt::EX::Config Migration MCP Server
Perlスクリプトの Getopt::EX::Config 移行を支援するMCPサーバー
"""

import asyncio
import json
import re
from typing import Dict, List, Any, Optional
from mcp.server import Server
from mcp.types import Tool, TextContent, Resource
import argparse
import sys


class GetoptAnalyzer:
    """Perlコードのgetoptパターンを解析するクラス"""
    
    def __init__(self):
        self.patterns = {
            'use_getopt_long': r'use\s+Getopt::Long\b',
            'use_getopt_ex': r'use\s+Getopt::EX(?:::(?!Config)|\b)',
            'use_getopt_ex_config': r'use\s+Getopt::EX::Config\b',
            'set_function': r'sub\s+set\s*\{',
            'setopt_function': r'sub\s+setopt\s*\{',
            'config_new': r'Getopt::EX::Config\s*->\s*new\b',
            'deal_with_call': r'(?:\$\w+\s*->\s*)?deal_with\s*\(',
            'finalize_function': r'sub\s+finalize\s*\{',
            'opt_hash_usage': r'\$opt\s*\{[^}]+\}',
            'our_opt': r'our\s+%opt\b'
        }
    
    def analyze_code(self, code: str) -> Dict[str, Any]:
        """コードを解析して移行に必要な情報を抽出"""
        analysis = {}
        
        # パターンマッチング
        for pattern_name, regex in self.patterns.items():
            matches = re.findall(regex, code, re.MULTILINE | re.IGNORECASE)
            analysis[pattern_name] = len(matches) > 0
            if matches:
                analysis[f"{pattern_name}_count"] = len(matches)
        
        # モジュール設定に関連する情報のみ抽出
        
        # 既存のset関数の内容を抽出
        set_function_matches = re.findall(
            r'sub\s+set\s*\{(.*?)\}', 
            code, 
            re.MULTILINE | re.DOTALL
        )
        analysis['set_function_content'] = set_function_matches
        
        # %optハッシュの使用パターンを抽出
        opt_usages = re.findall(r'\$opt\s*\{([^}]+)\}', code)
        # 変数名やクォートされていない文字列を除外
        clean_opt_keys = []
        for key in opt_usages:
            clean_key = key.strip('\'"')
            # 変数名（$で始まる）や明らかに変数と思われるものを除外
            if not clean_key.startswith('$') and clean_key.isidentifier():
                clean_opt_keys.append(clean_key)
        analysis['opt_keys'] = list(set(clean_opt_keys))  # 重複を除去
        
        # 移行の複雑さを評価（モジュール設定の観点から）
        complexity_score = 0
        if analysis.get('set_function'): complexity_score += 1
        if analysis.get('opt_hash_usage'): complexity_score += 2
        if len(analysis.get('opt_keys', [])) > 5: complexity_score += 1
        if analysis.get('use_getopt_long'): complexity_score += 1  # 依存関係の整理が必要
        analysis['complexity_score'] = complexity_score
        
        return analysis


class MigrationGuide:
    """移行ガイダンスを生成するクラス"""
    
    @staticmethod
    def generate_guidance(analysis: Dict[str, Any]) -> str:
        """解析結果から移行ガイダンスを生成"""
        guidance = []
        
        # 現状分析
        guidance.append("=== 現状分析 ===")
        if analysis.get('use_getopt_ex_config'):
            guidance.append("✓ 既にGetopt::EX::Configを使用しています")
            if analysis.get('deal_with_call'):
                guidance.append("✓ deal_with()メソッドも使用中")
            else:
                guidance.append("⚠ deal_with()メソッドの使用を検討してください")
            return "\n".join(guidance)
        
        # 複雑さの評価
        complexity = analysis.get('complexity_score', 0)
        if complexity <= 2:
            guidance.append("🟢 移行難易度: 簡単")
        elif complexity <= 4:
            guidance.append("🟡 移行難易度: 中程度")
        else:
            guidance.append("🔴 移行難易度: 複雑")
        
        if analysis.get('use_getopt_ex'):
            guidance.append("✓ Getopt::EXを使用中（Config移行が推奨）")
        elif analysis.get('use_getopt_long'):
            guidance.append("✓ Getopt::Longを使用中")
        
        if analysis.get('set_function') or analysis.get('setopt_function'):
            guidance.append("✓ 既存のset/setopt関数を検出")
        
        if analysis.get('use_getopt_long'):
            guidance.append("⚠ Getopt::Longの依存関係を整理する必要があります")
        
        # 検出された設定項目の表示
        opt_keys = analysis.get('opt_keys', [])
        if opt_keys:
            guidance.append(f"✓ 検出された設定項目: {', '.join(opt_keys[:5])}")
            if len(opt_keys) > 5:
                guidance.append(f"   （他{len(opt_keys) - 5}個の設定項目）")
        
        # 移行手順
        guidance.append("\n=== 移行手順 ===")
        guidance.append("1. use文の変更:")
        guidance.append("   use Getopt::EX::Config qw(config set);")
        
        guidance.append("\n2. 設定オブジェクトの作成:")
        guidance.append("   my $config = Getopt::EX::Config->new(")
        guidance.append("       # デフォルト値をここに定義")
        guidance.append("   );")
        
        if analysis.get('set_function'):
            guidance.append("\n3. 既存のset関数:")
            guidance.append("   → 削除可能（qw(config set)で自動提供）")
        
        guidance.append("\n4. finalize関数の実装:")
        guidance.append("   sub finalize {")
        guidance.append("       our($mod, $argv) = @_;")
        guidance.append("       $config->deal_with($argv,")
        guidance.append("           # モジュールオプション定義（Getopt::Long形式）")
        guidance.append("       );")
        guidance.append("   }")
        
        # 注意点
        guidance.append("\n=== 注意点 ===")
        guidance.append("• 設定名：アンダースコア (clear_screen)")
        guidance.append("• CLI名：ハイフンも自動対応 (--clear-screen)")
        guidance.append("• $REPLACE_UNDERSCORE=1でアンダースコア→ダッシュ変換")
        guidance.append("• Boolean値：! 付加で --no- 対応")
        guidance.append("• 後方互換性：既存の::set記法も継続利用可能")
        
        # 参考例
        guidance.append("\n=== App::Greple::pw の実例 ===")
        guidance.append("greple -Mpw::config=clear_screen=0  # 従来方式")
        guidance.append("greple -Mpw --no-clear-screen       # 新方式")
        guidance.append("greple -Mpw --config debug=1        # Config方式")
        
        return "\n".join(guidance)
    
    @staticmethod
    def generate_migration_code(analysis: Dict[str, Any], original_code: str) -> str:
        """移行後のコード例を生成"""
        code_parts = []
        
        code_parts.append("# Getopt::EX::Config移行版")
        code_parts.append("use Getopt::EX::Config qw(config set);")
        code_parts.append("")
        
        # 設定オブジェクト（実際のオプションから生成）
        code_parts.append("my $config = Getopt::EX::Config->new(")
        
        opt_keys = analysis.get('opt_keys', [])
        
        if opt_keys:
            code_parts.append("    # 検出された設定項目のデフォルト値")
            
            # 実際に検出された設定項目からデフォルト値を推測
            processed_keys = set()
            for key in opt_keys:
                clean_key = key.strip('\'"')
                # 有効な識別子のみを処理
                if clean_key not in processed_keys and clean_key.isidentifier() and not clean_key.startswith('$'):
                    # 一般的なデフォルト値を設定
                    code_parts.append(f"    {clean_key} => 0,")
                    processed_keys.add(clean_key)
        else:
            code_parts.append("    # デフォルト値を設定")
            code_parts.append("    debug => 0,")
            code_parts.append("    width => 80,")
        
        code_parts.append(");")
        code_parts.append("")
        
        # finalize関数
        code_parts.append("sub finalize {")
        code_parts.append("    our($mod, $argv) = @_;")
        code_parts.append("    $config->deal_with($argv,")
        
        # モジュールオプションの仕様を記述
        if opt_keys:
            code_parts.append("        # 検出された設定項目に基づくオプション仕様:")
            for key in opt_keys[:3]:  # 最初の3つまで例として
                clean_key = key.strip('\'"')
                if clean_key.isidentifier() and not clean_key.startswith('$'):
                    code_parts.append(f"        \"{clean_key}!\",")
        else:
            code_parts.append("        # 例: 実際の設定項目に置き換えてください")
            code_parts.append("        \"debug!\",")
            code_parts.append("        \"width=i\",")
        code_parts.append("        # 必要に応じて追加の設定項目")
        code_parts.append("    );")
        code_parts.append("}")
        code_parts.append("")
        
        # 既存のset関数についてのコメント
        if analysis.get('set_function'):
            code_parts.append("# 注意: 既存のset関数は削除してください")
            code_parts.append("# qw(config set)により自動的に提供されます")
        
        return "\n".join(code_parts)


# MCPサーバーの実装
app = Server("getopt-ex-config-migrator")
analyzer = GetoptAnalyzer()
guide = MigrationGuide()


@app.list_tools()
async def list_tools() -> List[Tool]:
    """利用可能なツールのリストを返す"""
    return [
        Tool(
            name="analyze_getopt_usage",
            description="Perlファイル内のGetopt使用箇所を解析し、移行ガイダンスを提供",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_content": {
                        "type": "string",
                        "description": "解析するPerlコードの内容"
                    },
                    "file_path": {
                        "type": "string", 
                        "description": "ファイルパス（オプショナル）"
                    }
                },
                "required": ["file_content"]
            }
        ),
        Tool(
            name="suggest_config_migration",
            description="具体的なGetopt::EX::Config移行コードを提案",
            inputSchema={
                "type": "object",
                "properties": {
                    "current_code": {
                        "type": "string",
                        "description": "現在のPerlコード"
                    }
                },
                "required": ["current_code"]
            }
        ),
        Tool(
            name="show_migration_patterns",
            description="一般的な移行パターンとベストプラクティスを表示",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
    """ツールの実行"""
    
    try:
        if name == "analyze_getopt_usage":
            file_content = arguments.get("file_content", "")
            file_path = arguments.get("file_path", "unknown")
            
            if not file_content.strip():
                return [TextContent(type="text", text="エラー: ファイル内容が空です")]
            
            analysis = analyzer.analyze_code(file_content)
            guidance = guide.generate_guidance(analysis)
            
            response = f"ファイル: {file_path}\n\n{guidance}"
            
            return [TextContent(type="text", text=response)]
    
        elif name == "suggest_config_migration":
            current_code = arguments.get("current_code", "")
            
            if not current_code.strip():
                return [TextContent(type="text", text="エラー: コードが空です")]
            
            analysis = analyzer.analyze_code(current_code)
            migration_code = guide.generate_migration_code(analysis, current_code)
            
            response = f"移行後のコード例:\n\n```perl\n{migration_code}\n```"
            
            return [TextContent(type="text", text=response)]
        
        elif name == "show_migration_patterns":
            patterns = """
=== Getopt::EX::Config 移行パターン集 ===

1. 基本的な移行パターン:
   Before: use Getopt::Long; sub set { ... }
   After:  use Getopt::EX::Config qw(config set);

2. モジュール設定方法の選択肢:
   • greple -Mfoo::config=width=80     # Config記法
   • greple -Mfoo::set=width=80        # 従来記法（互換）  
   • greple -Mfoo --width=80 -- args   # 直接モジュールオプション

3. Boolean値の扱い:
   • 設定: debug => 1
   • モジュールオプション: --debug / --no-debug
   • deal_with: "debug!"

4. 成功事例:
   • App::Greple::pw: 豊富なオプション、3つの設定方式対応
   • 後方互換性を保ちながら新機能を追加

5. よくある注意点:
   • finalize()内でdeal_with()を呼び出す
   • 設定名とCLI名の命名規則統一
   • 既存のset関数は削除可能
        """
        
            return [TextContent(type="text", text=patterns)]
        
        else:
            return [TextContent(type="text", text=f"未知のツール: {name}")]
    
    except Exception as e:
        return [TextContent(type="text", text=f"エラーが発生しました: {str(e)}")]


async def main():
    """サーバーの起動"""
    # stdio transport使用
    from mcp.server.stdio import stdio_server
    
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
