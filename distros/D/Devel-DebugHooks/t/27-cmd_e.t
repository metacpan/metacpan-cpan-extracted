#!/usr/bin/env perl


use strict;
use warnings;

use Test::More 'no_plan';
use Test::Output;
use FindBin qw/ $Bin /;  my $lib =  "-I$Bin/lib -I$Bin/../lib";
use Data::Section::Simple qw/ get_data_section /;

use Test::Differences;
unified_diff();
{
	no warnings qw/ redefine prototype /;
	*is =  \&eq_or_diff;
}



sub n {
	$_ =  join '', @_;

	s#\t#  #gm;
	s#([^/]*)(?:.*?)?([^/]+\.p(?:m|l))#$1xxx/$2#gm;

	$_;
}

sub nn {
	$_ =  n( @_ );

	s#( at ).*$#$1...#gm;    # Remove file:line info

	$_;
}


my $cmd;
my $script;
my $files =  get_data_section();


($script =  <<'PERL') =~ s#^\t##gm;
	$x =  1;
	$x =  [ a => 1 ];
	$x =  { a => 1 };
	@x =  ( a => 1 );
	%x =  ( a => 1 );
	2;
PERL

$cmd =  '2+2;e;q';
is
	n( `$^X $lib -d:DbInteract='$cmd' -e '$script'` )
	,$files->{ 'last eval' }
	,'Eval last expression if none supplied';

$cmd =  's;$x;e $x;$x++;e $x;s;e $x;s;e $x;s;@x;scalar @x;e \@x;s;%x;0+keys(%x);e \%x;';
is
	n( `$^X $lib -d:DbInteract='$cmd' -e '$script'` )
	,$files->{ 'eval' }
	,'Eval expressions at user context and dump them';



($script =  <<'PERL') =~ s#^\t##gm;
	sub t {
		1;
	}
	t( 1, [], {} );
PERL

$cmd =  's;scalar @_;e \@_';
is
	n( `$^X $lib -d:DbInteract='$cmd' -e '$script'` )
	,$files->{ '@_ not clash' }
	,'Debugger\'s @_ should not clash with client\'s one';



($script =  <<'PERL') =~ s#^\t##gm;
	$_ =  7;
	@_ = ( 1..$_ );
	1;
PERL

is
	n( `$^X $lib -d:DbInteract='s 2;e \$_;e \\\@_;q' -e '$script'` )
	,$files->{ '$_ not clash' }
	,"EXPR evaluation should see user's \@_ and \$_";



($script =  <<'PERL') =~ s#^\t##gm;
	1;
	use strict; use warnings;
	2;
PERL

$cmd =  '$#$DB::options{ undef }="undef"#3;4#$x#s#3;4#$x#q';
my $tmp =  nn( `$^X $lib -d:DbInteract='$cmd' -e '$script' 2>&1` );
$tmp =~ s# \(.*\)##g;             # Old perl has no elaborations
is
	$tmp
	,$files->{ 'pragma and warnings' }
	,'pragma and warnings from client\'s current scope should be applyed';

$cmd =  'n;e $y';
$tmp =  nn( `$^X $lib -d:DbInteract='$cmd' -e '$script' 2>&1` );
is
	+( $tmp =~ s#^ERROR: ##m )."\n"
	,$files->{ 'catch' }
	,'Catch error when expression evaluation dies';



__DATA__
@@ last eval
-e:0001  $x =  1;
4
4
@@ eval
-e:0001  $x =  1;
-e:0002  $x =  [ a => 1 ];
1
1
1
2
-e:0003  $x =  { a => 1 };
["a", 1]
-e:0004  @x =  ( a => 1 );
{ a => 1 }
-e:0005  %x =  ( a => 1 );
a 1
2
["a", 1]
-e:0006  2;
a 1
1
{ a => 1 }
@@ @_ not clash
-e:0004  t( 1, [], {} );
-e:0002    1;
3
[1, [], {}]
@@ $_ not clash
-e:0001  $_ =  7;
-e:0003  1;
7
[1 .. 7]
@@ pragma and warnings
Useless use of a constant in void context at ...
Useless use of a constant in void context at ...
Variable "$x" is not imported at ...
-e:0001  1;
undef
4
undef
-e:0003  2;
4
ERROR: Global symbol "$x" requires explicit package name at ...
@@ catch
1
