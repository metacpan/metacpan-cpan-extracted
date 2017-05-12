package JE::Object::RegExp;

our $VERSION = '0.066';


use strict;
use warnings; no warnings 'utf8';

use overload fallback => 1,
	'""'=> 'value';

# This constant is true if we need to work around perl bug #122460 to keep
# the ‘aardvark’ tests (in t/15.05-string-objects.t) passing.  This only
# applies  to  perl  5.20.0.  (perl  5.20.1  includes  a  fix.)  Basic-
# ally,  (?=...)  can result in buggy optimisations that cause  a  faulty
# rejection of the match at some locations, because it is assumed that it
# cannot match in some spots.
use constant aardvark_bug =>
 # This test should match the empty string.  If it advances (pos returns
 # true), then we have the bug.
 do { my $a = "rdvark"; $a =~ /(?{})(?=.)a*?/g; pos $a };

use Scalar::Util 'blessed';

our @ISA = 'JE::Object';

require JE::Boolean;
require JE::Code;
require JE::Object;
require JE::String;

import JE::Code 'add_line_number';
sub add_line_number;

our @Match;
our @EraseCapture;

#import JE::String 'desurrogify';
#sub desurrogify($);
# Only need to turn these on when Perl starts adding regexp modifiers
# outside the BMP.

# JS regexp features that Perl doesn't have, or which differ from Perl's,
# along with their Perl equivalents
#    ^ with /m  \A|(?<=[\cm\cj\x{2028}\x{2029}])  (^ with the  /m modifier
#                                                matches whenever a Unicode
#                                              line  break  (not  just  \n)
#                                           precedes the current  position,
#                                       even at the end of the string. In
#                                  Perl, /^/m matches \A|(?<=\n)(?!\z) .)
#    $          \z
#    $ with /m  (?:\z|(?=[\cm\cj\x{2028}\x{2029}]))
#    \b         (?:(?<=$w)(?!$w)|(?<!$w)(?=$w))  (where  $w  represents
#    \B         (?:(?<=$w)(?=$w)|(?<!$w)(?!$w))  [A-Za-z0-9_], because JS
#                                               doesn't include  non-ASCII
#                                             word chars in \w)
#    .          [^\cm\cj\x{2028}\x{2029}]
#    \v         \cK
#    \n         \cj  (whether \n matches \cj in Perl is system-dependent)
#    \r         \cm
#    \uHHHH     \x{HHHH}
#    \d         [0-9]
#    \D         [^0-9]
#    \s         [\p{Zs}\s\ck]
#    \S         [^\p{Zs}\s\ck]
#    \w         [A-Za-z0-9_]
#    \W         [^A-Za-z0-9_]
#    [^]	(?s:.)
#    []         (?!)

