# -*- perl -*-
#
#   HTML::EP	- A Perl based HTML extension.
#
#
#   Copyright (C) 1998              Jochen Wiedmann
#                                   Am Eisteich 9
#                                   72555 Metzingen
#                                   Germany
#
#                                   Email: joe@ispsoft.de
#
#
#   Portions Copyright (C) 1999	    OnTV Pittsburgh, L.P.
#			  	    123 University St.
#			  	    Pittsburgh, PA 15213
#			  	    USA
#
#			  	    Phone: 1 412 681 5230
#			  	    Developer: Jason McMullan <jmcc@ontv.com>
#			            Developer: Erin Glendenning <erg@ontv.com>
#
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.005;
use strict;

use CGI ();
use Symbol ();
use HTML::EP::Config ();
use HTML::EP::Parser ();


package HTML::EP;

$HTML::EP::VERSION = '0.2011';


sub new {
    my $proto = shift;
    my $self = (@_ == 1) ? {%{shift()}} : { @_ };
    $self->{'_ep_output'} = '';
    $self->{'_ep_output_stack'} = [];
    $self->{'_ep_config'} ||= $HTML::EP::Config::CONFIGURATION;
    $self->{'debug'} ||= 0;
    $self->{'cgi'} ||= (CGI->new() || die "Failed to create CGI object: $!");
    bless($self, (ref($proto) || $proto));
}

sub Run {
    my($self, $template) = @_;
    my $parser = HTML::EP::Parser->new();
    my $r = $self->{'_ep_r'};
    $self->{'env'} ||=  $r ?
	{ $r->cgi_env(), 'PATH_INFO' => $r->uri() } : \%ENV;
    if ($template) {
	$parser->parse($template);
    } else {
	my $file = $self->{'env'}->{'PATH_TRANSLATED'}
	    || die "Missing server environment (PATH_TRANSLATED variable)";
	my $fh = Symbol::gensym();
	open($fh, "<$file") || die "Failed to open $file: $!";
	$parser->parse_file($fh);
    }
    $parser->eof();
    my $tokens = HTML::EP::Tokens->new('tokens' => $parser->{'_ep_tokens'});
    $self->{'_ep_output'} = $self->ParseVars($self->TokenMarch($tokens));
}


sub CgiRun {
    my($self, $path, $r) = @_;
    my $cgi = $self->{'cgi'};
    my $ok_templates = $self->{'_ep_config'}->{'ok_templates'};
    local $| = 1;
    my $output = eval {
	die "Access to $path forbidden; check ok_templates in ",
	    $INC{'HTML/EP/Config.pm'}
		if $ok_templates && $path !~ /$ok_templates/;
	$self->_ep_debug({}) if $cgi->param('debug');
	$self->Run();
    };

    if ($@) {
	if ($@ =~ /_ep_exit, ignore/) {
	    $output .= $self->ParseVars($self->{'_ep_output'});
	} else {
            my $errmsg;
            my $errstr = $@;
            my $errfile = $self->{_ep_err_type} ?
                $self->{_ep_err_file_user} : $self->{_ep_err_file_system};
            if ($errfile) {
                if ($errfile =~ /^\//) {
                    my $derrfile = $r ?
                        $r->cgi_var('DOCUMENT_ROOT') : $ENV{'DOCUMENT_ROOT'}
                            . $errfile;
                    if ($self->{'debug'}) {
                        $self->print("Error type = " . $self->{_ep_err_type} .
                                     ", error file = $errfile" .
                                     ", derror file = $derrfile\n");
                    }
                    if (-f $derrfile) { $errfile = $derrfile }
                }
		my $fh = Symbol::gensym();
		if (open($fh, "<$errfile")) {
		    local $/ = undef;
		    $errmsg = <$fh>;
		    close($fh);
		}
	    }
            if (!$errmsg) {
                $errmsg = $self->{_ep_err_type} ?
                    $self->{_ep_err_msg_user} : $self->{_ep_err_msg_system};
            }
            return $self->SimpleError($errmsg, $errstr);
	}
    }

    if (!$self->{_ep_stop}) {
	$self->print($cgi->header($self->SetCookies(),
				  %{$self->{'_ep_headers'}}), $output);
    }
}

