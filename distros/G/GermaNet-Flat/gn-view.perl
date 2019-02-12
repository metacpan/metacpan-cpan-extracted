#!/usr/bin/perl -w

use CGI qw(:standard :cgi-lib);
use lib qw(.);
use GermaNet::Flat;
use GraphViz;
use File::Basename qw(basename dirname);
use Encode qw(encode decode encode_utf8 decode_utf8);
use HTTP::Status;
use File::Temp;
use JSON;

use utf8;
use strict;
use open qw(:std :utf8);

##==============================================================================
## constants
our $prog = basename($0);

our $label     = "GermaNet"; ##-- top-level label
our $charset   = 'utf-8';    ##-- this is all we support for now
our $max_depth = 2;          ##-- maximum 'depth' parameter (0:none)
our $vars = {};

our %defaults =
  (
   'q'=>'GNROOT',
   'f'=>'html',
   'case' => 1,
   'db' => 'gn',
   'depth' => 1, ##-- TODO
  );

##-- local overrides
if (-r "$0.rc") {
  do "$0.rc";
  die("$0: error reading rc file $0.rc: $@") if ($@);
}

##==============================================================================
## utils

BEGIN {
  *htmlesc = \&escapeHTML;
}

my ($gn);
sub syn_id {
  return ref($_[0]) ? $_[0]{synset} : $_[0];
}
sub syn_label {
  my $syn = shift;
  return join("\\n", @{ref($syn) ? $syn->{orth} : $gn->lex2orth($gn->syn2lex($syn))});
}

my (%nodes,%edges,$gv);
sub ensure_node {
  my ($syn,%opts) = @_;
  my $synid = syn_id($syn);
  $gv->add_node(($nodes{$synid}=$synid),
		label=>syn_label($syn),
		URL=>"?s=$synid",
		%opts,
	       ) if (!exists $nodes{$synid});
}

sub ensure_edge {
  my ($from,$to,%opts) = @_;
  my $fromid = syn_id($from);
  my $toid   = syn_id($to);
  if (exists $edges{"$fromid $toid"}) {
    #print STDERR "edge exists: $fromid $toid\n";
    return;
  }
  $edges{"$fromid $toid"} = "$fromid $toid";
  $gv->add_edge($fromid,$toid,%opts);
  return;
}

