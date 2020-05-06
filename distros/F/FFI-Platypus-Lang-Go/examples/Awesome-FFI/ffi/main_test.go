package main

import (
	"testing"
)

func TestAdd(t *testing.T) {
	got := Add(1,2)
	if got != 3 {
		t.Errorf("Add(1,2) = %d; want 3", got)
	}
}
