# ABSTRACT: Driver for the Chinese tagset of the CoNLL 2006 & 2007 Shared Tasks (derived from the Academia Sinica Treebank).
# Documentation in Chu-Ren Huang, Keh-Jiann Chen, Shin Lin (1997): Corpus on Web: Introducing the First Tagged and Balanced Chinese Corpus.
# See also here: http://ckip.iis.sinica.edu.tw/CKIP/engversion/20corpus.htm
# Copyright © 2007, 2015, 2017 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::ZH::Conll;
use strict;
use warnings;
our $VERSION = '3.008';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::Conll';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'zh::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # noun or pronoun
            # N Naa: 水 = water, 地 = ground, 茶 = tea, 土地 = land, 食物 = food
            # N Nab: 人 = people, 者 = person, 媽媽 = mother, 地方 = place, 爸爸 = father
            # N Nac: 國家 = country, 政府 = government, 問題 = issue, 事 = thing, 社會 = society
            # N Nad: 時候 = time, 時間 = time, 文化 = culture, 生活 = life, 歷史 = history
            # N Naea: 們 = they, 人人 = everyone, 國人 = people, 百貨 = merchandise, 飲食 = diet/food
            # N Naeb: 錢 = money, 人民 = people, 人們 = people, 海鮮 = seafood, 父母 = parents
            'Naa'  => ['pos' => 'noun', 'nountype' => 'com'],
            'Nab'  => ['pos' => 'noun', 'nountype' => 'com', 'other' => {'subpos' => 'ab'}],
            'Nac'  => ['pos' => 'noun', 'nountype' => 'com', 'other' => {'subpos' => 'ac'}],
            'Nad'  => ['pos' => 'noun', 'nountype' => 'com', 'other' => {'subpos' => 'ad'}],
            'Naea' => ['pos' => 'noun', 'nountype' => 'com', 'other' => {'subpos' => 'aea'}],
            'Naeb' => ['pos' => 'noun', 'nountype' => 'com', 'other' => {'subpos' => 'aeb'}],
            # N Nba: 中共 = Chinese Communist Party, 國民黨 = Kuomintang, 民進黨 = DPP, 老包 = Old Package, 布希 = Bush
            # N Nbc: 李 Lǐ, 林 Lín, 郝 Hǎo, 張 Zhāng, 于 Yú (probably Chinese surnames?)
            'Nba'  => ['pos' => 'noun', 'nountype' => 'prop'],
            'Nbc'  => ['pos' => 'noun', 'nountype' => 'prop', 'other' => {'subpos' => 'bc'}],
            # location noun (including some proper nouns, e.g. Feizhou = Africa)
            # N Nca: 台灣 = Taiwan, 中國 = China, 美國 = USA, 日本 = Japan, 蘇聯 = Soviet Union
            # N Ncb: 公司 = company, 世界 = world, 家 = home, 國 = country, 公園 = park
            # N Ncc: 國內 = domestic, 國際 = international, 民間 = folk, 國外 = foreign, 眼前 = present
            # Ncd = localizer
            # N Ncda: 上 shàng = on, 裡 lǐ = in, 中 zhōng = in, 內 nèi = within, 邊 biān = edge, border
            # N Ncdb: 這裡 zhèlǐ = here, 那裡 nàlǐ = there, 西方 xīfāng = west, 哪裡 nǎlǐ = where, 內部 nèibù = interior
            # N Nce: 當地 = local, 兩岸 = both sides, 全球 = global, 外國 = foreign, 本土 = local
            'Nca'  => ['pos' => 'noun', 'advtype' => 'loc'],
            'Ncb'  => ['pos' => 'noun', 'advtype' => 'loc', 'other' => {'subpos' => 'cb'}],
            'Ncc'  => ['pos' => 'noun', 'advtype' => 'loc', 'other' => {'subpos' => 'cc'}],
            'Ncda' => ['pos' => 'noun', 'advtype' => 'loc', 'other' => {'subpos' => 'cda'}],
            'Ncdb' => ['pos' => 'noun', 'advtype' => 'loc', 'other' => {'subpos' => 'cdb'}],
            'Nce'  => ['pos' => 'noun', 'advtype' => 'loc', 'other' => {'subpos' => 'ce'}],
            # time noun
            # N Ndaaa: 年代 = era, １７世紀 = 17th century, １９世紀, １８世紀, １５世紀
            # N Ndaab: 民國 = Republic, 明 = Ming, 清 = Qing, 明朝 = Ming Dynasty, 清朝 = Qing Dynasty
            # N Ndaac: 光緒 = Guangxu, 明治 = Meiji, 江戶 = Edo, 寬永 = Kanei, 萬曆 = Wanli
            # N Ndaad: 西元 xīyuán = AD, 一九九０年 = 1990, 七十九年 = 1990, １９９２年 = 1992, 七十六年 = 76 years (of the Republic?) / 1987
            # N Ndaba: 今年 = this year, 去年 = last year, 明年 = next year, 隔年 = next year, 元年 = first year
            # N Ndabb: 春天 = spring, 夏天 = summer, 秋天 = fall, 冬天 = winter, 春 = spring
            # N Ndabc: 月 = month, 十月 = October, 十一月 = November, 九月 = September, 八月 = August
            # N Ndabd: 昨天 = yesterday, 今天 = today, 昨日 = yesterday, 今日 = today, 明天 = tomorrow
            # N Ndabe: 當時 = at the time, 同時 = at the same time, 下午 = in the afternoon, 晚上 = at night, 上午 = morning
            # N Ndabf: 季 = season, 當年 = that year, 際 = occasion, 假日 = holiday, 新年 = New Year
            # N Ndbb: 末期 = late, 後 = later (only these two words, each occurred once)
            # N Ndc: 盤中 = middle of the day, 戰後 = after the war, 晚間 = evening, 日後 = future, 午後 = afternoon
            # N Ndda: 過去 = past, 以前 = before, 古代 = ancient times, 當時 = at the time, 從前 = before
            # N Nddb: 後來 = later, 未來 = future, 不久 = soon, 將來 = future, 以後 = after
            # N Nddc: 目前 = for now, 現在 = right now, 最後 = finally, 如今 = now, 最近 = recently
            'Ndaaa' => ['pos' => 'noun', 'advtype' => 'tim'],
            'Ndaab' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'daab'}],
            'Ndaac' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'daac'}],
            'Ndaad' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'daad'}],
            'Ndaba' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'daba'}],
            'Ndabb' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dabb'}],
            'Ndabc' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dabc'}],
            'Ndabd' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dabd'}],
            'Ndabe' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dabe'}],
            'Ndabf' => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dabf'}],
            'Ndbb'  => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dbb'}],
            'Ndc'   => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dc'}],
            'Ndda'  => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'dda'}],
            'Nddb'  => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'ddb'}],
            'Nddc'  => ['pos' => 'noun', 'advtype' => 'tim', 'other' => {'subpos' => 'ddc'}],
            # classifier (measure word)
            ###!!! There are much less occurrences than I would expect for this sort of words!
            # N Nfa: 個 gè (months), 次 cì (times), 句 jù (sentences), 隻 zhī (only), 頁 yè (pages)
            # N Nfc: 攤 = stalls, 項 = items, 席 = seats
            # N Nfd: 點 = points, 層 = layers, 段 = sections, 些 = some
            # N Nfe: 杯 = cups, 桶 = buckets
            # N Nfg: 年 = years, 歲 = years, 元 = yuans, 美元 = dollars, 天 = days
            # N Nfh: 成, 股 = shares
            # N Nfi: 次 = times, 場 = fields
            'Nfa' => ['pos' => 'noun', 'nountype' => 'class'],
            'Nfc' => ['pos' => 'noun', 'nountype' => 'class', 'other' => {'subpos' => 'fc'}],
            'Nfd' => ['pos' => 'noun', 'nountype' => 'class', 'other' => {'subpos' => 'fd'}],
            'Nfe' => ['pos' => 'noun', 'nountype' => 'class', 'other' => {'subpos' => 'fe'}],
            'Nfg' => ['pos' => 'noun', 'nountype' => 'class', 'other' => {'subpos' => 'fg'}],
            'Nfh' => ['pos' => 'noun', 'nountype' => 'class', 'other' => {'subpos' => 'fh'}],
            'Nfi' => ['pos' => 'noun', 'nountype' => 'class', 'other' => {'subpos' => 'fi'}],
            # pronoun
            # N Nhaa: 我 wǒ = I, 他 tā = he, 我們 wǒmen = we, 你 nǐ = you, 他們 tāmen = they
            # N Nhab: 自己 zìjǐ = oneself, 大家 dàjiā = everyone, 雙方 shuāngfāng = both sides, 個人 gèrén = person, 自我 zìwǒ = self
            # N Nhac: 您 nín = you, 敝國 bìguó = mine, 筆者 bǐzhě = author/I, 貴國 guìguó = your, 本人 běnrén = myself/himself
            # N Nhb: 誰 shuí = who, 您 nín = you, 筆者 bǐzhě = author/I, 孰 shú = what, 各人 gèrén = everyone
            # N Nhc: 之 zhī = it, 前者 = the former, 後者 = the latter, 凡此種種 = all these, 兩者 = both
            'Nhaa' => ['pos' => 'noun', 'prontype' => 'prs'],
            'Nhab' => ['pos' => 'noun', 'prontype' => 'prs', 'reflex' => 'yes'],
            'Nhac' => ['pos' => 'noun', 'prontype' => 'prs', 'polite' => 'form'],
            'Nhb'  => ['pos' => 'noun', 'prontype' => 'int'],
            'Nhc'  => ['pos' => 'noun', 'prontype' => 'prn', 'gender' => 'neut'],
            # verbal noun
            # N Nv1: 發展 = development, 服務 = service, 醫療 = medical treatment, 攻擊 = attack, 經營 = run
            # N Nv2: 注意 = attention, 同意 = consent, 認同 = identification, 欣賞 = appreciation, 了解 = understanding
            # N Nv3: 有關 = relation, 重視 = importance, 優惠 = preference, 認識 = understanding, 領先 = lead
            # N Nv4: 旅遊 = travel, 購物 = shopping, 觀光 = sightseeing, 旅行 = travel, 反彈 = rally
            'Nv1' => ['pos' => 'noun', 'verbform' => 'ger'],
            'Nv2' => ['pos' => 'noun', 'verbform' => 'ger', 'other' => {'subpos' => 'v2'}],
            'Nv3' => ['pos' => 'noun', 'verbform' => 'ger', 'other' => {'subpos' => 'v3'}],
            'Nv4' => ['pos' => 'noun', 'verbform' => 'ger', 'other' => {'subpos' => 'v4'}],
            # A A non-predicative adjective
            # Examples: 主要 = main, 一般 = general, 共同 = common, 最佳 = optimal, 唯一 = the only
            'A'    => ['pos' => 'adj'],
            # determiner
            # anaphoric determiner (this, that)
            # Ne Nep: 這 zhè = this, 此 cǐ = this, 其 qí = its, 什麼 shénme = any, 那 nà = that
            'Nep'  => ['pos' => 'adj', 'prontype' => 'dem'],
            # classifying determiner (much, half)
            # Ne Neqa: 全 quán = all, 許多 xǔduō = a lot of, 這些 zhèxiē = these, 一些 yīxiē = some, 其他 qítā = other
            # Neqb = postposed classifier determiner
            # Ne Neqb: 多 duō = many, 以上 = more/above, 左右 zuǒyòu = about/approximately, 許 xǔ = perhaps, 上下 shàngxià = up and down
            'Neqa' => ['pos' => 'adj', 'prontype' => 'prn'],
            'Neqb' => ['pos' => 'adj', 'prontype' => 'prn', 'other' => {'subpos' => 'qb'}],
            # specific determiner (you, shang, ge = every)
            # Ne Nes: 各 gè = each, 有 yǒu = there is, 該 gāi = that, 本 běn = this, 另 lìng = other
            'Nes' => ['pos' => 'adj', 'prontype' => 'prn', 'other' => {'subpos' => 's'}],
            # numeric determiner (one, two, three)
            # Ne Neu: 一 yī = one, 二 èr = two, 兩 liǎng = two, 三 sān = three, 四 sì = four
            'Neu' => ['pos' => 'num', 'numtype' => 'card'],
            # verb
            # V V_11: 是 shì = be, 乃是, 像是, 可說是, 有
            # V V_12: 是 shì = be
            # V V_2:  有 yǒu = have/there is, 有沒有, 是, 包括有
            'V_11' => ['pos' => 'verb', 'other' => {'subpos' => '_11'}],
            'V_12' => ['pos' => 'verb', 'other' => {'subpos' => '_12'}],
            'V_2'  => ['pos' => 'verb', 'other' => {'subpos' => '_2'}],
            # VA = active intransitive verb
            # V VA11: 來, 走, 飛, 回來, 出來
            # V VA12: 站, 坐, 生活, 存在, 消失
            # V VA13: 回家, 出國, 爬山, 回國, 上場
            # V VA2:  動, 聚集, 上演, 轉, 集合
            # V VA3:  下雨, 日出, 退潮, 出太陽, 地震
            # V VA4:  笑, 出發, 讀書, 工作, 旅行
            'VA11' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'A11'}],
            'VA12' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'A12'}],
            'VA13' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'A13'}],
            'VA2'  => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'A2'}],
            'VA3'  => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'A3'}],
            'VA4'  => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'A4'}],
            # VB = active pseudo-transitive verb
            # V VB11: 打電話, 相較, 拍照, 再見, 開玩笑
            # V VB12: 提前, 完工, 相比, 加油, 說出來
            # V VB2:  拿出來, 撕票, 送醫, 挖出來, 吞下去
            'VB11' => ['pos' => 'verb'], # default because occurs also with +SPV, +NEG, +ASP, +DE
            'VB12' => ['pos' => 'verb', 'other' => {'subpos' => 'B12'}],
            'VB2'  => ['pos' => 'verb', 'other' => {'subpos' => 'B2'}],
            # VC = active transitive verb
            # V VC1:  在, 到, 去, 過, 進入
            # V VC2:  看, 參加, 進行, 玩, 打
            # V VC31: 做, 吃, 喝, 作, 接受
            # V VC32: 帶, 進, 攜帶, 載, 投
            # V VC33: 寫, 成立, 建, 放, 設
            'VC1'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'C1'}],
            'VC2'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'C2'}],
            'VC31' => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'C31'}],
            'VC32' => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'C32'}],
            'VC33' => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'C33'}],
            # VD = ditransitive verb
            # V VD1:  提供, 給, 賣, 送, 送給
            # V VD2:  搶, 租, 借, 索, 贏
            'VD1'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'D1'}],
            'VD2'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'D2'}],
            # VE = active transitive verb with sentential object
            # V VE11: 問, 詢問, 請問, 質詢, 質問
            # V VE12: 告訴, 回答, 安排, 答應, 反映
            # V VE2:  說, 表示, 想, 指出, 認為
            'VE11' => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'E11'}],
            'VE12' => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'E12'}],
            'VE2'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'E2'}],
            # VF = active transitive verb with VP object
            # V VF1:  繼續, 準備, 拒絕, 申請, 停止
            # V VF2:  請, 要求, 供, 叫, 派
            'VF1'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'F1'}],
            'VF2'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'F2'}],
            # VG = classificatory verb
            # V VG1:  為, 作為, 叫, 稱, 視為
            # V VG2:  為, 成為, 像, 成, 做
            'VG1'  => ['pos' => 'verb', 'other' => {'subpos' => 'G1'}],
            'VG2'  => ['pos' => 'verb', 'other' => {'subpos' => 'G2'}],
            # VH = stative intransitive verb
            # VHC = stative causative verb
            # V VH11: 好, 新, 這樣, 一樣, 不同
            # V VH12: 長, 深, 成長, 重, 漲
            # V VH13: 大, 小, 高, 多, 快
            # V VH14: 出現, 流行, 生長, 生存, 林立
            # V VH15: 值得, 容易, 可惜, 適合, 夠
            # V VH16: 增加, 結束, 統一, 產生, 豐富
            # V VH17: 死, 敗, 掉, 餓, 遺失
            # V VH21: 快樂, 興奮, 失望, 愉快, 緊張
            # V VH22: 滿足, 感動, 可憐, 驚, 委屈
            'VH11' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H11'}],
            'VH12' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H12'}],
            'VH13' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H13'}],
            'VH14' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H14'}],
            'VH15' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H15'}],
            'VH16' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H16'}],
            'VH17' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H17'}],
            'VH21' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H21'}],
            'VH22' => ['pos' => 'verb', 'subcat' => 'intr', 'other' => {'subpos' => 'H22'}],
            # VI = stative pseudo-transitive verb
            # V VI1:  陌生, 感興趣, 過敏, 沈醉, 恭敬
            # V VI2:  為主, 聞名, 沒辦法, 著稱, 留念
            # V VI3:  受雇, 取材, 來自, 薰陶, 取自
            'VI1'  => ['pos' => 'verb', 'other' => {'subpos' => 'I1'}],
            'VI2'  => ['pos' => 'verb', 'other' => {'subpos' => 'I2'}],
            'VI3'  => ['pos' => 'verb', 'other' => {'subpos' => 'I3'}],
            # VJ = stative transitive verb
            # V VJ1:  發生, 超過, 維持, 歡迎, 靠
            # V VJ2:  欣賞, 享受, 尊重, 謝謝, 熟悉
            # V VJ3:  沒有, 無, 具, 獲得, 擁有
            'VJ1'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'J1'}],
            'VJ2'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'J2'}],
            'VJ3'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'J3'}],
            # VK = stative transitive verb with sentential object
            # V VK1:  知道, 希望, 覺得, 喜歡, 怕
            # V VK2:  包括, 造成, 需要, 顯示, 所謂
            'VK1'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'K1'}],
            'VK2'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'K2'}],
            # VL = stative transitive verb with VP object
            # V VL1:  愛, 敢, 肯, 喜愛, 不禁
            # V VL2:  開始, 負責, 持續, 用來, 不宜
            # V VL3:  輪到, 輪, 該, 輪由
            # V VL4:  讓, 使, 令, 使得, 導致
            'VL1'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'L1'}],
            'VL2'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'L2'}],
            'VL3'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'L3'}],
            'VL4'  => ['pos' => 'verb', 'subcat' => 'tran', 'other' => {'subpos' => 'L4'}],
            # adverb
            # Da = possibly preceding a noun
            # D Daa: 只 = only, 約 = approximately, 才 = only, 共 = altogether, 僅 = only
            # D Dab: 都 = all, 所, 均 = all, 皆 = all, 完全 = entirely
            # D Dbaa: 是 = is, 會 = can/will, 可能 = maybe, 不會 = will not, 一定 = for sure
            # D Dbab: 要 = want, 能 = can, 可以 = can, 可 = can, 來 = come
            # D Dbb: 也 = also, 還 = also, 則 = then, 卻 = yet, 並 = and
            # D Dbc: 看起來 = looks, 看來 = seems, 說起來 = speaks, 聽起來 = sounds, 吃起來 = tastes
            # D Dc: 不 = not, 未 = not, 沒有 = there is no, 沒 = not, 非 = non-
            # D Dd: 就 = then, 又 = again, 已 = already, 將 = will, 才 = only
            # Dfa = preceding VH through VL
            # D Dfa: 很 = very, 最 = most, 更 = more, 較 = relatively, 非常 = very much
            # Dfb = following a V
            # D Dfb: 一點 = a little, 極了 = extremely, 些 = some, 得很 = very, 多 = more
            # D Dg: 一路 = all the way, 到處 = everywhere, 四處 = around, 處處 = everywhere, 當場 = on the spot
            # D Dh: 如何 = how, 一起 = together, 更 = more, 分別 = respectively, 這麼 = so
            # Di = post-verbal
            # D Dj: 為什麼 = why, 是否 = whether, 怎麼 = how, 為何 = why, 有沒有 = is there?
            # Dk = sentence-initial
            # D Dk: 結果 = result, 那 = then, 據說 = reportedly, 據了解 = it is understood that, 那麼 = then
            'Daa'  => ['pos' => 'adv'],
            'Dab'  => ['pos' => 'adv', 'other' => {'subpos' => 'ab'}],
            'Dbaa' => ['pos' => 'adv', 'other' => {'subpos' => 'baa'}],
            'Dbab' => ['pos' => 'adv', 'other' => {'subpos' => 'bab'}],
            'Dbb'  => ['pos' => 'adv', 'other' => {'subpos' => 'bb'}],
            'Dbc'  => ['pos' => 'adv', 'other' => {'subpos' => 'bc'}],
            'Dc'   => ['pos' => 'adv', 'polarity' => 'neg'],
            'Dd'   => ['pos' => 'adv', 'other' => {'subpos' => 'd'}],
            'Dfa'  => ['pos' => 'adv', 'other' => {'subpos' => 'fa'}],
            'Dfb'  => ['pos' => 'adv', 'other' => {'subpos' => 'fb'}],
            'Dg'   => ['pos' => 'adv', 'other' => {'subpos' => 'g'}],
            'Dh'   => ['pos' => 'adv', 'other' => {'subpos' => 'h'}],
            'Dj'   => ['pos' => 'adv', 'prontype' => 'int'],
            'Dk'   => ['pos' => 'adv', 'other' => {'subpos' => 'k'}],
            # measure word, quantifier
            # DM DM: 一個 yīgè = a, 這個 zhège = this one, 這種 zhèzhǒng = this kind, 個 gè, 一種 yīzhǒng = one kind
            ###!!! There ought to be a better solution!
            'DM'  => ['pos' => 'adj', 'nountype' => 'class'],
            # postposition (qian = before)
            # Ng Ng: 中 zhōng = middle, 時 shí = during, 後 hòu = after, 上 shàng = on, 前 qián = ago
            'Ng'  => ['pos' => 'adp', 'adpostype' => 'post'],
            # preposition (66 kinds, 66 different tags)
            # P P01: 承, 似, 承蒙, 為, 深為 (like, thanks to, for) max 3 occ.
            # P P02: 被, 受, 為, 深受, 備受 (for, by) max 588 occ.
            # P P03: 為 wèi, 為了 wèile (for, in order to) max 354 occ.
            # P P04: 給 gěi, 對 duì (to, for) max 132 occ.
            # P P06: 由 yóu, 遭, 改由, 每逢 (from, by, instead of) max 492 occ.
            # P P07: 把 bǎ, 將 jiāng (to) max 537 occ.
            # P P08: 拿 ná, 拿著, 直至 (take, hold, until, up to) max 8 occ.
            # P P09: 管, 尤以 () max 2 occ.
            # P P10: 為, 作 (for, as) max 6 occ.
            # P P11: 以 yǐ (with) max 990 occ.
            # P P12: 自從 (since) max 23 occ.
            # P P13: 等, 待, 逢, 每當, 趁 (wait, etc., whenever) max 19 occ.
            # P P14: 有 yǒu (there is) max 11 occ.
            # P P15: 離, 距, 距離, 臨, 去 (from, off, apart) max 21 occ.
            # P P16: 當 dāng (when, as) max 150 occ.
            # P P17: 打從, 打 dǎ () max 1 occ.
            # P P18: 直到, 等到, 直至, 及至 (until) max 44 occ.
            # P P19: 從 cóng (from) max 514 occ.
            # P P20: 就 jiù (on) max 37 occ.
            # P P21: 在 zài (in, at) max 3616 occ.
            # P P22: 繼 jì (following) max 10 occ.
            # P P23: 於 yú (to, in, on) max 569 occ.
            # P P24: 沿著 yánzhe, 沿, 跟, 延著 (along) max 29 occ.
            # P P25: 順著 shùnzhe, 循, 循著, 順 (following, along) max 5 occ.
            # P P26: 經 jīng, 經過, 經由, 業經, 一經 (after) max 66 occ.
            # P P27: 靠 kào, 靠著 (by, near, against) max 24 occ.
            # P P28: 朝 cháo, 假, 朝著 (towards) max 8 occ.
            # P P29: 朝 cháo, 朝著 (towards) max 2 occ.
            # P P30: 往 wǎng (to, towards) max 71 occ.
            # P P31: 對 duì, 針對, 對著, 針對了 (to, against) max 784 occ.
            # P P32: 對於 duìyú (for, about, regarding) max 110 occ.
            # P P35: 與 yǔ, 和 hé (versus, and, with) max 424 occ.
            # P P36: 代, 跟著 (on behalf of, following, in accord with) max 3 occ.
            # P P37: 替 tì, 幫 bāng (for, on behalf of, with the help of) max 62 occ.
            # P P38: 藉 jí, 藉著, 憑, 藉由, 憑藉 (by means of, through, based on, with) max 20 occ.
            # P P39: 用 yòng, 透過 (using, through) max 191 occ.
            # P P40: 基於 (because of, due to) max 15 occ.
            # P P41: 至於 zhìyú, 有關, 關於 (touching, as for, with respect to) max 95 occ.
            # P P42: 依 yī, 按, 照, 依著, 照著 (according to) max 75 occ.
            # P P43: 據 jù, 根據, 依據, 依照, 按照 (according to) max 97 occ.
            # P P44: 依循, 比照, 仿照 (following, in contrast to, cf.) max 2 occ.
            # P P45: 逐 (individually, one by one) max 2 occ.
            # P P46: 視 shì, 每隔 (depending on) max 26 occ.
            # P P47: 如 rú (according to) max 164 occ.
            # P P48: 有如 yǒurú, 一如, 如同, 似, 猶如 (like) max 7 occ.
            # P P49: 比 bǐ, 較, 比起, 相對於 (comparison particle) max 140 occ.
            # P P50: 除了 chúle, 除 chú (apart from, except) max 129 occ.
            # P P51: 連同 (together with, along of) max 1 occ.
            # P P52: 因 yīn, 因著 yīnzhe, 因為 yīnwèi (because of) max 7 occ.
            # P P53: 途經, 隨著 (via) max 2 occ.
            # P P54: 例如 lìrú, 譬如, 比如, 諸如, 誠如 (for example, such as) max 61 occ.
            # P P55: 像 xiàng, 好像 (like) max 169 occ.
            # P P58: 隨著 suízhe, 隨 (along with, along of) max 52 occ.
            # P P59: 自 zì (from, since) max 129 occ.
            # P P60: 遭 zāo, 慘遭, 險遭, 遭到, 遭受 (missing, suffering from) max 47 occ.
            # P P61: 到 dào, 至, 迄, 到了, 去 (to, up to, until) max 334 occ.
            # P P62: 向 xiàng, 向著 xiàngzhe (to, toward) max 355 occ.
            # P P63: 跟 gēn, 跟著 gēnzhe (with) max 141 occ.
            # P P64: 隨同, 偕 (accompanying) max 4 occ.
            # P P65: 隔 gé (at a distance from, after an interval of) max 3 occ.
            # P P66: 為 wèi (for) max 9 occ.
            'P01'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P01'}],
            'P02'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P02'}],
            'P03'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P03'}],
            'P04'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P04'}],
            'P05'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P05'}],
            # P06 is default because it also exists with P1, P2 and +part.
            'P06'   => ['pos' => 'adp', 'adpostype' => 'prep'],
            'P07'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P07'}],
            'P08'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P08'}],
            'P09'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P09'}],
            'P10'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P10'}],
            'P11'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P11'}],
            'P12'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P12'}],
            'P13'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P13'}],
            'P14'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P14'}],
            'P15'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P15'}],
            'P16'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P16'}],
            'P17'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P17'}],
            'P18'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P18'}],
            'P19'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P19'}],
            'P20'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P20'}],
            'P21'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P21'}],
            'P22'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P22'}],
            'P23'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P23'}],
            'P24'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P24'}],
            'P25'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P25'}],
            'P26'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P26'}],
            'P27'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P27'}],
            'P28'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P28'}],
            'P29'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P29'}],
            'P30'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P30'}],
            'P31'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P31'}],
            'P32'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P32'}],
            'P33'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P33'}],
            'P34'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P34'}],
            'P35'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P35'}],
            'P36'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P36'}],
            'P37'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P37'}],
            'P38'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P38'}],
            'P39'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P39'}],
            'P40'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P40'}],
            'P41'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P41'}],
            'P42'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P42'}],
            'P43'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P43'}],
            'P44'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P44'}],
            'P45'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P45'}],
            'P46'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P46'}],
            'P47'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P47'}],
            'P48'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P48'}],
            'P49'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P49'}],
            'P50'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P50'}],
            'P51'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P51'}],
            'P52'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P52'}],
            'P53'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P53'}],
            'P54'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P54'}],
            'P55'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P55'}],
            'P56'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P56'}],
            'P57'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P57'}],
            'P58'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P58'}],
            'P59'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P59'}],
            'P60'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P60'}],
            'P61'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P61'}],
            'P62'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P62'}],
            'P63'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P63'}],
            'P64'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P64'}],
            'P65'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P65'}],
            'P66'   => ['pos' => 'adp', 'adpostype' => 'prep', 'other' => {'subpos' => 'P66'}],
            # conjunction
            # C Caa: 、, 和 = and, 及 = and, 與 = versus, 或 = or
            # C Caa[P1]: 從 = from, 又 = again, 既 = already, 由 = from, 或 = or
            # C Caa[P2]: 又 = again, 到 = to, 至 = to, 或 = or, 也 = also
            # C Cab: 等 = etc., 等等 = and so on, 之類 = the class, 什麼的 = something, 、
            # C Cbaa: 因為 = because, 如果 = in case, 因 = because, 雖然 = though, 若 = if
            # C Cbab: 的話 = if, 應該 = should, 而 = while, 能 = can/able, 並 = and
            # Cbb = following a subject
            # C Cbba: 由於 = due to, 雖 = although, 連 = even though, 既然 = since, 就是 = that
            # C Cbbb: 不但 = not only, 不僅 = not only, 一方面 = on the one hand, 首先 = first of all, 二 = two
            # Cbc = sentence-initial
            # C Cbca: 而 = and, 但 = but, 因此 = as such, 所以 = and so, 但是 = but
            # C Cbcb: 並 = and, 而且 = and, 且 = and, 並且 = and, 反而 = instead
            'Caa'  => ['pos' => 'conj', 'conjtype' => 'coor'],
            'Cab'  => ['pos' => 'conj', 'conjtype' => 'coor', 'other' => {'subpos' => 'ab'}],
            'Cbaa' => ['pos' => 'conj', 'conjtype' => 'sub'],
            'Cbab' => ['pos' => 'conj', 'conjtype' => 'sub', 'other' => {'subpos' => 'bab'}],
            'Cbba' => ['pos' => 'conj', 'conjtype' => 'sub', 'other' => {'subpos' => 'bba'}],
            'Cbbb' => ['pos' => 'conj', 'conjtype' => 'sub', 'other' => {'subpos' => 'bbb'}],
            'Cbca' => ['pos' => 'conj', 'conjtype' => 'coor', 'other' => {'subpos' => 'bca'}],
            'Cbcb' => ['pos' => 'conj', 'conjtype' => 'coor', 'other' => {'subpos' => 'bcb'}],
            # the "de" particle (two kinds)
            # DE DE: 的 de = of, 之 zhī = of, 得 dé = get, 地 de = ground/land/earth (tagging error?)
            # DE Di: 了 le, 著 zhe, 過 guò, 起來 qǐlái, 起 qǐ
            'DE'   => ['pos' => 'part', 'case' => 'gen'],
            'Di'   => ['pos' => 'part', 'case' => 'gen', 'other' => {'subpos' => 'Di'}],
            # particle
            # T Ta: 了 le, 的 de, 來 lái, 去 qù, 嘛 ma
            # T Tb: 而已 éryǐ, 罷了 bàle, 沒有 méiyǒu, 也好 yěhǎo, 好了 hǎole
            # T Tc: 呢 ne, 吧 ba, 啊 a, 呀 ya, 啦 la
            # T Td: 嗎 ma, 來 lái, 去 qù, 與否 yǔfǒu, 矣 yǐ
            'Ta'   => ['pos' => 'part'],
            'Tb'   => ['pos' => 'part', 'other' => {'subpos' => 'b'}],
            'Tc'   => ['pos' => 'part', 'other' => {'subpos' => 'c'}],
            'Td'   => ['pos' => 'part', 'other' => {'subpos' => 'd'}],
            # interjection
            'I'    => ['pos' => 'int']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => { 'nountype' => { 'com'   => { 'other/subpos' => { 'ab'  => 'Nab',
                                                                                    'ac'  => 'Nac',
                                                                                    'ad'  => 'Nad',
                                                                                    'aea' => 'Naea',
                                                                                    'aeb' => 'Naeb',
                                                                                    '@'   => 'Naa' }},
                                                   'prop'  => { 'other/subpos' => { 'bc'  => 'Nbc',
                                                                                    '@'   => 'Nba' }},
                                                   'class' => { 'other/subpos' => { 'fc'  => 'Nfc',
                                                                                    'fd'  => 'Nfd',
                                                                                    'fe'  => 'Nfe',
                                                                                    'fg'  => 'Nfg',
                                                                                    'fh'  => 'Nfh',
                                                                                    'fi'  => 'Nfi',
                                                                                    '@'   => 'Nfa' }},
                                                   '@'     => { 'advtype' => { 'loc' => { 'other/subpos' => { 'cb'  => 'Ncb',
                                                                                                              'cc'  => 'Ncc',
                                                                                                              'cda' => 'Ncda',
                                                                                                              'cdb' => 'Ncdb',
                                                                                                              'ce'  => 'Nce',
                                                                                                              '@'   => 'Nca' }},
                                                                               'tim' => { 'other/subpos' => { 'daab' => 'Ndaab',
                                                                                                              'daac' => 'Ndaac',
                                                                                                              'daad' => 'Ndaad',
                                                                                                              'daba' => 'Ndaba',
                                                                                                              'dabb' => 'Ndabb',
                                                                                                              'dabc' => 'Ndabc',
                                                                                                              'dabd' => 'Ndabd',
                                                                                                              'dabe' => 'Ndabe',
                                                                                                              'dabf' => 'Ndabf',
                                                                                                              'dbb'  => 'Ndbb',
                                                                                                              'dc'   => 'Ndc',
                                                                                                              'dda'  => 'Ndda',
                                                                                                              'ddb'  => 'Nddb',
                                                                                                              'ddc'  => 'Nddc',
                                                                                                              '@'    => 'Ndaaa' }},
                                                                               '@'   => { 'prontype' => { 'prs' => { 'reflex' => { 'yes' => 'Nhab',
                                                                                                                                   '@'      => { 'polite' => { 'form' => 'Nhac',
                                                                                                                                                               '@'    => 'Nhaa' }}}},
                                                                                                          'int' => 'Nhb',
                                                                                                          'prn' => 'Nhc',
                                                                                                          '@'   => { 'other/subpos' => { 'v2' => 'Nv2',
                                                                                                                                         'v3' => 'Nv3',
                                                                                                                                         'v4' => 'Nv4',
                                                                                                                                         '@'  => 'Nv1' }}}}}}}},
                       'adj'  => { 'prontype' => { 'dem' => 'Nep',
                                                   'prn' => { 'other/subpos' => { 'qb' => 'Neqb',
                                                                                  's'  => 'Nes',
                                                                                  '@'  => 'Neqa' }},
                                                   '@'   => { 'nountype' => { 'class' => 'DM',
                                                                              '@'     => 'A' }}}},
                       'num'  => 'Neu',
                       'verb' => { 'other/subpos' => { 'A11' => 'VA11',
                                                       'A12' => 'VA12',
                                                       'A13' => 'VA13',
                                                       'A2'  => 'VA2',
                                                       'A3'  => 'VA3',
                                                       'A4'  => 'VA4',
                                                       'B11' => 'VB11',
                                                       'B12' => 'VB12',
                                                       'B2'  => 'VB2',
                                                       'C1'  => 'VC1',
                                                       'C2'  => 'VC2',
                                                       'C31' => 'VC31',
                                                       'C32' => 'VC32',
                                                       'C33' => 'VC33',
                                                       'D1'  => 'VD1',
                                                       'D2'  => 'VD2',
                                                       'E11' => 'VE11',
                                                       'E12' => 'VE12',
                                                       'E2'  => 'VE2',
                                                       'F1'  => 'VF1',
                                                       'F2'  => 'VF2',
                                                       'G1'  => 'VG1',
                                                       'G2'  => 'VG2',
                                                       'H11' => 'VH11',
                                                       'H12' => 'VH12',
                                                       'H13' => 'VH13',
                                                       'H14' => 'VH14',
                                                       'H15' => 'VH15',
                                                       'H16' => 'VH16',
                                                       'H17' => 'VH17',
                                                       'H21' => 'VH21',
                                                       'H22' => 'VH22',
                                                       'I1'  => 'VI1',
                                                       'I2'  => 'VI2',
                                                       'I3'  => 'VI3',
                                                       'J1'  => 'VJ1',
                                                       'J2'  => 'VJ2',
                                                       'J3'  => 'VJ3',
                                                       'K1'  => 'VK1',
                                                       'K2'  => 'VK2',
                                                       'L1'  => 'VL1',
                                                       'L2'  => 'VL2',
                                                       'L3'  => 'VL3',
                                                       'L4'  => 'VL4',
                                                       '_11' => 'V_11',
                                                       '_12' => 'V_12',
                                                       '_2'  => 'V_2',
                                                       '@'   => 'VB11' }},
                       'adv'  => { 'prontype' => { 'int' => 'Dj',
                                                   '@'   => { 'polarity' => { 'neg' => 'Dc',
                                                                              '@'   => { 'other/subpos' => { 'ab'  => 'Dab',
                                                                                                             'baa' => 'Dbaa',
                                                                                                             'bab' => 'Dbab',
                                                                                                             'bb'  => 'Dbb',
                                                                                                             'bc'  => 'Dbc',
                                                                                                             'd'   => 'Dd',
                                                                                                             'fa'  => 'Dfa',
                                                                                                             'fb'  => 'Dfb',
                                                                                                             'g'   => 'Dg',
                                                                                                             'h'   => 'Dh',
                                                                                                             'k'   => 'Dk',
                                                                                                             '@'   => 'Daa' }}}}}},
                       'adp'  => { 'adpostype' => { 'prep' => { 'other/subpos' => { 'P01' => 'P01',
                                                                                    'P02' => 'P02',
                                                                                    'P03' => 'P03',
                                                                                    'P04' => 'P04',
                                                                                    'P05' => 'P05',
                                                                                    'P07' => 'P07',
                                                                                    'P08' => 'P08',
                                                                                    'P09' => 'P09',
                                                                                    'P10' => 'P10',
                                                                                    'P11' => 'P11',
                                                                                    'P12' => 'P12',
                                                                                    'P13' => 'P13',
                                                                                    'P14' => 'P14',
                                                                                    'P15' => 'P15',
                                                                                    'P16' => 'P16',
                                                                                    'P17' => 'P17',
                                                                                    'P18' => 'P18',
                                                                                    'P19' => 'P19',
                                                                                    'P20' => 'P20',
                                                                                    'P21' => 'P21',
                                                                                    'P22' => 'P22',
                                                                                    'P23' => 'P23',
                                                                                    'P24' => 'P24',
                                                                                    'P25' => 'P25',
                                                                                    'P26' => 'P26',
                                                                                    'P27' => 'P27',
                                                                                    'P28' => 'P28',
                                                                                    'P29' => 'P29',
                                                                                    'P30' => 'P30',
                                                                                    'P31' => 'P31',
                                                                                    'P32' => 'P32',
                                                                                    'P33' => 'P33',
                                                                                    'P34' => 'P34',
                                                                                    'P35' => 'P35',
                                                                                    'P36' => 'P36',
                                                                                    'P37' => 'P37',
                                                                                    'P38' => 'P38',
                                                                                    'P39' => 'P39',
                                                                                    'P40' => 'P40',
                                                                                    'P41' => 'P41',
                                                                                    'P42' => 'P42',
                                                                                    'P43' => 'P43',
                                                                                    'P44' => 'P44',
                                                                                    'P45' => 'P45',
                                                                                    'P46' => 'P46',
                                                                                    'P47' => 'P47',
                                                                                    'P48' => 'P48',
                                                                                    'P49' => 'P49',
                                                                                    'P50' => 'P50',
                                                                                    'P51' => 'P51',
                                                                                    'P52' => 'P52',
                                                                                    'P53' => 'P53',
                                                                                    'P54' => 'P54',
                                                                                    'P55' => 'P55',
                                                                                    'P56' => 'P56',
                                                                                    'P57' => 'P57',
                                                                                    'P58' => 'P58',
                                                                                    'P59' => 'P59',
                                                                                    'P60' => 'P60',
                                                                                    'P61' => 'P61',
                                                                                    'P62' => 'P62',
                                                                                    'P63' => 'P63',
                                                                                    'P64' => 'P64',
                                                                                    'P65' => 'P65',
                                                                                    'P66' => 'P66',
                                                                                    # P06 is default because it also exists with P1, P2 and +part.
                                                                                    '@'   => 'P06' }},
                                                    'post' => 'Ng' }},
                       'conj' => { 'conjtype' => { 'coor' => { 'other/subpos' => { 'ab'  => 'Cab',
                                                                                   'bca' => 'Cbca',
                                                                                   'bcb' => 'Cbcb',
                                                                                   '@'   => 'Caa' }},
                                                   'sub'  => { 'other/subpos' => { 'bab' => 'Cbab',
                                                                                   'bba' => 'Cbba',
                                                                                   'bbb' => 'Cbbb',
                                                                                   '@'   => 'Cbaa' }}}},
                       'part' => { 'case' => { 'gen' => { 'other/subpos' => { 'Di' => 'Di',
                                                                              '@'  => 'DE' }},
                                               '@'   => { 'other/subpos' => { 'b'  => 'Tb',
                                                                              'c'  => 'Tc',
                                                                              'd'  => 'Td',
                                                                              '@'  => 'Ta' }}}},
                       'int'  => 'I' }
        }
    );
    # PAIRED TOKENS ####################
    # Certain tokens (e.g. some conjunctions) occur in pairs.
    # This feature tells whether this is the first or the second token in the pair.
    # Example: 又 yòu = also; it can be used in pairs: "又 X 又 Y" means "both X and Y".
    # The first 又 will be tagged Caa[P1]. The second 又 will be tagged Caa[P2].
    ###!!! At the moment we abuse the 'puncside' feature for this purpose.
    ###!!! We may want to rename the feature in future because in this case we do not work with punctuation.
    $atoms{pair} = $self->create_simple_atom
    (
        'intfeature' => 'puncside',
        'simple_decode_map' =>
        {
            'P1' => 'ini',
            'P2' => 'fin'
        }
    );
    # +SPO ####################
    # An undocumented and rare feature of nouns.
    # +SPV ####################
    # An undocumented and rare feature of verbs.
    # +part ####################
    # An undocumented and rare feature of prepositions.
    $atoms{undoc} = $self->create_atom
    (
        'surfeature' => 'undoc',
        'decode_map' =>
        {
            '+SPO'  => ['other' => {'undoc' => 'spo'}],
            '+SPV'  => ['other' => {'undoc' => 'spv'}],
            '+part' => ['other' => {'undoc' => 'part'}]
        },
        'encode_map' =>
        {
            'other/undoc' => { 'spo'  => '+SPO',
                               'spv'  => '+SPV',
                               'part' => '+part' }
        }
    );
    # +ASP ####################
    # A verb with incorporated aspect morpheme 了 le.
    # 走了過來 zǒuliǎoguòlái = go over
    # 走 zǒu = go
    # 走了 zǒuliǎo = gone (action completed)
    $atoms{asp} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            '+ASP' => 'perf'
        }
    );
    # +NEG ####################
    # A verb with incorporated negative morpheme 不 bù.
    # 回不去 huíbùqù = return+not+go = not return there
    # 回不來 huíbùlái = return+not+come = not return here
    $atoms{neg} = $self->create_simple_atom
    (
        'intfeature' => 'polarity',
        'simple_decode_map' =>
        {
            '+NEG' => 'neg'
        }
    );
    # +DE ####################
    # A verb with incorporated morpheme 得 dé = get.
    # 得 is a particle used after a verb or an adjective to express possibility or capability.
    # 看得見 kàndéjiàn = look+get+view = be able to see
    # 拿得到 nádédào = take+get+to = get them
    # 做得好 zuòdéhǎo = do+get+good = do well
    $atoms{de} = $self->create_atom
    (
        'surfeature' => 'de',
        'decode_map' =>
        {
            '+DE' => ['other' => {'de' => '1'}]
        },
        'encode_map' =>
        {
            'other/de' => { '1' => '+DE' }
        }
    );
    # MERGED ATOM TO DECODE ANY FEATURE VALUE ####################
    my @fatoms = map {$atoms{$_}} (@{$self->features_all()});
    $atoms{feature} = $self->create_merged_atom
    (
        'surfeature' => 'feature',
        'atoms'      => \@fatoms
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of all surface CoNLL features that can appear in the FEATS
# column. This list will be used in decode().
#------------------------------------------------------------------------------
sub _create_features_all
{
    my $self = shift;
    my @features = ('pair', 'undoc', 'neg', 'de', 'asp');
    return \@features;
}



#------------------------------------------------------------------------------
# Creates the list of surface CoNLL features that can appear in the FEATS
# column with particular parts of speech. This list will be used in encode().
#------------------------------------------------------------------------------
sub _create_features_pos
{
    my $self = shift;
    my %features =
    (
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('zh::conll');
    my $atoms = $self->atoms();
    # Three components: pos, subpos, features (always empty).
    # example: N\tNaa\t_
    my ($pos, $subpos, $dummy_features) = split(/\s+/, $tag);
    my @bracket_features;
    if($subpos =~ s/\[(.*)\]//)
    {
        @bracket_features = split(/,/, $1);
    }
    $atoms->{pos}->decode_and_merge_hard($subpos, $fs);
    foreach my $bf (@bracket_features)
    {
        $atoms->{feature}->decode_and_merge_hard($bf, $fs);
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $atoms = $self->atoms();
    my $subpos = $atoms->{pos}->encode($fs);
    my $pos = $subpos =~ m/^(DE|Di)$/ ? 'DE' : $subpos eq 'DM' ? 'DM' : $subpos =~ m/^(N[eg])/ ? $1 : substr($subpos, 0, 1);
    my @bracket_feature_names = @{$self->features_all()};
    my @features;
    foreach my $bfn (@bracket_feature_names)
    {
        my $value = $atoms->{$bfn}->encode($fs);
        unless($value eq '')
        {
            push(@features, $value);
        }
    }
    if(@features)
    {
        $subpos .= '['.join(',', @features).']';
    }
    # Dc is implicitly negative and it does not take the explicit [+NEG] feature.
    $subpos =~ s/Dc\[\+NEG\]/Dc/;
    my $tag = "$pos\t$subpos\t_";
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 294 distinct tags found.
# Cleaned up erroneous instances (e.g. with "[P2}" instead of "[P2]").
# 283 tags survived.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A\tA\t_
C\tCaa\t_
C\tCaa[P1]\t_
C\tCaa[P2]\t_
C\tCab\t_
C\tCbaa\t_
C\tCbab\t_
C\tCbba\t_
C\tCbbb\t_
C\tCbca\t_
C\tCbcb\t_
D\tDaa\t_
D\tDab\t_
D\tDbaa\t_
D\tDbab\t_
D\tDbb\t_
D\tDbc\t_
D\tDc\t_
D\tDd\t_
D\tDfa\t_
D\tDfb\t_
D\tDg\t_
D\tDh\t_
D\tDj\t_
D\tDk\t_
DE\tDE\t_
DE\tDi\t_
DM\tDM\t_
I\tI\t_
Ne\tNep\t_
Ne\tNeqa\t_
Ne\tNeqb\t_
Ne\tNes\t_
Ne\tNeu\t_
Ng\tNg\t_
N\tNaa\t_
N\tNaa[+SPO]\t_
N\tNab\t_
N\tNab[+SPO]\t_
N\tNac\t_
N\tNac[+SPO]\t_
N\tNad\t_
N\tNad[+SPO]\t_
N\tNaea\t_
N\tNaeb\t_
N\tNba\t_
N\tNbc\t_
N\tNca\t_
N\tNcb\t_
N\tNcc\t_
N\tNcda\t_
N\tNcdb\t_
N\tNce\t_
N\tNdaaa\t_
N\tNdaab\t_
N\tNdaac\t_
N\tNdaad\t_
N\tNdaba\t_
N\tNdabb\t_
N\tNdabc\t_
N\tNdabd\t_
N\tNdabe\t_
N\tNdabf\t_
N\tNdbb\t_
N\tNdc\t_
N\tNdda\t_
N\tNddb\t_
N\tNddc\t_
N\tNfa\t_
N\tNfc\t_
N\tNfd\t_
N\tNfe\t_
N\tNfg\t_
N\tNfh\t_
N\tNfi\t_
N\tNhaa\t_
N\tNhab\t_
N\tNhac\t_
N\tNhb\t_
N\tNhc\t_
N\tNv1\t_
N\tNv2\t_
N\tNv3\t_
N\tNv4\t_
P\tP01\t_
P\tP02\t_
P\tP03\t_
P\tP04\t_
P\tP06\t_
P\tP06[P1]\t_
P\tP06[P2]\t_
P\tP06[+part]\t_
P\tP07\t_
P\tP08\t_
P\tP08[+part]\t_
P\tP09\t_
P\tP10\t_
P\tP11\t_
P\tP11[P1]\t_
P\tP11[P2]\t_
P\tP11[+part]\t_
P\tP12\t_
P\tP13\t_
P\tP14\t_
P\tP15\t_
P\tP16\t_
P\tP17\t_
P\tP18\t_
P\tP18[+part]\t_
P\tP19\t_
P\tP19[P1]\t_
P\tP19[P2]\t_
P\tP19[+part]\t_
P\tP20\t_
P\tP20[+part]\t_
P\tP21\t_
P\tP21[+part]\t_
P\tP22\t_
P\tP23\t_
P\tP24\t_
P\tP25\t_
P\tP26\t_
P\tP27\t_
P\tP28\t_
P\tP29\t_
P\tP30\t_
P\tP31\t_
P\tP31[P1]\t_
P\tP31[P2]\t_
P\tP31[+part]\t_
P\tP32\t_
P\tP32[+part]\t_
P\tP35\t_
P\tP35[+part]\t_
P\tP36\t_
P\tP37\t_
P\tP38\t_
P\tP39\t_
P\tP40\t_
P\tP41\t_
P\tP42\t_
P\tP42[+part]\t_
P\tP43\t_
P\tP44\t_
P\tP45\t_
P\tP46\t_
P\tP46[+part]\t_
P\tP47\t_
P\tP48\t_
P\tP48[+part]\t_
P\tP49\t_
P\tP50\t_
P\tP51\t_
P\tP52\t_
P\tP53\t_
P\tP54\t_
P\tP55\t_
P\tP55[+part]\t_
P\tP58\t_
P\tP59\t_
P\tP59[+part]\t_
P\tP60\t_
P\tP61\t_
P\tP62\t_
P\tP63\t_
P\tP64\t_
P\tP65\t_
P\tP66\t_
T\tTa\t_
T\tTb\t_
T\tTc\t_
T\tTd\t_
V\tV_11\t_
V\tV_12\t_
V\tV_2\t_
V\tVA11\t_
V\tVA11[+ASP]\t_
V\tVA11[+NEG]\t_
V\tVA12\t_
V\tVA12[+NEG]\t_
V\tVA12[+SPV]\t_
V\tVA13\t_
V\tVA13[+ASP]\t_
V\tVA2\t_
V\tVA2[+ASP]\t_
V\tVA2[+SPV]\t_
V\tVA3\t_
V\tVA3[+ASP]\t_
V\tVA4\t_
V\tVA4[+ASP]\t_
V\tVA4[+NEG]\t_
V\tVA4[+NEG,+ASP]\t_
V\tVA4[+SPV]\t_
V\tVB11\t_
V\tVB11[+ASP]\t_
V\tVB11[+DE]\t_
V\tVB11[+NEG]\t_
V\tVB11[+NEG,+ASP]\t_
V\tVB11[+SPV]\t_
V\tVB12\t_
V\tVB12[+ASP]\t_
V\tVB12[+NEG]\t_
V\tVB2\t_
V\tVB2[+ASP]\t_
V\tVB2[+NEG]\t_
V\tVC1\t_
V\tVC1[+NEG]\t_
V\tVC1[+SPV]\t_
V\tVC2\t_
V\tVC2[+ASP]\t_
V\tVC2[+DE]\t_
V\tVC2[+NEG]\t_
V\tVC2[+SPV]\t_
V\tVC31\t_
V\tVC31[+ASP]\t_
V\tVC31[+DE]\t_
V\tVC31[+DE,+ASP]\t_
V\tVC31[+NEG]\t_
V\tVC31[+SPV]\t_
V\tVC32\t_
V\tVC32[+DE]\t_
V\tVC32[+SPV]\t_
V\tVC33\t_
V\tVD1\t_
V\tVD2\t_
V\tVD2[+NEG]\t_
V\tVE11\t_
V\tVE12\t_
V\tVE2\t_
V\tVE2[+DE]\t_
V\tVE2[+NEG]\t_
V\tVE2[+SPV]\t_
V\tVF1\t_
V\tVF2\t_
V\tVG1\t_
V\tVG1[+NEG]\t_
V\tVG2\t_
V\tVG2[+DE]\t_
V\tVG2[+NEG]\t_
V\tVH11\t_
V\tVH11[+ASP]\t_
V\tVH11[+DE]\t_
V\tVH11[+NEG]\t_
V\tVH11[+SPV]\t_
V\tVH12\t_
V\tVH12[+ASP]\t_
V\tVH13\t_
V\tVH14\t_
V\tVH15\t_
V\tVH15[+NEG]\t_
V\tVH16\t_
V\tVH16[+ASP]\t_
V\tVH16[+NEG]\t_
V\tVH16[+SPV]\t_
V\tVH17\t_
V\tVH21\t_
V\tVH21[+ASP]\t_
V\tVH21[+DE]\t_
V\tVH21[+NEG]\t_
V\tVH22\t_
V\tVI1\t_
V\tVI2\t_
V\tVI2[+ASP]\t_
V\tVI3\t_
V\tVJ1\t_
V\tVJ1[+DE]\t_
V\tVJ1[+NEG]\t_
V\tVJ2\t_
V\tVJ2[+NEG]\t_
V\tVJ2[+SPV]\t_
V\tVJ3\t_
V\tVJ3[+DE]\t_
V\tVJ3[+NEG]\t_
V\tVK1\t_
V\tVK1[+ASP]\t_
V\tVK1[+DE]\t_
V\tVK1[+NEG]\t_
V\tVK2\t_
V\tVK2[+NEG]\t_
V\tVL1\t_
V\tVL2\t_
V\tVL3\t_
V\tVL4\t_
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::ZH::Conll - Driver for the Chinese tagset of the CoNLL 2006 & 2007 Shared Tasks (derived from the Academia Sinica Treebank).

=head1 VERSION

version 3.008

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::ZH::Conll;
  my $driver = Lingua::Interset::Tagset::ZH::Conll->new();
  my $fs = $driver->decode("N\tNaa\t_");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('zh::conll', "N\tNaa\t_");

=head1 DESCRIPTION

Interset driver for the Chinese tagset of the CoNLL 2006 and 2007 Shared Tasks.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Chinese,
these values are derived from the tagset of the Academia Sinica Treebank
and the FEAT column is always empty.

Some documentation can be found here:
L<http://ckip.iis.sinica.edu.tw/CKIP/engversion/20corpus.htm>.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
