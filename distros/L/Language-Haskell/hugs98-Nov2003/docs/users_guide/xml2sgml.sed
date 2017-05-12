/<?xml/d
/^<!ENTITY %/,/>/d
/^%/d
/^<!ENTITY/ s/\.xml/.sgml/
/^<!DOCTYPE/,/\[/ {
	s/ XML / /
	s/[ 	]*"[a-z]*:[^"]*"[ 	]*//
	/^$/d
}
s:/>:>:g
