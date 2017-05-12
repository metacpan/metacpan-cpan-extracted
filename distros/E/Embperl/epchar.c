/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epchar.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/

/* input and output escaping for iso-8859-1 (iso-latin-1) */

#include "ep.h"



/*
* Character Translation
*/


struct tCharTrans Char2Html [] = 

    {
        { ' ' ,   ""         },    /* &#00;		Unused */ 
        { ' ' ,   ""         },    /* &#01;		Unused */
        { ' ' ,   ""         },    /* &#02;		Unused  */
        { ' ' ,   ""         },    /* &#03;		Unused  */
        { ' ' ,   ""         },    /* &#04;		Unused  */
        { ' ' ,   ""         },    /* &#05;		Unused  */
        { ' ' ,   ""         },    /* &#06;		Unused  */
        { ' ' ,   ""         },    /* &#07;		Unused  */
        { ' ' ,   ""         },    /* &#08;		Unused  */
        { ' ' ,   ""         },    /* &#09;		Horizontal tab  */
        { ' ' ,   ""         },    /* &#10;		Line feed  */
        { ' ' ,   ""         },    /* &#11;		Unused  */
        { ' ' ,   ""         },    /* &#12;		Unused  */
        { ' ' ,   ""         },    /* &#13;		Carriage Return  */
        { ' ' ,   ""         },    /* &#14;		Unused  */
        { ' ' ,   ""         },    /* &#15;		Unused  */
        { ' ' ,   ""         },    /* &#16;		Unused  */
        { ' ' ,   ""         },    /* &#17;		Unused  */
        { ' ' ,   ""         },    /* &#18;		Unused  */
        { ' ' ,   ""         },    /* &#19;		Unused  */
        { ' ' ,   ""         },    /* &#20;		Unused  */
        { ' ' ,   ""         },    /* &#21;		Unused  */
        { ' ' ,   ""         },    /* &#22;		Unused  */
        { ' ' ,   ""         },    /* &#23;		Unused  */
        { ' ' ,   ""         },    /* &#24;		Unused  */
        { ' ' ,   ""         },    /* &#25;		Unused  */
        { ' ' ,   ""         },    /* &#26;		Unused  */
        { ' ' ,   ""         },    /* &#27;		Unused  */
        { ' ' ,   ""         },    /* &#28;		Unused  */
        { ' ' ,   ""         },    /* &#29;		Unused  */
        { ' ' ,   ""         },    /* &#30;		Unused  */
        { ' ' ,   ""         },    /* &#31;		Unused  */
        { ' ' ,   ""         },    /* 	&#32;		Space  */
        { '!' ,   ""         },    /* 	&#33;		Exclamation mark  */
        { '"' ,   "&quot;"   },    /* 	Quotation mark  */
        { '#' ,   ""         },    /* 	&#35;		Number sign  */
        { '$' ,   ""         },    /* 	&#36;		Dollar sign  */
        { '%' ,   ""         },    /* 	&#37;		Percent sign  */
        { '&' ,   "&amp;"    },    /* 	Ampersand  */
        { '\'' ,  ""         },    /* 	&#39;		Apostrophe  */
        { '(' ,   ""         },    /* 	&#40;		Left parenthesis  */
        { ')' ,   ""         },    /* 	&#41;		Right parenthesis  */
        { '*' ,   ""         },    /* 	&#42;		Asterisk  */
        { '+' ,   ""         },    /* 	&#43;		Plus sign  */
        { ',' ,   ""         },    /* 	&#44;		Comma  */
        { '-' ,   ""         },    /* 	&#45;		Hyphen  */
        { '.' ,   ""         },    /* 	&#46;		Period (fullstop)  */
        { '/' ,   ""         },    /* 	&#47;		Solidus (slash)  */
        { '0' ,   ""         },    /* 	&#48;		Digit 0  */
        { '1' ,   ""         },    /* 	&#49;		Digit 1  */
        { '2' ,   ""         },    /* 	&#50;		Digit 2  */
        { '3' ,   ""         },    /* 	&#51;		Digit 3  */
        { '4' ,   ""         },    /* 	&#52;		Digit 4  */
        { '5' ,   ""         },    /* 	&#53;		Digit 5  */
        { '6' ,   ""         },    /* 	&#54;		Digit 6  */
        { '7' ,   ""         },    /* 	&#55;		Digit 7  */
        { '8' ,   ""         },    /* 	&#56;		Digit 8  */
        { '9' ,   ""         },    /* 	&#57;		Digit 9  */
        { ':' ,   ""         },    /* 	&#58;		Colon  */
        { ';' ,   ""         },    /* 	&#59;		Semicolon  */
        { '<' ,   "&lt;"     },    /* 	Less than  */
        { '=' ,   ""         },    /* 	&#61;		Equals sign  */
        { '>' ,   "&gt;"     },    /* 	Greater than  */
        { '?' ,   ""         },    /* 	&#63;		Question mark  */
        { '@' ,   ""         },    /* 	&#64;		Commercial at  */
        { 'A' ,   ""         },    /* 	&#65;		Capital A  */
        { 'B' ,   ""         },    /* 	&#66;		Capital B  */
        { 'C' ,   ""         },    /* 	&#67;		Capital C  */
        { 'D' ,   ""         },    /* 	&#68;		Capital D  */
        { 'E' ,   ""         },    /* 	&#69;		Capital E  */
        { 'F' ,   ""         },    /* 	&#70;		Capital F  */
        { 'G' ,   ""         },    /* 	&#71;		Capital G  */
        { 'H' ,   ""         },    /* 	&#72;		Capital H  */
        { 'I' ,   ""         },    /* 	&#73;		Capital I  */
        { 'J' ,   ""         },    /* 	&#74;		Capital J  */
        { 'K' ,   ""         },    /* 	&#75;		Capital K  */
        { 'L' ,   ""         },    /* 	&#76;		Capital L  */
        { 'M' ,   ""         },    /* 	&#77;		Capital M  */
        { 'N' ,   ""         },    /* 	&#78;		Capital N  */
        { 'O' ,   ""         },    /* 	&#79;		Capital O  */
        { 'P' ,   ""         },    /* 	&#80;		Capital P  */
        { 'Q' ,   ""         },    /* 	&#81;		Capital Q  */
        { 'R' ,   ""         },    /* 	&#82;		Capital R  */
        { 'S' ,   ""         },    /* 	&#83;		Capital S  */
        { 'T' ,   ""         },    /* 	&#84;		Capital T  */
        { 'U' ,   ""         },    /* 	&#85;		Capital U  */
        { 'V' ,   ""         },    /* 	&#86;		Capital V  */
        { 'W' ,   ""         },    /* 	&#87;		Capital W  */
        { 'X' ,   ""         },    /* 	&#88;		Capital X  */
        { 'Y' ,   ""         },    /* 	&#89;		Capital Y  */
        { 'Z' ,   ""         },    /* 	&#90;		Capital Z  */
        { '[' ,   ""         },    /* 	&#91;		Left square bracket  */
        { '\\' ,  ""         },    /* 	&#92;		Reverse solidus (backslash)  */
        { ']' ,   ""         },    /* 	&#93;		Right square bracket  */
        { '^' ,   ""         },    /* 	&#94;		Caret  */
        { '_' ,   ""         },    /* 	&#95;		Horizontal bar (underscore)  */
        { '`' ,   ""         },    /* 	&#96;		Acute accent  */
        { 'a' ,   ""         },    /* 	&#97;		Small a  */
        { 'b' ,   ""         },    /* 	&#98;		Small b  */
        { 'c' ,   ""         },    /* 	&#99;		Small c  */
        { 'd' ,   ""         },    /* 	&#100;		Small d  */
        { 'e' ,   ""         },    /* 	&#101;		Small e  */
        { 'f' ,   ""         },    /* 	&#102;		Small f  */
        { 'g' ,   ""         },    /* 	&#103;		Small g  */
        { 'h' ,   ""         },    /* 	&#104;		Small h  */
        { 'i' ,   ""         },    /* 	&#105;		Small i  */
        { 'j' ,   ""         },    /* 	&#106;		Small j  */
        { 'k' ,   ""         },    /* 	&#107;		Small k  */
        { 'l' ,   ""         },    /* 	&#108;		Small l  */
        { 'm' ,   ""         },    /* 	&#109;		Small m  */
        { 'n' ,   ""         },    /* 	&#110;		Small n  */
        { 'o' ,   ""         },    /* 	&#111;		Small o  */
        { 'p' ,   ""         },    /* 	&#112;		Small p  */
        { 'q' ,   ""         },    /* 	&#113;		Small q  */
        { 'r' ,   ""         },    /* 	&#114;		Small r  */
        { 's' ,   ""         },    /* 	&#115;		Small s  */
        { 't' ,   ""         },    /* 	&#116;		Small t  */
        { 'u' ,   ""         },    /* 	&#117;		Small u  */
        { 'v' ,   ""         },    /* 	&#118;		Small v  */
        { 'w' ,   ""         },    /* 	&#119;		Small w  */
        { 'x' ,   ""         },    /* 	&#120;		Small x  */
        { 'y' ,   ""         },    /* 	&#121;		Small y  */
        { 'z' ,   ""         },    /* 	&#122;		Small z  */
        { '{' ,   ""         },    /* 	&#123;		Left curly brace  */
        { '|' ,   ""         },    /* 	&#124;		Vertical bar  */
        { '}' ,   ""         },    /* 	&#125;		Right curly brace  */
        { '~' ,   ""         },    /* 	&#126;		Tilde  */
        { '' ,   ""         },    /* 	&#127;		Unused  */
        { '\x80' ,   "&#128;"         },    /* 	&#128;		Unused */
        { '\x81' ,   "&#129;"         },    /* &#129;		Unused  */
        { '\x82' ,   "&#130;"         },    /* &#130;		Unused  */
        { '\x83' ,   "&#131;"         },    /* &#131;		Unused  */
        { '\x84' ,   "&#132;"         },    /* &#132;		Unused  */
        { '\x85' ,   "&#133;"         },    /* &#133;		Unused  */
        { '\x86' ,   "&#134;"         },    /* &#134;		Unused  */
        { '\x87' ,   "&#135;"         },    /* &#135;		Unused  */
        { '\x88' ,   "&#136;"         },    /* &#136;		Unused  */
        { '\x89' ,   "&#137;"         },    /* &#137;		Unused  */
        { '\x8a' ,   "&#138;"         },    /* &#138;		Horizontal tab  */
        { '\x8b' ,   "&#139;"         },    /* &#139;		Line feed  */
        { '\x8c' ,   "&#140;"         },    /* &#140;		Unused  */
        { '\x8d' ,   "&#141;"         },    /* &#141;		Unused  */
        { '\x8e' ,   "&#142;"         },    /* &#142;		Carriage Return  */
        { '\x8f' ,   "&#143;"         },    /* &#143;		Unused  */
        { '\x90' ,   "&#144;"         },    /* &#144;		Unused  */
        { '\x91' ,   "&#145;"         },    /* &#145;		Unused  */
        { '\x92' ,   "&#146;"         },    /* &#146;		Unused  */
        { '\x93' ,   "&#147;"         },    /* &#147;		Unused  */
        { '\x94' ,   "&#148;"         },    /* &#148;		Unused  */
        { '\x95' ,   "&#149;"         },    /* &#149;		Unused  */
        { '\x96' ,   "&#150;"         },    /* &#150;		Unused  */
        { '\x97' ,   "&#151;"         },    /* &#151;		Unused  */
        { '\x98' ,   "&#152;"         },    /* &#152;		Unused  */
        { '\x99' ,   "&#153;"         },    /* &#153;		Unused  */
        { '\x9a' ,   "&#154;"         },    /* &#154;		Unused  */
        { '\x9b' ,   "&#155;"         },    /* &#155;		Unused  */
        { '\x9c' ,   "&#156;"         },    /* &#156;		Unused  */
        { '\x9d' ,   "&#157;"         },    /* &#157;		Unused  */
        { '\x9e' ,   "&#158;"         },    /* &#158;		Unused  */
        { '\x9f' ,   "&#159;"         },    /* &#159;		Unused  */
        { '\xa0' ,   "&nbsp;"   },    /* 	Non-breaking Space  */
        { '¡' ,   "&iexcl;"  },    /* 	Inverted exclamation    */
        { '¢' ,   "&cent;"   },    /* 	Cent sign               */
        { '£' ,   "&pound;"  },    /* 	Pound sterling  */
        { '¤' ,   "&curren;" },    /* 	General currency sign  */
        { '¥' ,   "&yen;"    },    /* 	Yen sign  */
/*        { '¦' ,   "&brvbar;" },    / *  	Broken vertical bar  */
        { '¦' ,   "&brkbar;" },    /* 	Broken vertical bar  */
        { '§' ,   "&sect;"  },    /* 	Section sign  */
/*        { '¨' ,   "&&um;"    },    / *  	Diæresis / Umlaut  */
        { '¨' ,   "&die;"   },    /* 	Diæresis / Umlaut  */
        { '©' ,   "&copy;"  },    /* 	Copyright               */
        { 'ª' ,   "&ordf;"  },    /* 	Feminine ordinal  */
        { '«' ,   "&laquo;" },    /* 	Left angle quote, guillemot left  */
        { '¬' ,   "&euro;"   },    /*	Euro sign  */
        { '­' ,   "&shy;"    },    /* 	Soft hyphen  */
        { '®' ,   "&reg;"    },    /* 	Registered trademark  */
/*        { '¯' ,   "&macr;"   },    / *  	Macron accent  */
        { '¯' ,   "&hibar;"  },    /* 	Macron accent  */
        { '°' ,   "&deg;"    },    /* 	Degree sign  */
        { '±' ,   "&plusmn;" },    /* 	Plus or minus  */
        { '²' ,   "&sup2;"   },    /* 	Superscript two  */
        { '³' ,   "&sup3;"   },    /* 	Superscript three  */
        { '´' ,   "&acute;"  },    /* 	Acute accent  */
        { 'µ' ,   "&micro;"  },    /* 	Micro sign  */
        { '¶' ,   "&para;"   },    /* 	Paragraph sign  */
        { '·' ,   "&middot;" },    /* 	Middle dot  */
        { '¸' ,   "&cedil;"  },    /* 	Cedilla  */
        { '¹' ,   "&sup1;"   },    /* 	Superscript one  */
        { 'º' ,   "&ordm;"   },    /* 	Masculine ordinal  */
        { '»' ,   "&raquo;"  },    /* 	Right angle quote, guillemot right  */
        { '¼' ,   "&frac14;" },    /* 	Fraction one-fourth  */
        { '½' ,   "&frac12;" },    /* 	Fraction one-half  */
        { '¾' ,   "&frac34;" },    /* 	Fraction three-fourths  */
        { '¿' ,   "&iquest;" },    /* 	Inverted question mark  */
        { 'À' ,   "&Agrave;" },    /* 	Capital A, grave accent  */
        { 'Á' ,   "&Aacute;" },    /* 	Capital A, acute accent  */
        { 'Â' ,   "&Acirc;"  },    /* 	Capital A, circumflex  */
        { 'Ã' ,   "&Atilde;" },    /* 	Capital A, tilde  */
        { 'Ä' ,   "&Auml;"   },    /* 	Capital A, diæresis / umlaut  */
        { 'Å' ,   "&Aring;"  },    /* 	Capital A, ring  */
        { 'Æ' ,   "&AElig;"  },    /* 	Capital AE ligature  */
        { 'Ç' ,   "&Ccedil;" },    /* 	Capital C, cedilla  */
        { 'È' ,   "&Egrave;" },    /* 	Capital E, grave accent  */
        { 'É' ,   "&Eacute;" },    /* 	Capital E, acute accent  */
        { 'Ê' ,   "&Ecirc;"  },    /* 	Capital E, circumflex  */
        { 'Ë' ,   "&Euml;"   },    /* 	Capital E, diæresis / umlaut  */
        { 'Ì' ,   "&Igrave;" },    /* 	Capital I, grave accent  */
        { 'Í' ,   "&Iacute;" },    /* 	Capital I, acute accent  */
        { 'Î' ,   "&Icirc;"  },    /* 	Capital I, circumflex  */
        { 'Ï' ,   "&Iuml;"   },    /* 	Capital I, diæresis / umlaut  */
        { 'Ð' ,   "&ETH;"    },    /* 	Capital Eth, Icelandic  */
        { 'Ñ' ,   "&Ntilde;" },    /* 	Capital N, tilde  */
        { 'Ò' ,   "&Ograve;" },    /* 	Capital O, grave accent  */
        { 'Ó' ,   "&Oacute;" },    /* 	Capital O, acute accent  */
        { 'Ô' ,   "&Ocirc;"  },    /* 	Capital O, circumflex  */
        { 'Õ' ,   "&Otilde;" },    /* 	Capital O, tilde  */
        { 'Ö' ,   "&Ouml;"   },    /* 	Capital O, diæresis / umlaut  */
        { '×' ,   "&times;"  },    /* 	Multiply sign  */
        { 'Ø' ,   "&Oslash;" },    /* 	Capital O, slash  */
        { 'Ù' ,   "&Ugrave;" },    /* 	Capital U, grave accent  */
        { 'Ú' ,   "&Uacute;" },    /* 	Capital U, acute accent  */
        { 'Û' ,   "&Ucirc;"  },    /* 	Capital U, circumflex  */
        { 'Ü' ,   "&Uuml;"   },    /* 	Capital U, diæresis / umlaut  */
        { 'Ý' ,   "&Yacute;" },    /* 	Capital Y, acute accent  */
        { 'Þ' ,   "&THORN;"  },    /* 	Capital Thorn, Icelandic  */
        { 'ß' ,   "&szlig;"  },    /* 	Small sharp s, German sz  */
        { 'à' ,   "&agrave;" },    /* 	Small a, grave accent  */
        { 'ß' ,   "&aacute;" },    /* 	Small a, acute accent  */
        { 'â' ,   "&acirc;"  },    /* 	Small a, circumflex  */
        { 'ã' ,   "&atilde;" },    /* 	Small a, tilde  */
        { 'ä' ,   "&auml;"   },    /* 	Small a, diæresis / umlaut  */
        { 'å' ,   "&aring;"  },    /* 	Small a, ring  */
        { 'æ' ,   "&aelig;"  },    /* 	Small ae ligature  */
        { 'ç' ,   "&ccedil;" },    /* 	Small c, cedilla  */
        { 'è' ,   "&egrave;" },    /* 	Small e, grave accent  */
        { 'é' ,   "&eacute;" },    /* 	Small e, acute accent  */
        { 'ê' ,   "&ecirc;"  },    /* 	Small e, circumflex  */
        { 'ë' ,   "&euml;"   },    /* 	Small e, diæresis / umlaut  */
        { 'ì' ,   "&igrave;" },    /* 	Small i, grave accent  */
        { 'í' ,   "&iacute;" },    /* 	Small i, acute accent  */
        { 'î' ,   "&icirc;"  },    /* 	Small i, circumflex  */
        { 'ï' ,   "&iuml;"   },    /* 	Small i, diæresis / umlaut  */
        { 'ð' ,   "&eth;"    },    /* 	Small eth, Icelandic  */
        { 'ñ' ,   "&ntilde;" },    /* 	Small n, tilde  */
        { 'ò' ,   "&ograve;" },    /* 	Small o, grave accent  */
        { 'ó' ,   "&oacute;" },    /* 	Small o, acute accent  */
        { 'ô' ,   "&ocirc;"  },    /* 	Small o, circumflex  */
        { 'õ' ,   "&otilde;" },    /* 	Small o, tilde  */
        { 'ö' ,   "&ouml;"   },    /* 	Small o, diæresis / umlaut  */
        { '÷' ,   "&divide;" },    /* 	Division sign  */
        { 'ø' ,   "&oslash;" },    /* 	Small o, slash  */
        { 'ù' ,   "&ugrave;" },    /* 	Small u, grave accent  */
        { 'ú' ,   "&uacute;" },    /* 	Small u, acute accent  */
        { 'û' ,   "&ucirc;"  },    /* 	Small u, circumflex  */
        { 'ü' ,   "&uuml;"   },    /* 	Small u, diæresis / umlaut  */
        { 'ý' ,   "&yacute;" },    /* 	Small y, acute accent  */
        { 'þ' ,   "&thorn;"  },    /* 	Small thorn, Icelandic  */
        { '\255', "&yuml;"   },    /* 	Small y, diæresis / umlaut  */
    } ; 



