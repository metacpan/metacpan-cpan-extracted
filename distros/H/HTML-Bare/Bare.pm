#!/usr/bin/perl -w
package HTML::Bare;

use Carp;
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use utf8;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
$VERSION = "0.02";
use vars qw($VERSION *AUTOLOAD);

*AUTOLOAD = \&XML::Bare::AUTOLOAD;
bootstrap HTML::Bare $VERSION;

@EXPORT = qw( );
@EXPORT_OK = qw( xget merge clean add_node del_node find_node del_node forcearray del_by_perl htmlin xval find_by_id find_by_att nav );

=head1 NAME

HTML::Bare - Minimal HTML parser implemented via a C state engine

=head1 VERSION

0.02

=cut

sub new {
  my $class = shift; 
  my $self  = { @_ };
  
  $self->{'i'} = 0;
  if( $self->{ 'text' } ) {
    if( $self->{'unsafe'} ) {
        $self->{'parser'} = HTML::Bare::c_parse_unsafely( $self->{'text'} );
    }
    else {
        $self->{'parser'} = HTML::Bare::c_parse( $self->{'text'} );
    }
  }
  else {
    my $res = open( my $HTML, $self->{ 'file' } );
    if( !$res ) {
      $self->{ 'html' } = 0;
      return 0;
    }
    {
      local $/ = undef;
      $self->{'text'} = <$HTML>;
    }
    close( $HTML );
    $self->{'parser'} = HTML::Bare::c_parse( $self->{'text'} );
  }
  bless $self, "HTML::Bare::Object";
  return $self if( !wantarray );
  return ( $self, ( $self->{'simple'} ? $self->simple() : $self->parse() ) );
}

sub simple {
    return new( @_, simple => 1 );
}

package HTML::Bare::Object;

use Carp;
use strict;

# Stubs ( to allow these functions to be used via an object as well, not just via import or namespace )
sub find_by_perl { shift; return HTML::Bare::find_by_perl( @_ ); }
sub find_node { shift; return HTML::Bare::find_node( @_ ); }

sub DESTROY {
  my $self = shift;
  use Data::Dumper;
  #print Dumper( $self );
  undef $self->{'text'};
  undef $self->{'i'};
  $self->free_tree();
  undef $self->{'parser'};
}

sub read_more {
    my $self = shift;
    my %p = ( @_ );
    my $i = $self->{'i'}++;
    if( $p{'text'} ) {
        $self->{"text$i"} = $p{'text'};
        HTML::Bare::c_parse_more( $self->{"text$i"}, $self->{'parser'} );
    }
}

sub raw {
    my ( $self, $node ) = @_;
    my $i = $node->{'_i'};
    my $z = $node->{'_z'};
    #return HTML::Bare::c_raw( $self->{'parser'}, $i, $z );
    return substr( $self->{'text'}, $i - 1, $z - $i + 2 );
}

sub parse {
  my $self = shift;
  
  my $res = HTML::Bare::html2obj( $self->{'parser'} );
  
  if( defined( $self->{'scheme'} ) ) {
    $self->{'xbs'} = new HTML::Bare( %{ $self->{'scheme'} } );
  }
  if( defined( $self->{'xbs'} ) ) {
    my $xbs = $self->{'xbs'};
    my $ob = $xbs->parse();
    $self->{'xbso'} = $ob;
    readxbs( $ob );
  }
  
  #if( !ref( $res ) && $res < 0 ) { croak "Error at ".$self->lineinfo( -$res ); }
  $self->{ 'html' } = $res;
  
  if( defined( $self->{'xbso'} ) ) {
    my $ob = $self->{'xbso'};
    my $cres = $self->check( $res, $ob );
    croak( $cres ) if( $cres );
  }
  
  return $self->{ 'html' };
}

# html bare schema
sub check {
  my ( $self, $node, $scheme, $parent ) = @_;
  
  my $fail = '';
  if( ref( $scheme ) eq 'ARRAY' ) {
    for my $one ( @$scheme ) {
      my $res = $self->checkone( $node, $one, $parent );
      return 0 if( !$res );
      $fail .= "$res\n";
    }
  }
  else { return $self->checkone( $node, $scheme, $parent ); }
  return $fail;
}

