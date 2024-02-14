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
	)
	romaji = reformat.Replace(romaji)
	return romaji
}
