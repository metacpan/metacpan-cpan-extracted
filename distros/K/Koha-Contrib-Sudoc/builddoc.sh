#!/bin/bash

mkdir doc
asciidoctor README.adoc -o doc/sudoc.html
asciidoctor-pdf -a pdf-stylesdir=pdftheme -a pdf-style=tamil README.adoc -o doc/sudoc.pdf