sub FindEndTag {
    my($self, $tokens, $tag) = @_;
    my $level = 0;
    while (defined(my $token = $tokens->Token())) {
	if ($token->{'type'} eq 'S') {
	    ++$level if $token->{'tag'} eq $tag;
	} elsif ($token->{'type'} eq 'E') {
	    if ($token->{'tag'} eq $tag) {
		return $tokens->First() unless $level--;
	    }
	}
    }
    die "$tag without /$tag";
}

sub AttrVal {
    my($self, $val, $tokens, $token, $parse) = @_;
    return $val if defined($val);
    my $first = $tokens->First();
    my $last = $self->FindEndTag($tokens,
				 ref($token) ? $token->{'tag'} : $token);
    my $output = $self->TokenMarch($tokens->Clone($first, $last-1));
    $parse ? $self->ParseVars($output) : $output;
}

sub ParseAttr {
    my $self = shift; my $attr = shift;
    my $parsed_attr = {};
    while (my($var, $val) = each %$attr) {
	if ($val =~ /\$\_\W/) {
	    $_ = $self;
	    $parsed_attr->{$var} = eval $val;
	    die $@ if $@;
	} elsif ($val =~ /\$/) {
	    $parsed_attr->{$var} = $self->ParseVars($val);
	} else {
	    $parsed_attr->{$var} = $val;
	}
    }
    $parsed_attr;
}

sub RepeatedTokenMarch {
    my $self = shift; my $tokens = shift;
    my $first = $tokens->First();
    my $last = $tokens->Last();
    my $res = $self->TokenMarch($tokens);
    $tokens->First($first);
    $tokens->Last($last);
    $res;
}
sub TokenMarch {
    my($self, $tokens) = @_;
    my $debug = $self->{'debug'};

    push(@{$self->{'_ep_output_stack'}}, $self->{'_ep_output'});
    $self->{'_ep_output'} = '';
    $self->print("TokenMarch: From ", $tokens->First(), " to ",
		 $tokens->Last(), ".\n") if $debug >= 2;
    while (defined(my $token = $tokens->Token())) {
	my $type = $token->{'type'};
	my $res;
	if ($type eq 'T') {
	    $res = $token->{'text'};
	} elsif ($token->{'type'} eq 'S') {
	    my $method = "_$token->{'tag'}";
	    my $attr = $token->{'attr'};
	    $method =~ s/\-/_/g;
	    $res = $self->$method($self->ParseAttr($attr), $tokens, $token);
	    if (!defined($res)) {
		# Upwards compatibility: If the method returned undef, then
		# it is a multiline tag in the sense of EP1. We've got to
		# collect all lines until a matching /$tag and evaluate it.
		my $def = delete $tokens->{'default'};
		my $first = $tokens->First();
		my $last = $self->FindEndTag($tokens, $token->{'tag'});
		my $t = $tokens->Clone($first, $last-1);
		$attr->{$def} = $self->TokenMarch($t);
		$res = $self->$method($attr, $tokens);
	    }
	} elsif ($token->{'type'} eq 'I') {
	    $res = $self->RepeatedTokenMarch($token->{'tokens'});
	} elsif ($token->{'type'} eq 'E') {
	    die "Unexpected end tag: /$token->{'tag'} without $token->{'tag'}";
	} else {
	    die "Unknown token type $self->{'type'}";
	}
	$self->{'_ep_output'} .= $res;
    }
    my $result = $self->{'_ep_output'};
    $self->print("TokenMarch: Returning $result.\n") if $debug >= 2;
    $self->{'_ep_output'} = pop(@{$self->{'_ep_output_stack'}});
    $result;
}




sub WarnHandler {
    my $msg = shift;
    die $msg unless defined($^S);
    print STDERR $msg;
    print STDERR "\n" unless $msg =~ /\n$/;
}


sub SimpleError {
    my($self, $template, $errmsg, $admin) = @_;
    my $r;
    $r = $self->{'_ep_r'} if $self && ref($self);
    $admin ||= ($r ? $r->cgi_var('SERVER_ADMIN') : $ENV{'SERVER_ADMIN'});
    $admin = $admin ? "<A HREF=\"mailto:$admin\">Webmaster</A>" : 'Webmaster';
    my $vars = { errmsg => $errmsg, admin => $admin };

    if (!$template) {
        $template = <<'END_OF_HTML';
<HTML><HEAD><TITLE>Fatal internal error</TITLE></HEAD>
<BODY><H1>Fatal internal error</H1>
<P>An internal error occurred. The error message is:</P>
<PRE>
$errmsg$.
</PRE>
<P>Please contact the $admin$ and tell him URL, time and error message.</P>
<P>We apologize for any inconvenience, please try again later.</P>
<BR><BR><BR>
<P>Yours sincerely</P>
</BODY></HTML>
END_OF_HTML
    }

    $template =~ s/\$(\w+)\$/$vars->{$1}/g;
    if ($r) {
        $r->print($self->{'cgi'}->header('-type' => 'text/html'), $template);
    } else {
        print("content-type: text/html\n\n", $template);
	exit 0;
    }
}

