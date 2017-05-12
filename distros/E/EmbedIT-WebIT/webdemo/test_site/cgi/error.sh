#!/bin/sh

echo "<html>"
echo "<body>"

echo "<h3> This is a shell script cgi that produces an error on STDERR</h3>"

set | sed ':a;N;$!ba;s/\n/\<br\/\>\n/g'

echo "</body>"
echo "</html>"

echo "This is a CGI error" >&2
