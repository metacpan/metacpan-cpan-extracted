#####################################
package HTML::Merge::Compile;
#####################################
BEGIN 
{
	eval 'use HTML::Merge::Ext;';
}
# Modules ########################### 

use strict qw(subs vars);
use vars qw($open %enders %printers %tokenizers $VERSION $DEBUG 
		$INTERNAL_DB $INTERNAL_DB_TYPE);
use Carp;
use Config;
use subs qw(quotemeta);

#####################################
$VERSION = '3.54';
#####################################
# Globals ###########################
$open = '\$R';
#my @non_flow = qw(VAR SQL ASSIGN SET PSET PGET PIC STATE INDEX CFG);
#@non_flow{@non_flow} = @non_flow;

my @printers = qw(VERSION VAR SQL GET PGET PVAR INDEX PIC STATE CFG INI LOGIN 
	AUTH DECIDE EMPTY DATE DAY MONTH YEAR DATEDIFF LASTDAY ADDDATE
	USER MERGE TEMPLATE TRANSFER DUMP NAME TAG COOKIE SOURCE
	DATE2UTC UTC2DATE ENV DATEF EVAL HOUR MINUTE SECOND);
@printers{@printers} = @printers;

#my @stringers = qw(IF SET PSET SETCFG);
#@stringers{@stringers} = @stringers;

my @tokenizers = qw();
@tokenizers{@tokenizers} = @tokenizers;

%enders = qw(END_IF IF END LOOP END_WHILE WHILE);

$INTERNAL_DB_TYPE='SQLite';