struct tCharTrans Char2HtmlMin [] = 

    {
        { ' ' ,   ""         },    /* &#00;		Unused */ 
        { ' ' ,   ""         },    /* &#01;		Unused */
        { ' ' ,   ""         },    /* &#02;		Unused  */
        { ' ' ,   ""         },    /* &#03;		Unused  */
        { ' ' ,   ""         },    /* &#04;		Unused  */
        { ' ' ,   ""         },    /* &#05;		Unused  */
        { ' ' ,   ""         },    /* &#06;		Unused  */
        { ' ' ,   ""         },    /* &#07;		Unused  */
        { ' ' ,   ""         },    /* &#08;		Unused  */
        { ' ' ,   ""         },    /* &#09;		Horizontal tab  */
        { ' ' ,   ""         },    /* &#10;		Line feed  */
        { ' ' ,   ""         },    /* &#11;		Unused  */
        { ' ' ,   ""         },    /* &#12;		Unused  */
        { ' ' ,   ""         },    /* &#13;		Carriage Return  */
        { ' ' ,   ""         },    /* &#14;		Unused  */
        { ' ' ,   ""         },    /* &#15;		Unused  */
        { ' ' ,   ""         },    /* &#16;		Unused  */
        { ' ' ,   ""         },    /* &#17;		Unused  */
        { ' ' ,   ""         },    /* &#18;		Unused  */
        { ' ' ,   ""         },    /* &#19;		Unused  */
        { ' ' ,   ""         },    /* &#20;		Unused  */
        { ' ' ,   ""         },    /* &#21;		Unused  */
        { ' ' ,   ""         },    /* &#22;		Unused  */
        { ' ' ,   ""         },    /* &#23;		Unused  */
        { ' ' ,   ""         },    /* &#24;		Unused  */
        { ' ' ,   ""         },    /* &#25;		Unused  */
        { ' ' ,   ""         },    /* &#26;		Unused  */
        { ' ' ,   ""         },    /* &#27;		Unused  */
        { ' ' ,   ""         },    /* &#28;		Unused  */
        { ' ' ,   ""         },    /* &#29;		Unused  */
        { ' ' ,   ""         },    /* &#30;		Unused  */
        { ' ' ,   ""         },    /* &#31;		Unused  */
        { ' ' ,   ""         },    /* 	&#32;		Space  */
        { '!' ,   ""         },    /* 	&#33;		Exclamation mark  */
        { '"' ,   "&quot;"   },    /* 	Quotation mark  */
        { '#' ,   ""         },    /* 	&#35;		Number sign  */
        { '$' ,   ""         },    /* 	&#36;		Dollar sign  */
        { '%' ,   ""         },    /* 	&#37;		Percent sign  */
        { '&' ,   "&amp;"    },    /* 	Ampersand  */
        { '\'' ,  ""         },    /* 	&#39;		Apostrophe  */
        { '(' ,   ""         },    /* 	&#40;		Left parenthesis  */
        { ')' ,   ""         },    /* 	&#41;		Right parenthesis  */
        { '*' ,   ""         },    /* 	&#42;		Asterisk  */
        { '+' ,   ""         },    /* 	&#43;		Plus sign  */
        { ',' ,   ""         },    /* 	&#44;		Comma  */
        { '-' ,   ""         },    /* 	&#45;		Hyphen  */
        { '.' ,   ""         },    /* 	&#46;		Period (fullstop)  */
        { '/' ,   ""         },    /* 	&#47;		Solidus (slash)  */
        { '0' ,   ""         },    /* 	&#48;		Digit 0  */
        { '1' ,   ""         },    /* 	&#49;		Digit 1  */
        { '2' ,   ""         },    /* 	&#50;		Digit 2  */
        { '3' ,   ""         },    /* 	&#51;		Digit 3  */
        { '4' ,   ""         },    /* 	&#52;		Digit 4  */
        { '5' ,   ""         },    /* 	&#53;		Digit 5  */
        { '6' ,   ""         },    /* 	&#54;		Digit 6  */
        { '7' ,   ""         },    /* 	&#55;		Digit 7  */
        { '8' ,   ""         },    /* 	&#56;		Digit 8  */
        { '9' ,   ""         },    /* 	&#57;		Digit 9  */
        { ':' ,   ""         },    /* 	&#58;		Colon  */
        { ';' ,   ""         },    /* 	&#59;		Semicolon  */
        { '<' ,   "&lt;"     },    /* 	Less than  */
        { '=' ,   ""         },    /* 	&#61;		Equals sign  */
        { '>' ,   "&gt;"     },    /* 	Greater than  */
        { '?' ,   ""         },    /* 	&#63;		Question mark  */
        { '@' ,   ""         },    /* 	&#64;		Commercial at  */
        { 'A' ,   ""         },    /* 	&#65;		Capital A  */
        { 'B' ,   ""         },    /* 	&#66;		Capital B  */
        { 'C' ,   ""         },    /* 	&#67;		Capital C  */
        { 'D' ,   ""         },    /* 	&#68;		Capital D  */
        { 'E' ,   ""         },    /* 	&#69;		Capital E  */
        { 'F' ,   ""         },    /* 	&#70;		Capital F  */
        { 'G' ,   ""         },    /* 	&#71;		Capital G  */
        { 'H' ,   ""         },    /* 	&#72;		Capital H  */
        { 'I' ,   ""         },    /* 	&#73;		Capital I  */
        { 'J' ,   ""         },    /* 	&#74;		Capital J  */
        { 'K' ,   ""         },    /* 	&#75;		Capital K  */
        { 'L' ,   ""         },    /* 	&#76;		Capital L  */
        { 'M' ,   ""         },    /* 	&#77;		Capital M  */
        { 'N' ,   ""         },    /* 	&#78;		Capital N  */
        { 'O' ,   ""         },    /* 	&#79;		Capital O  */
        { 'P' ,   ""         },    /* 	&#80;		Capital P  */
        { 'Q' ,   ""         },    /* 	&#81;		Capital Q  */
        { 'R' ,   ""         },    /* 	&#82;		Capital R  */
        { 'S' ,   ""         },    /* 	&#83;		Capital S  */
        { 'T' ,   ""         },    /* 	&#84;		Capital T  */
        { 'U' ,   ""         },    /* 	&#85;		Capital U  */
        { 'V' ,   ""         },    /* 	&#86;		Capital V  */
        { 'W' ,   ""         },    /* 	&#87;		Capital W  */
        { 'X' ,   ""         },    /* 	&#88;		Capital X  */
        { 'Y' ,   ""         },    /* 	&#89;		Capital Y  */
        { 'Z' ,   ""         },    /* 	&#90;		Capital Z  */
        { '[' ,   ""         },    /* 	&#91;		Left square bracket  */
        { '\\' ,  ""         },    /* 	&#92;		Reverse solidus (backslash)  */
        { ']' ,   ""         },    /* 	&#93;		Right square bracket  */
        { '^' ,   ""         },    /* 	&#94;		Caret  */
        { '_' ,   ""         },    /* 	&#95;		Horizontal bar (underscore)  */
        { '`' ,   ""         },    /* 	&#96;		Acute accent  */
        { 'a' ,   ""         },    /* 	&#97;		Small a  */
        { 'b' ,   ""         },    /* 	&#98;		Small b  */
        { 'c' ,   ""         },    /* 	&#99;		Small c  */
        { 'd' ,   ""         },    /* 	&#100;		Small d  */
        { 'e' ,   ""         },    /* 	&#101;		Small e  */
        { 'f' ,   ""         },    /* 	&#102;		Small f  */
        { 'g' ,   ""         },    /* 	&#103;		Small g  */
        { 'h' ,   ""         },    /* 	&#104;		Small h  */
        { 'i' ,   ""         },    /* 	&#105;		Small i  */
        { 'j' ,   ""         },    /* 	&#106;		Small j  */
        { 'k' ,   ""         },    /* 	&#107;		Small k  */
        { 'l' ,   ""         },    /* 	&#108;		Small l  */
        { 'm' ,   ""         },    /* 	&#109;		Small m  */
        { 'n' ,   ""         },    /* 	&#110;		Small n  */
        { 'o' ,   ""         },    /* 	&#111;		Small o  */
        { 'p' ,   ""         },    /* 	&#112;		Small p  */
        { 'q' ,   ""         },    /* 	&#113;		Small q  */
        { 'r' ,   ""         },    /* 	&#114;		Small r  */
        { 's' ,   ""         },    /* 	&#115;		Small s  */
        { 't' ,   ""         },    /* 	&#116;		Small t  */
        { 'u' ,   ""         },    /* 	&#117;		Small u  */
        { 'v' ,   ""         },    /* 	&#118;		Small v  */
        { 'w' ,   ""         },    /* 	&#119;		Small w  */
        { 'x' ,   ""         },    /* 	&#120;		Small x  */
        { 'y' ,   ""         },    /* 	&#121;		Small y  */
        { 'z' ,   ""         },    /* 	&#122;		Small z  */
        { '{' ,   ""         },    /* 	&#123;		Left curly brace  */
        { '|' ,   ""         },    /* 	&#124;		Vertical bar  */
        { '}' ,   ""         },    /* 	&#125;		Right curly brace  */
        { '~' ,   ""         },    /* 	&#126;		Tilde  */
        { '' ,   ""         },    /* 	&#127;		Unused  */
        { '€' ,   ""         },    /* 	&#128;		Unused */
        { ' ' ,   ""         },    /* &#129;		Unused  */
        { ' ' ,   ""         },    /* &#130;		Unused  */
        { ' ' ,   ""         },    /* &#131;		Unused  */
        { ' ' ,   ""         },    /* &#132;		Unused  */
        { ' ' ,   ""         },    /* &#133;		Unused  */
        { ' ' ,   ""         },    /* &#134;		Unused  */
        { ' ' ,   ""         },    /* &#135;		Unused  */
        { ' ' ,   ""         },    /* &#136;		Unused  */
        { ' ' ,   ""         },    /* &#137;		Unused  */
        { ' ' ,   ""         },    /* &#138;		Horizontal tab  */
        { ' ' ,   ""         },    /* &#139;		Line feed  */
        { ' ' ,   ""         },    /* &#140;		Unused  */
        { ' ' ,   ""         },    /* &#141;		Unused  */
        { ' ' ,   ""         },    /* &#142;		Carriage Return  */
        { ' ' ,   ""         },    /* &#143;		Unused  */
        { ' ' ,   ""         },    /* &#144;		Unused  */
        { ' ' ,   ""         },    /* &#145;		Unused  */
        { ' ' ,   ""         },    /* &#146;		Unused  */
        { ' ' ,   ""         },    /* &#147;		Unused  */
        { ' ' ,   ""         },    /* &#148;		Unused  */
        { ' ' ,   ""         },    /* &#149;		Unused  */
        { ' ' ,   ""         },    /* &#150;		Unused  */
        { ' ' ,   ""         },    /* &#151;		Unused  */
        { ' ' ,   ""         },    /* &#152;		Unused  */
        { ' ' ,   ""         },    /* &#153;		Unused  */
        { ' ' ,   ""         },    /* &#154;		Unused  */
        { ' ' ,   ""         },    /* &#155;		Unused  */
        { ' ' ,   ""         },    /* &#156;		Unused  */
        { ' ' ,   ""         },    /* &#157;		Unused  */
        { ' ' ,   ""         },    /* &#158;		Unused  */
        { ' ' ,   ""         },    /* &#159;		Unused  */
        { ' ' ,   ""   },    /* 	Non-breaking Space  */
        { '¡' ,   ""  },    /* 	Inverted exclamation    */
        { '¢' ,   ""   },    /* 	Cent sign               */
        { '£' ,   ""  },    /* 	Pound sterling  */
        { '¤' ,   "" },    /* 	General currency sign  */
        { '¥' ,   ""    },    /* 	Yen sign  */
/*        { '¦' ,   "" },    / *  	Broken vertical bar  */
        { '¦' ,   "" },    /* 	Broken vertical bar  */
        { '§' ,   ""  },    /* 	Section sign  */
/*        { '¨' ,   ""    },    / *  	Diæresis / Umlaut  */
        { '¨' ,   ""   },    /* 	Diæresis / Umlaut  */
        { '©' ,   ""  },    /* 	Copyright               */
        { 'ª' ,   ""  },    /* 	Feminine ordinal  */
        { '«' ,   "" },    /* 	Left angle quote, guillemot left  */
        { '¬' ,   ""   },    /*	Not sign  */
        { '­' ,   ""    },    /* 	Soft hyphen  */
        { '®' ,   ""    },    /* 	Registered trademark  */
/*        { '¯' ,   ""   },    / *  	Macron accent  */
        { '¯' ,   ""  },    /* 	Macron accent  */
        { '°' ,   ""    },    /* 	Degree sign  */
        { '±' ,   "" },    /* 	Plus or minus  */
        { '²' ,   ""   },    /* 	Superscript two  */
        { '³' ,   ""   },    /* 	Superscript three  */
        { '´' ,   ""  },    /* 	Acute accent  */
        { 'µ' ,   ""  },    /* 	Micro sign  */
        { '¶' ,   ""   },    /* 	Paragraph sign  */
        { '·' ,   "" },    /* 	Middle dot  */
        { '¸' ,   ""  },    /* 	Cedilla  */
        { '¹' ,   ""   },    /* 	Superscript one  */
        { 'º' ,   ""   },    /* 	Masculine ordinal  */
        { '»' ,   ""  },    /* 	Right angle quote, guillemot right  */
        { '¼' ,   "" },    /* 	Fraction one-fourth  */
        { '½' ,   "" },    /* 	Fraction one-half  */
        { '¾' ,   "" },    /* 	Fraction three-fourths  */
        { '¿' ,   "" },    /* 	Inverted question mark  */
        { 'À' ,   "" },    /* 	Capital A, grave accent  */
        { 'Á' ,   "" },    /* 	Capital A, acute accent  */
        { 'Â' ,   ""  },    /* 	Capital A, circumflex  */
        { 'Ã' ,   "" },    /* 	Capital A, tilde  */
        { 'Ä' ,   ""   },    /* 	Capital A, diæresis / umlaut  */
        { 'Å' ,   ""  },    /* 	Capital A, ring  */
        { 'Æ' ,   ""  },    /* 	Capital AE ligature  */
        { 'Ç' ,   "" },    /* 	Capital C, cedilla  */
        { 'È' ,   "" },    /* 	Capital E, grave accent  */
        { 'É' ,   "" },    /* 	Capital E, acute accent  */
        { 'Ê' ,   ""  },    /* 	Capital E, circumflex  */
        { 'Ë' ,   ""   },    /* 	Capital E, diæresis / umlaut  */
        { 'Ì' ,   "" },    /* 	Capital I, grave accent  */
        { 'Í' ,   "" },    /* 	Capital I, acute accent  */
        { 'Î' ,   ""  },    /* 	Capital I, circumflex  */
        { 'Ï' ,   ""   },    /* 	Capital I, diæresis / umlaut  */
        { 'Ð' ,   ""    },    /* 	Capital Eth, Icelandic  */
        { 'Ñ' ,   "" },    /* 	Capital N, tilde  */
        { 'Ò' ,   "" },    /* 	Capital O, grave accent  */
        { 'Ó' ,   "" },    /* 	Capital O, acute accent  */
        { 'Ô' ,   ""  },    /* 	Capital O, circumflex  */
        { 'Õ' ,   "" },    /* 	Capital O, tilde  */
        { 'Ö' ,   ""   },    /* 	Capital O, diæresis / umlaut  */
        { '×' ,   ""  },    /* 	Multiply sign  */
        { 'Ø' ,   "" },    /* 	Capital O, slash  */
        { 'Ù' ,   "" },    /* 	Capital U, grave accent  */
        { 'Ú' ,   "" },    /* 	Capital U, acute accent  */
        { 'Û' ,   ""  },    /* 	Capital U, circumflex  */
        { 'Ü' ,   ""   },    /* 	Capital U, diæresis / umlaut  */
        { 'Ý' ,   "" },    /* 	Capital Y, acute accent  */
        { 'Þ' ,   ""  },    /* 	Capital Thorn, Icelandic  */
        { 'ß' ,   ""  },    /* 	Small sharp s, German sz  */
        { 'à' ,   "" },    /* 	Small a, grave accent  */
        { 'ß' ,   "" },    /* 	Small a, acute accent  */
        { 'â' ,   ""  },    /* 	Small a, circumflex  */
        { 'ã' ,   "" },    /* 	Small a, tilde  */
        { 'ä' ,   ""   },    /* 	Small a, diæresis / umlaut  */
        { 'å' ,   ""  },    /* 	Small a, ring  */
        { 'æ' ,   ""  },    /* 	Small ae ligature  */
        { 'ç' ,   "" },    /* 	Small c, cedilla  */
        { 'è' ,   "" },    /* 	Small e, grave accent  */
        { 'é' ,   "" },    /* 	Small e, acute accent  */
        { 'ê' ,   ""  },    /* 	Small e, circumflex  */
        { 'ë' ,   ""   },    /* 	Small e, diæresis / umlaut  */
        { 'ì' ,   "" },    /* 	Small i, grave accent  */
        { 'í' ,   "" },    /* 	Small i, acute accent  */
        { 'î' ,   ""  },    /* 	Small i, circumflex  */
        { 'ï' ,   ""   },    /* 	Small i, diæresis / umlaut  */
        { 'ð' ,   ""    },    /* 	Small eth, Icelandic  */
        { 'ñ' ,   "" },    /* 	Small n, tilde  */
        { 'ò' ,   "" },    /* 	Small o, grave accent  */
        { 'ó' ,   "" },    /* 	Small o, acute accent  */
        { 'ô' ,   ""  },    /* 	Small o, circumflex  */
        { 'õ' ,   "" },    /* 	Small o, tilde  */
        { 'ö' ,   ""   },    /* 	Small o, diæresis / umlaut  */
        { '÷' ,   "" },    /* 	Division sign  */
        { 'ø' ,   "" },    /* 	Small o, slash  */
        { 'ù' ,   "" },    /* 	Small u, grave accent  */
        { 'ú' ,   "" },    /* 	Small u, acute accent  */
        { 'û' ,   ""  },    /* 	Small u, circumflex  */
        { 'ü' ,   ""   },    /* 	Small u, diæresis / umlaut  */
        { 'ý' ,   "" },    /* 	Small y, acute accent  */
        { 'þ' ,   ""  },    /* 	Small thorn, Icelandic  */
        { '\255', ""   },    /* 	Small y, diæresis / umlaut  */
    } ; 
 