# Other differences
#
# A quantifier in a JS regexp will,  when repeated,  clear all values  cap-
# tured by capturing parentheses in the term that it quantifies. This means
# that /((a)?b)+/, when matched against "abb" will leave $2 undefined, even
# though the second () matched  "a"  the first time the first  ()  matched.
# (The ECMAScript spec says to do it this way,  but Safari leaves $2  with
# "a" in it and doesn't clear it on the second iteration of the '+'.) Perl
# does it both ways, and the rules aren't quite clear to me:
#
# $ perl5.8.8 -le '$, = ",";print "abb" =~ /((a)?b)+/;'
# b,
# $ perl5.8.8 -le '$, = ",";print "abb" =~ /((a+)?b)+/;'
# b,a
#
# perl5.9.4 produces the same. perl5.002_01 crashes quite nicely.
# 
#
# In ECMAScript, when the pattern inside a (?! ... ) fails (in which case
# the (?!) succeeds), values captured by parentheses within the negative
# lookahead are cleared, such that subsequent backreferences *outside* the
# lookahead are equivalent to (?:) (zero-width always-match assertion). In
# Perl, the captured values are left as they are when the pattern inside
# the lookahead fails:
#
# $ perl5.8.8 -le 'print "a" =~ /(?!(a)b)a/;'
# a
# $ perl5.9.4 -le 'print "a" =~ /(?!(a)b)a/;'
# a
#
#
# In ECMAScript, as in Perl, a pair of capturing parentheses will produce
# the undefined value if the parens were not  part  of  the  final  match.
# Undefined will still be produced if there  is  a  \digit  backreference
# reference to those parens. In ECMAScript, such a back-reference is equiv-
# alent to (?:); in Perl it is equivalent to (?!). Therefore, ECMAScript’s
# \1  is equivalent to Perl’s  (?(1)\1).  (It  would  seem,  upon  testing
# /(?:|())/ vs. /(?:|())\1/ in perl, that the \1 back-reference always suc-
# ceeds, and ends up setting $1 to "" [as opposed to undef]. What is actu-
# ally happening is that the failed \1 causes backtracking, so the second
# alternative in (?:|()) matches, setting $1 to the empty string. Safari,
# incidentally, does what Perl *appears* to do at first glance, *if* the
# backreference itself is within capturing parentheses (as in
# /(?:|())(\1)/).
#
# These issues are solved with embedded code snippets, as explained below,
# where the actual code is.
#
#
# In ECMAScript,  case-folding inside the regular expression engine is not
# allowed to change the length of a string.  Therefore,  "ß"  never matches
# /ss/i, and vice versa. I’m disinclined to be ECMAScript compliant in this
# regard though, because it would affect performance. The inefficient solu-
# tion I have in mind is to change /x/i to /(?-i:x)/  for every character
# that has a multi-character uppercase equivalent; and to change /xx/i to
# /(?-i:[Xx][Xx])/  where xx  represents a multi-character sequence that
# could match a single character in Perl. The latter is the main problem.
# How are we to find out which character sequences need  this?  We  could
# change /x/i to /[xX]/ for every literal character in the string, but how
# would we take /Σ/ -> /[Σσς]/ into account? And does perl’s regexp engine
# slow down if we feed it a ton of character classes instead  of  literal
# text? (Need to do some benchmarks.) (If we do fix this, we need to re-
# enable the skipped tests.)



=head1 NAME

JE::Object::RegExp - JavaScript regular expression (RegExp object) class

=head1 SYNOPSIS

  use JE;
  use JE::Object::RegExp;

  $j = new JE;

  $js_regexp = new JE::Object::RegExp $j, "(.*)", 'ims';

  $perl_qr = $js_regexp->value;

  $some_string =~ $js_regexp; # You can use it as a qr//

=head1 DESCRIPTION

This class implements JavaScript regular expressions for JE.

See L<JE::Types> for a description of most of the interface. Only what
is specific to JE::Object::RegExp is explained here.

A RegExp object will stringify the same way as a C<qr//>, so that you can
use C<=~> on it. This is different from the return value of the
C<to_string> method (the way it stringifies in JS).

Since JE's regular expressions use Perl's engine underneath, the 
features that Perl provides that are not part of the ECMAScript spec are
supported, except for C<(?s)>
and C<(?m)>, which don't do anything, and C<(?|...)>, which is 
unpredictable.

In versions prior to 0.042, a hyphen adjacent to C<\d>, C<\s> or C<\w> in a
character class would be unpredictable (sometimes a syntax error). Now it
is interpreted literally. This matches what most implementations do, which
happens to be the same as Perl's behaviour. (It is a syntax error
in ECMAScript.)

=head1 METHODS

=over 4

=cut

# ~~~ How should surrogates work??? To make regexps work with JS strings
#    properly, we need to use the surrogified string so that /../  will
#  correctly match two surrogates.  In this case it won't work properly
# with Perl strings, so what is the point of Perl-style stringification?
# Perhaps we should allow this anyway, but warn about code points outside
# the BMP in the documentation.  (Should we also produce a Perl  warning?
# Though I'm not that it's possible to catch  this:  "\x{10000}" =~ $re).
#
# But it would be nice if this would work:
#	$j->eval("'\x{10000}'") =~ $j->eval('/../')
# ~~~ We might be able to make this work with perl 5.12’s qr overloading.

our %_patterns = qw/
\b  (?:(?<=[A-Za-z0-9_])(?![A-Za-z0-9_])|(?<![A-Za-z0-9_])(?=[A-Za-z0-9_]))
\B  (?:(?<=[A-Za-z0-9_])(?=[A-Za-z0-9_])|(?<![A-Za-z0-9_])(?![A-Za-z0-9_]))
.   [^\cm\cj\x{2028}\x{2029}]
\v  \cK
\n  \cj
\r  \cm
\d  [0-9]
\D  [^0-9]
\s  [\p{Zs}\s\ck]
\S  [^\p{Zs}\s\ck]
\w  [A-Za-z0-9_]
\W  [^A-Za-z0-9_]
/;