#####################################
# locate the template from the various paths
sub GetTemplateFromPath
{
	my ($template) = @_;

        my @input = ("$HTML::Merge::Ini::TEMPLATE_PATH/$template",
         	     "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/public/template/$template");

        # let lets find the input
        foreach (@input)
        {
                if (-f)
                {
                        return $_;
                }
	}
	
	return "$HTML::Merge::Ini::TEMPLATE_PATH/$template";
}
#####################################
sub WantPrinter 
{
	my ($self, $tag, $dtag, $dline) = @_;

	my $ret = $self->WantTag($tag);
	return $ret if ($printers{$tag});
	my $line = $self->Line;
	$self->Die("$tag is not an output tag, perhaps you forgot to close a string in tag $dtag from line $dline? Output tags are " . join(", ", keys %printers));
}
#####################################
sub Translate 
{
	my ($self, $exp) = @_;
	my $result = "\\\\[=\\.]";
	my $i;
	my @fetch;
	my $tail;

	while ($exp =~ s/^(.*?)([QUELD])//i) 
	{
		my ($before, $token) = ($1, uc($2));
		$result .= quotemeta(quotemeta($before));

		if ($token eq 'U') 
		{
			$result .= '(.*?)';
			$i++;
			push(@fetch, "\$$i");
		} 
		elsif ($token eq 'L') 
		{
			$result .= '([A-Z])';
			$i++;
			push(@fetch, "\$$i");
		} 
		elsif ($token eq 'Q') 
		{
			$i++;
			$result .= "\\\\(['\"])(.*?)\\\\\\$i";
			$i++;
			push(@fetch, "\$$i");
		} 
		elsif ($token eq 'E') 
		{
			$result .= '(?:';
			$tail = ')?' . $tail;
		} 
		elsif ($token eq 'D') 
		{
			$result .= "\\\\[\\.=]";
		} 
		else 
		{
			$self->Die("Unknown notator: $token");
		}
	}

	$result .= quotemeta(quotemeta($exp)) . $tail;
	my $fetch = '(' . join(", ", @fetch) . ')';
	($result, $fetch);
}
#################################
# CGI parsing utility		#
#################################
sub ParseForm
{
        my $toParse = shift;
        my ($name , $value , @pairs , $pair , %FORM);
        @pairs = split(/&/, $toParse);
        foreach $pair (@pairs) {
                ($name, $value) = split(/=/, $pair);
                $value =~ tr/+/ /;
                $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
                $FORM{$name} = $value;
                #Debug("kak : $name \=  $value");
        }
        return \%FORM;
}
#####################################
sub CgiParse
{
        my $GFORM =  &ParseForm($ENV{'QUERY_STRING'});
        my $buffer;
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
        my $PFORM = &ParseForm($buffer);

        my (%FORM , $key);
        foreach $key(keys %$GFORM){
                $FORM{$key} = $GFORM->{$key};
        }

        foreach $key(keys %$PFORM){
                $FORM{$key} = $PFORM->{$key};
        }
        return \%FORM;
}
#####################################
sub WantTag 
{
	my ($self, $tag, $inv) = @_;
	my $candidate = $enders{$tag};
	if ($candidate && !$inv) 
	{
		$tag = $candidate;
		$inv = 1;
	}
	my $un = $inv ? "Un" : "";
	my $code = UNIVERSAL::can($self, "Do$un$tag");
	return $code if $code;
	my $macro = UNIVERSAL::can('HTML::Merge::Ext', "MACRO_$tag");
	if ($macro) 
	{
		my $proto = prototype("HTML::Merge::Ext::MACRO_$tag");
		my $text = quotemeta(&$macro);
		$proto = " ($proto)" if $proto;

		eval <<EOM;
		package HTML::Merge::Ext;

		sub API_$tag$proto 
		{
			Macro("$text", \@_);
		}
EOM
	}

	foreach my $api (qw(API OUT)) 
	{
		my $candidate = "RUN${api}_$tag";
		my $code = UNIVERSAL::can('HTML::Merge::Ext', $candidate);
		if ($code)
		{
			my $proto = prototype("HTML::Merge::Ext::$candidate");
			$proto =~ s/;.*$//;
			$self->Die("Prototype for $candidate may include only \$ signs")
			unless ($proto =~ /^\$*$/);
			my $check = "${api}_$tag";
			my $code = UNIVERSAL::can('HTML::Merge::Ext', $check);
			unless ($code) 
			{
				my @par;
				my $i = 0;
				foreach (split(//, $proto)) 
				{
					push(@par, qq{"\$_[$i]"});
					$i++;
				}
				my $pass = join(", ", @par);
				my $text = "package HTML::Merge::Ext;
					sub $check ($proto) 
					{
						$candidate($pass);
					}";
				eval $text;
				die $@ if $@;
				last;
			}
		}
	}
	my @options = !$inv ? qw(API OAPI OUT) : qw(CAPI);
	foreach my $api (@options) 
	{
		my $candidate = "${api}_$tag";
		$code = UNIVERSAL::can('HTML::Merge::Ext', $candidate);
		if ($code) 
		{
			my $ref = ref($self);
			my $proto = prototype("HTML::Merge::Ext::$candidate");
			$proto =~ s/;.*$//;
			$self->Die("Prototype for $candidate may include only \$ signs")
				unless ($proto =~ /^\$*$/);
			my $n = length($proto);
			my $shift = join(", ",
				map {"\$param[$_]";} (0 .. $n - 1));
			my $stack;
			my $scope = lc($tag);
			if ($api eq 'OAPI') 
			{
				$stack = qq!\$self->Push('$scope', \$engine);!;
			}
			if ($api eq 'CAPI') 
			{
				$stack = qq!\$self->Expect(\$engine, '$scope');!
			}
			my $desc = UNIVERSAL::can('HTML::Merge::Ext',
				"DESC_$tag");
			my $expand;
			unless ($desc) 
			{
				$expand = 'my @param = @$param;';
				$tokenizers{$tag} = 1;
			} 
			else 
			{
				if ($api eq 'CAPI') 
				{
					$expand = 'my @param;';
				} 
				else 
				{
					my $txt = &$desc;
					my ($re, $form) = $self->Translate($txt);
					$expand = <<EOM;
	unless (\$param =~ /^$re\$/s) 
	{
		\$self->Syntax;
	}
	my \@param = $form;
EOM
				}
			}
			my $extend = <<EOM;
package $ref;
sub Do$un$tag 
{
	my (\$self, \$engine, \$param) = \@_;
	$expand
	my \$n = \@param;
	\$self->Die("$n parameters expected for $tag, gotten \$n") unless (\$n == $n);
	$stack
	\$HTML::Merge::Ext::ENGINE = \$engine;
	\$HTML::Merge::Ext::COMPILER = \$self;
	HTML::Merge::Ext::$candidate($shift);
}
EOM
			eval $extend;
			$self->Die($@) if $@;
			$printers{$tag} = ($api eq 'OUT');
			return $self->WantTag($tag, $inv);
		}
	}
	$self->Die("$tag is not a valid Merge tag");
}
#####################################
sub quotemeta {
	my $text = CORE::quotemeta(shift);
	$text =~ s/\\ / /g;
	$text =~ s/\\\t/\t/g;
	$text;
}
#####################################
sub Compile {
	my $self = {'buffer' => '', 'scopes' => []};
	my $class = __PACKAGE__;
	my $in = $HTML::Merge::config;
	$in =~ s|/\w+\.\w+$||;
	$in =~ s|^/*||;
	$in =~ s/[\/\\]/::/g;
	$in =~ tr/A-Za-z0-9_://cd;
	if ($in) {
		my $code =  <<EOM;
package ${class}::$in;
use strict 'vars';
use vars qw(\@ISA);
\@ISA = qw($class);
EOM
		eval $code;
		die $@ if $@;
		$class .= "::$in";
	}
	bless $self, $class;
	$self->{'source'} = shift;
	$self->{'source'} =~ s/\r\n/\n/g;
	$self->{'save'} = $self->{'source'};
	$self->{'name'} = shift;
	$self->{'template'} = $self->{'name'};
	$self->{'template'} =~ s|^$HTML::Merge::Ini::TEMPLATE_PATH/||;
	$self->{'force line'} = shift;
	$self->Main;
	$self->{'buffer'};
}
#####################################
sub Clone {
	my $self = shift;

	return bless {},ref($self);
}
#####################################
sub Clause {
	my ($self,$text,$in) = @_;

	my $new=$self->Clone();
	my $error;
	my $res;

	$new->{'save'} = $new->{'source'} = "$text>";	
	eval{
		$res=$new->EatParam($in);
	};

	if($@){
		$error=$@;
		$error=~ s/ at .* line .*$//;
		$self->Die($error);		
	}
	$res=~ s/\n+$//s;

	return $res;
}
#####################################
sub Line {
	my $self = shift;
	my $force = $self->{'force line'};
	return $force if $force;
	my @lines = split(/\n/, $self->{'save'});
	my $left = substr($self->{'save'}, -length($self->{'source'}));
	my @ll = split(/\n/, $left);
	my $this = @lines - @ll + 1;
}
#####################################
sub Mark {
	my $self = shift;
	my $name = $self->{'name'};
	my $this = $self->Line;
	return unless $name;
	$self->{'buffer'} .= "\$HTML::Merge::context = [\"$name\", \"$this\"];\n";
	$self->{'buffer'} .= "#line $this $name\n";
	return;
}
#####################################
sub Die {
	my ($self, $error) = @_;
	my $this = $self->Line;
	my $s = (split(/\n/, $self->{'save'}))[$this - 1];
	my $name = $self->{'name'};
	if ($error < 0) {
		die "Depcrecated: Die(negative)";
	}

	$name =~ s|^.*/||;		
	Carp::cluck "Error: $error at $name line $this when doing: $s" if $DEBUG
		|| $ENV{'MERGE_DEBUG'};
	die "Error: $error at $name line $this, when doing: $s";
}
#####################################
sub Main {
	my $self = shift;
	$self->{'source'} =~ s/<(BODY)/<!-- GENERATOR: "Merge v. $VERSION (c) Raz Information systems www.raz.co.il" -->\n<$1/i;
	while  ($self->EatOne) {}
	$self->PrePrint($self->{'source'});
	$self->{'source'} = '';
	if (@{$self->{'scopes'}}) {
		my @scopes = map {join("/", @$_);} @{$self->{'scopes'}};
		my $stack = join(", ", @scopes);
		$self->Die("Stack not empty: $stack");
	}
}
#####################################
sub EatOne {
	my $self = shift;
	if ($self->{'source'} =~ s/^(.*?)\<(\/?)$open(\[.+?\]\.)?(\w+)//si) {
		my ($head, $close, $engine, $tag, $param) = ($1, $2, $3, uc($4));
		$engine =~ s/^\[(.*)\]\./$1/;
		$engine= $self->Clause($engine,$tag) if($engine=~ /\<$open/);
	
		my $code = $self->WantTag($tag, $close);
		$param = $self->EatParam($tag);
		$self->Die("Closing tags may not have parameters") if (($close || $enders{$tag}) && ($param && !ref($param) || ref($param) && $#$param >= 0));
		$self->Mark;
		if ($printers{$tag}) {
			$self->PrePrint($head);
			$self->{'buffer'} .= "print (";
		} else {
			$head =~ s/\s+$//s;
			$self->PrePrint($head);
		}
		$self->{'buffer'} .= &$code($self, $engine, $param);
		if ($printers{$tag}) {
			$self->{'buffer'} .= ");\n";
		}
		return 1;
	}
	undef;
}
#####################################
sub Macro {
	my ($self, $text) = @_;
	my $length = length($self->{'source'});
	my $lennow;

	$self->{'source'} = $text . $self->{'source'};
	for (;;) {
		$lennow = length($self->{'source'});
		last if ($lennow <= $length);
		my $left = $lennow - $length;
		last if $self->{'source'} =~ /^\s{$left}/;

		$self->EatOne || last;
	}
	my $remainder = $lennow - $length;
	$self->Die("macro did not resolve correctly") if ($remainder < 0);
	$self->PrePrint(substr($self->{'source'}, 0, $remainder));
	substr($self->{'source'}, 0, $remainder) = "";
}
#####################################
sub PrePrint {
	my ($self, $string) = @_;
	while ($string =~ s/^(.*?)\0(.*?)\0//) {
		my ($b4, $bt) = ($1, $2);

		$self->Print($b4);
		$self->{'buffer'} .= qq'print "$bt";';
	}
	$self->Print($string) if $string;
}
#####################################
sub Print {
	my ($self, $string) = @_;
	my @lines = split(/\n/, $string);
	my $last = pop @lines;
	foreach (@lines) {
		$self->{'buffer'} .= 'print "' . quotemeta($_) . '\n";' . "\n";
	}
	$self->{'buffer'} .= 'print "' . quotemeta($last) . '";' . "\n";
	$self->{'buffer'} .= 'print "\n";' . "\n" if ($string =~ /\n$/);
}
#####################################
sub EatParam {
	my ($self, $in) = @_;
	my $tokens = $tokenizers{$in};
	my $line = $self->Line;
	my $state = '';
	my $text = '';
	my @tokens;
	for (;;) {
		my $ch;
		if ($self->{'source'} =~ s/^(.)//s) {
			$ch = $1;
		} else {
			$self->Die("Could not close tag $in, probably unbalanced quotes");
		}
		if ($ch eq "\0") {
			unless ($self->{'source'} =~ s/^(.*?)\0//) {
				$self->Die("Unclosed null encpasulation. Check your macro");
			}
			$text .= $1;
			next;
		}
		if ($ch eq "'" && $state ne '"') {
			$text .= "\\'";
			$state = ($state eq "'" ? '' : "'");
			next;
		}
		if ($ch eq '"' && $state ne "'") {
			$text .= "\\\"";
			$state = ($state eq '"' ? '' : '"'); #'"
			next;
		}
		if ($ch eq "\\") {
			$self->{'source'} =~ s/^(.)//s;
			$ch = $1;
			$text .= "\\$ch";
			next;
		}
		if ($ch eq '>' && !$state) {
			$text =~ s/\s+$//;
			return $text unless $tokens;	
			return [] unless @tokens;
			my $pre = shift @tokens;
			$self->Die("Illegal prefix $pre") if $pre;
			push(@tokens, $text);
			return \@tokens;
		}
		if ($ch eq '.' && !$state && $tokens) {
			push(@tokens, $text);
			$text = '';
			next;
		}
		if ($ch eq "<") {
			unless ($self->{'source'} =~ s/^$open//) {
				$text .= "<";
				$text .= $self->FindRight if $in eq 'EM';
				next;
			}
			$self->{'source'} =~ s/(\[.+?\]\.)?(\w+)//;
			my $engine = $1;
			my $tag = uc($2);
			$engine =~ s/^\[(.*)\]\./$1/;
			$engine= $self->Clause($engine,$tag) if($engine=~ /\<$open/);
			my $code;
			if ($in ne 'EM') {
				$code = $self->WantPrinter($tag, $in, $line);
			}
			my $sub = $self->EatParam($in eq 'EM' ? 'EM' : $tag);
			if ($in ne 'EM') {
				$text .= '" . (' . &$code($self, $engine, $sub) . ') . "';
			}
		} else {
			$text .= quotemeta($ch);
		}
	}
}
#####################################
sub FindRight {
	my $self = shift;
	my $count = 1;
	my $text;
	while ($self->{'source'} =~ s/^(.*?)([\<\>])//) {
		$text .= "$1$2";
		$count += $2 eq '<' ? 1 : -1;
		return $text unless $count;
	}
	return $text;
}
#####################################
sub Expect {
	my ($self, $engine, @options) = @_;
	my $current = pop @{$self->{'scopes'}};
	my @topt = @options;
	my $last = pop @topt;
	my $expect = join(", ", @topt) . (@topt ? ' or ' : '') . $last;
	$self->Die("Stack underflow - a closing tag without a preceding tag, expecting: $expect. Perhaps you forgot $open in the opening tag?") unless ($current);
	my ($scope, $teng) = @$current;
	$self->Die("Expected engine '$engine', got '$teng'") unless ($teng eq $engine);
	foreach (@options) {
		return if ($_ eq $scope);
	}
	$self->Die("Unexpected scope $scope, expecting: $expect. Perhaps you forgot $open in the opening tag?");
}
#####################################
sub Push {
	my ($self, $scope, $engine) = @_;
	push(@{$self->{'scopes'}}, [$scope, $engine]);
}
#####################################
sub DoLOOP {
	my ($self, $engine, $param) = @_;
	my $limit = undef;
	if ($param =~ s/^\\\.LIMIT\\=((?:\\['"])?)(.+)\1$//s) { #'
		$limit = $2;
	}
	$self->Syntax if $param;
	my $text;
	unless ($limit) {
		$text = <<EOM;
local (\$_);
for (;;) {
	\$_++;
EOM
	} else {
		$text = <<EOM;
HTML::Merge::Engine::Force("$limit", 'iu');
foreach (1 .. "$limit") {
EOM
	}
	$text .= <<EOM;
	last unless (\$engines{"$engine"}->HasQuery);
	last unless (\$engines{"$engine"}->Fetch(1, \$_));
	local (\$_);
EOM
	$self->Push('loop', $engine);
	$text;
}
#####################################

*DoEPEAT = \&DoITERATION;
*DoUnEPEAT = \&DoUnITERATION;

#####################################
sub DoITERATION {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.LIMIT\\=((?:\\['"])?)(.+)\1$/s) { #'
		$self->Syntax;
	}
	my $limit = $2;
	$self->Push('iteration', $engine);
<<EOM;
HTML::Merge::Engine::Force("$limit", 'ui');
foreach (1 .. "$limit") {
EOM
}
#####################################
sub DoUnITERATION {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'iteration');
	"}\n";
}
#####################################
sub DoBREAK {
	my ($self, $engine, $param) = @_;
	$self->Syntax if ($param);
	"last;";
}

#####################################
sub DoCONT {
	my ($self, $engine, $param) = @_;
	$self->Syntax if ($param);
	"next;";
}
#####################################
sub DoUnLOOP {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'loop');
	"}\n";
}
#####################################
sub DoFETCH {
	my ($self, $engine, $param) = @_;
	$self->Syntax if ($param);
	"\$engines{\"$engine\"}->Fetch(1, 2);";
}
#####################################

*DoENVGET = \&DoENV;

#####################################
sub DoENV {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+)$//s) {
		$self->Syntax;
	}
	return "\$ENV{\"$1\"}";
}
#####################################
sub DoENVSET {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+?)\\=\\(['"])(.*?)\\\2$//s) {
		$self->Syntax;
	}
	"\$ENV{\"$1\"} = eval(\"$3\");\n";
}
#####################################
sub DoCFG {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+)$//s) {
		$self->Syntax;
	}
	"\${\"HTML::Merge::Ini::\"  . \"$1\"}";
}
#####################################

*DoINIGET = *DoINI = *DoCFGGET = \&DoCFG;
*DoINISET = \&DoCFGSET;

#####################################
sub DoCFGSET {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+?)\\=\\(['"])(.*)\\\2$//s) {
		$self->Syntax;
	}
	"\${\"HTML::Merge::Ini::\"  . \"$1\"} = eval(\"$3\");\n";
}
#####################################

*DoVAL = \&DoVAR;

#####################################
sub DoVAR 
{
	my ($self, $engine, $param) = @_;

	unless ($param =~ s/^\\\.(.+)$//s) 
	{
		$self->Syntax;
	}

	return "\$vars{\"$1\"}";
}
#####################################
sub DoVERSION 
{
	my ($self, $engine, $param) = @_;

	return $VERSION;
}
#####################################
sub DoSQL 
{
	my ($self, $engine, $param) = @_;

	unless ($param =~ s/^\\\.(.+)$//s) 
	{
		$self->Syntax;
	}

	return "\$engines{\"$engine\"}->Var(\"$1\")";
}
#####################################
sub DoIF 
{
	my ($self, $engine, $param) = @_;

	unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) 
	{
		$self->Syntax;
	}

	my $text = <<EOM;
HTML::Merge::Error::HandleError('INFO', "$2", 'IF');
my \$__test = eval("$2");
HTML::Merge::Error::HandleError('ERROR', \$@) if (\$@);
if (\$__test) {
EOM
	$self->Push('if', $engine);
	$text;
}
#####################################
sub DoTIF 
{
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) 
	{
		$self->Syntax;
	}

	my $text = <<EOM;
HTML::Merge::Error::HandleError('INFO', "$2", 'IF');
my \$__test = "$2";
HTML::Merge::Error::HandleError('ERROR', \$@) if (\$@);
if ("$2") {
EOM
	$self->Push('if', $engine);
	$text;
}
#####################################
sub DoUnTIF {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'if', 'else');
	"}\n";
}
#####################################
sub DoELSIF {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	$self->Expect($engine, 'if');
	$self->Push('if', $engine);
	my $text = <<EOM;
	\$__exit = 0;
} elsif (((HTML::Merge::Error::HandleError('INFO', "$2", 'IF'),
	\$__exit = eval("$2"),
	\$@ && HTML::Merge::Error::HandleError('ERROR', \$@),
	\$__exit))[-1]) {
EOM
	$text;
}


sub DoUnIF {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'if', 'else');
	"}\n";
}

sub DoELSE {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	$self->Expect($engine, 'if');
	$self->Push('else', $engine);
	"} else {\n";
}

sub DoWHILE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $cond = quotemeta($2);
	my $text = <<EOM;
HTML::Merge::Error::HandleError('INFO', "while $2", 'WHILE');
for (;;) {
	my \$__test = eval("$2");
	HTML::Merge::Error::HandleError('ERROR', \$@) if (\$@);
	last unless \$__test;
EOM
	$self->Push('while', $engine);
	$text;
}

sub DoUnWHILE {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'while');
	"}\n";
}

sub DoQ {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\[=\.]\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	"\$engines{\"$engine\"}->Query(\"$2\");\n";
}

sub DoS {
        my ($self, $engine, $param) = @_;
        unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) {
                $self->Syntax;
        }
        "\$engines{\"$engine\"}->Statement(\"$2\");\n";
}

sub DoEVAL {
        my ($self, $engine, $param) = @_;
        unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) {
                $self->Syntax;
        }
        "eval(\"$2\")";
}
#####################################
sub DoPERL {
        my ($self, $engine, $param) = @_;
	my $type;
	if ($param =~ s/^\\\.([ABC])$//i) {
		$type = uc($1);
	}
	$self->Syntax if $param;
	my $code = "";
	my $line = $self->Line;
	if ($type eq 'B' || $type eq 'C') {
		my $flag;
		while ($self->{'source'} =~ s/^(.*?)\<($open(?:\[.+?\]\.)?\w+|\/${open}PERL\>)//is) {
			my $let = quotemeta($1);
			$code .= qq!"$let" . !;
			my $tag = $2;
			if ($tag =~ m|^/${open}PERL>$|) {
				$flag = 1;
				last;
			}
			$tag =~ s/^$open//;
			my $engine = '';
			if ($tag =~ s/^\[(.+?)\]\.//) {
				$engine = $1;
				$engine= $self->Clause($engine,$tag) if($engine=~ /\<$open/);
			}
			my $coder = $self->WantPrinter($tag, "PERL", $line);
			my $param = $self->EatParam($tag);
			my $codet = &$coder($self, $engine, $param);
			$code .= "$codet . ";
		}
		$self->Die("End of PERL not found") unless $flag;
		$code .= q!""!;
	} else {
		unless ($self->{'source'} =~ s/^(.*?)\<\/${open}PERL\>//is) {
			$self->Die("End of PERL not found");
		}
		$code = '"' . quotemeta($1) . '"';
	}
	my $name = $self->{'name'};
	my $text = <<EOM;
\$__result = $code;
HTML::Merge::Error::HandleError('INFO', \$__result, 'PERL');
\$__result = eval("\$__result; undef;");
HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
EOM
	if ($type eq 'A' || $type eq 'C') {
		$line = $self->Line;
		$text .= <<EOM;
if (\$__result) {
	use HTML::Merge::Compile;
	eval { \$__result = &HTML::Merge::Compile::Compile(\$__result, "$name", $line); };
	HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
	\$__result = eval(\$__result);
	HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
}
EOM
	}
	$text;
}
###############################################################
sub DoSET 
{
        my ($self, $engine, $param) = @_;

	unless ($param =~ s/^\\\.(.+?)\\=\\(['"])(.*?)\\\2$//s) 
	{
		$self->Syntax;
	}

	return "\$vars{\"$1\"} = eval(\"$3\");\n";
}
###############################################################
sub DoASSIGN 
{
        my ($self, $engine, $param) = @_;

	unless ($param =~ s/^\\\.(.+?)\\=\\(['"])(.*?)\\\2$//s) 
	{
		$self->Syntax;
	}

	return "\$vars{\"$1\"} = \"$3\";\n";
}
###############################################################

sub DoPCLEAR {
        my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	"\$engines{\"$engine\"}->ErasePersistent;\n";
}

sub DoPSET {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+?)\\=\\(['"])(.*?)\\\2$//s) {
		$self->Syntax;
	}
	"\$engines{\"$engine\"}->SetPersistent(\"$1\", eval(\"$3\"));\n";
}

sub DoPGET {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+)$//s) {
		$self->Syntax;
	}
	return "\$engines{\"$engine\"}->GetPersistent(\"$1\")";
}

*DoPVAR = \&DoPGET;
*DoGET = \&DoVAR;

sub DoPIMPORT {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+)$//s) {
		$self->Syntax;
	}
	return "\$hash{\"$1\"} = \$engines{\"$engine\"}->GetPersistent(\"$1\");";
}

sub DoPEXPORT {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.+)$//s) {
		$self->Syntax;
	}
	return "\$engines{\"$engine\"}->SetPersistent(\"$1\", \$hash{\"$1\"});";
}


*DoREM = \&DoEM;
sub DoEM {}

sub DoTRACE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $line = $2;
	<<EOM;
HTML::Merge::Error::HandleError('INFO', "$line", 'TRACE');
EOM
}
sub DoDIE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $line = $2;
	<<EOM;
HTML::Merge::Error::HandleError('ERROR', "$line");
EOM
}
#################################################
sub DoINCLUDE 
{
	my ($self, $engine, $param) = @_;
	my $inc;
	my $name = $self->{'name'};
	my $text;

	unless ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) 
	{
		$self->Syntax;
	}
	$inc = $2;
	$inc =~ s/\\(.)/$1/g;

##################################################################
#	require Cwd;
#	my $curr = &Cwd::cwd;
#	my @tokens = split(/\//, $self->{'name'});
#	pop @tokens;
#	my $dir = join("/", @tokens);
#	chdir $dir if $dir;
#	open(I, $inc) || $self->Die("Can't open $inc at $dir");
#	my $text = join("", <I>);
#	close(I);
#	chdir $curr;
#	$self->{'source'} = $text . $self->{'source'};
##################################################################

	$text = <<EOM;
	my \$__input = HTML::Merge::Compile::GetTemplateFromPath("$inc");
	my \$__script = "\$HTML::Merge::Ini::CACHE_PATH/$inc.pli";
	my \$__candidate = "\$HTML::Merge::Ini::PRECOMPILED_PATH/$inc.pli";

	unless (-e \$__candidate) 
	{
		#HTML::Merge::Error::DoWarn('NO_TEMPLATE','$inc') unless -e \$__input;
		HTML::Merge::Error::HandleError('ERROR',
			"No template '$inc' found") unless -e \$__input;

		my \$__source = (stat(\$__input))[9];
		my \$__output = (stat(\$__script))[9];
		if (\$__source > \$__output) {
			require HTML::Merge::Compile;
			HTML::Merge::Compile::safecreate(\$__script)
				unless -e \$__script;
			eval '	HTML::Merge::Compile::CompileFile(\$__input, \$__script, 1); ';

			if(\$@)
			{
				# erase the pli file
				unlink(\$__script);
				HTML::Merge::Error::HandleError('ERROR', \$@);
			}
		}
	} else {
		\$__script = \$__candidate;
	}
	HTML::Merge::Error::HandleError('INFO',"$inc",'INCLUDE');
	do \$__script;
	HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
EOM
	$text;
}
#################################################
sub DoWEBINCLUDE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $url = $2;
<<EOM;
if (\$HTML::Merge::Ini::WEB) {
	require LWP;
	require HTTP::Request::Common;
	import HTTP::Request::Common;

	my \$__url = "$url";
	\$__url = "http://\$ENV{'SERVER_NAME'}:\$ENV{'SERVER_PORT'}\$__url"
		unless (\$__url =~ m|://|);
	my \$__ua = new LWP::UserAgent;
	my \$__req = GET("$url");
	my \$__resp = \$__ua->request(\$__req);
	if (\$__resp->is_success) {
		print \$__resp->content;
	} else {
		HTML::Merge::Error::HandleError('ERROR', "Web GET to URL $url returned code " . \$__resp->code);
	}
}
EOM
}

sub DoINDEX {
        my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	"\$engines{\"$engine\"}->Index";
}

*DoRERUN = \&DoERUN;

sub DoERUN {
        my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	"\$engines{\"$engine\"}->ReRun;";
}

*EQUEST = \&ENUMREQ;

sub DoENUMREQ {
	my ($self, $engine, $param) = @_;
	$self->Syntax unless ($param =~ /^\\\.(.+?)\\\=(.+)$/s);
	my ($iterator, $getter) = ($1, $2);
	$self->Push('enumreq', $engine);
	qq!foreach (param()) {
		next if (\$_ eq "template");
		\$vars{"$iterator"} = \$_;
		\$vars{"$getter"} = \$vars{\$_};\n!;
}

sub DoUnENUMREQ {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'enumreq');
	"}\n";
}

sub DoENUMQUERY {
	my ($self, $engine, $param) = @_;
	$self->Syntax unless ($param =~ /^\\\.(.+?)\\\=(.+)$/s);
	my ($iterator, $getter) = ($1, $2);
	$self->Push('enumquery', $engine);
	qq!foreach (\$engines{"$engine"}->Columns) {
		\$vars{"$iterator"} = \$_;
		\$vars{"$getter"} = \$engines{"$engine"}->Var(\$_);\n!;
}

sub DoUnENUMQUERY {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'enumquery');
	"}\n";
}

sub DoMULTI {
	my ($self, $engine, $param) = @_;
	$self->Syntax unless ($param =~ /^\\\.(.+?)\\\=(.+)$/s);
	my ($iterator, $getter) = ($1, $2);
	$self->Push('multi', $engine);
	qq!foreach (param("$getter")) {
		\$vars{"$iterator"} = \$_;!;
}

sub DoUnMULTI {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'multi');
	"}\n";
}

sub DoGLOB {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.([DF])\\\.(.+?)\\=\\(['"])(.*)\\\3$/is) {
		$self->Syntax;
	}
	my ($how, $iterator, $mask) = (uc($1), $2, $4);
	$self->Push('glob', $engine);
	my $cond = $how eq 'D' ? 'unless' : 'if';
	qq!\$__x = "$mask";
	\$__x .= "/*" if (-d \$__x);
	foreach (glob(\$__x)) {
		next $cond -d \$_;
		s|^.*/||;
		\$vars{"$iterator"} = \$_;\n!
}

sub DoUnGLOB {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'glob');
	"}\n";
}

sub DoFTS {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.(.+?)\\=\\(['"])(.*)\\\2$/is) {
		$self->Syntax;
	}
	my ($iterator, $base) = ($1, $3);
	$self->Push('fts', $engine);
	<<EOM;
	use File::Find;
	\@__files = ();
	find(sub {push(\@__files, \$File::Find::name)}, "$base");
	foreach (\@__files) {
		\$vars{"$iterator"} = \$_;
EOM
}

sub DoUnFTS {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'fts');
	"}\n";
}

sub DoCOUNT {
	my ($self, $engine, $param) = @_;
	$self->Syntax unless ($param =~ /^\\\.(.+?)\\\=(.*?)\\\:(.*?)(\\,.*)?$/s);
	my ($var, $from, $to, $step) = ($1, $2, $3, $4);
	$step ||= "\\,1";
	$step =~ s/^\\,//;

	my $i = "\$vars{\"$var\"}";
	$self->Push('count', $engine);
	<<EOM;
	HTML::Merge::Engine::Force("$from", "n");
	HTML::Merge::Engine::Force("$to", "n");
	HTML::Merge::Engine::Force("$step", "n");
	for ($i = "$from"; $i <= "$to"; $i += "$step") {
EOM
}

sub DoUnCOUNT {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'count');
	"}\n";
}

sub DoPIC {
	my ($self, $engine, $param) = @_;
	my $type;
	unless ($param =~ s/^\\\.([CFRNADX])(.*)$//is) {
		$self->Syntax;
	}
	($type, $param) = (uc($1), $2);
	my $code = &UNIVERSAL::can($self, "Picture$type");
	&$code($self, $param);
}

sub PictureF {
	my ($self, $param) = @_;
	$param =~ s/^\\\((\\?.)\\\)\\\.\\(['"])(.*?)\\\2$/$1\\$2$3\\$2/s;
	unless ($param =~ /^(\\?.)\\(['"])(.*?)\\\2$/s) {
		$self->Syntax;
	}
	my ($ch, $text) = ($1, $3);
	<<EOM;
"" . (\$__s = "$text", \$__s =~ s/\\s/$ch/g, \$__s)[-1]
EOM
}

sub PictureC {
	my ($self, $param) = @_;
	my @ary;
	my $flag;
	$param =~ s/^\\\((.*)\\\)\\\.\\(['"])(.*?)\\\2$/$1\\.\\$2$3\\$2/s;
	while ($param =~ 
			s/^\s*\\(['"])(.*?)\\\1\s*\\=\s*\\(['"])(.*?)\\\3\s*//s) {
		push(@ary, [$2, $4]);
		if ($param =~ s/^\\\.//) {
			$flag = 1;
			last;
		}
		unless ($param =~ s/^\\,//) {
			$self->Syntax;
		}
	}
	$self->Die("Syntax error in PIC.C") unless ($flag);
	unless ($param =~ s/^\\(["'])(.*?)\\\1$//s) {
		$self->Syntax;
	}
	my $text = $2;
	my $code = <<EOM;
"" . (\$__s = "$text",
EOM
	foreach (@ary) {
		my ($from, $to) = @$_;
		$code .= <<EOM;
\$__s =~ s/^$from\$/$to/g,
EOM
	}
	$code . ", \$__s)[-1]";
}

sub PictureR {
	my ($self, $param) = @_;
	my @ary;
	my $flag;
	$param =~ s/^\\\((.*)\\\)\\\.\\(['"])(.*?)\\\2$/$1\\.\\$2$3\\$2/s;
	while ($param =~ 
			s/^\s*\\(['"])(.*?)\\\1\s*\\=\s*\\(['"])(.*?)\\\3\s*//s) {
		push(@ary, [$2, $4]);
		if ($param =~ s/^\\\.//) {
			$flag = 1;
			last;
		}
		unless ($param =~ s/^\\,//) {
			$self->Syntax;
		}
	}
	$self->Die("Syntax error in PIC.R") unless ($flag);
	unless ($param =~ s/^\\(["'])(.*?)\\\1$//s) {
		$self->Syntax;
	}
	my $text = $2;
	my $code = <<EOM;
"" . (\$__s = "$text",
EOM
	foreach (@ary) {
		my ($from, $to) = @$_;
		$code .= <<EOM;
\$__s =~ s/$from/$to/g,
EOM
	}
	$code . ", \$__s)[-1]";
}

sub PictureN {
	my ($self, $param) = @_;
	my %opts;
	while ($param =~ s/^([ZF])//) {
		$opts{$1}++;
	}
	unless ($param =~ s/^\\\((.*?)\\\)//s) {
		$self->Syntax;
	}
	my $format = $1;
	unless ($param =~ s/^\\\.\\(["'])(.*?)\\\1$//s) {
		$self->Syntax;
	}
	my $text = $2;
	<<EOM;
"" . (\$__s = "$text" || !"$opts{'Z'}" ? sprintf("%${format}f", "$text") : "&nbsp;",
	"$opts{'F'}" ? (\$__s =~ 
	s!(\\d+)!scalar(reverse join(\$HTML::Merge::Ini::THOUSAND_SEPARATOR || ",", (reverse \$1) =~ /(\\d{1,3})/g))!e) : undef, 
	\$__s =~ s/\\./\$HTML::Merge::Ini::DECIMAL_SEPARATOR || '.'/e,
	\$__s)[-1]
EOM
}

sub PictureA {
	my ($self, $param) = @_;
	my %opts;
	while ($param =~ s/^([LRCSPWDE])//) {
		$opts{$1}++;
	}
	foreach (qw(SCP DE)) {
		my $count;
		foreach (split(//)) {
			$self->Die("Illegal flag combinations") 
				if ($opts{$_} && $count++);
		}
	}
	unless ($param =~ s/^\\\((.*?)\\\)//s) {
		$self->Syntax;
	}
	my $format = $1;
	unless ($param =~ s/^\\\.\\(["'])(.*?)\\\1$//s) {
		$self->Syntax;
	}
	my $text = $2;
	<<EOM;
"" . (\$__s = "$text",
	"$opts{'C'}" && \$__s =~ tr/a-z/A-Z/,
	"$opts{'S'}" && \$__s =~ tr/A-Z/a-z/,
	"$opts{'P'}" && \$__s =~ s/\\b([a-z]\\S+)/ucfirst(lc(\$1))/egi,
	"$opts{'L'}" && \$__s =~ s/^\\s+//,
	"$opts{'R'}" && \$__s =~ s/\\s+\$//,
	"$opts{'W'}" && \$__s =~ s/\\s{2,}/ /g,
	"$opts{'E'}" && (\$__s =~ s/([^ _A-Za-z0-9-\\/])/sprintf("%%%02X", ord(\$1))/ge, \$__s =~ s/ /+/g),
	"$opts{'D'}" && (\$__s =~ s/\\+/ /g, \$__s =~ s/%(..)/chr(hex(\$1))/ge),
	sprintf("%${format}s", \$__s))[-1]
EOM
}

sub PictureD {
	my ($self, $param) = @_;
	unless ($param =~ s/^\\\((.*?)\\\)//s) {
		$self->Syntax;
	}
	my $format = $1;
	unless ($param =~ s/^\\\.\\(["'])(.*?)\\\1$//s) {
		$self->Syntax;
	}
	my $date = $2;

	<<EOM;
(require Time::Local, 
("$date") =~ /^(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})\$/,
	\$__t = Time::Local::timelocal(\$6, \$5, \$4, \$3, \$2 - 1, \$1 - 1900),
	HTML::Merge::Engine::time2str("$format", \$__t))[-1]
	
EOM
}

sub PictureX {
	my ($self, $param) = @_;
	unless ($param =~ s/^\\\((.*?)\\\)//s) {
		$self->Syntax;
	}
	my $times = $1;
	unless ($param =~ s/^\\\.\\(["'])(.*?)\\\1$//s) {
		$self->Syntax;
	}
	my $text = $2;
	<<EOM;
(HTML::Merge::Engine::Force("$times", 'ui'),
	"$text" x "$times")[-1]
EOM
}

sub DoINC {
        my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.(.*?)(\\[+-]\d+)?$/s) {
		$self->Syntax;
	}
	my ($var, $step) = ($1, defined($2) ? $2 : 1);
	<<EOM;
HTML::Merge::Engine::Force("$step", "n");
HTML::Merge::Engine::Force(\$vars{"$var"}, "n");
\$vars{"$var"} += "$step";
EOM
}

sub DoSTATE {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	"\$engines{\"$engine\"}->State";
}

sub DoEMPTY {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	"\$engines{\"$engine\"}->Empty";
}

sub DoMAIL {
	my ($self, $engine, $param) = @_;
        unless ($param =~ /^\\\.\\(['"])(.*?)\\\1\\([\.,])\\(['"])(.*?)\\\4(.*)$/s) {
		$self->Syntax;
	}
	my $del = quotemeta($3);
	my ($from, $to, $rem, $subject) = ($2, $5, $6);
	if ($rem) {
		unless ($rem =~ /^\\$del\\(['"])(.*?)\\\1$/s) {
			$self->Syntax;
		}
		$subject = $2;
	}
	$self->Push('mail', $engine);
<<EOM;
	\$__from = "$from";
	\$__from =~ s/^.*\<(.*)\>\$/\$1/;
	\$__from =~ s/^(.*?)\\s+\(\".*\"\)\$/\$1/;
	\$__to = "$to";
	\$__to =~ s/^.*\<(.*)\>\$/\$1/;
	\$__to =~ s/^(.*?)\\s+\(\".*\"\)\$/\$1/;
	use HTML::Merge::Mail;
	eval '\$__mail = OpenMail(\$__from, \$__to, \$HTML::Merge::Ini::SMTP_SERVER);';

	HTML::Merge::Error::HandleError('WARN', 'Mail failed: \$\@') if \$\@;
	\$__prev = select \$__mail;

	print "From: $from\\r\\n";
	print "To: $to\\r\\n";
	print "Subject: $subject\\r\\n";
	print "X-Mailer: Merge v. $VERSION (c) http://www.raz.co.il\\r\\n";
	print "\\r\\n";
EOM
}
sub DoUnMAIL {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'mail');
	<<EOM;
	eval ' CloseMail(\$__mail); ';
        HTML::Merge::Error::HandleError('WARN', 'Mail failed: \$\@') if \$\@;
	select \$__prev;
EOM
}
#####################################
sub DoDB 
{
	my ($self, $engine, $param) = @_;
	
	my ($type, $db, $host);
	my ($dsn,$dsn1, $user, $pass);

	$INTERNAL_DB="dbname=$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/merge.db";

	unless ($param =~ /^\\[\.=]\\(['"])(.*?)\\\1$/s) 
	{
		$self->Syntax;
	}

	$dsn = $2;
	($dsn1, $user, $pass) = split(/\s*\\,\s*/, $dsn);

	unless ($dsn1) 
	{
		$self->Die("DSN not specified");
	}

	for($dsn)
	{
		if(/^SYSTEM$/)
		{
			if($HTML::Merge::Ini::SESSION_DB)
			{
				$type = $HTML::Merge::Ini::DB_TYPE;
				$db = $HTML::Merge::Ini::SESSION_DB;
				$host = $HTML::Merge::Ini::DB_HOST;
				$user = $HTML::Merge::Ini::DB_USER;
				$pass = $HTML::Merge::Ini::DB_PASSWORD;
			}
			else
			{			
				$type=$INTERNAL_DB_TYPE;
				$db="$INTERNAL_DB";
			}
			last;
		}
		if(/^DEFAULT$/)
		{
			$type = $HTML::Merge::Ini::DB_TYPE;
			$db = $HTML::Merge::Ini::DB_DATABASE;
			$host = $HTML::Merge::Ini::DB_HOST;
			$user = $HTML::Merge::Ini::DB_USER;
			$pass = $HTML::Merge::Ini::DB_PASSWORD;
			last;
		}
		else		
		{
			$dsn1 =~ s/^dbi\\://;
			($type, $db, $host) = split(/\\:/, $dsn1);
			($type, $db) = (undef, $type) unless ($db);
			last;
		}
	}

	<<EOM;
\$engines{"$engine"}->Preconnect("$type", "$db", "$host", "$user", "$pass");
EOM
}
#####################################
sub DoDISCONNECT {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	qq!delete \$engines{"$engine"};!;
}

sub DoEXIT {
	my ($self, $engine, $param) = @_;
	$self->Die if $param;
	"die 'STOP_ON_ERROR';\n";
}

sub DoLOGIN {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[\.=]\\(['"])(.*?)\\\1\\\,\\(['"])(.*?)\\\3$/s) {
		$self->Syntax;
	}
	my ($user, $pass) = ($2, $4);
	qq!\$engines{"$engine"}->Login("$user", "$pass")!;
}

sub DoCHPASS {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[\.=]\\(['"])(.*?)\\\1$/s) {
		$self->Syntax;
	}
	qq!\$engines{"$engine"}->ChangePassword("$2");!;
}

sub DoAUTH {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*?)\\\1$/s) {
		$self->Syntax;
	}
	qq!\$engines{"$engine"}->HasKey("$2")!;
}

sub DoADDUSER {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[\.=]\\(['"])(.*?)\\\1\\\,\\(['"])(.*?)\\\3$/s) {
		$self->Syntax;
	}
	my ($user, $pass) = ($2, $4);
	qq!\$engines{"$engine"}->AddUser("$user", "$pass");!;
}

sub DoDELUSER {
        my ($self, $engine, $param) = @_;
        unless ($param =~ /^\\[=\.]\\(['"])(.*?)\\\1$/s) {
                $self->Syntax;
        }
        my ($user) = ($2);
	qq!\$engines{"$engine"}->DelUser("$user");!;
}

sub DoJOIN {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[=\.]\\(['"])(.*?)\\\1\\\,\\(['"])(.*?)\\\3$/s) {
		$self->Syntax;
	}
	my ($user, $group) = ($2, $4);
	qq!\$engines{"$engine"}->JoinGroup("$user", "$group");!;
}

sub DoPART {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[=\.]\\(['"])(.*?)\\\1\\\,\\(['"])(.*?)\\\3$/s) {
		$self->Syntax;
	}
	my ($user, $group) = ($2, $4);
	qq!\$engines{"$engine"}->PartGroup("$user", "$group");!;
}

sub DoGRANT {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[=\.]([UG])\\\.\\(['"])(.*?)\\\2\\\,\\(['"])(.*?)\\\4$/si) {
		$self->Syntax;
	}
	my ($how, $who, $realm) = (uc($1), $3, $5);
	if ($how eq 'U') {
		return qq!\$engines{"$engine"}->GrantUser("$who", "$realm");!;
	}
	if ($how eq 'G') {
		return qq!\$engines{"$engine"}->GrantGroup("$who", "$realm");!;
	}
}

*DoREVOKE = \&DoEVOKE;

sub DoEVOKE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[=\.]([UG])\\\.\\(['"])(.*?)\\\2\\\,\\(['"])(.*?)\\\4$/si) {
		$self->Syntax;
	}
	my ($how, $who, $realm) = (uc($1), $3, $5);
	if ($how eq 'U') {
		return qq!\$engines{"$engine"}->RevokeUser("$who", "$realm");!;
	}
	if ($how eq 'G') {
		return qq!\$engines{"$engine"}->RevokeGroup("$who", "$realm");!;
	}
}

sub DoATTACH {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[=\.]\\(['"])(.*?)\\\1\\\,\\(['"])(.*?)\\\3$/s) {
		$self->Syntax;
	}
	my ($template, $subsite) = ($2, $4);
	qq!\$engines{"$engine"}->Attach("$template", "$subsite");!;
}

sub DoDETACH {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[=\.]\\(['"])(.*?)\\\1\\\,\\(['"])(.*?)\\\3$/s) {
		$self->Syntax;
	}
	my ($template, $subsite) = ($2, $4);
	qq!\$engines{"$engine"}->Detach("$template", "$subsite");!;
}


*DoREQUIRE = \&DoEQUIRE;

sub DoEQUIRE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\[=\.]\\(['"])(.*?)\\\1\\\,\\(['"])(.*?)\\\3$/s) {
		$self->Syntax;
	}
	my ($template, $realms) = ($2, $4);
	qq!\$engines{"$engine"}->Require("$template", "$realms");!;
}

sub DoUSER {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	qq!\$engines{"$engine"}->GetUser!;
}

sub DoNAME {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	qq!scalar(\$engines{"$engine"}->GetUserName)!;
}

sub DoTAG {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	qq!(\$engines{"$engine"}->GetUserName)[1]!;
}

sub DoMERGE {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	'"$HTML::Merge::Ini::MERGE_PATH/$HTML::Merge::Ini::MERGE_SCRIPT"';
}

sub DoTEMPLATE {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	qq!\$HTML::Merge::template!;
}

sub DoTRANSFER {
	my ($self, $engine, $param) = @_;
	my $validate;
	unless ($param =~ s/^\\\.(.+)$//s) {
		$self->Syntax;
	}
	qq!qq/<INPUT NAME="$1" TYPE=HIDDEN VALUE="\$vars{"$1"}">/!;
}

sub DoSUBMIT {
	my ($self, $engine, $param) = @_;
	my $validate;
	if ($param =~ s/^\\\.\\(["'])(.*)\\\1$//s) {
		$validate = " onSubmit=\"$2\"";
	}
	$self->Syntax if $param;
	$self->Push('submit', $engine);
	<<EOM;
print qq!<FORM ACTION="\$HTML::Merge::Ini::MERGE_PATH/\$HTML::Merge::Ini::MERGE_SCRIPT" METHOD=POST NAME="autoform"$validate>
<INPUT NAME="template" TYPE=HIDDEN VALUE="\$HTML::Merge::template">!;
EOM
}

sub DoUnSUBMIT {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'submit');
	qq!print "</FORM>\\n";!;
}

sub DoDECIDE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*?)\\\1\\\?\\(['"])(.*?)\\\3\\\:\\(['"])(.*?)\\\5$/s) {
		$self->Syntax;
	}
	my ($decision, $true, $false) = ($2, $4, $6);
	<<EOM;
	(
		(eval("$decision") ? "$true" : "$false"),
		\$@ && HTML::Merge::Error::HandleError('ERROR', \$@)
	)[0]
EOM
}

sub DoDATE {
	my ($self, $engine, $param) = @_;
	my $delta = 0;
	if ($param =~ s/^\\[,\.]((?:\\-)?\d+)$//s) {
		$delta = $1;
	}
	$self->Syntax if $param;
	<<EOM;
(HTML::Merge::Engine::Force("$delta", 'i'),
	\@__t = localtime(time + "$delta" * 3600 * 24), 
	sprintf("%04d" . ("%02d" x 5), \$__t[5] + 1900, \$__t[4] + 1,
		\@__t[reverse (0 .. 3)]))[-1]
EOM
}

sub DoDAY {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	qq{substr("$2", 6, 2) * 1};
}

sub DoMONTH {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	qq{substr("$2", 4, 2) * 1};
}

sub DoYEAR {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	qq{substr("$2", 0, 4)};
}

sub DoMINUTE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	qq{substr("$2", 10, 2) * 1};
}

sub DoHOUR {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	qq{substr("$2", 8, 2) * 1};
}


sub DoSECOND {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	qq{substr("$2", 12, 2) * 1};
}

sub DoDATEDIFF {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.([HSMD])\\\.(\\['"])?(.*)\2\\,(\\['"])?(.*)\4$/s) {
		$self->Syntax;
	}
	my ($how, $before, $now) = ($1, $3, $5);
	my %hash = qw(S 1 M 60 H 3600 D 86400);
	my $div = $hash{$how} || 1;
	<<EOM;
(require Time::Local, 
\$__conv = sub { (shift() =~ /^(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})/); 
	Time::Local::timelocal(\$6, \$5, \$4, \$3, \$2 - 1, \$1 - 1900); },
int((&\$__conv("$now") - &\$__conv("$before")) / $div))[-1]
EOM
}

sub DoDATE2UTC {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	<<EOM;
(require Time::Local, 
("$2") =~ /^(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})\$/,
	Time::Local::timelocal(\$6, \$5, \$4, \$3, \$2 - 1, \$1 - 1900))[-1]
EOM
}

sub DoUTC2DATE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/) {
		$self->Syntax if $param;
	}
	<<EOM;
(HTML::Merge::Engine::Force("$2", 'ui'),
	\@__t = localtime("$2"), 
	sprintf("%04d" . ("%02d" x 5), \$__t[5] + 1900, \$__t[4] + 1,
		\@__t[reverse (0 .. 3)]))[-1]
EOM
}

sub DoLASTDAY {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	<<EOM;
((\$__y, \$__m, \$__d) = ("$2" =~ /^(\\d{4})(\\d{2})(\\d{2})/),
\$__base = (qw(31 28 31 30 31 30 31 31 30 31 30 31))[\$__m - 1],
\$__leap = (\$__y % 4) ? 0 
	: ((\$__y % 100) ? 1 
		: ((\$__y % 400) ? 0 : 1)
	),
\$__base + (\$__m == 2 ? \$__leap : 0))[-1]
EOM
}

sub DoADDDATE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1\\\,\\(['"])(.*)\\\3\\,\\(['"])(.*)\\\5\\,\\(['"])(.*)\\\7$/s) {
		$self->Syntax;
	}
	my ($date, $d, $m, $y) = ($2, $4, $6, $8);
	<<EOM;
(require Time::Local,
("$date") =~ /^(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})/,
\$__t = Time::Local::timelocal(\$6, \$5, \$4, \$3, \$2 - 1, \$1 - 1900)
	+ 3600 * 24 * "$d",
\@__t = localtime(\$__t),
\$__t[4] += "$m", \$__t[5] += "$y", 
\$__t[5] += int(\$__t[4] / 12), \$__t[4] %= 12,
sprintf("%04d" . ("%02d" x 5), \$__t[5] + 1900, \$__t[4] + 1,
                \@__t[reverse (0 .. 3)]))[-1]
EOM
}

sub DoDIVERT {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	my $fn = $2;
	$self->Push('divert', $engine);
	<<EOM;
	push(\@__diverts, select);
	use Symbol;
	\$__sym = gensym;
	open(\$__sym, ">>/tmp/merge-\$\$-$fn.divert") || die \$!;
	select \$__sym;
	push(\@HTML::Merge::cleanups, eval qq!sub { unlink "/tmp/merge-\$\$-$fn.divert" }!);
EOM
	# Value of $fn might contain merge variables, that might change
	# until cleanup time. Therefore compile cleanup function
	# with the filename as part of the source.
}

sub DoUnDIVERT {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	$self->Expect($engine, 'divert');
	<<EOM;
	\$__sym = select;
	select pop \@__diverts;
	close \$__sym;
EOM
}

sub DoDUMP {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.\\(['"])(.*)\\\1$/s) {
		$self->Syntax;
	}
	my $fn = $2;
	<<EOM;
(open(DIVERT_DUMP, "/tmp/merge-\$\$-$fn.divert") || die(\$!), join("", <DIVERT_DUMP>),
	close(DIVERT_DUMP))[1]
EOM
}

*DoCGET = *DoCVAR = \&DoCOOKIE;

sub DoCOOKIE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*)$//s) {
		$self->Syntax;
	}
	"\$engines{\"$engine\"}->GetCookie(\"$1\")";
}

*DoCSET = \&DoCOOKIESET;

sub DoCOOKIESET {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*?)\\=\\(['"])(.*?)\\\2((?:\\,.*)?)$//s) {
		$self->Syntax;
	}
	my $expire = substr($4, 2);
	"\$engines{\"$engine\"}->SetCookie(\"$1\", eval(\"$3\"), \"$expire\");";
}

sub DoSOURCE {
        my ($self, $engine, $param) = @_;
	my $file = '$HTML::Merge::template';
	if ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) {
		$file = $2;
	}
	$self->Syntax if $param;
	$self->Push('source', $engine);
	qq!'<A HREF="' . 
	 HTML::Merge::Development::MakeLink('printsource.pl', "template=$file")
		. '" TITLE="view source">'!;
}

sub DoUnSOURCE {
        my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'source');
	qq!"</A>"!;
}

sub safecreate {
        my @tokens = split(/\//, shift);
        pop @tokens;
        my $dir;
        foreach (@tokens) {
                $dir .= "/$_";
                mkdir $dir, 0755;
        }
}
#####################################
sub CompileFile 
{
	my ($file, $out, $sub) = @_;

	my $tmp;
	open(I, $file) || die "Cannot open $file: $!";
	my $text = join("", <I>);
	close(I); 
	
	open(O, ">$out") || die "Can't write $out: $!";
	my $prev = select O;
	
	unless ($sub) {
		print $Config{'startperl'}, "\n";
		print <<'EOM';
	use HTML::Merge::Engine;
	use HTML::Merge::Error;
	no strict;
	sub getvar ($) {
		$vars{shift()};
	}
	sub setvar ($$) {
		$vars{$_[0]} = $_[1];
	}
	sub incvar ($$) {
		$vars{$_[0]} += $_[1];
	}
	sub getfield ($;$) {
		my ($field, $engine) = @_;
		$engines{$engine}->Var($field);
	}
	sub merge ($) {
		my $code = shift;
		require HTML::Merge::Compile;
		my $text;
		eval { $text = HTML::Merge::Compile::Compile($code, __FILE__); };
		HTML::Merge::Error::HandleError('ERROR', $@) if $@;
		eval $text;
		HTML::Merge::Error::HandleError('ERROR', $@) if $@;
	}
	sub dbh () {
		$engines{""}->{'dbh'};
	}
	sub register ($) {
		push(@HTML::Merge::cleanups, shift);
	}

	if (tied(%engines)) {
		undef %engines;
		untie %engines;
	}

	tie %engines, HTML::Merge::Engine;
	use CGI qw/:standard/;
	@keys = param();
	%vars = ();
	foreach (@keys) {
		$vars{$_} = param($_);
	}
=line
	$tmp = HTML::Merge::Compile::CgiParse();
	foreach (keys(%$tmp))
	{
		print "$_\t:\t",$tmp->{$_},"\n";
	}

	%vars = %$tmp; 
=cut
	unless ($HTML::Merge::Ini::TEMPLATE_CACHE) {
	
EOM
		print "\t\trequire '$HTML::Merge::config';\n\t}\n";
	}

	eval {	
		print &Compile($text, $file);
	};
	my $code = $@;
	
	unless ($sub) {
		print <<'EOM';
	HTML::Merge::Engine::DumpSuffix;
	untie %engines;

	1;
EOM
	}

	select $prev;
	close(O);
	die $code if $code;
	chmod 0755, $out;
	
}

sub Syntax {
	my $self = shift;
	&DB::Syntax($self);
}


package DB;

sub Syntax {
	my $self = shift;
	my $step = 0;
	my $sub;
	my $pkg = ref($self);
	for (;;) {
		$step++;
		my @c = caller($step);
		$sub = $c[3];
		last if $sub =~ s/^(.*)::Do// && UNIVERSAL::isa($self, $1);
	} 
	$self->Die("Syntax error on $sub: $DB::args[2]");
}


package HTML::Merge::Ext;

sub Macro {
	my $text = shift;
	$text =~ s/(?<!\\)\$(\d+)/\000$_[$1 - 1]\000/g;

	$HTML::Merge::Ext::COMPILER->Macro($text);
	return "";
}

1;
