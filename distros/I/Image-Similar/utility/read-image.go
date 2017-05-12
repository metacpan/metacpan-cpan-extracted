package main

import (
	"fmt"
	"image"
	_ "image/gif"
	_ "image/jpeg"
	_ "image/png"
	"os"
	"regexp"
)

var looksLikeImage = regexp.MustCompile(`\.(?i:jpe?g|png|gif)`)

type ImageSignature struct {
	height int
	width int
	data [][]byte
	Image image.Image
}

func pixel(grey float64) {
	if grey < 0.1 {
		fmt.Printf("@")	
	} else if grey < 0.2 {
		fmt.Printf("%%")
	} else if grey < 0.3 {
		fmt.Printf("#")
	} else if grey < 0.4 {
		fmt.Printf("=")
	} else if grey < 0.5 {
		fmt.Printf("x")
	} else if grey < 0.6 {
		fmt.Printf("*")
	} else if grey < 0.8 {
		fmt.Printf(":")
	} else if grey < 0.9 {
		fmt.Printf(".")
	} else {
		fmt.Printf(" ")
	}
}

func (is ImageSignature) WritePng(fileName string) {

}

func (is ImageSignature) GetData(Image image.Image) {
	var i int = 0
	is.width = Image.Bounds().Max.Y - Image.Bounds().Min.Y + 1 
	is.height = Image.Bounds().Max.X - Image.Bounds().Min.X + 1 
	is.data = make([][]byte, is.height)
	for y := Image.Bounds().Min.Y; y < Image.Bounds().Max.Y; y++ {
		var j int = 0
		is.data[i] = make([]byte, is.width)
		for x := Image.Bounds().Min.X; x < Image.Bounds().Max.X; x++ {
			colour := Image.At(x, y)
			r, g, b, _ := colour.RGBA()
			grey := (0.222 * float64(r) +
				0.707 * float64(g) +
				0.071 * float64(b))/float64(0xffff)
			is.data[i][j] = uint8(grey*256)
			j++
		}
		i++
	}
}

func makeSignature(Image image.Image) (is ImageSignature) {
	is.GetData(Image)
	is.WritePng("grey.png")
	return is
}

func readImage(name string) {
	jpeg, err := os.Open(name)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening %s: %s\n",
			name, err)
		return
	}
	defer jpeg.Close()
	Image, _, err := image.Decode(jpeg)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error decoding %s: %s\n",
			name, err);
		return
	}
	makeSignature(Image)
}

func main() {
	for _, name := range os.Args {
		if looksLikeImage.MatchString(name) {
			readImage(name)
		}
	}
}
