package Markdown::Foswiki;
use strict;
use warnings;
our $VERSION = '0.04';

use 5.010;

sub new {
    my $self = {};
    bless $self;    
    $self->initialize();
    return $self;
}

### 
# Configure SET
# $converter->setConfig ( 'Attr' => 'Value' );
# $converter->setConfig ( 'IncLang' => 'none' );
#
# 
#
sub setConfig {
    my $self = shift;

    $#_ % 2 or die("A pair of arguments is not correct");
    
    my %args = @_;

    exists $self->{config}->{$_} ? $self->{config}->{$_} = $args{$_} :
	die ("\"$_\" is not attribute") for keys %args;

#    say "$_ -> $self->{config}->{$_}" for keys $self->{config};
    
}

###
# Load Data
# $converter->getData( $filename );
sub getData {
    my ($self,$filename) = @_;
    my @lines;

    open my $fh, "<", $filename or die "open error:$!";
    push @lines, $_ for <$fh>;
    close $fh;

    return @lines;
}


###
# config , rules initializing
sub initialize {
    my $self = shift;

    #Defulat Config
    my $head_text = '%META:TOPICINFO{author="Markdown::Foswiki" date="'.time().'" format="1.1" version="1"}%';
    
    my $head_contents = "%TOC%\n";

    my $footer_text = '';

    my $foot_contents = '';
    
    my %config;
    $config{header_text}     =  $head_text;
    $config{head_contents}   =  $head_contents;
    $config{footer_text}     =  $footer_text;
    $config{foot_contents}   =  $foot_contents;
    $config{InterLinkBase}   =  '';
    $config{IncLang}         =  'plain'; # default : plain ,options: none , c ,c++,...

    $self->{config} = {%config};
    #Config End


    my %rules ;
    $rules{Definition}             = qr /^(.*?)<br \/>(.*?)$/;
    # Definition List  Word<br />Word ->   $ Word:Word || Word<br />Word
    $rules{TableStart} 		   = qr /^<table>$/;
    # table tag open -> new line
    $rules{TRO} 		   = qr /^<tr>$/;
    # tr tag open -> new line
    $rules{TRC} 		   = qr /^<\/tr>$/; 
    # tr tag close -> ignore
    $rules{TDO} 		   = qr /^<t(d|h)>(.*?)<\/t(d|h)>$/;
    # td or td tag <td>Word<td> -> | Word | // <th>Word</th> -> | *Word* |
    $rules{TableEnd} 		   = qr /^<\/table>$/;
    # Table close -> new line
    $rules{Row} 		   = qr /^----$/;
    # Row ---- -> ---
    $rules{Heading} 		   = qr /^(#+?)\s(.*?)#*$/;
    # Heading #.. Word -> ---+.. Word
    $rules{Bold} 		   = qr /^\*(\*.*?\*)\*$/; 
    # Bold **Word** -> *Word*
    $rules{SaveLinkList}	   = qr /^\s\s\[(\d+)\]:\s(.*?)(\s|$)/;
    # MD link list -> make array
    $rules{ShellDetecting} 	   = qr /^\$\s(.*)$/;
    # shell Start : $ Words -> <verbatim> $ Words </verbatim>
    $rules{CodeDetecting} 	   = qr /(;|\}$|\{$)/; 
    # CODE detecting  -> %CODE{ lang="sql" }%\n codes %ENDCODE% || <verbatim> codes </verbatim> 
    $rules{ContentsTable} 	   = qr /^\*\*(.*?)\*\*(.+\[.*\]\[\d+\]){2,2}/; 
    # ContentsTable :Structure to begin with a Bold Word and link enumulation 
    $rules{MimeTableNewLine} 	   = qr /^\---([\+\-]*\+[\+\-]*)\---$/;
    # -------+------- -> ''
    $rules{MimeTableCap} 	   = qr /^(\s*.+?\s+\|\s+.+?\s*)$/; 
    # Word | Word -> | Word | Word |
    $rules{List} 		   = qr /^(\s*)\*(.*)$/; 
    # List ^   * Word level1 | ^      * Word level2...
    $rules{FunctionDetecting} 	   = qr /^[a-zA-Z\_][\w\_]*?\s?\(.*?\).*(\.)/; 
    # function
    $rules{indent}                 = qr /^\t+(.*?)$/;
    # begin \t word

    $self->{rules} = {%rules};
}


sub process {
    my $self = shift;
    my @data = @_;

    my ($result, @link_list, @lines, $LP); 
    $LP = 0;
    #result 
    #link_list
    #lines
    #LP : LinePointer


    for ( @data ) {


	# remove newline character
	# adding newline character to end line when completes to line convert 
	chomp(); 

	# filtering invalid character
	$_ = word_replace($_); 
	
	my $converted;
	
	given ( $_ ) {
	    when ( /$self->{rules}->{Definition}/ ) { 
		if ( length($1) < 25 ) {
		    $converted = "   \$ $1: $2\n";
		} else {
		    $converted = "$_\n";
		} 
	    }

	    when ( /$self->{rules}->{TableStart}/ ) {  
		$converted = "<!--TABLE-->";
	    }
	    when ( /$self->{rules}->{TRO}/ ) {  
		$converted = "\n";
	    }
	    when ( /$self->{rules}->{TRC}/ ) {  		
	    }
	    when ( /$self->{rules}->{TDO}/ ) {  
		my $th_or_td = $1;
		my $matched = $2;
		if ( $lines[$LP-1] =~ /\|$/ ) {
		    $converted = ($th_or_td eq 'd')? " $matched |" : " *$matched* |";
		}else
		{
		    $converted = ($th_or_td eq 'd')? "| $matched |":"| *$matched* |";
		}
	    }
	    when ( /$self->{rules}->{TableEnd}/ ) {  
		$converted = "\n";
	    }
	    when ( /$self->{rules}->{Row}/ ) {  
		$converted = "---\n";
	    }
	    when ( /$self->{rules}->{Heading}/ ) {  
		$converted = sprintf("---".("+"x length($1))." $2\n");
	    }
	    when ( /$self->{rules}->{Bold}/ ) {  
		$converted = $1."\n";
	    }
	    when ( /$self->{rules}->{SaveLinkList}/ ) {  
		$link_list[$1] = $2;
	    }
	    when ( /$self->{rules}->{ShellDetecting}/ ) {  
		$converted = "\n\n<verbatim>\n\$ $1\n</verbatim>\n"; 
	    }
	    when ( /$self->{rules}->{CodeDetecting}/ ) {
		continue if $self->{config}->{IncLang} eq 'none';

		$converted = $_."\n";
		    
		for (my $SLP = $LP ; $SLP > -1 ; $SLP--) {
		    if ( defined($lines[$SLP]) and ( $lines[$SLP] eq "\n"  or $lines[$SLP] =~ /<\/verbatim>|\%ENDCODE\%/ ) ) {
			$lines [$SLP] .= $self->{config}->{IncLang} eq 'plain' ?  
			    "\n<verbatim>\n":
			    "\n\%CODE{ lang=".'"'.$self->{config}->{IncLang}.'"'." }\%\n";
			$converted = $self->{config}->{IncLang} eq 'plain' ?
			    $_."\n</verbatim>\n" :
			    $_."\n\%ENDCODE\%\n";
			last;
		    }
		}
	    }
	    when ( /$self->{rules}->{ContentsTable}/ ) {  
		my $numbers = '[\d]';    
		    my @listers = /((?:.*?\*\*.*?\*\*)|(?:.*?\[.*?\]\[$numbers+\]))/g;

		for ( @listers ) {
		    my $listDepth = 0;
              
		    if ( /^((?:$numbers+(?:\.)(?:$numbers+(?:\.| ))*)|(?:$numbers+\s))/ ) {
			$listDepth++ for split /$numbers+/,$1;
		    }

		    $listDepth -= $listDepth > 0? 1:0;

		    if ( /^$numbers/ ) {
			$converted .= ("   "x$listDepth)."* $_\n";    
		    }else {
			$converted .= "$_\n\n";
		    }
		}
	    }
	    when ( /$self->{rules}->{MimeTableNewLine}/ ) {  

	    }
	    when ( /$self->{rules}->{MimeTableCap}/ ) {  
		$converted = "|    $1     |\n"; # Matched -> | Matched |		
	    }
	    when ( /$self->{rules}->{List}/ ) {  
		$converted = "   $1*$2\n";
	    }
	    when ( /$self->{rules}->{FunctionDetecting}/ ) {  
		$converted = "\n<verbatim>\n$_\n</verbatim>\n";
	    }
	    when ( /$self->{rules}->{indent}/ ){
		$converted = "\n<verbatim>\n$1\n</verbatim>\n";
	    }
	    default {
		$converted = $_."\n\n";
	    }
	}

	#Link Method Change [word][linkNumberKey] -> [[linkNumberKey][word]]
	$converted =~ s/\[(.*?)\]\[(\d+)\]/[[$2][$1]]/g if defined ($converted);

	# insert converted line
	$lines[$LP] = defined($converted)? $converted:"";

	# Increase line pointer 
	$LP++;
    }

    # restructure link
    for ( @link_list ) {
	if ( defined($_) and /^(http\:\/\/){0}(?<filename>[^\/].+?)(\.([a-z]+)(|\#.*))$/ ) {
	    $_ = $self->{config}{InterLinkBase}.$+{filename};
	}
    }

    # apply link and remove empty link 
    for ( @lines ) {
	s/\[\[(\d+)\]\[(.*?)\]\]/[[$link_list[$1]][$2]]/g;
	s/\[\[\]\[(.*?)\]\]/$1/g;
    }
    $result .= defined($_)? $_:"" for @lines;


    # merge split code block  
    $result =~ s/(\<\/verbatim\>\s*\<verbatim\>)|(\%ENDCODE\%\s*\%CODE\{.*?\}\%)//gs;

    $result = $self->{config}->{head_contents}.$result;    
    $result = $self->{config}->{header_text}.$result;
    $result = $result.$self->{config}->{foot_contents};
    $result = $result.$self->{config}->{footer_text};
    return $result;
}

sub word_replace { 
# replace to invaild characters ex) &amp; > &
    my $text = shift;
    my %words_ref = (  "\&amp;" => "&" , # &amp; -> &
		       "\\\\" => "", # \ -> space
		       "<>" => "",
		       "\&gt;" => ">",
		       "\&lt;" => "<",
	);
    
    for ( keys %words_ref ) {
	$text =~ s/$_/$words_ref{$_}/g;
    }
    return $text;
} 

sub save {
    shift;
    my ($text,$dir,$newfile) = @_;

    $newfile =~ s/([a-z])/uc($1);/e;
    $dir = $dir || '.';

    open my $fh , ">", "$dir/$newfile" or die "can't save to file: $!";
    print $fh $text or die "can't writes text: $!" ;
    close $fh;
    
    return 1;
}

1;
__END__

=pod

=head1 NAME

Markdown::Foswiki - Convert Markdown to Foswiki(Twiki) α 

=head1 VERSION

version 0.04

=head1 SYNOPSIS
    
    use Markdown::Foswiki;
    my $mc = Markdown::Foswiki->new();
    my @md_lines = $mc->getData('index.md');
    my $fw_text = $mc->process(@md_lines);;
    print $fw_text;


    use Markdown::Foswiki;
    my $mc = Markdown::Foswiki->new();
    print $mc->process($mc->getData('index.md'));


    $mc->save ( $fw_text, '', 'index.txt');

=head1 DESCRIPTION

This module markdown format files foswiki (Twiki) to convert the format of the module.

markdown in the case of internal links basepath (directory) specified in the config,
and remove all the extensions are removed and replaced with basepath.

If the external link is retained.

=head2 CODE detecting 

This Feature wrapping to %CODE% Mark or verbatim tag if detect code context
 
you can switching Whether to use from config-IncLang Attribute 



set 'none' if want to maintaining code context 

set 'plain' if want to wrapping to verbatim tag 

be Styling with in SyntaxHighlighter if setting other options,

must installed SyntaxHighLighter plugin at your foswiki or twiki

    
=head1 METHODS

=head2 new

create Markdown::Foswiki instance

=head2 getData( $MarkdownFile )

    @ML = $mc->getData( $file );

Returns loaded markdown text lines from $file

=head2 process( @MarkdownLines )

    $FwText = $mc->process( @ML );

=head2 setConfig( 'Arg1' => Value ,...)

=over

=item * header_text

default :

    %META:TOPICINFO{author="Markdown::Foswiki" date="unixTimeStamp" format="1.1" version="1"}%

or your header

=item * head_contents

default :

    "%TOC%\n";

or your head contents

=item * footer_text

default :

    blink

or your footer

=item * foot_contents

default :

    blink

or your foot contents

=item * InterLinkBase

default :

    blink

=item * IncLang

for code detectings

default :

    plain

options 
    none
    plain
    c
    c++
    sql
    perl
    ...


L<http://alexgorbatchev.com/SyntaxHighlighter/manual/brushes/>

=back

=head2 save( $fwText, savedir, savefile) 

    $mc->save($FwText, '', 'newfile.txt');

=head1 SUPPORT

L<HTML::Wikiconverter::Markdown>

=head1 SEE ALSO

=head1 SOURCE REPOSITORY

L<https://github.com/skyend/Markdown--Foswiki>

=head1 AUTHOR

J.W. Han (skyend) E<lt>skyend@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) J.W. Han, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
