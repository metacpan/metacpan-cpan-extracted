package License::Syntax;

use warnings;
use strict;
use Carp;
use DBI;
use Text::CSV;
use POSIX;
use Data::Dumper;

=head1 NAME

License::Syntax - Coding and Decoding of License strings using SPDX and SUSE syntax.

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';


=head1 SYNOPSIS

This implements the SUSE License Syntax.

    use License::Syntax;

    my $obj = new License::Syntax licensemap => 'licenselist.csv;as';
    my $obj = new License::Syntax map => { 'GNU General Public License V2.0' => 'GPLv2' };
    my $obj = new License::Syntax 'pathname.sqlite;table(alias,name)';
    $obj->loadmap_csv($filename_csv);
    $obj->loadmap_sqlite($filename_sqlite, $table_name, $alias_col, $name_col);
    $obj->savemap_csv($filename_csv, scalar(localtime));
    $obj->savemap_sqlite($filename_sqlite, $table_name, $alias_col, $name_col, 'TRUNCATE');
    $obj->add_alias($alias, $canonical_name);
    $name = $obj->canonical_name($alias, $disambiguate);
    $tree = $obj->tokenize('GPLv2 & Apache 1.1; LGPLv2.1 | BSD4c<<ex(UCB); Any Noncommercial', $disambiguate);
    $name = $obj->format_tokens($tree);


=head1 FUNCTIONS

=head2 new

License::Syntax is an object oriented module.
When constructing new License::Syntax objects, you can provide a mapping table for
license names. The table is used for recognizing alternate alias names for the
licenses (left hand side) and also defines the canonical short names of the licenses
(right hand side). 
The mapping table is consulted twice, before and after decoding the syntax.
(Thus non-terminal mappings may actually be followed.)

The mapping table can be provided either 

=over 2

=item * as a CSV files of two columns. Column seperator is a comma (,)

=item * as a hash, or

=item * as table in an sqlite database using the given columns as left hand side and right hand side respectivly.

=back

As an alternative to specifying a mapping with new(), or additionally, mappings 
can also be provided via loadmap_sqlite(), loadmap_csv(), or add_alias() 
methods. Earlier mappings take precedence over later mappings.


=cut

sub new
{
  my $self = shift;
  my $class = ref($self) || $self;
  if (1 == scalar @_ and !ref $_[0])
    {
      $self = { new => { licensemap => $_[0] } };
    }
  else
    {
      $self = { new => { (ref $_[0] eq 'HASH') ? %{$_[0]} : @_ } };
    }
  $self = bless $self, $class;

  $self->set_rejects('REJECT');

  # use Data::Dumper;
  # carp Dumper $self, $class, \@_;
  if ($self->{new}{map})
    {
      for my $k (%{$self->{new}{map}})
        {
	  $self->add_alias($k, $self->{new}{map}{$k});
	}
      delete $self->{new}{map};
    }
  $self->_loadmap($self->{new}{licensemap})
               if $self->{new}{licensemap};
  return $self;
}