sub print ($;@) {
    my $self = shift;
    $self->{_ep_r} ? $self->{_ep_r}->print(@_) : print @_;
}

sub printf {
    my($self, $format, @args) = @_;
    $self->print(sprintf($format, @args));
}

sub escapeHTML {
    my $self = shift; my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/\"/&quot;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/\$/&#36;/g;
    $str;
}

sub FindVar {
    my($self, $var, $subvar) = @_;
    if ($var eq 'cgi') {
	$subvar =~ s/\-\>//;
	return $self->{'cgi'}->param($subvar);
    }

    $var = $self->{$var};
    while ($subvar  &&  $subvar =~ /^\-\>(\w+)(.*)/) {
	return '' unless ref $var;
	my $v = $1;
	$subvar = $2;
	if ($v =~ /^\d+$/) {
	    $var = $var->[$v];
	} else {
	    $var = $var->{$v};
	}
    }
    defined $var ? $var : '';
}

sub ParseVar {
    my($self, $type, $var, $subvar) = @_;
    my $func;

    if ($type  &&  $type eq '&') {
	# Custom format
	$func = exists($self->{'_ep_custom_formats'}->{$var}) ?
	    $self->{'_ep_custom_formats'}->{$var} : "_format_$var";

	# First part of subvar becomes var
	if ($subvar  &&  $subvar =~ /^\-\>(\w+)(.*)/) {
	    $var = $1;
	    $subvar = $2;
	} else {
	    $var = '';
	}
    }

    $var = FindVar($self, $var, $subvar);

    if (!$type  ||  $type eq '%') {
	$var = $self->escapeHTML($var);
    } elsif ($type eq '#') {
	$var = CGI->escape($var);
    } elsif ($type eq '~') {
	my $dbh = $self->{'dbh'} || die "Not connected";
	$var = $dbh->quote($var);
    } elsif ($func) {
	$var = $self->$func($var);
    }

    $var;
}

