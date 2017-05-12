## -*- Mode: CPerl -*-

#############################################################################
#
# File: Getopt::Gen.pm
# Author: Bryan Jurish <moocow@cpan.org>
# Description: Parser for extended '.ggo' (gengetopt) files
#
#############################################################################

package Getopt::Gen;

use Carp qw(carp confess);
use IO::File;
use Exporter;
use Text::Template;

use Parse::Lex;
use Parse::Token;
use Getopt::Gen::Parser;

@ISA = qw(Exporter);

@EXPORT = qw();
%EXPORT_TAGS =
  (
   utils=>[qw(
	      long2cname
	      podify
	      string_value
	      dequote
	     )],
  );
@EXPORT_OK = (map { @$_ } values(%EXPORT_TAGS));

###############################################################
# GLOBALS
###############################################################
our $VERSION = "0.14";

our %DEFAULT_TEMPLATE_NEWARGS = ();

our %DEFAULT_TEMPLATE_HASHARGS =
  (
   Getopt::GenVersion=>$VERSION,
   og=>undef,                  # this will be the Getopt::Gen object itself
  );

our %DEFAULT_TEMPLATE_FILLARGS =
  (
   DELIMITERS=>['[@','@]'],
   BROKEN=>\&template_broken,
   BROKEN_ARG=>undef,          # gets { NAME=>$og->{name},SOURCE=>$user_source,%user_broken_arg }
  );

# whether to carp()/croak() on complain()/wigout()
our $VERBOSE = 0;

###############################################################
# Natural language names for parser & lexer internals
###############################################################
our %NL_XLATE =
  (
   ##--------------------------------------
   ## error message literals
   ##--------------------------------------
   SYNTAX_ERROR =>
     "__NAME__: Syntax error in __FILE__ at line __LINE__ column __COL__, near `__CURTEXT__'\n"
     ."  > Expected one of: __EXPECTED__\n"
     ."  > Got: __CURTOK__\n",
   SEMANTIC_ERROR =>
     "__NAME__: Semantic error in __FILE__ at line __LINE__ column __COL__, near `__CURTEXT__'\n"
     ."  > Hint: __HINT__\n"
     ."  > Got: `__CURTEXT__'\n",
   LEXER_ERROR =>
     "__NAME__: Tokenization error in __FILE__ at line __LINE__ column __COL__, near `__CURTEXT__'\n"
     ."  > Hint: __HINT__\n",

   ##--------------------------------------
   ## lexer tokens
   ##--------------------------------------
   COMMENT => '<a comment>',
   #EQUALS => "=",
   #DBLQUOTE => '"',
   SYMBOL => '<a symbol>',
   STRING => '<a string>',
   NEWLINE => '<a newline>',
   #ONOFF => '<an on/off value>',
   #YESNO => '<a yes/no value>',
   #OTYPE => '<a token type>'

   ##--------------------------------------
   ## parser nonterminals
   ##--------------------------------------
   optspec => '<a specification>',

   ##--------------------------------------
   ## Lexer Hints
   ##--------------------------------------
   ILLEGAL_CHAR => "Illegal character `__MATCH__'.",
   UNKNOWN_LEXER_HINT => "???",

   ##--------------------------------------
   ## Parser Hints
   ##--------------------------------------
   NOT_SHORT_ENOUGH => "Short option names must be single-characters.",
  );

###############################################################
# Lexical Analysis variables
#  + Variable-name prefix conventions:
#    - $OG_ : any Getopt::Gen token
###############################################################

# $OG_SYMINIT, $OG_SYMBODY
#  + characters for symbol tokens
our $OG_SYMINIT = '\w\d';
our $OG_SYMBODY = '\w\d\.\_\-';
our $OG_SYMBOL = '(?:['.$OG_SYMINIT.']['.$OG_SYMBODY.']*)';

# $OG_TOK_(BEG|EWND)
#  + separator regexes
our $OG_TOK_BEG = '(?<!['.$OG_SYMBODY.'])';
our $OG_TOK_END = '(?!['.$OG_SYMBODY.'])';

# $OG_NEWLINE
#  + newline characters
our $OG_NEWLINE = '\n\r';

# $OG_ANY
#  + any known character
our $OG_ANY = '.';

# Special keywords added to lexer tokens (TOK_* constants)
our @OG_KEYWORDS = qw(
		      code
		      rcfile
		      package
		      version
		      podpreamble
		      purpose
		      on_reparse
		      unnamed
		      argument
		      group
		      option
		      on off
		      yes no
		      funct
		      flag
		      toggle
		      string
		      int short long
		      float double longdouble
		     );

