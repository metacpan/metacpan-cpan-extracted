#!/usr/bin/perl
# Copyright © 2007-2010 Stuart Butler (perldev@yahoo.co.uk) and Grant Holman (grant@collegeroad.eclipse.co.uk).
# This program is distributed under the terms of the The GNU General Public License (GPL), which can be viewed at http://www.opensource.org/licenses/gpl-license.php
#
package HTML::XHTML::DVSM;
use Carp;
BEGIN {
    $VERSION = '1.2';
}
use vars qw( $VERSION );
use strict;
my $ELEMENT = 1;
my $PROC_INSTR = 2;
my $COMMENT = 3;
my $DOCUMENT_ROOT = 0;

sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class );
    $self->sbInit();
    $self->{MarkupCache} = {};
    $self->{SubsCache} = {};
    $self->{StopOnError} = 0;
    $self->{EvalPackage} = "main";
    $self->{Stream} = *STDOUT if ( ! $self->{Stream} );
    return $self;
}

sub sbGetLastError() {
    my $self = shift;
    my $lasterror = $self->{LastError};
    return $lasterror; 
}

sub sbSetStopOnError {
    my $self = shift;
    my $sbStopOnError = shift;
    $self->{StopOnError} = $sbStopOnError;
}
sub sbIsStopOnError {
    my $self = shift;
    return $self->{StopOnError};
}

sub sbSetEvalPackage {
    my $self = shift;
    my $pkg = shift;
    $pkg = "main" if ( ! $pkg );
    $self->{EvalPackage} = $pkg;
    return $pkg;
}
sub sbManageError {
    my $self = shift;
    my $error = shift;
    return if ( ! $error );
    warn( $error );
    $self->{LastError} = $error;
    die( $error ) if ( $self->{StopOnError} );
}

sub sbHash2String {
    my $self = shift;
    my $hash = shift;
    return "" if ( ! $hash );
    my $res = "";
    foreach my $k ( keys %$hash ) {
        $res .= "$k => $$hash{$k}, ";
    }
    return $res;
}

sub sbPrintHash {
    my $self = shift;
    my $pre = shift;
    my $post = shift;
    my $hash = shift;
    print STDERR $pre;
    print STDERR $self->sbHash2String($hash);    
    print STDERR $post;
}

sub sbGetContents {
    my $self = shift;
    my $htmldir = shift;
    my $file_name = shift;
    my $instr_file = shift;
    my $contents = shift;
    my $instructions = shift;
    my $subs = shift;
    
    open( FIL, "< $htmldir/$file_name" ) || open( FIL, "< $file_name" ) || die( "Can't open file $file_name: $!" );
    {
        local $/;
        $$contents = <FIL>;
    }
    close( FIL );
    if ( $instr_file ) {
        local $/; #read all file in one go, slurp mode.
        open( FIL, "< $instr_file" ) || return "Can't find instruction  file $instr_file";
        $$contents .= <FIL>; # load all instructions into a string
        close( FIL ); 
    }
    return $self->sbAnalyseContents( $htmldir, $contents, $instructions, $subs )
}

sub sbAnalyseContents {
    my $self = shift;
    my $htmldir = shift;
    my $contents = shift;
    my $instructions = shift;
    my $subs = shift;
    
    my $SCRIPT_TAG = ($self->{SCRIPT_TAG} || "DVSM" );
    my $SUBS_TAG = ($self->{SUBS_TAG} || "DSUBS");
    while ( $$contents =~ m#(<(\?|!--)${SCRIPT_TAG}_include\s+(.*?)\s*(--|\?)>)#gsi ) {
        my $label = $1;
        my $snippet = $3;       
        my $snippet_txt = "";       
        open( FIL, "< $htmldir/$snippet" ) || open( FIL, "< $snippet" ) || die( "Can't find snippet $snippet: $!" );
        {
            local $/;
            $snippet_txt = <FIL>
        }
        close( FIL );
        $$contents =~ s#$label#$snippet_txt#gsie;
    }

    while ( $$contents =~ s|<\?${SCRIPT_TAG}(.*?)\?>\n*||si ) {
        $$instructions .= $1;
    } 
    while ( $$contents =~ s|<!--${SCRIPT_TAG}(.*?)-->\n*||si ) {
        $$instructions .= $1;
    } 
    while ( $$contents =~ s|<\?${SUBS_TAG}(.*?)\?>\n*||si ) {
        $$subs .= $1;
    }
    while ( $$contents =~ s|<!--${SUBS_TAG}(.*?)-->\n*||si ) {
        $$subs .= $1;
    }
    $$subs .= "\nreturn 1;\n";
    if ( $self->{DEBUG} && open( D, "> /tmp/dvsmsubs$$.pl") ) {
        print D $$subs;
        close( D );
    }
    return 1;
}

