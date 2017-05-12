package Egg::Util;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Util.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Base /;
use URI;

our $VERSION= '3.01';

sub page_title {
	my $e= shift;
	return ($e->stash->{page_title} ||= $e->config->{title}) unless @_;
	$e->stash->{page_title}= shift || $e->config->{title};
}
sub debug {
	$_[0]->flag->{-debug} || 0;
}
sub flag {
	my $e  = shift;
	my $key= shift || return $e->global->{flag};
	   $key=~s{^\-} [];
	$e->global->{flag}{ '-'. lc $key } || 0;
}
sub snip {
	my $e= shift;
	return $e->{snip} unless @_;
	$e->{snip}= $_[0] ? ($_[1] ? [@_]: $_[0]): croak q{ I want argument. };
}
sub action {
	my $e= shift;
	return $e->{action} unless @_;
	$e->{action}= $_[0] ? ($_[1] ? [@_]: $_[0]): croak q{ I want argument. };
}
sub stash {
	my $e= shift;
	return $e->{stash} unless @_;
	return $e->{stash}{$_[0]} if @_ < 2;
	$e->{stash}{$_[0]}= $_[1];
}
sub path_to {
	my $e= shift;
	my $class= ref($e) || $e;
	my $path= shift || return $class->config->{dir}{root};
	if (my $name= shift) {
		my $root= $class->config->{dir}{$path} || croak qq{'$path' is empty.};
		return "${root}/$name";
	} else {
		if (my $dir= $class->config->{dir}{$path}) { return $dir }
		return $class->config->{root}. "/$path";
	}
}
sub uri_to {
	my $e  = shift;
	my $uri= shift || croak q{ I want base URI };
	my $result= URI->new($uri);
	return $result unless @_;
	my %arg= ref($_[0]) eq 'HASH' ? %{$_[0]}: @_;
	$result->query_form(%arg);
	$result;
}
sub snip2template {
	my $e   = shift;
	my $num = shift || croak q{ I want snip num. };
	my $snip= $e->snip || return 0;
	@$snip < $num and croak q{ snip num error. };
	my $c= $e->config;
	my $tmpl= $e->template(
	  join('/', map{$_ || ""}@{$snip}[0..$num]). ".$c->{template_extention}"
	  );
	-e "$c->{template_path}[0]/$tmpl" ? $tmpl: 0;
}
sub setup_error_header {
	my($e)= @_;
	$e->response->clear_cookies;
	$e->response->clear_body;
	$e->response->no_cache(1);
	$e->response->headers->{"X-Egg-$e->{namespace}-ERROR"}= 'true';
	1;
}
sub get_config {
	my $e   = shift;
	my $name= shift || (caller())[0] || return {};
	$name=~s{\=.*?$} [];
	$name=~s{^(?:main$|Egg:+)} [];
	return $e->config if (! $name or $name eq $e->namespace);
	my $conf= $e->config;
	my $key = lc($name); $key=~s{\:+} [_]g;
	return $conf->{$key} if $conf->{$key};
	$key = lc($name);
	$key=~s{\:+[^\:]+$} []; $key=~s{\:+} [_]g;
	$conf->{$key} || {};
}
sub egg_var {
	my $e    = shift;
	my $param= shift || croak q{ I want base parameter. };
	my $str  = defined($_[0]) ? shift: return "";
	my $text;
	if (my $type= ref($str)) {
		return $str unless $type eq 'SCALAR';
		$text= $str;
	} else {
		$text= \$str;
	}
	return "" unless defined($$text);
	$$text=~s{([\\]?)< *\$?e\.([\w\.]+) *>}
	   [ $1 ? "<e.$2>": _replace($2, $e, $param, @_) ]sge;
	$$text;
}
sub egg_var_deep {
	my $e    = shift;
	my $param= shift || croak q{ I want base parameter. };
	my $value= defined($_[0]) ? $_[0]: return "";
	if (my $type= ref($value)) {
		if ($type eq 'HASH') {
			while (my($k, $v)= each %$value) {
				ref($v) ? $e->egg_var_deep($param, $v)
				        : $e->egg_var($param, \$v);
				$value->{$k}= $v;
			}
		} elsif ($type eq 'ARRAY') {
			for (@$value) {
				ref($_) ? $e->egg_var_deep($param, $_)
				        : $e->egg_var($param, \$_);
			}
		} else {
			return $value;
		}
	} else {
		return $e->egg_var($param, \$value);
	}
	$e;
}
sub _replace {
	my @part= split /\.+/, shift;
	my $v;
	eval "\$v= \$_[1]->{". join('}{', @part)."}";  ## no critic
	defined($v) ? do { ref($v) eq 'CODE' ? $v->(@_): $v }: "";
}
sub error {
	my $self= shift;
	$self->next::method(@_);
	if (my $error= $self->errstr) { $self->stash->{error}= $error }
	0;
}
sub _debug_screen {
	my $e= shift;
	$e->debugging->error(@_);
	$e->setup_error_header;
	$e->finished('500 Internal Server Error');
	$e->_output;
}
sub _check_config {
	my $e = shift;
	my $cf= shift || croak q{ I want configuration. };
	$cf->{root} || die q{ I want 'root' configuration. };
	$cf->{root}=~s{[/\\]+$} [];
	$cf->{project}= $e->namespace;
	$cf->{project}=~s{\:+} []g;
	$cf->{title} ||= $e->namespace;
	$cf->{content_type} ||= 'text/html';
	$cf->{template_extention} ||= 'tt';
	$cf->{template_extention}=~s{^\.+} [];
	$cf->{template_default_name} ||= 'index';
	$cf->{template_path} ||= ["$cf->{root}/root"];
	$cf->{template_path}= [$cf->{template_path}]
	                    unless ref($cf->{template_path}) eq 'ARRAY';
	s{[/\\]+$} [] for @{$cf->{template_path}};
	$cf->{static_uri} ||= '/';
	$cf->{static_uri}.= '/' unless $cf->{static_uri}=~m{/$};
	my $dir= $cf->{dir} ||= {};
	for (qw/ cache etc htdocs lib tmp /) {
		$dir->{$_} ||= "$cf->{root}/$_";
		$dir->{$_}=~s{[/\\]+$} [];
	}
	$dir->{root}   = $cf->{root};
	$dir->{static} = $dir->{htdocs};
	$dir->{temp} ||= $dir->{tmp};
	$dir->{comp} ||= $cf->{template_path}->[1] || "$dir->{root}/comp";
	$dir->{template} ||= $cf->{template_path}->[0];
	$dir->{lib_project}= "$dir->{lib}/$cf->{project}";
	$cf;
}
sub _load_config {
	my $class= shift;
	my $conf = shift || croak q{ I want config };
	   $conf = {$conf, @_} if $_[0];
	$class->_check_config($conf);
	$class->egg_var_deep($conf, $conf->{dir});
	$class->egg_var_deep($conf, $conf);
	$conf;
}