# @LEXER_TOKENS
#   + Tokenization specification for Parse::Lex lexer
#   + the 'SEARCH_TOKEN' type is further checked by
#     the yylex() sub
our @LEXER_TOKENS =
  (
   ## -- curly-braces (special handling by _yylex_sub())
   'ALL:LBRACE', '{',
   'ALL:RBRACE', '}',
   'BRACED:STRING', '[^\{\}]*',

   ## Comments
   'COMMENT', '(?:\#[^'.$OG_NEWLINE.']*)', \&yyignore,
   Parse::Token::Delimited->new(Name=>'MULTILINE_COMMENT',
				Start => '/[*]',
				End => '[*]/',
				Sub=>\&yyignore),

   ## Keyword symbols
   (map {
     my $kwname = $_;
     my $kwregex = $OG_TOK_BEG.$kwname.$OG_TOK_END;
     $kwname =~ tr/a-z/A-Z/;
     ('TOK_'.$kwname,$kwregex)
   } @OG_KEYWORDS),

   ## Newlines are lexical elements (ick)
   'NEWLINE', '['.$OG_NEWLINE.']+',

   ## Special symbols
   'MINUS', '\-',
   'EQUALS', '\=',
   'ESCAPED_NEWLINE', '\\\\['.$OG_NEWLINE.']', \&yyignore,

   ## Literal symbols
   'SYMBOL', $OG_SYMBOL,

   ## Strings (double-quoted)
   Parse::Token::Quoted->new(Name=>'DQ_STRING',
			     Handler=>'string',
			     Escape=>'\\',
			     Quote=>'"',
			     Sub=>sub { dequote($_[1],'"'); }
			    ),
   ## Strings (single-quoted)
   Parse::Token::Quoted->new(Name=>'SQ_STRING',
			     Handler=>'string',
			     Escape=>'\\',
			     Quote=>'\'',
			     Sub=>sub { dequote($_[1],"'"); },
			    ),
   ## Strings (back-quoted)
   Parse::Token::Quoted->new(Name=>'BQ_STRING',
			     Handler=>'string',
			     Escape=>'\\',
			     Quote=>'`',
			     Sub=>sub { bq_dequote($_[1],"`"); },
			    ),
  );

###############################################################
# CONSTRUCTOR
###############################################################
sub new {
  my ($that,%args) = @_;
  my $class = ref($that)||$that;
  my $og = bless
    {
     ## -- user data
     USER   => {},                      # hashref to user-strings
     ## -- new parsing data
     parser => undef,                   # Getopt::Gen::Parser object
     lexer  => undef,                   # Parse::Lex lexer
     yylex  => undef,                   # lexer sub
     yyerr  => undef,                   # error sub
     errstr => undef,                   # last error message (undef on success)
     ## -- i/o data
     name=> __PACKAGE__ ,               # name to use for error-reporting
     infile=>undef,                     # input filename
     infh=>undef,                       # input filehandle
     outfile=>undef,                    # output filename
     outfh=>undef,                      # output filehandle
     #TEMPLATE_ARGS=>{},                # args for template
     ## -- generation-flags
     filename=>'cmdline',               # basename of output file
     funcname=>'cmdline_parser',        # name of parsing-function
     structname=>'gengetopt_args_info', # name of parser-structure
     longhelp=>0,                       # long usage line in help ?
     unnamed=>0,                        # allow non-option arguments ?
     reparse_action=>'error',           # what to do when an option is re-given: error|warn|clobber
     handle_help=>1,                    # whether to handle '-h' and '--help' options
     handle_version=>1,                 # whether to handle '-V' and '--version' options
     handle_rcfile=>1,                  # whether to handle '-c' and '--rcfile' options
     handle_error=>1,                   # whether to exit on errors
     want_timestamp=>0,                 # whether to add timestamp to pod files
     ## -- parsed data from input file
     package   => undef,                # program package
     #program   => undef,               # program name (in USER)
     version   => undef,                # program version
     purpose   => undef,                # brief description
     podpreamble => undef,              # pod preamble
     rcfiles   => [],                   # default config files (literals!)
     args      => [],                   # [ {name=>$arg1name,descr=>$arg1descr},... ]
     user_code => undef,                # literal user code for .c file
     group     => 'Options',            # name of current group (used during parsing)
     optl      => [],                   # list of options in order given
     opth      => {},                   # { $optid1=>$opt1, ..., }
     optshort  => {},                   # { $short1=>$opdid1, ...} : for conflict-resolution
     optlong   => {},                   # { $long1=>$opdid1, ...} : for conflict-resolution
    }, $class;

  #%{$og->{TEMPLATE_ARGS}} = %DEFAULT_TEMPLATE_ARGS;
  my ($arg,$aval);
  while (($arg,$aval) = each(%args)) {
    if (exists($og->{$arg})) {
      if (ref($og->{$arg}) && ref($og->{$arg}) eq 'HASH') {
	%{$og->{$arg}} = (%{$og->{$arg}}, %$aval);
      }
      elsif (ref($og->{$arg}) && ref($og->{$arg}) eq 'ARRAY') {
	@{$og->{$arg}} = @$aval;
      }
      else {
	$og->{$arg} = $aval;
      }
    }
    else {
      carp(__PACKAGE__ , "::new(): ignoring unknown keyword '$arg'");
    }
  }

  ## -- sanity check
  my @reparse_actions = qw(error warn clobber);
  if (!grep { $_ eq $og->{reparse_action} } @reparse_actions) {
    carp(__PACKAGE__ , "::new(): unknown reparse_action keyword '$_' -- using 'error'");
    $og->{reparse_action} = 'error';
  }


  ## -- setup new lexer/parser pair
  if (!defined($og->{lexer})) {
    Parse::Lex->exclusive('BRACED');
    $og->{lexer} = Parse::Lex->new
      (
       @LEXER_TOKENS,
       qw(ERROR .*), $og->lexer_error()
      );

    $og->{lexer}->skip('[ \t]*');

#    $og->{lexer}->skip('\[ \t]*(?:#(?:[^'.$OG_NEWLINE.']*)'
#		       .'|[ \t]+'
#		       .'|(?:\\\\['.$OG_NEWLINE.'])'
#		       .')[ \t]*');

#    $og->{lexer}->skip('\s*(?:#(?s:.*)'
#		       .'|\s+'
#		       .'|\\\\['.$OG_NEWLINE.']'
#		       .')\s*');
  }
  $og->{parser} = Getopt::Gen::Parser->new()
    if (!defined($og->{parser}));

  $og->{yylex} = $og->_yylex_sub()
    if (!defined($og->{yylex}));

  $og->{yyerror} = $og->_yyerror_sub()
    if (!defined($og->{yyerror}));


  ## -- add auto-handlers
  if ($og->{handle_help}) {
    #$oid = $og->parse_option(q("help" h "Print help and exit" no));
    $og->add_option({short=>'h',
		     long=>'help',
		     descr=>'Print help and exit.',
		     is_help=>1,
		    },$og->{parser});
  }
  if ($og->{handle_version}) {
    $og->add_option({short=>'V',
		     long=>'version',
		     descr=>'Print version and exit.',
		     is_version=>1,
		    },$og->{parser});
  }
  if ($og->{handle_rcfile}) {
    $og->add_option({short=>'c',
		     long=>'rcfile',
		     descr=>'Read an alternate configuration file.',
		     type=>'string',
		     arg=>'FILE',
		     is_rcfile=>1,
		    },$og->{parser});
  }


  return $og;
}