our %_class_patterns = qw/
\v  \cK
\n  \cj
\r  \cm
\d  0-9
\s  \p{Zs}\s\ck
\w  A-Za-z0-9_
/;

my $clear_captures = qr/(?{@Match=@EraseCapture=()})/;
my $save_captures = do { no strict 'refs';
  qr/(?{$Match[$_]=$EraseCapture[$_]?undef:$$_ for 1..$#+})/; };
# These are pretty scary, aren’t they?
my $plain_regexp =
	qr/^((?:[^\\[()]|\\.|\((?:\?#|\*)[^)]*\))[^\\[()]*(?:(?:\\.|\((?:\?#|\*)[^)]*\))[^\\[()]*)*)/s;
my $plain_regexp_x_mode =
	qr/^((?:[^\\[()]|\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()]*(?:(?:\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()]*)*)/s;
my $plain_regexp_wo_pipe =
	qr/^((?:[^\\[()|]|\\.|\((?:\?#|\*)[^)]*\))[^\\[()|]*(?:(?:\\.|\((?:\?#|\*)[^)]*\))[^\\[()|]*)*)/s;
my $plain_regexp_x_mode_wo_pipe =
	qr/^((?:[^\\[()|]|\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()|]*(?:(?:\\.|\(\s*(?:\?#|\*)[^)]*\))[^\\[()|]*)*)/s;

sub _capture_erasure_stuff {
	"(?{local\@EraseCapture[" . join(',',@{$_[0]}) . "]=(1)x"
		. @{$_[0]} . '})'
}

sub new {
	my ($class, $global, $re, $flags) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prototype_for('RegExp')
		          || $global->prop('RegExp')->prop('prototype')
	});

	my $qr;

	if(defined blessed $re) {
		if ($re->isa(__PACKAGE__)) {
			defined $flags && eval{$flags->id} ne 'undef' and
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					'Second argument to ' .
					'RegExp() must be undefined if ' .
					'first arg is a RegExp');
			$flags = $$$re{regexp_flags};
			$qr = $$$re{value};
			$re = $re->prop('source')->[0];
		}
		elsif(can $re 'id' and $re->id eq 'undef') {
			$re = '';
		}
		elsif(can $re 'to_string') {
			$re = $re->to_string->value16;
		}
	}
	else {
		defined $re or $re = '';
	}

	if(defined blessed $flags) {
		if(can $flags 'id' and $flags->id eq 'undef') {
			$flags = '';
		}
		elsif(can $flags 'to_string') {
			$flags = $flags->to_string->value;
		}
	}
	else {
		defined $flags or $flags = '';
	}


	# Let's begin by processing the flags:

	# Save the flags before we start mangling them
	$$$self{regexp_flags} = $flags;

	$self->prop({
		name => global =>
		value  => JE::Boolean->new($global, $flags =~ y/g//d),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});

#	$flags = desurrogify $flags;
# Not necessary, until Perl adds a /𐐢 modifier (not likely)

	# I'm not supporting /s (at least not for now)
	no warnings 'syntax'; # so syntax errors in the eval are kept quiet
	$flags =~ /^((?:(?!s)[\$_\p{ID_Continue}])*)\z/ and eval "qr//$1"
		or die new JE::Object::Error::SyntaxError $global,
		add_line_number "Invalid regexp modifiers: '$flags'";

	my $m = $flags =~ /m/;
	$self->prop({
		name => ignoreCase =>
		value  => JE::Boolean->new($global, $flags =~ /i/),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});
	$self->prop({
		name => multiline =>
		value  => JE::Boolean->new($global, $m),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});


	# Now we'll deal with the pattern itself.

	# Save it before we go and mangle it
	$self->prop({
		name => source =>
		# ~~~ Can we use ->_new here?
		value  => JE::String->new($global, do {
			(my $tmp = $re) =~
				s<(\\.)|/>
				<defined $1 ? $1 : '\/'>egg;
			$tmp
		}),
		dontenum => 1,
		readonly  => 1,
		dontdel   => 1,
	});

	unless (defined $qr) { # processing begins here

	# This horrific piece of code converts an ECMAScript regular
	# expression into a Perl one, more or less.

	# Since Perl sometimes fills in $1, etc., where they are supposed
	# to be undefined in ECMAScript, we use embedded code snippets to
	# put the values into @Match[1..whatever] instead.

	# The cases we have to take into account are
	# 1) quantified captures; i.e., (...)+ or (?:()?)+ ; and
	# 2) captures within interrobang groups: (?!())

	# The solution is to mark captures as erasure candidates with the
	# @EraseCapture array.

	# To solve case 1, we have to put (?{}) markers at the begin-
	# ning of each grouping construct that has captures  in  it,
	# and a quantifier within each pair of capturing  parenthe-
	# ses before the closing paren.  (?:(a+)?b)+  will  become
	# (?: (?{...}) ( a+ (?{...}) )? b )+  (spaced out for reada-
	# bility). The first code interpolation sets $EraseCapture[n]
	# to 1  for  all  the  captures  within  that  group.  The  sec-
	# ond code  interpolation  will  only  be  triggered  if  the  a+
	# matches,  and there we  set  $EraseCapture[n]  to  0.  It’s actu-
	# ally  slightly  more  complicated  than  that,  because  we  may
	# have alternatives directly  inside  the  outer  grouping;  e.g.,
	# (?:a|(b))+,  so we have to wrap the contents  thereof  within
	# (?:),  making ‘(?:(?{...})(?:a|(b(?{...}))))+’.  Whew!

	# For case 2 we change (?!...) to (?:(?!...)(?{...})). The embedded
	# code marks the captures inside  (?!)  for erasure.  The  (?:  is
	# needed because the (?!) might be quantified. (We used not to add
	# the extra (?:),  but put the (?{})  at the end of the innermost
	# enclosing group,  but that causes the  same  \1  problem  men-
	# tioned above.

	use constant 1.03 # multiple
	{ # Make sure any changes to these constants are also
	  # made at  the  end
	  # of the subroutine
		# array indices within each item on the @stack:
		posi => 0, # position within $new_re where the current
		           # group’s contents start, or before the opening
		           # paren for interrobang groups
		type => 1, # type of group; see constants below
		xmod => 2, # whether /x mode is active
		capn => 3, # array ref of capture numbers within this group

		# types of parens:
		reg => 0, cap => 1, itrb => 2, brch => 3, cond => 4
	};

	my $new_re = '';
	my $sub_pat;
	my @stack = [0,0,$flags =~ /x/];
	my $capture_num; # number of the most recently started capture
	my @capture_nums;   # numbers of the captures we’re inside
#my $warn;
#++$warn if $re eq '(?p{})';
	{
		@stack or die new JE::Object::Error::SyntaxError $global,
			add_line_number "Unmatched ) in regexp";

		# no parens or char classes:
		if( $stack[-1][xmod]
		  ? $stack[-1][type] == cond || $stack[-1][type] == brch
		    ? $re =~ s/$plain_regexp_x_mode_wo_pipe//
		    : $re =~ s/$plain_regexp_x_mode//
		  : $stack[-1][type] == cond || $stack[-1][type] == brch
		    ? $re =~ s/$plain_regexp_wo_pipe//
		    : $re =~ s/$plain_regexp//
		) {
			($sub_pat = $1) =~
			s/
				([\^\$])
				  |
				(\.|\\[bBvnrdDsSwW])
				  |
				\\u([A-Fa-f0-9]{4})
				  |
				\\([1-9][0-9]*)
				  |
				\\?([\x{d800}-\x{dfff}])
				  |
				(\\(?:[^c]|c.))
			/
			  defined $1
			  ? $1 eq '^'
			    ? $m
			      ? '(?:\A|(?<=[\cm\cj\x{2028}\x{2029}]))'
			      : '^'
			    : $m
			      ? '(?:\z|(?=[\cm\cj\x{2028}\x{2029}]))'
			      : '\z'
			  : defined $2 ? $_patterns{$2} :
			    defined $3 ? "\\x{$3}"      :
			    defined $4 ? "(?(?{defined\$$4&&"
			                ."!\$EraseCapture[$4]})\\$4)" :
			    # work around a bug in perl:
			    defined $5 ? sprintf '\\x{%x}', ord $5 :
			    $6
			/egxs;
			$new_re .= $sub_pat;
		}

		# char class:
		elsif($re=~s/^\[([^]\\]*(?:\\.[^]\\]*)*)]//s){
			if($1 eq '') {
				$new_re .= '(?!)';
			}
			elsif($1 eq '^') {
				$new_re .= '(?s:.)';
			}
			else {
				my @full_classes;
				($sub_pat = $1) =~ s/
				  (\\[vnr])
				    |
				  (-?)(\\[dsw])(-?)
				    |
				  (\\[DSW])
				    |
				  \\u([A-Fa-f0-9]{4})
				    |
				  \\?([\x{d800}-\x{dfff}])
				    |
				  (\\(?:[^c]|c.))
				/
			  	  defined $1 ? $_class_patterns{$1} :
			  	  defined $3 ?
				     ($2 ? '\-' : '')
				    .$_class_patterns{$3}
				    .($4 ? '\-' : '')     :
				  defined $5 ? ((push @full_classes,
					$_patterns{$5}),'') :
				  defined $6 ? "\\x{$6}"  :
				  # work around a bug in perl:
				  defined $7 ? sprintf '\\x{%x}', ord $7 :
			    	  $8
				/egxs;

				$new_re .= length $sub_pat
				  ? @full_classes
				    ? '(?:' .
				      join('|', @full_classes,
				        "[$sub_pat]")
				      . ')'
				    : "[$sub_pat]"
				  : @full_classes == 1
				    ? $full_classes[0]
				    : '(?:' . join('|', @full_classes) .
				      ')';
			}
		}

		# (?mods) construct (no colon) :
		elsif( $stack[-1][xmod]
		             ? $re =~ s/^(\(\s*\?([\w]*)(?:-([\w]*))?\))//
		             : $re =~ s/^(\(   \?([\w]*)(?:-([\w]*))?\))//x
		) {
			$new_re .= $1;
			defined $3 && index($3,'x')+1
			? $stack[-1][xmod]=0
			: $2 =~ /x/ && ++$stack[-1][xmod];
		}

		# start of grouping construct:
		elsif( $stack[-1][xmod]
		 ? $re=~s/^(\((?:\s*\?([\w-]*:|[^:{?<p]|<.|([?p]?\{)))?)//
		 : $re=~s/^(\((?:   \?([\w-]*:|[^:{?<p]|<.|([?p]?\{)))?)//x
		) {
#			warn "$new_re-$1-$2-$3-$re" if $warn;
			$3 and  die JE'Object'Error'SyntaxError->new(
				      $global, add_line_number
				        "Embedded code in regexps is not " 
				        . "supported"
				    );
			my $pos_b4_parn = length $new_re;
			$new_re .= $1;
			my $caq = $2; # char(s) after question mark
			my @current;
			if(defined $caq) {  # (?...) patterns
				if($caq eq '(') {
				  $re =~ s/^([^)]*\))//;
				  $new_re .= $1;
				  $1 =~ /^\?[?p]?\{/ && die
				    JE'Object'Error'SyntaxError->new(
				      $global, add_line_number
				        "Embedded code in regexps is not " 
				        . "supported"
				    );
				  $current[type] = cond;
				}
				elsif($caq =~ /^[<'P](?![!=])/) {
				  ++$capture_num;
				  $caq eq "'" ? $re =~ s/^(.*?')//
				              : $re =~ s/^(.*?>)//;
				  $new_re .= $1;
				  $current[type] = reg;
				}
				else {
				  $current[type] = (reg,itrb)[$caq eq '!'];
				}
				$current[posi] = $caq eq '!' ? $pos_b4_parn
					: length $new_re;
			}else{ # capture
				++$capture_num;
				push @capture_nums, $capture_num;
				push @{$$_[capn]}, $capture_num for @stack;
				$current[posi] = length $new_re;
				$current[type] = cap;
			}
			$current[xmod] = $stack[-1][xmod];
			push @stack, \@current;
		}

		# closing paren:
		elsif($re =~ s/^\)//) {
			my @commands;
			my $cur = $stack[-1];
			if($$cur[type] != itrb) {
				if($$cur[type] == cap) {
				  # we are exiting a capturing group
				  $new_re .= "(?{local" .
				    "\$EraseCapture[$capture_nums[-1]]=0"
				   ."})";
				  pop @capture_nums;
				}
				if($$cur[capn] && @{$$cur[capn]} &&
				   $re =~ /^[+{*?]/) { # quantified group
				  substr $new_re,$$cur[posi],0 =>=
				    _capture_erasure_stuff($$cur[capn])
					. "(?:";
				   $new_re .= ")";
				}
				$new_re .= ')';
			}
			else {{ # ?!
				$new_re .= ')';
				last unless($$cur[capn] && @{$$cur[capn]});

				# change (?!...) to (?!...)(?{...})
				$new_re .= _capture_erasure_stuff(
					$$cur[capn]
				);

				# wrap (?!)(?{}) in (?:) if necessary
				$re =~ /^[+{*?]/ and
					substr $new_re,$$cur[posi],0 
						=>= '(?:',
					$new_re .= ')';
			}}
			pop @stack;
		}

		# pipe within (?()|) or (?|) (the latter doesn’t work yet):
		elsif($re =~ s/^\|//) {
			my $cur = $stack[-1];
			if($$cur[capn] && @{$$cur[capn]}
			   #&& $re =~ /^[+{*?]/ # We can’t actually tell
			) {         # at this point whether the enclosing
			 # group is quantified. Does anyone have any ideas?
				substr $new_re,$$cur[posi],0 =>=
					_capture_erasure_stuff(
						$$cur[capn]
					);
				@{$$cur[capn]} = ();
			}
			$new_re .= '|';
			$$cur[posi] = length $new_re;
		}

		# something invalid left over:
		elsif($re) {
#warn $re;
			die JE::Object::Error::SyntaxError->new($global,
			    add_line_number
			    $re =~ /^\[/
			    ? "Unterminated character class $re in regexp"
			    : 'Trailing \ in regexp');
		}
		length $re and redo;
	}
	@stack or die new JE::Object::Error::SyntaxError $global,
		add_line_number "Unmatched ) in regexp";

	aardvark_bug && $new_re =~ /\(\?=/
	 and substr $new_re,0,0, = '(??{""})';

#warn $new_re;
	$qr = eval {
		use re 'eval'; no warnings 'regexp'; no strict;

		# The warnings pragma doesn’t make it into the re-eval, so
		# we have to localise  $^W,  in case the  string  contains
		# @EraseCapture[1]=(1)x1  and someone is using  -w.
		local $^W;

		# We have to put (?:)  around $new_re in the first case,
		    # because it may contain a top-level disjunction, but
		         # not in the second,  because the array  modifica-
		$capture_num  # tions in $clear_captures are not localised.
		  ? qr/(?$flags:$clear_captures(?:$new_re)$save_captures)/
		  : qr/(?$flags:$clear_captures$new_re)/
	} or $@ =~ s/\.?$ \n//x,
	     die JE::Object::Error::SyntaxError->new($global,
			add_line_number $@);

	} # end of pattern processing

	$$$self{value} = $qr;

	$self->prop({
		name => lastIndex =>
		value => JE::Number->new($global, 0),
		dontdel => 1,
		dontenum => 1,
	});

	$self;
}
BEGIN {
 no strict;
 delete @{__PACKAGE__.'::'}{qw[posi type xmod capn reg cap itrb brch cond]}
}



=item value

Returns a Perl C<qr//> regular expression.

If the regular expression
or the string that is being matched against it contains characters outside
the Basic Multilingual Plane (whose character codes exceed 0xffff), the
behavior is undefined--for now at least. I still need to solve the problem
caused by JS's unintuitive use of raw surrogates. (In JS, C</../> will 
match a
surrogate pair, which is considered to be one character in Perl. This means
that the same regexp matched against the same string will produce different
results in Perl and JS.)

=cut

sub value {
	$${$_[0]}{value};
}




=item class

Returns the string 'RegExp'.

=cut

sub class { 'RegExp' }


sub call {
				my ($self,$str) = @_;

				die JE::Object::Error::TypeError->new(
					$self->global, add_line_number
					"Argument to exec is not a " .
					"RegExp object"
				) unless $self->class eq 'RegExp';

				my $je_str;
				if (defined $str) {
					$str =
					($je_str=$str->to_string)->value16;
				}
				else {
					$str = 'undefined';
				}

				my(@ary,$indx);
				my $global = $$$self{global};

				my $g = $self->prop('global')->value;
				if ($g) {
					my $pos = 
					   $self->prop('lastIndex')
					    ->to_number->value;
					$pos < 0 || $pos > length $str
					 ||
					(
					 pos $str = $pos, 
					 $str !~ /$$$self{value}/g
					)
					 and goto phail;

					@ary = @Match;
					$ary[0] = substr($str, $-[0],
						$+[0] - $-[0]);
					$indx = $-[0];

					$self->prop(lastIndex =>
						JE::Number->new(
							$global,
							pos $str
						));
					$global->prototype_for('RegExp')
					 ->prop('constructor')
					 ->capture_re_vars($str);
				}
				else {
					$str =~ /$$$self{value}/
					 or goto phail;

					@ary = @Match;
					$ary[0] = substr($str, $-[0],
						$+[0] - $-[0]);
					$indx = $-[0];
					$global->prototype_for('RegExp')
					 ->prop('constructor')
					 ->capture_re_vars($str);
				}
			
				my $ary = JE::Object::Array->new(
					$global, 
					\@ary
				);
				$ary->prop(index =>
					JE::Number->new($global,$indx));
				$ary->prop(input => defined $je_str
					? $je_str :
					JE::String->_new(
						$global, $str
					));
				
				return $ary;

				phail:
				$self->prop(lastIndex =>
					    JE::Number->new(
					     $global,
					     0
					    ));
				return $global->null;
}

sub apply { splice @'_, 1, 1; goto &call }

@JE::Object::Function::RegExpConstructor::ISA = 'JE::Object::Function';
sub JE::Object::Function::RegExpConstructor::capture_re_vars { 
   my $self = shift;
   my $global = $$$self{global};
   $self->prop(
    'lastMatch',
     JE::String->new($global, substr $_[0], $-[0], $+[0]-$-[0])
   );
   {
    no warnings 'uninitialized';
    $self->prop('lastParen', new JE::String $global, "$+")
   }
   $self->prop(
    'leftContext',
     new JE'String $global, substr $_[0], 0, $-[0]
   );
   $self->prop('rightContext', new JE'String $global, substr $_[0], $+[0]);
   no warnings 'uninitialized';
   $self->prop("\$$_", new JE'String $global, "$Match[$_]") for 1..9;
}
sub new_constructor {
	my($package,$global) = @_;
	my $f = JE::Object::Function::RegExpConstructor->new({
		name            => 'RegExp',
		scope            => $global,
		argnames         => [qw/pattern flags/],
		function         => sub {
			my (undef, $re, $flags) = @_;
			if ($re->class eq 'RegExp' and !defined $flags
			    || $flags->id eq 'undef') {
				return $re
			}
			unshift @_, __PACKAGE__;
			goto &new;
		},
		function_args    => ['scope','args'],
		constructor      => sub {
			unshift @_, $package;
			goto &new;
		},
		constructor_args => ['scope','args'],
	});

	my $proto = $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	});
	$global->prototype_for('RegExp', $proto);

	$f->prop({
	 name => '$&',
	 dontdel => 1,
	 fetch => sub { shift->prop('lastMatch') },
	 store => sub { shift->prop('lastMatch', shift) },
	});
	$f->prop({
	 name => '$`',
	 dontdel => 1,
	 fetch => sub { shift->prop('leftContext') },
	 store => sub { shift->prop('leftContext', shift) },
	});
	$f->prop({
	 name => '$\'',
	 dontdel => 1,
	 fetch => sub { shift->prop('rightContext') },
	 store => sub { shift->prop('rightContext', shift) },
	});
	$f->prop({
	 name => '$+',
	 dontdel => 1,
	 fetch => sub { shift->prop('lastParen') },
	 store => sub { shift->prop('lastParen', shift) },
	});
	my $empty = JE::String->new($global,"");
	for(
	 qw(lastParen lastMatch leftContext rightContext),
	 map "\$$_", 1..9
	) {
		$f->prop({ name => $_, dontdel => 1, value => $empty});
	}
	
	$proto->prop({
		name  => 'exec',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'exec',
			argnames => ['string'],
			no_proto => 1,
			function_args => ['this','args'],
			function => \&call,
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'test',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'test',
			argnames => ['string'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
				my ($self,$str) = @_;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to test is not a " .
					"RegExp object"
				) unless $self->class eq 'RegExp';
				my $ret = call($self,$str);
				JE::Boolean->new(
					$global, $ret->id ne 'null'
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my ($self,) = @_;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to toString is not a " .
					"RegExp object"
				) unless $self->class eq 'RegExp';
				JE::String->_new(
					$global,
					"/" . $self->prop('source')->value
					. "/$$$self{regexp_flags}"
				);
			},
		}),
		dontenum => 1,
	});


	$f;
}


=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Object

=back

=cut


