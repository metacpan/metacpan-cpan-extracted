package HCKit::Template;

use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HCKit::Template ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ();
@EXPORT_OK = ();
@EXPORT = ();

$VERSION = '0.02';

package HCKit::Template::Rule;

sub new {
    my ($class, $body) = @_;
    my $ref = {};
    $ref->{body} = $body;
    $ref->{args} = [];
    return bless $ref, ref($class)||$class;
}

sub body {
    my ($self) = @_;
    return $self->{body};
}

sub append {
    my ($self, $newbody) = @_;
    $self->{body} .= $newbody;
}

sub set_args {
    my ($self, @arg) = @_;
    $self->{args} = \@arg;
}

sub get_args {
    my ($self) = @_;
    return @{$self->{args}};
}

package HCKit::Template;

sub new {
    my $class = shift;
    my $ref = {};
    $ref->{env}  = {};
    $ref->{fun}  = {};
    $ref->{op}   = {};
    $ref->{delayed} = {};    # names of delayed pre-precess fun
    setup($ref);
    bless $ref, ref($class)||$class;
}

sub rewrite_file {
    my ($self, $file) = @_;
    return $self->_rewrite_file($file, $self->{env});
}

sub rewrite_string {
    my ($self, $string) = @_;
    return $self->_rewrite_string($string, $self->{env});
}

sub process_file {
    my ($self, @file) = @_;
    foreach my $f (@file){
	$self->_include_file($f, $self->{env});
    }
}

sub get_var {
    my ($self, $key) = @_;
    return $self->{env}{$key};
}

sub set_var {
    my ($self, $key, $val) = @_;
    $self->{env}{$key} = $val;
}

# utilities ###########################################################

sub add_delayed {
    my ($self, $name) = @_;
    $self->{delayed}->{$name} = 1;
}

sub is_delayed {
    my ($self, $name) = @_;
    return $self->{delayed}->{$name};
}

sub _rewrite_file {
    my ($self, $file, $env) = @_;
    my ($tmpl, $rule, $data) = read_src($file);
    $self->parse_rule($rule, $env);
    $self->parse_data($data, $env);
    return $self->rewrite($tmpl, $env);
}

sub _include_file {
    my ($self, $file, $env) = @_;
    my ($tmpl, $rule, $data) = read_src($file);
    $self->parse_rule($rule, $env);
    $self->parse_data($data, $env);
}

sub _rewrite_string {
    my ($self, $string, $env) = @_;
    my ($tmpl, $rule, $data) = read_src_from_string($string);
    $self->parse_rule($rule, $env);
    $self->parse_data($data, $env);
    return $self->rewrite($tmpl, $env);
}

sub read_src {
    my ($file) = @_;
    local *FILE;
    my @x;  # ($tmpl, $rule, $data);
    my $mode = 0;
    open(FILE, $file) || die "can't open $file: $!";
    while(<FILE>){
	if( index($_, '---RULE---') >= 0 ){
	    $mode = 1;
	}
	elsif( index($_, '---DATA---') >= 0 ){
	    $mode = 2;
	}
	else{
	    $x[$mode] .= $_;
	}
    }
    close(FILE);
    return @x;
}

sub read_src_from_string {
    my ($str) = @_;
    my @lines = split /\n/, $str;
    my @x;  # ($tmpl, $rule, $data);
    my $mode = 0;
    foreach (@lines){
	if( index($_, '---RULE---') >= 0 ){
	    $mode = 1;
	}
	elsif( index($_, '---DATA---') >= 0 ){
	    $mode = 2;
	}
	else{
	    $x[$mode] .= $_;
	}
    }
    return @x;
}

sub parse_rule {
    my ($self, $rule, $env) = @_;
    $rule ||= "";
    while( $rule =~ 
	   /
	   <([\w-]+)(\s[^>]+)?>(.*?)<\/\1> |
	   <\*(.*?)\*> |
           (<\*--.*?--\*>)
	   /gsx ){
	my ($sym, $opt, $val, $cmd, $comm) = ($1,$2,$3,$4,$5);
	if( $comm ){ next }
	if( $cmd ){
	    if( $cmd =~ /^\?(.*?)\?$/ ){
		my $instr = trim($1);
		if( $instr =~ /^include\s+(\S+)$/ ){
		    $self->_include_file($1, $env);
		    next;
		}
		die "invalid instruction $cmd";
	    }
	    $self->eval_var_raw($cmd, $env);
	    next;
	}
	my $append = 0;
	my @args;
	$opt = "" if !defined($opt);
	foreach(split " ", $opt){
	    if( $_ eq 'append' || $_ eq '+' ){
		$append = 1;
	    }
	    elsif( $_ eq 'trim' ){
		$val = trim($val);
	    }
	    elsif( $_ eq 'chomp' ){
		$val =~ s/\s+$//;
	    }
	    elsif( $_ eq 'remove-white' ){
		$val = trim($val);
		$val =~ s/>\s+</></g;
	    }
	    elsif( /args=(.*)/ ){
		@args = split /,/, $1;
	    }
	}
	my $prev = $env->{$sym};
	if( $prev ){
	    ref($prev) eq "HCKit::Template::Rule" 
		|| die "$sym already defined";
	    if( $append ){
		if( @args ){
		    die "cannot specify args in appending rule";
		}
		$prev->append($val);
	    }
	    else{
		$env->{$sym} = HCKit::Template::Rule->new($val);
	    }
	}
	else{
	    $env->{$sym} = HCKit::Template::Rule->new($val);
	    if( @args ){
		$env->{$sym}->set_args(@args);
	    }
	}
    }
}