###############################################################
# Destructor
#  + close files and break all references
###############################################################
sub DESTROY {
  if (defined($_[0]->{infh}) && $_[0]->{infh}->opened()) {
    $_[0]->{infh}->close();
  }
  %{$_[0]} = ();
}

###############################################################
# Accessors
###############################################################
sub lexer { return $_[0]->{lexer}; }
sub parser { return $_[0]->{parser}; }
sub errstr { return $_[0]->{errstr}; }

###############################################################
# Parsing: high-level
###############################################################

# $parse_status = $og->parse($file);
#   + on failure, returns undef $og->errstr() holds an error message
sub parse {
  my ($og,$file) = @_;
  $og->reset;

  $og->{infile} = $file;
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  if (!$fh) {
    $og->complain("open failed for file '$file': $!");
    return undef;
  }
  $og->{infh} = $fh;
  $og->{lexer}->from($fh);
  $og->{parser}{USER}{og} = $og;

  $result = eval {
    $og->{parser}->YYParse
      (
       yylex => $og->{yylex},
       yyerror => $og->{yyerror},
       #yydebug => 0x01,  # lexer debug
       #yydebug => 0x02,  # state info
       #yydebug => 0x04,  # driver actions (shift/reduce/etc.)
       #yydebug => 0x08,  # stack dump
       #yydebug => 0x10,  # Error recovery trace
       #yydebug => 0x01 | 0x02 | 0x04 | 0x08, # almost everything
      )
    };

  # -- cleanup
  delete $og->{parser}{USER}{og};
  $fh->close();
  @$og{qw(infile infh)} = undef;

  # everything was kosher...
  return $result unless ($@);

  # ... or it wasn't
  $og->{errstr} = $@;
  return undef;
}

# ---- DEBUG
# $result = $og->dummylex(@strings_or_filehandles);
sub dummylex {
  my $og = shift;
  $og->{lexer}->reset;

  my ($name,$text);
  foreach (@_) {
    $og->{infile} = $_;
    $og->{lexer}->from($_);
  TOKEN:while (1) {
      ($name,$text) = &{$og->{yylex}}();
      if ($name) {
	print("-" x 64, "\n",
	      ">>  Line: ", $og->{lexer}->line, ", Pos: ", $og->{lexer}->pos, "\n",
	      ">>  Type: ", $name, "\n",
	      ">>  Text: `", $text, "'\n");
	last TOKEN if ($name eq 'ERROR');
      }
      else {
	last TOKEN;
      }
    }
    print("-" x 64, "\n",
	  ">>  Line: ", $og->{lexer}->line, ", Pos: ", $og->{lexer}->pos, "\n",
	  ">>  Text: `", (defined($text) ? $text : '<undef>'), "'\n",
	  ">>  EOF\n");
  }
  return $text;
}