struct tCharTrans Char2HtmlLatin2 [] = 

    {
        { ' ' ,   ""         },    /* &#00;		Unused */ 
        { ' ' ,   ""         },    /* &#01;		Unused */
        { ' ' ,   ""         },    /* &#02;		Unused  */
        { ' ' ,   ""         },    /* &#03;		Unused  */
        { ' ' ,   ""         },    /* &#04;		Unused  */
        { ' ' ,   ""         },    /* &#05;		Unused  */
        { ' ' ,   ""         },    /* &#06;		Unused  */
        { ' ' ,   ""         },    /* &#07;		Unused  */
        { ' ' ,   ""         },    /* &#08;		Unused  */
        { ' ' ,   ""         },    /* &#09;		Horizontal tab  */
        { ' ' ,   ""         },    /* &#10;		Line feed  */
        { ' ' ,   ""         },    /* &#11;		Unused  */
        { ' ' ,   ""         },    /* &#12;		Unused  */
        { ' ' ,   ""         },    /* &#13;		Carriage Return  */
        { ' ' ,   ""         },    /* &#14;		Unused  */
        { ' ' ,   ""         },    /* &#15;		Unused  */
        { ' ' ,   ""         },    /* &#16;		Unused  */
        { ' ' ,   ""         },    /* &#17;		Unused  */
        { ' ' ,   ""         },    /* &#18;		Unused  */
        { ' ' ,   ""         },    /* &#19;		Unused  */
        { ' ' ,   ""         },    /* &#20;		Unused  */
        { ' ' ,   ""         },    /* &#21;		Unused  */
        { ' ' ,   ""         },    /* &#22;		Unused  */
        { ' ' ,   ""         },    /* &#23;		Unused  */
        { ' ' ,   ""         },    /* &#24;		Unused  */
        { ' ' ,   ""         },    /* &#25;		Unused  */
        { ' ' ,   ""         },    /* &#26;		Unused  */
        { ' ' ,   ""         },    /* &#27;		Unused  */
        { ' ' ,   ""         },    /* &#28;		Unused  */
        { ' ' ,   ""         },    /* &#29;		Unused  */
        { ' ' ,   ""         },    /* &#30;		Unused  */
        { ' ' ,   ""         },    /* &#31;		Unused  */
        { ' ' ,   ""         },    /* 	&#32;		Space  */
        { '!' ,   ""         },    /* 	&#33;		Exclamation mark  */
        { '"' ,   "&quot;"   },    /* 	Quotation mark  */
        { '#' ,   ""         },    /* 	&#35;		Number sign  */
        { '$' ,   ""         },    /* 	&#36;		Dollar sign  */
        { '%' ,   ""         },    /* 	&#37;		Percent sign  */
        { '&' ,   "&amp;"    },    /* 	Ampersand  */
        { '\'' ,  ""         },    /* 	&#39;		Apostrophe  */
        { '(' ,   ""         },    /* 	&#40;		Left parenthesis  */
        { ')' ,   ""         },    /* 	&#41;		Right parenthesis  */
        { '*' ,   ""         },    /* 	&#42;		Asterisk  */
        { '+' ,   ""         },    /* 	&#43;		Plus sign  */
        { ',' ,   ""         },    /* 	&#44;		Comma  */
        { '-' ,   ""         },    /* 	&#45;		Hyphen  */
        { '.' ,   ""         },    /* 	&#46;		Period (fullstop)  */
        { '/' ,   ""         },    /* 	&#47;		Solidus (slash)  */
        { '0' ,   ""         },    /* 	&#48;		Digit 0  */
        { '1' ,   ""         },    /* 	&#49;		Digit 1  */
        { '2' ,   ""         },    /* 	&#50;		Digit 2  */
        { '3' ,   ""         },    /* 	&#51;		Digit 3  */
        { '4' ,   ""         },    /* 	&#52;		Digit 4  */
        { '5' ,   ""         },    /* 	&#53;		Digit 5  */
        { '6' ,   ""         },    /* 	&#54;		Digit 6  */
        { '7' ,   ""         },    /* 	&#55;		Digit 7  */
        { '8' ,   ""         },    /* 	&#56;		Digit 8  */
        { '9' ,   ""         },    /* 	&#57;		Digit 9  */
        { ':' ,   ""         },    /* 	&#58;		Colon  */
        { ';' ,   ""         },    /* 	&#59;		Semicolon  */
        { '<' ,   "&lt;"     },    /* 	Less than  */
        { '=' ,   ""         },    /* 	&#61;		Equals sign  */
        { '>' ,   "&gt;"     },    /* 	Greater than  */
        { '?' ,   ""         },    /* 	&#63;		Question mark  */
        { '@' ,   ""         },    /* 	&#64;		Commercial at  */
        { 'A' ,   ""         },    /* 	&#65;		Capital A  */
        { 'B' ,   ""         },    /* 	&#66;		Capital B  */
        { 'C' ,   ""         },    /* 	&#67;		Capital C  */
        { 'D' ,   ""         },    /* 	&#68;		Capital D  */
        { 'E' ,   ""         },    /* 	&#69;		Capital E  */
        { 'F' ,   ""         },    /* 	&#70;		Capital F  */
        { 'G' ,   ""         },    /* 	&#71;		Capital G  */
        { 'H' ,   ""         },    /* 	&#72;		Capital H  */
        { 'I' ,   ""         },    /* 	&#73;		Capital I  */
        { 'J' ,   ""         },    /* 	&#74;		Capital J  */
        { 'K' ,   ""         },    /* 	&#75;		Capital K  */
        { 'L' ,   ""         },    /* 	&#76;		Capital L  */
        { 'M' ,   ""         },    /* 	&#77;		Capital M  */
        { 'N' ,   ""         },    /* 	&#78;		Capital N  */
        { 'O' ,   ""         },    /* 	&#79;		Capital O  */
        { 'P' ,   ""         },    /* 	&#80;		Capital P  */
        { 'Q' ,   ""         },    /* 	&#81;		Capital Q  */
        { 'R' ,   ""         },    /* 	&#82;		Capital R  */
        { 'S' ,   ""         },    /* 	&#83;		Capital S  */
        { 'T' ,   ""         },    /* 	&#84;		Capital T  */
        { 'U' ,   ""         },    /* 	&#85;		Capital U  */
        { 'V' ,   ""         },    /* 	&#86;		Capital V  */
        { 'W' ,   ""         },    /* 	&#87;		Capital W  */
        { 'X' ,   ""         },    /* 	&#88;		Capital X  */
        { 'Y' ,   ""         },    /* 	&#89;		Capital Y  */
        { 'Z' ,   ""         },    /* 	&#90;		Capital Z  */
        { '[' ,   ""         },    /* 	&#91;		Left square bracket  */
        { '\\' ,  ""         },    /* 	&#92;		Reverse solidus (backslash)  */
        { ']' ,   ""         },    /* 	&#93;		Right square bracket  */
        { '^' ,   ""         },    /* 	&#94;		Caret  */
        { '_' ,   ""         },    /* 	&#95;		Horizontal bar (underscore)  */
        { '`' ,   ""         },    /* 	&#96;		Acute accent  */
        { 'a' ,   ""         },    /* 	&#97;		Small a  */
        { 'b' ,   ""         },    /* 	&#98;		Small b  */
        { 'c' ,   ""         },    /* 	&#99;		Small c  */
        { 'd' ,   ""         },    /* 	&#100;		Small d  */
        { 'e' ,   ""         },    /* 	&#101;		Small e  */
        { 'f' ,   ""         },    /* 	&#102;		Small f  */
        { 'g' ,   ""         },    /* 	&#103;		Small g  */
        { 'h' ,   ""         },    /* 	&#104;		Small h  */
        { 'i' ,   ""         },    /* 	&#105;		Small i  */
        { 'j' ,   ""         },    /* 	&#106;		Small j  */
        { 'k' ,   ""         },    /* 	&#107;		Small k  */
        { 'l' ,   ""         },    /* 	&#108;		Small l  */
        { 'm' ,   ""         },    /* 	&#109;		Small m  */
        { 'n' ,   ""         },    /* 	&#110;		Small n  */
        { 'o' ,   ""         },    /* 	&#111;		Small o  */
        { 'p' ,   ""         },    /* 	&#112;		Small p  */
        { 'q' ,   ""         },    /* 	&#113;		Small q  */
        { 'r' ,   ""         },    /* 	&#114;		Small r  */
        { 's' ,   ""         },    /* 	&#115;		Small s  */
        { 't' ,   ""         },    /* 	&#116;		Small t  */
        { 'u' ,   ""         },    /* 	&#117;		Small u  */
        { 'v' ,   ""         },    /* 	&#118;		Small v  */
        { 'w' ,   ""         },    /* 	&#119;		Small w  */
        { 'x' ,   ""         },    /* 	&#120;		Small x  */
        { 'y' ,   ""         },    /* 	&#121;		Small y  */
        { 'z' ,   ""         },    /* 	&#122;		Small z  */
        { '{' ,   ""         },    /* 	&#123;		Left curly brace  */
        { '|' ,   ""         },    /* 	&#124;		Vertical bar  */
        { '}' ,   ""         },    /* 	&#125;		Right curly brace  */
        { '~' ,   ""         },    /* 	&#126;		Tilde  */
        { '' ,   ""         },    /* 	&#127;		Unused  */
        { '€' ,   ""         },    /* 	&#128;		Unused */
         
        { ' ' ,   ""         },    /* &#129;		Unused  */
        { ' ' ,   ""         },    /* &#130;		Unused  */
        { ' ' ,   ""         },    /* &#131;		Unused  */
        { ' ' ,   ""         },    /* &#132;		Unused  */
        { ' ' ,   ""         },    /* &#133;		Unused  */
        { ' ' ,   ""         },    /* &#134;		Unused  */
        { ' ' ,   ""         },    /* &#135;		Unused  */
        { ' ' ,   ""         },    /* &#136;		Unused  */
        { ' ' ,   ""         },    /* &#137;		Unused  */
        { ' ' ,   ""         },    /* &#138;		Horizontal tab  */
        { ' ' ,   ""         },    /* &#139;		Line feed  */
        { ' ' ,   ""         },    /* &#140;		Unused  */
        { ' ' ,   ""         },    /* &#141;		Unused  */
        { ' ' ,   ""         },    /* &#142;		Carriage Return  */
        { ' ' ,   ""         },    /* &#143;		Unused  */
        { ' ' ,   ""         },    /* &#144;		Unused  */
        { ' ' ,   ""         },    /* &#145;		Unused  */
        { ' ' ,   ""         },    /* &#146;		Unused  */
        { ' ' ,   ""         },    /* &#147;		Unused  */
        { ' ' ,   ""         },    /* &#148;		Unused  */
        { ' ' ,   ""         },    /* &#149;		Unused  */
        { ' ' ,   ""         },    /* &#150;		Unused  */
        { ' ' ,   ""         },    /* &#151;		Unused  */
        { ' ' ,   ""         },    /* &#152;		Unused  */
        { ' ' ,   ""         },    /* &#153;		Unused  */
        { ' ' ,   ""         },    /* &#154;		Unused  */
        { ' ' ,   ""         },    /* &#155;		Unused  */
        { ' ' ,   ""         },    /* &#156;		Unused  */
        { ' ' ,   ""         },    /* &#157;		Unused  */
        { ' ' ,   ""         },    /* &#158;		Unused  */
        { ' ' ,   ""         },    /* &#159;		Unused  */
        { ' ', "&nbsp;" },             /* &#160; - nobreakspace */
        { '¡',  "" },           /* &#161; - Aogonek */
        { '¢',  "" },           /* &#162; - breve */
        { '£',  "" },           /* &#163; - Lstroke */
        { '¤',  "&curren;" },           /* &#164; - currency */
        { '¥',  "" },           /* &#165; - Lcaron */
        { '¦',  "" },           /* &#166; - Sacute */
        { '§',  "&sect;" },             /* &#167; - section */
        { '¨',  "&die;" },              /* &#168; - diaeresis */
        { '©',  "" },           /* &#169; - Scaron */
        { 'ª',  "" },           /* &#170; - Scedilla */
        { '«',  "" },           /* &#171; - Tcaron */
        { '¬',  "" },           /* &#172; - Zacute */
        { '­',  "&shy;" },              /* &#173; - hyphen */
        { '®',  "" },           /* &#174; - Zcaron */
        { '¯',  "" },           /* &#175; - Zabovedot */
        { '°',  "&degree;" },           /* &#176; - degree */
        { '±',  "" },           /* &#177; - aogonek */
        { '²',  "" },           /* &#178; - ogonek */
        { '³',  "" },           /* &#179; - lstroke */
        { '´',  "&acute;" },            /* &#180; - acute */
        { 'µ',  "" },           /* &#181; - lcaron */
        { '¶',  "" },           /* &#182; - sacute */
        { '·',  "" },           /* &#183; - caron */
        { '¸',  "&Cedilla;" },          /* &#184; - cedilla */
        { '¹',  "" },           /* &#185; - scaron */
        { 'º',  "" },           /* &#186; - scedilla */
        { '»',  "" },           /* &#187; - tcaron */
        { '¼',  "" },           /* &#188; - zacute */
        { '½',  "" },           /* &#189; - doubleacute */
        { '¾',  "" },           /* &#190; - zcaron */
        { '¿',  "" },           /* &#191; - zabovedot */
        { 'À',  "" },           /* &#192; - Racute */
        { 'Á',  "&Aacute;" },           /* &#193; - Aacute */
        { 'Â',  "&Acirc;" },            /* &#194; - Acircumflex */
        { 'Ã',  "" },           /* &#195; - Abreve */
        { 'Ä',  "&Auml;" },             /* &#196; - Adiaeresis */
        { 'Å',  "" },           /* &#197; - Lacute */
        { 'Æ',  "" },           /* &#198; - Cacute */
        { 'Ç',  "&Ccedil;" },           /* &#199; - Ccedilla */
        { 'È',  "" },           /* &#200; - Ccaron */
        { 'É',  "&Eacute;" },           /* &#201; - Eacute */
        { 'Ê',  "" },           /* &#202; - Eogonek */
        { 'Ë',  "&Euml;" },             /* &#203; - Ediaeresis */
        { 'Ì',  "" },           /* &#204; - Ecaron */
        { 'Í',  "&Iacute;" },           /* &#205; - Iacute */
        { 'Î',  "&Icirc;" },            /* &#206; - Icircumflex */
        { 'Ï',  "" },           /* &#207; - Dcaron */
        { 'Ð',  "&ETH;" },              /* &#208; - Eth */
        { 'Ñ',  "" },           /* &#209; - Nacute */
        { 'Ò',  "" },           /* &#210; - Ncaron */
        { 'Ó',  "&Oacute;" },           /* &#211; - Oacute */
        { 'Ô',  "&Ocirc;" },            /* &#212; - Ocircumflex */
        { 'Õ',  "" },           /* &#213; - Odoubleacute */
        { 'Ö',  "&Ouml;" },             /* &#214; - Odiaeresis */
        { '×',  "&times;" },            /* &#215; - multiply */
        { 'Ø',  "" },           /* &#216; - Rcaron */
        { 'Ù',  "" },           /* &#217; - Uring */
        { 'Ú',  "&Uacute;" },           /* &#218; - Uacute */
        { 'Û',  "" },           /* &#219; - Udoubleacute */
        { 'Ü',  "&Uuml;" },             /* &#220; - Udiaeresis */
        { 'Ý',  "&Yacute;" },           /* &#221; - Yacute */
        { 'Þ',  "" },           /* &#222; - Tcedilla */
        { 'ß',  "&szlig;" },            /* &#223; - ssharp */
        { 'à',  "" },           /* &#224; - racute */
        { 'ß',  "&aacute;" },           /* &#225; - aacute */
        { 'â',  "&acirc;" },            /* &#226; - acircumflex */
        { 'ã',  "" },           /* &#227; - abreve */
        { 'ä',  "&auml;" },             /* &#228; - adiaeresis */
        { 'å',  "" },           /* &#229; - lacute */
        { 'æ',  "" },           /* &#230; - cacute */
        { 'ç',  "&ccedil;" },           /* &#231; - ccedilla */
        { 'è',  "" },           /* &#232; - ccaron */
        { 'é',  "&eacute;" },           /* &#233; - eacute */
        { 'ê',  "" },           /* &#234; - eogonek */
        { 'ë',  "&euml;" },             /* &#235; - ediaeresis */
        { 'ì',  "" },           /* &#236; - ecaron */
        { 'í',  "&iacute;" },           /* &#237; - iacute */
        { 'î',  "&icirc;" },            /* &#238; - icircumflex */
        { 'ï',  "" },           /* &#239; - dcaron */
        { 'ð',  "&eth;" },              /* &#240; - eth */
        { 'ñ',  "" },           /* &#241; - nacute */
        { 'ò',  "" },           /* &#242; - ncaron */
        { 'ó',  "&oacute;" },           /* &#243; - oacute */
        { 'ô',  "&ocirc;" },            /* &#244; - ocircumflex */
        { 'õ',  "" },           /* &#245; - odoubleacute */
        { 'ö',  "&ouml;" },             /* &#246; - odiaeresis */
        { '÷',  "&divide;" },           /* &#247; - division */
        { 'ø',  "" },           /* &#248; - rcaron */
        { 'ù',  "" },           /* &#249; - uring */
        { 'ú',  "&uacute;" },           /* &#250; - uacute */
        { 'û',  "" },           /* &#251; - udoubleacute */
        { 'ü',  "&uuml;" },             /* &#252; - udiaeresis */
        { 'ý',  "&yacute;" },           /* &#253; - yacute */
        { 'þ',  "" },           /* &#254; - tcedilla */
        { '\255',  "" },           /* &#255; - abovedot */
    } ; 
 
 

