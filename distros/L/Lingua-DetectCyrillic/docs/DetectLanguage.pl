#!/usr/bin/perl -w

require "Languages.inc"; # получили @AvailableLangs
my $AcceptLang=$ENV{HTTP_ACCEPT_LANGUAGE};

#print "content-type: text/html\n\n";

if ( $AcceptLang ) { # Если переменная HTTP-ACCEPT-LANGUAGE от браузера получена
# Перебираем список @AvailableLangs и выходим, как только наткнемся на нужный язык
  for  ( @{$AvailableLangs} ) {
   if ($AcceptLang=~/$_/ ) { $DefaultLang=$_; last;}
  }
}

( $ScriptPath )=( $ENV{SCRIPT_NAME} =~ m|(/.*/)(.*)$| );
#print "Refresh: 0; url=$ScriptPath$DefaultLang\n\n";
print "Location: $ScriptPath$DefaultLang\n\n";