###############################################################
# METHODS : generation
###############################################################

# $template_output = fill_in(%args);
sub fill_in {
  my ($og,%userargs) = @_;
  my %args = %userargs;

  $og->{template} =
    Text::Template->new(%DEFAULT_TEMPLATE_NEWARGS,%args)
	or $og->wigout("could not create Text::Template object!");
  delete(@args{qw(SOURCE TYPE)});

  my $hashargs = {
		  %DEFAULT_TEMPLATE_HASHARGS,
		  og=>$og,
		  (exists($args{HASH}) ? %{$args{HASH}} : qw()),
		  SOURCE=>$userargs{SOURCE},
		 };
  delete($args{HASH});

  my $brokenargs = {
		    NAME=>$og->{name},
		    SOURCE=>$userargs{SOURCE},
		    (exists($args{BROKEN_ARG}) ? (%{$args{BROKEN_ARG}}) : qw()),
		   };

  return
    $og->{template}->fill_in(
			     %DEFAULT_TEMPLATE_FILLARGS,
			     HASH=>$hashargs,
			     %args,
			     (exists($args{BROKEN})
			      ? (BROKEN_ARG=>$args{BROKEN_ARG})
			      : (BROKEN_ARG=>$brokenargs)),
			    );
}

# broken(%args)
#   + called when things go wrong
#   + %args keys:
#     text=>$failed_perl_fragment,
#     lineno=>$template_input_line_number,
#     error=>$@_of_failed_perl_frag,
#     arg=>$USER_REFERENCE,
#   + here, arg is the same as the template's HASH.
sub template_broken {
  my (%args) = @_;
  print STDERR
    ("$args{arg}{NAME}: '$args{arg}{SOURCE}', line $args{lineno}: $args{error}\n",
     ($VERBOSE
      ? ("> Code Fragment: \n> ",
	 (defined($args{text})
	  ? join("\n> ", split(/\n/,$args{text}))
	  : '(undefined, sorry)'),
	 "\n")
      : qw()),
    );
  return undef; ## -- abort
}



###############################################################
# METHODS: MANIPULATORS
###############################################################

# $optid = $og->add_option($opt,$parser)
#  + parses a partial option-hash
#  + to be called by parser
sub add_option {
  my ($og,$opt,$ogp) = @_;

  ## -- get basic data
  my ($short,$long,$descr,$type,$default,$required) =
    @$opt{qw(short long descr type default required)};
  $type = 'funct' if (!defined($type));
  $long = '-' if (!defined($long));
  $short = '-' if (!defined($short));
  $descr = '???' if (!defined($descr));
  #$default = 0 if (!defined($default));
  $required = 0 if (!defined($required));
  $long = string_value($long);
  $short = string_value($short);
  $descr = string_value($descr);
  $default = string_value($default);

  my $optid = "$short|$long";
  ## -- sanity check(s)
  if (exists($og->{optshort}{$short})
      && exists($og->{optlong}{$long})
      && $og->{optshort}{$short} eq $optid
      && $og->{optlong}{$long}  eq $optid) {
    $og->complain("option '$optid' multiply specified -- overriding.");
  }
  elsif ($short ne '-' && exists($og->{optshort}{$short})) {
    return $og->wigout
      ("conflict for short option '$short': old=($og->{optshort}{$short}), new=($optid)");
  }
  elsif ($long ne '-' && exists($og->{optlong}{$long})) {
    return $og->wigout
      ("conflict for long option $long: old=($og->{optlong}{$long}), new=($optid)");
  } else {
    ## -- add the option to our list
    push(@{$og->{optl}},$optid);
  }

  ## -- type-dependent initialization
  if ($type eq 'funct') {
    ## -- funct ('funct-opt')
    $default       = 0;
    $opt->{cname}  = long2cname($long ne '-' ? $long : $short)
      if (!defined($opt->{cname}));
    $opt->{cgiven} = cname2given($opt->{cname})
      if (!defined($opt->{cgiven}));
  }
  elsif ($type eq 'flag' || $type eq 'flag2') {
    ## -- flag
    $opt->{cname}  = long2cname($long ne '-' ? $long : $short).'_flag'
      if (!defined($opt->{cname}));
    $opt->{cgiven} = cname2given($opt->{cname})
      if (!defined($opt->{cgiven}));

    $default = 0 if (!defined($default));
  }
  elsif ($type eq 'string') {
    ## -- strings
    $opt->{cname}  = long2cname($long ne '-' ? $long : $short).'_arg'
      if (!defined($opt->{cname}));
    $opt->{cgiven} = cname2given($opt->{cname})
      if (!defined($opt->{cgiven}));

    $default = 'NULL' if (!defined($default));

    # argument name
    if (!defined($opt->{arg})) {
      $opt->{arg} = $type;
      $opt->{arg} =~ tr/a-z/A-Z/;
    }
  }
  elsif ($type eq 'int' || $type eq 'short' || $type eq 'long') {
    ## -- integer types
    $opt->{cname}  = long2cname($long ne '-' ? $long : $short).'_arg'
      if (!defined($opt->{cname}));
    $opt->{cgiven} = cname2given($opt->{cname})
      if (!defined($opt->{cgiven}));

    $default = 0 if (!defined($default));

    # argument name
    if (!defined($opt->{arg})) {
      $opt->{arg} = $type;
      $opt->{arg} =~ tr/a-z/A-Z/;
    }
  }
  elsif ($type eq 'float' || $type eq 'double' || $type eq 'longdouble') {
    ## -- floating-point types
    $opt->{cname}  = long2cname($long ne '-' ? $long : $short).'_arg'
      if (!defined($opt->{cname}));
    $opt->{cgiven} = cname2given($opt->{cname})
      if (!defined($opt->{cgiven}));

    $default = 0 if (!defined($default));

    # argument name
    if (!defined($opts->{arg})) {
      $opt->{arg} = $type;
      $opt->{arg} =~ tr/a-z/A-Z/;
    }
  }
  else {
    return $og->wigout("option $optid: option-type '$argtype' unknown -- ignoring.");
  }

  ## -- add option information to $og
  $og->{optshort}{$short} = $optid if ($short ne '-');
  $og->{optlong}{$long}   = $optid if ($long ne '-');

  @$opt{qw(long short id)}      = ($long,$short,$optid);
  @$opt{qw(descr type default)} = ($descr,$type,$default);
  @$opt{qw(group ctype)}        = ($og->{group},otype2ctype($opt->{type}));

  $og->{opth}{$optid} = $opt;
  #push(@{$og->{optl}}, $optid); #-- above

  return $optid;
}


