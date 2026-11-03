package simple

import (
	"encoding/binary"
	"os"
	"strings"
	"sync"
)

// catalog is one parsed .mo file: msgid (with "ctxt\x04" prefix when present)
// to the list of translation forms, plus the plural rule of its header.
type catalog struct {
	entries map[string][]string
	rule    pluralRule
}

var (
	catalogMu sync.Mutex
	catalogs  = map[string]*catalog{} // nil value: file missing or unusable
)

// loadCatalog returns the catalog of a .mo path, reading it once per process.
// Both the package functions and every Translator go through this cache.
func loadCatalog(path string) *catalog {
	catalogMu.Lock()
	defer catalogMu.Unlock()
	if c, ok := catalogs[path]; ok {
		return c
	}
	var c *catalog
	if data, err := os.ReadFile(path); err == nil {
		c = parseMo(data)
	}
	catalogs[path] = c
	return c
}

func resetCatalogs() {
	catalogMu.Lock()
	catalogs = map[string]*catalog{}
	catalogMu.Unlock()
}

// parseMo reads the GNU .mo format (spec: .claude/skills/locale-simple-core/references/mo-reader.md §1).
// Any structural problem rejects the whole file and yields nil.
func parseMo(d []byte) *catalog {
	if len(d) < 28 {
		return nil
	}
	var bo binary.ByteOrder
	switch binary.LittleEndian.Uint32(d) {
	case 0x950412de:
		bo = binary.LittleEndian
	case 0xde120495:
		bo = binary.BigEndian
	default:
		return nil
	}
	if bo.Uint32(d[4:])>>16 != 0 {
		return nil
	}
	n := uint64(bo.Uint32(d[8:]))
	o := uint64(bo.Uint32(d[12:]))
	t := uint64(bo.Uint32(d[16:]))
	size := uint64(len(d))
	if o+8*n > size || t+8*n > size {
		return nil
	}
	entries := make(map[string][]string, n)
	for i := uint64(0); i < n; i++ {
		ol, oo := uint64(bo.Uint32(d[o+8*i:])), uint64(bo.Uint32(d[o+8*i+4:]))
		tl, to := uint64(bo.Uint32(d[t+8*i:])), uint64(bo.Uint32(d[t+8*i+4:]))
		if oo+ol > size || to+tl > size {
			return nil
		}
		orig := string(d[oo : oo+ol])
		trans := string(d[to : to+tl])
		key := orig
		if z := strings.IndexByte(orig, 0); z >= 0 {
			key = orig[:z]
		}
		entries[key] = strings.Split(trans, "\x00")
	}
	var header *string
	if h, ok := entries[""]; ok {
		s := strings.Join(h, "\x00")
		header = &s
		delete(entries, "")
	}
	return &catalog{entries: entries, rule: ruleFromHeader(header)}
}
