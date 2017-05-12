package HTML::Template::Filter::Dreamweaver;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Template::Filter::Dreamweaver ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( DWT2HTML DWT2HTMLExpr 
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.01';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
sub escapeQuote {
    my $toencode = shift;

    if    ( $toencode !~ /\'/ ) { return "'$toencode'";   }
    elsif ( $toencode !~ /\"/ ) { return "\"$toencode\""; }
    else {
	$toencode =~ s{\"}{\'}gso;
	return "\"$toencode\"";
    }
}

sub handleTemplateEditable {
    my $str = shift;
    my $default = shift;

    my $ret = "<!-- TMPL_VAR";
    my $name;
    if ( $str =~ m{\s[Nn][Aa][Mm][Ee]\s*=\s*([\"\'])(.*?)\1}s ) {
	$name = $2;
	$ret .= " NAME=$1$2$1";
    }

    if ( $str =~ m{\s[Ee][Ss][Cc][Aa][Pp][Ee]\s*=\s*([\"\'])(.*?)\1}s ) {
	$ret .= " ESCAPE=$2";
    }
    
    if ( 0 && $default ) {
	$ret .= " DEFAULT=" . escapeQuote($default);
    }

    $ret .= " -->";
    return $ret;
}

sub handleTernary {
    my $str = shift;
    my $defaults = shift;
    my $use_expr = shift;

    my ( $char, $expr ) = $str =~ m{\s[Ee][Xx][Pp][Rr]\s*=\s*([\"\'])(.*?)\1}s;
    
    my ( $if, $true, $false ) = $expr =~ m{(.*)\?(.*)\:(.*)};

    $if =~ s/^\s+//g;
    $if =~ s/\s+$//g;
    $true =~ s/^\s+//g;
    $true =~ s/\s+$//g;
    $false =~ s/^\s+//g;
    $false =~ s/\s+$//g;

    while ( $true =~ m{([\w\'\"]+)}sg ) {
	if ( $defaults->{ $1 } ) {
	    $true = handleTemplateExpr( "cond=" . escapeQuote($true), $defaults, $use_expr );
	    last;
	}
    }

    while ( $false =~ m{([\w\'\"]+)}sg ) {
	if ( $defaults->{ $1 } ) {
	    $false = handleTemplateExpr( "cond=" . escapeQuote($false), $defaults, $use_expr );
	    last;
	}
    }

    $true = "" if $true eq '""' || $true eq "''";
    $false = "" if $false eq '""' || $false eq "''";
      
    return "<!-- TemplateBeginIf cond=$char$if$char -->$true<TMPL_ELSE>$false<!-- TemplateEndIf -->";
}

sub handleTemplateExpr {
    my $str = shift;
    my $defaults = shift;
    my $use_expr = shift;

    my $ret = "<!-- TMPL_VAR";
    my $name;
    if ( $str =~ m{\s[Ee][Xx][Pp][Rr]\s*=\s*([\"\'])(.*?)\1}s ) {
	$name = $2;
	$name =~ s/^\s+//s;
	$name =~ s/\s+$//s;
	if ( $name =~ m{\?.*\:.+} ) {
	    return handleTernary( $str, $defaults, $use_expr );
	}
	if ( !$use_expr || exists( $defaults->{ $name } ) ) {
	    $ret .= " NAME=$1$name$1";
	}
	else {
	    $ret .= " EXPR=$1$name$1";
	}
    }

    if ( $str =~ m{\s[Ee][Ss][Cc][Aa][Pp][Ee]\s*=\s*([\"\'])(.*?)\1}s ) {
	$ret .= " ESCAPE=$2" if $2;
    }
    elsif ( $defaults->{ $name }->{ ESCAPE } ) {
	$ret .= " ESCAPE=$defaults->{ $name }->{ ESCAPE }";
    }
    
    if ( $defaults->{ $name }->{ DEFAULT } ) {
	$ret .= " DEFAULT=" . escapeQuote($defaults->{ $name }->{ DEFAULT });
    }

    $ret .= " -->";
    return $ret;
}

sub handleTemplateIf {
    my $str = shift;
    my $character = shift;
    my $defaults = shift;
    my $use_expr = shift;

    my $ret = "";

    $str =~ s/^\s+//s;
    $str =~ s/\s+$//s;

    if ( $str =~ m{^\!} ) {
	$ret = "<TMPL_BEGIN_UNLESS";
	$str =~ s/^\!//;
    }
    else {
	$ret = "<TMPL_BEGIN_IF";
    }

    if ( !$use_expr || exists( $defaults->{ $str } ) ) {
	$ret .= " NAME=$character$str$character";
    }
    else {
	my %words;
	my $hasText = 0;
	
	while ( $str =~ m{([\w\'\"]+)}sg ) {
	    if ( $defaults->{ $1 } && $defaults->{ $1 }->{ TYPE } eq "text" ) {
		$hasText = 1;
		last;
	    }
	}

	if ( $hasText ) {
	    $str =~ s/\s*\=\=\s*/ eq /sg;
	    $str =~ s/\s*\!\=\s*/ ne /sg;
	    $str =~ s/\s*\<\=\>\s*/ cmp /sg;
	    $str =~ s/\s*\>\=\s*/ ge /sg;
	    $str =~ s/\s*\>\s*/ gt /sg;
	    $str =~ s/\s*\<\=\s*/ le /sg;
	    $str =~ s/\s*\<\s*/ lt /sg;
	}

	$ret .= " EXPR=$character$str$character";
    }

    $ret .= ">";
    return $ret;
}

sub addEndifs {
    my $str = shift;

    my $begins = 0;
    my $ends = 0;
    while ( $str =~ m{<TMPL_BEGIN_(?:IF|UNLESS)}g ) {
	$begins++;
    }

    while ( $str =~ m{</TMPL_END_IF_UNLESS>}g ) {
	$ends++;
    }

    $str .= ( "</TMPL_END_IF_UNLESS>" x ($begins - $ends) );
}

sub DWT2HTML {
    my $dwt = shift;
    my $force_template_expr = shift || 0;

    my $using_template_expr = caller(6) && caller(6) eq "HTML::Template::Expr" ? 1 : 0;
    $using_template_expr ||= $force_template_expr;

    my %params = ( "_isFirst" => {},
		   "_isLast" => {},
		   "_index" => {},
		 );
    while ( $$dwt =~ /<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Pp][Aa][Rr][Aa][Mm](.*?)-->/g ) {
	my $text = $1;

	my $name;
	if ( $text =~ m{\s[Nn][Aa][Mm][Ee]=([\'\"])(.*?)\1} ) {
	    $name = $2;
	}
	else {
	    next;
	}

	my $val = "";
	if ( $text =~ m{\s[Vv][Aa][Ll][Uu][Ee]=([\'\"])(.*?)\1} ) {
	    $val = $2;
	}
#	else {
#	    next;
#	}

	my $type = "";
	if ( $text =~ m{\s[Tt][Yy][Pp][Ee]=([\'\"])(.*?)\1} ) {
	    $type = $2;
	}

	my $escape = "";
	if ( $text =~ m{\s[Ee][Ss][Cc][Aa][Pp][Ee]=([\'\"])(.*?)\1} ) {
	    $escape = $2;
	}

	if ( lc($type) eq "boolean" ) {
	    $val = lc($val) eq "false" ? 1 : 0;
	}

	$params{ $name } = { DEFAULT => $val || "",
			     ESCAPE => $escape || "",
			     TYPE => lc($type || ""),
			   };
    }

    $$dwt =~ s/\@\@\(\s*_document._Get\(\s*([\'\"])(.*?)\1\s*\,\s*([\'\"])(.*?)\3\s*\)\s*\)\@\@/<!-- TemplateExpr expr=$1$2$1 ESCAPE=$3$4$3 -->/sg;
    $$dwt =~ s/\@\@\(\s*_document._Get\(\s*([\'\"])(.*?)\1\s*\)\s*\)\@\@/<!-- TemplateExpr expr=$1$2$1 -->/sg;

    $$dwt =~ s/_document\[([\'\"])(.*?)\1\]/$2/sg;
    $$dwt =~ s/_repeat\[([\'\"])(.*?)\1\]/$2/sg;
    $$dwt =~ s/<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Pp][Aa][Rr][Aa][Mm].*?-->\s*//sg;

    # TemplateBeginEditable
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Bb][Ee][Gg][Ii][Nn][Ee][Dd][Ii][Tt][Aa][Bb][Ll][Ee](.*?)-->(.*?)<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Ee][Nn][Dd][Ee][Dd][Ii][Tt][Aa][Bb][Ll][Ee]\s*-->}{handleTemplateEditable( $1, $2 )}esg;

    $$dwt =~ s{\@\@\((.*?)\)\@\@}{ my $var = $1;
				   $var =~ s/^\s+//s;
				   $var =~ s/\s+$//s;
				   sprintf( "<!-- TemplateExpr expr=%s%s -->", 
					    escapeQuote($var), 
					    $params{$var} && $params{$var}->{ ESCAPE } ? " ESCAPE='$params{$var}->{ ESCAPE}'" : "",
					  )
			       }esg;

    # TemplateExpr
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Ee][Xx][Pp][Rr](.*?)-->}{handleTemplateExpr($1, \%params, $using_template_expr)}esg;

    # TemplateBeginIf Cond=
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Bb][Ee][Gg][Ii][Nn][Ii][Ff]\s+[Cc][Oo][Nn][Dd]\s*=\s*([\"\'])(.*?)\1\s*-->}{handleTemplateIf($2, $1, \%params, $using_template_expr )}esg;
    # TemplateEndIf
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Ee][Nn][Dd][Ii][Ff]\s*-->}{</TMPL_END_IF_UNLESS>}sg;

    # IgnoreTemplateBeginIf Cond=   NOTE: this is not a real dreamweaver tag, but we need it because dreamweaver doesn't
    # like to have TemplateBeginIf tags before the <body> tag
    $$dwt =~ s{<!--\s*[Ii][Gg][Nn][Oo][Rr][Ee][Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Bb][Ee][Gg][Ii][Nn][Ii][Ff]\s+[Cc][Oo][Nn][Dd]\s*=\s*([\"\'])(.*?)\1\s*-->}{handleTemplateIf($2, $1, \%params, $using_template_expr )}esg;

    # IgnoreTemplateEndIf   NOTE: Like the IgnoreTemplateBeginIf tag, this tag is not a real dreamweaver tag
    $$dwt =~ s{<!--\s*[Ii][Gg][Nn][Oo][Rr][Ee][Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Ee][Nn][Dd][Ii][Ff]\s*-->}{</TMPL_END_IF_UNLESS>}sg;

    # TemplateBeginMultipleIf
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Bb][Ee][Gg][Ii][Nn][Mm][Uu][Ll][Tt][Ii][Pp][Ll][Ee][Ii][Ff]\s*-->}{<!-- TemplateBeginMultipleIf -->}sg;

    # TemplateEndMultipleIf
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Ee][Nn][Dd][Mm][Uu][Ll][Tt][Ii][Pp][Ll][Ee][Ii][Ff]\s*-->}{<!-- TemplateEndMultipleIf -->}sg;

    # TemplateBeginIfClause Cond=
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Bb][Ee][Gg][Ii][Nn][Ii][Ff][Cc][Ll][Aa][Uu][Ss][Ee]\s+[Cc][Oo][Nn][Dd]\s*=\s*([\"\'])(.*?)\1\s*-->}{handleTemplateIf($2, $1, \%params, $using_template_expr )}esg;
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Ee][Nn][Dd][Ii][Ff][Cc][Ll][Aa][Uu][Ss][Ee]\s*-->}{<TMPL_ELSE>}sg;

    while ( $$dwt =~ m{(<!-- TemplateBeginMultipleIf -->(?:(?!<!-- Template(?:Begin|End)MultipleIf -->).)*<!-- TemplateEndMultipleIf -->)}s ) {
	$$dwt =~ s{<!-- TemplateBeginMultipleIf -->(((?!<!-- Template(?:Begin|End)MultipleIf -->).)*)<!-- TemplateEndMultipleIf -->}{addEndifs($1)}se;
    }

    while ( $$dwt =~ m{<TMPL_BEGIN_(?:IF|UNLESS)((?!</?TMPL_(?:BEGIN_IF|BEGIN_UNLESS|END_IF_UNLESS)).)*</TMPL_END_IF_UNLESS}s ) {
	$$dwt =~ s{<TMPL_BEGIN_(IF|UNLESS)(((?!</?TMPL_(?:BEGIN_IF|BEGIN_UNLESS|END_IF_UNLESS)).)*)</TMPL_END_IF_UNLESS>}
	{"<TMPL_$1$2" . ( $1 eq "IF" ? "</TMPL_IF>" : "</TMPL_UNLESS>")}seg;
    }


    $$dwt =~ s{<TMPL_(\w*) NAME=([\"\'])_isFirst\2}{<TMPL_$1 NAME=$2__FIRST__$2}sg;
    $$dwt =~ s{<TMPL_(\w*) NAME=([\"\'])_isLast\2}{<TMPL_$1 NAME=$2__LAST__$2}sg;
    $$dwt =~ s{<TMPL_(\w*) NAME=([\"\'])_index\2}{<TMPL_$1 NAME=$2__COUNTER__$2}sg;
    $$dwt =~ s{<\!\-\- TMPL_(\w*) NAME=([\"\'])_isFirst\2}{<!-- TMPL_$1 NAME=$2__FIRST__$2}sg;
    $$dwt =~ s{<\!\-\- TMPL_(\w*) NAME=([\"\'])_isLast\2}{<!-- TMPL_$1 NAME=$2__LAST__$2}sg;
    $$dwt =~ s{<\!\-\- TMPL_(\w*) NAME=([\"\'])_index\2}{<!-- TMPL_$1 NAME=$2__COUNTER__$2}sg;

    # TemplateBeginRepeat Name=
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Bb][Ee][Gg][Ii][Nn][Rr][Ee][Pp][Ee][Aa][Tt]\s+[Nn][Aa][Mm][Ee]=([\"\'])(.*?)\1\s*-->}{<TMPL_LOOP NAME=$1$2$1>}sg;
    # TemplateEndRepeat Name=
    $$dwt =~ s{<!--\s*[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee][Ee][Nn][Dd][Rr][Ee][Pp][Ee][Aa][Tt]\s*-->}{</TMPL_LOOP>}sg;
}

sub DWT2HTMLExpr {
    DWT2HTML( shift, 1 );
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

HTML::Template::Filter::Dreamweaver - a module that provides a filter function to translate
 Dreamweaver MX Template pages (.dwt) to HTML::Template pages

=head1 SYNOPSIS

 use HTML::Template::Filter::Dreamweaver qw( DWT2HTML );
 use HTML::Template;

 my $template = new HTML::Template( filename => "foo.dwt",
                                    filter => \&DWT2HTML,
                                  );
 print $template->output;

=head1 DESCRIPTION
 This module will translate Dreamweaver MX templates into a form understood HTML::Template

 This used to be the old documentation...
 For the most part this module should work exactly how you expect it should.  There are a few
 features in this module that Dreamweaver designers should know about.

 As you might expect, I got a few requests for something more descriptive.  Here is a second try.
 
 Dreamweaver MX has updated their templating code fairly heavily, and 
 now it supports many of the things that HTML::Template does.
 
 For example, you can define template variables, repeating sections, use 
 conditional logic, etc.  I'll try to give a quick summation here, but 
 in all honesty, you would do better by browsing Macromedia's website, 
 downloading the trial version. or buying a book on it.
 
 Dreamweaver allows you to set up a template file (it ends in an 
 extension called .dwt).  You can then use this template to create HTML 
 files where you change the pre-defined parameters of the template.
 
 Some examples:
 Dreamweaver MX prefers that all variables in the template be named at 
 the top of the .dwt HTML.  This is done by using the <!-- TemplateParam 
 --> tag.  You can define a default for the parameters and you also 
 define the type of variable (e.g. boolean, text, number, etc.)
 
 In the HTML of the template, you can then use your variables in syntax 
 like <!-- TemplateExpr expr="foo" --> or @@(foo)@@.  This is analagous 
 to the <TMPL_VAR> syntax of HTML::Template
 
 Another Dreamweaver tag is the <!-- TemplateBeginIf --> and <!-- 
 TemplateEndIf --> tags.  These are similar to the <TMPL_IF> and 
 </TMPL_IF> tags.
 
 Also, there are <!-- TemplateBeginRepeat --> and <!-- TemplateEndRepeat 
 --> tags.  As you can guess, these are similar to the <TMPL_LOOP> and 
 </TMPL_LOOP> tags.
 
 There's also a few more tags, but as you can see Dreamweaver MX 
 supports syntax very similar to HTML::Template.
 
 Finally, for seeing what the page would look like when you populate the 
 variables, Dreamweaver allows you to create an HTML page using the 
 template as a starting point.  Under the "Modify" menu, there is a 
 choice that says "Template Properties".  In there, you can set 
 variables to whatever you like.  This is very similar to the param 
 function of HTML::Template.
 
 Personally, I think Dreamweaver MX is so close to HTML::Template that 
 it's possible for an HTML designer to use it and create great mockups 
 of pages.  After developing the mockup, he can give the template to an 
 HTML::Template user who can then combine it with his code to 
 dynamically fill in the template variables.
 
 So, the package that I provided should create be an excellent transform 
 function for converting Dreamweaver template files into HTML::Template 
 files.

=over 4

=item *
 Escaping.  HTML::Template allows variables to be HTML escaped or URL escaped.  I do not know
 how to specify this in Dreamweaver, so I invented a syntax.  

 In the <!-- TemplateParam --> section, you can specify an escaping scheme that you would like
 to use.  For example, <!-- TemplateParam name="foo" type="text" value="yes & no" escape="HTML" -->
 would mean that the "foo" variable would be HTML escaped whenever it is used.

 If you wish to override the escaping scheme provided by the <!-- TemplateParam --> section,
 you can do this in the <!-- TemplateExpr --> section.  For example, to get URL escaping, do
 the following:  <!-- TemplateExpr expr="foo" escape="HTML" -->

 An alternative syntax would be the following @@(_document._Get( "foo", "HTML" ))@@


=item *
 The filter should be able to translate Dreamweaver templates into something that could be
 understood by HTML::Template::Expr.  However, it will only attempt to do this if the filter
 is being used from within HTML::Template::Expr.  It does this by looking at the caller stack.
 If for some reason this is not working correctly, you can force the filter to convert into
 HTML::Template::Expr syntax by using the function DWT2HTMLExpr


=item *
 While we are on the Expr subject...  I believe it will work in most cases.  Just remember that
 this is a fairly dumb filter.  It will translate things like '==' to ' eq ' for text strings,
 but that is about it.  In other words, there are some warnings about how expressions should
 be written within the HTML::Template::Expr documentation.  Heed those warnings, because this
 filter will not fix the problems for you.


=item *
 Dreamweaver supports ternary logic (i.e, foo > 5 ? "yes" : "no" ), but HTML::Template::Expr
 does not.  I put in a very basic test to try to convert these into IF-ELSE clauses.


=item *
 HTML::Template allows you to not put quotes around variables and words.  For example, you could
 say <TMPL_VAR NAME=foo ESCAPE=HTML>.  DWT2HTML is not so nice.  It expects quotes (either single
 or double) around those things.  I believe that Dreamweaver also requires the same, so this 
 should not be an issue unless you are hand editing code.

=back

=head1 AUTHOR

 Brian Paulsen (<lt>brian@thepaulsens.com<gt>) 

=head1 SEE ALSO

 HTML::Tempate and HTML::Tempate::Expr

L<perl>.

=cut