sub sbParseInstructions {
    my $self = shift;
    my $instructionsStr = shift; # reference to a string
    my $instructions = shift; # reference to an array of instructions
    my @lines = split( /\n/, $$instructionsStr );
    for ( my $i = 0; $i < @lines; $i++ ) {        
        my $line = $lines[$i];
        if ( $line =~ m|^\s*set\s+(\S+)\s+to\s+"([^"]+)"\s+where\s+(\S+)\s*=\s*"([^"]+)"|i ) {
            #set textnode to getTitle('Login') where tagname = title
            my %instr = ();
            $instr{cmd} = "set";
            $instr{target} = $1;
            $instr{exec} = $2;
            $instr{where} = $3;
            $instr{value} = $4;
            if ( $line =~ m|\bif\s+"([^"]+)"|i ) {
                $instr{condition} = $1;               
            }
            push( @$instructions, \%instr ); #add instruction structure to the array of instructions
        }
        elsif ( $line =~ m|^\s*toggle\s+(\S+)\s+to\s+"([^"]+)"\s+where\s+(\S+)\s*=\s*"([^"]+)"|i ) {
            #toggle checked to "canAddProject()" where name = "canaddproj"
            my %instr = ();
            $instr{cmd} = "toggle";
            $instr{target} = $1;
            $instr{exec} = $2;
            $instr{where} = $3;
            $instr{value} = $4;
            push( @$instructions, \%instr ); #add instruction structure to the array of instructions
        }
        elsif ( $line =~ m|^\s*load\s+module\s+"([^"]+)"|i ) {
            #load module "routines.pl" 
            if ( $1 ) {
                my %instr = ();
                $instr{cmd} = "load";
                $instr{exec} = $1;
                push( @$instructions, \%instr ); #add instruction structure to the array of instructions
            }
        }
        elsif ( $line =~ m|^\s*run\s+"([^"]+)"|i ) {
            #run "rSecurity()"
            if ( $1 ) {
                my %instr = ();
                $instr{cmd} = "run";
                $instr{exec} = $1;
                if ( $line =~ m|\s+where\s+(\S+)\s*=\s*"([^"]+)"|i ) {
                    $instr{where} = $1;
                    $instr{value} = $2;
                }
                push( @$instructions, \%instr ); #add instruction structure to the array of instructions
            }
        }
        elsif ( $line =~ m|^\s*(while\|if)\s+"([^"]+)"\s+where\s+(\S+)\s*=\s*"([^"]+)"|i ) {
            #while "nextRole()" where name = "template"
            #end while
            my $cmd = lc( $1 );            
            my %instr = ();
            $instr{cmd} = $cmd;
            $instr{exec} = $2;
            $instr{where} = $3;
            $instr{value} = $4;
            my $subinstr = "";
            my @subinstr = ();
            my $pop = 1;
            WHILELOOP:
            for ( ++$i; $i < @lines; $i++ ) {
                $pop++ if ( $lines[$i] =~ m#^\s*(while|if)\b#i );
                if ( $lines[$i] =~ m#^\s*end\b#i ){
                    $pop--;
                    die( $instr{cmd}." START/END stack not even\n" ) if ( $pop < 0 );
                    if ( $pop <= 0 ) {
                        last WHILELOOP;
                    }
                }
                $subinstr .= $lines[$i]."\n";
            }            
            $self->sbParseInstructions( \$subinstr, \@subinstr ); # get child instructions for this while or if loop
            #{
                my @mychildren = @subinstr;
                my %myinstr = %instr;
                $myinstr{children} = \@mychildren; # add child instructions to the instruction's children attribute.
                push( @$instructions, \%myinstr ); #add instruction structure to the array of instructions
            #}
            #if ( $lines[$i] =~ m#^\s*else\b#i ) {
            #    $pop = 1;
            #    $subinstr = "";
            #    @subinstr = ();
            #    my $ifinstr = $$instructions[@$instructions - 1];
            #    $instr{cmd} = "else";
            #    $instr{exec} = "";
            #    $instr{if} = $ifinstr;
            #    #$instr{where} is same
            #    #$instr{value} is same
            #    delete( $instr{children} );
            #    goto WHILELOOP;   
            #}
        }
        elsif ( $line =~ m|^\s*delete\s+where\s+(\S+)\s*=\s*"([^"]+)"|i ) {
            #delete where name = "deleteme"
            my %instr = ();
            $instr{cmd} = "delete";
            $instr{where} = $1;
            $instr{value} = $2;
            push( @$instructions, \%instr ); #add instruction structure to the array of instructions
        }
        elsif ( $line =~ m|^\s*$| ) {
            next; # empty line
        }
        elsif ( $line =~ m|^\s*#| ) {
            next; # comment
        }
        else {
            $self->sbManageError( "ERROR: Invalid command: $line" );
        }
    }
    return "";
}


sub sbTrim {
    my $class = shift;
    my $str = shift;    
    $str =~ s/^\s+//s;    
    $str =~ s/\s+$//s;
    return $str;
}

sub sbTrimStr {
    my $class = shift;
    my $str = shift;
    my $trm = shift;    
    $str =~ s#^$trm##s;
    $str =~ s#$trm$##s;
    return $str;
}

#sbOnEndTag - Called to process an </endtag>
sub sbOnEndTag {
    my $self = shift;
    my $endtag = shift; # reference to a string containing tag name if to be terminated by </tag>
    my $orphantext = shift; #text not within tags - e.g. <a href=x>A</a> | <a href=y>B</a> - the | is orphaned
    my $currenttag = 0;
    my $sbTagparents = $self->{Tagparents};
    my $sbInstrstack = $self->{Instrstack};
    while( @{$sbTagparents} ) { # loop tags that are still open, e.g if we are now a tr typically might have <table><body><html> still open
        $currenttag = pop( @$sbTagparents ); # get the most recent tag on the list of open tags.
        if ( ! $currenttag ) { # there should be one, else we don't have an opening <tag>
            warn( "Found no tag for endtag=$$endtag" );
            last;
        }
        my $instructionarr = $$currenttag{instructions}; #Get the instructions for this current tag
        foreach my $instr ( @$instructionarr ) { # loop through the tag's instructions
            next if ( ! $$instr{children} ); # If there are no child instructions to this instruction, go get the next instruction
            for( my $i = 1; $i < @$sbInstrstack ; $i++ ) { # Now try to find that array of child instructions in our global instruction stack
                next if ( $$instr{children} != $$sbInstrstack[$i] ); # if this is not it keep on search
                for ( ; $i < @$sbInstrstack; $i++ ) {
                    #printHash( "POP INSTRSTACK FOR $$endtag", "\n", $instr );
                    delete( $$sbInstrstack[$i] ); # we have found the top of the global instruction stack, so we can pop them - don't need them any more
                }
                last; 
            }
        }
        next if ( $$currenttag{tagend} ); # This tag is a self close one <tag/> - tagend is /
        next if ( $$currenttag{tag} !~ m|^$$endtag$|i ); # This current tag is not our endtag, so continue searching
        $$currenttag{orphantext} = $orphantext; # Save any text that comes at the end of the </tag> so we keep exact format
        last; # finished
    }    
}