# dispatch into either loadmap_sqlite or loadmap_csv.
sub _loadmap
{
  my ($s,$f) = @_;

  # "filename.csv"
  # "filename.csv;garbage"
  my $suf = $1 if $f =~ s{;([\w,;\#\(\)]+)$}{};
  return $s->loadmap_csv($f, $suf) if $f =~ m{\.csv$}i;

  croak "$f: needs either .csv or .sqlite suffix\n" unless $f =~ m{\.sql(ite)?$}i;

  # "filename.sqlite;table"
  # "filename.sqlite;table(alias,name)"
  my ($table,$left,$right) = ($1,'alias','name') if $suf =~ m{^(\w+)};
  ($left,$right) = ($1,$2) if $suf =~ m{\((\w+)\W(\w+)};
  return $s->loadmap_sqlite($f, $table, $left, $right);
}

## returns a two column array with the minimum representation of a license map.
sub _saveable_map
{
  my ($s) = @_;
  my %identity;
  my %done;

  my @r;
  for my $k (sort keys %{$s->{licensemap}{ex}})
    {
      my $v = $s->{licensemap}{ex}{$k};
      if ($v eq $k)
        {
	  $identity{$v}++;
	}
      else
        {
	  push @r, [$k,$v];
	  $done{$v}++;
	}
    }

  for my $k (keys %identity)
    {
      next if $done{$k};
      push @r, ['',$k];
    }

  return \@r;
}

=head2 canonical_name

    $name = $obj->canonical_name($alias);
is equivalent to
    $name = $obj->format_tokens($obj->tokenize($alias));
    
=cut

sub canonical_name
{
  my ($s, $name) = @_;
  return $s->format_tokens($s->tokenize($name));
}

=head2 savemap_csv

$obj->savemap_csv('filename.csv', scalar(localtime));

Writes the current mapping table as a comma seperated file.

=cut

sub savemap_csv
{
  my ($s, $f, $header_suffix) = @_;
  open O, ">", $f or croak "$f: write failed: $!";
  print O qq{# "Alias name","Canonical Name"  -- saved by License::Syntax $VERSION};
  $header_suffix = '' unless defined $header_suffix;
  $header_suffix .= "\n" unless $header_suffix =~ m{\n$}s;
  print O $header_suffix;

  my $list = $s->_saveable_map();
  for my $r (@$list)
    {
      print O qq{"$r->[0]","$r->[1]"\n};
    }
  close O or croak "$f: write failed: $!";
}

=head2 set_rejects

$obj->set_rejects('REJECT', ...);

define the license names to be rejected. Per default,
exactly one name 'REJECT' is rejected.

=cut

sub set_rejects
{
  my ($s, @r) = @_;

  # store as a hash for faster test.
  $s->{REJECT} = { map { $_ => 1 } @r };
  return $s;
}

=head2 add_alias

$obj->add_alias($alias,$name);
$obj->add_alias(undef,$name);
$obj->add_alias('',$name);

adds $name (and optionally $alias) to the objects licensemap.
Both, lower case and exact mappings are maintained.
(add_url is used in loadmap_csv)

add_alias() takes care to extend to the right. That is, if it's right hand side 
parameter is already known to be an alias, the new alias is added pointing to the old alias's canonical name (rahter than to the old alias that the caller provided).

CAVEAT:
add_alias() does not maintain full tranitivity, as it does not extend to the left.
If its left hand side is already known to be a canonical name, a warning is 
issued, but the situation cannot be corrected, as this would require rewriting
existing entries. This is non-obvious, as mappings are applied more than once 
during format_tokens(), so indirect mappings involving non-terminal names, may 
or may not work. A two step mapping currently works reliably, though.

add_alias() does nothing, if it would directly redo an existing mapping.

See also new() for more details about mappings.

=cut

=head2 add_url

$obj->add_url($urls, $name);

Add one or multiple URLs to the canonical license name. URLs can be seperated by comma or whitespace.
May be called multiple times for the same name, and fills an array of urls.
(add_url is used in loadmap_csv)

=cut

=head2 set_compat_class
$obj->set_compat_class($cc, $name);

Specify the compatibility class, for a canonical license name.
compatibility classes are numerical. These classes allow to derive certain compatibility issues 
amongst liceses. Some classes are always incompatible (even amongst themselves), other
classes are always comaptible, and for some other classses, compatibility is uncertain.
The exact semantics are to be defined.  (set_compat_class is used in loadmap_csv).

=cut

sub set_compat_class
{
  my ($s, $cc, $canonical_name) = @_;
  $cc += 0;
  croak "compatibility class should be numeric and > 0\n" unless $cc;
  $s->{licensemap}{cc}{$canonical_name} = $cc;
}

sub add_url
{
  my ($s, $url, $canonical_name) = @_;
  my @url = split(/[,\s]+/, $url);
  push @{$s->{licensemap}{url}{$canonical_name}}, @url;
}

sub add_alias
{
  my ($s, $from, $to) = @_;

  $from = '' if defined($from) and $from eq $to;	# not an alias.

  # normalize whitespace:
  $to =~ s{\s+}{ }g;
  $from =~ s{\s+}{ }g if defined $from;

  if (defined(my $nn = $s->{licensemap}{ex}{$to}))
    {
      # do right extend
      # simple loopdetection first:
      croak "cyclic alias '$from' -> '$to' with already known canonical name '$nn'\n"
        if defined($from) && $from eq $nn;

      # now extend:
      carp "add_alias: '$from' -> '$to' extended to '$nn'\n" if $s->{debug};
      $to = $nn;
    }

  if (defined $from and $from ne '')
    {
      my $aa;
      if (defined($aa = $s->{licensemap}{ex}{$from}))
        {
	  if ($aa eq $from)
	    {
	      # this alias is a right hand side. 
	      # We recognize this, because all right hand sides map to itself.
	      my $msg = "mapping error: '$from' is now both alias and canonical name. Try to load '$from' -> '$to' earlier.";
	      carp "$msg\n" if $s->{debug};
	      push @{$s->{diagnostics}}, $msg;
	    }
	  else
	    {
	      # this is a chane attempt to an existing mapping.
	      # silently ignored.
	      carp "mapping ignored: '$from' => '$to', it already maps to '$aa'\n" if $s->{debug};
	      return $s;
	    }
	}
      $s->{licensemap}{ex}{$from} = $to;
      $s->{licensemap}{lc}{lc $from} = $to;
      if (scalar(my @a = _tokenize_linear($from)) > 1)
        {
          $s->{licensemap}{tok}{lc $a[0]}{$from} = [ @a ];
	}
    }
  $s->{licensemap}{ex}{$to} = $to;
  $s->{licensemap}{lc}{lc $to} = $to;
  if (scalar(my @a = _tokenize_linear($to)) > 1)
    {
      $s->{licensemap}{tok}{lc $a[0]}{$to} = [ @a ];
    }
  return $s;
}

=head2 savemap_sqlite

$obj->savemap_sqlite('filename.sqlite', 'lic_map', 'alias', 'shortname', $trunc_flag);


	# sqlite3 filename.sqlite
	sqlite> select * from lic_map
	alias | shortname
	------|----------
	...

If $trunc_flag is true and the table previously exists, the table is truncated before it is written to; 
otherwise new contents merges over old contents, if any.

=cut

sub savemap_sqlite
{
  my ($s, $f, $t, $a, $n, $trunc_flag) = @_;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$f","","") or carp "DBI-connect($f) failed: $!";

  $dbh->do("PRAGMA default_synchronous = OFF") if $s->{new}{nofsync};
  $dbh->do("CREATE TABLE IF NOT EXISTS $t ( $a TEXT, $n TEXT )");
  $dbh->do("DELETE FROM $t") if $trunc_flag;

  my $list = $s->_saveable_map();
  for my $r (@$list)
    {
      $dbh->do("INSERT OR REPLACE INTO $t ($a,$n) VALUES(?,?)", {}, $r->[0], $r->[1]);
    }
  $dbh->disconnect();
  return $s;
}

=head2 loadmap_sqlite

See also new() for more details about mappings.

=cut

sub loadmap_sqlite
{
  my ($s, $f, $t, $a, $n) = @_;

  my $dbh = DBI->connect("dbi:SQLite:dbname=$f","","") or carp "DBI-connect($f) failed: $!";
  my $list = $dbh->selectall_arrayref("SELECT $a,$n FROM $t");
  for my $r (@$list)
    {
      $s->add_alias($r->[0], $r->[1]);
    }
  $dbh->disconnect();
  return $s;
}

=head2 tokenize

$tree_arr = $obj->tokenize($complex_license_expr);
$tree_arr = $obj->tokenize($complex_license_expr, 1);

Returns an array reference containing tokens and sub-arrays, 
describing how the $complex_license_expr is parsed.
If a second parameter disambiguate is provided and is true,
extra parenthesis are inserted to unambiguiusly show how the 
complex expression is interpreted.
If names have been loaded with add_alias, before calling tokenize, 
all names and aliases are recognized as one token. E.g. "GPL 2.0 or later"
would be split as ["GPL 2.0", "or", "later"] otherwise.
No name mapping is performed here.


=cut

sub _tokenize_linear
{
  my ($text) = @_;
  $text =~ s{\s+}{ }g;	# normalize whitespace
  my @a = ($text =~ m{\s*(.*?)?\s*(;|\||&|\bor\b|\band\b|<<|\(|\)|$)}gi);

  ## the above regexp often returns ['somthing', '', '', '']
  ## remove the empty trailers.
  while ((scalar @a) and ($a[-1] eq ''))
    {
      pop @a;
    }
  return @a;
}

sub tokenize
{
  my ($s, $text, $disambiguate) = @_;

  $text = "REJECT(?undefined($text)?)" unless $text =~ m{\w\w};

  #### accept a comma instead of a semicolon, unless there are semicolons.
  ## Not done, we have to digest this: "The PHP License, version 3.01"
  ## $text =~ s{,}{;} unless $text =~ m{;};

  ## tokenize the expression by cutting at all operators and parenthesis.
  ## we cut before and after such operators and parenthesis, so that we
  ## do not lose anything by cutting.

  my @a = _tokenize_linear($text);
  my $i = 0;
  for (; $i <= $#a; $i++)	# this may shorten while we walk along.
    {
      if (my $m = $s->{licensemap}{tok}{lc $a[$i]})
        {
	  for my $k (keys %$m)
	    {
	      my $match = 1;
	      for my $j (1..$#{$m->{$k}})
		{
		  if ($a[$i+$j] ne $m->{$k}[$j])
		    {
		      $match = 0;
		      last;
		    }
		}

	      if ($match)
		{
		  # Undo tokenization:
		  # Replace tokenized version with original license name
		  splice @a, $i, (scalar @{$m->{$k}}), $k;
		  last;
		}
	    }
	}
      $a[$i] = 'and' if $a[$i] eq '&';
      $a[$i] = 'or'  if $a[$i] eq '|';
    }

  ## before we group tokens, we pull back license names that contain or.
  
  $s->{disambiguate}++ if $disambiguate;
  my $r = [ $s->_group_tokens(0, @a) ];
  $s->{disambiguate}-- if $disambiguate;
  return $r;
}

sub _group_tokens
{
  my ($s, $l, @a) = @_;
  $s->{debug} ||= 0;	# manually enable debugging here, in new().

  push @a, '';		# helps flushing $arr

  my @r;
  my $arr = [];
  my $in_word = 0;
  my $in_parens = 0;

  for my $a (@a)
    {
      $in_parens++ if ($a =~ m{\(});
      $in_parens-- if ($a =~ m{\)}) and $in_parens;
      $in_word++ if ($a =~ m{\w}) and !$in_parens;

      carp "$l: a='$a' in_parens=$in_parens in_word=$in_word\n" if $s->{debug};

      ## operators, but not parenthesis
      ## must include the empty string here!
      if ($a =~ m{^(;|\||&|\bor\b|\band\b|<<|)$}i and !$in_parens)
        {
	  carp "$l: emit [@$arr]\n" if $s->{debug};
	  if (scalar @$arr)
	    {
	      if ($in_word)
	        {
		  # put whitespace around some operators, so that it looks nicer.
		  # ; only has a trailing whitespace, << has no whitespaces.
	  	  # KEEP IN SYNC with format_tokens()
		  map { $_ = " $1 " if /^(;|\||&|\bor\b|\band\b)$/; s{^ ; $}{; } } @$arr;
	          push @r, join '', @$arr;
		}
	      else
	        {
		  ## must be an expression in parenthesis
		  unless ($arr->[0] eq '(' and $arr->[-1] eq ')')
		    {
		      my $msg = "parse error: not in_word, and not in parens: a='$a' [@$arr]";
		      push @{$s->{diagnostics}}, $msg;
		      carp "$msg\n" if $s->{debug};
		    }
		  shift @$arr if $arr->[0] eq '('; 
		  pop @$arr   if $arr->[-1] eq ')';
		  carp "$l: recursion into [@$arr]\n" if $s->{debug};
	          push @r, [ $s->_group_tokens($l+1, @$arr) ];
		}
	    }
	  $arr = [];
          $in_word = 0 
	}
      if ($in_word or $in_parens or $a eq ')')
        {
	  carp "$l: add '$a' to [@$arr]\n" if $s->{debug};
	  if ($a eq ')' and !$in_parens and !@$arr)
	    {
	      my $msg = "parse error: bogus '$a'";
	      push @{$s->{diagnostics}}, $msg;
	      carp "$msg\n" if $s->{debug};
	    }
	  push @$arr, $a if length $a;
	}
      else
        {
	  carp "$l: emit '$a'\n" if $s->{debug};
          push @r, $a if length $a;
	}
    }

  if ($in_parens)
    {
      my $msg = "parse error: missing closing ')'";
      push @{$s->{diagnostics}}, $msg;
      carp "$msg\n" if $s->{debug};
      return $s->_group_tokens($l, @a, ')') 
    }

  if ($s->{disambiguate})
    {
      ## the ordering here defines operator precedence.
      for my $op ('<<', '&', 'and', '|', 'or', ';')
        {
          @r = _disambiguate($op, @r);
	}
    }

  ## we remove extra parens unconditionally.
  while (scalar(@r) == 1 and ref $r[0] eq 'ARRAY')
    {
      if ($s->{debug})
        {
	  use Data::Dumper;
          warn "removing extra parens from" . Dumper(\@r). Dumper $r[0];
	}
      @r = @{$r[0]};
    }
  return @r;
}

## find stretches of indentical operators $tok
## and replace them by one sub-array each, containing the same.
sub _disambiguate
{
  my ($tok, @a) = @_;
  
  my $i;
  for ($i = 1; $i <= $#a; $i+= 2)
    {
      if (defined($a[$i]) && $a[$i] eq $tok)
        {
	  my $e = $i;
          while (defined($a[$e+2]) && $a[$e+2] eq $tok) { $e += 2; }
	  splice @a, $i-1, $e-$i+3, [ @a[$i-1 .. $e+1] ];
	  # assert: $a[$i+2] cannot be $tok now.
	}
    }
  return @a;
}

=head2 format_tokens

reverse operation of tokenize()

=cut

sub _map_license_name
{
  my ($s, $name, $prev_op) = @_;
  my $parens;

  my $origname = $name;

  # used as a flag, so that we know if we mapped the name at least once.
  my $mapped; 
  # we try the mapping three times:
  # first including any parenthesis
  # second: after splitting parethetical description
  # third: after shaping into possibly conforming syntax

  {
    my $new = $s->{licensemap}{ex}{$name};
    $new = $s->{licensemap}{lc}{lc $name} unless defined $new;
    $mapped = $name = $new if defined $new;
  }

  ($name,$parens) = ($1,$3) if $name =~ m{^\s*(.*?)\s*(\((.*)\))?\s*$};
  $origname = $name unless $name eq 'REJECT';

  ## allow for underscores in these name, to make vim users happy.
  $name =~ s{(PERMISSIVE|NON|COPYLEFT)[-_]OSI[-_]COMPLIANT}{$1-OSI-COMPLIANT}g;


  {
    my $new = $s->{licensemap}{ex}{$name};
    $new = $s->{licensemap}{lc}{lc $name} unless defined $new;
    $mapped = $name = $new if defined $new;
  }

  if (1)
    {
      ## policy: version numbers are appended with '-', not with 'v', ' V'
      ##         version numbers do not end in '.0'
      # LGPLv2.1	->	LGPL-2.1
      # Apache V2.0	->	Apache-2.0
      ###
      $name =~ s{(\w+)(-v|-V| V| v|v| )(\d[\.\d]*\+?|\d+\.\d[-~\w]*\+?)\s*$}{$1-$3} unless $s->{licensemap}{lc}{lc $name};
      $name =~ s{(\d)\.0$}{$1} unless $s->{licensemap}{lc}{lc $name};
    }
  else	# this is old policy, we do it the other way round now.
    {
      ## policy: version numbers are appended with a lower case v, 
      ##         if the name is all caps and without white space.
      ##         otherwise append with space and capital V.

      ## LGPL-2.1      -> LGPL v2.1		-> LGPLv2.1
      ## LGPL-V2.1     -> LGPL v2.1		-> LGPLv2.1
      ## GPL-2+        -> GPL v2+		-> GPLv2+
      ## Apache-2.0    -> Apache v2.0	-> Apache V2.0
      ## do this only, if it really looks like a version number.
      ## e.g. XXX-3   XXX-3.0~alpha  BUT NOT vision-3d or BSD-4clause
      $name =~ s{(\w+)-[vV]?(\d[\.\d]*\+?|\d+\.\d[-~\w]*\+?)\s*$}{$1 v$2};


      ## LGPL v2.1     -> LGPLv2.1
      ## LGPL 2.1+     -> LGPLv2.1+
      ## PERMISSIVE	   -> PERMISSIVE
      unless ($name =~ s{^([A-Z_\d\.-]+)\s*[vV ](\d\S*?)$}{$1v$2})
	{
	  ## CC BY-SA v3.5 -> CC BY-SA V3.5
	  ## Apache v2.0   -> Apache V2.0
	  $name =~ s{^(.*\S)\s*[vV ](\d\S*?)$}{$1 V$2};
	}
    }

  ##        
  ## policy: modifiers are all lower case, licenses start upper case.
  if (($prev_op||'') eq '<<')
    { 
      $name = lc $name;
    }
  else
    {

	{
	  my $new = $s->{licensemap}{ex}{$name};
	  $new = $s->{licensemap}{lc}{lc $name} unless defined $new;
	  $mapped = $name = $new if defined $new;
	}
      
      unless (defined $mapped)
        {
	  # names not in the mapping table get an questionmark!
	  $name = ucfirst $origname;
	  $name = '?' . $name unless $name =~ m{^\?};
	  $name = $name . '?' unless $name =~ m{\?$};
	  push @{$s->{diagnostics}}, "unknown name: '$origname'";
	}
      else
        {
          $name = ucfirst $name;
	}
    }
  if ($name eq 'REJECT' and $origname !~ m{REJECT})
    {
      $parens = "?$origname?";
      push @{$s->{diagnostics}}, "rejected name: '$origname'";
    }
  $name .= "($parens)" if $parens;
  return $name;
}

sub format_tokens
{
  my ($s, $aa) = @_;
  my @a;
  for my $a (@$aa)
    {
      if (ref $a)
        {
	  push @a, '(', $s->format_tokens($a), ')';
	}
      else
        {
	  if ($a =~ m{\w\w} and $a !~ m{^(and|or)$}i)
	    {
	      $a = $s->_map_license_name($a, @a?$a[-1]:undef);
	    }
	  else
	    {
	      # put whitespace around some operators, so that it looks nicer.
	      # ; only has a trailing whitespace, << has no whitespaces.
	      # KEEP IN SYNC with _group_tokens() if in_word
	      $a =~ s{^(;|\||&|or|and)$}{ $1 }i; $a =~ s{^ ; $}{; };
	    }
	  push @a, $a;
	}
    }
  return join '', @a;
}

=head2 loadmap_csv

$obj->loadmap_csv('license_map.csv', 'as');
$obj->loadmap_csv('synopsis.csv', 'lauaas#c');

Object method to 
load (or merge) contents of a CVS table into the object.
This uses a trivial csv parser. Field seperator must be ;
linebreaks are record seperators, and the first line is ignored, 
if it starts with '#'.
Fields can be surrounded by doublequotes, if a comma may be embedded.

The second parameter is a field template, defining what the meaning of the fields is.
 l    Long name (none or once). This is a speaking name of the License: Example "Creative Commons Attribution 1.0"
 a    Alias name (any number). Any other name by which the license is known: Example: "CC-BY 1.0"
 s    Short name (once). The canonical (unique) short license identifiner: Example: "CC-BY-1"
 u    URL (any). Multiple URLs can also be written in one filed, seperated by whitespace.
 #    License classification number (none or once). (1..5)
 c    Comment (none or once)
The default template is "as", an alias, followed by the canonical short name.
Empty fields are ignored, as well as fields that contian only one '?'. Thus you
can use records like 
"","Name"
to pass in a valid name without an alias.

See also new() for more details about mappings.

=cut
sub loadmap_csv
{
  my ($self,$file,$template) = @_;
  $template ||= "as";

  my @colum_types = split(//, $template);
  my $canon_idx = undef;
  for my $i (0..$#colum_types)
    {
      if ($colum_types[$i] eq 's')
        {
	  die "multiple canonical short name columns in template '$template'\n" if defined $canon_idx;
	  $canon_idx = $i;
	}
    }
  die "no canonical short name columns in template '$template'\n" unless defined $canon_idx;

  open my $in, "<", $file or croak "open($file) failed: $!\n";  
  my %opts = ( binary => 1, sep_char => ',', empty_is_undef => 1, eol => $/ );
  my $csv = Text::CSV->new(\%opts);
  my $line_no = 0;
  for (;;)
    {
      my $row = $csv->getline ($in);
      last if $csv->eof();
      if (!$line_no++)
	{
	  # be forgiving, if we have errors while parsing the first line.
	  # it may be a comment, or the seperator chacracter may be wrong.
	  if (my @err = $csv->error_diag())
	    {
	      my $line = $csv->error_input();
	      if ($err[0] == 2025)
		{
		  # no field seperator seen in the line
		  if ($opts{sep_char} eq ',')
		    {
		      $opts{sep_char} = ';';
                      POSIX::rewind $in;
		      $csv = Text::CSV->new(\%opts);
		      $line_no = 0;
		      next;
		    }
		  else
		    {
		      die "neither comma nor semicolon work as a field seperator.\n";
		    }
		}
	      elsif (defined($line) and $line =~ s{^#\s*}{})
		{
		  # can we do something with this header line now?
		  next;
		}
	      elsif ($err[0])
		{
		  # sometimes we come here, although there is no error.
		  # e.g. after restarting with changed sep_char,
		  print Dumper @err,  $line;
		  next;
		}
	      else
	        {
		  # "# heading","fields","...."
		  # "\160SPDX Full name","..."
		  # " SPDX Full name","..."
		  next if $row->[0] =~ m{^(\#|\W*SPDX)};	# heading
		}
	    }
	}

      next unless defined $row->[$canon_idx];	# a dummy entry?

      my $alias_count = 0;
      for my $i (0..$#colum_types)
        {
	  next unless defined $row->[$i];
	  next if $row->[$i] =~ m{^[\?\s-]+$};
	  if ($colum_types[$i] eq 'l' or 
	      $colum_types[$i] eq 'a')
	    {
	      $self->add_alias($row->[$i], $row->[$canon_idx]);
	      $alias_count++;
	    }
	  elsif($colum_types[$i] eq 'u')
	    {
	      $self->add_url($row->[$i], $row->[$canon_idx]);
	    }
	  elsif($colum_types[$i] eq 'c')
	    {
	      $self->set_compat_class($row->[$i], $row->[$canon_idx]);
	    }
	}
      unless ($alias_count)
        {
	  $self->add_alias(undef, $row->[$canon_idx]);
	}
      last if $csv->eof();
    }
  return $self;
}

sub _loadmap_csv_old
{
  my ($self,$file) = @_;

  open IN, "<", $file or croak "open($file) failed: $!\n";  
  my $linecount = 0;
  while (defined (my $line = <IN>))
    {
      chomp $line;
      next if $line =~ m{^#} and !$linecount++;
      if (($line =~ m{^"([^"]*)",\s*"([^"]*)"}) or
          ($line =~ m{^([^,"]*),\s*([^,]*)}))
	{
	  # actual mapping from old name to new name
	  $self->add_alias($1,$2);

	}
      elsif ($line =~ m{^("",\s*)?"([^"]*)"\s*$} or
             $line =~ m{^(,)?([^,"]*)\s*$})
	{
	  # simple mentioning of good ones, needs no mapping
	  $self->add_alias(undef,$2);
	}
      else
        {
	  die "$file:$linecount:\n\t$line\n not my csv syntax.";
	}
    }
  return $self;
}

=head1 AUTHOR

Juergen Weigert, C<< <jw at suse.de> >>

=head1 BUGS

This module defines a different syntax than 
http://rpmlint.zarb.org/cgi-bin/trac.cgi/browser/trunk/TagsCheck.py

Please report any bugs or feature requests to C<bug-rpm-license at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=License-Syntax>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc License::Syntax


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=License-Syntax>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/License-Syntax>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/License-Syntax>

=item * Search CPAN

L<http://search.cpan.org/dist/License-Syntax/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Juergen Weigert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of License::Syntax