sub ensure_tree {
  my ($syn,$subdepth,$supdepth, $opts,$subopts,$supopts) = @_;
  ensure_node($syn, %{$opts//{}});
  if (($subdepth//0) > 0) {
    foreach my $sub (@{$syn->{hyponyms}//[]}) {
      ensure_tree($sub, $subdepth-1,0, $subopts,$subopts,undef);
      ensure_edge($syn, $sub);
    }
  }
  if (($supdepth//0) > 0) {
    foreach my $sup (@{$syn->{hyperonyms}//[]}) {
      ensure_tree($sup, 0,$supdepth-1, $supopts,undef,$supopts);
      ensure_edge($sup, $syn);
    }
  }
}


## \%info = synset_info($synsetId, $subdepth=0, $supdepth=0)
##  + returned hash is of the form {synset=>$synsetId, orth=>\@orths, ...}
##  + if $subdepth is greater than zero, hash also has hyponyms=>\@subs
##  + if $supdepth is greater than zero, hash also has hyperonyms=>\@supers
sub synset_info {
  my ($syn,$subdepth,$supdepth) = @_;
  my $info = {synset=>$syn, orth=>[map {s/_/ /g; $_} @{$gn->lex2orth($gn->syn2lex($syn))}]};
  if (($subdepth//0) > 0) {
    $info->{hyponyms}=[];
    foreach my $sub (@{$gn->hyponyms($syn)}) {
      push(@{$info->{hyponyms}}, synset_info($sub,$subdepth-1,0));
    }
  }
  if (($supdepth//0) > 0) {
    $info->{hyperonyms}=[];
    foreach my $sup (@{$gn->hyperonyms($syn)}) {
      push(@{$info->{hyperonyms}}, synset_info($sup,0,$supdepth-1));
    }
  }
  return $info;
}

## $tmpdata = gvdump($gv,$fmt)
##  + workaround for broken UTF-8 support in GraphViz::as_* methods
sub gvdump {
  my ($gv,$fmt) = @_;
  my ($fh,$filename) = File::Temp::tempfile('gnvXXXXX',DIR=>'/tmp',SUFFIX=>".$fmt",UNLINK=>1);
  $fh->close();
  my $dot = $gv->as_debug;
  open(DOT,'|-','dot',"-T$fmt","-o$filename")
    or die("$prog: could not open pipe to dot: $!");
  binmode(DOT,':utf8');
  print DOT $dot
    or die("$prog: failed to write to DOT pipe: $!");
  close DOT
    or die("$prog: failed to close DOT pipe: $!");
  local $/=undef;
  open(BUF,"<:raw", $filename)
    or die("$prog: open failed for temp file '$filename': $!");
  my $buf = <BUF>;
  close BUF;

  return $buf;
}

## $bool = is_robot()
##  + check for common robots via user agent
##  + found in logs:
## "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
## "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)" 
sub is_robot {
  my $ua = user_agent() // '';
  return $ua =~ /Googlebot|YandexBot/ ? 1 : 0;
}

##======================================================================
## cgi parameters

##-- DEBUG
sub showq {
  return;
  my ($lab,$q) = @_;
  $q //= '';
  printf STDERR
    ("$0: $lab: q=$q \[utf8:%d,valid:%d,check:%d]\n",
     (utf8::is_utf8($q) ? 1 : 0),
     (utf8::valid($q) ? 1 : 0),
     (Encode::is_utf8($q,1) ? 1 : 0),
    );
}

##-- get params
if (param()) {
  $vars = { Vars() }; ##-- copy tied Vars()-hash, otherwise utf8 flag gets handled wrong!
}

##-- rename vars
$vars->{q} //= (grep {$_} @$vars{qw(lemma l term t word w)})[0];
$vars->{s} //= (grep {$_} @$vars{qw(synset syn s)})[0];
$vars->{f} //= (grep {$_} @$vars{qw(format fmt f mode m)})[0];
$vars->{db} //= (grep {$_} @$vars{qw(database base db)})[0];
$vars->{case} //= (grep {$_} @$vars{qw(case_sensitive sensitive sens case cs)})[0];
$vars->{depth} //= (grep {$_} @$vars{qw(depth d)})[0];
showq('init', $vars->{q}//'');

charset($charset); ##-- initialize charset AFTER calling Vars(), otherwise fallback utf8::upgrade() won't work

##-- instantiate defaults
#use Data::Dumper; print STDERR Data::Dumper->Dump([\%defaults,$vars],['defaults','vars']);
$vars->{$_} = $defaults{$_} foreach (grep {!defined($vars->{$_})} keys %defaults);
$vars->{depth} = $max_depth if (($max_depth//0) > 0 && ($vars->{depth}//0) > $max_depth);
showq('default', $vars->{q});

##-- sanitize vars
foreach (keys %$vars) {
  next if (!defined($vars->{$_}));
  my $tmp = $vars->{$_};
  $tmp =~ s/\x{0}//g;
  eval {
    ##-- try to decode utf8 params e.g. "%C3%B6de" for "öde"
    $tmp = decode_utf8($tmp,1) if (!utf8::is_utf8($tmp) && utf8::valid($tmp));
  };
  if ($@) {
    ##-- decoding failed; treat as bytes (e.g. "%F6de" for "öde")
    utf8::upgrade($tmp);
    undef $@;
  }
  $vars->{$_} = $tmp;
}

showq('sanitized', $vars->{q});
our $depth = $vars->{depth};

##==============================================================================
## MAIN
my %fmtxlate = ('text'=>'dot',
		'jpg'=>'jpeg',
	       );
my %fmt2type = ('png'=>'image/png',
		'gif'=>'image/gif',
		'jpeg'=>'image/jpeg',
		'dot'=>'text/plain',
		'canon'=>'text/plain',
		'debug'=>'text/plain',
		'cmapx'=>'text/plain',
		'imap'=>'text/html',
		'svg'=>'image/svg+xml',
                'eps'=>'application/postscript',
                'ps'=>'application/postscript',
		'json'=>'application/json',
	       );
eval {
  die "$prog: you must specify either a query term (q=TERM) or a synset (s=SYNSET)!"
    if (!$vars->{q} && !$vars->{s});

  my $dir0   = dirname($0);
  my $infile = (grep {-r $_} map {($_,"$_.db","$dir0/$_","$dir0/$_.db")} map {($_,"${label}/$_")} ($vars->{db}))[0];
  die("$0: couldn't find input file for db=$vars->{db}") if (!$infile);
  #print STDERR "$0: using database '$infile'\n";
  $gn = GermaNet::Flat->load($infile)
    or die("$prog: failed to load '$infile': $!");

  ##-- output format
  my $fmt = $vars->{f};
  $fmt    = $fmtxlate{$fmt} if (exists($fmtxlate{$fmt}));

  ##-- basic properties
  my ($syns,$qtitle);
  if ($vars->{s}) {
    ##-- basic properties: synset query
    $syns   = [grep {exists($gn->{rel}{"syn2lex:$_"})} split(' ',$vars->{s})];
    $qtitle = '{'.join(', ', @{$gn->auniq($gn->synset_terms($syns))}).'}';
  } else {
    ##-- basic properties: lemma or synset query
    my @terms = split(' ',$vars->{q});
    @terms    = $gn->luniq(map {($_,lc($_),ucfirst(lc($_)))} @terms) if (!$vars->{case});
    $syns     = $gn->get_synsets(\@terms) // [];
    push(@$syns, grep {exists($gn->{rel}{"syn2lex:$_"})} @terms); ##-- allow synset names as 'lemma' queries
    $qtitle   = $vars->{q};
  }
  #print STDERR "syns = {", join(' ',@{$syns||[]}), "}\n";
  #die("$prog: no synset(s) found for query \`$qtitle'") if (!$syns || !@$syns);
  $syns //= [];

  ##-- header keys
  my %versionHeader = ("-X-germanet-version"=>($gn->dbversion()||'unknown'));

  my $info = [map {synset_info($_,$depth,$depth)} @$syns];
  if ($fmt eq 'json') {
    ##-- json format: just dump info

    binmode *STDOUT, ':raw';
    print
      (header(-type=>$fmt2type{json},%versionHeader),
       to_json($info, {utf8=>1, pretty=>1, canonical=>1}),
      );

    exit 0;
  }


  ##-- graphviz object
  $gv = GraphViz->new(
		      directed=>1,
		      rankdir=>'LR',
		      #concentrate=>1,
		      name=>'gn',
		      node=>{shape=>'rectangle',fontname=>'arial',fontsize=>12,style=>'filled',fillcolor=>'white'},
		      edge=>{dir=>'back'},
		     );

  foreach my $syn (@$info) {
    ensure_node($syn, fillcolor=>'yellow',fontname=>'arial bold',shape=>'circle');
  }
  foreach my $syn (@$info) {
    ensure_tree($syn,$depth,$depth, {},{fillcolor=>'cyan'},{fillcolor=>'magenta'});
  }

  ##-- dump
  #print $gv->as_debug; exit 0;
  #print $gv->as_canon; exit 0;

  ##-- get content
  my ($fmtsub);
  if ($fmt eq 'html') {
    ##-- content: html
    my ($imgfmt);
    #$imgfmt = 'svg';
    $imgfmt = 'png';
    my $cmapx = gvdump($gv,'cmapx');
    my $deptharg = ($depth > 1) ? "&d=$depth" : '';
    if (1) {
      ##-- trim/rename titles
      $cmapx =~ s/\s(?:title|alt)=\"[^\"]*\"//sg;
      $cmapx =~ s/href=\"\?s=(\w+)\"/href="?s=$1$deptharg" title="$1"/g;
    }
    print
      (header(-type=>'text/html',-charset=>$charset,%versionHeader),
       start_html("$label Graph: $qtitle"),
       h1("$label Graph: $qtitle"),
       ($syns && @$syns
	? ("<img src=\"${prog}?fmt=${imgfmt}&s=".join('+',@{$syns||[]})."$deptharg\" usemap=\"#gn\" />\n",
	   $cmapx,
	  )
	: ("no synset(s) found!")
       ),
       ##-- ugly hack
       q{<hr/>
<span style="display:block; text-align:center; color:#666666;">
 <a style="color:#666666;" href="/dstar/imprint">Imprint</a>
 &#x00b7;
 <a style="color:#666666;" href="/dstar/privacy">Privacy</a>
</span>
},
       end_html,
      );
  }
  elsif ($fmt eq 'debug') {
    print header(-type=>$fmt2type{$fmt},-charset=>'utf-8'), eval "\$gv->as_${fmt}()";
  }
  elsif (exists($fmt2type{$fmt})) {
    binmode *STDOUT, ':raw';
    print
      (header(-type=>($fmt2type{$fmt}//"application/octet-stream")),
       gvdump($gv,$fmt),
      );
  }
  else {
    die "$prog: unknown format '$fmt'";
  }
  exit 0;
};

##----------------------------------------------------------------------
## catch errors
if ($@) {
  print
    (header(-status=>RC_INTERNAL_SERVER_ERROR),
     start_html('Error'),
     h1('Error'),
     pre(escapeHTML($@)),
     end_html);
  exit 1;
}

