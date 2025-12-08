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
            'use_getopt_long': r'use\s+Getopt::Long\b(?:\s+qw\([^)]*\))?',
            'use_getopt_ex': r'use\s+Getopt::EX(?:::(?!Config)|\b)(?:\s+qw\([^)]*\))?',
            'use_getopt_ex_config': r'use\s+Getopt::EX::Config\b(?:\s+qw\([^)]*\))?',
            'set_function': r'sub\s+set\s*\{',
            'setopt_function': r'sub\s+setopt\s*\{',
            'option_function': r'sub\s+option\s*\{',  # optex style option function
            'config_new': r'Getopt::EX::Config\s*->\s*new\b',
            'deal_with_call': r'(?:\$\w+\s*->\s*)?deal_with\s*\(',
            'initialize_function': r'sub\s+initialize\s*\{',  # optex module pattern
            'finalize_function': r'sub\s+finalize\s*\{',
            'opt_hash_usage': r'\$opt\s*\{[^}]+\}',
            'option_hash_usage': r'\$option\s*\{[^}]+\}',  # %option pattern
            'our_opt': r'our\s+%opt\b',
            'our_option': r'our\s+%option\b',  # our %option pattern
            'getoptions_call': r'GetOptions(?:FromArray)?\s*\(',
            'option_spec': r'["\']([\w\-\|!+=:@%]+)["\']',
            'module_declaration': r'package\s+([\w:]+)',
            'export_ok': r'our\s+@EXPORT_OK\s*=\s*qw\(([^)]+)\)',
            'config_access': r'\$config\s*->\s*\{([^}]+)\}',
            'config_method_call': r'\$config\s*->\s*(\w+)\s*\('
        }
        
        # 一般的なコマンドオプションのパターン（これらはモジュール固有ではない可能性が高い）
        self.common_command_options = {
            'help', 'h', 'man', 'version', 'v', 'verbose', 'quiet', 'q',
            'debug', 'd', 'dry-run', 'force', 'f', 'output', 'o', 'input', 'i',
            'config', 'c', 'log', 'l'
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
        
        # GetOptionsの詳細解析
        analysis.update(self._analyze_getoptions(code))
        
        # オプション分類
        analysis.update(self._classify_options(analysis))
        
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

        # %optionハッシュの使用パターンを抽出
        option_usages = re.findall(r'\$option\s*\{([^}]+)\}', code)
        clean_option_keys = []
        for key in option_usages:
            clean_key = key.strip('\'"')
            if not clean_key.startswith('$') and clean_key.isidentifier():
                clean_option_keys.append(clean_key)
        analysis['option_keys'] = list(set(clean_option_keys))

        # our %option = (...) からデフォルト値付きのキーを抽出
        our_option_match = re.search(
            r'our\s+%option\s*=\s*\((.*?)\)\s*;',
            code,
            re.MULTILINE | re.DOTALL
        )
        if our_option_match:
            option_def = our_option_match.group(1)
            # キー => 値 のパターンを抽出
            option_pairs = re.findall(r'(\w+)\s*=>\s*([^,\)]+)', option_def)
            analysis['option_defaults'] = {k.strip(): v.strip() for k, v in option_pairs}
        
        # 移行の複雑さを評価（モジュール設定の観点から）
        complexity_score = 0
        if analysis.get('set_function'): complexity_score += 1
        if analysis.get('opt_hash_usage'): complexity_score += 2
        if len(analysis.get('opt_keys', [])) > 5: complexity_score += 1
        if analysis.get('use_getopt_long'): complexity_score += 1  # 依存関係の整理が必要
        if len(analysis.get('module_specific_options', [])) > 3: complexity_score += 1
        analysis['complexity_score'] = complexity_score
        
        return analysis
    
    def _analyze_getoptions(self, code: str) -> Dict[str, Any]:
        """GetOptions呼び出しを詳細解析"""
        result = {}
        
        # GetOptions呼び出し全体を抽出（より柔軟な正規表現）
        getoptions_pattern = r'GetOptions(?:FromArray)?\s*\(\s*(.*?)\s*\);?'
        getoptions_matches = []
        
        # 複数行にわたるGetOptions呼び出しも捕捉
        for match in re.finditer(getoptions_pattern, code, re.MULTILINE | re.DOTALL):
            getoptions_matches.append(match.group(1))
        
        all_options = []
        variable_mappings = {}
        
        for match in getoptions_matches:
            # オプション仕様を抽出（変数マッピングも含む）
            option_patterns = [
                r'["\']([\w\-\|!+=:@%]+)["\']\s*=>\s*\\?\$(\w+)',  # "option" => \$var
                r'["\']([\w\-\|!+=:@%]+)["\']\s*=>\s*\\?(\$\w+)',  # "option" => $var
                r'["\']([\w\-\|!+=:@%]+)["\']'  # "option" のみ
            ]
            
            for pattern in option_patterns:
                option_matches = re.findall(pattern, match)
                for option_match in option_matches:
                    if isinstance(option_match, tuple) and len(option_match) == 2:
                        option_spec, var_name = option_match
                        all_options.append(option_spec)
                        variable_mappings[option_spec] = var_name
                    else:
                        all_options.append(option_match)
        
        result['getoptions_options'] = all_options
        result['option_specs'] = self._parse_option_specs(all_options)
        result['variable_mappings'] = variable_mappings
        
        # 追加の分析
        result['has_complex_getoptions'] = len(getoptions_matches) > 1 or any(len(match) > 200 for match in getoptions_matches)
        
        return result
    
    def _parse_option_specs(self, option_specs: List[str]) -> List[Dict[str, Any]]:
        """オプション仕様を解析"""
        parsed_options = []
        
        for spec in option_specs:
            option_info = {'spec': spec}
            
            # オプション名を抽出（|で区切られた別名も含む）
            base_spec = spec.split('=')[0].split(':')[0].rstrip('!+')
            names = base_spec.split('|')
            option_info['names'] = names
            option_info['primary_name'] = names[0]
            
            # タイプを判定
            if '=' in spec:
                if spec.endswith('=s'): option_info['type'] = 'string'
                elif spec.endswith('=i'): option_info['type'] = 'integer'
                elif spec.endswith('=f'): option_info['type'] = 'float'
                elif spec.endswith('=s@'): option_info['type'] = 'string_array'
                elif spec.endswith('=i@'): option_info['type'] = 'integer_array'
                elif spec.endswith('=s%'): option_info['type'] = 'string_hash'
                else: option_info['type'] = 'string'
            elif spec.endswith('!'):
                option_info['type'] = 'boolean_negatable'
            elif spec.endswith('+'):
                option_info['type'] = 'incremental'
            else:
                option_info['type'] = 'boolean'
            
            parsed_options.append(option_info)
        
        return parsed_options
    
    def _classify_options(self, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """オプションをモジュール固有/コマンド共通に分類"""
        result = {}
        
        option_specs = analysis.get('option_specs', [])
        
        module_specific = []
        command_common = []
        ambiguous = []
        
        for option_info in option_specs:
            primary_name = option_info['primary_name']
            
            # 共通オプションかチェック
            if any(name in self.common_command_options for name in option_info['names']):
                command_common.append(option_info)
            # モジュール固有の特徴があるかチェック
            elif self._is_module_specific_option(option_info):
                module_specific.append(option_info)
            else:
                ambiguous.append(option_info)
        
        result['module_specific_options'] = module_specific
        result['command_common_options'] = command_common
        result['ambiguous_options'] = ambiguous
        
        return result
    
    def _is_module_specific_option(self, option_info: Dict[str, Any]) -> bool:
        """オプションがモジュール固有かどうかを判定"""
        primary_name = option_info['primary_name']
        
        # 特定のパターンをモジュール固有と判定
        module_patterns = [
            r'.*color.*', r'.*theme.*', r'.*style.*',
            r'.*format.*', r'.*template.*', r'.*pattern.*',
            r'.*filter.*', r'.*exclude.*', r'.*include.*',
            r'.*width.*', r'.*height.*', r'.*size.*',
            r'.*mode.*', r'.*type.*', r'.*method.*'
        ]
        
        for pattern in module_patterns:
            if re.match(pattern, primary_name, re.IGNORECASE):
                return True
        
        # 長いオプション名（3文字以上）は多くの場合モジュール固有
        if len(primary_name) >= 3 and primary_name not in self.common_command_options:
            return True
        
        return False


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

        if analysis.get('option_function'):
            guidance.append("✓ 既存のoption関数を検出（optexモジュールパターン）")

        if analysis.get('our_option'):
            guidance.append("✓ our %option パターンを検出")
            option_defaults = analysis.get('option_defaults', {})
            if option_defaults:
                guidance.append(f"   設定項目: {', '.join(option_defaults.keys())}")

        if analysis.get('initialize_function'):
            guidance.append("✓ initialize関数を検出（optexモジュール）")
        
        if analysis.get('use_getopt_long'):
            guidance.append("⚠ Getopt::Longの依存関係を整理する必要があります")
        
        # オプション分類の表示
        module_options = analysis.get('module_specific_options', [])
        command_options = analysis.get('command_common_options', [])
        ambiguous_options = analysis.get('ambiguous_options', [])
        
        if module_options:
            guidance.append(f"🎯 モジュール固有オプション: {len(module_options)}個")
            for opt in module_options[:3]:
                guidance.append(f"   • {opt['primary_name']} ({opt['type']})")
            if len(module_options) > 3:
                guidance.append(f"   （他{len(module_options) - 3}個）")
        
        if command_options:
            guidance.append(f"⚠ コマンド共通オプション: {len(command_options)}個")
            common_names = [opt['primary_name'] for opt in command_options[:3]]
            guidance.append(f"   • {', '.join(common_names)}")
            if len(command_options) > 3:
                guidance.append(f"   （他{len(command_options) - 3}個）")
            guidance.append("   → これらは移行時に注意が必要です")
        
        if ambiguous_options:
            guidance.append(f"❓ 分類が曖昧なオプション: {len(ambiguous_options)}個")
            ambiguous_names = [opt['primary_name'] for opt in ambiguous_options[:3]]
            guidance.append(f"   • {', '.join(ambiguous_names)}")
            guidance.append("   → 手動での確認を推奨します")
        
        # 検出された設定項目の表示（レガシー）
        opt_keys = analysis.get('opt_keys', [])
        if opt_keys:
            guidance.append(f"✓ %opt使用パターン: {', '.join(opt_keys[:5])}")
            if len(opt_keys) > 5:
                guidance.append(f"   （他{len(opt_keys) - 5}個の設定項目）")
        
        # 移行手順
        guidance.append("\n=== 移行手順 ===")
        guidance.append("1. use文の変更:")
        guidance.append("   use Getopt::EX::Config qw(config set);")
        
        guidance.append("\n2. 設定オブジェクトの作成:")
        guidance.append("   my $config = Getopt::EX::Config->new(")
        if module_options:
            guidance.append("       # モジュール固有オプションのデフォルト値")
            for opt in module_options[:3]:
                default_val = MigrationGuide._get_default_value(opt['type'])
                guidance.append(f"       {opt['primary_name']} => {default_val},")
        else:
            guidance.append("       # デフォルト値をここに定義")
        guidance.append("   );")
        
        if analysis.get('set_function'):
            guidance.append("\n3. 既存のset関数:")
            guidance.append("   → 削除可能（qw(config set)で自動提供）")
        
        guidance.append("\n4. finalize関数の実装:")
        guidance.append("   sub finalize {")
        guidance.append("       our($mod, $argv) = @_;")
        guidance.append("       $config->deal_with($argv,")
        if module_options:
            guidance.append("           # モジュール固有オプションのみを定義:")
            for opt in module_options[:3]:
                guidance.append(f"           \"{opt['spec']}\",")
            if len(module_options) > 3:
                guidance.append("           # 他のモジュール固有オプション...")
        else:
            guidance.append("           # モジュールオプション定義（Getopt::Long形式）")
        guidance.append("       );")
        guidance.append("   }")
        
        # オプション分類に基づく特別な注意点
        if command_options:
            guidance.append(f"\n=== ⚠ 重要：コマンド共通オプションについて ===")
            guidance.append("以下のオプションはコマンド本体のオプションと重複の可能性があります：")
            for opt in command_options:
                guidance.append(f"• {opt['primary_name']}: {opt['spec']}")
            guidance.append("→ これらをdeal_with()に含めるか慎重に検討してください")
            guidance.append("→ 必要に応じてオプション名を変更することを推奨します")
        
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
    def _get_default_value(option_type: str) -> str:
        """オプションタイプに基づくデフォルト値を返す"""
        type_defaults = {
            'string': "''",
            'integer': "0",
            'float': "0.0",
            'boolean': "0",
            'boolean_negatable': "0",
            'incremental': "0",
            'string_array': "[]",
            'integer_array': "[]",
            'string_hash': "{}"
        }
        return type_defaults.get(option_type, "''")
    
    @staticmethod
    def generate_migration_code(analysis: Dict[str, Any], original_code: str) -> str:
        """移行後のコード例を生成"""
        code_parts = []

        # optexモジュールパターンの検出
        is_optex_module = analysis.get('initialize_function') or analysis.get('option_function')

        code_parts.append("# Getopt::EX::Config移行版")
        code_parts.append("use Getopt::EX::Config;")
        code_parts.append("")

        # 設定オブジェクト（実際のオプションから生成）
        code_parts.append("my $config = Getopt::EX::Config->new(")

        module_options = analysis.get('module_specific_options', [])
        opt_keys = analysis.get('opt_keys', [])
        option_keys = analysis.get('option_keys', [])
        option_defaults = analysis.get('option_defaults', {})

        # our %option = (...) から検出した場合を優先
        if option_defaults:
            code_parts.append("    # %optionから検出した設定項目")
            for key, value in option_defaults.items():
                code_parts.append(f"    {key} => {value},")
        elif module_options:
            code_parts.append("    # モジュール固有オプションのデフォルト値")
            for opt in module_options:
                default_val = MigrationGuide._get_default_value(opt['type'])
                code_parts.append(f"    {opt['primary_name']} => {default_val},")
        elif option_keys:
            code_parts.append("    # $option{...}から検出した設定項目")
            for key in option_keys:
                code_parts.append(f"    {key} => 0,")
        elif opt_keys:
            code_parts.append("    # 検出された設定項目のデフォルト値")
            processed_keys = set()
            for key in opt_keys:
                clean_key = key.strip('\'"')
                if clean_key not in processed_keys and clean_key.isidentifier() and not clean_key.startswith('$'):
                    code_parts.append(f"    {clean_key} => 0,")
                    processed_keys.add(clean_key)
        else:
            code_parts.append("    # デフォルト値を設定")
            code_parts.append("    debug => 0,")

        code_parts.append(");")
        code_parts.append("")

        # optexモジュールの場合はinitialize/finalizeパターン
        if is_optex_module:
            code_parts.append("my($mod, $argv);")
            code_parts.append("sub initialize { ($mod, $argv) = @_ }")
            code_parts.append("")
            code_parts.append("sub finalize {")
            code_parts.append("    $config->deal_with($argv,")
        else:
            code_parts.append("sub finalize {")
            code_parts.append("    our($mod, $argv) = @_;")
            code_parts.append("    $config->deal_with($argv,")

        # モジュールオプションの仕様を記述
        if option_defaults:
            code_parts.append("        # %optionから検出した設定項目:")
            for key in option_defaults.keys():
                code_parts.append(f"        '{key}!',")
        elif module_options:
            code_parts.append("        # モジュール固有オプションのみを定義:")
            for opt in module_options:
                code_parts.append(f"        \"{opt['spec']}\",")
        elif option_keys:
            code_parts.append("        # $option{...}から検出した設定項目:")
            for key in option_keys:
                code_parts.append(f"        '{key}!',")
        elif opt_keys:
            code_parts.append("        # 検出された設定項目に基づくオプション仕様:")
            for key in opt_keys[:5]:
                clean_key = key.strip('\'"')
                if clean_key.isidentifier() and not clean_key.startswith('$'):
                    code_parts.append(f"        '{clean_key}!',")
        else:
            code_parts.append("        # 例: 実際の設定項目に置き換えてください")
            code_parts.append("        'debug!',")
        code_parts.append("    );")

        # optexモジュールの場合、finalize内での処理例を追加
        if is_optex_module:
            code_parts.append("    # finalizeで処理を実行")
            code_parts.append("    # 例: some_processing() if $config->{all};")

        code_parts.append("}")
        code_parts.append("")
        
        # コマンド共通オプションについての警告
        command_options = analysis.get('command_common_options', [])
        if command_options:
            code_parts.append("# ⚠ 注意: 以下のオプションはコマンド本体と競合する可能性があります")
            for opt in command_options:
                code_parts.append(f"# • {opt['primary_name']}: {opt['spec']}")
            code_parts.append("# これらをdeal_with()に含めるかは慎重に判断してください")
            code_parts.append("")
        
        # 既存のset関数についてのコメント
        if analysis.get('set_function'):
            code_parts.append("# 注意: 既存のset関数は削除してください")
            code_parts.append("# qw(config set)により自動的に提供されます")
        
        return "\n".join(code_parts)
    
    @staticmethod
    def generate_staged_plan(analysis: Dict[str, Any], risk_level: str = "moderate") -> str:
        """段階的移行計画を生成"""
        plan = []
        
        # 現状の複雑度を評価
        complexity = analysis.get('complexity_score', 0)
        module_options = analysis.get('module_specific_options', [])
        command_options = analysis.get('command_common_options', [])
        
        plan.append("=== 段階的移行計画 ===")
        plan.append(f"複雑度スコア: {complexity}")
        plan.append(f"リスク許容度: {risk_level}")
        plan.append("")
        
        if risk_level == "conservative":
            # 保守的アプローチ：最小限の変更で段階的に移行
            plan.append("🛡️ 保守的移行アプローチ（リスク最小化）")
            plan.append("")
            
            plan.append("【段階 1: 準備作業】")
            plan.append("1. 現在のコードをバックアップ")
            plan.append("2. 既存機能のテストケース作成（可能であれば）")
            plan.append("3. use Getopt::EX::Config の追加（既存useと併存）")
            plan.append("")
            
            plan.append("【段階 2: 設定オブジェクト導入】")
            plan.append("1. $configオブジェクトの作成")
            if module_options:
                plan.append("2. モジュール固有オプションのみを$configに設定")
                for opt in module_options[:2]:
                    plan.append(f"   • {opt['primary_name']}")
            plan.append("3. 既存のset関数は保持（互換性維持）")
            plan.append("")
            
            plan.append("【段階 3: 段階的移行】")
            plan.append("1. 新しいfinalize関数を追加（既存処理と併存）")
            plan.append("2. モジュール固有オプションのみdeal_with()で処理")
            if command_options:
                plan.append("3. コマンド共通オプションは既存処理のまま維持")
            plan.append("4. 十分テスト後、古い処理を削除")
            
        elif risk_level == "aggressive":
            # 積極的アプローチ：一気に完全移行
            plan.append("🚀 積極的移行アプローチ（効率重視）")
            plan.append("")
            
            plan.append("【段階 1: 完全置換】")
            plan.append("1. use文を Getopt::EX::Config に完全置換")
            plan.append("2. 既存のset関数を削除")
            plan.append("3. 全オプションを$configオブジェクトに移行")
            plan.append("")
            
            plan.append("【段階 2: 最適化】")
            if command_options:
                plan.append("1. コマンド共通オプションの競合解決")
                for opt in command_options[:2]:
                    plan.append(f"   • {opt['primary_name']} の扱いを決定")
            plan.append("2. deal_with()に全オプションを統合")
            plan.append("3. 設定アクセスを$config->{key}形式に統一")
            
        else:  # moderate
            # 中間的アプローチ：バランス重視
            plan.append("⚖️ バランス型移行アプローチ（推奨）")
            plan.append("")
            
            plan.append("【段階 1: 基盤構築】")
            plan.append("1. use Getopt::EX::Config qw(config set); を追加")
            plan.append("2. $configオブジェクトの作成")
            if module_options:
                plan.append("3. モジュール固有オプションから開始")
                plan.append(f"   対象: {len(module_options)}個のオプション")
            plan.append("")
            
            plan.append("【段階 2: 段階的置換】")
            plan.append("1. finalize関数の実装")
            plan.append("2. モジュール固有オプションをdeal_with()に移行")
            if command_options:
                plan.append("3. コマンド共通オプションは慎重に検討")
                plan.append("   → 競合回避のため名前変更を検討")
            plan.append("4. 既存set関数との並行動作でテスト")
            plan.append("")
            
            plan.append("【段階 3: 完成・最適化】")
            plan.append("1. 動作確認後、既存set関数を削除")
            plan.append("2. 設定アクセスパターンの統一")
            plan.append("3. ドキュメント更新")
        
        # 共通の注意点
        plan.append("")
        plan.append("=== 移行時の共通注意点 ===")
        if command_options:
            plan.append("⚠ 以下のオプションは慎重な検討が必要:")
            for opt in command_options:
                plan.append(f"  • {opt['primary_name']}: コマンド本体との競合の可能性")
        
        plan.append("")
        plan.append("✅ 各段階でのチェックポイント:")
        plan.append("• 既存機能が正常動作すること")
        plan.append("• モジュール設定が正しく反映されること")
        plan.append("• ::config=key=value 形式での設定が機能すること")
        plan.append("• --module-option 形式のCLIオプションが機能すること")
        
        return "\n".join(plan)


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
        ),
        Tool(
            name="generate_staged_migration_plan",
            description="段階的な移行計画を生成",
            inputSchema={
                "type": "object",
                "properties": {
                    "current_code": {
                        "type": "string",
                        "description": "現在のPerlコード"
                    },
                    "risk_level": {
                        "type": "string",
                        "enum": ["conservative", "moderate", "aggressive"],
                        "description": "移行のリスク許容度"
                    }
                },
                "required": ["current_code"]
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
   Before: our %option = (...); sub option { ... }
   After:  use Getopt::EX::Config;
           my $config = Getopt::EX::Config->new(...);

2. モジュール設定方法の選択肢:
   • optex -Mfoo::config=width=80     # Config記法
   • optex -Mfoo --width=80 -- args   # 直接モジュールオプション

3. optexモジュールのパターン:
   my($mod, $argv);
   sub initialize { ($mod, $argv) = @_ }
   sub finalize {
       $config->deal_with($argv, 'all!', 'verbose!');
       process() if $config->{all};
   }

4. Boolean値の扱い:
   • 設定: all => 1, verbose => 0
   • CLI: --all / --no-all, --verbose
   • deal_with: 'all!', 'verbose!'

5. 成功事例:
   • App::optex::rpn: %optionパターンからの移行
     Before: our %option = (debug => 0, verbose => 0);
             sub option { while (my($k,$v) = splice @_,0,2) {...} }
     After:  my $config = Getopt::EX::Config->new(all => 1, verbose => 0);
             sub finalize { $config->deal_with($argv, 'all!', 'verbose!'); }

   • App::Greple::pw: 豊富なオプション、複数の設定方式対応

6. よくある注意点:
   • finalize()内でdeal_with()を呼び出す（オプション処理後に実行）
   • initialize()で$mod, $argvを保存
   • $config->{key}で設定値にアクセス
   • 既存のoption/set関数は削除可能
        """
        
            return [TextContent(type="text", text=patterns)]
        
        elif name == "generate_staged_migration_plan":
            current_code = arguments.get("current_code", "")
            risk_level = arguments.get("risk_level", "moderate")
            
            if not current_code.strip():
                return [TextContent(type="text", text="エラー: コードが空です")]
            
            analysis = analyzer.analyze_code(current_code)
            migration_plan = MigrationGuide.generate_staged_plan(analysis, risk_level)
            
            response = f"段階的移行計画 (リスクレベル: {risk_level}):\n\n{migration_plan}"
            
            return [TextContent(type="text", text=response)]
        
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