struct tCharTrans Char2Url [] = 

    {
        { ' ' ,   "%00"         },    /* &#00;		Unused */ 
        { ' ' ,   "%01"         },    /* &#01;		Unused */
        { ' ' ,   "%02"         },    /* &#02;		Unused  */
        { ' ' ,   "%03"         },    /* &#03;		Unused  */
        { ' ' ,   "%04"         },    /* &#04;		Unused  */
        { ' ' ,   "%05"         },    /* &#05;		Unused  */
        { ' ' ,   "%06"         },    /* &#06;		Unused  */
        { ' ' ,   "%07"         },    /* &#07;		Unused  */
        { ' ' ,   "%08"         },    /* &#08;		Unused  */
        { ' ' ,   "%09"         },    /* &#09;		Horizontal tab  */
        { ' ' ,   "%0A"         },    /* &#10;		Line feed  */
        { ' ' ,   "%0B"         },    /* &#11;		Unused  */
        { ' ' ,   "%0C"         },    /* &#12;		Unused  */
        { ' ' ,   "%0D"         },    /* &#13;		Carriage Return  */
        { ' ' ,   "%0E"         },    /* &#14;		Unused  */
        { ' ' ,   "%0F"         },    /* &#15;		Unused  */
        { ' ' ,   "%10"         },    /* &#16;		Unused  */
        { ' ' ,   "%11"         },    /* &#17;		Unused  */
        { ' ' ,   "%12"         },    /* &#18;		Unused  */
        { ' ' ,   "%13"         },    /* &#19;		Unused  */
        { ' ' ,   "%14"         },    /* &#20;		Unused  */
        { ' ' ,   "%15"         },    /* &#21;		Unused  */
        { ' ' ,   "%16"         },    /* &#22;		Unused  */
        { ' ' ,   "%17"         },    /* &#23;		Unused  */
        { ' ' ,   "%18"         },    /* &#24;		Unused  */
        { ' ' ,   "%19"         },    /* &#25;		Unused  */
        { ' ' ,   "%1A"         },    /* &#26;		Unused  */
        { ' ' ,   "%1B"         },    /* &#27;		Unused  */
        { ' ' ,   "%1C"         },    /* &#28;		Unused  */
        { ' ' ,   "%1D"         },    /* &#29;		Unused  */
        { ' ' ,   "%1E"         },    /* &#30;		Unused  */
        { ' ' ,   "%1F"         },    /* &#31;		Unused  */
        { ' ' ,   "%20"           },    /* 	&#32;		Space  */
        { '!' ,   ""         },    /* 	&#33;		Exclamation mark  */
        { '"' ,   "%22"   },    /* 	Quotation mark  */
        { '#' ,   "%23"      },    /* 	&#35;		Number sign  */
        { '$' ,   "%24"         },    /* 	&#36;		Dollar sign  */
        { '%' ,   "%25"      },    /* 	&#37;		Percent sign  */
        { '&' ,   "%26"    },    /* 	Ampersand  */
        { '\'' ,  "%27"       },    /* 	&#39;		Apostrophe  */
        { '(' ,   ""         },    /* 	&#40;		Left parenthesis  */
        { ')' ,   ""         },    /* 	&#41;		Right parenthesis  */
        { '*' ,   ""         },    /* 	&#42;		Asterisk  */
        { '+' ,   "%2B"         },    /* 	&#43;		Plus sign  */
        { ',' ,   "%2C"         },    /* 	&#44;		Comma  */
        { '-' ,   ""         },    /* 	&#45;		Hyphen  */
        { '.' ,   ""         },    /* 	&#46;		Period (fullstop)  */
        { '/' ,   ""         },    /* 	&#47;		Solidus (slash)  */
        { '0' ,   ""         },    /* 	&#48;		Digit 0  */
        { '1' ,   ""         },    /* 	&#49;		Digit 1  */
        { '2' ,   ""         },    /* 	&#50;		Digit 2  */
        { '3' ,   ""         },    /* 	&#51;		Digit 3  */
        { '4' ,   ""         },    /* 	&#52;		Digit 4  */
        { '5' ,   ""         },    /* 	&#53;		Digit 5  */
        { '6' ,   ""         },    /* 	&#54;		Digit 6  */
        { '7' ,   ""         },    /* 	&#55;		Digit 7  */
        { '8' ,   ""         },    /* 	&#56;		Digit 8  */
        { '9' ,   ""         },    /* 	&#57;		Digit 9  */
/* We should escape this according to the rfc, but this would make troubles inside
   of urls, so will don' escape it   
        { ':' ,   "%3A"      },   */ /* 	&#58;		Colon  */
        { ':' ,   ""      },    /* 	&#58;		Colon  */
        { ';' ,   "%3B"      },    /* 	&#59;		Semicolon  */
        { '<' ,   "%3C"      },    /* 	Less than  */
        { '=' ,   "%3D"      },    /* 	&#61;		Equals sign  */
        { '>' ,   "%3E"      },    /* 	Greater than  */
        { '?' ,   "%3F"      },    /* 	&#63;		Question mark  */
        { '@' ,   ""      },    /* 	&#64;		Commercial at  */
        { 'A' ,   ""         },    /* 	&#65;		Capital A  */
        { 'B' ,   ""         },    /* 	&#66;		Capital B  */
        { 'C' ,   ""         },    /* 	&#67;		Capital C  */
        { 'D' ,   ""         },    /* 	&#68;		Capital D  */
        { 'E' ,   ""         },    /* 	&#69;		Capital E  */
        { 'F' ,   ""         },    /* 	&#70;		Capital F  */
        { 'G' ,   ""         },    /* 	&#71;		Capital G  */
        { 'H' ,   ""         },    /* 	&#72;		Capital H  */
        { 'I' ,   ""         },    /* 	&#73;		Capital I  */
        { 'J' ,   ""         },    /* 	&#74;		Capital J  */
        { 'K' ,   ""         },    /* 	&#75;		Capital K  */
        { 'L' ,   ""         },    /* 	&#76;		Capital L  */
        { 'M' ,   ""         },    /* 	&#77;		Capital M  */
        { 'N' ,   ""         },    /* 	&#78;		Capital N  */
        { 'O' ,   ""         },    /* 	&#79;		Capital O  */
        { 'P' ,   ""         },    /* 	&#80;		Capital P  */
        { 'Q' ,   ""         },    /* 	&#81;		Capital Q  */
        { 'R' ,   ""         },    /* 	&#82;		Capital R  */
        { 'S' ,   ""         },    /* 	&#83;		Capital S  */
        { 'T' ,   ""         },    /* 	&#84;		Capital T  */
        { 'U' ,   ""         },    /* 	&#85;		Capital U  */
        { 'V' ,   ""         },    /* 	&#86;		Capital V  */
        { 'W' ,   ""         },    /* 	&#87;		Capital W  */
        { 'X' ,   ""         },    /* 	&#88;		Capital X  */
        { 'Y' ,   ""         },    /* 	&#89;		Capital Y  */
        { 'Z' ,   ""         },    /* 	&#90;		Capital Z  */
        { '[' ,   "%5B"         },    /* 	&#91;		Left square bracket  */
        { '\\' ,  "%5C"         },    /* 	&#92;		Reverse solidus (backslash)  */
        { ']' ,   "%5D"         },    /* 	&#93;		Right square bracket  */
        { '^' ,   "%5E"         },    /* 	&#94;		Caret  */
        { '_' ,   ""         },    /* 	&#95;		Horizontal bar (underscore)  */
        { '`' ,   "%60"         },    /* 	&#96;		Acute accent  */
        { 'a' ,   ""         },    /* 	&#97;		Small a  */
        { 'b' ,   ""         },    /* 	&#98;		Small b  */
        { 'c' ,   ""         },    /* 	&#99;		Small c  */
        { 'd' ,   ""         },    /* 	&#100;		Small d  */
        { 'e' ,   ""         },    /* 	&#101;		Small e  */
        { 'f' ,   ""         },    /* 	&#102;		Small f  */
        { 'g' ,   ""         },    /* 	&#103;		Small g  */
        { 'h' ,   ""         },    /* 	&#104;		Small h  */
        { 'i' ,   ""         },    /* 	&#105;		Small i  */
        { 'j' ,   ""         },    /* 	&#106;		Small j  */
        { 'k' ,   ""         },    /* 	&#107;		Small k  */
        { 'l' ,   ""         },    /* 	&#108;		Small l  */
        { 'm' ,   ""         },    /* 	&#109;		Small m  */
        { 'n' ,   ""         },    /* 	&#110;		Small n  */
        { 'o' ,   ""         },    /* 	&#111;		Small o  */
        { 'p' ,   ""         },    /* 	&#112;		Small p  */
        { 'q' ,   ""         },    /* 	&#113;		Small q  */
        { 'r' ,   ""         },    /* 	&#114;		Small r  */
        { 's' ,   ""         },    /* 	&#115;		Small s  */
        { 't' ,   ""         },    /* 	&#116;		Small t  */
        { 'u' ,   ""         },    /* 	&#117;		Small u  */
        { 'v' ,   ""         },    /* 	&#118;		Small v  */
        { 'w' ,   ""         },    /* 	&#119;		Small w  */
        { 'x' ,   ""         },    /* 	&#120;		Small x  */
        { 'y' ,   ""         },    /* 	&#121;		Small y  */
        { 'z' ,   ""         },    /* 	&#122;		Small z  */
        { '{' ,   "%7B"         },    /* 	&#123;		Left curly brace  */
        { '|' ,   "%7C"         },    /* 	&#124;		Vertical bar  */
        { '}' ,   "%7D"         },    /* 	&#125;		Right curly brace  */
        { '~' ,   ""         },    /* 	&#126;		Tilde  */
        { '' ,   "%7F"         },    /* 	&#127;		Unused  */
        { '€' ,   "%80"         },    /* 	&#128;		Unused */
        { ' ' ,   "%81"         },    /* &#129;		Unused  */
        { ' ' ,   "%82"         },    /* &#130;		Unused  */
        { ' ' ,   "%83"         },    /* &#131;		Unused  */
        { ' ' ,   "%84"         },    /* &#132;		Unused  */
        { ' ' ,   "%85"         },    /* &#133;		Unused  */
        { ' ' ,   "%86"         },    /* &#134;		Unused  */
        { ' ' ,   "%87"         },    /* &#135;		Unused  */
        { ' ' ,   "%88"         },    /* &#136;		Unused  */
        { ' ' ,   "%89"         },    /* &#137;		Unused  */
        { ' ' ,   "%8A"         },    /* &#138;		Horizontal tab  */
        { ' ' ,   "%8B"         },    /* &#139;		Line feed  */
        { ' ' ,   "%8C"         },    /* &#140;		Unused  */
        { ' ' ,   "%8D"         },    /* &#141;		Unused  */
        { ' ' ,   "%8E"         },    /* &#142;		Carriage Return  */
        { ' ' ,   "%8F"         },    /* &#143;		Unused  */
        { ' ' ,   "%90"         },    /* &#144;		Unused  */
        { ' ' ,   "%91"         },    /* &#145;		Unused  */
        { ' ' ,   "%92"         },    /* &#146;		Unused  */
        { ' ' ,   "%93"         },    /* &#147;		Unused  */
        { ' ' ,   "%94"         },    /* &#148;		Unused  */
        { ' ' ,   "%95"         },    /* &#149;		Unused  */
        { ' ' ,   "%96"         },    /* &#150;		Unused  */
        { ' ' ,   "%97"         },    /* &#151;		Unused  */
        { ' ' ,   "%98"         },    /* &#152;		Unused  */
        { ' ' ,   "%99"         },    /* &#153;		Unused  */
        { ' ' ,   "%9A"         },    /* &#154;		Unused  */
        { ' ' ,   "%9B"         },    /* &#155;		Unused  */
        { ' ' ,   "%9C"         },    /* &#156;		Unused  */
        { ' ' ,   "%9D"         },    /* &#157;		Unused  */
        { ' ' ,   "%9E"         },    /* &#158;		Unused  */
        { ' ' ,   "%9F"         },    /* &#159;		Unused  */
        { ' ' ,   "%A0"   },    /* 	Non-breaking Space  */
        { '¡' ,   "%A1"  },    /* 	Inverted exclamation    */
        { '¢' ,   "%A2"   },    /* 	Cent sign               */
        { '£' ,   "%A3"  },    /* 	Pound sterling  */
        { '¤' ,   "%A4" },    /* 	General currency sign  */
        { '¥' ,   "%A5"    },    /* 	Yen sign  */
        { '¦' ,   "%A6" },    /* 	Broken vertical bar  */
        { '§' ,   "%A7"  },    /* 	Section sign  */
        { '¨' ,   "%A8"   },    /* 	Diæresis / Umlaut  */
        { '©' ,   "%A9"  },    /* 	Copyright               */
        { 'ª' ,   "%AA"  },    /* 	Feminine ordinal  */
        { '«' ,   "%AB" },    /* 	Left angle quote, guillemot left  */
        { '¬' ,   "%AC"   },    /*	Not sign  */
        { '­' ,   "%AD"    },    /* 	Soft hyphen  */
        { '®' ,   "%AE"    },    /* 	Registered trademark  */
        { '¯' ,   "%AF"  },    /* 	Macron accent  */
        { '°' ,   "%B0"    },    /* 	Degree sign  */
        { '±' ,   "%B1" },    /* 	Plus or minus  */
        { '²' ,   "%B2"   },    /* 	Superscript two  */
        { '³' ,   "%B3"   },    /* 	Superscript three  */
        { '´' ,   "%B4"  },    /* 	Acute accent  */
        { 'µ' ,   "%B5"  },    /* 	Micro sign  */
        { '¶' ,   "%B6"   },    /* 	Paragraph sign  */
        { '·' ,   "%B7" },    /* 	Middle dot  */
        { '¸' ,   "%B8"  },    /* 	Cedilla  */
        { '¹' ,   "%B9"   },    /* 	Superscript one  */
        { 'º' ,   "%BA"   },    /* 	Masculine ordinal  */
        { '»' ,   "%BB"  },    /* 	Right angle quote, guillemot right  */
        { '¼' ,   "%BC" },    /* 	Fraction one-fourth  */
        { '½' ,   "%BD" },    /* 	Fraction one-half  */
        { '¾' ,   "%BE" },    /* 	Fraction three-fourths  */
        { '¿' ,   "%BF" },    /* 	Inverted question mark  */
        { 'À' ,   "%C0" },    /* 	Capital A, grave accent  */
        { 'Á' ,   "%C1" },    /* 	Capital A, acute accent  */
        { 'Â' ,   "%C2"  },    /* 	Capital A, circumflex  */
        { 'Ã' ,   "%C3" },    /* 	Capital A, tilde  */
        { 'Ä' ,   "%C4"   },    /* 	Capital A, diæresis / umlaut  */
        { 'Å' ,   "%C5"  },    /* 	Capital A, ring  */
        { 'Æ' ,   "%C6"  },    /* 	Capital AE ligature  */
        { 'Ç' ,   "%C7" },    /* 	Capital C, cedilla  */
        { 'È' ,   "%C8" },    /* 	Capital E, grave accent  */
        { 'É' ,   "%C9" },    /* 	Capital E, acute accent  */
        { 'Ê' ,   "%CA"  },    /* 	Capital E, circumflex  */
        { 'Ë' ,   "%CB"   },    /* 	Capital E, diæresis / umlaut  */
        { 'Ì' ,   "%CC" },    /* 	Capital I, grave accent  */
        { 'Í' ,   "%CD" },    /* 	Capital I, acute accent  */
        { 'Î' ,   "%CE"  },    /* 	Capital I, circumflex  */
        { 'Ï' ,   "%CF"   },    /* 	Capital I, diæresis / umlaut  */
        { 'Ð' ,   "%D0"    },    /* 	Capital Eth, Icelandic  */
        { 'Ñ' ,   "%D1" },    /* 	Capital N, tilde  */
        { 'Ò' ,   "%D2" },    /* 	Capital O, grave accent  */
        { 'Ó' ,   "%D3" },    /* 	Capital O, acute accent  */
        { 'Ô' ,   "%D4"  },    /* 	Capital O, circumflex  */
        { 'Õ' ,   "%D5" },    /* 	Capital O, tilde  */
        { 'Ö' ,   "%D6"   },    /* 	Capital O, diæresis / umlaut  */
        { '×' ,   "%D7"  },    /* 	Multiply sign  */
        { 'Ø' ,   "%D8" },    /* 	Capital O, slash  */
        { 'Ù' ,   "%D9" },    /* 	Capital U, grave accent  */
        { 'Ú' ,   "%DA" },    /* 	Capital U, acute accent  */
        { 'Û' ,   "%DB"  },    /* 	Capital U, circumflex  */
        { 'Ü' ,   "%DC"   },    /* 	Capital U, diæresis / umlaut  */
        { 'Ý' ,   "%DD" },    /* 	Capital Y, acute accent  */
        { 'Þ' ,   "%DE"  },    /* 	Capital Thorn, Icelandic  */
        { 'ß' ,   "%DF"  },    /* 	Small sharp s, German sz  */
        { 'à' ,   "%E0" },    /* 	Small a, grave accent  */
        { 'ß' ,   "%E1" },    /* 	Small a, acute accent  */
        { 'â' ,   "%E2"  },    /* 	Small a, circumflex  */
        { 'ã' ,   "%E3" },    /* 	Small a, tilde  */
        { 'ä' ,   "%E4"   },    /* 	Small a, diæresis / umlaut  */
        { 'å' ,   "%E5"  },    /* 	Small a, ring  */
        { 'æ' ,   "%E6"  },    /* 	Small ae ligature  */
        { 'ç' ,   "%E7" },    /* 	Small c, cedilla  */
        { 'è' ,   "%E8" },    /* 	Small e, grave accent  */
        { 'é' ,   "%E9" },    /* 	Small e, acute accent  */
        { 'ê' ,   "%EA"  },    /* 	Small e, circumflex  */
        { 'ë' ,   "%EB"   },    /* 	Small e, diæresis / umlaut  */
        { 'ì' ,   "%EC" },    /* 	Small i, grave accent  */
        { 'í' ,   "%ED" },    /* 	Small i, acute accent  */
        { 'î' ,   "%EE"  },    /* 	Small i, circumflex  */
        { 'ï' ,   "%EF"   },    /* 	Small i, diæresis / umlaut  */
        { 'ð' ,   "%F0"    },    /* 	Small eth, Icelandic  */
        { 'ñ' ,   "%F1" },    /* 	Small n, tilde  */
        { 'ò' ,   "%F2" },    /* 	Small o, grave accent  */
        { 'ó' ,   "%F3" },    /* 	Small o, acute accent  */
        { 'ô' ,   "%F4"  },    /* 	Small o, circumflex  */
        { 'õ' ,   "%F5" },    /* 	Small o, tilde  */
        { 'ö' ,   "%F6"   },    /* 	Small o, diæresis / umlaut  */
        { '÷' ,   "%F7" },    /* 	Division sign  */
        { 'ø' ,   "%F8" },    /* 	Small o, slash  */
        { 'ù' ,   "%F9" },    /* 	Small u, grave accent  */
        { 'ú' ,   "%FA" },    /* 	Small u, acute accent  */
        { 'û' ,   "%FB"  },    /* 	Small u, circumflex  */
        { 'ü' ,   "%FC"   },    /* 	Small u, diæresis / umlaut  */
        { 'ý' ,   "%FD" },    /* 	Small y, acute accent  */
        { 'þ' ,   "%FE"  },    /* 	Small thorn, Icelandic  */
        { '\255', "%FF"   },    /* 	Small y, diæresis / umlaut  */
    } ; 
    