# $group = $og->add_group($groupname)
#  + adds a group
sub add_group {
  my ($og,$group) = @_;
  $og->wigout("undefined group name in add_group()")
    if (!defined($group));
  $og->{group} = $group;
}

# $arg = $og->add_argument({name=>$argname,descr=>$argdescr})
#  + implicitly turns on 'unnamed'
sub add_argument {
  my ($og,$arg) = @_;
  $og->wigout("undefined argument-name in add_argument()")
    if (!defined($arg->{name}));
  $og->{unnamed} = 1;
  $arg->{descr} = '???' if (!defined($arg->{descr}));
  push(@{$og->{args}},$arg);
}

sub set_reparse_action {
  my ($og,$action) = @_;
  if (!grep { $_ eq $action } qw(error warn clobber)) {
    $og->complain("unknown reparse action '$_' -- ignoring");
    return $og->{reparse_action};
  }
  $og->{reparse_action} = $action;
}

# $code = $og->add_user_code($code_string)
#  + add literal code section
sub add_user_code {
  my ($og,$code) = @_;
  if (defined($og->{user_code})) {
    $og->{user_code} .= $code;
  } else {
    $og->{user_code} = $code;
  }
  return $og->{user_code};
}


# $rcfiles = $og->add_rcfile($filename)
#  + add a degault global .rc file
sub add_rcfile {
  my ($og,$rcfile) = @_;
  push(@{$og->{rcfiles}}, $rcfile);
  return $og->{rcfiles};
}


###############################################################
# Parse::Lex <-> Parse::Yapp interface
# - CONVENTIONS for yylex() sub:
#   + if the token's associated action is \&yyignore (a dummy sub),
#     we don't return to the parser, but keep gobbling
#
# - REQUIREMENTS on yylex() sub:
#   + Yapp-compatible lexing routine
#   + reads input and returns token values to the parser
#   + our only argument ($MyParser) is the Parse::Yapp object itself
#   + We return a list ($TOKENTYPE, $TOKENVAL) of the next tokens
#     to the parser
#   + on end-of-input, we should return the list ('', undef)
###############################################################

# undef = $og->reset();
#   + reset all parse-relevant data structures
sub reset {
  $_[0]->{errstr} = undef;
  $_[0]->{lexer}->reset;
  delete($_[0]->{parser}{USER}{hint});
}

# undef = yyignore()
#   + dummy function
sub yyignore { $_[1]; }

