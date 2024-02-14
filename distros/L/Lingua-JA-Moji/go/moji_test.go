package moji

import "testing"

func TestRomaji(t *testing.T) {
	baka := "ばか"
	if Romaji(baka) != "baka" {
		t.Errorf("%s != %s\n", Romaji(baka), "baka")
	}
}