struct tCharTrans Char2XML [] = 

    {
        { ' ' ,   ""         },    /* &#00;		Unused */ 
        { ' ' ,   ""         },    /* &#01;		Unused */
        { ' ' ,   ""         },    /* &#02;		Unused  */
        { ' ' ,   ""         },    /* &#03;		Unused  */
        { ' ' ,   ""         },    /* &#04;		Unused  */
        { ' ' ,   ""         },    /* &#05;		Unused  */
        { ' ' ,   ""         },    /* &#06;		Unused  */
        { ' ' ,   ""         },    /* &#07;		Unused  */
        { ' ' ,   ""         },    /* &#08;		Unused  */
        { ' ' ,   ""         },    /* &#09;		Horizontal tab  */
        { ' ' ,   ""         },    /* &#10;		Line feed  */
        { ' ' ,   ""         },    /* &#11;		Unused  */
        { ' ' ,   ""         },    /* &#12;		Unused  */
        { ' ' ,   ""         },    /* &#13;		Carriage Return  */
        { ' ' ,   ""         },    /* &#14;		Unused  */
        { ' ' ,   ""         },    /* &#15;		Unused  */
        { ' ' ,   ""         },    /* &#16;		Unused  */
        { ' ' ,   ""         },    /* &#17;		Unused  */
        { ' ' ,   ""         },    /* &#18;		Unused  */
        { ' ' ,   ""         },    /* &#19;		Unused  */
        { ' ' ,   ""         },    /* &#20;		Unused  */
        { ' ' ,   ""         },    /* &#21;		Unused  */
        { ' ' ,   ""         },    /* &#22;		Unused  */
        { ' ' ,   ""         },    /* &#23;		Unused  */
        { ' ' ,   ""         },    /* &#24;		Unused  */
        { ' ' ,   ""         },    /* &#25;		Unused  */
        { ' ' ,   ""         },    /* &#26;		Unused  */
        { ' ' ,   ""         },    /* &#27;		Unused  */
        { ' ' ,   ""         },    /* &#28;		Unused  */
        { ' ' ,   ""         },    /* &#29;		Unused  */
        { ' ' ,   ""         },    /* &#30;		Unused  */
        { ' ' ,   ""         },    /* &#31;		Unused  */
        { ' ' ,   ""         },    /* 	&#32;		Space  */
        { '!' ,   ""         },    /* 	&#33;		Exclamation mark  */
        { '"' ,   "&quot;"   },    /* 	Quotation mark  */
        { '#' ,   ""         },    /* 	&#35;		Number sign  */
        { '$' ,   ""         },    /* 	&#36;		Dollar sign  */
        { '%' ,   ""         },    /* 	&#37;		Percent sign  */
        { '&' ,   "&amp;"    },    /* 	Ampersand  */
        { '\'' ,  "&apos;"         },    /* 	&#39;		Apostrophe  */
        { '(' ,   ""         },    /* 	&#40;		Left parenthesis  */
        { ')' ,   ""         },    /* 	&#41;		Right parenthesis  */
        { '*' ,   ""         },    /* 	&#42;		Asterisk  */
        { '+' ,   ""         },    /* 	&#43;		Plus sign  */
        { ',' ,   ""         },    /* 	&#44;		Comma  */
        { '-' ,   ""         },    /* 	&#45;		Hyphen  */
        { '.' ,   ""         },    /* 	&#46;		Period (fullstop)  */
        { '/' ,   ""         },    /* 	&#47;		Solidus (slash)  */
        { '0' ,   ""         },    /* 	&#48;		Digit 0  */
        { '1' ,   ""         },    /* 	&#49;		Digit 1  */
        { '2' ,   ""         },    /* 	&#50;		Digit 2  */
        { '3' ,   ""         },    /* 	&#51;		Digit 3  */
        { '4' ,   ""         },    /* 	&#52;		Digit 4  */
        { '5' ,   ""         },    /* 	&#53;		Digit 5  */
        { '6' ,   ""         },    /* 	&#54;		Digit 6  */
        { '7' ,   ""         },    /* 	&#55;		Digit 7  */
        { '8' ,   ""         },    /* 	&#56;		Digit 8  */
        { '9' ,   ""         },    /* 	&#57;		Digit 9  */
        { ':' ,   ""         },    /* 	&#58;		Colon  */
        { ';' ,   ""         },    /* 	&#59;		Semicolon  */
        { '<' ,   "&lt;"     },    /* 	Less than  */
        { '=' ,   ""         },    /* 	&#61;		Equals sign  */
        { '>' ,   "&gt;"     },    /* 	Greater than  */
        { '?' ,   ""         },    /* 	&#63;		Question mark  */
        { '@' ,   ""         },    /* 	&#64;		Commercial at  */
        { 'A' ,   ""         },    /* 	&#65;		Capital A  */
        { 'B' ,   ""         },    /* 	&#66;		Capital B  */
        { 'C' ,   ""         },    /* 	&#67;		Capital C  */
        { 'D' ,   ""         },    /* 	&#68;		Capital D  */
        { 'E' ,   ""         },    /* 	&#69;		Capital E  */
        { 'F' ,   ""         },    /* 	&#70;		Capital F  */
        { 'G' ,   ""         },    /* 	&#71;		Capital G  */
        { 'H' ,   ""         },    /* 	&#72;		Capital H  */
        { 'I' ,   ""         },    /* 	&#73;		Capital I  */
        { 'J' ,   ""         },    /* 	&#74;		Capital J  */
        { 'K' ,   ""         },    /* 	&#75;		Capital K  */
        { 'L' ,   ""         },    /* 	&#76;		Capital L  */
        { 'M' ,   ""         },    /* 	&#77;		Capital M  */
        { 'N' ,   ""         },    /* 	&#78;		Capital N  */
        { 'O' ,   ""         },    /* 	&#79;		Capital O  */
        { 'P' ,   ""         },    /* 	&#80;		Capital P  */
        { 'Q' ,   ""         },    /* 	&#81;		Capital Q  */
        { 'R' ,   ""         },    /* 	&#82;		Capital R  */
        { 'S' ,   ""         },    /* 	&#83;		Capital S  */
        { 'T' ,   ""         },    /* 	&#84;		Capital T  */
        { 'U' ,   ""         },    /* 	&#85;		Capital U  */
        { 'V' ,   ""         },    /* 	&#86;		Capital V  */
        { 'W' ,   ""         },    /* 	&#87;		Capital W  */
        { 'X' ,   ""         },    /* 	&#88;		Capital X  */
        { 'Y' ,   ""         },    /* 	&#89;		Capital Y  */
        { 'Z' ,   ""         },    /* 	&#90;		Capital Z  */
        { '[' ,   ""         },    /* 	&#91;		Left square bracket  */
        { '\\' ,  ""         },    /* 	&#92;		Reverse solidus (backslash)  */
        { ']' ,   ""         },    /* 	&#93;		Right square bracket  */
        { '^' ,   ""         },    /* 	&#94;		Caret  */
        { '_' ,   ""         },    /* 	&#95;		Horizontal bar (underscore)  */
        { '`' ,   ""         },    /* 	&#96;		Acute accent  */
        { 'a' ,   ""         },    /* 	&#97;		Small a  */
        { 'b' ,   ""         },    /* 	&#98;		Small b  */
        { 'c' ,   ""         },    /* 	&#99;		Small c  */
        { 'd' ,   ""         },    /* 	&#100;		Small d  */
        { 'e' ,   ""         },    /* 	&#101;		Small e  */
        { 'f' ,   ""         },    /* 	&#102;		Small f  */
        { 'g' ,   ""         },    /* 	&#103;		Small g  */
        { 'h' ,   ""         },    /* 	&#104;		Small h  */
        { 'i' ,   ""         },    /* 	&#105;		Small i  */
        { 'j' ,   ""         },    /* 	&#106;		Small j  */
        { 'k' ,   ""         },    /* 	&#107;		Small k  */
        { 'l' ,   ""         },    /* 	&#108;		Small l  */
        { 'm' ,   ""         },    /* 	&#109;		Small m  */
        { 'n' ,   ""         },    /* 	&#110;		Small n  */
        { 'o' ,   ""         },    /* 	&#111;		Small o  */
        { 'p' ,   ""         },    /* 	&#112;		Small p  */
        { 'q' ,   ""         },    /* 	&#113;		Small q  */
        { 'r' ,   ""         },    /* 	&#114;		Small r  */
        { 's' ,   ""         },    /* 	&#115;		Small s  */
        { 't' ,   ""         },    /* 	&#116;		Small t  */
        { 'u' ,   ""         },    /* 	&#117;		Small u  */
        { 'v' ,   ""         },    /* 	&#118;		Small v  */
        { 'w' ,   ""         },    /* 	&#119;		Small w  */
        { 'x' ,   ""         },    /* 	&#120;		Small x  */
        { 'y' ,   ""         },    /* 	&#121;		Small y  */
        { 'z' ,   ""         },    /* 	&#122;		Small z  */
        { '{' ,   ""         },    /* 	&#123;		Left curly brace  */
        { '|' ,   ""         },    /* 	&#124;		Vertical bar  */
        { '}' ,   ""         },    /* 	&#125;		Right curly brace  */
        { '~' ,   ""         },    /* 	&#126;		Tilde  */
        { '' ,   ""         },    /* 	&#127;		Unused  */
        { '€' ,   ""         },    /* 	&#128;		Unused */
        { ' ' ,   ""         },    /* &#129;		Unused  */
        { ' ' ,   ""         },    /* &#130;		Unused  */
        { ' ' ,   ""         },    /* &#131;		Unused  */
        { ' ' ,   ""         },    /* &#132;		Unused  */
        { ' ' ,   ""         },    /* &#133;		Unused  */
        { ' ' ,   ""         },    /* &#134;		Unused  */
        { ' ' ,   ""         },    /* &#135;		Unused  */
        { ' ' ,   ""         },    /* &#136;		Unused  */
        { ' ' ,   ""         },    /* &#137;		Unused  */
        { ' ' ,   ""         },    /* &#138;		Horizontal tab  */
        { ' ' ,   ""         },    /* &#139;		Line feed  */
        { ' ' ,   ""         },    /* &#140;		Unused  */
        { ' ' ,   ""         },    /* &#141;		Unused  */
        { ' ' ,   ""         },    /* &#142;		Carriage Return  */
        { ' ' ,   ""         },    /* &#143;		Unused  */
        { ' ' ,   ""         },    /* &#144;		Unused  */
        { ' ' ,   ""         },    /* &#145;		Unused  */
        { ' ' ,   ""         },    /* &#146;		Unused  */
        { ' ' ,   ""         },    /* &#147;		Unused  */
        { ' ' ,   ""         },    /* &#148;		Unused  */
        { ' ' ,   ""         },    /* &#149;		Unused  */
        { ' ' ,   ""         },    /* &#150;		Unused  */
        { ' ' ,   ""         },    /* &#151;		Unused  */
        { ' ' ,   ""         },    /* &#152;		Unused  */
        { ' ' ,   ""         },    /* &#153;		Unused  */
        { ' ' ,   ""         },    /* &#154;		Unused  */
        { ' ' ,   ""         },    /* &#155;		Unused  */
        { ' ' ,   ""         },    /* &#156;		Unused  */
        { ' ' ,   ""         },    /* &#157;		Unused  */
        { ' ' ,   ""         },    /* &#158;		Unused  */
        { ' ' ,   ""         },    /* &#159;		Unused  */
        { ' ' ,   ""   },    /* 	Non-breaking Space  */
        { '¡' ,   ""  },    /* 	Inverted exclamation    */
        { '¢' ,   ""   },    /* 	Cent sign               */
        { '£' ,   ""  },    /* 	Pound sterling  */
        { '¤' ,   "" },    /* 	General currency sign  */
        { '¥' ,   ""    },    /* 	Yen sign  */
/*        { '¦' ,   "" },    / *  	Broken vertical bar  */
        { '¦' ,   "" },    /* 	Broken vertical bar  */
        { '§' ,   ""  },    /* 	Section sign  */
/*        { '¨' ,   ""    },    / *  	Diæresis / Umlaut  */
        { '¨' ,   ""   },    /* 	Diæresis / Umlaut  */
        { '©' ,   ""  },    /* 	Copyright               */
        { 'ª' ,   ""  },    /* 	Feminine ordinal  */
        { '«' ,   "" },    /* 	Left angle quote, guillemot left  */
        { '¬' ,   ""   },    /*	Not sign  */
        { '­' ,   ""    },    /* 	Soft hyphen  */
        { '®' ,   ""    },    /* 	Registered trademark  */
/*        { '¯' ,   ""   },    / *  	Macron accent  */
        { '¯' ,   ""  },    /* 	Macron accent  */
        { '°' ,   ""    },    /* 	Degree sign  */
        { '±' ,   "" },    /* 	Plus or minus  */
        { '²' ,   ""   },    /* 	Superscript two  */
        { '³' ,   ""   },    /* 	Superscript three  */
        { '´' ,   ""  },    /* 	Acute accent  */
        { 'µ' ,   ""  },    /* 	Micro sign  */
        { '¶' ,   ""   },    /* 	Paragraph sign  */
        { '·' ,   "" },    /* 	Middle dot  */
        { '¸' ,   ""  },    /* 	Cedilla  */
        { '¹' ,   ""   },    /* 	Superscript one  */
        { 'º' ,   ""   },    /* 	Masculine ordinal  */
        { '»' ,   ""  },    /* 	Right angle quote, guillemot right  */
        { '¼' ,   "" },    /* 	Fraction one-fourth  */
        { '½' ,   "" },    /* 	Fraction one-half  */
        { '¾' ,   "" },    /* 	Fraction three-fourths  */
        { '¿' ,   "" },    /* 	Inverted question mark  */
        { 'À' ,   "" },    /* 	Capital A, grave accent  */
        { 'Á' ,   "" },    /* 	Capital A, acute accent  */
        { 'Â' ,   ""  },    /* 	Capital A, circumflex  */
        { 'Ã' ,   "" },    /* 	Capital A, tilde  */
        { 'Ä' ,   ""   },    /* 	Capital A, diæresis / umlaut  */
        { 'Å' ,   ""  },    /* 	Capital A, ring  */
        { 'Æ' ,   ""  },    /* 	Capital AE ligature  */
        { 'Ç' ,   "" },    /* 	Capital C, cedilla  */
        { 'È' ,   "" },    /* 	Capital E, grave accent  */
        { 'É' ,   "" },    /* 	Capital E, acute accent  */
        { 'Ê' ,   ""  },    /* 	Capital E, circumflex  */
        { 'Ë' ,   ""   },    /* 	Capital E, diæresis / umlaut  */
        { 'Ì' ,   "" },    /* 	Capital I, grave accent  */
        { 'Í' ,   "" },    /* 	Capital I, acute accent  */
        { 'Î' ,   ""  },    /* 	Capital I, circumflex  */
        { 'Ï' ,   ""   },    /* 	Capital I, diæresis / umlaut  */
        { 'Ð' ,   ""    },    /* 	Capital Eth, Icelandic  */
        { 'Ñ' ,   "" },    /* 	Capital N, tilde  */
        { 'Ò' ,   "" },    /* 	Capital O, grave accent  */
        { 'Ó' ,   "" },    /* 	Capital O, acute accent  */
        { 'Ô' ,   ""  },    /* 	Capital O, circumflex  */
        { 'Õ' ,   "" },    /* 	Capital O, tilde  */
        { 'Ö' ,   ""   },    /* 	Capital O, diæresis / umlaut  */
        { '×' ,   ""  },    /* 	Multiply sign  */
        { 'Ø' ,   "" },    /* 	Capital O, slash  */
        { 'Ù' ,   "" },    /* 	Capital U, grave accent  */
        { 'Ú' ,   "" },    /* 	Capital U, acute accent  */
        { 'Û' ,   ""  },    /* 	Capital U, circumflex  */
        { 'Ü' ,   ""   },    /* 	Capital U, diæresis / umlaut  */
        { 'Ý' ,   "" },    /* 	Capital Y, acute accent  */
        { 'Þ' ,   ""  },    /* 	Capital Thorn, Icelandic  */
        { 'ß' ,   ""  },    /* 	Small sharp s, German sz  */
        { 'à' ,   "" },    /* 	Small a, grave accent  */
        { 'ß' ,   "" },    /* 	Small a, acute accent  */
        { 'â' ,   ""  },    /* 	Small a, circumflex  */
        { 'ã' ,   "" },    /* 	Small a, tilde  */
        { 'ä' ,   ""   },    /* 	Small a, diæresis / umlaut  */
        { 'å' ,   ""  },    /* 	Small a, ring  */
        { 'æ' ,   ""  },    /* 	Small ae ligature  */
        { 'ç' ,   "" },    /* 	Small c, cedilla  */
        { 'è' ,   "" },    /* 	Small e, grave accent  */
        { 'é' ,   "" },    /* 	Small e, acute accent  */
        { 'ê' ,   ""  },    /* 	Small e, circumflex  */
        { 'ë' ,   ""   },    /* 	Small e, diæresis / umlaut  */
        { 'ì' ,   "" },    /* 	Small i, grave accent  */
        { 'í' ,   "" },    /* 	Small i, acute accent  */
        { 'î' ,   ""  },    /* 	Small i, circumflex  */
        { 'ï' ,   ""   },    /* 	Small i, diæresis / umlaut  */
        { 'ð' ,   ""    },    /* 	Small eth, Icelandic  */
        { 'ñ' ,   "" },    /* 	Small n, tilde  */
        { 'ò' ,   "" },    /* 	Small o, grave accent  */
        { 'ó' ,   "" },    /* 	Small o, acute accent  */
        { 'ô' ,   ""  },    /* 	Small o, circumflex  */
        { 'õ' ,   "" },    /* 	Small o, tilde  */
        { 'ö' ,   ""   },    /* 	Small o, diæresis / umlaut  */
        { '÷' ,   "" },    /* 	Division sign  */
        { 'ø' ,   "" },    /* 	Small o, slash  */
        { 'ù' ,   "" },    /* 	Small u, grave accent  */
        { 'ú' ,   "" },    /* 	Small u, acute accent  */
        { 'û' ,   ""  },    /* 	Small u, circumflex  */
        { 'ü' ,   ""   },    /* 	Small u, diæresis / umlaut  */
        { 'ý' ,   "" },    /* 	Small y, acute accent  */
        { 'þ' ,   ""  },    /* 	Small thorn, Icelandic  */
        { '\255', ""   },    /* 	Small y, diæresis / umlaut  */
    } ; 
 
    
