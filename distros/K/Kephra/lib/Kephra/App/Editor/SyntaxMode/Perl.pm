use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::Perl;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( &Wx::wxSTC_LEX_PERL );
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
# $self->StyleSetSpec( &Wx::wxSTC_H_TAG, "fore:#000055" ); # Apply tag style for selected lexer (blue)

    $self->StyleSetSpec(0,"fore:#aabbbb,back:#ffffff");                        # Whitespace
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
    $self->StyleSetSpec(31,"fore:#f36600,back:#fff8f8");                       # POD verb
    $self->StyleSetSpec(&Wx::wxSTC_STYLE_BRACELIGHT, "fore:#0000ff,back:#FFFFFF,bold");# 34
    $self->StyleSetSpec(&Wx::wxSTC_STYLE_BRACEBAD,   "fore:#ff0000,back:#FFFFFF,bold");# 35
}

1;

__END__
# wxSTC_PL_SUB_PROTOTYPE   40
# wxSTC_PL_FORMAT_IDENT   41
# wxSTC_PL_FORMAT   42
# wxSTC_PL_STRING_VAR   43
# wxSTC_PL_XLAT   44
# wxSTC_PL_REGEX_VAR   54
# wxSTC_PL_REGSUBST_VAR   55
# wxSTC_PL_BACKTICKS_VAR   57
# wxSTC_PL_HERE_QQ_VAR   61
# wxSTC_PL_HERE_QX_VAR   62
# wxSTC_PL_STRING_QQ_VAR   64
# wxSTC_PL_STRING_QX_VAR   65
# wxSTC_PL_STRING_QR_VAR   66
