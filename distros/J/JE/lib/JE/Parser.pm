package JE::Parser;

our $VERSION = '0.066';

use strict;  # :-(
use warnings;# :-(
no warnings 'utf8';

use Scalar::Util 'blessed';

require JE::Code  ;
require JE::Number; # ~~~ Don't want to do this

import JE::Code 'add_line_number';
sub add_line_number;

our ($_parser, $global, @_decls, @_stms, $_vars);

#----------METHODS---------#

sub new {
	my %self = (
		stm_names => [qw[
			-function block empty if while with for switch try
			 labelled var do continue break return throw expr
		]],
		stm => {
			-function => \&function,  block    => \&block,
			 empty    => \&empty,     if       => \&if,
			 while    => \&while,     with     => \&with,
			 for      => \&for,       switch   => \&switch,
			 try      => \&try,       labelled => \&labelled,
			 var      => \&var,       do       => \&do,
			 continue => \&continue,  break    => \&break,
			 return   => \&return,    throw    => \&throw,
			 expr     => \&expr_statement,
		},
		global => pop,
	);
	return bless \%self, shift;
}

sub add_statement {
	my($self,$name,$parser) = shift;
	my $in_list;
#	no warnings 'exiting';
	grep $_ eq $name && ++$in_list && goto END_GREP,
		@{$$self{stm_names}};
	END_GREP: 
	$in_list or unshift @{$$self{stm_names}} ,$name;
	$$self{stm}{$name} = $parser;
	return; # Don't return anything for now, because if we return some-
	        # thing, even if it's not documented, someone might start
		# relying on it.
}

sub delete_statement {
	my $self = shift;
	for my $name (@_) {
		delete $$self{stm}{$name};
		@{$$self{stm_names}} =
			grep $_ ne $name, @{$$self{stm_names}};
	}
	return $self;
}

sub statement_list {
	$_[0]{stm_names};
}

sub parse {
	local $_parser = shift;
	local(@_decls, @_stms); # Doing this here and localising it saves
	for(@{$_parser->{stm_names}}) { # us from having to do it multiple
		push @{/^-/ ? \@_decls : \@_stms}, # times.
			$_parser->{stm}{$_};
	}

	JE::Code::parse($_parser->{global}, @_);
}

sub eval {
	shift->parse(@_)->execute
}

#----------PARSER---------#

use Exporter 5.57 'import';

our @EXPORT_OK = qw/ $h $n $optional_sc $ss $s $S $id_cont
                     str num skip ident expr expr_noin statement
                     statements expected optional_sc/;
our @EXPORT_TAGS = (
	vars => [qw/ $h $n $optional_sc $ss $s $S $id_cont/],
	functions => [qw/ str num skip ident expr expr_noin statement
                          statements expected optional_sc /],
);

use re 'taint';
#use subs qw'statement statements assign assign_noin expr new';
use constant JECE => 'JE::Code::Expression';
use constant JECS => 'JE::Code::Statement';

require JE::String;
import JE::String 'desurrogify';
import JE::String 'surrogify';
sub desurrogify($);
sub surrogify($);


# die is called with a scalar ref when the  string  contains  what  is
# expected. This will be converted to a longer message afterwards, which
# will read something like "Expected %s but found %s"  (probably the most
# common error message, which is why there is a shorthand). Using an array
# ref is the easiest way to stop the 'at ..., line ...' from being appended
# when there is no line break at the end already.  die  is  called  with  a
# double reference to a  string  if  the  string  is  the  complete  error
# message.
# ~~~ We may need a function for this second usage, in case we change the
#     \\ yet again.

# @ret != push @ret, ...  is a funny way of pushing and then checking to
# see whether anything was pushed.


sub expected($) { # public
	die \shift
}


# public vars:

# optional horizontal comments and whitespace
our $h = qr(
	(?> [ \t\x0b\f\xa0\p{Zs}]* ) 
	(?> (?>/\*[^\cm\cj\x{2028}\x{2029}]*?\*/) [ \t\x0b\f\xa0\p{Zs}]* )?
)x;

# line terminators
our $n = qr((?>[\cm\cj\x{2028}\x{2029}]));

# single space char
our $ss = qr((?>[\p{Zs}\s\ck\x{2028}\x{2029}]));