# \&lexer_sub = $og->_yylex_sub()
#   + returns a Parse::Yapp-friendly lexer subroutine
sub _yylex_sub {
  my $og = shift;
  my $lexer = $og->{lexer};
  my ($token,$name,$text,$bracedepth);

  return sub {
    while (1) {
      return ('',undef) if ($lexer->eoi || !defined($token = $lexer->next()) );
      last unless (defined($token->action) && $token->action eq \&yyignore);
    }

    ($name,$text) = ($token->name,$token->text);
    #print STDERR "LEXER: name=$name ; text=$text\n"; ##-- DEBUG


    ## -- handle (nested) braces
    if ($name eq 'LBRACE') {
      my $bline = $lexer->line;
      $lexer->start('BRACED');
      $bracedepth = 1;
      #print STDERR "> LBRACE(bd=1)='$text'\n";
      while (!$lexer->eoi && defined($token = $lexer->next())) {
	$text .= $token->text();
	$name = $token->name();
	#print STDERR "> $name(bd=$bracedepth)='",$token->text(),"'\n";
	if ($name eq 'LBRACE') {
	  $bracedepth++;
	  #print STDERR ("> ++(bd=$bracedepth)\n");
	}
	elsif ($name eq 'RBRACE') {
	  $bracedepth--;
	  #print STDERR ("> --(bd=$bracedepth)\n");
	  if (!$bracedepth) {
	    $lexer->end('BRACED');
	    last;
	  }
	}
      }
      if ($lexer->eoi || !defined($token)) {
	$og->wigout("EOI while parsing braced string (started at line $bline)");
      }
      $text =~ s/^\{//;
      $text =~ s/\}$//;
      return ('BR_STRING',$text);
    }
    return ($name,$text);
  };
}



###############################################################
# Parsing: errors
#   + Yapp error sub called as '&sub($yapp_parser)'
#   + conventions:
#     - allow user-hint codes for parse errors in
#       $yapp_parser->{USER}{hint}
#     - hints override default error-reporting format
###############################################################

# lexer_error($lexer)
#   + reports tokenization errors
sub lexer_error {
  my $og = shift;
  return sub {
    my $err = $og->_gen_error('LEXER_ERROR',
			      {
			       __LINE__ => $og->{lexer}->line,
			       __COL__ => $og->{lexer}->pos,
			       __CURTEXT__ => $_[1],
			       __FILE__ => (defined($og->{infile}) ? $og->{infile} : '???'),
			       __NAME__ => (defined($og->{name}) ? $og->{name} : __PACKAGE__ ),
			       (($_[1] =~ /[^$OG_ANY]/)
				? (__HINT__ => 'ILLEGAL_CHAR',
				   __MATCH__ => $&)
				: (__HINT__ => 'UNKNOWN_LEXER_HINT'))
			      });
    $og->{parser}->YYAbort() if (defined($og->{parser}));
    if ($VERBOSE) {
      confess(">>> ", __PACKAGE__ , "::lexer_error() called") if ($VERBOSE);
    } else {
      die($err);
    }
  };
}

# $errstr = $qp->_gen_error($base, \%macros)
#  + generates an error message based on the string $base
#  + all occurrences of any of the strings which occur as keys
#    of the hashref \%macros are expanded to (the translations of)
#    their corresponding values.
sub _gen_error {
  my ($og,$errmsg,$macros) = @_;
  $errmsg = $og->nl_xlate($errmsg);
  my $changed = 1;
  my %nlmacros = map { ($_ => $og->nl_xlate($macros->{$_})) } keys(%$macros);
  while ($changed) {
    $changed = 0;
    foreach (keys(%nlmacros)) {
      if (!defined($nlmacros{$_})) {
	carp(__PACKAGE__ , "::_gen_error(): some goofball forgot to translate '$_'!");
	next;
      }
      $changed = 1 if ($errmsg =~ s/$_/$nlmacros{$_}/g);
    }
  }
  return $errmsg;
}

# \&error_sub = $og->_yyerror_sub()
#   + returns a Parse::Yapp-friendly error-catching subroutine
sub _yyerror_sub {
  my $og = shift;
  return sub {
    die($og->_gen_error((defined($_[0]->{USER}{hint})
			 ? 'SEMANTIC_ERROR'
			 : 'SYNTAX_ERROR'),
			{
			 __NAME__ => (defined($og->{name}) ? $og->{name} : __PACKAGE__ ),
			 __FILE__ => (defined($og->{infile}) ? $og->{infile} : '???'),
			 __LINE__ => $og->{lexer}->line,
			 __COL__ => $og->{lexer}->pos,
			 __CURTEXT__ => $_[0]->YYCurval,
			 __CURTOK__ => $og->nl_xlate($_[0]->YYCurtok),
			 (defined($_[0]->{USER}{hint})
			  ? (__HINT__ => $_[0]->{USER}{hint})
			  : qw()),
			 __EXPECTED__ =>
			   join(', ',
				map { 
				  my $xl = $og->nl_xlate($_);
				  $xl ? $xl : qw()
				} $_[0]->YYExpect),
			}));
  };
}

# $nl_string = $og->nl_xlate($symbol)
#  + returns a natural-language string for $symbol, if
#    one is available in the package-global '%NL_XLATE' hash
sub nl_xlate {
  my $nlx = \%{ref($_[0]).'::NL_XLATE'};
  return
    (defined($_[1]) && exists($nlx->{$_[1]})
     ? $nlx->{$_[1]}
     : $_[1]);
}


