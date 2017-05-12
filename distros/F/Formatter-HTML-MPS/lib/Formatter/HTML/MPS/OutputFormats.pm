package Formatter::HTML::MPS::OutputFormats;

use strict;
use warnings;

use Exporter;
use vars qw( @ISA @EXPORT $VERSION);

@ISA = qw( Exporter );
@EXPORT = qw( %HEADERS %FOOTERS %CSS );
$VERSION = '0.2';

our %HEADERS = (
                'xhtml1.0_strict' =>
q{<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
<meta name="generator" content="Formatter::HTML::MPS"/>
<title>$title</title>
$css
</head>
<body>

}
    
);

our %CSS = ( 'xhtml1.0_strict' =>
             { link => q{<link rel="stylesheet" type="text/css" href="$cssfile" media="projection" />},
               inline => q{<style type="text/css">$content</style>} }
            );

our %FOOTERS = (
                'xhtml1.0_strict' =>
q{
</body>
</html>
}
    

);