# optional comments and whitespace
our $s = qr((?>
	(?> $ss* )
	(?> (?> //[^\cm\cj\x{2028}\x{2029}]* (?>$n|\z) | /\*.*?\*/ )
	    (?> $ss* )
	) *
))sx;

# mandatory comments/whitespace
our $S = qr(
	(?>
	  $ss
	    |
	  //[^\cm\cj\x{2028}\x{2029}]*
	    |
	  /\*.*?\*/
	)
	$s
)xs;

our $id_cont = qr(
	(?>
	  \\u([0-9A-Fa-f]{4})
	    |
	  [\p{ID_Continue}\$_]
	)
)x;

# end public vars


sub str() { # public
        # For very long strings (>~45000), this pattern hits a perl bug (Complex regular subexpression recursion limit (32766) exceeded) 
	#/\G (?: '((?>(?:[^'\\] | \\.)*))'
	#          |
	#        "((?>(?:[^"\\] | \\.)*))"  )/xcgs or return;
	# There are two solutions:
	# 1) Use the unrolling technique from the Owl Book.
	# 2) Use shorter patterns but more code (contributed by Kevin
	#    Cameron)
	# Number 1 should be faster, but it crashes under perl 5.8.8 on
	# Windows, and perhaps on other platforms, too. So we use #2 for
	# 5.8.x regardless of platform to be on the safe side.

	use constant old_perl => $] < 5.01;        # Use a constant so the
	my $yarn;                                   # if-block disappears
	if(old_perl) {                              # at compile-time.
		# Use a simpler pattern (but more code) to break strings up
		# into extents bounded by the quote or escape
		my $qt = substr($_,pos($_),1);
		$qt =~ /['"]/ or return; # not a string literal if first
		pos($_)++;               # char not a quote
		my $done = 0;
		while (defined(substr($_,pos($_),1))) {
		    my ($part) = /\G([^\\$qt]*)/xcgs;
		    defined($part) or $part = "";
		    $yarn .= $part;
		    my $next = substr($_,pos($_)++,1);

		    if ($next eq "\\") {
		        #pass on any escaped char
		        $next = substr($_,pos($_)++,1);
		        $yarn .= "\\$next";
		    } else {
		        # handle end quote
		        $done = 1;
		        last;
		    }
		}

		# error if EOF before end of string
        	return if !$done;
	}
	else {
		/\G (?: '([^'\\]*(?:\\.[^'\\]*)*)'
		          |
		        "([^"\\]*(?:\\.[^"\\]*)*)"  )/xcgs or return;
		$yarn = $+;
	}
# Get rid of that constant, as it’s no longer needed.
BEGIN { no strict; delete ${__PACKAGE__.'::'}{old_perl}; }

        # transform special chars
	no re 'taint'; # I need eval "qq-..." to work
	$yarn =~ s/\\(?:
		u([0-9a-fA-F]{4})
		 |
		x([0-9a-fA-F]{2})
		 |
                (\r\n?|[\n\x{2028}\x{2029}])
		 |
		([bfnrt])
		 |
		(v)
		 |
		([0-3][0-7]{0,2}|[4-7][0-7]?) # actually slightly looser
		 |                    # than what ECMAScript v3 has in its
		(.)           # addendum (it forbids \0 when followed by 8)
	)/
		$1 ? chr(hex $1) :
		$2 ? chr(hex $2) :
                $3 ? "" :               # escaped line feed disappears
		$4 ? eval "qq-\\$4-" :
		$5 ? "\cK" :
		defined $6 ? chr oct $6 :
		$7
	/sgex;
	"s$yarn";
}

sub  num() { # public
	/\G (?:
	  0[Xx] ([A-Fa-f0-9]+)
	    |
	  0 ([01234567]+)
	    |
	  (?=[0-9]|\.[0-9])
	  (
	    (?:0|[1-9][0-9]*)?
	    (?:\.[0-9]*)?
	    (?:[Ee][+-]?[0-9]+)?
	  )
	) /xcg
	or return;
	return defined $1 ? hex $1 : defined $2 ? oct $2 : $3;
}

our $ident = qr(
          (?! (?: case | default )  (?!$id_cont) )
	  (?:
	    \\u[0-9A-Fa-f]{4}
	      |
	    [\p{ID_Start}\$_]
	  )
	  (?> $id_cont* )
)x;

sub unescape_ident($) {
	my $ident = shift;
	$ident =~ s/\\u([0-9a-fA-F]{4})/chr hex $1/ge;
	$ident = desurrogify $ident;
	$ident =~ /^[\p{ID_Start}\$_]
	            [\p{ID_Continue}\$_]*
	          \z/x
	  or die \\"'$ident' is not a valid identifier";
	$ident;
}

 # public
sub skip() { /\G$s/g } # skip whitespace

sub ident() { # public
	return unless my($ident) = /\G($ident)/cgox;
	unescape_ident $ident;
}

sub params() { # Only called when we know we need it, which is why it dies
                # on the second line
	my @ret;
	/\G\(/gc or expected "'('";
	&skip;
	if (@ret != push @ret, &ident) { # first identifier (not prec.
	                               # by comma)
		while (/\G$s,$s/gc) {
			# if there's a comma we need another ident
			@ret != push @ret, &ident or expected 'identifier';
		}
		&skip;
	}
	/\G\)/gc or expected "')'";
	\@ret;
}

sub term() {
	my $pos = pos;
	my $tmp;
	if(/\Gfunction(?!$id_cont)$s/cg) {
		my @ret = (func => ident);
		@ret == 2 and &skip;
		push @ret, &params;
		&skip;
		/\G \{ /gcx or expected "'{'";
		{
			local $_vars = [];
			push @ret, &statements, $_vars;
		}
		/\G \} /gocx or expected "'}'";

		return bless [[$pos, pos], @ret], JECE;
	}
	# We don’t call the ident subroutine here,
	# because we need to sift out null/true/false/this.
	elsif(($tmp)=/\G($ident)/cgox) {
		$tmp=~/^(?:(?:tru|fals)e|null)\z/ &&return $global->$tmp;
		$tmp eq 'this' and return $tmp;
		return "i" . unescape_ident $tmp;
	}
	elsif(defined($tmp = &str) or
	      defined($tmp = &num)) {
		return $tmp;
	}
	elsif(m-\G
		/
		( (?:[^/*\\[] | \\. | \[ (?>(?:[^]\\] | \\.)*) \] )
		  (?>(?:[^/\\[] | \\. | \[ (?>(?:[^]\\] | \\.)*) \] )*) )
		/
	  	($id_cont*)
	      -cogx ) {

		#  I have to use local *_ because
		# 'require JE::Object::RegExp' causes
		#  Scalar::Util->import() to be called (import is inherited
		#  from Exporter), and  &Exporter::import does  'local $_',
		#  which,  in p5.8.8  (though not  5.9.5)  causes  pos()
		#  to be reset.
		{ local *_; require JE::Object::RegExp; }
# ~~~ This needs to unescape the flags.
		return JE::Object::RegExp->new( $global, $1, $2);
	}
	elsif(/\G\[$s/cg) {
		my $anon;
		my @ret;
		my $length;

		while () {
			@ret != ($length = push @ret, &assign) and &skip;
			push @ret, bless \$anon, 'comma' while /\G,$s/cg;
			$length == @ret and last;
		}

		/\G]/cg or expected "']'";
		return bless [[$pos, pos], array => @ret], JECE;
	}
	elsif(/\G\{$s/cg) {
		my @ret;

		if($tmp = &ident or defined($tmp = &str)&&$tmp=~s/^s// or
				defined($tmp = &num)) {
			# first elem, not preceded by comma
			push @ret, $tmp;
			&skip;
			/\G:$s/cggg or expected 'colon';
			@ret != push @ret, &assign
				or expected \'expression';
			&skip;

			while (/\G,$s/cg) {
				$tmp = ident
				or defined($tmp = &str)&&$tmp=~s/^s// or
					defined($tmp = &num)
				or do {
					# ECMAScript 5 allows a
					# trailing comma
					/\G}/cg or expected
					 "'}', identifier, or string or ".
					 " number literal";
					return bless [[$pos, pos],
					              hash => @ret], JECE;
				};

				push @ret, $tmp;
				&skip;
				/\G:$s/cggg or expected 'colon';
				@ret != push @ret, &assign
					or expected 'expression';
				&skip;
			}
		}
		/\G}/cg or expected "'}'";
		return bless [[$pos, pos], hash => @ret], JECE;
	}
	elsif (/\G\($s/cg) {
		my $ret = &expr or expected 'expression';
		&skip;
		/\G\)/cg or expected "')'";
		return $ret;
	}
	return
}

sub subscript() { # skips leading whitespace
	my $pos = pos;
	my $subscript;
	if (/\G$s\[$s/cg) {
		$subscript = &expr or expected 'expression';
		&skip;
		/\G]/cog or expected "']'";
	}
	elsif (/\G$s\.$s/cg) {
		$subscript = &ident or expected 'identifier';
	} 
	else { return }

	return bless [[$pos, pos], $subscript], 'JE::Code::Subscript';
}

sub args() { # skips leading whitespace
	my $pos = pos;
	my @ret;
	/\G$s\($s/gc or return;
	if (@ret != push @ret, &assign) { # first expression (not prec.
	                               # by comma)
		while (/\G$s,$s/gc) {
			# if there's a comma we need another expression
			@ret != push @ret, &assign
				or expected 'expression';
		}
		&skip;
	}
	/\G\)/gc or expected "')'";
	return bless [[$pos, pos], @ret], 'JE::Code::Arguments';
}

sub new_expr() {
	/\G new(?!$id_cont) $s /cgx or return;
	my $ret = bless [[pos], 'new'], JECE;
	
	my $pos = pos;
	my @member_expr = &new_expr || &term
		|| expected "identifier, literal, 'new' or '('";

	0 while @member_expr != push @member_expr, &subscript;

	push @$ret, @member_expr == 1 ? @member_expr :
		bless [[$pos, pos], 'member/call', @member_expr],
		      JECE;
	push @$ret, args;
	$ret;
}

sub left_expr() {
	my($pos,@ret) = pos;
	@ret != push @ret, &new_expr || &term or return;

	0 while @ret != push @ret, &subscript, &args;
	@ret ? @ret == 1 ? @ret : 
		bless([[$pos, pos], 'member/call', @ret],
			JECE)
		: return;
}

sub postfix() {
	my($pos,@ret) = pos;
	@ret != push @ret, &left_expr or return;
	push @ret, $1 while /\G $h ( \+\+ | -- ) /cogx;
	@ret == 1 ? @ret : bless [[$pos, pos], 'postfix', @ret],
		JECE;
}

sub unary() {
	my($pos,@ret) = pos;
	push @ret, $1 while /\G $s (
	    (?: delete | void | typeof )(?!$id_cont)
	      |
	    \+\+? | --? | ~ | !
	) $s /cgx;
	@ret != push @ret, &postfix or (
		@ret
		? expected "expression"
		: return
	);
	@ret == 1 ? @ret : bless [[$pos, pos], 'prefix', @ret],
		JECE;
}

sub multi() {
	my($pos,@ret) = pos;
	@ret != push @ret, &unary or return;
	while(m-\G $s ( [*%](?!=) | / (?![*/=]) ) $s -cgx) {
		push @ret, $1;
		@ret == push @ret, &unary and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub add() {
	my($pos,@ret) = pos;
	@ret != push @ret, &multi or return;
	while(/\G $s ( \+(?![+=]) | -(?![-=]) ) $s /cgx) {
		push @ret, $1;
		@ret == push @ret, &multi and expected 'expression'
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bitshift() {
	my($pos,@ret) = pos;
	@ret == push @ret, &add and return;
	while(/\G $s (>>> | >>(?!>) | <<)(?!=) $s /cgx) {
		push @ret, $1;
		@ret == push @ret, &add and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub rel() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bitshift and return;
	while(/\G $s ( ([<>])(?!\2|=) | [<>]= |
	               in(?:stanceof)?(?!$id_cont) ) $s /cgx) {
		push @ret, $1;
		@ret== push @ret, &bitshift and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub rel_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bitshift and return;
	while(/\G $s ( ([<>])(?!\2|=) | [<>]= | instanceof(?!$id_cont) )
	          $s /cgx) {
		push @ret, $1;
		@ret == push @ret, &bitshift and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub equal() {
	my($pos,@ret) = pos;
	@ret == push @ret, &rel and return;
	while(/\G $s ([!=]==?) $s /cgx) {
		push @ret, $1;
		@ret == push @ret, &rel and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub equal_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &rel_noin and return;
	while(/\G $s ([!=]==?) $s /cgx) {
		push @ret, $1;
		@ret == push @ret, &rel_noin and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_and() {
	my($pos,@ret) = pos;
	@ret == push @ret, &equal and return;
	while(/\G $s &(?![&=]) $s /cgx) {
		@ret == push @ret, '&', &equal and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_and_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &equal_noin and return;
	while(/\G $s &(?![&=]) $s /cgx) {
		@ret == push @ret, '&', &equal_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_or() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_and and return;
	while(/\G $s \|(?![|=]) $s /cgx) {
		@ret == push @ret, '|', &bit_and and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_or_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_and_noin and return;
	while(/\G $s \|(?![|=]) $s /cgx) {
		@ret == push @ret, '|', &bit_and_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_xor() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_or and return;
	while(/\G $s \^(?!=) $s /cgx) {
		@ret == push @ret, '^', &bit_or and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub bit_xor_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_or_noin and return;
	while(/\G $s \^(?!=) $s /cgx) {
		@ret == push @ret, '^', &bit_or_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub and_expr() { # If I just call it 'and', then I have to write
                 # CORE::and for the operator! (Far too cumbersome.)
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_xor and return;
	while(/\G $s && $s /cgx) {
		@ret == push @ret, '&&', &bit_xor
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub and_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &bit_xor_noin and return;
	while(/\G $s && $s /cgx) {
		@ret == push @ret, '&&', &bit_xor_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub or_expr() {
	my($pos,@ret) = pos;
	@ret == push @ret, &and_expr and return;
	while(/\G $s \|\| $s /cgx) {
		@ret == push @ret, '||', &and_expr
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub or_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &and_noin and return;
	while(/\G $s \|\| $s /cgx) {
		@ret == push @ret, '||', &and_noin
			and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'lassoc', @ret],
		JECE;
}

sub assign() {
	my($pos,@ret) = pos;
	@ret == push @ret, &or_expr and return;
	while(m@\G $s ((?>(?: [-*/%+&^|] | << | >>>? )?)=) $s @cgx) {
		push @ret, $1;
		@ret == push @ret, &or_expr and expected 'expression';
	}
	if(/\G$s\?$s/cg) {
		@ret == push @ret, &assign and expected 'expression';
		&skip;
		/\G:$s/cg or expected "colon";
		@ret == push @ret, &assign and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'assign', @ret],
		JECE;
}

sub assign_noin() {
	my($pos,@ret) = pos;
	@ret == push @ret, &or_noin and return;
	while(m~\G $s ((?>(?: [-*/%+&^|] | << | >>>? )?)=) $s ~cgx) {
		push @ret, $1;
		@ret == push @ret, &or_noin and expected 'expression';
	}
	if(/\G$s\?$s/cg) {
		@ret == push @ret, &assign and expected 'expression';
		&skip;
		/\G:$s/cg or expected "colon";
		@ret == push @ret, &assign_noin and expected 'expression';
	}
	@ret == 1 ? @ret : bless [[$pos, pos], 'assign', @ret],
		JECE;
}

sub expr() { # public
	my $ret = bless [[pos], 'expr'], JECE;
	@$ret == push @$ret, &assign and return;
	while(/\G$s,$s/cg) {
		@$ret == push @$ret,& assign and expected 'expression';
	}
	push @{$$ret[0]},pos;
	$ret;
}

sub expr_noin() { # public
	my $ret = bless [[pos], 'expr'], JECE;
	@$ret == push @$ret, &assign_noin and return;
	while(/\G$s,$s/cg) {
		@$ret == push @$ret, &assign_noin
			and expected 'expression';
	}
	push @{$$ret[0]},pos;
	$ret;
}

sub vardecl() { # vardecl is only called when we *know* we need it, so it
                # will die when it can't get the first identifier, instead
                # of returning undef
	my @ret;
	@ret == push @ret, &ident and expected 'identifier';
	/\G$s=$s/cg and
		(@ret != push @ret, &assign or expected 'expression');
	push @$_vars, $ret[0];
	\@ret;
}

sub vardecl_noin() {
	my @ret;
	@ret == push @ret, &ident and expected 'identifier';
	/\G$s=$s/cg and
		(@ret != push @ret, &assign_noin or expected 'expression');
	push @$_vars, $ret[0];
	\@ret;
}

sub finish_for_sc_sc() {  # returns the last two expressions of a for (;;)
                          # loop header
	my @ret;
	my $msg;
	if(@ret != push @ret, expr) {
		$msg = '';
		&skip
	} else {
		push @ret, 'empty';
		$msg = 'expression or '
	}
	/\G;$s/cg or expected "${msg}semicolon";
	if(@ret != push @ret, expr) {
		$msg = '';
		&skip
	} else {
		push @ret, 'empty';
		$msg = 'expression or '
	}
	/\G\)$s/cg or expected "${msg}')'";

	@ret;
}

# ----------- Statement types ------------ #
#        (used by custom parsers)

our $optional_sc = # public
		qr-\G (?:
		    $s (?: \z | ; $s | (?=\}) )
		      |

		    # optional horizontal whitespace
		    # then a line terminator or a comment containing one
		    # then optional trailing whitespace
		    $h
		    (?: $n | //[^\cm\cj\x{2028}\x{2029}]* $n |
		        /\* [^*\cm\cj\x{2028}\x{2029}]* 
			    (?: \*(?!/) [^*\cm\cj\x{2028}\x{2029}] )*
			  $n
		          (?s:.)*?
		        \*/
		    )
		    $s
		)-x;

sub optional_sc() {
	/$optional_sc/gc or expected "semicolon, '}' or end of line";
}

sub block() {
	/\G\{/gc or return;
	my $ret = [[pos()-1], 'statements'];
	&skip;
	while() { # 'last' does not work when 'while' is a
	         # statement modifier
		@$ret == push @$ret, &statement and last;
	}
	expected "'}'" unless /\G\}$s/gc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub empty() {
	my $pos = pos;
	/\G;$s/cg or return;
	bless [[$pos,pos], 'empty'], JECS;
}

sub function() {
	my $pos = pos;
	/\Gfunction$S/cg or return;
	my $ret = [[$pos], 'function'];
	@$ret == push @$ret, &ident
		and expected "identifier";
	&skip;
	push @$ret, &params;
	&skip;
	/\G \{ /gcx or expected "'{'";
	{
		local $_vars = [];
		push @$ret, &statements, $_vars;
	}
	/\G \}$s /gcx or expected "'}'";

	push @{$$ret[0]},pos;

	push @$_vars, $ret;

	bless $ret, JECS;
}

sub if() {
	my $pos = pos;
	/\Gif$s\($s/cg or return;
	my $ret = [[$pos], 'if'];

	@$ret == push @$ret, &expr
		and expected 'expression';
	&skip;
	/\G\)$s/gc or expected "')'";
	@$ret != push @$ret, &statement
		or expected 'statement';
	if (/\Gelse(?!$id_cont)$s/cg) {
		@$ret == push @$ret, &statement
			and expected 'statement';
	}

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub while() {
	my $pos = pos;
	/\Gwhile$s\($s/cg or return;
	my $ret = [[$pos], 'while'];

	@$ret == push @$ret, &expr
		and expected 'expression';
	&skip;
	/\G\)$s/gc or expected "')'";
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub for() {
	my $pos = pos;
	/\Gfor$s\($s/cg or return;
	my $ret = [[$pos], 'for'];

	if (/\G var$S/cgx) {
		push @$ret, my $var = bless
			[[pos() - length $1], 'var'],
			'JE::Code::Statement';

		push @$var, &vardecl_noin;
		&skip;
		if (/\G([;,])$s/gc) {
			# if there's a comma or sc then
			# this is a for(;;) loop
			if ($1 eq ',') {
				# finish getting the var
				# decl list
				do{
				    @$var ==
				    push @$var, &vardecl 
				    and expected
				      'identifier'
				} while (/\G$s,$s/gc);
				&skip;
				/\G;$s/cg
				   or expected 'semicolon';
			}
			push @$ret, &finish_for_sc_sc;
		}
		else {
			/\Gin$s/cg or expected
			    "'in', comma or semicolon";
			push @$ret, 'in';
			@$ret == push @$ret, &expr
				and expected 'expresssion';
			&skip;
			/\G\)$s/cg or expected "')'";
		}
	}
	elsif(@$ret != push @$ret, &expr_noin) {
		&skip;
		if (/\G;$s/gc) {
			# if there's a semicolon then
			# this is a for(;;) loop
			push @$ret, &finish_for_sc_sc;
		}
		else {
			/\Gin$s/cg or expected
				"'in' or semicolon";
			push @$ret, 'in';
			@$ret == push @$ret, &expr
				and expected 'expresssion';
			&skip;
			/\G\)$s/cg or expected "')'";
		}
	}
	else {
		push @$ret, 'empty';
		/\G;$s/cg
		    or expected 'expression or semicolon';
		push @$ret, &finish_for_sc_sc;
	}

	# body of the for loop
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub with() { # almost identical to while
	my $pos = pos;
	/\Gwith$s\($s/cg or return;
	my $ret = [[$pos], 'with'];

	@$ret == push @$ret, &expr
		and expected 'expression';
	&skip;
	/\G\)$s/gc or expected "')'";
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub switch() {
	my $pos = pos;
	/\Gswitch$s\($s/cg or return;
	my $ret = [[$pos], 'switch'];

	@$ret == push @$ret, &expr
		 and expected 'expression';
	&skip;
	/\G\)$s/gc or expected "')'";
	/\G\{$s/gc or expected "'{'";

	while (/\G case(?!$id_cont) $s/cgx) {
		@$ret == push @$ret, &expr
			and expected 'expression';
		&skip;
		/\G:$s/cg or expected 'colon';
		push @$ret, &statements;
	}
	my $default=0;
	if (/\G default(?!$id_cont) $s/cgx) {
		/\G : $s /cgx or expected 'colon';
		push @$ret, default => &statements;
		++$default;
	}
	while (/\G case(?!$id_cont) $s/cgx) {
		@$ret == push @$ret, &expr
			and expected 'expression';
		&skip;
		/\G:$s/cg or expected 'colon';
		push @$ret, &statements;
	}
	/\G \} $s /cgx or expected (
		$default
		? "'}' or 'case'"
		: "'}', 'case' or 'default'"
	); 

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub try() {
	my $pos = pos;
	/\Gtry$s\{$s/cg or return;
	my $ret = [[$pos], 'try', &statements];

	/\G \} $s /cgx or expected "'}'";

	$pos = pos;

	if(/\Gcatch$s/cg) {
		/\G \( $s /cgx or expected "'('";
		@$ret == push @$ret, &ident
			and expected 'identifier';
		&skip;
		/\G \) $s /cgx or expected "')'";

		/\G \{ $s /cgx or expected "'{'";
		push @$ret, &statements;
		/\G \} $s /cgx or expected "'}'";
	}
	if(/\Gfinally$s/cg) {
		/\G \{ $s /cgx or expected "'{'";
		push @$ret, &statements;
		/\G \} $s /cgx or expected "'}'";
	}

	pos eq $pos and expected "'catch' or 'finally'";

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub labelled() {
	my $pos = pos;
	/\G ($ident) $s : $s/cgx or return;
	my $ret = [[$pos], 'labelled', unescape_ident $1];

	while (/\G($ident)$s:$s/cg) {
		push @$ret, unescape_ident $1;
	}
	@$ret != push @$ret, &statement
		or expected 'statement';

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub var() {
	my $pos = pos;
	/\G var $S/cgx or return;
	my $ret = [[$pos], 'var'];

	do{
		push @$ret, &vardecl;
	} while(/\G$s,$s/gc);

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub do() {
	my $pos = pos;
	/\G do(?!$id_cont)$s/cgx or return;
	my $ret = [[$pos], 'do'];

	@$ret != push @$ret, &statement
		or expected 'statement';
	/\Gwhile$s/cg               or expected "'while'";
	/\G\($s/cg                or expected "'('";
	@$ret != push @$ret, &expr
		or expected 'expression';
	&skip;
	/\G\)/cog or expected "')'";

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub continue() {
	my $pos = pos;
	/\G continue(?!$id_cont)/cogx or return;
	my $ret = [[$pos], 'continue'];

	/\G$h($ident)/cog
		and push @$ret, unescape_ident $1;

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub break() { # almost identical to continue
	my $pos = pos;
	/\G break(?!$id_cont)/cogx or return;
	my $ret = [[$pos], 'break'];

	/\G$h($ident)/cog
		and push @$ret, unescape_ident $1;

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub return() {
	my $pos = pos;
	/\G return(?!$id_cont)/cogx or return;
	my $ret = [[$pos], 'return'];

	$pos = pos;
	/\G$h/g; # skip horz ws
	@$ret == push @$ret, &expr and pos = $pos;
		# reverse to before the white space if
		# there is no expr

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub throw() {
	my $pos = pos;
	/\G throw(?!$id_cont)/cogx
	        or return; 
	my $ret = [[$pos], 'throw'];

	/\G$h/g; # skip horz ws
	@$ret == push @$ret, &expr and expected 'expression';

	optional_sc;

	push @{$$ret[0]},pos;

	bless $ret, JECS;
}

sub expr_statement() {
	my $ret = &expr or return;
	optional_sc; # the only difference in behaviour between
	             # this and &expr
	$ret;
}



# -------- end of statement types----------#

# This takes care of trailing white space.
sub statement_default() {
	my $ret = [[pos]];

	# Statements that do not have an optional semicolon
	if (/\G (?:
		( \{ | ; )
		  |
		(function)$S
		  |
		( if | w(?:hile|ith) | for | switch ) $s \( $s
		  |
		( try $s \{ $s )
		  |
		($ident) $s : $s
	   ) /xgc) {
		no warnings 'uninitialized';
		if($1 eq '{') {
			push @$ret, 'statements';
			&skip;
			while() { # 'last' does not work when 'while' is a
			         # statement modifier
				@$ret == push @$ret, 
					&statement_default and last;
			}
			
			expected "'}'" unless /\G\}$s/gc;
		}
		elsif($1 eq ';') {
			push @$ret, 'empty';
			&skip;
		}
		elsif($2) {
			push @$ret, 'function';
			@$ret == push @$ret, &ident
				and expected "identifier";
			&skip;
			push @$ret, &params;
			&skip;
			/\G \{ /gcx or expected "'{'";
			{
				local $_vars = [];
				push @$ret, &statements, $_vars;
			}
			/\G \}$s /gcx or expected "'}'";
			push @$_vars, $ret;
		}
		elsif($3 eq 'if') {
			push @$ret, 'if';
			@$ret == push @$ret, &expr
				and expected 'expression';
			&skip;
			/\G\)$s/gc or expected "')'";
			@$ret != push @$ret, &statement_default
				or expected 'statement';
			if (/\Gelse(?!$id_cont)$s/cg) {
				@$ret == push @$ret, 
					&statement_default
					and expected 'statement';
			}
		}
		elsif($3 eq 'while') {
			push @$ret, 'while';
			@$ret == push @$ret, &expr
				and expected 'expression';
			&skip;
			/\G\)$s/gc or expected "')'";
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
		elsif($3 eq 'for') {
			push @$ret, 'for';
			if (/\G var$S/cgx) {
				push @$ret, my $var = bless
					[[pos() - length $1], 'var'],
					'JE::Code::Statement';

				push @$var, &vardecl_noin;
				&skip;
				if (/\G([;,])$s/gc) {
					# if there's a comma or sc then
					# this is a for(;;) loop
					if ($1 eq ',') {
						# finish getting the var
						# decl list
						do{
						    @$var ==
						    push @$var, &vardecl 
						    and expected
						      'identifier'
						} while (/\G$s,$s/gc);
						&skip;
						/\G;$s/cg
						   or expected 'semicolon';
					}
					push @$ret, &finish_for_sc_sc;
				}
				else {
					/\Gin$s/cg or expected
					    "'in', comma or semicolon";
					push @$ret, 'in';
					@$ret == push @$ret, &expr
						and expected 'expresssion';
					&skip;
					/\G\)$s/cg or expected "')'";
				}
			}
			elsif(@$ret != push @$ret, &expr_noin) {
				&skip;
				if (/\G;$s/gc) {
					# if there's a semicolon then
					# this is a for(;;) loop
					push @$ret, &finish_for_sc_sc;
				}
				else {
					/\Gin$s/cg or expected
						"'in' or semicolon";
					push @$ret, 'in';
					@$ret == push @$ret, &expr
						and expected 'expresssion';
					&skip;
					/\G\)$s/cg or expected "')'";
				}
			}
			else {
				push @$ret, 'empty';
				/\G;$s/cg
				    or expected 'expression or semicolon';
				push @$ret, &finish_for_sc_sc;
			}

			# body of the for loop
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
		elsif($3 eq 'with') {
			push @$ret, 'with';
			@$ret == push @$ret, &expr
				and expected 'expression';
			&skip;
			/\G\)$s/gc or expected "')'";
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
		elsif($3 eq 'switch') {
			push @$ret, 'switch';
			@$ret == push @$ret, &expr
				 and expected 'expression';
			&skip;
			/\G\)$s/gc or expected "')'";
			/\G\{$s/gc or expected "'{'";

			while (/\G case(?!$id_cont) $s/cgx) {
				@$ret == push @$ret, &expr
					and expected 'expression';
				&skip;
				/\G:$s/cg or expected 'colon';
				push @$ret, &statements;
			}
			my $default=0;
			if (/\G default(?!$id_cont) $s/cgx) {
				/\G : $s /cgx or expected 'colon';
				push @$ret, default => &statements;
				++$default;
			}
			while (/\G case(?!$id_cont) $s/cgx) {
				@$ret == push @$ret, &expr
					and expected 'expression';
				&skip;
				/\G:$s/cg or expected 'colon';
				push @$ret, &statements;
			}
			/\G \} $s /cgx or expected (
				$default
				? "'}' or 'case'"
				: "'}', 'case' or 'default'"
			); 
		}
		elsif($4) { # try
			push @$ret, 'try', &statements;
			/\G \} $s /cgx or expected "'}'";

			my $pos = pos;

			if(/\Gcatch$s/cg) {
				/\G \( $s /cgx or expected "'('";
				@$ret == push @$ret, &ident
					and expected 'identifier';
				&skip;
				/\G \) $s /cgx or expected "')'";

				/\G \{ $s /cgx or expected "'{'";
				push @$ret, &statements;
				/\G \} $s /cgx or expected "'}'";
			}
			if(/\Gfinally$s/cg) {
				/\G \{ $s /cgx or expected "'{'";
				push @$ret, &statements;
				/\G \} $s /cgx or expected "'}'";
			}

			pos eq $pos and expected "'catch' or 'finally'";
		}
		else { # labelled statement
			push @$ret, 'labelled', unescape_ident $5;
			while (/\G($ident)$s:$s/cg) {
				push @$ret, unescape_ident $1;
			}
			@$ret != push @$ret, &statement_default
				or expected 'statement';
		}
	}
	# Statements that do have an optional semicolon
	else {
		if (/\G var$S/xcg) {
			push @$ret, 'var';

			do{
				push @$ret, &vardecl;
			} while(/\G$s,$s/gc);
		}
		elsif(/\Gdo(?!$id_cont)$s/cg) {
			push @$ret, 'do';
			@$ret != push @$ret, &statement_default
				or expected 'statement';
			/\Gwhile$s/cg               or expected "'while'";
			/\G\($s/cg                or expected "'('";
			@$ret != push @$ret, &expr
				or expected 'expression';
			&skip;
			/\G\)/cog or expected "')'";
		}
		elsif(/\G(continue|break)(?!$id_cont)/cog) {
			push @$ret, $1;
			/\G$h($ident)/cog
				and push @$ret, unescape_ident $1;
		}
		elsif(/\Greturn(?!$id_cont)/cog) {
			push @$ret, 'return';
			my $pos = pos;
			/\G$h/g; # skip horz ws
			@$ret == push @$ret, &expr and pos = $pos;
				# reverse to before the white space if
				# there is no expr
		}
		elsif(/\Gthrow(?!$id_cont)/cog) {
			push @$ret, 'throw';
			/\G$h/g; # skip horz ws
			@$ret == push @$ret, &expr
				and expected 'expression';
		}
		else { # expression statement
			$ret = &expr or return;
		}

		# Check for optional semicolon
		m-$optional_sc-cgx
		 or expected "semicolon, '}' or end of line";
	}
	push @{$$ret[0]},pos unless @{$$ret[0]} == 2; # an expr will 
	                                             # already have this

	ref $ret eq 'ARRAY' and bless $ret, 'JE::Code::Statement';

	return $ret;
}

sub statement() { # public
	my $ret;
	for my $sub(@_stms) {
		defined($ret = &$sub)
			and last;
	}
	defined $ret ? $ret : ()
}

# This takes care of leading white space.
sub statements() {
	my $ret = bless [[pos], 'statements'], 'JE::Code::Statement';
	/\G$s/g; # skip initial whitespace
	while () { # 'last' does not work when 'while' is a
	           # statement modifier
		@$ret != push @$ret,
			$_parser ? &statement : &statement_default
			or last;
	}
	push @{$$ret[0]},pos;
	return $ret;
}

sub program() { # like statements(), but it allows function declarations
                # as well
	my $ret = bless [[pos], 'statements'], 'JE::Code::Statement';
	/\G$s/g; # skip initial whitespace
	if($_parser) {
		while () {	
			DECL: {
				for my $sub(@_decls) {
					@$ret != push @$ret, &$sub
						and redo DECL;
				}
			}
			@$ret != push @$ret, &statement or last;
		}
	}
	else {
		while () {	
			while() {
				@$ret == push @$ret, &function and last;
			}
			@$ret != push @$ret, &statement_default or last;
		}
	}
	push @{$$ret[0]},pos;
	return $ret;
}


# ~~~ The second arg to add_line_number is a bit ridiculous. I may change
#     add_line_number's parameter list, perhaps so it accepts either a
#     code object, or (src,file,line) if $_[1] isn'ta JE::Code. I don't
#     know....
sub _parse($$$;$$) { # Returns just the parse tree, not a JE::Code object.
                     # Actually,  it returns the source followed  by  the
                     # parse tree in list context, or just the parse tree
                     # in scalar context.
	my ($rule, $src, $my_global, $file, $line) = @_;
	local our($_source, $_file, $_line) =($src,$file,$line);

	# Note: We *hafta* stringify the $src, because it could be an
	# object  with  overloading  (e.g.,  JE::String)  and  we
	# need to rely on its  pos(),  which simply cannot be
	# done with an object.  Furthermore,  perl5.8.5 is
	# a bit buggy and sometimes mangles the contents
	# of $1 when one does $obj =~ /(...)/.
	$src = defined blessed $src && $src->isa("JE::String")
	       ? $src->value16
	       : surrogify("$src");

	# remove unicode format chrs
	$src =~ s/\p{Cf}//g;

	# In HTML mode, modify the whitespace regexps to remove HTML com-
	# ment delimiters and following junk up to the end of the line.
	$my_global->html_mode and
	 local $s = qr((?>
	  (?> [ \t\x0b\f\xa0\p{Zs}]* )
	  (?> (?>
	       $n
	       (?>(?:
	        (?>[ \t\x0b\f\xa0\p{Zs}]*) -->
	        (?>[^\cm\cj\x{2028}\x{2029}]*)(?>$n|\z)
	       )?)
	        |
	       ^
	       (?>[ \t\x0b\f\xa0\p{Zs}]*) -->
	       (?>[^\cm\cj\x{2028}\x{2029}]*)(?>$n|\z)
	        |
	       (?>//|<!--)(?>[^\cm\cj\x{2028}\x{2029}]*)(?>$n|\z)
	        |
	       /\*.*?\*/
	      )
	      (?> [ \t\x0b\f\xa0\p{Zs}]* )
	  ) *
	 ))sx,
	 local $S = qr(
	  (?>
	   $ss
	    |
	   (?>//|<!--)[^\cm\cj\x{2028}\x{2029}]*
	    |
	   /\*.*?\*/
	  )
	  $s
	 )xs,
	 local $optional_sc = qr _\G (?:
	    $s (?: \z | ; $s | (?=\}) )
	      |
	    # optional horizontal whitespace
	    # then a line terminator or a comment containing one
	    # then optional trailing whitespace
	    $h
	    (?:
	        $n
	         |
	        (?>//|<!--)[^\cm\cj\x{2028}\x{2029}]* $n
	         |
	        /\* [^*\cm\cj\x{2028}\x{2029}]* 
	            (?: \*(?!/) [^*\cm\cj\x{2028}\x{2029}] )*
	          $n
	          (?s:.)*?
	        \*/
	    )
	    $s
	 )_x;

	my $tree;
	local $_vars = [];
	$rule eq 'program' and !$_parser
	 and ($ENV{'YES_I_WANT_JE_TO_OPTIMISE'}||'') eq 2
	 and do { require 'JE/parsetoperl.pl', $rule = \&ptp_program };
	for($src) {
		pos = 0;
		eval {
			local $global = $my_global;
			$tree = (\&$rule)->();
			!defined pos or pos == length 
			   or expected 'statement or function declaration';
		};
		if(ref $@ ne '') {
			defined blessed $@ and
				$@->isa('JE::Object::Error')
				? last : die;
			ref($@) =~ /^(?:SCALAR|REF)\z/ or die;
			$@
			 = ref ${$@} eq 'SCALAR'
			   ? JE::Object::Error::SyntaxError->new(
				$my_global,
				add_line_number(
				    $${$@},	
				   {file=>$file,line=>$line,source=>\$src},
				     pos)
			     )
			   : JE::Object::Error::SyntaxError->new(
				$my_global,
			# ~~~ This should perhaps show more context
				add_line_number
				    "Expected ${$@} but found '".
				    substr($_, pos, 10) . "'",
				   {file=>$file,line=>$line,source=>\$src},
				     pos
			     );
			return;
		}
		elsif($@) { die }
	}
#use Data::Dumper;
#print Dumper $tree;
	wantarray ? ($src, $tree, $_vars) : $tree;
}



#----------DOCS---------#

!!!0;

=head1 NAME

JE::Parser - Framework for customising JE's parser

=cut

# Actually, this *is* JE's parser. But since JE::Parser's methods are never
# used directly with the default parser, I think it's actually less confus-
# ing to call it this.

=head1 SYNOPSIS

  use JE;
  use JE::Parser;

  $je = new JE;
  $p = new JE::Parser $je; # or: $p = $je->new_parser

  $p->delete_statement('for', 'while', 'do'); # disable loops
  $p->add_statement(try => \&parser); # replace existing 'try' statement

=head1 DESCRIPTION

This allows one to change the list of statement types that the parser
looks for. For instance, one could disable loops for a mini-JavaScript, or
add extensions to the language, such as the 'catch-if' clause of a C<try> 
statement.

As yet, C<delete_statement> works, but I've not finished
designing the API for C<add_statement>.

I might provide an API for extending expressions, if I can resolve the
complications caused by the 'new' operator. If anyone else wants to have a
go at it, be my guest. :-)

=head1 METHODS

=over 4

=item $p = new JE::Parser

Creates a new parser object.

=item $p->add_statement($name, \&parser);

This adds a new statement (source element, to be precise) type 
to the
list of statements types the parser supports. If a statement type called 
C<$name> already exists, it will be replaced.
Otherwise, the new statement type will be added to the top of the list.

(C<$name> ought to be optional; it should only be necessary if one wants to 
delete 
it
afterwards or rearrange the list.)

If the name of a statement type begins with a hyphen, it is only allowed at
the 'program' level, not within compound statements. Function declarations
use this. Maybe this
convention is too unintuitive.... (Does anyone think I should change it?
What should I change it too?)

C<&parser> will need to parse code contained in C<$_> starting at C<pos()>, then either
return an object, list or coderef (see below)
and set C<pos()> to the position of the next token[1], or, if it 
could not
parse anything, return undef and reset C<pos()> to its initial value if it
changed.

[1] I.e., it is expected to move C<pos> past any trailing whitespace.

The return value of C<&parser> can be one of the following:

=over 4

=item 1)

An object with an C<eval> method, that will execute the statement, and/or 
an C<init> method, which will be called
before the code runs.

=item 2)

B<(Not yet 
supported!)> A coderef, which will be called when the code is executed.

=item 3)

B<(Not yet 
supported.)> A hash-style list, the two keys being C<eval> and C<init> 
(corresponding to
the methods under item 1) and the values being coderefs; i.e.:

  ( init => \&init_sub, eval => \&eval_sub )

=back

Maybe we need support for a JavaScript function to be called to handnle the
statement.

=item $p->delete_statement(@names);

Deletes the given statement types and returns C<$p>.

=item $p->statement_list

B<(Not yet implemented.)>

Returns an array ref of the names of the various statement types. You can 
rearrange this
list, but it is up to you to make sure you do not add to it any statement
types that have not been added via C<add_statement> (or were not there by
default). The statement types in the list will be tried in order, except
that items beginning with a hyphen always come before other items.

The default list is C<qw/-function block empty if while with for switch try
labelled var do continue break return throw expr/>

=item $p->parse($code)

Parses the C<$code> and returns a parse tree (JE::Code object).

=item $p->eval($code)

Shorthand for $p->parse($code)->execute;

=back

=head1 EXPORTS

None by default. You may choose to export the following:

=head2 Exported Variables

... blah blah blah ...

=head2 Exported Functions

These all have C<()> for their prototype, except for C<expected> which has
C<($)>.

... blah blah blah ...

=head1 SYNTAX ERRORS

(To be written)

  expected 'aaaa'; # will be changed to 'Expected aaaa but found....'
  die \\"You can't put a doodad after a frombiggle!"; # complete message
  die 'aoenstuhoeanthu'; # big no-no (the error is propagated)

=head1 EXAMPLES

=head2 Mini JavaScript

This is an example of a mini JavaScript that does not allow loops or the
creation of functions.

  use JE;
  $j = new JE;
  $p = $j->new_parser;
  $p->delete_statement('for','while','do','-function');

Since function expressions could still create functions, we need to remove
the Function prototype object. Someone might then try to put it back with
C<Function = parseInt.constructor>, so we'll overwrite Function with an
undeletable read-only undefined property.

  $j->prop({ name     => 'Function',
             value    => undef,
             readonly => 1,
             dontdel  => 1 });

Then, after this, we call C<< $p->eval('...') >> to run JS code.

=head2 Perl-style for(LIST) loop

Well, after writing this example, it seems to me this API is not 
sufficient....

This example doesn't actually work yet.

  use JE;
  use JE::Parser qw'$s ident expr statement expected';
  
  $j = new JE;
  $p = $j->new_parser;
  $p->add_statement('for-list',
      sub {
          /\Gfor$s/cog or return;
          my $loopvar = ident or return;
          /\G$s\($s/cog or return;
          my @expressions;
          do {
              # This line doesn't actually work properly because
              # 'expr' will gobble up all the commas
              @expressions == push @expressions, expr
                  and return; # If nothing gets pushed on  to  the
                              # list,  we need to give the default
                              # 'for' handler a chance, instead of
                              # throwing an error.
          } while /\G$s,$s/cog;
          my $statement = statement or expected 'statement';
          return bless {
              var => $loopvar,
              expressions => \@expressions,
              statement => $statement
          }, 'Local::JEx::ForList';
      }
  );
  
  package Local::JEx::ForList;
  
  sub eval {
      my $self = shift;
      local $JE::Code::scope =
          bless [@$JE::Code::scope], 'JE::Scope';
          # I've got to come up with a better interface than this.
      my $obj = $JE::Code::global->eval('new Object');
      push @$JE::Code::scope, $obj;

      for (@{$self->{expressions}}) {
          $obj->{ $self->{loopvar} } = $_->eval;
          $self->{statement}->execute;
      }
  }

=head1 SEE ALSO

L<JE> and L<JE::Code>.

=cut




