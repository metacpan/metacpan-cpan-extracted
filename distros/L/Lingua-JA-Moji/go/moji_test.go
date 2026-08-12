package moji

import "testing"

func romajiInOut(t *testing.T, in, out string) {
	r := RomajiToKana(in)
	if r != out {
		t.Errorf("%s != %s\n", r, out)
	}
}

func TestRomajiToKana(t *testing.T) {
	romajiInOut(t, "baka", "ばか")
	romajiInOut(t, "shimbun", "しんぶん")
	romajiInOut(t, "sisso", "しっそ")
	romajiInOut(t, "natchi", "なっち")
	romajiInOut(t, "geki", "げき")
}
func TestRomaji(t *testing.T) {
	baka := "ばか"
	if Romaji(baka) != "baka" {
		t.Errorf("%s != %s\n", Romaji(baka), "baka")
	}
}