#sbOnTag - called when the start of a tag is found
sub sbOnTag {
    my $self = shift;
    my $tag = shift; # reference to a string with tagname in it      
    my $type = shift; # reference to the tag type 1 for ELEMENT
    my $tagend = shift; # Reference to the tagend string - "/" or "" if terminated with </tag>         
    my $attribstr = shift; # Reference to a string with the attributes e.g. src="something.pl" border="0"
    my $attribs = shift; # Reference to a hash of the attributes e.g. src => somethinth.pl, border => 0
    my $text = shift; # Reference to textnode text between <tag>text</tag>
    my $orphantext = shift; # reference to orphantext to be output after the tag
    my $pretext = shift; # Reference to orphantext to be output before the tag
    my %tagdata = ( tag => $$tag, # save tag as plain string
                    type => $$type, # save type as plain int string
                    tagend => $$tagend, # save tagend as reference
                    attribs => $attribs, # save attribute hash as reference
                    attribstr => $attribstr, # save attribute string as reference
                    text => $text, # save text as reference
                    orphantext => $orphantext, # save any orphan text if self closing "<p/> stuf"
                    pretext => $pretext, # save any text that came before the tag
                    );
    $tagdata{instructions} = [];  # initialise instructions to a reference to an empty array
    my $sbInstrstack = $self->{Instrstack};
    my $sbTagparents = $self->{Tagparents};
    my $instructions = $$sbInstrstack[$#{$sbInstrstack}] if ( @$sbInstrstack ); # Get the current array of instructions
    if ( ! $instructions ) {
        warn( "NO INSTRUCTIONS for <$$tag $$attribstr>" );
    }
    if ( $$type == $DOCUMENT_ROOT ) { # this is the first
        $self->{Markup} = \%tagdata;
        push( @$sbTagparents, \%tagdata );
        return;
    }
    else {
        my $currenttag = $$sbTagparents[$#{$sbTagparents}];
        my $children = $$currenttag{ children };
        $children = [] if ( ! $children );
        push( @$children, \%tagdata );
        $$currenttag{ children } = $children;
        if ( $$type == $ELEMENT ) {
            if ( $$tagend !~ m|/| ) {
                push( @$sbTagparents, \%tagdata );
            }
            if ( ! $$currenttag{pop_child_instructions} ) {
                my $instructarr = $$currenttag{instructions};
                foreach my $instr ( @$instructarr ) {
                    my $childinstrs = $$instr{children};
                    next if ( ! $childinstrs || ! @$childinstrs );
                    push( @$sbInstrstack,  $childinstrs );
                    #see if there are any instructions that are relevant for the parent tag
                }
                $$currenttag{pop_child_instructions} = 1;
                $instructions = $$sbInstrstack[$#{$sbInstrstack}] if ( @$sbInstrstack );
            }
        }
    }
    return if ( ! $instructions );
    $self->sbAllocateInstr( $instructions, \%tagdata );
}

sub sbAllocateInstr {
    my $self = shift;
    my $instructions = shift;
    my $tagdata = shift;
    my $norecurse = shift;
    my $tag = $$tagdata{tag};
    my $attribs = $$tagdata{attribs};
    foreach my $instr ( @$instructions ) {
        if ( $$instr{where} && $$instr{where} =~ m|^tagname$|i
        &&   $$instr{value} && $$instr{value} =~ m|^$tag$|i ) {
            my $instructionarr = $$tagdata{instructions};           
            push( @$instructionarr, $instr );
            $self->sbAllocateInstr( $$instr{children}, $tagdata, 1 )
                if ( ! $norecurse ); # for while and if can be child instructions that are relevant
        }
        elsif ( $$instr{where} && exists( $$attribs{$$instr{where}} )
        && $$instr{value} =~ m|^$$attribs{$$instr{where}}$|i ) {
            my $instructionarr = $$tagdata{instructions};
            push( @$instructionarr, $instr );
            $self->sbAllocateInstr( $$instr{children}, $tagdata, 1 )
                if ( ! $norecurse ); # for while and if can be child instructions that are relevant
        }
        elsif ( ! $$instr{allocated} && ! $$instr{where} 
        &&    (   $$instr{cmd} eq "load" || $$instr{cmd} eq "run" ) ) {
            my $instructionarr = $$tagdata{instructions}; # for while and if can be child instructions that are relevant
            push( @$instructionarr, $instr );
            $$instr{allocated} = 1;
        }
    }
}

sub sbGetAttribs {
    my $self = shift;
    my $tag = shift;
    my $attribstr = shift;
    my $attribs = shift;
    $$attribstr = $$tag;
    $$attribstr =~ s#^\s*(\S+)##s;
    my $save_attribstr = $$attribstr;
    $$tag = $1;
    while( $$attribstr =~ m#\s*([^=\s]+)#gs ) { #=(["'][^"']*["']|\S+)|\S+)
        my $attrib = $1;
        $$attribstr = substr( $$attribstr, pos( $$attribstr ) );
        my $value = undef;
        if ( $$attribstr =~ m#^\s*=\s*#s ) {
            $$attribstr = $';
            if ( $$attribstr =~ m#^"([^"]*)"#s )  {
                $value = $1;
                $$attribstr = $';
            }
            elsif ( $$attribstr =~ m#^'([^']*)'#s ) {
                $value = $1;
                $$attribstr = $';
            }
            elsif ( $attribstr =~ m#^(\S+)#s ) {
                $value = $1;
                $attribstr = $';
            }
        }       
        $$attribs{$attrib} = $value;
    }
    $$attribstr = $save_attribstr;
    return "";
}

sub sbParseMarkup {
    my $self = shift;
    my $contents = shift;
    my $gotelement = 0;
    $self->{documentroot} = "_document_root_" if ( ! $self->{documentroot} );
    my $root = $self->{documentroot};
    my $root_type = $DOCUMENT_ROOT;
    my $root_attribs = "";
    $self->sbOnTag( \$root, \$root_type, \"", \"", {}, \"" , \"" );
    while ( $$contents =~ m#<#gm ) {     
        $$contents = substr( $$contents, pos( $$contents ) );
        if ( $$contents =~ m#(^!\[CDATA\[.*?\]\])>([^<]*)#s ) { # //<![CDATA] ... ]]> ...
            my $tag = $1;
            my $orphantext = $2;          
            my $type = $COMMENT;
            $$contents = $';
            $self->sbOnTag( \$tag, \$type, \"", \"", {}, \"" , \$orphantext );
        }
        elsif ( $$contents =~ m#(^!--.*?--)>([^<]*)#s ) { # <!-- ... --> ...
            my $tag = $1;
            my $orphantext = $2;          
            my $type = $COMMENT;
            $$contents = $';
            $self->sbOnTag( \$tag, \$type, \"", \"", {}, \"" , \$orphantext );
        }
        elsif ( $$contents =~ m#(^!.*?)>([^<]*)#s ) { # <!DOCTYPE ... > ...
            my $tag = $1;
            my $orphantext = $2;          
            my $type = $COMMENT;
            $$contents = $';
            $self->sbOnTag( \$tag, \$type, \"", \"", {}, \"" , \$orphantext );
        }
        elsif ( $$contents =~ m#(^\?.*?\?)>([^<]*)#s ) { # <? ... ?> ...
            my $tag = $1;
            my $orphantext = $2;          
            my $type = $PROC_INSTR;
            $$contents = $';
            $self->sbOnTag( \$tag, \$type, \"", \"", {}, \"" , \$orphantext );
        }
        elsif ( $$contents =~ m#^\s*\/([^>]+)>([^<]*)#s ) { # </tagname>...
            my $tag = $1;
            my $orphantext = $2;
            $$contents = $';
            $tag = $self->sbTrim( $tag );
            $self->sbOnEndTag( \$tag, \$orphantext );
        }
        elsif ( $$contents =~ m#(^[^>]+)>([^<]*)#s ) { # <tagname attrib1=value1>...
            my $tag = $1;
            my $text = $2;
            $$contents = $';
            $tag = $self->sbTrim( $tag );
            my $notextnode = "";
            $notextnode = "/" if ( $tag =~ s#/$##s );   
            my $type = $ELEMENT;
            my $attribstr = "";
            my %attribs = ();
            $self->sbGetAttribs( \$tag, \$attribstr, \%attribs );     
            $self->sbOnTag( \$tag, \$type, \$notextnode, \$attribstr, \%attribs, \$text, \"" );
        }
        else {
            warn( "sbParseMarkup - no tag regexp worked: $$contents" );
        }
    }
}

sub sbPrintTag {
    my $self = shift;
    my $indent = shift;
    my $tag = shift;
    my $stream = $self->{Stream};
    my $text = $$tag{text};
    my $orphantext = $$tag{orphantext}; # often white space which helps keep format, but can be text between text e.g. <a>A</a> | <a>B</b> - the " | " is orphan
    if ( ! $text ) {
        my $txt = "";
        $text = \$txt;
        $$tag{text} = $text;
    }
    my $attribs = $$tag{attribs};
    print $stream "<$$tag{tag}";
    foreach my $attrib ( keys %$attribs ) {
        next if ( ! defined( $attrib ));
        $$attribs{$attrib} = "" if ( ! defined( $$attribs{$attrib} ) );
        print $stream " $attrib=\"$$attribs{$attrib}\"";
    }
    print $stream "$$tag{tagend}>$$text";
    $self->sbMergeDocument( $indent + 1, $$tag{children});
    print $stream "</$$tag{tag}>" if ( $$tag{type} == $ELEMENT && ! $$tag{tagend} );
    print $stream $$orphantext if ( $orphantext );
}

sub sbGetCurrentTagValue {
    my $self = shift;
    my $attrib = shift;    
    my $sbCurrentTag = $self->{CurrentTag};
    return "" if ( ! $sbCurrentTag || ! $attrib );
    return $$sbCurrentTag{tag} if ( $attrib eq "tagname" );
    return $$sbCurrentTag{text} if ( $attrib eq "textnode" );
    my $attribs  = $$sbCurrentTag{attribs};
    return "" if ( ! $attribs );
    return  $$attribs{$attrib};
}

sub sbDebugCurrentTag {
    my $self = shift;
    my $attrib = shift;    
    my $sbCurrentTag = $self->{CurrentTag};
    my $res="<$$sbCurrentTag{tag} ${$$sbCurrentTag{attribstr}}>";
    return $res;
}

sub sbCopyTag {
    my $self = shift;
    my $origtag = shift;
    my %copytag = %{$origtag};
    my $tag = \%copytag;
    my $text = $$tag{text};
    $text = \"" if ( ! $text );
    my $copytext = $$text;
    $$tag{text} = \$copytext;
    my $attribs = $$tag{attribs};
    $attribs = {} if ( ! $attribs );
    my %copyattribs = %{$attribs};  
    $$tag{attribs} = \%copyattribs;
    return $tag;
}


#sbMergeDocument - merges data into the markup and prints it
sub sbMergeDocument {
    my $self = shift;
    my $indent = shift;
    my $tags = shift;
    my $error;
    TAGLOOP:
    foreach my $origtag ( @$tags ) {
        my $run = 0;
        my $cmd = "";
        my $exec = "";
        my $inrepeat = 0;
        do { # while inrepeat
            my $tag = $self->sbCopyTag($origtag);
            $self->{CurrentTag} = $tag;
            my $text = $$tag{text};
            if ( ! $text ) {
                my $txt = "";
                $text = \$txt;
                $$tag{text} = $text;
            }
            my $attribstr = $$tag{attribstr};
            $attribstr = \"" if ( ! $attribstr );
            my $attribs = $$tag{attribs};            
            my $instructionarr = $$tag{instructions};
            $run = 0;
            for ( my $count = 0; ;$count++ ) {
                my $instruction = $$instructionarr[$count] if ( $instructionarr && $count < @$instructionarr );
                $run = 1 if ( $count == 0  && ! $instruction );
                last if ( $count > 0 && ! $instruction );
                next if ! ( $instruction );
                $cmd = lc( $$instruction{cmd} );
                $exec = $$instruction{exec};
                if ( $cmd eq "load" ) {
                    require $exec;
                    if ( $@ ) {
                        $error = "ERROR: $exec: $@";
                        $self->sbManageError( $error );
                    }
                    $run = 1;
                }
                elsif ( $cmd eq "run" ) {
                    eval "package ".$self->{EvalPackage}."; ".$exec;
                    if ( $@ ) {
                        $error = "ERROR: $exec: $@";
                        $self->sbManageError( $error );
                    }
                    $run = 1;
                }
                elsif ( $cmd eq "set" ) {
                    my $cond = 1;
                    $cond = eval "package ".$self->{EvalPackage}."; ".$$instruction{condition} if ( $$instruction{condition} );
                    if ( $cond ) {
                        my $res = eval "package ".$self->{EvalPackage}."; ".$$instruction{exec};
                        if ( $@ ) {
                            $error = "ERROR: $exec: $@";
                            $self->sbManageError( $error );
                        }
                        if ( lc($$instruction{target}) eq "textnode" ) {                   
                            $$text = $res;
                        }
                        else {
                            $$attribs{$$instruction{target}} = $res;
                        }
                    }
                    $run = 1;
                }
                elsif( $cmd eq "toggle" ) {
                    my $res = eval "package ".$self->{EvalPackage}."; ".$$instruction{exec};
                    if ( $@ ) {
                        $error = "ERROR: $exec: $@";
                        $self->sbManageError( $error );
                    }
                    if ( $res ) {
                        $$attribs{$$instruction{target}} = "true";
                    }
                    else {
                        delete( $$attribs{$$instruction{target}} );
                    }
                    $run = 1;
                }
                elsif( $cmd eq "delete" ) {
                    next TAGLOOP;
                }
                elsif( $cmd eq "if" ) {
                    $run = eval "package ".$self->{EvalPackage}."; ".$exec;                   
                    if ( $@ ) {
                        $error = "ERROR: $exec: $@";
                        $self->sbManageError( $error );
                    }
                    #$$instruction{lastresult} = $run;                    
                }
                #elsif( $cmd eq "else" ) {                    
                #    my $ifinstr = $$instruction{if};
                #    if ( ! $ifinstr ) {
                #        $error = "ERROR: else has no if instruction";
                #        $self->sbManageError( $error );
                #    }
                #    if ( ! exists( $$ifinstr{lastresult} ) ) {
                #        $error = "ERROR: if related to else does not have lastresult";
                #        $self->sbManageError( $error );
                #    }
                #    $run = 1;
                #    $run = 0 if ( $$ifinstr{lastresult} );                    
                #}
                elsif ( $cmd eq "while" ) {
                    $run = eval "package ".$self->{EvalPackage}."; ".$exec;
                    $inrepeat = $run;
                    if ( $@ ) {
                        $error = "ERROR: $exec: $@";
                        $self->sbManageError( $error );
                    }
                }
                else {
                    $error = "ERROR: Invalid cmd $cmd";
                    $self->sbManageError( $error );
                }
                last if ( ! $run );
            } # for ($count;; )
            $self->sbPrintTag( $indent, $tag ) if ( $run );
        } while( $inrepeat );
    }
}

sub sbPrintDocument {
    my $self = shift;
    my $document = $self->{Markup};
    $self->sbMergeDocument( 0, $$document{children} );
}

sub sbDebugPrintDocument {
    my $self = shift;
    my $indent = shift;
    my $tags = shift;
    my $stream = $self->{Stream};
    foreach my $tag ( @$tags ) {
        my $text = $$tag{text};
        $text = \"" if ( ! $text );
        my $attribstr = $$tag{attribstr};
        $attribstr = \"" if ( ! $attribstr );
        my $orphantext = $$tag{orphantext};
        $orphantext = \"" if ( ! $orphantext );
        my $attribs = $$tag{attribs};
        print $stream "<$$tag{tag}";
        foreach my $attrib ( keys %$attribs ) {
            print $stream " $attrib=\"$$attribs{$attrib}\"";
        }
        print $stream "$$tag{tagend}>$$text";
        my $instructions = $$tag{instructions};
        print $stream "\n", "-" x 80, "\n" if ( @$instructions );
        foreach my $instr ( @$instructions ) {
            print $stream $self->sbHash2String( $instr ), "\n";
        }
        print $stream "-" x 80, "\n" if ( @$instructions );
        $self->sbDebugPrintDocument( $indent + 1, $$tag{children});
        print $stream "</$$tag{tag}>" if ( $$tag{type} == $ELEMENT && ! $$tag{tagend} );
        print $stream "$$orphantext";
    }
}
sub sbDebugPrintInstructions {
    my $self = shift;
    my $indent = shift;
    my $instructions = shift;
    my $stream = $self->{Stream};
    foreach my $instr ( @$instructions ) {
        print $stream " " x $indent, $self->sbHash2String( $instr ), "\n";
        if ( $$instr{cmd} eq "load" ) {
            require $$instr{exec};
        }
        else {
            print $stream " " x $indent, "FUNCTION RETURN=[", eval "package ".$self->{EvalPackage}."; ".$$instr{exec}, "] \n";
            print $stream " " x $indent, "ERROR: $$instr{exec}=$@\n" if $@;
        }
        if ( $$instr{children} ) {
            $self->sbDebugPrintInstructions( $indent + 2, $$instr{children} );
        }
    }
}
sub sbDebugPrint {
    my $self = shift;
    my $stream = $self->{Stream};
    $self->sbDebugPrintInstructions( 0, $self->{Instructions} );
    print $stream "-" x 80, "\n";
    my $document = $self->{Markup};
    $self->sbDebugPrintDocument( 0, $$document{children} );
}
sub sbDebugDumpTags {
    my $self = shift;
    my $indent = shift; # The number of dots to print to indent children under parents.
    my $tags = shift;   # A reference to an array of references to tag data to dump
    my $stream = $self->{Stream};
    foreach my $tag ( @$tags ) {
        my $attribstr_ref = ( $$tag{attribstr} ? $$tag{attribstr} : \"" ); # get the attribute string from the tag data e.g. 'src="something.html" border="1"'
        my $attribstr = $$attribstr_ref;
        if ( $attribstr ) {
            $attribstr = "$attribstr>";
        } else {
            $attribstr = ">";
        }
        print $stream "." x $indent, "<$$tag{tag}$attribstr"; # output the start of the tag and it's attributes
        my $text = $$tag{text}; # get the reference to the text string from the tag data
        my $txt = $$text if $text; # dereference the text into a simple string variable.
        $txt =~ s|\n| |gs; # strip out newlines
        print $stream substr( $txt, 0, 30 ), ( length( $txt ) > 30 ? "..." : "" ) if ( $txt );
            # print a chopped string, max length 30, and with ... if it has been chopped

        my $instructions = $$tag{instructions}; # get the instructions to be applied to this tag
        foreach my $instr ( @$instructions ) { # loop round the instructions
            my $exec = $$instr{exec} || "";
            my $cmd = $$instr{cmd} || "";
            print $stream ":$cmd $exec"; # print the cmd (set,toggle,etc) and exec (function call) values
        }
        print $stream "\n"; # This tag now becomes the current parent.
        $self->sbDebugDumpTags( $indent + 2, $$tag{children} ); # Recursively call sbDebugDumpTags to print the children if any.
        print $stream "." x $indent, "</$$tag{tag}>\n" if ( $$tag{type} == $ELEMENT ); # close the parent.
    }
}
sub sbDebugDump{
    my $self = shift;
    my $document = $self->{Markup};
    $self->sbDebugDumpTags( 0, $$document{children} );
}

sub sbClearCache {
    my $self = shift;
    my $cachename = shift;
    my $sbMarkupCache = $self->{MarkupCache};
    my $sbSubsCache = $self->{SubsCache};
    if ( $cachename ) {
        delete( $$sbMarkupCache{$cachename} );
        delete( $$sbSubsCache{$cachename} );
    }
    else {       
        $self->{MarkupCache} = {};
        $self->{SubsCache} = {};
    }
    return 1;
}

### Initialise page from string input
sub sbInitMarkup {
    my $self = shift;
    my $htmldir = shift;
    my $markup_ref = shift;
    
    my $instructions = "";
    my $subs = "";
    $self->sbAnalyseContents( $htmldir, $markup_ref, \$instructions, \$subs );
    if ( $subs ) {
        eval "package ".$self->{EvalPackage}."; ".$subs;
        if ( $@ ) {
            my $error = "ERROR: in subroutines in markup: $@";
            $self->sbManageError( $error );
        }
    }
    $self->sbParseInstructions( \$instructions, $self->{Instructions} );
    $self->sbParseMarkup( $markup_ref );
    return 1;
}

## Initialise page from file input
sub sbInitPage {
    my $self = shift;
    my $cachename = shift;
    my $htmldir = shift;
    my $page = shift;
    my $instrfile = shift;
    my $sbMarkupCache = $self->{MarkupCache};
    my $sbSubsCache = $self->{SubsCache};
    $cachename = $page if ( ! $cachename );
    my $cachedmarkup = $$sbMarkupCache{$cachename} if ( $cachename );
    my $subs = $$sbSubsCache{$cachename} if ( $cachename );
    $subs = "" if ( ! defined( $subs ));
    
    if ( $cachedmarkup ) {
        #warn( "$$ Getting cached version for $cachename" );
        $self->{Markup} = $cachedmarkup;
        $self->{Subs} = $subs;
        my $sbSubs = $$subs;
        if ( $sbSubs ) {
            eval "package ".$self->{EvalPackage}."; ".$sbSubs; # must always re-eval as other evals redefine common func names
            if ( $@ ) {
                my $error = "ERROR: in subroutines on page $page: $@";
                $self->sbManageError( $error );
            }
        }
    }
    else {
        #warn( "$$ First time for $cachename" );
        my $sbContents;
        my $sbInstructions;
        my $sbSubs;
        $self->sbGetContents( $htmldir, $page, $instrfile, \$sbContents, \$sbInstructions, \$sbSubs );
        if ( $sbSubs ) {
            eval "package ".$self->{EvalPackage}."; ".$sbSubs;
            if ( $@ ) {
                my $error = "ERROR: in subroutines on page $page: $@";
                $self->sbManageError( $error );
            }
        }
        $self->sbParseInstructions( \$sbInstructions, $self->{Instructions} );
        $self->sbParseMarkup( \$sbContents );
        my %copymarkup = %{$self->{Markup}};        
        ${$self->{MarkupCache}}{$cachename} = \%copymarkup;
        my $copySubs = $sbSubs;
        ${$self->{SubsCache}}{$cachename} = \$copySubs;
    }
    return 0;
}


sub sbInit() {
    my $self = shift;
    my @sbInstructions = ();
    my %sbMarkup = ();
    my @sbTagparents = ();
    my @sbInstrstack = (\@sbInstructions);
    $self->{Instructions} = \@sbInstructions;
    $self->{Markup} = \%sbMarkup;
    $self->{Tagparents} = \@sbTagparents;
    $self->{Instrstack} = \@sbInstrstack;
    $self->{LastError} = "";
    $self->{CurrentTag} = 0;
}

sub sbGetPath {
    my $class = shift;
    my $path = shift;
    $path =~ s#\\#/#g;
    if ( $path =~ m#(.+)/([^/]+$)# ) {
        $path = $1;
        my $file = $2;
        return ( $path, $file ) if ( wantarray() );
        return $path;
    }
    else {
        return ( "", $path ) if ( wantarray() );
        return "";
    }
}

sub sbBasename {
    my $class = shift;
    my $pathname = shift;
    my ( $path, $filename ) = sbGetPath( $pathname );
    return $path;
}

sub sbFilename {
    my $class = shift;
    my $pathname = shift;
    my ( $path, $filename ) = sbGetPath( $pathname );
    return $filename;
}

return 1;


__END__

=head1 NAME

HTML::XHTML::DVSM - Dynamic Visual Software Modelling, XML/XHTML template system that does not screw up your templates. V1.2

=head1 SYNOPSIS

=over 4

=item The HTML - getstarted.html 

Illustrates all but one of the the DVSM commands that can be 
embedded into xml or xhtml markup, and the missing one is explained below.   
All markup must be xhtml not html.

    <html>
    <head>
    <title>Getting Started with HTML::XHTML::DVSM</title>
    </head>
    <body>
    <h1>Getting Started with HTML::XHTML::DVSM</h1>
    This html markup illustrated the script commands available in HTML::XHTML::DVSM<br/>
    run printheader has output the header<br/>
    <h2>RUN</h2>
    run dorun will output "doRun called 1 times"<Br/>
    <span id="sid">hello world</span><br/>
    run dorun will output "doRun called 2 times"<br/>
    <span id="sid2">hello world</span>
    <!--DVSM
    run "printHeader"
    run "doRun()" where id = "sid"
    run "doRun()" where id = "sid2"
    -->
    <!--DSUBS
    sub printHeader { print "Content-type: text/html\n\n"; }
    my $count = 0;
    sub doRun {
        ++$count;
        print "doRun called $count times<br/>\n";
    }
    -->
    <h2>SET</h2>
    textnode is set from hello world to hello sid<br/>
    <span id="set">hello world</span><br/>
    value of input is set to "set by set"<br/>
    <input type="text" value="" name="set2">
    <!--DVSM
    set textnode to "sayHello()" where id = "set"
    set value to "return 'set by set';" where name = "set2"
    -->
    <!--DSUBS
    sub sayHello {
        return "hello sid";
    }
    -->
    <h2>TOGGLE</h2>
    Current value set to Option 2 by TOGGLE command<br/>
    <select name="myselect">
    <option value="1" select="myselect">Option 1</option>
    <option value="2" select="myselect">Option 2</option>
    <option value="3" select="myselect">Otpion 3</option>
    </select><br/>
    <!--DVSM
    toggle selected to "doToggle()" where select = "myselect"
    -->
    <!--DSUBS
    my $selected = 2;
    sub doToggle {
        my $sb = getSB();
        my $value = $sb->sbGetCurrentTagValue( "value" );
        return ( $value eq $selected );
    }
    -->
    <h2>DELETE</h2>
    Option 2 and Option 3 removed by DELETE command<br/>
    <select name="myselect">
    <option value="1" select="myselect">Option 1</option>
    <option value="2" select="deleteme">Option 2</option>
    <option value="3" select="deleteme">Otpion 3</option>
    </select>
    <!--DVSM
    delete where select = "deleteme"
    -->
    <h2>WHILE</h2>
    WHILE command is used to populate the table with a data set of customers:
    148842 => "Mr J Smith", 848488 => "Ms S Jones", 484848 => "Mrs P Cook", 982828 => "Joe Bloggs"
    <table>
    <tr><th>Customer Number</th><th>Customer Name</th></tr>
    <tbody>
    <tr name="customers"><td name="custid">12345</td><td name="custname">Mr Bloggs</td></tr>
    <tr name="deleteme"><td>23456</td><td>Mrs Soap</td></tr>
    <tr name="deleteme"><td>67890</td><td>Mr A N Other</td></tr>
    </tbody>
    </table>
    <!--DVSM
    delete where name = "deleteme"
    while "moreCustomers()" where name = "customers"
       set textnode to "getCustid()" where name = "custid"
       set textnode to "getCustname()" where name = "custname"
    end while
    -->
    <!--DSUBS
    my %db = ( 148842 => "Mr J Smith", 848488 => "Ms S Jones", 484848 => "Mrs P Cook", 982828 => "Joe Bloggs" );
    my $cursor = -1;
    sub moreCustomers {
        $cursor++;
        my @keys = keys( %db );
        return ( $cursor < @keys );
    }
    sub getCustid {
        my @keys = sort keys( %db );
        return $keys[$cursor];
    }
    sub getCustname {
        return $db{getCustid()};
    }
    -->
    <h2>IF</h2>
    <p>This paragraph always happens</p>
    <p id="datepara_even">This paragraph only happens if the date of the month
    (<span id="thedate"></span>) is an even number</p>
    <p id="datepara_odd">This version of the paragraph only happens if the date of the month
    (<span id="thedate"></span>) is an odd number</p>
    <!--DVSM
    if "dateiseven()" where id = "datepara_even"
       set textnode to "getdate()" where id = "thedate"
    end if
    if "dateisodd()" where id = "datepara_odd"
       set textnode to "getdate()" where id="thedate"
    end if
    -->
    <!--DSUBS
    sub dateisodd { return ( ! dateiseven() ); }
    sub dateiseven {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
            localtime(time);
        return ( $mday % 2 == 0 );
    }
    sub getdate {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
            localtime(time);
        return sprintf( "%.2d/%.2d/%.4d", $mday, $mon + 1, 1900 + $year );
    }
    -->
    </body>
    </html>

The one DVSM script command not shown here is: C<< <!--DVSM_include file/path.html--> >> 
which allows you to load a snippet of markup into the main document at the point of the
include directive.  The snippet can contain DVSM script and DSUBS perl sections.

=item The perl script - getstarted.pl

Shows how to use HTML::XHTML::DVSM to animate getstarted.html

    #!/usr/bin/perl -w
    package sb_getstarted;
    use HTML::XHTML::DVSM;
    my $scriptdir = "."; #may have to change this for mod_perl
    my $htmldir = "$scriptdir";
    our $sb; #for mod_perl
    sub getSB { return $sb; }
    $sb = HTML::XHTML::DVSM->new( SCRIPT_TAG => "DVSM", SUBS_TAG => "DSUBS" ) if ( ! $sb );
    $sb->sbInit();
    #$sb->sbClearCache(); #can be used if modify html and using mod_perl
    $sb->sbSetEvalPackage( "sb_getstarted" ); #when running code in getstarted.html this is the package name
    $sb->sbSetStopOnError( 1 );
    eval {
        $sb->sbInitPage( "", "$htmldir", "getstarted.html", "" );
        $sb->sbPrintDocument();
    };
    if ( $@ ) {
        print "Content-type: text/plain\n\n";
        print "ERROR: $@";
    }

=item Instructions

Put both getstarted.html and getstarted.pl in the same directory.  
cd to that directory.

Run:

    perl getstarted.pl
    
and view the output. 

Once you have viewed the output try putting both files in your cgi-bin directory.  Then run the demo
by loading the getstarted.pl url in your browser: e.g. http://localhost/cgi-bin/getstarted.pl.
Make sure getstarted.pl has execute permissions and that C<#!/usr/bin/perl> is the correct
path for perl - you may have to change this shell directive to give the correct path.

Notice that getstarted.html is good html that any browser can load.  The html before transformation
is not corrupted by the DVSM instructions, unlike almost all other html template systems.

=back

=head1 CONSTRUCTOR

=over 4

=item new([SCRIPT_TAG => "MyTag"],[SUBS_TAG => "MySubs"],[Stream => *STDOUT ] )

Creates new instance of HTML::XHTML::DVSM.  When specified, the given C<SCRIPT_TAG> sets the script
marker in the markup to: E<lt>!--MyTag --E<gt> and the C<SUBS_TAG> sets the perl subroutines section
marker to E<lt>!--MySubs --E<gt>.  The defaults are DVSM and DSUBS.
C<Stream> holds the file handle to print output to.  It defaults to STDOUT.

=back

=head1 METHODS

=over 4

=item sbInit()

Initialises internal structures.  This should be called for each request for a page.

=item sbClearCache([documentname])

Clears the cache of parsed markup.  When running in mod_perl (ModPerl::Registry),
HTML::XHTML::DVSM caches markup after it has been parsed, so it won't be necessary to parse it again.
If documentname is specified, only that document will be cleared from the cache.
The document name is the same value given to the first parameter of sbInitPage().

=item sbSetEvalPage(packagename)

Sets the package name for subroutines that are run from E<lt>!--DSUBS --E<gt> sections.  Usually this is
the same as the package of the main runner cgi (getstarted.pl in our example).

=item sbSetStopOnError( 1|0 )

If set to true (1) then HTML::XHTML::DVSM will die  if it comes across an error while parsing or running
DVSM script or DSUBS routines.  If set to false (0) HTML::XHTML::DVSM will cache errors and continue parsing
the markup and running DVSM script and DSUBS routines.  The last error can then be obtained using
sbGetLastError().

=item sbInitPage( pagename, htmldir, htmlfile, dvsm_dsubs_file )

Reads in the markup from htmlfile, parses the page, caches it, and then runs the DVSM script and DSUBS perl subroutines to
animate the page.  If the page has already been cached, the parsed markup is retrieved from
the cache.

C<pagename> a name to give the page. Used for cacheing the parsed markup. If "" is given,
then the pagename will be the name of the html file.
C<htmldir> the filesystem directory where the html is stored.
C<htmlfile> the relative path of the file in htmldir.
C<dvsm_dsubs_file> the relative path from htmldir of a file holding DVSM and DSUBS sections. This
is blank "" if the DVSM and DSUBS sections are in the xml/xhtml file.

=item sbPrintDocument()

Prints out the parsed and animated markup.  Animated markup is markup after applying the instructions
in DVSM sections and running the DSUBS sections.  There are various debug forms of output: sbDebugPrint()
and sbDebugDump().  These can be useful to try and catch bugs or problems with a page.

=item sbGetCurrentTagValue(attribute_name)

Returns the value of C<attribute_name> of the current tag being processed.  This is usually used by 
subroutines in DSUBS sections when they need to know the current value of an attribute of the currently
processed tag.  attribute_name can be two special values: 1) 'tagname' when the actual tag name being processed
is returned (so for E<lt>spanE<gt> that would be 'span', and for E<lt>tableE<gt> it would be 'table'); 2) 'textnode'
which returns the text between the opening and closing tag. 

=back

=head1 DVSM SCRIPT COMMANDS

The script is extremely simple.  The script parser is not very sophisticated.  At this stage it is only a proof of concept.
Most script lines are attached to an html tag using a where clause.

    where attribute = "value"

Attribute can be a tag attribute such as name or id, or the special value "tagname" for the actual name of the tag (e.g. "span" for a <span> tag).  
When specifying the part of a tag to act on, such as with the set command, you can provide a tag attribute to set such as value or href, or the special value "textnode" to indicate the text between the opening and closing tag should be set.
set attribute to "function()" where attribute = value

=over 4

=item DVSM_include

    <!--DVSM_include file/path.html-->

Includes snippets of html with or without DVSM and DSUBS sections.  
In a web application this is used to include a footer.html in every page.  
File pathnames are relative to htmldir passed to sbInitPage().

=item run

    run "function()" [where attribute = "value"]

Unconditionally runs a subroutine.  
If a where clause is provided, all tags that satisfy the criteria have the run 
statement attached to them, and the function will be run when each tag is arrived at.  
If the where clause is not provided, the function is run on the very first tag.

Example:

    <html><body>    
    <span id="sid">hello world</span>
    </body></html>
    <!--DVSM
    run "doRun()"
    run "doRun()" where id = "sid"
    -->
    <!--DSUBS
    my $count = 0;
    sub doRun {
        ++$count;
        my $stream = getSB()->{Stream};
        print $stream "doRun called $count\n";
    }
    -->

Result: 

    doRun called 1
    <html><body>    
    doRun called 2
    <span id="sid">hello world</span>
    </body></html>

=item set

    set attribute1 to "function()" where attribute2 = "value"

Sets a tag's attribute or its child textnode to the return value of function().  
attribute1 can be a tag attribute or the special value textnode.  
attribute2 can be a tag attribute or the special value tagname.

Example:

    <html><body>    
    <span id="sid">hello world</span>
    </body></html>
    <!--DVSM
    set textnode to "sayHello()" where id = "sid"
    set id to "return 'sidney'" where id = "sid"
    -->
    <!--DSUBS
    sub sayHello {
        return "hello sid";
    }
    -->

Result:

    <html><body>    
    <span id="sidney">hello sid</span>
    </body></html>

=item toggle

    toggle attribute_1 to "boolean_function()" where attribute_2 = "value"

Toggles the existence of an attribute - such as checked or selected.  
The attribute does not exist if boolean_function() returns false.  
Otherwise it is created and to satisfy xhtml requirements it is set to a value of "true".

Example:

    <html><body>    
    <select name="myselect">
    <option value="1" select="myselect">Option 1</option>
    <option value="2" select="myselect">Option 2</option>
    <option value="3" select="myselect">Otpion 3</option>
    </select>
    </body></html>
    <!--DVSM
    toggle selected to "doToggle()" where select = "myselect"
    -->
    <!--DSUBS
    my $selected = 2;
    sub doToggle {
        my $sb = getSB();
        my $value = $sb->sbGetCurrentTagValue( "value" );
        return ( $value == $selected );
    }
    -->    

The getSB() function merely returns the HTML::XHTML::DVSM instance - we'll assume it is 
defined by the code that created the HTML::XHTML::DVSM instance.  
Notice we've had to create an attribute that all the options share (select="myselect"), 
so doToggle() is run against each one.  The sbGetCurrentTagValue() sub is in HTML::XHTML::DVSM and 
is used to return attributes of the current tag.  

Result:

    <html><body>    
    <select name="myselect">
    <option value="1" select="myselect">Option 1</option>
    <option value="2" selected="true" select="myselect">Option 2</option>
    <option value="3" select="myselect">Otpion 3</option>
    </select>
    </body></html>

=item delete

    delete where attribute = "value" 

Deletes tags where their xml/html attribute or tagname equals value. 

Example:

    <html><body>    
    <select name="myselect">
    <option value="1" select="myselect">Option 1</option>
    <option value="2" select="deleteme">Option 2</option>
    <option value="3" select="deleteme">Otpion 3</option>
    </select>
    </body></html>
    <!--DVSM
    delete where select = "deleteme"
    -->

Result:

    <html><body>    
    <select name="myselect">
    <option value="1" select="myselect">Option 1</option>
    </select>
    </body></html>

=item if

    if "boolean_function()" where attribute = "value"
        [child instructions] 
    end if

Conditionally includes the tag where attribute or the tagname equals "value".  
If boolean_function() returns true then the tag is output and its children.  
If there are child instructions between if ... end if, they are executed against the child tags.

Example:

    <html><body>
    <p>This paragraph always happens</p>
    <p id="datepara_even">This paragraph only happens if the date of the month
    (<span id="thedate"></span>) is an even number</p>
    <p id="datepara_odd">This version of the paragraph only happens if the date of the month
    (<span id="thedate"></span>) is an odd number</p>
    </body></html>
    <!--DVSM
    if "dateiseven()" where id = "datepara_even"
       set textnode to "getdate()" where id = "thedate"
    end if
    if "dateisodd()" where id = "datepara_odd"
       set textnode to "getdate()" where id="thedate"
    end if
    -->
    <!--DSUBS
    sub dateisodd { return ( ! dateiseven() ); }
    sub dateiseven {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
            localtime(time);
        return ( $mday % 2 == 0 );
    }
    sub getdate {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
            localtime(time);
        return sprintf( "%.2d/%.2d/%.4d", $mday, $mon + 1, 1900 + $year );
    }
    -->


Result:

    <html><body>
    <p>This paragraph always happens</p>
    <p id="datepara_even">This paragraph only happens if the date of the month
    (<span id="thedate">12/01/2009</span>) is an even number</p>
    </body></html>

=item while

    while "boolean_function()" where attribute = "value"
       [child instructions...]
    end while 

Attaches itself to tags where attribute is equal to "value".  
It keeps repeating the tag while boolean_function() returns true.  
For each copy of the tag, it runs child instructions to the child tags.

Example:

    <html><body>
    <table>
    <tr><th>Customer Number</th><th>Customer Name</th></tr>
    <tbody>
    <tr name="customers"><td name="custid">12345</td><td name="custname">Mr Bloggs</td></tr>
    <tr name="deleteme"><td>23456</td><td>Mrs Soap</td></tr>
    <tr name="deleteme"><td>67890</td><td>Mr A N Other</td></tr>
    </tbody>
    </table>
    </body></html>
    <!--DVSM
    delete where name = "deleteme"
    while "moreCustomers()" where name = "customers"
       set textnode to "getCustid()" where name = "custid"
       set textnode to "getCustname()" where name = "custname"
    end while
    -->
    <!--DSUBS
    my %db = ( 148842 => "Mr J Smith", 848488 => "Ms S Jones", 484848 => "Mrs P Cook" );
    my $cursor = -1;
    sub moreCustomers {
        $cursor++;
        my @keys = keys( %db );
        return ( $cursor < @keys );
    }
    sub getCustid {
        my @keys = sort keys( %db );
        return $keys[$cursor];
    }
    sub getCustname {
        return $db{getCustid()};
    }
    --> 

Result:

    <html><body>
    <table>
    <tr><th>Customer Number</th><th>Customer Name</th></tr>
    <tbody>
    <tr name="customers"><td name="custid">148842</td><td name="custname">Mr J Smith</td></tr>
    <tr name="customers"><td name="custid">484848</td><td name="custname">Mrs P Cook</td></tr>
    <tr name="customers"><td name="custid">848488</td><td name="custname">Ms S Jones</td></tr>
    </tbody>
    </table>
    </body></html>

=back

=head1 README

C<HTML::XHTML::DVSM> A perl module that uses a simple scripting language embedded within
XML/XHTML markup to change the markup by adding, removing and
changing tags and attributes. The obvious application is for
generating dynamic web sites. But other applications would be
generating XUL gui screens (using XULs such as thinlet), or B2B XML
documents.

The unique thing about DVSM is it does NOT corrupt your original XML/XHTML. After XHTML is 
developed to run dynamically in your website you can still load the template xhtml into your
dreamweaver or other html tool and it will look exactly the same as it did before.  You can
do a storyboard of your whole website and the story board will be preserved even when it is
used as a template for your dynamic, live website.

=head1 PREREQUISITES

Other than for the use of C<strict> there are actually no dependancies in HTML::XHTML::DVSM.
It uses simple regular expressions to parse script elements and xml/xhtml.  In future
should there be demand, it would probably be amended to allow the use of a proper XML
parser and perhaps a robust mini-language compiler/interpreter.  But the aim is to
allow HTML::XHTML::DVSM to be used with the most primitive web hoster.  If there is perl, HTML::XHTML::DVSM
will run.

IO::String is required for the unit tests.  It is not needed by HTML::XHTML::DVSM itself.

=head1 OSNAMES

any

=head1 SCRIPT CATEGORIES



=head1 AUTHORS

Copyright © 2007-2010 Stuart Butler (perldev@yahoo.co.uk) and Grant Holman (grant@collegeroad.eclipse.co.uk).

=cut
