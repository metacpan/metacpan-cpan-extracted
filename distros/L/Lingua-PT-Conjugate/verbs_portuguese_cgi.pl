#!/usr/bin/perl -w  

## This script offers a web interface to the conjug and unconj programs.
##
## INSTALLATION INSTRUCTIONS
##
## 1 REQUISITES :
## 
##   You must have write access to a directory containing web-executable
##   scripts.
## 
##   You must have installed the Lingua::PT::Conjugate and
##   Lingua::PT::UnConjugate modules (i.e. done 'make install' in this
##   directory).
##
## 2 INSTALLATION
##
##   Copy this file to the desired directory.
##
## 3 CONFIGURATION
##
##   Set this variable to the URL that reaches the script.
##

$thisurl = "http://anonimo.local/cgi-bin-etienne/verbs_portuguese_cgi.pl";

##   If you only have a local (not site-wide) installation of the Lingua::PT
##   modules, add to the @INC variable the directory in which the modules
##   are installed : uncomment the line below and replace the directory by
##   an appropriate value.
## 
BEGIN {
    ## push(@INC, "/home/etienne/prog/perl/myinstall/lib/site_perl";
}

## 4 : That should be it!
##
## AUTHOR : Etienne Grossmann <etienne@isr.ist.utl.pt>
##
## This script is part of the Lingua::PT package. It is distributed in the
## hope that it will be useful but comes with no warranty of any kind.
##
## Don't hesitate to send me feedback, comments, patches, suggestions etc.
##

use Lingua::PT::UnConjugate qw( unconj list_entries );
use Lingua::PT::Conjugate qw( conjug );

print(join "\n",
      "Content-type: text/html",
      "","",
      "<head>",
      "<title>Portuguese Verb Conjugation &amp; Recognition</title>",
      "<meta name=\"keywords\" ",
      "content=\"Portuguese Portugues verb verbo conjugation recognition\" />",
      "<meta name=\"description\" content=\"Conjugate and recognize Portuguese verbs\" />",
      "<link rel=\"stylesheet\" type=\"text/css\"",
      "href=\"http://omni.isr.ist.utl.pt/~etienne/etienne.css\" />",
      "</head>",
      "<body>");


%FORM = getform();

$FORM{verbname} = "" unless exists $FORM{verbname};
$FORM{action} = "conjug" unless exists $FORM{action};

if (! $FORM{verbname}) {

    print "<H2>You haven't specified any verb, or there's a bug somewhere .... </H2>";
    
} elsif ($FORM{action} eq "unconj") {

    $theverb = $FORM{verbname} ;
    $theverb =~ /\s*(\S+)\s*/ ;
    $theverb = $1 ;
    
    $ans = unconj( $theverb ) ;
    @res = list_entries( "l", $ans ) ;
    
    if( @res ) 
    {
        $v = '' ;
        foreach (@res)
        {
            $v .= "<TR><TD ALIGN=CENTER><BIG>" ;
            $v .= join "</BIG></TD><TD ALIGN=CENTER><BIG>", @$_ ;
            $v .= "</BIG></TD></TR>" ;
        }
        $v = join "\n", "<BIG>",
        "<center>",
        "<P>The word <B>$theverb</B> is recognized as :",
        "<BR>",
        "<P><TABLE BORDER=5 CELLPADDING=10>",
        "<TR><TD ALIGN=CENTER><BIG>Infinitive</BIG></TD>",
        "<TD ALIGN=CENTER><BIG>Tense</BIG></TD>",
        "<TD ALIGN=CENTER><BIG>Person</BIG></TD></TR>",
        "$v",
        "</TABLE>",
        "<BR>",
        "</BIG>",
        "</center>","\n";

    } else {                    # Second try, with accents
        
        $ans = unconj("-a", $theverb ) ;
        @res = list_entries( "l", $ans ) ;
        
        if( @res )
        {
            $v = '' ;
            foreach $x (@res) {
                my ($i,$t,$p) = @$x ;
                $x->[3] = conjug("s",$i,$t,$p) ;
                $v .= "<TR><TD ALIGN=CENTER><BIG>" ;
                $v .= join "</BIG></TD><TD ALIGN=CENTER><BIG>", @$x ;
                $v .= "</BIG></TD></TR>" ;
            }
            $v = join "\n",
            "<BIG>",
            "<center>",
            "<P>The word <B>$theverb</B> is not recognized as-is. However, it looks",
            "like :",
            "<BR>",
            "<P><TABLE BORDER=5 CELLPADDING=10 CELLSPACING=0>",
            "<TR><TD ALIGN=CENTER><BIG>Infinitive</BIG></TD>",
            "<TD ALIGN=CENTER><BIG>Tense</BIG></TD>",
            "<TD ALIGN=CENTER><BIG>Person</BIG></TD>",
            "<TD ALIGN=CENTER><BIG>Correct Form</BIG></TD></TR>",
            "$v",
            "</TABLE>",
            "<BR>",
            "<P><B>",
            "This software comes with NO GUARANTY. </B>  ",
            "</BIG>",
            "</center>","\n";

        } else {
            $v = join "\n",
            "<BIG><CENTER>",
            "Sorry, $FORM{verbname} is not recognized. This could be due to a bug",
            "</BIG></CENTER>","\n";
        }
    }

    print "<html>",
    "<h3> Output of unconj : </h3>\n",
    "$v <BR>\n",
    "<p> Problems? Found an error in the program?\n",
    "<A HREF=\"mailto:etienne\@isr.ist.utl.pt\">send me a mail.</a>\n";

    
} else {                                                                                        # Default action : Conjugate 

    $theverb = $FORM{verbname} ;
    $theverb =~ /\s*(\S+)\s*/ ;
    $theverb = $1 ;
    
    @opts = ("ol") ;
    # Specify if you want iso accents
    push @opts, "-i" if $FORM{isoacc} ;
    $v = conjug (@opts , $theverb) ;
    
    if( $v =~ /\S/ ){

        # At beginning of row, put tense in bold and alternate row colors
        my $i = -1;
        sub rowcol () {$i++ % 2 ? 'bgcolor="#efefff"' : "" }
        $v =~ s{^(.*)?\s*,}{"<TR " . rowcol() . "><TD> <B>$1</B> </TD><TD> "}emg;
        # End of row
        $v =~ s!$!</TR></TD>\n!mg ; 
        
        # Separate table cells
        $v =~ s{\s*,\s*}{ </TD><TD> }g ;
        
        # Put the persons
        $tmp = join("</B></TD><TD><B>",
                    "<\TR><TR><TD COLSPAN=7></TD><\TR>",
                    "\n<TR bgcolor=\"#dfdfff\"><TD><B>", "eu", "tu", "ela/ele",
                    "nós", "vós", "eles/elas",
                    "</B><\TR><TR><TD COLSPAN=7></TD><\TR>");
        
        $tmp =~ s/ó/'o/g if $FORM{isoacc} ; # '
        $v =~ s{(.*?\<\/TR\>)}{ $1 $tmp }m ;
        
        $v = "<center><TABLE rules=\"none\" cellpadding=\"3\">$v</TABLE></center>";
        
        
    } else {
        
        $v =  "Sorry, $FORM{verbname} does not look like a verb ... \n" ;
    }

    print "<html>",
    "<h3> Output of conjug : </h3>\n",
    "$v <BR>\n",
    "<p> Problems? Found an error in the program?\n",
    "<A HREF=\"mailto:etienne\@isr.ist.utl.pt\">send me a mail.</a>\n";
}