sub checkone {
  my ( $self, $node, $scheme, $parent ) = @_;
  
  for my $key ( keys %$node ) {
    next if( substr( $key, 0, 1 ) eq '_' || $key eq '_att' || $key eq 'comment' );
    if( $key eq 'value' ) {
      my $val = $node->{ 'value' };
      my $regexp = $scheme->{'value'};
      if( $regexp ) {
        if( $val !~ m/^($regexp)$/ ) {   
          my $linfo = $self->lineinfo( $node->{'_i'} );
          return "Value of '$parent' node ($val) does not match /$regexp/ [$linfo]";
        }
      }
      next;
    }
    my $sub = $node->{ $key };
    my $ssub = $scheme->{ $key };
    if( !$ssub ) { #&& ref( $schemesub ) ne 'HASH'
      my $linfo = $self->lineinfo( $sub->{'_i'} );
      return "Invalid node '$key' in html [$linfo]";
    }
    if( ref( $sub ) eq 'HASH' ) {
      my $res = $self->check( $sub, $ssub, $key );
      return $res if( $res );
    }
    if( ref( $sub ) eq 'ARRAY' ) {
      my $asub = $ssub;
      if( ref( $asub ) eq 'ARRAY' ) {
        $asub = $asub->[0];
      }
      if( $asub->{'_t'} ) {
        my $max = $asub->{'_max'} || 0;
        if( $#$sub >= $max ) {
          my $linfo = $self->lineinfo( $sub->[0]->{'_i'} );
          return "Too many nodes of type '$key'; max $max; [$linfo]"
        }
        my $min = $asub->{'_min'} || 0;
        if( ($#$sub+1)<$min ) {
          my $linfo = $self->lineinfo( $sub->[0]->{'_i'} );
          return "Not enough nodes of type '$key'; min $min [$linfo]"
        }
      }
      for( @$sub ) {
        my $res = $self->check( $_, $ssub, $key );
        return $res if( $res );
      }
    }
  }
  if( my $dem = $scheme->{'_demand'} ) {
    for my $req ( @{$scheme->{'_demand'}} ) {
      my $ck = $node->{ $req };
      if( !$ck ) {
        my $linfo = $self->lineinfo( $node->{'_i'} );
        return "Required node '$req' does not exist [$linfo]"
      }
      if( ref( $ck ) eq 'ARRAY' ) {
        my $linfo = $self->lineinfo( $node->{'_i'} );
        return "Required node '$req' is empty array [$linfo]" if( $#$ck == -1 );
      }
    }
  }
  return 0;
}

sub simple {
  my $self = shift;
  
  my $res = HTML::Bare::html2obj_simple( $self->{'parser'} );#$self->html2obj();
  
  if( !ref( $res ) && $res < 0 ) { croak "Error at ".$self->lineinfo( -$res ); }
  $self->{ 'html' } = $res;
  
  return $res;
}

sub add_node {
  my ( $self, $node, $name ) = @_;
  my @newar;
  my %blank;
  $node->{ 'multi_'.$name } = \%blank if( ! $node->{ 'multi_'.$name } );
  $node->{ $name } = \@newar if( ! $node->{ $name } );
  my $newnode = new_node( 0, splice( @_, 3 ) );
  push( @{ $node->{ $name } }, $newnode );
  return $newnode;
}

sub add_node_after {
  my ( $self, $node, $prev, $name ) = @_;
  my @newar;
  my %blank;
  $node->{ 'multi_'.$name } = \%blank if( ! $node->{ 'multi_'.$name } );
  $node->{ $name } = \@newar if( ! $node->{ $name } );
  my $newnode = $self->new_node( splice( @_, 4 ) );
  
  my $cur = 0;
  for my $anode ( @{ $node->{ $name } } ) {
    $anode->{'_pos'} = $cur if( !$anode->{'_pos'} );
    $cur++;
  }
  my $opos = $prev->{'_pos'};
  for my $anode ( @{ $node->{ $name } } ) {
    $anode->{'_pos'}++ if( $anode->{'_pos'} > $opos );
  }
  $newnode->{'_pos'} = $opos + 1;
  
  push( @{ $node->{ $name } }, $newnode );
  
  return $newnode;
}

sub del_node {
  my $self = shift;
  my $node = shift;
  my $name = shift;
  my %match = @_;
  $node = $node->{ $name };
  return if( !$node );
  for( my $i = 0; $i <= $#$node; $i++ ) {
    my $one = $node->[ $i ];
    foreach my $key ( keys %match ) {
      my $val = $match{ $key };
      if( $one->{ $key }->{'value'} eq $val ) {
        delete $node->[ $i ];
      }
    }
  }
}

# Created a node of HTML hash with the passed in variables already set
sub new_node {
  my $self  = shift;
  my %parts = @_;
  
  my %newnode;
  foreach( keys %parts ) {
    my $val = $parts{$_};
    if( m/^_/ || ref( $val ) eq 'HASH' ) {
      $newnode{ $_ } = $val;
    }
    else {
      $newnode{ $_ } = { value => $val };
    }
  }
  
  return \%newnode;
}

sub simplify {
    my $node = CORE::shift;
    my $ref = ref( $node );
    if( $ref eq 'ARRAY' ) {
        my @ret;
        for my $sub ( @$node ) {
            CORE::push( @ret, simplify( $sub ) );
        }
        return \@ret;
    }
    if( $ref eq 'HASH' ) {
        my %ret;
        my $cnt = 0;
        for my $key ( keys %$node ) {
            next if( $key eq 'comment' || $key eq 'value' || $key =~ m/^_/ );
            $cnt++;
            $ret{ $key } = simplify( $node->{ $key } );
        }
        if( $cnt == 0 ) {
            return $node->{'value'};
        }
        return \%ret;
    }
    return $node;
}

sub hash2html {
    my ( $node, $name ) = @_;
    my $ref = ref( $node );
    return '' if( $name && $name =~ m/^\_/ );
    my $txt = $name ? "<$name>" : '';
    if( $ref eq 'ARRAY' ) {
       $txt = '';
       for my $sub ( @$node ) {
           $txt .= hash2html( $sub, $name );
       }
       return $txt;
    }
    elsif( $ref eq 'HASH' ) {
       for my $key ( keys %$node ) {
           $txt .= hash2html( $node->{ $key }, $key );
       }
    }
    else {
        $node ||= '';
        if( $node =~ /[<]/ ) { $txt .= '<![CDATA[' . $node . ']]>'; }
        else { $txt .= $node; }
    }
    if( $name ) {
        $txt .= "</$name>";
    }
        
    return $txt;
}

# Save an HTML hash tree into a file
sub save {
  my $self = shift;
  return if( ! $self->{ 'html' } );
  
  my $html = $self->html( $self->{'html'} );
  
  my $len;
  {
    use bytes;  
    $len = length( $html );
  }
  return if( !$len );
  
  # This is intentionally just :utf8 and not :encoding(UTF-8)
  # :encoding(UTF-8) checks the data for actually being valid UTF-8, and doing so would slow down the file write
  # See http://perldoc.perl.org/functions/binmode.html
  
  my $os = $^O;
  my $F;
  
  # Note on the following conditional OS check... WTF? This is total bullshit.
  if( $os eq 'MSWin32' ) {
      open( $F, '>:utf8', $self->{ 'file' } );
      binmode $F;
  }
  else {
      open( $F, '>', $self->{ 'file' } );
      binmode $F, ':utf8';
  }
  print $F $html;
  
  seek( $F, 0, 2 );
  my $cursize = tell( $F );
  if( $cursize != $len ) { # concurrency; we are writing a smaller file
    warn "Truncating File $self->{'file'}";
    `cp $self->{'file'} $self->{'file'}.bad`;
    truncate( F, $len );
  }
  seek( $F, 0, 2 );
  $cursize = tell( $F );
  if( $cursize != $len ) { # still not the right size even after truncate??
    die "Write problem; $cursize != $len";
  }
  close $F;
}

sub html {
  my ( $self, $obj, $name ) = @_;
  if( !$name ) {
    my %hash;
    $hash{0} = $obj;
    return HTML::Bare::obj2html( \%hash, '', 0 );
  }
  my %hash;
  $hash{$name} = $obj;
  return HTML::Bare::obj2html( \%hash, '', 0 );
}

sub htmlcol {
  my ( $self, $obj, $name ) = @_;
  my $pre = '';
  if( $self->{'style'} ) {
    $pre = "<style type='text/css'>\@import '$self->{'style'}';</style>";
  }
  if( !$name ) {
    my %hash;
    $hash{0} = $obj;
    return $pre.obj2htmlcol( \%hash, '', 0 );
  }
  my %hash;
  $hash{$name} = $obj;
  return $pre.obj2htmlcol( \%hash, '', 0 );
}

sub lineinfo {
  my $self = shift;
  my $res  = shift;
  my $line = 1;
  my $j = 0;
  for( my $i=0;$i<$res;$i++ ) {
    my $let = substr( $self->{'text'}, $i, 1 );
    if( ord($let) == 10 ) {
      $line++;
      $j = $i;
    }
  }
  my $part = substr( $self->{'text'}, $res, 10 );
  $part =~ s/\n//g;
  $res -= $j;
  if( $self->{'offset'} ) {
    my $off = $self->{'offset'};
    $line += $off;
    return "$off line $line char $res \"$part\"";
  }
  return "line $line char $res \"$part\"";
}

sub free_tree { my $self = shift; HTML::Bare::free_tree_c( $self->{'parser'} ); }

package HTML::Bare;

sub find_node {
  my $node = shift;
  my $name = shift;
  my %match = @_;
  return 0 if( ! defined $node );
  $node = $node->{ $name } or return 0;
  $node = [ $node ] if( ref( $node ) eq 'HASH' );
  if( ref( $node ) eq 'ARRAY' ) {
    for( my $i = 0; $i <= $#$node; $i++ ) {
      my $one = $node->[ $i ];
      for my $key ( keys %match ) {
        my $val = $match{ $key };
        croak('undefined value in find') unless defined $val;
        if( $one->{ $key }{'value'} eq $val ) {
          return $node->[ $i ];
        }
      }
    }
  }
  return 0;
}

sub xget {
  my $hash = shift;
  return map $_->{'value'}, @{$hash}{@_};
}

sub forcearray {
  my $ref = shift;
  return [] if( !$ref );
  return $ref if( ref( $ref ) eq 'ARRAY' );
  return [ $ref ];
}

sub merge {
  # shift in the two array references as well as the field to merge on
  my ( $a, $b, $id ) = @_;
  my %hash = map { $_->{ $id } ? ( $_->{ $id }->{ 'value' } => $_ ) : ( 0 => 0 ) } @$a;
  for my $one ( @$b ) {
    next if( !$one->{ $id } );
    my $short = $hash{ $one->{ $id }->{ 'value' } };
    next if( !$short );
    foreach my $key ( keys %$one ) {
      next if( $key eq '_pos' || $key eq 'id' );
      my $cur = $short->{ $key };
      my $add = $one->{ $key };
      if( !$cur ) { $short->{ $key } = $add; }
      else {
        my $type = ref( $cur );
        if( $type eq 'HASH' ) {
          my @arr;
          $short->{ $key } = \@arr;
          push( @arr, $cur );
        }
        if( ref( $add ) eq 'HASH' ) {
          push( @{$short->{ $key }}, $add );
        }
        else { # we are merging an array
          push( @{$short->{ $key }}, @$add );
        }
      }
      # we need to deal with the case where this node
      # is already there, either alone or as an array
    }
  }
  return $a;  
}

sub clean {
  my $ob = new HTML::Bare( @_ );
  my $root = $ob->parse();
  if( $ob->{'save'} ) {
    $ob->{'file'} = $ob->{'save'} if( "$ob->{'save'}" ne "1" );
    $ob->save();
    return;
  }
  return $ob->html( $root );
}

sub htmlin {
  my $text = shift;
  my %ops = ( @_ );
  my $ob = new HTML::Bare( text => $text );
  my $simple = $ob->simple();
  if( !$ops{'keeproot'} ) {
    my @keys = keys %$simple;
    my $first = $keys[0];
    $simple = $simple->{ $first } if( $first );
  }
  return $simple;
}

sub tohtml {
  my %ops = ( @_ );
  my $ob = new HTML::Bare( %ops );
  return $ob->html( $ob->parse(), $ops{'root'} || 'html' );
}

sub readxbs { # xbs = html bare schema
  my $node = shift;
  my @demand;
  for my $key ( keys %$node ) {
    next if( substr( $key, 0, 1 ) eq '_' || $key eq '_att' || $key eq 'comment' );
    if( $key eq 'value' ) {
      my $val = $node->{'value'};
      delete $node->{'value'} if( $val =~ m/^\W*$/ );
      next;
    }
    my $sub = $node->{ $key };
    
    if( $key =~ m/([a-z_]+)([^a-z_]+)/ ) {
      my $name = $1;
      my $t = $2;
      my $min;
      my $max;
      if( $t eq '+' ) {
        $min = 1;
        $max = 1000;
      }
      elsif( $t eq '*' ) {
        $min = 0;
        $max = 1000;
      }
      elsif( $t eq '?' ) {
        $min = 0;
        $max = 1;
      }
      elsif( $t eq '@' ) {
        $name = 'multi_'.$name;
        $min = 1;
        $max = 1;
      }
      elsif( $t =~ m/\{([0-9]+),([0-9]+)\}/ ) {
        $min = $1;
        $max = $2;
        $t = 'r'; # range
      }
      
      if( ref( $sub ) eq 'HASH' ) {
        my $res = readxbs( $sub );
        $sub->{'_t'} = $t;
        $sub->{'_min'} = $min;
        $sub->{'_max'} = $max;
      }
      if( ref( $sub ) eq 'ARRAY' ) {
        for my $item ( @$sub ) {
          my $res = readxbs( $item );
          $item->{'_t'} = $t;
          $item->{'_min'} = $min;
          $item->{'_max'} = $max;
        }
      }
      
      push( @demand, $name ) if( $min );
      $node->{$name} = $node->{$key};
      delete $node->{$key};
    }
    else {
      if( ref( $sub ) eq 'HASH' ) {
        readxbs( $sub );
        $sub->{'_t'} = 'r';
        $sub->{'_min'} = 1;
        $sub->{'_max'} = 1;
      }
      if( ref( $sub ) eq 'ARRAY' ) {
        for my $item ( @$sub ) {
          readxbs( $item );
          $item->{'_t'} = 'r';
          $item->{'_min'} = 1;
          $item->{'_max'} = 1;
        }
      }
      
      push( @demand, $key );
    }
  }
  if( @demand ) { $node->{'_demand'} = \@demand; }
}

sub find_by_perl {
  my $arr = shift;
  my $cond = shift;
  
  my @res;
  if( ref( $arr ) eq 'ARRAY' ) {
      $cond =~ s/-([a-z_]+)/\$ob->\{'$1'\}->\{'value'\}/gi;
      foreach my $ob ( @$arr ) { push( @res, $ob ) if( eval( $cond ) ); }
  }
  else {
      $cond =~ s/-([a-z_]+)/\$arr->\{'$1'\}->\{'value'\}/gi;
      push( @res, $arr ) if( eval( $cond ) );
  }
  return \@res;
}

sub del_by_perl {
  my $arr = shift;
  my $cond = shift;
  $cond =~ s/-value/\$ob->\{'value'\}/g;
  $cond =~ s/-([a-z]+)/\$ob->\{'$1'\}->\{'value'\}/g;
  my @res;
  for( my $i = 0; $i <= $#$arr; $i++ ) {
    my $ob = $arr->[ $i ];
    delete $arr->[ $i ] if( eval( $cond ) );
  }
  return \@res;
}

sub newhash { shift; return { value => shift }; }

sub xval {
  return $_[0] ? $_[0]->{'value'} : ( $_[1] || '' );
}

sub obj2html {
  my ( $objs, $name, $pad, $level, $pdex ) = @_;
  $level  = 0  if( !$level );
  $pad    = '' if(  $level <= 2 );
  my $html = '';
  my $att = '';
  my $imm = 1;
  return '' if( !$objs );
  #return $objs->{'_raw'} if( $objs->{'_raw'} );
  my @dex = sort { 
    my $oba = $objs->{ $a };
    my $obb = $objs->{ $b };
    my $posa = 0;
    my $posb = 0;
    $oba = $oba->[0] if( ref( $oba ) eq 'ARRAY' );
    $obb = $obb->[0] if( ref( $obb ) eq 'ARRAY' );
    if( ref( $oba ) eq 'HASH' ) { $posa = $oba->{'_pos'} || 0; }
    if( ref( $obb ) eq 'HASH' ) { $posb = $obb->{'_pos'} || 0; }
    return $posa <=> $posb;
  } keys %$objs;
  for my $i ( @dex ) {
    my $obj  = $objs->{ $i } || '';
    my $type = ref( $obj );
    if( $type eq 'ARRAY' ) {
      $imm = 0;
      
      my @dex2 = sort { 
        if( !$a ) { return 0; }
        if( !$b ) { return 0; }
        if( ref( $a ) eq 'HASH' && ref( $b ) eq 'HASH' ) {
          my $posa = $a->{'_pos'};
          my $posb = $b->{'_pos'};
          if( !$posa ) { $posa = 0; }
          if( !$posb ) { $posb = 0; }
          return $posa <=> $posb;
        }
        return 0;
      } @$obj;
      
      for my $j ( @dex2 ) {
        $html .= obj2html( $j, $i, $pad.'  ', $level+1, $#dex );
      }
    }
    elsif( $type eq 'HASH' && $i !~ /^_/ ) {
      if( $obj->{ '_att' } ) {
        my $val = $obj->{'value'} || '';
        $att .= ' ' . $i . '="' . $val . '"' if( $i !~ /^_/ );;
      }
      else {
        $imm = 0;
        $html .= obj2html( $obj , $i, $pad.'  ', $level+1, $#dex );
      }
    }
    else {
      if( $i eq 'comment' ) { $html .= '<!--' . $obj . '-->' . "\n"; }
      elsif( $i eq 'value' ) {
        if( $level > 1 ) { # $#dex < 4 && 
          if( $obj && $obj =~ /[<>&;]/ ) { $html .= '<![CDATA[' . $obj . ']]>'; }
          else { $html .= $obj if( $obj =~ /\S/ ); }
        }
      }
      elsif( $i =~ /^_/ ) {}
      else { $html .= '<' . $i . '>' . $obj . '</' . $i . '>'; }
    }
  }
  my $pad2 = $imm ? '' : $pad;
  my $cr = $imm ? '' : "\n";
  if( substr( $name, 0, 1 ) ne '_' ) {
    if( $name ) {
      if( $html ) {
        $html = $pad . '<' . $name . $att . '>' . $cr . $html . $pad2 . '</' . $name . '>';
      }
      else {
        $html = $pad . '<' . $name . $att . ' />';
      }
    }
    return $html."\n" if( $level > 1 );
    return $html;
  }
  return '';
}

sub obj2htmlcol {
  my ( $objs, $name, $pad, $level, $pdex ) = @_;
    
  my $less = "<span class='ang'>&lt;</span>";
  my $more = "<span class='ang'>></span>";
  my $tn0 = "<span class='tname'>";
  my $tn1 = "</span>";
  my $eq0 = "<span class='eq'>";
  my $eq1 = "</span>";
  my $qo0 = "<span class='qo'>";
  my $qo1 = "</span>";
  my $sp0 = "<span class='sp'>";
  my $sp1 = "</span>";
  my $cd0 = "";
  my $cd1 = "";
  
  $level = 0 if( !$level );
  $pad = '' if( $level == 1 );
  my $html  = '';
  my $att  = '';
  my $imm  = 1;
  return '' if( !$objs );
  my @dex = sort { 
    my $oba = $objs->{ $a };
    my $obb = $objs->{ $b };
    my $posa = 0;
    my $posb = 0;
    $oba = $oba->[0] if( ref( $oba ) eq 'ARRAY' );
    $obb = $obb->[0] if( ref( $obb ) eq 'ARRAY' );
    if( ref( $oba ) eq 'HASH' ) { $posa = $oba->{'_pos'} || 0; }
    if( ref( $obb ) eq 'HASH' ) { $posb = $obb->{'_pos'} || 0; }
    return $posa <=> $posb;
  } keys %$objs;
  
  if( $objs->{'_cdata'} ) {
    my $val = $objs->{'value'};
    $val =~ s/^(\s*\n)+//;
    $val =~ s/\s+$//;
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $objs->{'value'} = $val;
    #$html = "$less![CDATA[<div class='node'><div class='cdata'>$val</div></div>]]$more";
    $cd0 = "$less![CDATA[<div class='node'><div class='cdata'>";
    $cd1 = "</div></div>]]$more";
  }
  for my $i ( @dex ) {
    my $obj  = $objs->{ $i } || '';
    my $type = ref( $obj );
    if( $type eq 'ARRAY' ) {
      $imm = 0;
      
      my @dex2 = sort { 
        if( !$a ) { return 0; }
        if( !$b ) { return 0; }
        if( ref( $a ) eq 'HASH' && ref( $b ) eq 'HASH' ) {
          my $posa = $a->{'_pos'};
          my $posb = $b->{'_pos'};
          if( !$posa ) { $posa = 0; }
          if( !$posb ) { $posb = 0; }
          return $posa <=> $posb;
        }
        return 0;
      } @$obj;
      
      for my $j ( @dex2 ) { $html .= obj2html( $j, $i, $pad.'&nbsp;&nbsp;', $level+1, $#dex ); }
    }
    elsif( $type eq 'HASH' && $i !~ /^_/ ) {
      if( $obj->{ '_att' } ) {
        my $val = $obj->{ 'value' };
        $val =~ s/</&lt;/g;
        if( $val eq '' ) {
          $att .= " <span class='aname'>$i</span>" if( $i !~ /^_/ );
        }
        else {
          $att .= " <span class='aname'>$i</span>$eq0=$eq1$qo0\"$qo1$val$qo0\"$qo1" if( $i !~ /^_/ );
        }
      }
      else {
        $imm = 0;
        $html .= obj2html( $obj , $i, $pad.'&nbsp;&nbsp;', $level+1, $#dex );
      }
    }
    else {
      if( $i eq 'comment' ) { $html .= "$less!--" . $obj . "--$more" . "<br>\n"; }
      elsif( $i eq 'value' ) {
        if( $level > 1 ) {
          if( $obj && $obj =~ /[<>&;]/ && ! $objs->{'_cdata'} ) { $html .= "$less![CDATA[$obj]]$more"; }
          else { $html .= $obj if( $obj =~ /\S/ ); }
        }
      }
      elsif( $i =~ /^_/ ) {}
      else { $html .= "$less$tn0$i$tn1$more$obj$less/$tn0$i$tn1$more"; }
    }
  }
  my $pad2 = $imm ? '' : $pad;
  if( substr( $name, 0, 1 ) ne '_' ) {
    if( $name ) {
      if( $imm ) {
        if( $html =~ /\S/ ) {
          $html = "$sp0$pad$sp1$less$tn0$name$tn1$att$more$cd0$html$cd1$less/$tn0$name$tn1$more";
        }
        else {
          $html = "$sp0$pad$sp1$less$tn0$name$tn1$att/$more";
        }
      }
      else {
        if( $html =~ /\S/ ) {
          $html = "$sp0$pad$sp1$less$tn0$name$tn1$att$more<div class='node'>$html</div>$sp0$pad$sp1$less/$tn0$name$tn1$more";
        }
        else { $html = "$sp0$pad$sp1$less$tn0$name$tn1$att/$more"; }
      }
    }
    $html .= "<br>" if( $objs->{'_br'} );
    if( $objs->{'_note'} ) {
      $html .= "<br>";
      my $note = $objs->{'_note'}{'value'};
      my @notes = split( /\|/, $note );
      for( @notes ) {
        $html .= "<div class='note'>$sp0$pad$sp1<span class='com'>&lt;!--</span> $_ <span class='com'>--></span></div>";
      }
    }
    return $html."<br>\n" if( $level );
    return $html;
  }
  return '';
}

# a.b.c@att=10
# a.b.@att=10
# a.b.@value=10 ( value of node )
# a.*.c
sub nav {
    my ( $node, $navtext ) = @_;
    my @parts = split( /\./, $navtext );
    my $curnodes;
    
    if( ref( $node ) eq 'HASH' ) {
        $curnodes = [ $node ];
    }
    else {
        $curnodes = $node;
    }
    my $nextnodes = [];
    
    # make sure we haven't passed in references to arrays of nodes
    my $fix = 0;
    for my $curnode ( @$curnodes ) {
        if( ref( $curnode ) eq 'ARRAY' ) {
            $fix = 1;
            last;
        }
    }
    if( $fix ) {
        for my $curnode ( @$curnodes ) {
            if( ref( $curnode ) eq 'ARRAY' ) {
                push( @$nextnodes, @$curnode );
            }
            else {
                push( @$nextnodes, $curnode );
            }
        }
        $curnodes = $nextnodes;
        $nextnodes = [];
    }
    
    for my $part ( @parts ) {
        #print Dumper( $curnodes );
        if( $part =~ m/^([a-zA-Z]*)\@([a-zA-Z]+)=(.+)/ ) {
            my $subname = $1;
            my $att = $2;
            my $val = $3;
            if( $subname ) {
                # first collect named nodes
                if( scalar @$curnodes == 1 ) {
                    $curnodes = forcearray( $curnodes->[0]{ $subname } );
                }
                else {
                    for my $curnode ( @$curnodes ) {
                        my $morenodes = forcearray( $curnode->{ $subname } );
                        push( @$nextnodes, @$morenodes )
                    }
                    $curnodes = $nextnodes;
                    $nextnodes = [];
                }
                # then ditch the ones that don't have the matching attribute ( done automatically by the below code outside of if )
            }
            else {
                # collect -all- subnodes, regardless of name ( note this methodology is not terribly efficient )
                for my $curnode ( @$curnodes ) {
                    # note curnode will never be an array at this point
                    for my $key ( keys %$curnode ) {
                        next if( $key =~ m/^_/ );
                        next if( $key eq 'value' );
                        my $morenodes = forcearray( $curnode->{ $key } );
                        push( @$nextnodes, @$morenodes );
                    }
                }
            }
            
            # go through all subnodes, finding the ones that have the matching attribute
            if( $att eq 'value' ) {
                for my $curnode ( @$curnodes ) {
                    push( @$nextnodes, $curnode ) if( $curnode->{'value'} eq $val );
                }
            }
            else {
                for my $curnode ( @$curnodes ) {
                    push( @$nextnodes, $curnode ) if( $curnode->{ $att }{'value'} eq $val );
                }
            }
        }
        elsif( $part eq '*' ) {
            for my $curnode ( @$curnodes ) {
                # note curnode will never be an array at this point
                for my $key ( keys %$curnode ) {
                    next if( $key =~ m/^_/ );
                    next if( $key eq 'value' );
                    my $morenodes = forcearray( $curnode->{ $key } );
                    push( @$nextnodes, @$morenodes );
                }
            }
        }
        else {
            if( scalar @$curnodes == 1 ) {
                $nextnodes = forcearray( $curnodes->[0]{ $part } );
                #print Dumper( $curnodes );
            }
            else {
                for my $curnode ( @$curnodes ) {
                    my $morenodes = forcearray( $curnode->{ $part } );
                    push( @$nextnodes, @$morenodes )
                }
            }
        }
        $curnodes = $nextnodes;
        $nextnodes = [];
        last if( ! scalar @$curnodes );
    }
    return $curnodes;
}

sub find_by_tagname {
    my ( $node, $tagname ) = @_;
    my @nodes;
    find_by_tagnamer( $node, \@nodes, $tagname );
    return \@nodes;
}
sub find_by_tagnamer {
    my ( $node, $res, $tagname ) = @_;
    if( ref( $node ) eq 'HASH' ) {
        return if( $node->{'_att'} );
        for my $name ( %$node ) {
            next if( $name =~ m/^_/ );
            next if( $name eq 'value' );
            if( $name eq $tagname ) {
                push( @$res, $node );
            }
            find_by_tagnamer( $node->{$name}, $res, $tagname );
        }
    }
    if( ref( $node ) eq 'ARRAY' ) {
        for my $item ( @$node ) {
            find_by_tagnamer( $item, $res, $tagname );
        }
    }
}

sub find_by_id {
    my ( $node, $id ) = @_;
    my @nodes;
    find_by_idr( $node, \@nodes, $id );
    return \@nodes;
}
sub find_by_idr {
    my ( $node, $res, $id ) = @_;
    if( ref( $node ) eq 'HASH' ) {
        return if( $node->{'_att'} );
        if( $node->{'id'} && $node->{'id'}{'value'} eq $id ) {
            push( @$res, $node );
        }
        for my $name ( %$node ) {
            next if( $name =~ m/^_/ );
            next if( $name eq 'value' );
            find_by_idr( $node->{$name}, $res, $id );
        }
    }
    if( ref( $node ) eq 'ARRAY' ) {
        for my $item ( @$node ) {
            find_by_idr( $item, $res, $id );
        }
    }
}

sub find_by_att {
    my ( $node, $att, $val ) = @_;
    my @nodes;
    find_by_attr( $node, \@nodes, $att, $val );
    return \@nodes;
}
sub find_by_attr {
    my ( $node, $res, $att, $val ) = @_;
    if( ref( $node ) eq 'HASH' ) {
        return if( $node->{'_att'} );
        if( $node->{$att} && $node->{$att}{'value'} eq $val ) {
            push( @$res, $node );
        }
        for my $name ( %$node ) {
            next if( $name =~ m/^_/ );
            next if( $name eq 'value' );
            find_by_attr( $node->{$name}, $res, $att, $val );
        }
    }
    if( ref( $node ) eq 'ARRAY' ) {
        for my $item ( @$node ) {
            find_by_attr( $item, $res, $att, $val );
        }
    }
}

1;

__END__

=head1 SYNOPSIS

  use HTML::Bare;
  
  my $ob = new HTML::Bare( text => '<html><name>Bob</name></html>' );
  
  # Parse the html into a hash tree
  my $root = $ob->parse();
  
  # Print the content of the name node
  print $root->{html}->{name}->{value};
  
  ---
  
  # Load html from a file ( assume same contents as first example )
  my $ob2 = new HTML::Bare( file => 'test.html' );
  
  my $root2 = $ob2->parse();
  
  $root2->{html}->{name}->{value} = 'Tim';
  
  # Save the changes back to the file
  $ob2->save();
  
  ---
  
  # Load html and verify against XBS ( HTML Bare Schema )
  my $html_text = '<html><item name=bob/></html>''
  my $schema_text = '<html><item* name=[a-z]+></item*></html>'
  my $ob = new HTML::Bare( text => $html_text, schema => { text => $schema_text } );
  $ob->parse(); # this will error out if schema is invalid

=head1 DESCRIPTION

This module is a 'Bare' HTML parser. It is implemented in C. The parser
itself is a simple state engine that is less than 500 lines of C. The
parser builds a C struct tree from input text. That C struct tree is
converted to a Perl hash by a Perl function that makes basic calls back
to the C to go through the nodes sequentially.

The parser itself will only cease parsing if it encounters tags that
are not closed properly. All other inputs will parse, even invalid
inputs. To allowing checking for validity, a schema checker is included
in the module as well.

The schema format is custom and is meant to be as simple as possible.
It is based loosely around the way multiplicity is handled in Perl
regular expressions.

=head2 Supported HTML

To demonstrate what sort of HTML is supported, consider the following
examples. Each of the PERL statements evaluates to true.

=over 2

=item * Node containing just text

  HTML: <html>blah</html>
  PERL: $root->{html}->{value} eq "blah";

=item * Subset nodes

  HTML: <html><name>Bob</name></html>
  PERL: $root->{html}->{name}->{value} eq "Bob";

=item * Attributes unquoted

  HTML: <html><a href=index.htm>Link</a></html>
  PERL: $root->{html}->{a}->{href}->{value} eq "index.htm";

=item * Attributes quoted

  HTML: <html><a href="index.htm">Link</a></html>
  PERL: $root->{html}->{a}->{href}->{value} eq "index.htm";

=item * CDATA nodes

  HTML: <html><raw><![CDATA[some raw $~<!bad html<>]]></raw></html>
  PERL: $root->{html}->{raw}->{value} eq "some raw \$~<!bad html<>";

=item * Multiple nodes; form array

  HTML: <html><item>1</item><item>2</item></html>
  PERL: $root->{html}->{item}->[0]->{value} eq "1";

=item * Forcing array creation

  HTML: <html><multi_item/><item>1</item></html>
  PERL: $root->{html}->{item}->[0]->{value} eq "1";

=item * One comment supported per node

  HTML: <html><!--test--></html>
  PERL: $root->{html}->{comment} eq 'test';

=back

=head2 Schema Checking

Schema checking is done by providing the module with an XBS (HTML::Bare Schema) to check
the HTML against. If the HTML checks as valid against the schema, parsing will continue as
normal. If the HTML is invalid, the parse function will die, providing information about
the failure.

The following information is provided in the error message:

=over 2

=item * The type of error

=item * Where the error occured ( line and char )

=item * A short snippet of the HTML at the point of failure

=back

=head2 XBS ( HTML::Bare Schema ) Format

=over 2

=item * Required nodes

  HTML: <html></html>
  XBS: <html/>

=item * Optional nodes - allow one

  HTML: <html></html>
  XBS: <html item?/>
  or XBS: <html><item?/></html>

=item * Optional nodes - allow 0 or more

  HTML: <html><item/></html>
  XBS: <html item*/>

=item * Required nodes - allow 1 or more

  HTML: <html><item/><item/></html>
  XBS: <html item+/>

=item * Nodes - specified minimum and maximum number

  HTML: <html><item/><item/></html>
  XBS: <html item{1,2}/>
  or XBS: <html><item{1,2}/></html>
  or XBS: <html><item{1,2}></item{1,2}></html>

=item * Multiple acceptable node formats

  HTML: <html><item type=box volume=20/><item type=line length=10/></html>
  XBS: <html><item type=box volume/><item type=line length/></html>

=item * Regular expressions checking for values

  HTML: <html name=Bob dir=up num=10/>
  XBS: <html name=[A-Za-z]+ dir=up|down num=[0-9]+/>

=item * Require multi_ tags

  HTML: <html><multi_item/></html>
  XBS: <html item@/>

=back

=head2 Parsed Hash Structure

The hash structure returned from HTML parsing is created in a specific format.
Besides as described above, the structure contains some additional nodes in
order to preserve information that will allow that structure to be correctly
converted back to HTML.
  
Nodes may contain the following 3 additional subnodes:

=over 2

=item * _i

The character offset within the original parsed HTML of where the node
begins. This is used to provide line information for errors when HTML
fails a schema check.

=item * _pos

This is a number indicating the ordering of nodes. It is used to allow
items in a perl hash to be sorted when writing back to html. Note that
items are not sorted after parsing in order to save time if all you
are doing is reading and you do not care about the order.

In future versions of this module an option will be added to allow
you to sort your nodes so that you can read them in order.
( note that multiple nodes of the same name are stored in order )

=item * _att

This is a boolean value that exists and is 1 iff the node is an
attribute.

=back

=head2 Parsing Limitations / Features

=over 2

=item * CDATA parsed correctly, but stripped if unneeded

Currently the contents of a node that are CDATA are read and
put into the value hash, but the hash structure does not have
a value indicating the node contains CDATA.

When converting back to HTML, the contents of the value hash
are parsed to check for html incompatible data using a regular
expression. If 'CDATA like' stuff is encountered, the node
is output as CDATA.

=item * Node position stored, but hash remains unsorted

The ordering of nodes is noted using the '_pos' value, but
the hash itself is not ordered after parsing. Currently
items will be out of order when looking at them in the
hash.

Note that when converted back to HTML, the nodes are then
sorted and output in the correct order to HTML. Note that
nodes of the same name with the same parent will be
grouped together; the position of the first item to
appear will determine the output position of the group.

=item * Comments are parsed but only one is stored per node.

For each node, there can be a comment within it, and that
comment will be saved and output back when dumping to HTML.

=item * Comments override output of immediate value

If a node contains only a comment node and a text value,
only the comment node will be displayed. This is in line
with treating a comment node as a node and only displaying
immediate values when a node contains no subnodes.

=item * PI sections are parsed, but discarded

=item * Unknown C<< <! >> sections are parsed, but discarded

=item * Attributes may use no quotes, single quotes, quotes, or backtics

=item * Quoted attributes cannot contain escaped quotes

No escape character is recognized within quotes. As a result,
regular quotes cannot be stored to HTML, or the written HTML
will not be correct, due to all attributes always being written
using quotes.

=item * Attributes are always written back to HTML with quotes

=item * Nodes cannot contain subnodes as well as an immediate value

Actually nodes can in fact contain a value as well, but that
value will be discarded if you write back to HTML. That value is
equal to the first continuous string of text besides a subnode.

  <node>text<subnode/>text2</node>
  ( the value of node is text )

  <node><subnode/>text</node>
  ( the value of node is text )

  <node>
    <subnode/>text
  </node>
  ( the value of node is "\n  " )
  
=item * Entities are not parsed

No entity parsing is done. This is intentional. Future versions of the module
may include a feature to automatically parse entities, but by default any such
feature will be disabled in order to keep from slowing down the parser.

Also, this is done so that round trip ( read and then write back out ) behavior
is consistent.

=item * Nodes named value

Previously iterations of this module had problems with nodes named 'value',
due to the fact that node contents are stored under the 'value' key already.
The current version should parse such files without any problem, although it
may be confusing to see a parsed tree with 'value' pointing to another hash
containing 'value' as well.

In a future version of the module it will be possible to alter the name that
values are stored under.

Note that node values are stored under the key 'content' when the "simple"
parsing mode is used, so as to be consistent with HTML::Simple.

=back

=head2 Module Functions

=over 2

=item * C<< $ob = HTML::Bare->new( text => "[some html]" ) >>

Create a new HTML object, with the given text as the html source.

=item * C<< $object = HTML::Bare->new( file => "[filename]" ) >>

Create a new HTML object, with the given filename/path as the html source

=item * C<< $object = HTML::Bare->new( text => "[some html]", file => "[filename]" ) >>

Create a new HTML object, with the given text as the html input, and the given
filename/path as the potential output ( used by save() )

=item * C<< $object = HTML::Bare->new( file => "data.html", scheme => { file => "scheme.xbs" } ) >>

Create a new HTML object and check to ensure it is valid html by way of the XBS scheme.

=item * C<< $tree = $object->parse() >>

Parse the html of the object and return a tree reference

=item * C<< $tree = $object->simple() >>

Alternate to the parse function which generates a tree similar to that
generated by HTML::Simple. Note that the sets of nodes are turned into
arrays always, regardless of whether they have a 'name' attribute, unlike
HTML::Simple.

Note that currently the generated tree cannot be used with any of the
functions in this module that operate upon trees. The function is provided
purely as a quick and dirty way to read simple HTML files.

=item * C<< $tree = htmlin( $htmlext, keeproot => 1 ) >>

The htmlin function is a shortcut to creating an HTML::Bare object and
parsing it using the simple function. It behaves similarly to the
HTML::Simple function by the same name. The keeproot option is optional
and if left out the root node will be discarded, same as the function
in HTML::Simple.

=item * C<< $text = $object->html( [root] ) >>

Take the hash tree in [root] and turn it into cleanly indented ( 2 spaces )
HTML text.

=item * C<< $text = $object->html( [root], [root node name] ) >>

Take the hash tree in [root] and turn it into nicely colorized and styled
html. [root node name] is optional.

=item * C<< $object->save() >>

The the current tree in the object, cleanly indent it, and save it
to the file parameter specified when creating the object.

=item * C<< $value = xval $node, $default >>

Returns the value of $node or $default if the node does not exist.
If default is not passed to the function, then '' is returned as
a default value when the node does not exist.

=item * C<< ( $name, $age ) = xget( $personnode, qw/name age/ ) >>

Shortcut function to grab a number of values from a node all at the
same time. Note that this function assumes that all of the subnodes
exist; it will fail if they do not.

=item * C<< $text = HTML::Bare::clean( text => "[some html]" ) >>

Shortcut to creating an html object and immediately turning it into clean html text.

=item * C<< $text = HTML::Bare::clean( file => "[filename]" ) >>

Similar to previous.

=item * C<< HTML::Bare::clean( file => "[filename]", save => 1 ) >>

Clean up the html in the file, saving the results back to the file

=item * C<< HTML::Bare::clean( text => "[some html]", save => "[filename]" ) >>

Clean up the html provided, and save it into the specified file.

=item * C<< HTML::Bare::clean( file => "[filename1]", save => "[filename2]" ) >>

Clean up the html in filename1 and save the results to filename2.

=item * C<< $html = HTML::Bare::tohtml( text => "[some html]", root => 'html' ) >>

Shortcut to creating an html object and immediately turning it into html.
Root is optional, and specifies the name of the root node for the html
( which defaults to 'html' )

=item * C<< $object->add_node( [node], [nodeset name], name => value, name2 => value2, ... ) >>

  Example:
    $object->add_node( $root->{html}, 'item', name => 'Bob' );
    
  Result:
    <html>
      <item>
        <name>Bob</name>
      </item>
    </html>

=item * C<< $object->add_node_after( [node], [subnode within node to add after], [nodeset name], ... ) >>

=item * C<< $object->del_node( [node], [nodeset name], name => value ) >>

  Example:
    Starting HTML:
      <html>
        <a>
          <b>1</b>
        </a>
        <a>
          <b>2</b>
        </a>
      </html>
      
    Code:
      $html->del_node( $root->{html}, 'a', b=>'1' );
    
    Ending HTML:
      <html>
        <a>
          <b>2</b>
        </a>
      </html>

=item * C<< $object->find_node( [node], [nodeset name], name => value ) >>

  Example:
    Starting HTML:
      <html>
        <ob>
          <key>1</key>
          <val>a</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </html>
      
    Code:
      $object->find_node( $root->{html}, 'ob', key => '1' )->{val}->{value} = 'test';
      
    Ending HTML:
      <html>
        <ob>
          <key>1</key>
          <val>test</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </html>

=item * C<< $object->find_by_perl( [nodeset], "[perl code]" ) >>

find_by_perl evaluates some perl code for each node in a set of nodes, and
returns the nodes where the perl code evaluates as true. In order to
easily reference node values, node values can be directly referred
to from within the perl code by the name of the node with a dash(-) in
front of the name. See the example below.

Note that this function returns an array reference as opposed to a single
node unlike the find_node function.

  Example:
    Starting HTML:
      <html>
        <ob>
          <key>1</key>
          <val>a</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </html>
      
    Code:
      $object->find_by_perl( $root->{html}->{ob}, "-key eq '1'" )->[0]->{val}->{value} = 'test';
      
    Ending HTML:
      <html>
        <ob>
          <key>1</key>
          <val>test</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </html>

=item * C<< HTML::Bare::merge( [nodeset1], [nodeset2], [id node name] ) >>

Merges the nodes from nodeset2 into nodeset1, matching the contents of
each node based up the content in the id node.

Example:

  Code:
    my $ob1 = new HTML::Bare( text => "
      <html>
        <multi_a/>
        <a>bob</a>
        <a>
          <id>1</id>
          <color>blue</color>
        </a>
      </html>" );
    my $ob2 = new HTML::Bare( text => "
      <html>
        <multi_a/>
        <a>john</a>
        <a>
          <id>1</id>
          <name>bob</name>
          <bob>1</bob>
        </a>
      </html>" );
    my $root1 = $ob1->parse();
    my $root2 = $ob2->parse();
    merge( $root1->{'html'}->{'a'}, $root2->{'html'}->{'a'}, 'id' );
    print $ob1->html( $root1 );
  
  Output:
    <html>
      <multi_a></multi_a>
      <a>bob</a>
      <a>
        <id>1</id>
        <color>blue</color>
        <name>bob</name>
        <bob>1</bob>
      </a>
    </html>

=item * C<< HTML::Bare::del_by_perl( ... ) >>

Works exactly like find_by_perl, but deletes whatever matches.

=item * C<< HTML::Bare::forcearray( [noderef] ) >>

Turns the node reference into an array reference, whether that
node is just a single node, or is already an array reference.

=item * C<< HTML::Bare::new_node( ... ) >>

Creates a new node...

=item * C<< HTML::Bare::newhash( ... ) >>

Creates a new hash with the specified value.

=item * C<< HTML::Bare::simplify( [noderef] ) >>

Take a node with children that have immediate values and
creates a hashref to reference those values by the name of
each child.

=item * C<< HTML::Bare::hash2html( [hashref] ) >>

Take a recursive hash tree ( perhaps generated by the simplify function ) and turn it
into a raw HTML string. Note that this function does not indent nicely. You will need
to feed this string back into the parser and output it again if you want it to look
nice. ( or you could use the 'clean' function to do it in one go )

=item * C<< HTML::Bare->new( text => "[html]", unsafe => 1 ) >>

An extra speedy way to parse HTML. It is unsafe; may harm pets and children. Don't
say you weren't warned. 30% speed boost compared to the normal parsing. You -must-
use $ob->simple() in combination with this for it to work properly.

The speed boost is gained by skipping checks for the end of the string when in the
middle of properly formatted HTML. The only time the check is done is within "values"
( which includes the space after the final closing </html> )

Also, in the unsafe mode, tags, complete with their attributes, must be on one line.
Node contents of course, can still have carriage returns...

=item * C<< $object->read_more( text => "[html fragment]" ) >>

Add more HTML text to be handled. Note that this function must be called before
calling the parse function.

Example:

  Code:
    my $ob = HTML::Bare->new( text => "
      <html>
        <node>a</node>" );
    $ob->read_more( text => "<node>b</node>" );
    $ob->read_more( text => "</html>" );
    my $root = $ob->parse();
    print $ob->html( $root );
  
  Output:
    <html>
      <node>a</node>
      <node>b</node>
    </html>

Warning! Reading in additional HTML fragments only works properly at proper "division points".
Currently the parser will -not- work properly if you split in the middle of a node value, or
in the middle of a node name. A future version of the module will be properly updated to handle
these cases.

Currently there is little to no benefit to parsing this way, rather than simple concatenating
the two strings together and then reading all the HTML in at once.

=back

=head2 Functions not yet documented

=over 2

=item * C<< find_by_att() find_by_attr() find_by_id() find_by_idr() find_by_tagname() find_by_tagnamer() nav() >>

=back

=head2 Functions Used Internally

=over 2

=item * C<< check() checkone() readxbs() free_tree_c() >>

=item * C<< lineinfo() c_parse() c_parse_unsafely() c_parse_more() c_parsefile() free_tree() html2obj() >>

=item * C<< obj2htmlcol() get_root() obj2html() html2obj_simple() >>

=back

=head2 Controversy

Since the creation of this module there has been a fair amount of controvesy surrounding
it. A number of authors of other HTML parsers have gone so far as to publicly attack this
module and claim that it 'does not parse HTML', and 'it is not HTML compliant'. Some of the
same people seem to be angered by the inclusion of a benchmark, claiming that it is an
unfair comparison, and that if the proper options and setup are used, that other HTML
parsers are better.

The module should parse any HTML document that conforms to the standardized
HTML specifications, there is no need for alarm and fear that the module will corrupt
your HTML documents on reading.

To be blunt about how the parser works, very little has been done to make the parser
follow the specification known as 'HTML'. The parser is meant to be flexibile and somewhat
resilient, and will parse HTML like garbage that would cause other parsers to error out.

As far as I am concerned, as the author of the module, the 'HTML' in 'HTML::Bare' should
be thought of to mean 'eXtremely Mad Language', because the module was written from
scratch without referring to the specification known as 'HTML'.

In regard to the complaints about the unfairness of the included benchmarks, please
make your own intelligent decision as to what module you like by trying multiple
modules and/or running the performance tests yourself. If you like some other module,
use that module. If you like HTML::Bare and think it is the fastest thing on the planet,
that is cool too.

If you hate HTML::Bare and want to go around on the internet trashing it and telling
people to use something else, I think perhaps you may want to seek counseling.

=head2 Performance

In comparison to other available perl html parsers that create trees, HTML::Bare
is extremely fast. In order to measure the performance of loading and parsing
compared to the alternatives, a templated speed comparison mechanism has been
created and included with HTML::Bare.

The include makebench.pl file runs when you make the module and creates perl
files within the bench directory corresponding to the .tmpl contained there.

Currently there are three types of modules that can be tested against,
executable parsers ( exe.tmpl ), tree parsers ( tree.tmpl ), and parsers
that do not generated trees ( notree.tmpl ).

A full list of modules currently tested against is as follows:

  EzHTML (exe)
  Tiny HTML (exe)
  HTML::Descent (notree)
  HTML::DOM
  HTML::Fast
  HTML::Grove::Builder
  HTML::Handler::Trees
  HTMLIO (exe)
  HTML::LibHTML (notree)
  HTML::LibHTML::Simple
  HTML::Parser (notree)
  HTML::Parser::EasyTree
  HTML::Parser::Expat (notree)
  HTML::SAX::Simple
  HTML::Simple using HTML::Parser
  HTML::Simple using HTML::SAX::PurePerl
  HTML::Simple using HTML::LibHTML::SAX::Parser
  HTML::Simple using HTML::Bare::SAX::Parser
  HTML::Smart
  HTML::Twig
  HTML::TreePP
  HTML::Trivial
  HTML::XPath::HTMLParser

To run the comparisons, run the appropriate perl file within the
bench directory. ( exe.pl, tree.pl, or notree.pl )

The script measures the milliseconds of loading and parsing, and
compares the time against the time of HTML::Bare. So a 7 means
it takes 7 times as long as HTML::Bare.

Here is a combined table of the script run against each alternative
using the included test.html:

  -Module-                   load     parse    total
  HTML::Bare                  1        1        1
  HTML::TreePP                2.3063   33.1776  6.1598
  HTML::Parser::EasyTree      4.9405   25.7278  7.4571
  HTML::Handler::Trees        7.2303   26.5688  9.6447
  HTML::Trivial               5.0636   12.4715  7.3046
  HTML::Smart                 6.8138   78.7939  15.8296
  HTML::Simple (HTML::Parser)  2.3346   50.4772  10.7455
  HTML::Simple (PurePerl)     2.361    261.4571 33.6524
  HTML::Simple (LibHTML)       2.3187   163.7501 23.1816
  HTML::Simple (HTML::Bare)    2.3252   59.1254  10.9163
  HTML::SAX::Simple           8.7792   170.7313 28.3634
  HTML::Twig                  27.8266  56.4476  31.3594
  HTML::Grove::Builder        7.1267   26.1672  9.4064
  HTML::XPath::HTMLParser      9.7783   35.5486  13.0002
  HTML::LibHTML (notree)       11.0038  4.5758   10.6881
  HTML::Parser (notree)       4.4698   17.6448  5.8609
  HTML::Parser::Expat(notree) 3.7681   50.0382  6.0069
  HTML::Descent (notree)      6.0525   37.0265  11.0322
  Tiny HTML (exe)                               1.0095
  EzHTML (exe)                                  1.1284
  HTMLIO (exe)                                  1.0165

Here is a combined table of the script run against each alternative
using the included feed2.html:

  -Module-                   load     parse    total
  HTML::Bare                  1        1        1
  HTML::Bare (simple)         1        0.7238   ?
  HTML::Bare (unsafe simple)  1       ~0.5538   ?
  HTML::Fast                  1.516    0.9733   1.4783
  HTML::TreePP                0.6393   30.5951  2.6874
  HTML::MyHTML                 1.8266   14.2571  2.7113 
  HTML::Parser::EasyTree      1.5208   22.8283  2.9748 
  HTML::Trivial               2.007    25.742   3.615  
  HTML::Tiny                  0.1665   61.4918  4.3234  
  HTML::XPath::HTMLParser      2.5762   33.2567  4.6742  
  HTML::Smart                 1.702    59.4907  5.7566
  HTML::Simple (HTML::Parser)  0.5838   64.7243  5.0006  
  HTML::DOM::Lite             4.5207   17.4617  5.4033
  HTML::Simple (LibHTML)       0.5904   161.7544 11.5731
  HTML::Twig                  8.553    56.9034  11.8805 
  HTML::Grove::Builder        7.2021   30.7926  12.9334
  HTML::Handler::Trees        6.8545   33.1007  13.0575
  HTML::LibHTML::Simple        14.0204  11.8482  13.8707
  HTML::Simple (PurePerl)     0.6176   321.3422 23.0465 
  HTML::Simple                2.7168   90.7203  26.7525
  HTML::SAX::Simple           8.7386   94.8276  29.2166
  HTML::LibHTML (notree)       11.0023  5.022    10.5214
  HTML::Parser (notree)       4.3748   25.0213  5.9803
  HTML::Parser::Expat(notree) 3.6555   51.6426  7.4316
  HTML::Descent (notree)      5.9206   155.0289 18.7767
  Tiny HTML (exe)                               1.2212
  EzHTML (exe)                                  1.3618
  HTMLIO (exe)                                  1.0145

These results show that HTML::Bare is, at least on the
test machine, running all tests within cygwin, faster
at loading and parsing than everything being tested
against.

The following things are shown as well:
  - HTML::Bare can parse HTML and create a hash tree
  in less time than it takes LibHTML just to parse.
  - HTML::Bare can parse HTML and create a tree
  in less time than all three binary parsers take
  just to parse.
  - HTML::Fast is theoretically faster at parsing than
  the default 'full' mode of HTML::Bare. Despite that,
  the 'simple' mode of HTML::Bare is even faster.

Note that the executable parsers are not perl modules
and are timed using dummy programs that just uses the
library to load and parse the example files. The
executables are not included with this program. Any
source modifications used to generate the shown test
results can be found in the bench/src directory of
the distribution

=head1 LICENSE

  Copyright (C) 2008 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut
