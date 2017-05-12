package Lingua::GA::Gramadoir::Languages::zh;
# Chinese translations for gramadoir package
# gramadoir 软件包的简体中文翻译.
# Copyright (C) 2008 Kevin P. Scannell
# This file is distributed under the same license as the gramadoir package.
# Ji ZhengYu <zhengyuji@gmail.com>, 2008.
#
#msgid ""
#msgstr ""
#"Project-Id-Version: gramadoir 0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2008-08-18 09:44+0800\n"
#"Last-Translator: Ji ZhengYu <zhengyuji@gmail.com>\n"
#"Language-Team: Chinese (simplified) <translation-team-zh-cn@lists."
#"sourceforge.net>\n"
#"MIME-Version: 1.0\n"
#"Content-Type: text/plain; charset=UTF-8\n"
#"Content-Transfer-Encoding: 8bit\n"

use strict;
use warnings;
use utf8;
use base qw(Lingua::GA::Gramadoir::Languages);
use vars qw(%Lexicon);

%Lexicon = (
    "Line %d: [_1]\n"
 => "行 %d: [_1]\n",

    "unrecognized option [_1]"
 => "未知选项 [_1]",

    "option [_1] requires an argument"
 => "选项 [_1] 需要参数",

    "option [_1] does not allow an argument"
 => "选项 [_1] 不允许带参数",

    "error parsing command-line options"
 => "分析命令行选项时出错",

    "Unable to set output color to [_1]"
 => "不能设置 [_1] 的输出色彩",

    "Language [_1] is not supported."
 => "不支持语言 [_1]",

    "An Gramadoir"
 => "An Gramadoir",

    "Try [_1] for more information."
 => "尝试用 [_1] 取得更多信息。",

    "version [_1]"
 => "版本 [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "用法: [_1] ~[选项~] ~[文件~]",

    "Options for end-users:"
 => "最终用户的选项:",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan      报告所有错误(如: 未使用 ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  指定要检查的文本的字符编码",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   指定输出时的字符编码",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx 选择错误信息所用语言",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COLOR   指定用于高亮化错误的颜色",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       将拼错的单词发送给标准输出",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       对拼写错误提出更正建议",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FILE  将输出写入 FILE",

    "    --help         display this help and exit"
 => "    --help         显示此帮助并退出",

    "    --version      output version information and exit"
 => "    --version      输出版本信息并退出",

    "Options for developers:"
 => "开发者的选项:",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          输出一个其它程序能用的简易 XML 格式",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         为用浏览器观看而生成 HTML 输出",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   不要多次地解析词法的歧义部分",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          为调试而将标记好的 XML 流写入标准输出",

    "If no file is given, read from standard input."
 => "若不指定文件，将从标准输入读取。",

    "Send bug reports to <[_1]>."
 => "发送错误报告给 <[_1]>。",

    "There is no such file."
 => "没有那样的文件。",

    "Is a directory"
 => "是否目录",

    "Permission denied"
 => "权限被禁",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1]: 警告: 正在关闭 [_2] 时出现问题\n",

    "Currently checking [_1]"
 => "正在检查 [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     报告未解决的歧义词语，以次数排序",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        输出所有标记，以次数排序(为 unigram--xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        通过 Brill 的非监督分类算法找出无歧义的规则 ",

    "[_1]: problem reading the database\n"
 => "[_1]: 正在读取数据库时出错\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1]: ‘[_2]’ 在 [_3] 被破坏了\n",

    "conversion from [_1] is not supported"
 => "不支持从 [_1] 转换编码",

    "[_1]: illegal grammatical code\n"
 => "[_1]: 非法的语法符号\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1]: 无语法符号: [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1]: 未知的宏错误: [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "有效单词但实际上极少使用。此单词确实是您想要的？",

    "Repeated word"
 => "多次重复的单词",

    "Unusual combination of words"
 => "不多见的单词合用",

    "The plural form is required here"
 => "这里要求使用复数形式",

    "The singular form is required here"
 => "这里要求使用单数形式",

    "Plural adjective required"
 => "这里要求使用复数形容词",

    "Comparative adjective required"
 => "要求使用比较级形容词",

    "Definite article required"
 => "要求使用明确的冠词",

    "Unnecessary use of the definite article"
 => "不必使用明确的冠词",

    "No need for the first definite article"
 => "第一次使用的冠词没必要这么做",

    "Unnecessary use of the genitive case"
 => "不必使用所有格词",

    "The genitive case is required here"
 => "这里需要所有格词",

    "You should use the present tense here"
 => "这里应该使用现在时",

    "You should use the conditional here"
 => "这里应该使用现在时",

    "It seems unlikely that you intended to use the subjunctive here"
 => "看起来您不可能会在这里用虚拟语气",

    "Usually used in the set phrase /[_1]/"
 => "通常用于固定词组 /[_1]/ 中",

    "You should use /[_1]/ here instead"
 => "这里你该用 /[_1]/ 代替",

    "Non-standard form of /[_1]/"
 => "/[_1]/ 的非标准形式",

    "Derived from a non-standard form of /[_1]/"
 => "从 /[_1]/ 的非标准形式引申",

    "Derived incorrectly from the root /[_1]/"
 => "从 /[_1]/ 词根的错误引申",

    "Unknown word"
 => "未知单词",

    "Unknown word: /[_1]/?"
 => "未知单词: /[_1]/？",

    "Valid word but /[_1]/ is more common"
 => "该单词有效，但/[_1]/ 更常用",

    "Not in database but apparently formed from the root /[_1]/"
 => "不在数据库中但很明显是从 /[_1]/ 词根形成的",

    "The word /[_1]/ is not needed"
 => "不需要单词 /[_1]/",

    "Do you mean /[_1]/?"
 => "你是要 /[_1]/？",

    "Derived form of common misspelling /[_1]/?"
 => "衍生自 /[_1]/ 的常见拼写错误？",

    "Not in database but may be a compound /[_1]/?"
 => "不在数据库中但可能是个复合词 /[_1]/？",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "不在数据库中但可能是个非标准的复合词 /[_1]/？",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "可能是个外来词汇 (词组 /[_1]/ 不可能出现)",

    "Gender disagreement"
 => "性别词不一致",

    "Number disagreement"
 => "数词不一致",

    "Case disagreement"
 => "格词不一致",

    "Prefix /h/ missing"
 => "缺少 /h/ 前缀",

    "Prefix /t/ missing"
 => "缺少 /t/ 前缀",

    "Prefix /d'/ missing"
 => "缺少 /d'/ 前缀",

    "Unnecessary prefix /h/"
 => "没必要的 /h/ 前缀",

    "Unnecessary prefix /t/"
 => "没必要的 /t/ 前缀",

    "Unnecessary prefix /d'/"
 => "没必要的 /d'/ 前缀",

    "Unnecessary prefix /b'/"
 => "没必要的 /b'/ 前缀",

    "Unnecessary initial mutation"
 => "不必进行首字母的元音变化",

    "Initial mutation missing"
 => "缺少首字母元音变化",

    "Unnecessary lenition"
 => "没必要的字首轻辅音",

    "The second lenition is unnecessary"
 => "第二个字首轻辅音是不必要的",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "通常介词 /[_1]/ 会引起轻辅音化，但不一定如此",

    "Lenition missing"
 => "缺少轻辅音",

    "Unnecessary eclipsis"
 => "没必要的字首浊辅音",

    "Eclipsis missing"
 => "缺少浊辅音",

    "The dative is used only in special phrases"
 => "与格语只用在特定语句中",

    "The dependent form of the verb is required here"
 => "这里需要动词的从属形式",

    "Unnecessary use of the dependent form of the verb"
 => "没必要用动词的从属形式",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "这里常用以 /[_1]/ 结尾的综合(合成)形式",

    "Second (soft) mutation missing"
 => "缺少第二(弱音)辅音变化",

    "Third (breathed) mutation missing"
 => "缺少第三(轻声)辅音变化",

    "Fourth (hard) mutation missing"
 => "缺少第四(重音)辅音变化",

    "Fifth (mixed) mutation missing"
 => "缺少第五(混音)辅音变化",

    "Fifth (mixed) mutation after 'th missing"
 => "在 ‘th’ 后缺少第五(混音)辅音变化",

    "Aspirate mutation missing"
 => "缺少首字母元音发送气音",

    "This word violates the rules of Igbo vowel harmony"
 => "这个单词违反了 Igbo 语言中的母音同化规则",

    "Valid word but more often found in place of /[_1]/"
 => "有效单词但在 /[_1]/ 中更常用",

);
1;
