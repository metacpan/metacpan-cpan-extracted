use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: blank lines and comment lines as comments
blank lines and lines of just comments may appear among
the command lines; they are ignored.
--- src
foo:
	first

 
# This is ignored
	second

--- dom
M::D::G
  M::R::S
    M::T::B         'foo'
    M::T::S         ':'
    M::T::W         '\n'
  M::C
    M::T::S         '\t'
    M::T::B         'first'
    M::T::W         '\n'
  M::T::W           '\n'
  M::T::W           ' \n'
  M::T::C           '# This is ignored'
  M::T::W           '\n'
  M::C
    M::T::S         '\t'
    M::T::B         'second'
    M::T::W         '\n'



=== TEST 2: empty commands
a blank line that begins with a tab is not blank; it's an empty
command
--- src

foo:
	
	echo

--- dom
M::D::G
  M::R::S
    M::T::B         'foo'
    M::T::S         ':'
    M::T::W         '\n'
  M::C
    M::T::S         '\t'
    M::T::W         '\n'
  M::C
    M::T::S         '\t'
    M::T::B         'echo'
    M::T::W         '\n'



=== TEST 3: comments as commands
a comment in a command line is not a make comment;
it will be passed to the shell as-is.
--- src

foo:
	# This is a command, not a comment

--- dom
M::D::G
  M::R::S
    M::T::B             'foo'
    M::T::S             ':'
    M::T::W             '\n'
  M::C
    M::T::S             '\t'
    M::T::B             '# This is a command, not a comment'
    M::T::W             '\n'



=== TEST 4: var def as commands
a variable definition in a "rule context" which is indented by a tab
as the first character on the line, will be considered a command line.
--- src

foo:
	var = value
	var := value
	var += value
	var ?= value

--- dom
M::D::G
  M::R::S
    M::T::B                 'foo'
    M::T::S                 ':'
    M::T::W                 '\n'
  M::C
    M::T::S                 '\t'
    M::T::B                 'var = value'
    M::T::W                 '\n'
  M::C
    M::T::S                 '\t'
    M::T::B                 'var := value'
    M::T::W                 '\n'
  M::C
    M::T::S                 '\t'
    M::T::B                 'var += value'
    M::T::W                 '\n'
  M::C
    M::T::S                 '\t'
    M::T::B                 'var ?= value'
    M::T::W                 '\n'



=== TEST 5: conditional directives as commands
a conditional expression (ifdef, ifeq, etc) in a "rule context"
which is indented by a tab as the first character on the line,
will be considered a command line
--- src

foo:
	ifdef $(foo)
	echo
	endif

--- dom
M::D::G
  M::R::S
    M::T::B             'foo'
    M::T::S             ':'
    M::T::W             '\n'
  M::C
    M::T::S             '\t'
    M::T::B             'ifdef '
    M::T::I             '$(foo)'
    M::T::W             '\n'
  M::C
    M::T::S             '\t'
    M::T::B             'echo'
    M::T::W             '\n'
  M::C
    M::T::S             '\t'
    M::T::B             'endif'
    M::T::W             '\n'



=== TEST 6: line continuations in commands
--- src
a :
	- mv \#\
	+ e \
  \\
	@

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'a'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     '\n'
  MDOM::Command
    MDOM::Token::Separator      '\t'
    MDOM::Token::Modifier       '-'
    MDOM::Token::Bare           ' mv \#\\n\t+ e \\n  \\'
    MDOM::Token::Whitespace     '\n'
  MDOM::Command
    MDOM::Token::Separator      '\t'
    MDOM::Token::Modifier       '@'
    MDOM::Token::Whitespace     '\n'



=== TEST 7: line continuations in prereqs and "inline" commands
--- src

a: \
	b;\
    c \
    d

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'a'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Continuation   '\\n'
    MDOM::Token::Whitespace     '\t'
    MDOM::Token::Bare           'b'
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Bare         '\\n    c \\n    d'
      MDOM::Token::Whitespace   '\n'



=== TEST 8: whitespace before command modifiers (@)
--- src

all:
	  @ echo $@

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Whitespace           '  '
    MDOM::Token::Modifier             '@'
    MDOM::Token::Bare         ' echo '
    MDOM::Token::Interpolation                '$@'
    MDOM::Token::Whitespace           '\n'



=== TEST 9: whitespace before command modifiers (+/-)
--- src

all:
	  + echo $@
		-blah!

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Whitespace           '  '
    MDOM::Token::Modifier             '+'
    MDOM::Token::Bare         ' echo '
    MDOM::Token::Interpolation                '$@'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Whitespace           '\t'
    MDOM::Token::Modifier             '-'
    MDOM::Token::Bare                 'blah!'
    MDOM::Token::Whitespace           '\n'



=== TEST 10: multi-line commands
--- src

compile_all:
	for d in $(source_dirs); \
	do                       \
		$(JAVAC) $$d/*.java; \
	done

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'compile_all'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Bare         'for d in '
    MDOM::Token::Interpolation        '$(source_dirs)'
    MDOM::Token::Bare	'; \\n\tdo                       \\n\t\t'
    MDOM::Token::Interpolation          '$(JAVAC)'
    MDOM::Token::Bare         ' '
    MDOM::Token::Interpolation      '$$'
    MDOM::Token::Bare           'd/*.java; \\n\tdone'
    MDOM::Token::Whitespace		'\n'



=== TEST 11: multi-modifiers
--- src
all:
	@ - exit
        -@ exit 1
        @-exit 1
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Modifier             '@'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Modifier             '-'
    MDOM::Token::Bare         ' exit'
    MDOM::Token::Whitespace           '\n'
  MDOM::Unknown
    MDOM::Token::Whitespace           '        '
    MDOM::Token::Modifier             '-'
    MDOM::Token::Modifier             '@'
    MDOM::Token::Bare         ' exit 1'
    MDOM::Token::Whitespace           '\n'
  MDOM::Unknown
    MDOM::Token::Whitespace           '        '
    MDOM::Token::Modifier             '@'
    MDOM::Token::Modifier             '-'
    MDOM::Token::Bare         'exit 1'
    MDOM::Token::Whitespace           '\n'



=== TEST 12: line continuations in commands
--- src
all:
	\
	echo $@
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Bare               '\\n\techo '
    MDOM::Token::Interpolation        '$@'
    MDOM::Token::Whitespace           '\n'



=== TEST 13: ditto (with interpolations)
--- src
all:
	@echo $(FOO) \
   $(BAR) \
	$(BIT)
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Modifier             '@'
    MDOM::Token::Bare         'echo '
    MDOM::Token::Interpolation                '$(FOO)'
    MDOM::Token::Bare         ' \\n   '
    MDOM::Token::Interpolation  '$(BAR)'
    MDOM::Token::Bare           ' \\n\t'
    MDOM::Token::Interpolation                '$(BIT)'
    MDOM::Token::Whitespace           '\n'

