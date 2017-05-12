package HTML::YaTmpl;
use strict;
use warnings;
no warnings 'uninitialized';
use HTML::YaTmpl::_parse;
use Class::Member::HASH qw{template file path package _extra errors onerror
			   eprefix no_eval_cache no_parse_cache _macros
			   compress debug
			   -CLASS_MEMBERS};
use Config ();
use IO::File ();
use File::Spec ();
use Errno ();
use Compress::Zlib ();

our $VERSION='1.8';
our @CLASS_MEMBERS;

#$SIG{INT}=sub {
#  use Carp 'cluck';
#  cluck "SIGINT\n";
#};

sub clear_errors {
  my $rc=$_[0]->errors;
  $_[0]->errors=[];
  return @{$rc};
}

sub _report_error {
  my $I=shift;
  my $eval=shift;
  my $x=join( ' ', 'ERROR', length $I->eprefix?$I->eprefix:() ).' ';
  if( length( $eval ) ) {
    if( $@=~/\bline \d+\b/ ) {
      my $nr=2;
      $eval=~s/\n/sprintf "\n%04d: ", $nr++/ge;
      $x.="while eval( \n0001: $eval\n): ";
    } else {
      $x.="while eval( $eval ): ";
    }
  } else {
    $x.=": ";
  }
  $x.=shift || $@;

  push @{$I->errors}, $x;
  die $x."\n" if( $I->onerror eq 'die' );
  return $x if( $I->onerror eq 'output' );
  return $I->onerror->( $x ) if( ref($I->onerror) eq 'CODE' );
  warn $x if( $I->onerror eq 'warn' );
  return '';
}

sub new {
  my $parent=shift;
  my $class=ref($parent) || $parent;
  my $I=bless {}=>$class;
  my %o=@_;

  if( ref($parent) ) {
    foreach my $m (@CLASS_MEMBERS) {
      $I->$m=$parent->$m;
    }
  } else {
    if( exists $ENV{HTML_TMPL_SEARCH_PATH} ) {
      my $sep=$Config{path_sep} || ':';
      $I->path=[split $sep, $ENV{HTML_TMPL_SEARCH_PATH}];
    }
  }
  $I->package=(caller)[0];
  $I->errors=[];
  foreach my $m (@CLASS_MEMBERS) {
    $I->$m=$o{$m} if( exists $o{$m} );
  }

  length $I->file and return $I->open;

  return $I;
}

sub open {
  my $I=shift;
  my %o=@_;

  $I->file=$o{file} if( exists $o{file} );
  $I->path=$o{path} if( exists $o{path} );
  local *F;
  local $/;
  if( -d $I->file ) {
    (exists($!{EISDIR}) and $!=&Errno::EISDIR) or
    (exists($!{EACCES}) and $!=&Errno::EACCES);
    return;
  }
  open F, '<'.$I->file or do {
    my $rc=0;
    unless( File::Spec->file_name_is_absolute( $I->file ) ) {
      foreach my $el (@{$I->path||[]}) {
	next unless( length $el );
	$el=~s!/*$!!;		# strip trailing slash if any
	my $f=File::Spec->catfile( $el, $I->file );
	if( -d $f ) {
	  (exists($!{EISDIR}) and $!=&Errno::EISDIR) or
	  (exists($!{EACCES}) and $!=&Errno::EACCES);
	  last;
	} elsif( open F, '<'.$f ) {
	  $rc=1;
	  last;
	}
      }
    }
    $rc;
  } or return;

  $I->template=<F>;
  close F;
  return unless( defined $I->template );
  return $I;
}

sub _param {
  my $name=shift;
  my $el=shift;

  foreach my $p (reverse @{$el->[2]}) {
    return $p->[1] if( ref $p eq 'ARRAY' and lc($p->[0]) eq $name );
  }
  return;
}

sub _fill_in {
  my $I=shift;
  my $v=shift;
  my $clist=shift;
  my $first=shift;
  my $last=shift;
  my $pre=shift;
  my $post=shift;
  my $gsm=shift;
  my $h=shift;

  my @list=@{$v};
  foreach my $e (@{$gsm}) {
    if( length( $e->[1] ) ) {
      if( $e->[0] eq 'grep' ) {
	my $x=('sub { package '.$I->package.';use strict;'.$e->[1].'}');
	$x=$I->__insert_ecache( $x, $e->[1], 1 );
	@list=grep( &$x, @list ) if( ref($x) eq 'CODE' );
      } elsif( $e->[0] eq 'map' ) {
	my $x=('sub { package '.$I->package.';use strict;'.$e->[1].'}');
	$x=$I->__insert_ecache( $x, $e->[1], 1 );
	@list=map( &$x, @list ) if( ref($x) eq 'CODE' );
      } elsif( $e->[0] eq 'sort' ) {
	my $x=('sub { use strict;'.$e->[1].'}');
	$x=$I->__insert_ecache( $x, $e->[1], 1 );
	@list=sort( $x @list ) if( ref($x) eq 'CODE' );
      }
    }
  }

  my @res;
  push @res, $I->_eval_list( undef, $h, @{$pre} ) if( @{$pre} );
  if( @list>=1 ) {
    push @res, $I->_eval_list( $list[0], $h, @{$first} );
  }
  if( @list ) {
    for( my $i=1; $i<@list-1; $i++ ) {
      push @res, $I->_eval_list( $list[$i], $h, @{$clist} );
    }
  } else {
    push @res, $I->_eval_list( undef, $h, @{$clist} );
  }
  if( @list>=2 ) {
    push @res, $I->_eval_list( $list[$#list], $h, @{$last} );
  }
  push @res, $I->_eval_list( undef, $h, @{$post} ) if( @{$post} );
  return \@res;
}

sub _eval_var {
  my $I=shift;
  my $el=shift;
  my $h=shift;

  local $_;
  my $type=_param( type=>$el );
  my $given=0;
  if( length $type ) {
    $type=lc $type;
    my $found=0;
    foreach my $t (split /\s*,\s*/, $type) {
      if( $t eq 'empty' ) {
	$found++ if( !exists $h->{$el->[1]} or
		     (ref( $h->{$el->[1]} ) eq 'ARRAY' and
		      @{$h->{$el->[1]}}==0) or
		     length( "$h->{$el->[1]}" )==0 );
      } elsif( $t eq 'given' ) {
	$found++ if( exists $h->{$el->[1]} and
		     ((ref( $h->{$el->[1]} ) eq 'ARRAY' and
		       @{$h->{$el->[1]}}>0) or
		      (ref( $h->{$el->[1]} ) ne 'ARRAY' and
		       length "$h->{$el->[1]}")) );
	$given++;
      } elsif( $t eq 'array' ) {
	$found++ if( exists $h->{$el->[1]} and
		     ref( $h->{$el->[1]} ) eq 'ARRAY' and
		     @{$h->{$el->[1]}}>0 );
      } elsif( $t eq 'scalar' ) {
	$found++ if( exists $h->{$el->[1]} and
		     ref( $h->{$el->[1]} ) ne 'ARRAY' and
		     length "$h->{$el->[1]}" );
      }
    }
    return '' unless( $found );
  }

  unless( defined $el->[3] ) {
    my $code=_param( code=>$el );
    if( length $code ) {
      $el->[3]=$code;
    } else {
      $el->[3]='<:/>';
    }
  }

  my (@clist, @first, @last, @pre, @post, @gsm); # gsm stands for grep/sort/map
  foreach my $p (@{$el->[2]}) {
    if( ref($p) eq 'ARRAY' ) {
      $p->[1]='' unless( defined $p->[1] );
      @first=$I->_parse_cached( $p->[1] ) if( lc($p->[0]) eq 'first' );
      @last=$I->_parse_cached( $p->[1] ) if( lc($p->[0]) eq 'last' );
      @pre=$I->_parse_cached( $p->[1] ) if( lc($p->[0]) eq 'pre' );
      @post=$I->_parse_cached( $p->[1] ) if( lc($p->[0]) eq 'post' );
      push @gsm, [lc($p->[0])=>$p->[1]]
	if( lc($p->[0]) eq 'grep' or
	    lc($p->[0]) eq 'map' or
	    lc($p->[0]) eq 'sort' );
    }
  }

  my @code;
  @clist=map {
    if( $_->[0] eq ':' ) {
      if( lc($_->[1]) eq 'first' ) {
	@first=$I->_parse_cached( defined $_->[3]?$_->[3]:'' );
	();
      } elsif( lc($_->[1]) eq 'last' ) {
	@last=$I->_parse_cached( defined $_->[3]?$_->[3]:'' );
	();
      } elsif( lc($_->[1]) eq 'pre' ) {
	@pre=$I->_parse_cached( defined $_->[3]?$_->[3]:'' );
	();
      } elsif( lc($_->[1]) eq 'post' ) {
	@post=$I->_parse_cached( defined $_->[3]?$_->[3]:'' );
	();
      } elsif( lc($_->[1]) eq 'code' ) {
	@code=$I->_parse_cached( defined $_->[3]?$_->[3]:'' );
	();
      } elsif( lc($_->[1]) eq 'grep' or
	       lc($_->[1]) eq 'sort' or
	       lc($_->[1]) eq 'map' ) {
	push @gsm, [lc($_->[1])=>(defined $_->[3]?$_->[3]:'')];
	();
      } else {
	$_;
      }
    } else {
      $_;
    }
  } $I->_parse_cached( defined $el->[3] ? $el->[3] : '' );

  @clist=@code if( @code );
  @first=@clist unless( @first );
  @last=@clist unless( @last );

  if( $given or ref($h->{$el->[1]}) ne 'ARRAY' ) {
    return $I->_eval_list( $h->{$el->[1]}, $h, @clist );
  } else {
    return $I->_fill_in( $h->{$el->[1]},
			 \@clist, \@first, \@last, \@pre, \@post, \@gsm,
			 $h );
  }
}

{ my %ecache;
  my %pcache;
  my $hwm=10000;
  my $lwm=5000;

  sub clear_cache {
    %ecache=();
    %pcache=();
  }

  sub cache_highwatermark :lvalue {
    $hwm=pop;
    $hwm;
  }

  sub cache_lowwatermark :lvalue {
    $lwm=pop;
    $lwm;
  }

  sub cache_sizes {
    (scalar keys %ecache, scalar keys %pcache);
  }

  sub __insert_ecache {
    my ($self, $x, $eval, $noerroroutput)=@_;

    if( $self->no_eval_cache ) {
      my $rc=eval $x;
      if( $@ ) {
	$rc=$self->_report_error( $eval );
	return if( $noerroroutput );
      }
      return $rc;
    } else {
      unless( defined $ecache{$x} ) {
	if( scalar keys %ecache >= $hwm ) {
	  local $_;
	  my @l=sort {$a->[1] <=> $b->[1]}
	    map {[$_, $ecache{$_}->[1]]}
	      keys %ecache;
	  delete @ecache{map {$_->[0]} @l[0 .. $hwm-$lwm-1]};
	}
	$ecache{$x}=[eval( $x ), 0];
	if( $@ ) {
	  my $rc=$self->_report_error( $eval );
	  return $noerroroutput ? undef : $rc;
	}
      }

      $ecache{$x}->[1]=time;
      return $ecache{$x}->[0];
    }
  }

  sub __eval_cached {
    my ($self, $eval, $v, $h, $noerroroutput)=@_;

    if( $self->no_eval_cache ) {
      my $p=$self->_extra;
      my $x=eval ('package '.$self->package.
		  ';use strict;local$_=[$v,$p,$h];do{'.$eval."\n}");
      if( $@ ) {
	$x=$self->_report_error( $eval );
	return if( $noerroroutput );
      }
      return $x;
    } else {
      my $x=('sub {package '.$self->package.';use strict;'.
	     'my ($v,$p,$h)=@_;local $_=\@_;do{'.$eval."\n}}");
      my $f=$self->__insert_ecache( $x, $eval, $noerroroutput );
      return $f unless( ref($f) eq 'CODE' );
      my $rc=eval {
	&{$f}( $v, $self->_extra, $h );
      };
      if( $@ ) {
	$rc=$self->_report_error( $eval );
	return if( $noerroroutput );
      }
      return $rc;
    }
    return;
  }

  sub _parse_cached {
    my ($I, $str)=@_;

    $str=$I->template unless( defined $str );

    if( $I->no_parse_cache ) {
      return $I->_parse( $str );
    } else {
      my $el=$pcache{$str};
      unless( defined $el ) {
	if( scalar keys %pcache >= $hwm ) {
	  local $_;
	  my @l=sort {$a->[1] <=> $b->[1]}
	    map {[$_, $pcache{$_}->[1]]}
	      keys %pcache;
	  delete @pcache{map {$_->[0]} @l[0 .. $hwm-$lwm-1]};
	}
	$el=$pcache{$str}=[0, $I->_parse( $str )];
      }

      $el->[0]=time;
      return @{$el}[1..$#{$el}];
    }
  }
}

sub _eval_v {
  my $I=shift;
  my $v=shift;
  my $el=shift;
  my $h=shift;

  my $eval;
  if( length $el->[3] ) {
    $eval=$el->[3];
  } elsif( @{$el->[2]} ) {
    $eval=substr( $el->[4], 2, -2 );
  } else {
    return $v;
  }

  $eval=~s/^\s+|\s+$//g;
  if( length $eval ) {
    #my $rc=$I->__eval_cached( $eval, $v, $h );
    #use Data::Dumper; warn "$el->[1]: ", Dumper( $rc );
    #return $rc;
    return $I->__eval_cached( $eval, $v, $h );
  }

  return '';
}

sub __get_code_list {
  my $I=shift;
  my $el=shift;
  local $_;

  my @l2;
  my @l1=grep {
    if( $_->[0] eq ':' and $_->[1]=~/^code$/i ) {
      push @l2, $I->_parse_cached( defined $_->[3] ? $_->[3] : '' );
    }
    !($_->[0] eq ':' and $_->[1]=~/^(set|code)$/i);
  } $I->_parse_cached( defined $el->[3] ? $el->[3] : '' );
  return @l2?@l2:@l1;
}

sub _eval_control {
  my $I=shift;
  my $v=shift;
  my $el=shift;
  my $h=shift;

  if( 0==length $el->[1] ) {	# <: code />
    #my $rc=$I->_eval_v( $v, $el, $h );
    #use Data::Dumper; warn "$el->[1]: ", Dumper( $rc );
    #return $rc;
    return $I->_eval_v( $v, $el, $h );
  } elsif( $el->[1] eq 'include' ) {
    my $file;
    foreach my $f (@{$el->[2]}) {
      if( !ref($f) and length($f) ) {
	$file=$I->_eval_list( $v, $h, $I->_parse_cached($f) );
	last;
      }
    }
    my $nh=+{$I->_make_include_param_list( $v, $el, $h )};
    my ($sv_file, $sv_eprefix, $sv_template)=
      ($I->file, $I->eprefix, $I->template); # save
    $I->file=$file;
    $I->eprefix=join( ' ', $I->eprefix, "While including $file" );
    defined($I->open) or do {
      ($I->file, $I->eprefix, $I->template)=
	($sv_file, $sv_eprefix, $sv_template); # restore
      return $I->_report_error( "<:include $file>", "$!" );
    };

    my $rc=eval {
      $I->_eval_list( $v, $nh, $I->_parse_cached( defined($I->template)
						  ? $I->template
						  : '' ) );
    };
    my $msg=$@;
    undef $@;

    ($I->file, $I->eprefix, $I->template)=
      ($sv_file, $sv_eprefix, $sv_template); # restore

    die $msg if( $msg );	# propagate

    return $rc;
  } elsif( $el->[1] eq 'for' ) {
    my $nh=+{$I->_make_include_param_list( $v, $el, $h )};
    #warn "FOR FOR FOR: ";
    #use Data::Dumper; warn Dumper($nh);
    return $I->_eval_list( $v, $nh, $I->__get_code_list($el) );
  } elsif( $el->[1] eq 'm' or $el->[1] eq 'macro' ) { # invoke macro
    my $macro;
    foreach my $f (@{$el->[2]}) {
      if( !ref($f) and length($f) ) {
	$macro=$I->_eval_list( $v, $h, $I->_parse_cached($f) );
	last;
      }
    }
    unless( exists $I->_macros->{$macro} ) {
      return $I->_report_error( "<:macro $macro>", "Macro not defined" );
    }
    $macro=$I->_macros->{$macro};
    my $nh=+{$I->_make_include_param_list( $v, $el, $h )};
    #warn "M M M: ";
    #use Data::Dumper; warn Dumper($nh);
    return $I->_eval_list( $v, $nh, @{$macro} );
  } elsif( $el->[1] eq 'eval' ) {
    my $nh=+{$I->_make_include_param_list( $v, $el, $h )};
    my $new_tmpl=$I->_eval_list( $v, $nh, $I->__get_code_list($el) );
    #warn "new_tmpl: $new_tmpl\n";
    #use Data::Dumper; warn Dumper($nh);
    return $I->_eval_list( $v, $h, $I->_parse_cached( defined $new_tmpl
						      ? $new_tmpl
						      : '' ) );
  } elsif( $el->[1] eq 'cond' ) {
    my $vdecl='';
    foreach my $x (@{$el->[2]}) {
      unless( ref($x) ) {
	$vdecl.=q{my $}.$x.q(=$_->[2]->{').$x.q('}; );
      }
    }
    foreach my $c ($I->_parse_cached( defined $el->[3] ? $el->[3] : '' )) {
      if( $c->[0] eq ':' and
	  ($c->[1] eq '' or $c->[1] eq 'case') ) {
	my $eval=$c->[5];
	$eval=~s/\\(.)|"/$1/g;              #";#
	$eval="$vdecl $eval";
	if( $I->__eval_cached( $eval, $v, $h, 1 ) ) {
	  return $I->_eval_list( $v, $h, $I->__get_code_list($c) )
	}
      }
    }
  } elsif( $el->[1] eq 'set' ) {
    my $name;
    foreach my $f (@{$el->[2]}) {
      next if( ref($f) );
      $name=$f;
      last;
    }
    my @l=$I->_make_one_param( $v, $el, $h, [$name=>$el->[3]] );
    $h->{$l[0]}=$l[1];
  } elsif( $el->[1] eq 'defmacro' ) { # define macro
    my $macro;
    foreach my $f (@{$el->[2]}) {
      if( !ref($f) and length($f) ) {
	$macro=$I->_eval_list( $v, $h, $I->_parse_cached($f) );
	last;
      }
    }
    $I->_macros->{$macro}=[$I->__get_code_list($el)];
  }
  return;
}

sub _make_one_param {
  my $I=shift;
  my $v=shift;
  my $el=shift;
  my $h=shift;
  my $p=shift;

  if( ref($p) eq 'ARRAY' ) {
    my @pp=$I->_parse_cached( $p->[1] );
    my $string='';
    my $pl=[];
    my $array=0;
    foreach my $ve (@pp) {
      if( !defined( $ve->[0] ) ) { # text element
	if( $array ) {
	  foreach my $s (@$pl) {
	    $s.=$ve->[4];
	  }
	} else {
	  $string.=$ve->[4];
	}
	next;
      }
      my $x;
      if( $ve->[0] eq ':' ) { # control element
	$x=$I->_eval_control( $v, $ve, $h );
	#use Data::Dumper; warn "_eval_control returns ", Dumper($x);
      } else {
	$x=$I->_eval_var( $ve, $h );
	#use Data::Dumper; warn "_eval_var returns ", Dumper($x);
      }
      if( ref($x) eq 'ARRAY' ) {
	if( $array ) {		# schon array mode ==> kreuzprodukt
	  my $npl;
	  foreach my $s (@$pl) {
	    foreach my $v (@{$x}) {
	      push @$npl, $s.$v;
	    }
	  }
	  $pl=$npl;
	} elsif( length( $string ) ) { # noch kein array mode aber $string
	  local $_;	       	       # nicht leer
	  $pl=[map {$string.$_} @$x];
	  undef $string;	# $string is useless in array mode
				# save a little memory
	} else {		# noch kein array mode und $string immer noch
	  $pl=$x;		# leer
	}
	$array=1;		# turn on array mode
      } else {
	if( $array ) {
	  foreach my $s (@$pl) {
	    $s.=$x;
	  }
	} else {
	  if( length $string ) {
	    $string.=$x;
	  } else {
	    $string=$x;
	  }
	}
      }
    }
    return ($I->_eval_list( $v, $h,
			    $I->_parse_cached(defined $p->[0] ? $p->[0] : '') )
	    =>($array ? $pl : $string));
  } else {
    if( $p eq ':inherit' or $p eq ':inheritparams' ) {
      return (%{$h});
    }
  }
  return;
}

sub _make_include_param_list {
  my $I=shift;
  my $v=shift;
  my $el=shift;
  my $h=shift;

  my @res;
  local $_;
  foreach my $p (@{$el->[2]}, map {
    if( $_->[0] eq ':' and $_->[1] eq 'set' ) {
      my $name;
      foreach my $f (@{$_->[2]}) {
	next if( ref($f) );
	$name=$f;
	last;
      }
      [$name, $_->[3]];
    } else {
      ();
    }
  } $I->_parse_cached( defined $el->[3] ? $el->[3] : '' )) {
    push @res, $I->_make_one_param( $v, $el, $h, $p );
  }

  return @res;
}

sub _eval_list {
  my $I=shift;
  my $v=shift;
  my $h=shift;

  my $res='';
  foreach my $el (@_) {
    if( !defined( $el->[0] ) ) { # text element
      $res.=$el->[4];
    } elsif( $el->[0] eq ':' ) { # control element
      $res.=$I->_eval_control( $v, $el, $h );
    } else {			# variable element
      my $el=$I->_eval_var( $el, $h );
      if( ref($el) eq 'ARRAY' ) {
	$res.=join('',@{$el});
      } else {
	$res.=$el;
      }
    }
  }
  return $res;
}

sub evaluate_as_config {
  my $I=shift;
  if( @_%2 ) {
    $I->_extra=shift;
  } else {
    $I->_extra={};
  }
  my $h=+{@_};

  my $res={};

  $I->_macros={} unless( defined $I->_macros );
  foreach my $el ($I->_parse_cached) {
    if( !defined( $el->[0] ) ) { # text element: skip
    } elsif( $el->[0] eq ':' ) { # control element: eval but ignore result
      $I->_eval_control( undef, $el, $h );
    } else {			# variable element
      $res->{$el->[1]}=$I->_eval_var( $el, $h );
    }
  }
  return $res;
}

sub evaluate {
  my $I=shift;
  if( @_%2 ) {
    $I->_extra=shift;
  } else {
    $I->_extra={};
  }
  my $h=+{@_};

  $I->_macros={} unless( defined $I->_macros );
  my $rc=$I->_eval_list( undef, $h, $I->_parse_cached );

  if( $I->compress=~/gz$/ ) {
    return Compress::Zlib::memGzip $rc;
  } else {
    return $rc;
  }
}

sub evaluate_to_file {
  my $I=shift;
  my $fh=shift;

  my $text;
  $text=$I->evaluate( @_ );

  if( UNIVERSAL::isa($fh, 'GLOB') ) {
    return print $fh $text;
  }
  if( UNIVERSAL::isa($fh, 'CODE') ) {
    return $fh->( $text );
  }
  if( ref($fh) and UNIVERSAL::can( $fh, 'print' ) ) {
    return $fh->print( $text );
  }

  if( $I->compress=~/gz$/ ) {
    my $ext=$I->compress;
    $fh=~s/\Q$ext\E$//;
    $fh.=$ext;
  }
  $fh=IO::File->new( $fh, 'w' ) or return;
  print $fh $text or return;
  return 1;
}

1;
