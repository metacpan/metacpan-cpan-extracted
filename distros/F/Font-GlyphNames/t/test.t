#!perl -w

use Test::More tests => 152;
use strict;
use utf8;



#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'Font::GlyphNames' => qw "name2str name2ord str2name
                                         ord2name ord2ligname" }


#--------------------------------------------------------------------#
# Tests 2-4: Object creation

ok our $gn = Font::GlyphNames->new, 'Create Font::GlyphNames object';
isa_ok $gn, 'Font::GlyphNames';
isa_ok my $gn2 =( new Font::GlyphNames{substitute=>'<^>'}),
	'Font::GlyphNames', 'The other object';


#--------------------------------------------------------------------#
# Tests 5-70: name2str

# Examples from "Unicode and Glyph Names"
our %examples = (
	 Lcommaaccent => "\x{13b}",
	 uni20AC0308  => "\x{20ac}\x{308}",
	 u1040C       => "\x{1040C}",
	 uniD801DC0C  =>  undef,
	 uni20ac      =>  undef,
	'Lcommaaccent_uni20AC0308_u1040C.alternate' => "\x{13B}\x{20AC}\x{308}\x{1040C}",
	 uni013B      => "\x{13b}",
	 u013B        => "\x{13b}",
	 foo          =>  undef,
	'.notdef'     =>  undef,
);

our(@input,@output);
for(sort keys %examples) {
	push @input, $_;
	push @output, $examples{$_};
}

our $x = 1;
for (@input) {
	is_deeply scalar(name2str $_),       $examples{$_} ,
		"name2str - Example $x, function, scalar context";
	is_deeply       [name2str $_],      [$examples{$_}],
		"name2str - Example $x, function, list context";
	is_deeply scalar($gn->name2str($_)), $examples{$_} ,
		"name2str - Example $x, OO, scalar context";
	is_deeply       [$gn->name2str($_)],[$examples{$_}],
		"name2str - Example $x, OO, list context";
	is_deeply       [$gn2->name2str($_)],[$examples{$_}||'<^>'],
		"name2str - Example $x with substitute, list context";
	is_deeply scalar $gn2->name2str($_),  $examples{$_}||'<^>',
		"name2str - Example $x with substitute, scalar context";
	++$x;
}
no warnings 'uninitialized';
my $output = join '', @output;
my @transmogrified_output = map $_||'<^>', @output;
is_deeply       [name2str      @input],  \@output,   'All examples as a list';
is_deeply       [$gn->name2str(@input)], \@output,   'All examples as a list (OO)';
is_deeply       [$gn2->name2str(@input)], \@transmogrified_output,
	'name2str - All examples as a list (with substitute)';
is_deeply scalar(name2str      @input),  $output,
	'name2str - All examples as a list (scalar context)';
is_deeply scalar($gn->name2str(@input)), $output,
	'name2str - All examples as a list (OO, scalar context)';
is_deeply scalar($gn2->name2str(@input)), join('', @transmogrified_output),
	'name2str - All examples as list (w/substitute, scalar context)';


#--------------------------------------------------------------------#
# Tests 71 & 72: Custom file (instead of using a file, I'm going to
#                use STDIN input and pass '-' as the file name)

pipe STDIN, WH;
print WH <<END;

# IGNORE THIS LINE
 # AND THIS ONE

bill;2603
bob; 3020 

ChiRo;2627
snip-snip;2702 2701 2702 2701

END
close WH;

ok($gn = (new Font::GlyphNames '-'), 'Create object with custom glyph list file') or diag($@);
is_deeply [$gn->name2str(qw<bill bob ChiRo snip-snip>)], ["\x{2603}","\x{3020}","\x{2627}","\x{2702}\x{2701}"x2], 'custom object -> name2str';

#--------------------------------------------------------------------#
# Tests 73 & 74: Object without glyph list

isa_ok $gn = (new Font::GlyphNames{lists=>[]}), 'Font::GlyphNames',
	'The object without a glyph list';
is_deeply [$gn->name2str(qw(
	 Lcommaaccent
	 uni20AC0308 
	 u1040C      
	 uniD801DC0C 
	 uni20ac     
	 Lcommaaccent_uni20AC0308_u1040C.alternate
	 uni013B  
	 u013B    
	 foo      
	.notdef
))], [
	undef, "\x{20ac}\x{308}","\x{1040C}", undef, undef,
	"\x{20AC}\x{308}\x{1040C}","\x{13b}","\x{13b}",undef,undef,
], 'name2str without glyph list';


#--------------------------------------------------------------------#
# Tests 75-7: ‘search_inc’ and ‘list’ options

use lib 't';
isa_ok $gn = Font::GlyphNames->new({list => 'test.txt', search_inc => 1})
	|| diag($@),
	'Font::GlyphNames', 'An object that tests search_inc';
is_deeply [$gn->name2str(qw<bill bob ChiRo snip-snip>)], ["\x{2603}","\x{3020}","\x{2627}","\x{2702}\x{2701}"x2], 'search_inc';

new Font::GlyphNames { search_inc => 1, list => 'bad file' };
like $@,
    qr-^Font::GlyphNames:\ Can't\ locate\ .*?Font.*?GlyphNames.*?bad\ file
       .*?\ in\ \@INC-x,
	'$@ after a glyph list is not found in @INC';
	# during development the file name was not making it into the msg


