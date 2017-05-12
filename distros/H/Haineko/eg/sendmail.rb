#!/usr/bin/env ruby
# coding : utf-8
require 'rubygems';
require 'open-uri'
require 'json'
require 'uri'
require 'net/http'

credential = { 
    :username => 'haineko', 
    :password => 'kijitora',
}
clientname = `hostname`.rstrip
emaildata1 = {
    :'ehlo' => clientname,
    :'mail' => 'envelope-sender@example.jp',
    :'rcpt' => [ 'envelope-recipient@example.org' ],
    :'body' => 'メール本文です。',
    :'header' => {
        :'from' => 'キジトラ <envelope-sender@example.jp>',
        :'subject' => 'テストメール',
        :'replyto' => 'neko@example.jp'
    }
}

hainekourl = URI.parse('http://127.0.0.1:2794/submit')
httpobject = Net::HTTP.new( hainekourl.host, hainekourl.port )
htrequest1 = Net::HTTP::Post.new( hainekourl.path )
htrequest1.body = emaildata1.to_json

if( ENV['HAINEKO_AUTH'] or $*[0] )
    htrequest1.basic_auth( credential[:'username'], credential[:'password'] )
end
htresponse = httpobject.request( htrequest1 )
puts htresponse.body

