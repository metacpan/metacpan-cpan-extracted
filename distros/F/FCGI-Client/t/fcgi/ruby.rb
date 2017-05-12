#!/usr/bin/ruby
load 't/fcgi/fcgi.rb'

FCGI.each {|f|
    f.err.print("hello, stderr\n")
    f.out.print("Content−type: text/html\r\n\r\nhello\n#{ f.env['QUERY_STRING'] }")
}