#--------------------------------------------------------------------#
# Tests 78 & 79: name2str’s uXXXXX validation

is name2str('u0D800'), undef, 'name2str u0D800';
is name2str('u120000'), undef, 'name2str u120000';


#--------------------------------------------------------------------#
# Tests 80-102: name2ord

# Examples from "Unicode and Glyph Names"
%examples = (
	 Lcommaaccent => [0x13b],
	 uni20AC0308  => [0x20ac,0x308],
	 u1040C       => [0x1040C],
	 uniD801DC0C  => [-1],
	 uni20ac      => [-1],
	'Lcommaaccent_uni20AC0308_u1040C.alternate' =>
		[0x13B,0x20AC,0x308,0x1040C],
	 uni013B      => [0x13b],
	 u013B        => [0x13b],
	 foo          => [-1],
	'.notdef'     => [-1],
);

is name2ord("Lcommaaccent"), 0x13b, 'name2ord in scalar context';

(@input,@output) = ();
for(sort keys %examples) {
	push @input, $_;
	push @output, $examples{$_};
}

$gn = new Font::GlyphNames;

$x = 1;
for (@input) {
	is_deeply     [name2ord $_],      $examples{$_},
		"name2ord example $x, function, list context";
	is_deeply     [$gn->name2ord($_)],$examples{$_},
		"name2ord example $x, OO, list context";
	++$x;
}
@output = map @$_, @output;
is_deeply[name2ord      @input],\@output, 
	'name2ord - all examples as a list';
is_deeply[$gn->name2ord(@input)],\@output,
	'name2ord - all examples as a list (OO)';


#--------------------------------------------------------------------#
# Tests 103 & 104: name2ord and name2str’s hex digit matching

is name2str('uni௫௪௩௨'), undef, 'name2str uni+Tamil digits';
is name2ord('uni๕๔๓๒'), -1, 'name2ord uni+Thai digits';

#--------------------------------------------------------------------#
# Tests 105-24: str2name

%examples = (
	"\x{13b}"                 => 'Lcedilla',
	'ft'                      => 'f_t',
	"\x{05D3}\x{05B2}"        => 'dalethatafpatah',
	"\x{20ad}\x{326}\x{346}"  => 'uni20AD03260346',
	"\x{20ad}\x{326}"         => 'uni20AD0326',
	"\x{20ad}"                => 'uni20AD',
	''                        => '.notdef',
	"\x{1040C}"               => 'u1040C',
	"\x{13B}\x{20AD}\x{326}\x{1040C}" =>
		'Lcedilla_uni20AD0326_u1040C',
);

(@input,@output) = ();
for(sort keys %examples) {
	push @input, $_;
	push @output, $examples{$_};
}

$gn = new Font::GlyphNames;

$x = 1;
for (@input) {
	is_deeply     str2name($_),      $examples{$_},
		"str2name example $x, function, scalar context";
	is_deeply     $gn->str2name($_),$examples{$_},
		"str2name example $x, OO, scalar context";
	++$x;
}
is_deeply[str2name      @input],\@output, 
	'str2name - all examples as a list';
is_deeply[$gn->str2name(@input)],\@output,
	'str2name - all examples as a list (OO)';


#--------------------------------------------------------------------#
# Tests 125-32: ord2name

%examples = (
	0x13b                 => 'Lcedilla',
	0x20ad                => 'uni20AD',
	0x1040C               => 'u1040C',
);

(@input,@output) = ();
for(sort keys %examples) {
	push @input, $_;
	push @output, $examples{$_};
}

$gn = new Font::GlyphNames;

$x = 1;
for (@input) {
	is_deeply     ord2name($_),      $examples{$_},
		"ord2name example $x, function, scalar context";
	is_deeply     $gn->ord2name($_),$examples{$_},
		"ord2name example $x, OO, scalar context";
	++$x;
}
is_deeply[ord2name      @input],\@output, 
	'ord2name - all examples as a list';
is_deeply[$gn->ord2name(@input)],\@output,
	'ord2name - all examples as a list (OO)';


#--------------------------------------------------------------------#
# Tests 133-52: ord2ligname

my @examples = (
	[[0x13b]                 => 'Lcedilla'],
	[[102,116]               => 'f_t'],
	[[0x05D3,0x05B2]         => 'dalethatafpatah'],
	[[0x20ad,0x326,0x346]     => 'uni20AD03260346'],
	[[0x20ad,0x326]            => 'uni20AD0326'],
	[[0x20ad]                   => 'uni20AD'],
	[[]                         => '.notdef'],
	[[0x1040C]                   => 'u1040C'],
	[[0x13B,0x20AD,0x326,0x1040C] => 'Lcedilla_uni20AD0326_u1040C'],
	[[0x13b,102,116,0x05D3,0x05B2,0x20ad,0x326,0x346,0x1040C] =>
		'Lcedilla_f_t_afii57667_afii57800_uni20AD03260346_u1040C'],
);

$gn = new Font::GlyphNames;

$x = 1;
for (@examples) {
	is     ord2ligname(@{$$_[0]}),      $$_[1],
		"ord2ligname example $x, function, scalar context";
	is     $gn->ord2ligname(@{$$_[0]}), $$_[1],
		"ord2ligname example $x, OO, scalar context";
	++$x;
}
