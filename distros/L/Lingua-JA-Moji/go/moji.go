package moji

import "strings"

func KataHira(kata rune) rune {
	/* Katakana to hiragana */
	if kata >= 0x30a0 && kata <= 0x30ff {
		kata -= 0x60
	}
	return kata
}

func Romaji(kana string) (romaji string) {
	runes := []rune(kana)
	for _, r := range runes {
		r = KataHira(r)
		romaji += Consonant[r] + Vowel[r]
	}
	romaji = strings.Replace(romaji, "sixy", "sh", -1)
	romaji = strings.Replace(romaji, "ixy", "y", -1)
	romaji = strings.Replace(romaji, "zy", "j", -1)
	romaji = strings.Replace(romaji, "si", "shi", -1)
	romaji = strings.Replace(romaji, "tu", "tsu", -1)
	romaji = strings.Replace(romaji, "ty", "ch", -1)

	reformat := strings.NewReplacer(
		"ixy", "y",
		"zy", "j",
		"si", "shi",
		"tu", "tsu",
		"ty", "ch",
		"ti", "chi",
		"hu", "fu",
		"zi", "ji",
	)
	romaji = reformat.Replace(romaji)
	return romaji
}

func RomajiToKana(romaji string) (kana string) {
	kana = romaji
	dc := strings.NewReplacer(
		"ss", "っs",
		"hh", "っh",
		"bb", "っb",
		"pp", "っp",
		"kk", "っk",
		"tt", "っt",
		"tch", "っch",
		"mb", "んb",
		"nn", "んn",
	)
	k2r := strings.NewReplacer(
		"shi", "し",
		"chi", "ち",
		"tsu", "つ",
		"cha", "ちゃ",
		"cha", "ちょ",
		"chu", "ちゅ",
		"kyo", "きょ",
		"kya", "きゃ",
		"kyu", "きゅ",
		"rya", "りゃ",
		"ryu", "りゅ",
		"ryo", "りょ",
		"sya", "しゃ",
		"syu", "しゅ",
		"syo", "しょ",
		"sha", "しゃ",
		"shu", "しゅ",
		"sho", "しょ",
		"ja", "じゃ",
		"ju", "じゅ",
		"jo", "じょ",
		"ka", "か",
		"ki", "き",
		"ku", "く",
		"ke", "け",
		"ko", "こ",
		"ga", "が",
		"gi", "ぎ",
		"gu", "ぐ",
		"ge", "げ",
		"go", "ご",
		"sa", "さ",
		"si", "し",
		"su", "す",
		"se", "せ",
		"so", "そ",
		"ta", "た",
		"ti", "ち",
		"tu", "つ",
		"te", "て",
		"to", "と",
		"na", "な",
		"ni", "に",
		"nu", "ぬ",
		"ne", "ね",
		"no", "の",
		"ha", "は",
		"hi", "ひ",
		"hu", "ふ",
		"fu", "ふ",
		"he", "へ",
		"ho", "ほ",
		"ma", "ま",
		"mi", "み",
		"mu", "む",
		"me", "め",
		"mo", "も",
		"ra", "ら",
		"ri", "り",
		"ru", "る",
		"re", "れ",
		"ro", "ろ",
		"ji", "じ",
		"zi", "じ",
		"za", "ざ",
		"zu", "ず",
		"zo", "ぞ",
		"ze", "ぜ",
		"zi", "じ",
		"da", "だ",
		"du", "づ",
		"do", "ど",
		"de", "で",
		"ba", "ば",
		"bi", "び",
		"bu", "ぶ",
		"be", "べ",
		"bo", "ぼ",
		"pa", "ぱ",
		"pi", "び",
		"pu", "ぷ",
		"pe", "ぺ",
		"po", "ぽ",
		"ya", "や",
		"yu", "ゆ",
		"yo", "よ",
		"wa", "わ",
		"a", "あ",
		"i", "い",
		"u", "う",
		"e", "え",
		"o", "お",
		"n", "ん",
	)
	kana = dc.Replace(kana)
	kana = k2r.Replace(kana)
	return kana
}