###############################################################
# older METHODS : error-reporting (still used)
###############################################################

# $undef = $og->complain(@msg)
#   + like carp(), but reports position in input file
sub complain {
  my ($og,@msg) = @_;
  print STDERR ("$og->{name}: Warning: ",
		(## -- input details
		 defined($og->{infh})
		 ? (## -- filename
		    ($og->{infile} eq '-' ? "<stdin>" : "'$og->{infile}'"),
		    ## -- input line-number
		    ", line ", $og->{infh}->input_line_number(),
		    ": ")
		 : qw()),
		@msg,
		($msg[$#msg] !~ /\n$/s ? "\n" : qw()),
	       );
  carp(">>> ", __PACKAGE__ , "::complain() called") if ($VERBOSE);
}

# $undef = $og->wigout(@msg)
#   + like croak(), but reports position in input file
sub wigout {
  my ($og,@msg) = @_;
  print STDERR ("$og->{name}: Warning: ",
		(## -- input details
		 defined($og->{infh})
		 ? (## -- filename
		    ($og->{infile} eq '-' ? "<stdin>" : "'$og->{infile}'"),
		    ## -- input line-number
		    ", line ", $og->{infh}->input_line_number(),
		    ": ")
		 : qw()),
		@msg,
		($msg[$#msg] !~ /\n$/s ? "\n" : qw()),
	       );
  confess(">>> ", __PACKAGE__ , "::wigout() called:\n") if ($VERBOSE);
  exit(1);
}

###############################################################
# DEBUG METHODS: dump
###############################################################

# @list = $og->dump();
# @list = $og->dump($name);
sub dump {
  my ($og,$name) = @_;
  $name = $og->{name} if (!defined($name));
  if ($name eq __PACKAGE__ || $name eq ref($og)) {
    $name = "$og"; ## -- default: stringify
  }
  eval "use Data::Dumper";
  return Data::Dumper->Dump([$og],[$name]);
}

###############################################################
# NON-METHOD SUBS : utilities
###############################################################

# $unquoted = dequote($txt,$quote);
#  + i.e. $string = dequote('"', '"string"');
sub dequote {
  my ($txt,$quote) = @_;
  $txt =~ s/^$quote//;
  $txt =~ s/$quote$//;
  $txt =~ s/\\$quote/$quote/g;
  return $txt;
}

# $unquoted = bq_dequote($txt,$backquoted_string);
#  + i.e. $string = bq_dequote('`', '`string`');
sub bq_dequote {
  my ($txt,$bquote) = @_;
  $txt =~ s/^$bquote//;
  $txt =~ s/$bquote$//;
  $txt =~ s/\\$bquote/$bquote/g;
  return join("", `$txt`);
}

# $pod_string = podify($str)
sub podify {
  my $str = shift;
  return '\'undef\'' if (!defined($str));
  $str =~ s/([\<\>])/E<$1>/g;
  $str =~ s/E<<>/E<lt>/g;
  $str =~ s/E<>>/E<gt>/g;
  #... other escapes here
  return $str;
}

# $str_or_empty = is_string($str)
#   + quasi double-quoted string-checker
sub is_string {
  my $str = shift;
  return $str =~ /^\"(?:[^\"]|(?:\\\"))*\"$/s;
}

# string_value($string)
#  + removes quotes
sub string_value {
  my $str = shift;
  return undef if (!defined($str));
  $str =~ s/^\"//s;
  $str =~ s/\"$//s;
  return $str;
}

# $bool = is_bool($str)
#   + check if string is a boolean
sub is_bool {
  my $str = shift;
  return undef if (!defined($str));
  return ($str eq 'yes' || $str eq 'no');
}

# $bool_value_or_undef = bool_value($str)
#   + return integer boolean-value of string
sub bool_value {
  my $str = shift;
  return undef if (!defined($str));
  return 1 if ($str eq 'yes');
  return 0 if ($str eq 'no');
  return undef;
}

# $bool = is_onoff($str)
#   + check if string is an on/off flag
sub is_onoff {
  my $str = shift;
  return undef if (!defined($str));
  return ($str eq 'on' || $str eq 'off');
}

# $bool_value_or_undef = onoff_value($str)
#   + return integer boolean-value of an on/off-string
sub onoff_value {
  my $str = shift;
  return undef if (!defined($str));
  return 1 if ($str eq 'on');
  return 0 if ($str eq 'off');
  return undef;
}

# $bool = is_intstring($str)
#   + returns true if $str eq "$i" for some $i \in Z, false otherwise.
#   + hack: also accepts plain ints
sub is_intstring {
  my $str = shift;
  return undef if (!defined($str));
  return $str =~ /^\s*\"?\s*(?:[+-]?)\d+\s*\"?\s*$/;
}

# $int_or_undef = intstring_value($str)
#   + get integer-value from an intstring
sub intstring_value {
  my $str = shift;
  return undef if (!defined($str));
  return $str =~ /^\s*\"?\s*(?:[+-]?)(\d+)\s*\"?\s*$/ ? $1 : undef;
}

# $bool = is_floatstring($str)
#   + returns true if $str eq "$f" for some $f \in R, false otherwise.
#   + hack: also accepts plain floats
sub is_floatstring {
  my $str = shift;
  return undef if (!defined($str));
  return $str =~ /^\s*\"?\s*[+-]?\d*\.?\d+\s*\"?\s*$/;
}

# $float_or_undef = floatstring_value($str)
#   + get floating-point-value from a float-string
sub floatstring_value {
  my $str = shift;
  return undef if (!defined($str));
  return $str =~ /^\s*\"?\s*([+-]?\d*\.?\d+)\s*\"?\s*$/ ? $1 : undef;
}

# $cname = long2cname($longname_string)
sub long2cname {
  my $long = string_value(shift);
  $long =~ s/[[:punct:]\s]/\_/g;
  return $long;
}

# $cgiven = cname2given($cname)
sub cname2given {
  my $name = shift;
  return undef if (!defined($name));
  if ($name =~ /(.*)_(?:arg|flag)$/) {
    $name = $1.'_given';
  } else {
    $name = $name._given;
  }
  return $name;
}

# $ctype = otype2ctype($otype)
sub otype2ctype {
  my $otype = shift;
  return 'char *' if ($otype eq 'string');
  return 'int' if ($otype eq 'flag' || $otype eq 'flag2');
  return undef if ($otype eq 'funct');
  return $otype;
}



1; ## -- make perl happy

__END__

###############################################################
=pod

=head1 NAME

Getopt::Gen - extended module for gengetopt-like parsing.

=head1 SYNOPSIS

 use Getopt::Gen;

 $og = Getopt::Gen->new({...});                # create a new object

 $og->parse($filename);                        # parse a program specification file
 $og->parse(\*HANDLE);                         # ... or a filehandle

 $og->fill_in(TYPE=>'FILE',SOURCE=>$filename); # Fill in a Text::Template skeleton
                                               # + You don't need 'TYPE' and 'SOURCE'
                                               #   arguments if you use a subclass
                                               #   such as Getopt::Gen::cmdline_h.

=cut

###############################################################
# Description
###############################################################
=pod

=head1 DESCRIPTION

Parse extended 'gengetopt'-style option files, and
fill in output templates based on the parsed values.

=cut

###############################################################
# Variables
###############################################################
=pod

=head1 PACKAGE VARIABLES

=over 4

=item * C<%DEFAULT_TEMPLATE_ARGS>

Default arguments for creating a new Text::Template object.

=back

=cut


###############################################################
# Methods
###############################################################
=pod

=head1 METHODS

=cut

###############################################################
# Constructor
###############################################################
=pod

=head2 Constructor

=over 4

=item * C<new(%args)>

Creates a new Getopt::Gen object based on keyword-arguments
%args.

Available keywords:

     ## -- basic data
     name=> __PACKAGE__ ,               # name to use for error-reporting

     ## -- generation-flags
     filename=>'cmdline',               # basename of output file
     funcname=>'cmdline_parser',        # name of parsing-function
     structname=>'gengetopt_args_info', # name of parser-structure
     longhelp=>0,                       # long usage line in help ?
     unnamed=>0,                        # allow non-option arguments ?
     reparse_action=>'error',           # when an option is re-given: error|warn|clobber
     handle_help=>1,                    # whether to handle '-h' and '--help' options
     handle_version=>1,                 # whether to handle '-V' and '--version' options
     handle_error=>1,                   # whether to exit on errors

=back

=cut


###############################################################
# Parsing Methods
###############################################################
=pod

=head2 Parsing Methods

=over 4

=item * C<parse_options($file)>

Parses an option-specification file.
$file may be either a filename or an open filehandle.
See L<optgen.perl> for details on the file
format.

=back

=cut


###############################################################
# Generation Methods
###############################################################
=pod

=head2 Generation Methods

=over 4

=item * C<$og-E<gt>fill_in(\%args)>

Generate a source file based on a skeleton
using Text::Template.  \%args may be used
to override the default values for the
Text::Template::new() and/or fill_in() methods.

=back

=cut

###############################################################
# Bugs
###############################################################
=pod

=head1 BUGS

Probably many.

=cut


###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

'gengetopt' was originally written by Roberto Arturo Tena Sanchez,
and it is currently maintained by Lorenzo Bettini.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2016 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Getopt::Gen::cmdline_pod(3pm)|Getopt::Gen::cmdline_pod>,
L<Getopt::Gen::cmdline_h(3pm)|Getopt::Gen::cmdline_h>,
L<Getopt::Gen::cmdline_c(3pm)|Getopt::Gen::cmdline_c>,
L<Getopt::Gen::Parser(3pm)|Getopt::Gen::Parser>,
L<Text::Template(3pm)|Text::Template>,
L<perl(1)|perl>.

=cut
