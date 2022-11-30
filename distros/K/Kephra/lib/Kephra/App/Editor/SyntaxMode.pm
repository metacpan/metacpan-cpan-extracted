use v5.12;
use warnings;

package Kephra::App::Editor::SyntaxMode;
use Wx qw/ :everything /;
use Wx::STC;
#use Wx::Scintilla;

sub apply {
    my ($self) = @_;
    load_font( $self );  # before setting highlighting
    set_perlhighlight( $self );
    set_colors( $self ); # after highlight
    set_tab_size( $self, $self->{'tab_size'} );
    set_tab_usage( $self, 0 );
    set_margin( $self );

}

sub set_tab_size {
    my ($self, $size) = @_;
    #$size *= 2 if $^O eq 'darwin';
    $self->SetTabWidth($size);
    $self->SetIndent($size);
    $self->SetHighlightGuide($size);
    $self->SetIndentationGuides(1);
}

sub set_tab_usage {
    my ($self, $usage) = @_;
   $self->SetUseTabs($usage);
}

sub set_margin {
    my ($self, $style) = @_;

    if (not defined $style or not $style or $style eq 'default') {
        $self->SetMarginType( 0, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginType( 1, &Wx::wxSTC_MARGIN_NUMBER );
        $self->SetMarginType( 2, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginType( 3, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginMask( 0, 0x01FFFFFF );
        $self->SetMarginMask( 1, 0 );
        $self->SetMarginMask( 2, 0x01FFFFFF); #  | &Wx::wxSTC_MASK_FOLDERS
        $self->SetMarginMask( 3, &Wx::wxSTC_MASK_FOLDERS );
        $self->SetMarginSensitive( 0, 1 );
        $self->SetMarginSensitive( 1, 1 );
        $self->SetMarginSensitive( 2, 1 );
        $self->SetMarginSensitive( 3, 0 );
        $self->StyleSetForeground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(93,93,97));    # 33
        $self->StyleSetBackground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(206,206,202));
        $self->SetMarginWidth(0,  1);
        $self->SetMarginWidth(1, 47);
        $self->SetMarginWidth(2, 22);
        $self->SetMarginWidth(3,  2);
        # extra text margin
    }
    elsif ($style eq 'no') { $self->SetMarginWidth($_, 0) for 1..3 }

    # extra margin left and right inside the white text area
    $self->SetMargins(2, 2);
    $self;
}

sub set_colors {
    my $self = shift;
    $self->SetCaretPeriod( 600 );
    $self->SetCaretWidth( 2 );
    $self->SetCaretForeground( create_color( 0, 0, 100) ); #140, 160, 255
    $self->SetCaretLineVisible(1);
    $self->SetCaretLineBack( create_color(235, 235, 235) );
    $self->SetSelForeground( 1, create_color(243,243,243) );
    $self->SetSelBackground( 1, create_color(0, 17, 119) );
    $self->SetWhitespaceForeground( 1, create_color(200, 200, 153) );
    $self->SetViewWhiteSpace(1);
    
    $self->SetEdgeColour( create_color(200,200,255) );
    $self->SetEdgeColumn( 80 );
    $self->SetEdgeMode( &Wx::wxSTC_EDGE_LINE );
}
sub create_color { Wx::Colour->new(@_) }

sub load_font {
    my ($self, $font) = @_;
    my ( $fontweight, $fontstyle ) = ( &Wx::wxNORMAL, &Wx::wxNORMAL );
    $font = {
        family => $^O eq 'darwin' ? 'Andale Mono' : 'Courier New', # old default
                # Courier New
        #family => 'DejaVu Sans Mono', # new
        size => $^O eq 'darwin' ? 13 : 11,
        style => 'normal',
        weight => 'normal',    
    } unless defined $font;
    #my $font = _config()->{font};
    $fontweight = &Wx::wxLIGHT  if $font->{weight} eq 'light';
    $fontweight = &Wx::wxBOLD   if $font->{weight} eq 'bold';
    $fontstyle  = &Wx::wxSLANT  if $font->{style}  eq 'slant';
    $fontstyle  = &Wx::wxITALIC if $font->{style}  eq 'italic';
    my $wx_font = Wx::Font->new( 
        $font->{size}, &Wx::wxDEFAULT, $fontstyle, $fontweight, 0, $font->{family}
    );
    $self->StyleSetFont( &Wx::wxSTC_STYLE_DEFAULT, $wx_font ) if $wx_font->Ok > 0;
}

sub set_perlhighlight {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( &Wx::wxSTC_LEX_PERL );         # Set Lexers to use
    $self->SetKeyWords(0, 'NULL 
__FILE__ __LINE__ __PACKAGE__ __DATA__ __END__ __WARN__ __DIE__
AUTOLOAD BEGIN CHECK CORE DESTROY END EQ GE GT INIT LE LT NE UNITCHECK 
abs accept alarm and atan2 bind binmode bless break
caller chdir chmod chomp chop chown chr chroot close closedir cmp connect
continue cos crypt
dbmclose dbmopen default defined delete die do dump
each else elsif endgrent endhostent endnetent endprotoent endpwent endservent 
eof eq eval exec exists exit exp 
fcntl fileno flock for foreach fork format formline 
ge getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname gethostent 
getlogin getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid 
getpriority getprotobyname getprotobynumber getprotoent getpwent getpwnam 
getpwuid getservbyname getservbyport getservent getsockname getsockopt given 
glob gmtime goto grep gt 
hex if index int ioctl join keys kill 
last lc lcfirst le length link listen local localtime lock log lstat lt 
m map mkdir msgctl msgget msgrcv msgsnd my ne next no not 
oct open opendir or ord our pack package pipe pop pos print printf prototype push 
q qq qr quotemeta qu qw qx 
rand read readdir readline readlink readpipe recv redo ref rename require reset 
return reverse rewinddir rindex rmdir
s say scalar seek seekdir select semctl semget semop send setgrent sethostent 
setnetent setpgrp setpriority setprotoent setpwent setservent setsockopt shift 
shmctl shmget shmread shmwrite shutdown sin sleep socket socketpair sort splice 
split sprintf sqrt srand stat state study sub substr symlink syscall sysopen 
sysread sysseek system syswrite 
tell telldir tie tied time times tr truncate
uc ucfirst umask undef unless unlink unpack unshift untie until use utime 
values vec wait waitpid wantarray warn when while write x xor y');
# Add new keyword.
# $_[0]->StyleSetSpec( &Wx::wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)

    $self->StyleSetSpec(1,"fore:#ff0000,back:#ffff00");                        # Error
    $self->StyleSetSpec(&Wx::wxSTC_PL_COMMENTLINE,"fore:#aaaaaa");                                     # Comment
    $self->StyleSetSpec(&Wx::wxSTC_PL_POD,        "fore:#004000,back:#E0FFE0,$(font.text),eolfilled"); # POD: = at beginning of line
    $self->StyleSetSpec(&Wx::wxSTC_PL_NUMBER,     "fore:#007f7f");                                     # Number
    $self->StyleSetSpec(5,"fore:#000077,bold");                                # Keywords #
    $self->StyleSetSpec(6,"fore:#ee7b00,back:#fff8f8");                        # Doublequoted string
    $self->StyleSetSpec(7,"fore:#f36600,back:#fffcff");                        # Single quoted string
    $self->StyleSetSpec(8,"fore:#FF5555,bold");                                # Symbols / Punctuation. Currently not used by LexPerl.
    $self->StyleSetSpec(9,"");                                                 # Preprocessor. Currently not used by LexPerl.
    $self->StyleSetSpec(10,"fore:#000000");                                    # Operators
    $self->StyleSetSpec(11,"fore:#3355bb");                                    # Identifiers (functions, etc.)
    $self->StyleSetSpec(12,"fore:#228822");                                    # Scalars: $var
    $self->StyleSetSpec(13,"fore:#339933");                                    # Array: @var
    $self->StyleSetSpec(14,"fore:#44aa44");                                    # Hash: %var
    $self->StyleSetSpec(15,"fore:#55bb55");                                    # Symbol table: *var
    $self->StyleSetSpec(17,"fore:#000000,back:#A0FFA0");                       # Regex: /re/ or m{re}
    $self->StyleSetSpec(18,"fore:#000000,back:#F0E080");                       # Substitution: s/re/ore/
    $self->StyleSetSpec(19,"fore:#000000,back:#8080A0");                       # Long Quote (qq, qr, qw, qx) -- obsolete: replaced by qq, qx, qr, qw
    $self->StyleSetSpec(20,"fore:#ff7700,back:#f9f9d7");                       # Back Ticks
    $self->StyleSetSpec(21,"fore:#600000,back:#FFF0D8,eolfilled");             # Data Section: __DATA__ or __END__ at beginning of line
    $self->StyleSetSpec(22,"fore:#000000,back:#DDD0DD");                       # Here-doc (delimiter)
    $self->StyleSetSpec(23,"fore:#7F007F,back:#DDD0DD,eolfilled,notbold");     # Here-doc (single quoted, q)
    $self->StyleSetSpec(24,"fore:#7F007F,back:#DDD0DD,eolfilled,bold");        # Here-doc (double quoted, qq)
    $self->StyleSetSpec(25,"fore:#7F007F,back:#DDD0DD,eolfilled,italics");     # Here-doc (back ticks, qx)
    $self->StyleSetSpec(26,"fore:#7F007F,$(font.monospace),notbold");          # Single quoted string, generic 
    $self->StyleSetSpec(27,"fore:#ee7b00,back:#fff8f8");                       # qq = Double quoted string
    $self->StyleSetSpec(28,"fore:#ff7700,back:#f9f9d7");                       # qx = Back ticks
    $self->StyleSetSpec(29,"fore:#000000,back:#A0FFA0");                       # qr = Regex
    $self->StyleSetSpec(30,"fore:#f36600,back:#fff8f8");                       # qw = Array
    $self->StyleSetSpec(&Wx::wxSTC_STYLE_BRACELIGHT, "fore:#0000ff,back:#FFFFFF,bold");# 34
    $self->StyleSetSpec(&Wx::wxSTC_STYLE_BRACEBAD,   "fore:#ff0000,back:#FFFFFF,bold");# 35
    $self->StyleSetForeground(&Wx::wxSTC_STYLE_INDENTGUIDE,create_color(206,206,202)); # 37
}

1;

__END__

$self->SetIndicatorCurrent( $c);
$self->IndicatorFillRange( $start, $len );
$self->IndicatorClearRange( 0, $len )
	#Wx::Event::EVT_STC_STYLENEEDED($self, sub{}) 
	#Wx::Event::EVT_STC_CHARADDED($self, sub {});
	#Wx::Event::EVT_STC_ROMODIFYATTEMPT($self, sub{}) 
	#Wx::Event::EVT_STC_KEY($self, sub{}) 
	#Wx::Event::EVT_STC_DOUBLECLICK($self, sub{}) 
	Wx::Event::EVT_STC_UPDATEUI($self, -1, sub { 
		#my ($ed, $event) = @_; $event->Skip; print "change \n"; 
	});
	#Wx::Event::EVT_STC_MODIFIED($self, sub {});
	#Wx::Event::EVT_STC_MACRORECORD($self, sub{}) 
	#Wx::Event::EVT_STC_MARGINCLICK($self, sub{}) 
	#Wx::Event::EVT_STC_NEEDSHOWN($self, sub {});
	#Wx::Event::EVT_STC_PAINTED($self, sub{}) 
	#Wx::Event::EVT_STC_USERLISTSELECTION($self, sub{}) 
	#Wx::Event::EVT_STC_UR$selfROPPED($self, sub {});
	#Wx::Event::EVT_STC_DWELLSTART($self, sub{}) 
	#Wx::Event::EVT_STC_DWELLEND($self, sub{}) 
	#Wx::Event::EVT_STC_START_DRAG($self, sub{}) 
	#Wx::Event::EVT_STC_DRAG_OVER($self, sub{}) 
	#Wx::Event::EVT_STC_DO_DROP($self, sub {});
	#Wx::Event::EVT_STC_ZOOM($self, sub{}) 
	#Wx::Event::EVT_STC_HOTSPOT_CLICK($self, sub{}) 
	#Wx::Event::EVT_STC_HOTSPOT_DCLICK($self, sub{}) 
	#Wx::Event::EVT_STC_CALLTIP_CLICK($self, sub{}) 
	#Wx::Event::EVT_STC_AUTOCOMP_SELECTION($self, sub{})
	#$self->SetAcceleratorTable( Wx::AcceleratorTable->new() );
	#Wx::Event::EVT_STC_SAVEPOINTREACHED($self, -1, \&Kephra::File::savepoint_reached);
	#Wx::Event::EVT_STC_SAVEPOINTLEFT($self, -1, \&Kephra::File::savepoint_left);
	$self->SetAcceleratorTable(
		Wx::AcceleratorTable->new(
			[&Wx::wxACCEL_CTRL, ord 'n', 1000],
	));



