package HTML::Template::Ex;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Ex.pm 297 2007-03-25 14:34:59Z lushe $
#
use strict;
use warnings;
use base qw/HTML::Template/;
use Carp qw/croak/;
use Digest::MD5 qw/md5_hex/;

our $VERSION = '0.08';

my $ErrstrStyle= <<END_OF_STYLE;
padding    : 5px;
background : #004858;
color      : #FFF;
font-size  : 13px;
END_OF_STYLE

sub initStyle { $ErrstrStyle= $_[1] }

my $GetCharSetRegix=
 qr{<meta.+?content=[\'\"]text/html\s*\;\s*charset=([A-Za-z0-9\-_]+)[\'\"].*?/?\s*>};

sub new {
	my $class= shift;
	my $base = shift || HTML::Template::Ex::DummyObject->new;
	my %opt  = $_[0] ? ($_[1] ? @_: %{$_[0]})
	  : croak __PACKAGE__.'::new: I want argument.';

	for (
	  [qw{ strict 0 }],
	  [qw{ file_cache 0 }],
	  [qw{ global_vars 1 }],
	  [qw{ shared_cache 0 }],
	  [qw{ die_on_bad_params 0 }],
	  ) {
		$opt{$_->[0]}= $_->[1] if exists($opt{$_->[0]});
	}

	my(%param, %mark, %order, %temp);
	$opt{_ex_base_object}= $base;
	$opt{_ex_params}     = \%param;
	$opt{_ex_orders}     = \%order;
	$opt{_ex_mark}       = \%mark;
	if (exists($opt{filter})) {
		if (ref($opt{filter}) eq 'CODE') {
			$opt{filter}= [{ format=> 'scalar', sub=> $opt{filter} }];
		} elsif (ref($opt{filter}) eq 'HASH') {
			$opt{filter}= [$opt{filter}];
		} elsif (ref($opt{filter}) ne 'ARRAY') {
			croak __PACKAGE__.q{::new: Bad format for 'filter'};
		}
	}
	if ($opt{setup_env}) {
		$param{"env_$_"}= sub { $ENV{$_} || "" } for keys %ENV;
	}
	my $filter= $opt{exec_off}
	 ? sub { &_offFilter(\%param, @_) }
	 : sub { &_exFilter($base, \%opt, \%temp, @_) };
	push @{$opt{filter}}, { format=> 'scalar', sub=> $filter };
	my $self= HTML::Template::new($class, %opt);
	$opt{cache} and $self->{_ex_charset}= pop @{$self->{parse_stack}} || "";
	$self;
}
sub output {
	my($self)= @_;
	my $parse_stack= $self->{parse_stack};
	my $options    = $self->{options};
	my($ex_mark, $ex_param, $ex_order);
	if ($options->{cache}) {
		$ex_mark = pop @$parse_stack;
		$ex_param= pop @$parse_stack;
		$ex_order= pop @$parse_stack;
	} else {
		$ex_mark = $options->{_ex_mark}   || {};
		$ex_param= $options->{_ex_params} || {};
		$ex_order= $options->{_ex_orders} || {};
	}
	HTML::Template::param($self, $ex_mark);
	my $base = $options->{_ex_base_object};
	my %param= %$ex_param;

	$options->{no_strict_exec} and do { no strict };  ## no critic
	my $cnt;
	for my $v (@$parse_stack) {
		next if (ref($v) ne 'HTML::Template::VAR' || ! $$v);
		my $hash= $ex_order->{$$v} || next;
		++$cnt;
		my $result;
		eval{ $result= $hash->{function}->($base, \%param) };
		if (my $err= $@) {
			require HTML::Entities;
			require Devel::StackTrace;
			my $st= Devel::StackTrace->new( no_refs=> 1 );
			my $error;
			$error.= $_->filename. ': '
			      .  $_->line. "\n" for $st->frames;
			$error = HTML::Entities::encode_entities(
			  "<TMPL_EX( $cnt )> - error:\n $err \n stack trace:\n $error",
			  q{\\\<>&\"\'},
			  );
			$error=~s{\r?\n} [<br />\n]sg;
			$param{$$v}= qq{<div style="$ErrstrStyle">$error</div>};
		} else {
			$param{$$v}= ref($result) eq 'ARRAY' ? ""
			           : $hash->{hidden} ? "": ($result || "");
			$param{$hash->{key_name}}= $result if $hash->{key_name};
		}
	}

	HTML::Template::param($self, \%param);
	my $result= HTML::Template::output(@_);
	if ($options->{cache}) {
		push @$parse_stack, $ex_order;
		push @$parse_stack, $ex_param;
		push @$parse_stack, $ex_mark;
		push @$parse_stack, ($self->{_ex_charset} || "");
	}
	$result;
}
sub charset { $_[0]->{_ex_charset} || "" }

sub _call_filters {
	my($self, $html)= @_;
	$self->{_ex_charset}= $1 if $$html=~m{$GetCharSetRegix}i;
	if ($self->{options}{auto_encoder}) {
		$self->{options}{auto_encoder}->($html) if $self->{_ex_charset};
	} elsif ($self->{options}{encoder}) {
		$self->{options}{encoder}->($html);
	}
	HTML::Template::_call_filters(@_);
}
sub _exFilter {
	my($base, $opt, $temp, $text)= @_;
	$$text=~s{<tmpl_ex(\s+[^>]+\s*)?>(.+?)</tmpl_ex[^>]*>}
	         [ &_replaceEx($1, $2, $base, $opt, $temp) ]isge;
	$$text=~m{(?:<tmpl_ex[^>]*>|</tmpl_ex[^>]*>)}
	  and croak q{At least one <TMPL_EX> not terminated at end of file!};
	$$text=~s{<tmpl_set([^>]+)>} [ &_replaceSet($1, $opt->{_ex_params}) ]isge;
}
sub _offFilter {
	my($param, $text)= @_;
	$$text=~s{<tmpl_ex\s+[^>]+\s*?>.+?</tmpl_ex[^>]*>} []isg;
	$$text=~s{(?:<tmpl_ex[^>]*>|</tmpl_ex[^>]*>)} []isg;
	$$text=~s{<tmpl_set([^>]+)>} [ &_replaceSet($1, $param) ]isge;
}
sub _replaceSet {
	my $opt  = shift || return "[ tmpl_set Error!! ]";
	my $param= shift || return "[ tmpl_set Error!! ]";
	my $name = ($opt=~/name=\s*[\'\"]?([^\s\'\"]+)/)[0]
	        || return "[ tmpl_set Error!! ]";
	my $value= ($opt=~/value=\s*[\'\"](.+?)[\'\"]/)[0]
	        || ($opt=~/value=\s*([^\s]+)/)[0]
	        || return "[ tmpl_set Error!! ('$name') ]";
	$param->{$name}= $value if $value;
	"";
}
sub _replaceEx {
	my($tag, $code, $base, $opt, $temp)= @_;
	my $escape= my $default= "";
	my($exec, %attr);
	if ($tag) {
		$attr{key_name}= lc($1)     if $tag=~/name=[\"\']?([^\s\"\']+)/;
		$attr{hidden}= 1            if $tag=~/hidden=[\"\']?([^\s\"\']+)/;
		$escape = qq{ escape="$1"}  if $tag=~/escape=[\"\']?([^\s\"\']+)/;
		$default= qq{ default="$1"} if $tag=~/default=[\"\']?([^\s\"\']+)/;
	}
	my $ident= '__$ex_'. &_get_ident_id($opt) .'$'. (++$temp->{count}). '$__';
	$code= "no strict;\n". $code if $opt->{no_strict_exec};
	eval"\$exec= sub { $code }";  ## no critic
	$attr{function}= sub { $exec->(@_) || "" };
	$opt->{_ex_orders}{$ident}= \%attr;
	$opt->{_ex_mark}{$ident}  = $ident;
	qq{<tmpl_var name="$ident"$escape$default>};
}
sub _commit_to_cache {
	my($self)= @_;
	push @{$self->{parse_stack}}, $self->{options}{_ex_orders};
	push @{$self->{parse_stack}}, $self->{options}{_ex_params};
	push @{$self->{parse_stack}}, $self->{options}{_ex_mark};
	push @{$self->{parse_stack}}, ($self->{_ex_charset} || "");
	HTML::Template::_commit_to_cache(@_);
}
sub _get_ident_id {
	$_[0]->{___ident_id} ||= substr(md5_hex(time(). {}. rand()), 0, 32);
}

package HTML::Template::Ex::DummyObject;
use strict;
sub new { bless {}, shift }

1;

__END__

=head1 NAME

HTML::Template::Ex - The Perl code is operated in the template for HTML::Template.

=head1 SYNOPSIS

  package MyProject;
  use CGI;
  use Jcode;
  use HTML::Template::Ex;
  
  my $cgi = CGI->new;
  my $self= bless { cgi=> cgi }, __PACKAGE__;
  
  my $template= <<END_OF_TEMPLATE;
  <html>
  <head><title><tmpl_var name="title"></title></head>
  <body>
  <tmpl_set name="title" value="HTML::Template::Ex">
  
  <h1><tmpl_var name="page_title"></h1>
  <h2><tmpl_var name="title"></h2>
  
  <div style="margin:10; background:#DDD;">
  <tmpl_ex>
    my($self, $param)= @_;
    $param->{page_title}= 'My Page Title';
    return $self->{cgi}->param('name') || 'It doesn't receive it.';
  </tmpl_ex>
  </div>
  
  <div style="margin:10; background:#DDD;">
  <tmpl_loop name="users">
   <div>
   <tmpl_var name="u_name" escape="html">
   : <tmpl_var name="email" escape="html">
    </div>
  </tmpl_loop>
  </div>
  
  <tmpl_ex name="users">
    return [
     { u_name=> 'foo', email=> 'foo@mydomain'    },
     { u_name=> 'boo', email=> 'boo@localdomain' },
     ];
  </tmpl_ex>
  
  <tmpl_var name="env_remote_addr">
  
  <body></html>
  END_OF_TEMPLATE
  
  my $tmpl= HTML::Template::Ex->new($self, {
    setup_env=> 1,
    scalarref=> \$template,
    encoder  => sub { Jcode->new($_[0])->euc },
    # ... other 'HTML::Template' options.
    });
  
  print STDOUT $cgi->header, $tmpl->output;

=head1 DESCRIPTION

This module offers the function to evaluate the Perl code to the template that
HTML::Template uses.

The character string enclosed with '<TMPL_EX> ... </TMPL_EX>' is evaluated as
Perl code.

  <tmpl_ex>
    my($self, $param)= @_;
    my $hoge= $self->to_method;
    $param->{hoge}= $hoge;
    return "";
  </tmpl_ex>

The object passed to the constructor is passed to the first argument to the
tmpl_ex tag.

The second argument is HASH reference for the parameter that HTML::Template uses.

When the ending value of each tmpl_ex block is returned, the value is buried
under the position.
Therefore, it is necessary to return the dead blank character to bury anything.

When HTML::Template::Ex evaluates a little code, there is a little habit when a 
complex thing is done though it is convenient.

One is the priority level when two or more tmpl_ex blocks are described.

There is no problem for one template.
It is sequentially evaluated on.
And, please pay attention to the point done earlier than HTML::Template evaluates
tag about this evaluation.

The problem reads other templates from the template.
It is time when it exists also in the read template the tmpl_ex block.
HTML::Template::Ex is not intervened for the include of the template.
Therefore, after HTML::Template evaluates tag, the tmpl_ex block include ahead
will be evaluated. This sometimes causes confusion.

  <tmpl_include name="first.tmpl">  ... [3]
  <tmpl_ex>
   .... [ 1 ]
  </tmpl_ex>
  <tmpl_include name="middle.tmpl"> ... [4]
  <tmpl_ex>
   .... [ 2 ]
  </tmpl_ex>
  <tmpl_include name="end.tmpl">    ... [5]

And, the error message is a very difficult secondarily thing.

As for each tmpl_ex block, the code is individually evaluated with eval.
Therefore, it is not a translation processed while looking about the entire 
template. Therefore, only the error where eval originates is obtained.
As for this, specific in the error generation part becomes very difficult.

The thing of this problem solved only by HTML::Template::Ex is difficult.
Therefore, the improvement is not scheduled in the future.

Using HTML::Template::Ex on the assumption of the thing to write a complex
code doesn't come recommended though it is regrettable.
Intuition is compelled every time the error occurs and debugging is compelled 
to reliance. Perhaps, this will be annoyed by the stress.

Still, I think that it can do the template that works more high-speed than
HTML::Mason and Template ToolKit if the code can be completed.
Please try and look at interesting one. 

Therefore, HTML::Template::Ex selects it by the rental server etc. of the
template driver. We will recommend the usage not to expect many of the template
driver in the situation in which the leg is limited.


And, '<TMPL_IF >' doesn't have the meaning because it is evaluated earlier than
HTML::Template though it is a thing misunderstood easily at the end.

  <tmpl_if name="hoge">
    <tmpl_ex>
      ....
    </tmpl_ex>
  <tmpl_exse>
    <tmpl_ex>
      ....
    </tmpl_ex>
  </tmpl_if>

This is smoothly evaluated to diverge to both of the tmpl_ex block.
Please solve 'IF' related to tmpl_ex block in tmpl_ex block.

  <tmpl_ex>
    my($self, $param)= @_;
    if ($apram->{hoge}) {
      ...
    } else {
      ...
    }
    "";
  </tmpl_ex>


=head1 TAGS

It is enhancing tag that introduces here added by using HTML::Template::Ex. 
Please see the document of HTML::Template about standard tag of L<HTML::Template>.

=head2 <TMPL_EX ... > [PERL_CODE] </TMPL_EX>

The Perl code is evaluated in the template.

Please see DESCRIPTION for details concerning basic operation. 

When the NAME attribute is given, the value that the tmpl_ex block returned to
the parameter of the name is substituted.
Please give the HIDDEN attribute at the same time to prevent the value being
buried under the position of the tmpl_ex block. 

  <h1><tmpl_var name="hoge"></h1>
  
  <tmpl_ex name="hoge" hidden="1">
    my($self)= @_;
    ..... ban, bo, bon.
    return $self->request->param('Fooo');
  </tmpl_ex>

The ESCAPE attribute can be used. 

  <tmpl_ex escape="html">
    ..... ban, bo, bon.
    return "<font>Zooooo</font>";
  </tmpl_ex>

* After it is escaped of html, this is buried.

=head2 <TMPL_SET NAME='...' VALUE='...'>

The value is set in the parameter in the template.

=head2 <tmpl_var name='env_*[ Environment variable name. ]'>

When the setup_env option is given to the constructor, the environment variable
is set up. 
It can be referred to by '<TMPL_VAR NAME=...>'. Please specify the environment
variable name putting up 'env_' to the head of the name.

  <tmpl_var name="env_remote_addr">
  <tmpl_var name="env_path_info">

=head1 METHODS

=head2 new ([OBJECT], [OPTION])

It is a constructor.

An arbitrary object is given to the first argument.
The given object is passed as the first argument of each tmpl_ex block.

[OPTION] is an option to pass to HTML::Template. 
Please include the option of HTML::Template::Ex here.

Options.

=over 4

=item * setup_env

It is set up to refer to the environment variable.

=item * exec_off

All the tag that HTML::Template::Ex evaluates is invalidated and it puts it out.

=item * no_strict_exec

This is turned off though the code of the tmpl_ex block is evaluated under the strict 
environment usually. For person who is not accustomed to making strict code.

=item * encoder

The CODE reference to process the character-code can be defined.

=item * auto_encoder

When charset was able to be acquired from the template, encoder is processed.

=back

=head2 charset

When charset was able to be acquired from the template, the value is returned.

=head2 initStyle ([STYLE])

The output style etc. when the error occurs are defined.

=head2 output

Contents are output.

=head2 other

Please refer to the document of L<HTML::Template> for other methods.

=head1 NOTES

There is causing the defective operation according to the kind of the cash used
by HTML::Template option.

* If it is 'cache' option to specify at mod_perl, it operates normally usually.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