printform();

print <<EOFHTML;
</BODY>
    </HTML>
    EOFHTML


    sub printform {

        my ($cconj,$cunconj) = $FORM{action} eq "unconj" ?
            ("", 'checked="checked"') :       ('checked="checked"', "") ;

        print <<EOFHTML;
        <h1>Portuguese Verb Conjugation and Recognition Form</h1>

            <form method="post" action="$thisurl" enctype="application/x-www-form-urlencoded">

            Accents can be entered as "'e" for "é", "~a" for "ã", "\c" for "ç" etc.<br>

            <p class="myform"><br>
            Enter a new query 
            <input type="text" name="verbname"  />
            <input type="submit" name="submit" value="submit" />

            Action :
            <input type="radio" name="action" value="conj"   $cconj   />Conjugate
            <input type="radio" name="action" value="unconj" $cunconj />Recognize
            <br>
            <br>
            <input type="checkbox" name="isoacc" unchecked>
            Don't output accentuated (ISO-8959-1) characters<br>
<br>
</p>
</form>

<p>Author : <A HREF="mailto:etienne\@isr.ist.utl.pt">Etienne Grossmann</A>
(contact me for any kind of feedback).</p>

    EOFHTML
    # '
}


# Straight out of everycht.pl  v.3.61 (w/ slight changes), 
# thanks, Matt Hahnfeld
#>---------------------------------------<#
#| Sub getform - reads form data         |#
#>---------------------------------------<#

sub getform {
    my $buffer = "";
				# Post method

    if (exists ($ENV{'REQUEST_METHOD'}) && $ENV{'REQUEST_METHOD'} eq "POST") {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

				# Using GET Method

    } elsif (exists $ENV{'QUERY_STRING'}) {
        $buffer = $ENV{'QUERY_STRING'};
    }

    my @pairs=split(/&/,$buffer);
    foreach my $pair (@pairs)
    {
        my ($name, $value) = split(/=/,$pair);
        ## my ($name=$a[0];
        ## my $value=$a[1];
        $value =~ s/\+/ /g;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $value =~ s/~!/ ~!/g;
        $value =~ s/\</\&lt\;/g;  # html tag removal (remove these lines to enable HTML tags in messages)
        $value =~ s/\>/\&gt\;/g;  # html tag removal (remove these lines to enable HTML tags in messages)
        $value =~ s/[\r\n]//g;
        push (@data,$name,$value);
    }
    my %form=@data;
}