sub parse_data {
    my ($self, $data, $env) = @_;
    $data ||= "";
    while( $data =~ 
	   /<([\w-]+)>(.*?)<\/\1>|<\*(.*?)\*>|(<--.*?-->)/gs ){
	my ($sym, $body, $cmd, $comm) = ($1, $2, trim($3), $4);
	if( $comm ){ next }
	if( $sym ){
	    my $val = $self->parse_data_body($body, $env);
	    extend_data($sym, $val, $env);
	}
	else{
	    if( $cmd =~ /^\?(.*?)\?$/ ){
		my $instr = trim($1);
		if( $instr =~ /^include\s+(\S+)$/ ){
		    $self->_include_file($1, $env);
		    next;
		}
		die "invalid instruction $cmd";
	    }
	    $self->eval_var_raw($cmd, $env);
	}
    }
}

sub parse_data_body {
    my ($self, $body, $env) = @_;
    my %hash;
    my $text;
    my $last = 0;
    while( $body =~ 
	   /(<([\w-]+)>(.*?)<\/\2> |
	     <\*(.*?)\*> |
	     (<!\[\[CDATA\[.*\]\]>)
	     )/gsx ){
	my ($match, $sym, $val, $cmd, $cdata) = ($1,$2,$3,$4,$5);
	my $len = length($match);
	my $pre = substr($body, $last, pos($body)-$len-$last);
	$text .= $pre;
	$last = pos($body);
	if( $sym ){
	    my $sub = $self->parse_data_body($val, $env);
	    extend_data($sym, $sub, \%hash);
	}
	elsif( $cdata ){
	    $cdata =~ s/^<!\[\[CDATA\[//;
	    $cdata =~ s/\]\]>$//;
	    $text .= $cdata;
	}
	else{
	    my ($key, $aux) = 
		$cmd =~ /\s*([\w:.-]+)\s*(.*)/;
	    my $val = $self->eval_var($key, $aux, $env);
	    if( ref($val) eq "HASH" ){
		while( my ($sym, $sub) = each %$val ){
		    extend_data($sym, $sub, \%hash);
		}
	    }
	    else{ $text .= $val }
	}
    }
    if( $last < length($body) ){
	$text .= substr($body, $last);
    }
    return %hash ? \%hash : $text;
}

sub extend_data {
    my ($key, $val, $env) = @_;
    if( defined($env->{$key}) ){
	if( ref($env->{$key}) eq 'ARRAY' ){
	    push @{$env->{$key}}, $val;
	}
	else{
	    $env->{$key} = [$env->{$key}, $val];
	}
    }
    else{
	$env->{$key} = $val;
    }
}

sub rewrite {
    my ($self, $tmpl, $env) = @_;
    $tmpl = "" if !defined($tmpl);
    my $last = 0;
    my $output = "";
    while( $tmpl =~ 
	   /(
	     <\*\s*([\w:.-]+)\s*(.*?)\*> |
	     <\&\s*([\w:.-]+(?:@\w+)?)\s*(.*?)\&>(.*?)<\&\s*\/\4\s*\&> |
	     <\{\s*([\w:.-]+(?:@\w+)?)\s*(.*?)\}>(.*?)<\{\s*\/\7\s*\}>
	     )/gxs ){
	my ($match, $var, $varaux, $fun, $funaux, $funarg, 
	    $loop, $loopaux, $loopbody) = 
		($1,$2,$3,$4,$5,$6,$7,$8,$9);
	my $len = length($match);
	my $pre = substr($tmpl, $last, pos($tmpl)-$len-$last);
	$output .= $pre;
	$last = pos($tmpl);
	if( $var ){
	    $output .= $self->eval_var($var, $varaux, $env);
	}
	elsif( $fun ){
	    $fun =~ s/@.*//;
	    $output .= $self->eval_fun($fun, $funaux, $funarg, $env);
	}
	elsif( $loop ){
	    $loop =~ s/@.*//;
	    $output .= $self->eval_block($loop, $loopaux, $loopbody, $env);
	}
    }
    if( $last < length($tmpl) ){
	$output .= substr($tmpl, $last);
    }
    return $output;
}

sub eval_var_raw {
    my ($self, $text, $env) = @_;
    my ($key, $aux) = $text =~ /\s*([\w:.-]+)\s*(.*)/;
    return $self->eval_var($key, $aux, $env);
}

sub eval_var {
    my ($self, $key, $aux, $env) = @_;
    $self->eval_construct($key, $aux, { __NEXT__ => $env });
}

sub eval_fun {
    my ($self, $key, $aux, $funarg, $env) = @_;
    my $newenv = { __NEXT__ => $env };
    $self->parse_funarg($funarg, $newenv);
    $self->eval_construct($key, $aux, $newenv);
}

sub eval_block {
    my ($self, $key, $aux, $body, $env) = @_;
    my $newenv = { __NEXT__ => $env, __BODY__ => $body };
    $self->eval_construct($key, $aux, $newenv);
}

sub eval_construct {
    my ($self, $key, $aux, $env) = @_;
    my ($pre, $post) = parse_aux($aux);
    my $stack = [];
    if( $self->is_delayed($key) ){
	$stack = $pre;
    }
    else{
	$self->process_tokens($stack, $env, @$pre);
    }
    my $val = $self->eval_with_fun($key, $stack, $env);
    $stack = [$val];
    $self->process_tokens($stack, $env, @$post);
    return $stack->[0];
}

sub eval_data_construct {
    my ($self, $key, $aux, $env) = @_;
    my ($pre, $post) = parse_aux($aux);
    my $stack = [];
    if( $self->is_delayed($key) ){
	$stack = $pre;
    }
    else{
	$self->process_tokens($stack, $env, @$pre);	
    }
    my $val = $self->eval_with_fun($key, $stack, $env);
    $stack = [$val];
    $self->process_tokens($stack, $env, @$post);
    return $stack->[0];
}

sub process_para {
    my ($rule, $stack, $env) = @_;
    my @args = $rule->get_args();
    if( @args ){
	foreach my $p (@args){
	    if( exists $env->{$p} ){ next }
	    $env->{$p} = shift @$stack;
	}
    }
}

sub parse_aux {
    my ($aux) = @_;
    $aux = "" if !defined($aux);
    my $pre = [];
    my $post = [];
    my $ref = $pre;
    while( $aux =~ 
	   /(
	     [\w:-]+=\"[^\"]*\" |
	     [\w:-]+=\'[^\']*\' |
	     [\w:-]+=[^\'\"\;\s]+ |
	     \"[^\"]*\" |
	     \'[^\']*\' |
	     [^\s=;]+ |
	     ;
	     )/gsx ){
	if( $1 eq ';' ){ $ref = $post; next }
	push @$ref, $1;
    }
    return ($pre, $post);
}

sub parse_funarg {
    my ($self, $funarg, $env) = @_;
    $funarg ||= "";
    while( $funarg =~ /<([\w-]+)>(.*?)<\/\1>/gs ){
	my ($key, $val) = ($1, $2);
	$env->{$key} = $self->rewrite($val, $env);
    }
}

sub process_tokens {
    my ($self, $stack, $env, @tok) = @_;
    my $i;
    for($i=0;$i<=$#tok;$i++){
	my $t = $tok[$i];
	if( $t =~ /^([\w:-]+)=\"([^\"]*)\"$/ ){
	    $env->{$1} = $2;
	}
	elsif( $t =~ /^([\w:-]+)+=\'([^\']*)\'$/ ){
	    $env->{$1} = $2;
	}
	elsif( $t =~ /^([\w:-]+)=([^\'\"\;\s]+)$/ ){
	    $env->{$1} = var_lookup($2, $env);
	}
	elsif( $t =~ /^\"(.*)\"$/ ){
	    push @$stack, $1;
	}
	elsif( $t =~ /^\'(.*)\'$/ ){
	    push @$stack, $1;
	}
	elsif( $t eq "as" ){
	    push @$stack, $tok[++$i];
	}
	elsif( $t =~ /^(\d+|\d+\.\d+)$/ ){
	    push @$stack, $1;
	}
	elsif( $t =~ /^(\d+)\.\.(\d+)$/ ){
	    push @$stack, [$1..$2];
	}
	else{
	    $self->eval_with_op($t, $stack, $env);
	}
    }
}

sub lookup {
    my ($sym, $env) = @_;
    while( $env ){
	if( defined($env->{$sym}) ){ 
	    return $env->{$sym};
	}
	$env = $env->{'__NEXT__'};
    }
    return undef;
}

sub var_lookup {
    my ($var, $env) = @_;
    my @tok = split /\./, $var;
    my $first = shift @tok;
    my $val = lookup($first, $env);
    foreach my $i (@tok){
	unless( ref($val) eq 'HASH' ){ 
	    return "";
	}
	$val = $val->{$i};
    }
    return $val;
}

sub eval_with_op {
    my ($self, $expr, $stack, $env) = @_;
    my $val = var_lookup($expr, $env);
    if( defined($val) ){
	unless( ref($val) ){
	    $val = $self->rewrite($val, $env);
	}
	push @$stack, $val;
    }
    else{
	my $op = $self->{op}->{$expr};
	if( $op ){
	    &{$op}($self, $stack, $env);
	}
	else{
	    push @$stack, "";
	}
    }
}

sub eval_with_fun {
    my ($self, $expr, $stack, $env) = @_;
    my $val = var_lookup($expr, $env);
    if( defined($val) ){
	if( ref($val) eq "HCKit::Template::Rule" ){
	    process_para($val, $stack, $env);
	    return $self->rewrite($val->body(), $env);
	}
	elsif( ref($val) ){
	    return $val;
	}
	else{
	    return $val;
	}
    }
    else{
	my $fun = $self->{fun}->{$expr};
	if( $fun ){
	    return &{$fun}($self, $stack, $env);
	}
    }
    return "";
}

# fun ###############################################################

# fun_foreach
#   stack: LIST [IDENT]
#   switches:
#     foreach:sep=SEP
#     foreach:toggle=INIT

sub fun_foreach {
    my ($self, $stack, $env) = @_;
    my $body = $env->{__BODY__};
    my ($ident, $list);
    my $top = pop @$stack;

    if( ref($top) eq "ARRAY" ){
	$ident = "iter";
	$list  = $top;
    }
    else{
	$ident = $top;
	$list  = pop @$stack;
    }
    my $output = "";
    my $join = $env->{'foreach:sep'};
    my $n = 0;
    my $toggle = 0;
    if( defined($env->{'foreach:toggle'}) ){
	$toggle = 1;
	$env->{toggle} = $env->{'foreach:toggle'};
    }
    unless( ref($list) eq "ARRAY" ){
	$list = [$list];
    }
    foreach my $e (@$list){
	if( $join && $n++ > 0 ){
	    $output .= $join;
	}
	$env->{$ident} = $e;
	if( $toggle ){
	    $env->{toggle} = $env->{toggle} ? 0 : 1;
	}
	my $tmp = $self->rewrite($body, $env);
	$output .= $tmp;
    }
    return $output;
}

sub fun_if {
    my ($self, $stack, $env) = @_;
    my ($test) = @$stack;
    if( $test ){
	my $body = $env->{__BODY__};
	return $self->rewrite($body, $env);
    }
    else{ return ""; }
}

sub fun_include {
    my ($self, $stack, $env) = @_;
    my $prev_env = $env->{__NEXT__};
    foreach my $f (@$stack){
	$self->_include_file($f, $prev_env);
    }
    return "";
}

sub fun_set {
    my ($self, $stack, $env) = @_;  # <* set ident val *>
    my $key = shift @$stack;
    $key =~ /^[\w.-]+$/ || die "invalid identifier in set: $key";
    my $ns = [];
    $self->process_tokens($ns, $env, @$stack);
    my $prev = $env->{__NEXT__};
    $prev->{$key} = $ns->[0];
    return "";
}

sub fun_default {
    my ($self, $stack, $env) = @_;  # <* default ident val *>
    my $key = shift @$stack;
    $key =~ /^[\w-]+$/ || die "invalid identifier in set: $key";
    my $bind = lookup($key, $env);
    if( defined $bind ){ return }
    my $ns = [];
    $self->process_tokens($ns, $env, @$stack);
    my $prev = $env->{__NEXT__};
    $prev->{$key} = $ns->[0];
    return "";
}

sub setup_fun {
    my ($ref) = @_;
    my $env = $ref->{fun};
    $env->{foreach}      = \&fun_foreach;
    $env->{if}           = \&fun_if;
    $env->{include}      = \&fun_include;
    $env->{set}          = \&fun_set;
    $ref->{delayed}->{set} = 1;
    $env->{default}      = \&fun_default;
    $ref->{delayed}->{default} = 1;
}

sub op_trim {
    my ($self, $stack, $env) = @_;
    my $s = pop @$stack;
    push @$stack, trim($s);
}

sub op_list_remove_last {
    my ($self, $stack, $env) = @_;
    my $orig = pop @$stack;
    my @list = @$orig;
    pop @list;
    push @$stack, \@list;
}

sub op_list_last {
    my ($self, $stack, $env) = @_;
    my $orig = pop @$stack;
    my $last = pop @$orig;
    push @$stack, $last;
}

sub op_not {
    my ($self, $stack, $env) = @_;
    my $arg = pop @$stack;
    push @$stack, ((!$arg) ? 1 : 0);
}

sub op_eq {
    my ($self, $stack, $env) = @_;
    my $right = pop @$stack;
    my $left  = pop @$stack;
    push @$stack, (($left eq $right) ? 1 : 0);
}

sub op_or {
    my ($self, $stack, $env) = @_;
    my $right = pop @$stack || 0;
    my $left  = pop @$stack || 0;
    push @$stack, (($left || $right) ? 1 : 0);
}

sub op_and {
    my ($self, $stack, $env) = @_;
    my $right = pop @$stack || 0;
    my $left  = pop @$stack || 0;
    push @$stack, (($left && $right) ? 1 : 0);
}

sub op_concat {
    my ($self, $stack, $env) = @_;
    my $right = pop @$stack;
    my $left  = pop @$stack;
    push @$stack, ($left . $right);
}

sub op_lookup {
    my ($self, $stack, $env) = @_;
    my $attr = pop @$stack || return "";
    my $hash = pop @$stack || return "";
    foreach my $a (split /\./, $attr){
	if( $hash && ref($hash) eq "HASH" && exists($hash->{$a}) ){
	    $hash = $hash->{$a};
	}
	else{ return "" }
    }
    push @$stack, $hash;
}

sub setup_op {
    my ($self) = @_;
    my $env = $self->{op};
    $env->{trim} = \&op_trim;
    $env->{'list-remove-last'} = \&op_list_remove_last;
    $env->{'list-last'} = \&op_list_last;
    $env->{'not'} = \&op_not;
    $env->{'eq'} = \&op_eq;
    $env->{'or'} = \&op_or;
    $env->{'and'} = \&op_and;
    $env->{'lookup'} = \&op_lookup;
    $env->{'concat'} = \&op_concat;
}

sub setup {
    my ($ref) = @_;
    setup_fun($ref);
    setup_op($ref);
}

# utilities ##########################################################

sub file_content {
    my ($file) = @_;
    local *FILE;
    local $/;
    $/ = undef;
    open(FILE, $file) || die "can't open $file: $!";
    my $c = <FILE>;
    close(FILE);
    return $c;
}

sub trim {
    my ($str) = @_;
    $str ||= "";
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub debug_env {
    my ($env, $prefix) = @_;
    if( ref($env) eq "ARRAY" ){
	foreach(@$env){
	    debug_env($_, $prefix);
	}
    }
    elsif( ref($env) eq "HASH" ){
	while( my($key, $val) = each %$env ){
	    print " " x $prefix, "<$key>\n";
	    debug_env($val, $prefix+2);
	    print "\n";
	    print " " x $prefix, "</$key>\n";
	}
    }
    else{
	print " " x $prefix, $env;
    }
}

1;
__END__

=head1 NAME

HCKit::Template - A template system for HTML construction

=head1 SYNOPSIS

First you make a template like this, test.tmpl:

 <html>
 <body>
   <h1><* title text="My Friends" *></h1>
   <ul>
     <{ foreach friend as f }>
       <li><* f.name *>, <* f.age *>
     <{ /foreach }>
   </ul>
 </body>
 </html>
 ---RULE---
 <title><h1><* text *></h1></title>
 ---DATA---
 <friend>
   <name>Arthur Beck</name>
   <age>23</age>
 </friend>
 <friend>
   <name>Charles Douglas</name>
   <age>26</age>
 </friend>
 <friend>
   <name>Earl Fairchild</name>
   <age>18</age>
 </friend>
  
Then you convert the template to an HTML page with the following
script.

 use HCKit::Template;
 my $tmpl = HCKit::Template->new;
 print $tmpl->rewrite_file("test.tmpl");

The output becomes like this:
   
 <html>
 <head><title>My Friends</title>
 <body>
   <h1>My Friends</h1>
   <ul>
     <li>Arthur Beck, 23
     <li>Charles Douglas, 26
     <li>Earl Fairchild, 18
   </ul>
 </body>
 </html>

Rewriting process can be controlled by a script. For example,
with the following template in a file "test2.tmpl":

 <html>
 <body>
   <h1><* title text="My Friends" *></h1>
   <ul>
     <{ foreach friend as f }>
       <li><* f.name *>, <* f.age *>
     <{ /foreach }>
   </ul>
 </body>
 </html>
 ---RULE---
 <title><h1><* text *></h1></title>

following script produces the same output as the above example.

 use HCKit::Template;
 my $tmpl = HCKit::Template->new;
 $tmpl->set_var( friend =>
		 [ { name => 'Arthur Beck', age => 23 },
		   { name => 'Charles Douglas', age => 26 },
		   { name => 'Earl Fairchild', age => 18 },
		   ]);
 print $tmpl->rewrite_file("test.tmpl");

=head1 DESCRIPTION

This module constructs an HTML page from a template. The conversion
proceeds with the help of rewrite rules and data sources. Rewrite
rules can be specified in the template file itself, or in the Perl
script. Data sources can be XML files, or dynamically constructed in
the Perl script.

=head1 TEMPLATE FILE

A template file consists of three portions: a template itself, rewrite
rules, and data sources. A template file starts by specifying a
template itself. A line beginning with the string '---RULE---' starts
rewrite rules. A line beginning with the string '---DATA---' starts
data sources. Sections for rewrite rules and data sources are
optional.

Here is an example template file:

 I am <* full-name first=first-name last=last-name *>
 I am <* first-name *> <* last-name *>.
 ---RULE---
 <full-name><* first *> <* last *></full-name>
 ---DATA---
 <first-name>Andy</first-name>
 <last-naem>Davis</last-name>

This template lacks data source, and is converted to:

 I am Andy Davis.

=head1 TEMPLATE

Within templates, three kinds of constructs are identified and
rewritten by this module: simple constructs, funcall constructs, 
block constructs;

Following is the syntax of a simple construct.

 <* IDENTIFIER *>

When a simple construct is encountered, the module searches for
IDENTIFIER in the rewrite rules and data sources and replaces the 
construct with its value.

For example, with the following template file:

 <* name *>
 ---RULE---
 <name><b>Harold</b></name>
    
'name' is looked up in the rewrite rules, and the construct is
replaced with its value, <b>Harold</b>.

With the following template file:

 <* name *>
 ---DATA---
 <name>Eugene</name>

'name' is looked up in the data source, and the construct is replaced
with its value, Eugene.

By concatenating identifiers with C<.>, nested data in the data
source can be accessed. For example, the following template

 <* name.first-name *> <* name.last-name *>
 ---DATA---
 <name>
   <first-name>Andy</first-name>
   <last-name>Varmus</last-name>
 </name>

is rewritten to 'Andy Varmus'.

Following is the syntax of a funcall construct.
  
 <& IDENTIFIER &>
   <key1>val1</key1>
   <key2>val2</key2>
   ...
 <& /IDENTIFIED &>

This construct extends the current environment with the key-value
pairs specified in its body and applies the IDENTIFIEER rewrite rule.
IDENTIFIER.

For example, the following template

 <& full-name &>
   <first>Andy</first>
   <last>Varmus</last>
 <& /full-name &>
 ---RULE---
 <full-name><* first *> <* last *></full-name>

is rewritten to 'Andy Varmus'.

Following is the syntax of a block construct.

 <{ IDENTIFIER }>
   ...
 <{ /IDENTIFIER }>

This construct invokes a built in block function identified by
IDENTIFIER.

For example the following template

 <{ foreach num as n }>
   <* n *>
 <{ /foreach }>
 ---DATA---
 <num>1</num>
 <num>2</num>
 <num>3</num>

is rewritten to
   1
   2
   3

Nested block constructs are supported by supplying a distinctive tag
to each construct. Such a tag is appended to IDENTIFIER following the
character '@'.

For example, following template

  <{ foreach@1 1..3 as i }>
    <{ foreach@2 1..2 as j }>
      <* i *>-<* j *>
    <{ /foreach@2 }>
  <{ /foreach@1 }>

results in

  1-1
  1-2
  2-1
  2-2
  3-1
  3-2

=head1 REWRITE RULE

Rewrite rules appear following a line that begins with '---RULE---'.
Each rewrite rule is in the following format:

 <IDENTIFIER>
   BODY
 </IDENTIFIER>

'IDENTIFIER' indicates the name with which this rewrite rule is
invoked. BODY indicates the output of this rewrite rule. In BODY,
all kinds of constructs can appear as in templates.

For example, with the following rewrite rule and data section,
  
 ---RULE---
 <greeting>
   Hello, <* guest *>!
 </greeting>
 ---DATA---
 <guest>Andy</guest>

<* greeting *> is rewritten to 'Hello, Andy!' (neglecting the
leading and trailing white spaces).

=head1 DATA SECTION

The data section consists of data in the XML format.

For example, with the following data section,

 ---DATA---
 <friend>
  <name>Arthur Beck</name>
  <age>23</age>
 </friend>

<* friend.name *> is rewritten to 'Arthur Beck'.

If there are multiple data with the same name, they are grouped as a
list of data.

For example, with the following data section,

 ---DATA---
 <friend>
   <name>Arthur Beck</name>
   <age>23</age>
 </friend>
 <friend>
   <name>Charles Douglas</name>
   <age>26</age>
 </friend>
 <friend>
   <name>Earl Fairchild</name>
   <age>18</age>
 </friend>

a block construct of
 
 <{ foreach friend as f }>
   <* f.name *>, <* f.age *>
 <{ /foreach }>

is rewritten to

  Arthur Beck, 23
  Charles Douglas, 26
  Earl Fiarchild, 18

=head1 PRE/POST PROCESSOR

Each construct can have multiple pre/post processors. They are
specified following IDENTIFIER in the start tag.

For example in the simple construct, the general syntax is 

 <* IDENTIFIER PRE ; POST *>

in which PRE is a space-separated list of pre-processors and POST
is a space-separated list of post-procesors. 

These processors are applied before and after the invocation of
rewrite, respectively.

Each construct has a value stack of its own (construct stack). This
stack is used by built in functions to pass and retrieve
arguments. Initially, this stack is empty. pre-processors manipulate
this stack before invoking the rule/function identified by
IDENTIFIER. Then, the stack is reset to empty, and the output of the
rule/function is pushed to the stack.  The post-processors manipulate
this stack and should leave only one element in the stack, which
becomes the final result of the rewrite of the construct.

Currently, following pre/post-processors are supported.

=over 4

=item B<name=value>  

Extends the current environment with name/value pair. It does not
alter the construct stack. If value includes a space, it should be
quoted by ' or ". This processor is useful only in pre-processing.

Example:

  <* full-name first=Andy last=Varmus *>
  ---RULE---
  <full-name><* first *> <* last *></full-name>

The output becomes: Andy Varmus

=item B<FROM..TO>

Pushes a list of numbers ranging from FROM to TO (inclusive). 

For example, following template

  <{ foreach 1..3 as i }>
    <* i *>
  <{ /foreach }>

results in

  1
  2
  3

=item B<trim>

Pops an element from the stack, removes leading and trailing space
characters from the element, and push the result back to the stack.

For example,

  My name is <* name ; trim *>.
  ---RULE---
  <name>
    Andy
  </name>

is rewritten to

  My name is Andy.

Whereas,

  My name is <* name *>.
  ---RULE---
  <name>
    Andy
  </name>

is rewritten to

  My name is 
    Andy

=item B<list-remove-last>

Pops an element from the stack, removes the last item from the element
(which should be a list), and pushes back the element to the stack.

For example, following template

  <{ foreach fruit list-remove-last as f }>
    <* f *>
  <{ /foreach }>
  ---DATA---
  <fruit>apple</fruit>
  <fruit>banana</fruit>
  <fruit>orange</fruit>
  <fruit>water melon</fruit>

is rewritten to

  apple
  banana
  orange

=item B<list-last>

Pops an element from the stack, takes the last item from the element
(which should be a list), and push back the item to the stack.

For example, following template

  <* fruit ; list-last *>
  ---DATA---
  <fruit>apple</fruit>
  <fruit>banana</fruit>
  <fruit>orange</fruit>
  <fruit>water melon</fruit>

is rewritten to 'water melon'. In this example, the value of 'fruit'
is pushed to the construct stack, as the only element, before
post-processor is invoked. The post-processor pops the list (apple,
banana, orange, and water melon) and pushes back the last item in the
list, which becomes the final rewrite of the construct.

=item B<not>

Pops an element from the stack, negates the value of the element, and
pushes back the result to the stack.

For example, following template

  <{ foreach fruit as f }>
    <* f.name *> <{ if f.stock not }>(not available)<{ /if }>
  <{ /foreach }>
  ---DATA---
  <fruit>
    <name>apple</name>
    <stock>0</stock>
  </fruit>
  <fruit>
    <name>banana</name>
    <stock>12</stock>
  </fruit>
  <fruit>
    <name>orange</name>
    <stock>23</stock>
  </fruit>
  <fruit>
    <name>water melon</name>
    <stock>0</stock>
  </fruit>

is rewritten to
  apple (not available)
  banana
  orange
  water melon (not available)

=item B<eq>

Pops str2 from the stack, pops str1 from the stack, compares str1 and
str2 (string compare), and pushes the boolean result to the stack.

For example, following template

  <{ foreach friend as f }>
    <{ if f.gender 'female' eq }><* f.name *><{ /if }>
  <{ /foreach }>
  ---DATA---
  <friend>
    <name>Alice</name>
    <gender>female</gender>
  </friend>
  <friend>
    <name>Bob</name>
    <gender>male</gender>
  </friend>
  <friend>
    <name>Eve</name>
    <gender>female</gender>
  </friend>

is rewritten to

  Alice
  Eve

=item B<or>

Pops a boolean value b2 from the stack, pops a boolean value b1 from
the stack, and pushes (b1 || b2) to the stack.

  <{ foreach friend as f }>
    <{ if f.hair 'black' eq f.hair 'red' eq or }><* f.name *><{ /if }>
  <{ /foreach }>
  ---DATA---
  <friend>
    <name>Alice</name>
    <hair>black</hair>
  </friend>
  <friend>
    <name>Bob</name>
    <hair>red</hair>
  </friend>
  <friend>
    <name>Eve</name>
    <hair>blonde</hair>
  </friend>
  
is rewritten to

  Alice
  Bob

=item B<and>

Pops a boolean value b2 from the stack, pops a boolean value b1 from
the stack, and pushes (b1 && b2) to the stack.

  <{ foreach friend as f }>
    <{ if f.hair 'black' eq f.eye 'brown' eq and }><* f.name *><{ /if }>
  <{ /foreach }>
  ---DATA---
  <friend>
    <name>Alice</name>
    <hair>black</hair>
    <eye>brown</eye>
  </friend>
  <friend>
    <name>Bob</name>
    <hair>red</hair>
    <eye>blue</eye>
  </friend>
  <friend>
    <name>Eve</name>
    <hair>blonde</hair>
    <eye>black</eye>
  </friend>
  
is rewritten to

  Alice

=item B<concat>

Pops a string value str1 from the stack, pops another string value
str2 from the stack, and pushes a concatenated string "$str1$str2" to
the stack.

For example, following template

  <* name ; ', Jr' concat *>
  ---DATA---
  <name>Davis</name>

is rewritten to 'Davis, Jr'.

=item B<lookup>

Pops an attribute name from the stack, pops a data from the stack,
and pushes back the attribute value of the data to the stack.

For example, following template

  <* friend ; 'name.first' lookup *>
  ---DATA---
  <friend>
    <name>
      <first>Michael</first>
      <last>Stuart</last>
    </name>
  </friend>

is rewritten to 'Michael'.

=back

=head1 REWRITE RULE OPTIONS

The definition of a rewrite rule can have options after its IDENTIFIER.
Options are separated by spaces with each other.

For example, in the following rule,

  ---RULE---
  <full-name trim>
    <* first *> <* last *>
  </full-name>

'trim' option removes leading and trailing white spaces from rewrite
rule BODY. Therefore, the above rule is equivalent to

  ---RULE---
  <full-name><* first *> <* last *></full-name>

Currently available options are as follows.

=over 4

=item B<trim>

Removes leading and trailing white spaces from rewrite rule BODY.

=item B<+>

Appends rewrite rule BODY to the previously defined rule with the same
name. Normally, when multiple rewrite rules with the same name are
defined, the last definition overwrites the others.

For exmaple, the following template

  <style type="text/css">
  <* stylesheet *>
  </style>
  ---RULE---
  <stylesheet>
    body { background-color: #fff }
  </stylesheet>
  <stylesheet>
    frame { border:thin solid #f00 }
  </stylesheet>

is equivalent to
      
  <style type="text/css">
    frame { border:thin solid #f00 }
  </style>

However, with C<+> option (note the '+' in the second stylesheet
rule),

  <style type="text/css">
  <* stylesheet *>
  </style>
  ---RULE---
  <stylesheet>
    body { background-color: #fff }
  </stylesheet>
  <stylesheet +>
    frame { border:thin solid #f00 }
  </stylesheet>

the above template is equivalent to

  <style type="text/css">
    body { background-color: #fff }
    frame { border:thin solid #f00 }
  </style>
  
=back

=head1 DATA SECTION

Data section appears following a line that begins '---DATA---'.
Data section comprises of data described in XML format.

For example, following template

  <* friend.first *>
  ---DATA---
  <friend>
    <first>John</first>
    <last>Williams</last>
  </friend>

results in 'John'.

CDATA section can be included in the data.

For example, following template

  <* header *>
  ---DATA---
  <header>
    <![[CDATA[
      <h1>Header</h1>
    ]]>
  </header>

results in '<h1>Header</h1>'.

=head1 BUILTIN FUNCTIONS

Followings are the list of builtin functions.

=over 4

=item B<foreach>

  <{ foreach LIST [AS NAME] }>
    BODY
  <{ /foreach }>

For each item in LIST, it is bound to NAME and then BODY is rewritten.
If NAME is omitted, each item is bound to the name 'iter'.

For example:

  <{ foreach num }>
    <* iter *>
  <{ /foreach }>
  ---DATA---
  <num>1</num>
  <num>2</num>
  <num>3</num>

This results in:

    1
    2
    3

Another example:

  <{ foreach site as s }>
    <a href="<* s.url *>"><* s.label *></a><br>
  <{ /foreach }>
  ---DATA---
  <site>
    <href>http://www.yahoo.com</href>
    <label>Yahoo!</label>
  </site>
  <site>
    <href>http://www.google.com</href>
    <label>Google</label>
  </site>

This results in:

  <a href="http://www.yahoo.com">Yahoo!</a>
  <a href="http://www.google.com">Google</a>

Following preprocessors are effective for C<foreach>.

C<foreach:sep=SEP> proprocessor specifies separator between outputs of
iterations.

For example,

  <{ foreach num foreach:sep=' | '}>
    <* iter *>
  <{ /foreach }>
  ---DATA---
  <num>1</num>
  <num>2</num>
  <num>3</num>

This results in:

    1 | 
    2 |
    3

C<foreach:toggle=INIT> preprocessor introduces a new variable named
'toggle' that has initial value of INIT. After each iteration, the
variable 'toggle' is toggled between 0 and 1.

For example,

  <{ foreach num as n foreach:toggle=0 }>
    <div class="style-<* toggle *>"><* n *></div>
  <{ /foreach }>
  ---DATA---
  <num>1</num>
  <num>2</num>
  <num>3</num>

Results in:

    <div class="style-0">1</div>
    <div class="style-1">1</div>
    <div class="style-0">1</div>
  

=item B<if>

  <{ if EXPR }>
    BODY
  <{ /if }>

If EXPR evaluates to true, BODY is rewritten; otherwise, nothing is
output.

For example, following template

  <{ if link }>
    <* link.label *>
  <{ /if }>
  ---DATA---
  <link>
    <label>Yahoo!</label>
    <url>http://www.yahoo.com</url>
  </link>

is rewritten to 'Yahoo!'.


=item B<include>

  <* include FILE *>

Reads FILE and processes its rewrite rule and data sections. The
template section, if any, is ignored.

For example, following template

  <* include './friends.xml' *>
  <{ foreach friend as f }>
    <* f.name *>, <* f.age *><br>
  <{ /foreach }>

with accompanying file ./friends.data, whose content is

  ---DATA---
  <friend>
    <name>Arthur</name>
    <age>23</age>
  </friend>
  <friend>
    <name>Charles</name>
    <age>26</age>
  </friend>
  <friend>
    <name>Earl</name>
    <age>18</age>
  </friend>

results in
  
  Arthur, 23<br>
  Charles, 26<br>
  Earl, 18<br>

=item B<set>

  <* set IDENTIFIER VALUE *>

sets the value of a variable with name IDENTIFIER to VALUE.

For example, following template

  <* set f friend *>
  <* f.name *>
  <* f.age *>
  ---DATA---
  <friend>
    <name>Arthur</name>
    <age>23</age>
  </friend>

results in

  Arthur
  23

=item B<default>

  <* default IDENTIFIER VALUE *>

sets the value of a variable with name IDENTIFIER to VALUE, if the
variable value is not already defined.

For example, following template

  <* background *>
  ---RULE---
  <background>
    <* default color "#ff0000" *>
    <* color *>
  </background>

results in

  #ff0000

However, following template 

  <* background color="#000000"*>
  ---RULE---
  <background>
    <* default color "#ff0000" *>
    <* color *>
  </background>

results in

  #000000  

=back

=head1 METHODS

=over 4

=item B<new>

Creates a template object.

  my $tmpl = HCKit::Template->new;

=item B<rewrite_file>

Rewrites the template contained in a file and returns the string.

  my $tmpl = HCKit::Template->new;
  print $tmpl->rewrite_file("main.tmpl");

=item B<rewrite_string>

Rewrites the template contained in a string and returns the rewritten
string.

  my $tmpl = HCKit::Template->new;
  print $tmpl->rewrite_string(<<EOI);
  <* friend.name *>
  ---DATA---
  <friend><name>John</name></friend>
  EOI

=item B<process_file>

Reads files and processes rewrite rule sections and data
sections. Template sections in these files are neglected.

  my $tmpl = HCKit::Template->new;
  $tmpl->process_file("frame.tlib", "box.tlib");

=item B<get_var>

Gets the value of a variable.

  my $tmpl = HCKit::Template->new;
  $tmpl->get_var('width');

=item B<set_var>

Sets the value of a variable.

  my $tmpl = HCKit::Template->new;
  $tmpl->set_var('width', 780);

=back

=head1 SEE ALSO

There are other excellent and mature Perl modules with similar
purposes, but with different concepts. For example, Sam Tregar's
HTML::Template,
L<http://theoryx5.uwinnipeg.ca/mod_perl/cpan-search?modinfo=8997> and
Andy Wardley's Template
L<http://theoryx5.uwinnipeg.ca/mod_perl/cpan-search?modinfo=18155> are
famous ones.

=head1 AUTHOR

Hangil Chang, E<lt>hangil@chang.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Hangil Chang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