struct tCharTrans Html2Char [] = 
 
    {
        { '\x80' ,   "&#128;"         },    /* &#129;		Unused  */
        { '\x81' ,   "&#129;"         },    /* &#129;		Unused  */
        { '\x82' ,   "&#130;"         },    /* &#130;		Unused  */
        { '\x83' ,   "&#131;"         },    /* &#131;		Unused  */
        { '\x84' ,   "&#132;"         },    /* &#132;		Unused  */
        { '\x85' ,   "&#133;"         },    /* &#133;		Unused  */
        { '\x86' ,   "&#134;"         },    /* &#134;		Unused  */
        { '\x87' ,   "&#135;"         },    /* &#135;		Unused  */
        { '\x88' ,   "&#136;"         },    /* &#136;		Unused  */
        { '\x89' ,   "&#137;"         },    /* &#137;		Unused  */
        { '\x8a' ,   "&#138;"         },    /* &#138;		Horizontal tab  */
        { '\x8b' ,   "&#139;"         },    /* &#139;		Line feed  */
        { '\x8c' ,   "&#140;"         },    /* &#140;		Unused  */
        { '\x8d' ,   "&#141;"         },    /* &#141;		Unused  */
        { '\x8e' ,   "&#142;"         },    /* &#142;		Carriage Return  */
        { '\x8f' ,   "&#143;"         },    /* &#143;		Unused  */
        { '\x90' ,   "&#144;"         },    /* &#144;		Unused  */
        { '\x91' ,   "&#145;"         },    /* &#145;		Unused  */
        { '\x92' ,   "&#146;"         },    /* &#146;		Unused  */
        { '\x93' ,   "&#147;"         },    /* &#147;		Unused  */
        { '\x94' ,   "&#148;"         },    /* &#148;		Unused  */
        { '\x95' ,   "&#149;"         },    /* &#149;		Unused  */
        { '\x96' ,   "&#150;"         },    /* &#150;		Unused  */
        { '\x97' ,   "&#151;"         },    /* &#151;		Unused  */
        { '\x98' ,   "&#152;"         },    /* &#152;		Unused  */
        { '\x99' ,   "&#153;"         },    /* &#153;		Unused  */
        { '\x9a' ,   "&#154;"         },    /* &#154;		Unused  */
        { '\x9b' ,   "&#155;"         },    /* &#155;		Unused  */
        { '\x9c' ,   "&#156;"         },    /* &#156;		Unused  */
        { '\x9d' ,   "&#157;"         },    /* &#157;		Unused  */
        { '\x9e' ,   "&#158;"         },    /* &#158;		Unused  */
        { '\x9f' ,   "&#159;"         },    /* &#159;		Unused  */
        { 'Æ' ,   "&AElig"  },    /* 	Capital AE ligature  */
        { 'Á' ,   "&Aacute" },    /* 	Capital A, acute accent  */
        { 'Â' ,   "&Acirc"  },    /* 	Capital A, circumflex  */
        { 'À' ,   "&Agrave" },    /* 	Capital A, grave accent  */
        { 'Å' ,   "&Aring"  },    /* 	Capital A, ring  */
        { 'Ã' ,   "&Atilde" },    /* 	Capital A, tilde  */
        { 'Ä' ,   "&Auml"   },    /* 	Capital A, diæresis / umlaut  */
        { 'Ç' ,   "&Ccedil" },    /* 	Capital C, cedilla  */
        { 'Ð' ,   "&ETH"    },    /* 	Capital Eth, Icelandic  */
        { 'É' ,   "&Eacute" },    /* 	Capital E, acute accent  */
        { 'Ê' ,   "&Ecirc"  },    /* 	Capital E, circumflex  */
        { 'È' ,   "&Egrave" },    /* 	Capital E, grave accent  */
        { 'Ë' ,   "&Euml"   },    /* 	Capital E, diæresis / umlaut  */
        { 'Í' ,   "&Iacute" },    /* 	Capital I, acute accent  */
        { 'Î' ,   "&Icirc"  },    /* 	Capital I, circumflex  */
        { 'Ì' ,   "&Igrave" },    /* 	Capital I, grave accent  */
        { 'Ï' ,   "&Iuml"   },    /* 	Capital I, diæresis / umlaut  */
        { 'Ñ' ,   "&Ntilde" },    /* 	Capital N, tilde  */
        { 'Ó' ,   "&Oacute" },    /* 	Capital O, acute accent  */
        { 'Ô' ,   "&Ocirc"  },    /* 	Capital O, circumflex  */
        { 'Ò' ,   "&Ograve" },    /* 	Capital O, grave accent  */
        { 'Ø' ,   "&Oslash" },    /* 	Capital O, slash  */
        { 'Õ' ,   "&Otilde" },    /* 	Capital O, tilde  */
        { 'Ö' ,   "&Ouml"   },    /* 	Capital O, diæresis / umlaut  */
        { 'Þ' ,   "&THORN"  },    /* 	Capital Thorn, Icelandic  */
        { 'Ú' ,   "&Uacute" },    /* 	Capital U, acute accent  */
        { 'Û' ,   "&Ucirc"  },    /* 	Capital U, circumflex  */
        { 'Ù' ,   "&Ugrave" },    /* 	Capital U, grave accent  */
        { 'Ü' ,   "&Uuml"   },    /* 	Capital U, diæresis / umlaut  */
        { 'Ý' ,   "&Yacute" },    /* 	Capital Y, acute accent  */
        { 'ß' ,   "&aacute" },    /* 	Small a, acute accent  */
        { 'â' ,   "&acirc"  },    /* 	Small a, circumflex  */
        { '´' ,   "&acute"  },    /* 	Acute accent  */
        { 'æ' ,   "&aelig"  },    /* 	Small ae ligature  */
        { 'à' ,   "&agrave" },    /* 	Small a, grave accent  */
        { '&' ,   "&amp"    },    /* 	Ampersand  */
        { 'å' ,   "&aring"  },    /* 	Small a, ring  */
        { 'ã' ,   "&atilde" },    /* 	Small a, tilde  */
        { 'ä' ,   "&auml"   },    /* 	Small a, diæresis / umlaut  */
        { '¦' ,   "&brkbar" },    /* 	Broken vertical bar  */
        { '¦' ,   "&brvbar" },    /*  	Broken vertical bar  */
        { 'ç' ,   "&ccedil" },    /* 	Small c, cedilla  */
        { '¸' ,   "&cedil"  },    /* 	Cedilla  */
        { '¢' ,   "&cent"   },    /* 	Cent sign  */
        { '©' ,   "&copy"  },    /* 	Copyright  */
        { '¤' ,   "&curren" },    /* 	General currency sign  */
        { '°' ,   "&deg"    },    /* 	Degree sign  */
        { '¨' ,   "&die"   },    /* 	Diæresis / Umlaut  */
        { '÷' ,   "&divide" },    /* 	Division sign  */
        { 'é' ,   "&eacute" },    /* 	Small e, acute accent  */
        { 'ê' ,   "&ecirc"  },    /* 	Small e, circumflex  */
        { 'è' ,   "&egrave" },    /* 	Small e, grave accent  */
        { 'ð' ,   "&eth"    },    /* 	Small eth, Icelandic  */
        { 'ë' ,   "&euml"   },    /* 	Small e, diæresis / umlaut  */
        { '¬' ,   "&euro"   },    /*	Euro sign  */
        { '½' ,   "&frac12" },    /* 	Fraction one-half  */
        { '¼' ,   "&frac14" },    /* 	Fraction one-fourth  */
        { '¾' ,   "&frac34" },    /* 	Fraction three-fourths  */
        { '>' ,   "&gt"     },    /* 	Greater than  */
        { '¯' ,   "&hibar"  },    /* 	Macron accent  */
        { 'í' ,   "&iacute" },    /* 	Small i, acute accent  */
        { 'î' ,   "&icirc"  },    /* 	Small i, circumflex  */
        { '¡' ,   "&iexcl"  },    /* 	Inverted exclamation  */
        { 'ì' ,   "&igrave" },    /* 	Small i, grave accent  */
        { '¿' ,   "&iquest" },    /* 	Inverted question mark  */
        { 'ï' ,   "&iuml"   },    /* 	Small i, diæresis / umlaut  */
        { '«' ,   "&laquo" },    /* 	Left angle quote, guillemot left  */
        { '<' ,   "&lt"     },    /* 	Less than  */
        { '¯' ,   "&macr"   },    /*  	Macron accent  */
        { 'µ' ,   "&micro"  },    /* 	Micro sign  */
        { '·' ,   "&middot" },    /* 	Middle dot  */
        { ' ' ,   "&nbsp"   },    /* 	Non-breaking Space  */
        { 'ñ' ,   "&ntilde" },    /* 	Small n, tilde  */
        { 'ó' ,   "&oacute" },    /* 	Small o, acute accent  */
        { 'ô' ,   "&ocirc"  },    /* 	Small o, circumflex  */
        { 'ò' ,   "&ograve" },    /* 	Small o, grave accent  */
        { 'ª' ,   "&ordf"  },    /* 	Feminine ordinal  */
        { 'º' ,   "&ordm"   },    /* 	Masculine ordinal  */
        { 'ø' ,   "&oslash" },    /* 	Small o, slash  */
        { 'õ' ,   "&otilde" },    /* 	Small o, tilde  */
        { 'ö' ,   "&ouml"   },    /* 	Small o, diæresis / umlaut  */
        { '¶' ,   "&para"   },    /* 	Paragraph sign  */
        { '±' ,   "&plusmn" },    /* 	Plus or minus  */
        { '£' ,   "&pound"  },    /* 	Pound sterling  */
        { '"' ,   "&quot"   },    /* 	Quotation mark  */
        { '»' ,   "&raquo"  },    /* 	Right angle quote, guillemot right  */
        { '®' ,   "&reg"    },    /* 	Registered trademark  */
        { '§' ,   "&sect"  },    /* 	Section sign  */
        { '­' ,   "&shy"    },    /* 	Soft hyphen  */
        { '¹' ,   "&sup1"   },    /* 	Superscript one  */
        { '²' ,   "&sup2"   },    /* 	Superscript two  */
        { '³' ,   "&sup3"   },    /* 	Superscript three  */
        { 'ß' ,   "&szlig"  },    /* 	Small sharp s, German sz  */
        { 'þ' ,   "&thorn"  },    /* 	Small thorn, Icelandic  */
        { '×' ,   "&times"  },    /* 	Multiply sign  */
        { 'ú' ,   "&uacute" },    /* 	Small u, acute accent  */
        { 'û' ,   "&ucirc"  },    /* 	Small u, circumflex  */
        { 'ù' ,   "&ugrave" },    /* 	Small u, grave accent  */
        { '¨' ,   "&um"    },    /*  	Diæresis / Umlaut  */
        { 'ü' ,   "&uuml"   },    /* 	Small u, diæresis / umlaut  */
        { 'ý' ,   "&yacute" },    /* 	Small y, acute accent  */
        { '¥' ,   "&yen"    },    /* 	Yen sign  */
        { '\255', "&yuml"   },    /* 	Small y, diæresis / umlaut  */
} ;


int sizeHtml2Char = sizeof (Html2Char) / sizeof (struct tCharTrans) ;

