package makehtml

type MakeHTML interface {
	Text() string
	Push()
}

func MakePage() (html, body MakeHTML) {

}