1;

__END__

=head1 NAME

Egg::Util - Standard method of utility for Egg. 

=head1 DESCRIPTION

This module offers the method of utility for Egg.

=head1 METHODS

=head2 page_title ([TITLE_STRING])

The title of the output contents is set. 

The value is substituted for $e-E<gt>stash-E<gt>{page_title}.

When TITLE_STRING was omitted, the value of the defined value or $e-E<gt>config-E<gt>{title}
had already been used.

  $e->page_title('Hoge Page');

=head2 debug

True is restored if it is operating by debug mode.

=head2 flag

Refer to the value of the flag set by the start option.
The value cannot be set.

 use Egg qw/ -MyFlag /;

  if ($e->flag('MyFlag')) {
     ...........

=head2 snip

Refer to the value though L<Egg::Response> divides the URI by '/' at each request
and it preserves it as ARRAY reference.

 my($path1, $path2)= @{$e->snip};

=head2 action

The ARRAY reference to divide request URI to the place matched with dispatch_map
by '/' is returned.

  my($path1, $path2)= @{$e->action};

=head2 stash ([KEY], [VALUE]);

It is a place where the common data is treated.

When KEY is given, data corresponding to KEY is returned.

When KEY and VALUE are given, data corresponding to KEY is set.

When the argument is not given, the HASH reference of the common data is 
returned.

  my $tmpl= $e->stash('template');
  
  $e->stash( template => 'hoge.tt' );
  
  my $tmpl= $e->stash->{template};

=head2 path_to ([ARG1], [ARG2])

When the argument is omitted, the value of $e-E<gt>config-E<gt>{root} is returned.
Project route in a word.

When ARG1 is given, "$e-E<gt>config-E<gt>{root}/ARG1" is returned.

When ARG2 is given, "$e-E<gt>config-E<gt>{dir}{ARG1}/ARG2" is returned.

  my $project_root= $e->path_to;
  
  my $cache_dir = $e->path_to('cache');
  
  my $yaml= $e->path_to('etc', 'mydata.yaml');

=head2 uri_to ([URI], [ARGS])

The result of the URI module is returned.

  my $uri= $e->uri_to($e->req->host_name);

=head2 snip2template ([NUM])

The template name is generated with the value to the element given with NUM
for $e-E<gt>snip.

  my $template= $e->snip2template(3);

=head2 setup_error_header

The content set in call L<Egg::Response> when the error etc. occur is initialized
and the header for the error etc. are set.

=head2 get_config

This is a convenient method to the reference to the configuration in which Egg
system module is defined in the parents package.

=head2 egg_var ([PARAM], [STRING])

It is a method for the use of a peculiar replace function to Egg.

The HASH reference for the substituted data is given to PARAM.

<e.[name]> of STRING is replaced by the value of PARAM corresponding to [name].

Even if it is <e.[name].[name2]>, the key can be handled well.

  my $param= { data => { hoge=> '123' } };
  my $text = "abc <e.data.hoge>";
  $e->egg_var($param, $text);
  print $text;  # -> abc 123

=head2 egg_var_deep ([PARAM], [VALUE])

It is a method for the use of a peculiar replace function to Egg.

Only the character string is treated as for egg_var, and if VALUE is HASH and ARRAY,
the contents also recurrently try substituting here.

  my $param= { hoge=> '123' };
  my $hash = { data=> 'abc <e.hoge>' };
  $e->egg_var_deep($param, $hash);
  print $hash->{data}; # -> abc 123

=head2 error ([MESSAGE])

To do some error processing, the error message is set.

The message is set in $e->errstr and $e-E<gt>stash-E<gt>{error}.

Because this method always returns 0, it is not possible to use it to judge the
error situation of the occurrence.
Please look at $e-E<gt>errstr and $e-E<gt>stash-E<gt>{error}.

  $e->error('Intarnal Error.');
  
  if ($e->errstr) {
     .......

=head2 SEE ALSO

L<Egg::Release>,
L<Tie::Hash::Indexed>,
L<URI>,

=head2 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head2 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