sub ParseVars ($$) {
    my($self, $str) = @_;
    $str =~ s/\$([\&\@\#\~\%]?)(\w+)((?:\-\>\w+)*)\$/$self->ParseVar($1,$2,$3)/eg;
    $str;
}



# For debugging
sub Dump {
    my $self = shift;
    require Data::Dumper;
    Data::Dumper->new([@_])->Indent(1)->Terse(1)->Dump();
}

sub SetCookies {
    my $self = shift;
    my @cookies = values %{$self->{'_ep_cookies'}};
    return () unless @cookies;
    print "Setting cookies:\n", $self->Dump(\@cookies), "\n"
	if $self->{'debug'};
    ('-cookie' => \@cookies);
}



sub EvalIf {
    my($self, $tag, $attr) = @_;
    my $debug = $self->{'debug'};
    if (exists($attr->{'eval'})) {
	$self->print("$tag: Evaluating $attr->{'eval'}\n") if $debug;
	return $attr->{'eval'};
    }
    if (exists($attr->{'neval'})) {
	$self->print("$tag: Evaluating ! $attr->{'neval'}\n") if $debug;
	return !$attr->{'neval'};
    }
    die "Missing condition" unless(exists($attr->{'cnd'}));
    if ($attr->{'cnd'} =~ /^(.*?)(==|!=|<=?|>=?)(.*)$/) {
	$self->print("$tag: Numeric condition $1 $2 $3\n") if $debug;
	my $left = $1 || 0;
	my $cnd = $2;
	my $right = $3 || 0;
	return ($left == $right) if $cnd eq '==';
	return ($left != $right) if $cnd eq '!=';
	return ($left < $right) if $cnd eq '<';
	return ($left > $right) if $cnd eq '>';
	return ($left >= $right) if $cnd eq '>=';
	return ($left <= $right);
    }
    die "Cannot parse condition cnd=$attr->{'cnd'}"
	unless $attr->{'cnd'} =~ /^\s*\'(.*?)\'\s*(eq|ne)\s*\'(.*)\'\s*$/;
    $self->print("$tag: String condition $1 $2 $3\n") if $debug;
    return $1 eq $3 if $2 eq 'eq';
    return $1 ne $3;
}



sub init { 1 }

sub Stop ($) { my($self) = @_; $self->{_ep_stop} = 1; }


sub _ep_comment {
    my $self = shift; my $attr = shift;
    $self->AttrVal($attr->{'comment'}, @_);
    '';
}


sub _ep_package {
    my $self = shift; my $attr = shift;
    my $package = $attr->{name};
    if (!exists($attr->{'require'})  ||  $attr->{'require'}) {
	my @inc = ($ENV{'DOCUMENT_ROOT'} . $attr->{'lib'},
		   $attr->{'lib'}, @INC) if $attr->{'lib'};
	local @INC = @inc if @inc;
        my $ppm = $package;
	$ppm =~ s/\:\:/\//g;
	require "$ppm.pm";
    }

    my $pack = ($self->{'_ep_package'} || 0) + 1;
    if ($attr->{'isa'}  ||  $self->{'_ep_package'}) {
	# If ep-package is called multiple times, or if $attr->{'isa'}
	# is set, we create a new package and bless $self into it.
	my @isa;
	@isa = split(',', $attr->{'isa'}) if @isa;
	my $p = ref($self);
	no strict 'refs';
	push(@isa, $p);
	my $bpack = "HTML::EP::PACK$pack";
	@{"$bpack\::ISA"} = ($package, @isa);
	bless($self, $bpack);
    } else {
	# Otherwise it's faster to bless $self into the package
	bless($self, $package);
    }
    $self->{'_ep_package'} = $pack;

    $self->init($attr);
    '';
}

sub _ep_debug {
    my $self = shift;
    my $cgi = $self->{'cgi'};

    my $debughosts = $self->{'_ep_config'}->{'debughosts'};
    if ($debughosts) {
	my $remoteip = '';
	my $remotehost = '';
	if ($self->{'_ep_r'}  &&  (my $r = $self->{'_ep_r'})) {
	    $remoteip = ($r->connection()->remote_ip() || '');
	    $remotehost = ($r->get_remote_host() || '');
	} else {
	    $remoteip = ($ENV{'REMOTE_ADDR'} || '');
	}
	die "Debugging not permitted from $remoteip"
	    . " ($remotehost), debug hosts = $debughosts"
		if (($remoteip and $remoteip !~ /$debughosts/)  and
		    ($remotehost !~ /$debughosts/));
    }

    $| = 1;
    $self->print($cgi->header('-type' => 'text/plain'));
    $self->print("Entering debugging mode;",
		 " list of input values:\n");
    foreach my $p ($cgi->param()) {
	$self->print(" $p = ", $cgi->param($p), "\n");
    }
    $self->{'debug'} = $cgi->param('debug') || 1;
    '';
}

sub GetPerlCode {
    my $self = shift;  my $attr = shift;

    my $code;
    if (my $file = $attr->{'src'}) {
	my $fh = Symbol::gensym();
	if (! -f $file  &&  -f ($self->{env}->{DOCUMENT_ROOT} . $file)) {
	    $file = ($self->{env}->{DOCUMENT_ROOT} . $file);
	}
	open($fh, "<$file") || die "Cannot open $file: $!";
	local $/ = undef;
	$code = <$fh>;
	die "Error while reading $file: $!" unless defined($fh) and close($fh);
    } else {
	$code = $self->AttrVal($attr->{'code'}, @_);
    }
    $code;
}

sub EvalPerlCode {
    my($self, $attr, $code) = @_;
    my $output;
    if ($attr->{'safe'}) {
	my $compartment = $self->{_ep_compartment};
	if (!$compartment) {
	    require Safe;
	    $compartment = $self->{_ep_compartment} = Safe->new();
	}
	if ($self->{debug}) {
	    $self->print("Evaluating in Safe compartment:\n$code\n");
	}
	local $_ = $self; # The 'local' is required for garbage collection
	$output = $compartment->reval($code);
    } else {
	$code = "package ".
	    ($attr->{'package'} || "HTML::EP::main").";".$code;
	$self->print("Evaluating script:\n$code\n") if $self->{'debug'};
	local $_ = $self; # The 'local' is required for garbage collection
	$output = eval $code;
    }
    die $@ if $@;
    $self->printf("Script returned:\n$output\nEnd of output.\n")
	if $self->{debug};
    $output;
}

sub EncodeByAttr {
    my($self, $attr, $str) = @_;
    my $debug = $self->{'debug'};
    $self->print("EncodeByAttr: Input $str\n") if $debug;
    if (my $type = $attr->{'output'}) {
	if ($type eq 'html') {
	    $str = $self->escapeHTML($str);
	} elsif ($type eq 'htmlbr') {
	    $str = $self->escapeHTML($str);
	    $str =~ s/\n/<br>/sg;
	} elsif ($type eq 'url') {
	    $str = CGI->escape($str);
	}
    }
    $self->print("EncodeByAttr: Output $str\n") if $debug;
    $str;
}

sub _ep_perl {
    my $self = shift; my $attr = shift;
    my $code = $self->GetPerlCode($attr, @_);
    return undef unless defined $code;
    $self->EncodeByAttr($attr, $self->EvalPerlCode($attr, $code));
}


sub _ep_database ($$;$) {
    my $self = shift; my $attr = shift;
    my $dsn = $attr->{'dsn'} || $self->{env}->{DBI_DSN};
    my $user = $attr->{'user'} || $self->{env}->{DBI_USER};
    my $pass = $attr->{'password'} || $self->{env}->{DBI_PASS};
    my $dbhvar = $attr->{'dbh'} || 'dbh';
    require DBI;
    $self->printf("Connecting to database: dsn = %s, user = %s,"
		  . " pass = %s\n", $dsn, $user, $pass) if $self->{'debug'};
    $self->{$dbhvar} = DBI->connect($dsn, $user, $pass,
				    { 'RaiseError' => 1, 'Warn' => 0,
				      'PrintError' => 0 });
    '';
}


sub SqlSetupStatement {
    my($self, $attr, $dbh, $statement) = @_;

    my $start_at = $attr->{'startat'} || 0;
    my $limit = $attr->{'limit'} || -1;
    if (($start_at  ||  $limit != -1)  &&
	$dbh->{'ImplementorClass'} eq 'DBD::mysql::db') {
	$statement .= " LIMIT $start_at, $limit";
	$start_at = 0;
    }
    if ($self->{'debug'}) {
	$self->print("Executing query, statement = $statement\n");
	$self->printf("Result starting at row %s\n",
		      $attr->{'startat'} || 0);
	$self->printf("Rows limited to %s\n", $attr->{'limit'});
    }
    my $sth = $dbh->prepare($statement);
    $sth->execute();
    ($sth, $start_at, $limit)
}

sub SqlSetupResult {
    my($self, $attr, $sth, $start_at, $limit) = @_;
    my $result = $attr->{'result'};
    my $list = [];
    my $ref;
    while ($limit  &&  $start_at-- > 0) {
	if (!$sth->fetchrow_arrayref()) {
	    $limit = 0;
	    last;
	}
    }
    my $resultmethod =
	(exists($attr->{'resulttype'})  &&  $attr->{'resulttype'} =~ /array/) ?
	    "fetchrow_arrayref" : "fetchrow_hashref";
    while ($limit--  &&  ($ref = $sth->$resultmethod())) {
	push(@$list, (ref($ref) eq 'ARRAY') ? [@$ref] : {%$ref});
    }
    if (exists($attr->{'resulttype'})  &&
	$attr->{'resulttype'} =~ /^single_/) {
	$self->{$result} = $list->[0];
    } else {
	$self->{$result} = $list;
    }
    $self->{"$result\_rows"} = scalar(@$list);
    $self->print("Result: ", scalar(@$list), " rows.\n") if $self->{'debug'};
}

sub _ep_query {
    my($self, $attr, $tokens, $token) = @_;
    my $debug = $self->{'debug'};
    my $statement = $self->AttrVal($attr->{'statement'}, $tokens, $token, 1);
    my $dbh = $self->{$attr->{'dbh'} || 'dbh'} || die "Not connected";
    if (!exists($attr->{'result'})) {
        $self->print("Doing Query: $statement\n") if $debug;
	$dbh->do($statement);
	return '';
    }

    $self->SqlSetupResult($attr,
			  $self->SqlSetupStatement($attr, $dbh, $statement));
    '';
}


sub _ep_select ($$;$) {
    my $self = shift;  my $attr = shift;
    my @tags;
    while (my($var, $val) = each %$attr) {
	if ($var !~ /^template|range|format|items?|selected(?:\-text)?$/i){
	    push(@tags, sprintf('%s="%s"', $var, $self->escapeHTML($val)));
	}
    }

    $attr->{'format'} = '<SELECT ' . join(" ", @tags) . '>$@output$</SELECT>';
    $self->_ep_list($attr, @_);
}


sub _ep_list {
    my($self, $attr, $tokens, $token) = @_;
    my $debug = $self->{'debug'};
    my $template;
    if (defined($attr->{'template'})) {
	my $parser = HTML::EP::Parser->new();
	$parser->text($attr->{'template'});
	$template = HTML::EP::Tokens->new('tokens' => $parser->{'_ep_tokens'});
    } else {
	my $first = $tokens->First();
	my $last = $self->FindEndTag($tokens, $token->{'tag'});
	$template = $tokens->Clone($first, $last-1);
    }
    my $output = '';
    my($list, $range);
    if ($range = $attr->{'range'}) {
	$list = [ map { $_ =~ /(\d+)\.\.(\d+)/ ? ($1 .. $2) : $_}
		  split(/,/, $range) ];
    } else {
	my $items = $attr->{'items'};
	$list = ref($items) ? $items :
	    ($items =~ /^(\w+)((?:\-\>\w+)+)$/) ?
		$self->FindVar($1, $2) : $self->{$items};
    }
    $self->print("_ep_list: Template = $template, Items = ", @$list, "\n")
	if $debug;
    my $l = $attr->{'item'} or die "Missing item name";
    my $i = 0;
    my $selected = $attr->{'selected'};
    my $isSelected;
    foreach my $ref (@$list) {
	$self->{$l} = $ref;
	$self->{'i'} = $i++ unless $l eq 'i';
	if ($selected) {
	    if (ref($ref)  eq  'HASH') {
		$isSelected = $ref->{'val'} eq $selected;
	    } elsif (ref($ref) eq 'ARRAY') {
		$isSelected = $ref->[0] eq $selected;
	    } else {
		$isSelected = $ref eq $selected;
	    }
	    $self->{'selected'} = $isSelected ?
		($attr->{'selected-text'} || 'SELECTED') : '';
	}
	$output .= $self->ParseVars($self->RepeatedTokenMarch($template));
    }
    if (my $format = $attr->{'format'}) {
	$attr->{'output'} = $output;
	$format =~ s/\$([\@\#\~]?)(\w+)((?:\-\>\w+)*)\$/HTML::EP::ParseVar($attr, $1, $2, $3)/eg;
	$format;
    } else {
	$output;
    }
}


sub _ep_errhandler {
    my $self = shift; my $attr = shift;
    my $type = $attr->{type};
    $type = ($type  &&  (lc $type) eq 'user') ? 'user' : 'system';
    if ($attr->{src}) {
	$self->{"_ep_err_file_$type"} = $attr->{src};
    } else {
	my $template = $self->AttrVal($attr->{'template'}, @_);
	$self->{"_ep_err_msg_$type"} = $template;
    }
    '';
}


sub _ep_error {
    my($self, $attr, $tokens, $token) = @_;
    my $msg = $self->AttrVal($attr->{'msg'}, $tokens, $token, 1);
    my $type = $attr->{'type'};
    $self->{_ep_err_type} = ($type  &&  (lc $type) eq 'user') ? 1 : 0;
    die $msg;
    '';
}


sub _ep_input_sql_query {
    my $self = shift;  my $attr = shift;
    my $dbh = $self->{'dbh'} ||
	die "Missing database-handle (Did you run ep-database?)";
    my $dest = $attr->{'dest'} ||
	die "Missing attribute 'dest' (Destination variable)";
    my $debug = $self->{'debug'};

    my $names = '';
    my $values = '';
    my $update = '';
    my $comma = '';
    while (my($var, $val) = each %{$self->{$dest}}) {
	$names .= $comma . $var;
	my $v = $val->{'val'};
	$v = $dbh->quote($v) if !defined($v) || $val->{'type'} ne 'n';
	$values .= $comma . $v;
	$update .= $comma . "$var=$v";
	$comma = ',' unless $comma;
    }
    my $hash = $self->{$dest};
    $hash->{'names'} = $names;
    print "_ep_input_sql_query: Setting $dest\->names to $names\n" if $debug;
    $hash->{'values'} = $values;
    print "_ep_input_sql_query: Setting $dest\->values to $values\n" if $debug;
    $hash->{'update'} = $update;
    print "_ep_input_sql_query: Setting $dest\->update to $update\n" if $debug;
    '';
}

sub _ep_input {
    my($self, $attr) = @_;
    my $prefix = $attr->{'prefix'};
    my($var, $val);
    my $cgi = $self->{'cgi'};
    my @params = $cgi->param();
    my $i = 0;
    my $list = $attr->{'list'};
    my $dest = $attr->{'dest'};

    $self->{$dest} = [] if $list;
    while(1) {
	my $p = $prefix;
	my $hash = {};
	if ($list) {
	    $p .= "$i\_";
	}
	foreach $var (@params) {
	    if ($var =~ /^\Q$p\E\_?(\w+?)_(.*)$/) {
		my $col = $2;
		my $type = $1;
		if ($type =~ /^d[dmy]$/) {
		    # A date
		    if ($hash->{$col}) {
			# Do this only once
			next;
		    }
		    if (!$hash->{$col}) {
			my $year = $cgi->param("${p}dy_$col");
			my $month = $cgi->param("${p}dm_$col");
			my $day = $cgi->param("${p}dd_$col");
			if ($year eq ''  &&  $month eq ''  &&  $day eq '') {
			    $val = undef;
			} else {
			    if ($year < 20) {
				$year += 2000;
			    } elsif ($year < 100) {
				$year += 1900;
			    }
			    $val = sprintf("%04d-%02d-%02d",
					   $year, $month, $day);
			}
			$hash->{$col} = { col => $col,
					  val => $val,
					  type => 'd',
					  year => $year,
					  month => $month,
					  day => $day
					  };
		    }
		} else {
		    $val = ($type eq 's') ?
			join(",", $cgi->param($var)) : $cgi->param($var);
		    $hash->{$col} = { col => $col,
				      type => $type,
				      val => $val
				      };
		}
	    }
	}
	if ($list) {
	    die "Cannot create 'names', 'values' and 'update' attributes"
		. " if 'list' is set." if $attr->{'sqlquery'};
	    last unless %$hash;
	    $hash->{'i'} = $i++;
	    push(@{$self->{$dest}}, $hash);
	} else {
	    $self->{$dest} = $hash;
	    $self->_ep_input_sql_query($attr) if $attr->{'sqlquery'};
	    last;
	}
    }
    if ($self->{'debug'}) {
	$self->print("_ep_input: Gelesene Daten\n",
                     $self->Dump($self->{$dest}));
    }
    '';
}

sub _ep_if {
    my($self, $attr, $tokens, $token) = @_;
    my $level = 0;
    my $tag = $token->{'tag'};
    my $state = $self->EvalIf($tag, $attr);
    my $start = $tokens->First() if $state;
    my $state_done = $state;
    my $last;
    while (defined(my $token = $tokens->Token())) {
	if ($token->{'type'} eq 'S') {
	    if ($token->{'tag'} eq 'ep-if') {
		++$level;
	    } elsif ($token->{'tag'} =~ /^ep-els(?:e|e?if)?$/) {
		next if $level;
		if ($state) {
		    $last = $tokens->First()-1;
		    $state = 0;
		} elsif (!$state_done) {
		    if ($state = $token->{'tag'} eq 'ep-else' ||
			$self->EvalIf
			    ($tag, $self->ParseAttr($token->{'attr'}))) {
			$state_done = 1;
			$start = $tokens->First();
		    }
		}
	    }
	} elsif ($token->{'type'} eq 'E') {
	    if ($token->{'tag'} eq 'ep-if') {
		next if $level--;
		return '' unless $state_done;
		$last = $tokens->First()-1 if $state;
		return $self->TokenMarch($tokens->Clone($start, $last));
	    }
	}
    }
    die "ep-if without /ep-if";
}

sub _ep_elseif { die "ep-elseif without ep-if" }
sub _ep_elsif { die "ep-elsif without ep-if" }
sub _ep_else { die "ep-else without ep-if" }


sub _ep_mail {
    my($self, $attr, $tokens, $token) = @_;

    my $host = (delete $attr->{'mailserver'})  ||
	$self->{'_ep_config'}->{'mailhost'} || '127.0.0.1';
    my @options;
    my $body = $self->AttrVal($attr->{'body'}, $tokens, $token, 1);
    require Mail::Header;
    my $msg = Mail::Header->new();
    my($header, $val);
    my $from = $attr->{'from'} || die "Missing header attribute: from";
    die "Missing header attribute: to" unless $attr->{'to'};
    die "Missing header attribute: subject" unless $attr->{'subject'};
    while (($header, $val) = each %$attr) {
	$msg->add($header, $val);
    }
    require Net::SMTP;
    require Mail::Internet;
    my $debug = $self->{'debug'};
    local *STDERR if $debug;
    if ($debug) {
	$self->print("Headers: \n");
	$self->print($msg->as_string());
        $self->print("Making SMTP connection to $host.\n");
        open(STDERR, ">&STDOUT");
    }
    my $smtp = Net::SMTP->new($host, 'Debug' => $debug)
        or die "Cannot open SMTP connection to $host: $!";
    my $mail = Mail::Internet->new([$body], Header => $msg);
    $Mail::Util::mailaddress = $from; # Ugly hack to prevent
                                      # DNS lookup for 'mailhost'
                                      # in Mail::Util::mailaddress().
    $mail->smtpsend('Host' => $smtp, @options);
    $smtp->quit();
    '';
}


sub _ep_include {
    my($self, $attr, $tokens, $token) = @_;
    my $parser = HTML::EP::Parser->new();
    my $f = $attr->{'file'}  ||  die "Missing file name\n";
    my $df = $self->{'env'}->{'DOCUMENT_ROOT'} . $f;
    $f = $df if -f $df;
    my $fh = Symbol::gensym();
    open($fh, "<$f") || die "Failed to open file $f: $!";
    $parser->parse_file($fh);
    $parser->eof();
    my $new_toks = HTML::EP::Tokens->new('tokens' => $parser->{'_ep_tokens'});
    $tokens->Replace
	($tokens->First()-1,
	 { 'type' => 'I',
	   'tokens' => $new_toks
	 }) if $tokens; # Upwards compatibility: Before EP 0.20 users
                        # didn't pass a tokens argument.
    $self->RepeatedTokenMarch($new_toks)
}


sub _ep_exit {
    my $self = shift;
    # If we are inside of an ep-if, we need to collect previous output
    $self->{'_ep_output'} = join('', @{$self->{'_ep_output_stack'}},
				 $self->{'_ep_output'});
    die "_ep_exit, ignore";
}

sub _ep_redirect {
    my $self = shift; my $attr = shift;
    my $to = $attr->{'to'} or die "Missing redirect target";
    $self->print("Redirecting to $to\n") if $self->{'debug'};
    $self->print($self->{'cgi'}->redirect('-uri' => $to,
                                          '-type' => 'text/plain',
					  '-refresh' => "0; URL=$to",
                                          $attr->{'cookies'} ?
                                              $self->SetCookies() : ()));
    $self->print('<BODY BGCOLOR="#FFFFFF">Click <A HREF="', $to,
                 '">here</A> to go on</BODY>');
    $self->Stop();
    '';
}

sub _ep_set {
    my($self, $attr, $tokens, $token) = @_;
    my $val = $self->AttrVal($attr->{'val'}, $tokens, $token,
			     !$attr->{'noparse'});
    my $var = $attr->{'var'};
    my $ref = $self;
    while ($var =~ /(.*?)\-\>(.*)/) {
        my $key = $1;
        $var = $2;
        if ($key =~ /^\d+$/) {
            $ref = $ref->[$key];
        } else {
            $ref = $ref->{$key};
        }
    }
    print "Setting $ref -> $var to $val\n" if $self->{'debug'};
    if ($var =~ /^\d+$/) {
        $ref->[$var] = $val;
    } else {
        $ref->{$var} = $val;
    }
    '';
}

sub _format_NBSP {
    my $self = shift; my $str = shift;
    if (!defined($str)  ||  $str eq '') {
	$str = '&nbsp;';
    }
    $str;
}


1;
