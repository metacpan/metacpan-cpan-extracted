use warnings;
use strict;
use Test::More;
use Image::SVG::Path qw/extract_path_info create_path_string/;

my $path1 = 'M6.93,103.36c3.61-2.46,6.65-6.21,6.65-13.29c0-1.68-1.36-3.03-3.03-3.03s-3.03,1.36-3.03,3.03s1.36,3.03,3.03,3.03C15.17,93.1,10.4,100.18,6.93,103.36z';

my @path_info = extract_path_info ($path1, {verbose => 0});

is ($path_info[0]->{type}, 'moveto');
is ($path_info[1]->{position}, 'relative');
is ($path_info[2]->{control2}->[1], -3.03);
is ($path_info[3]->{type}, 'smooth-cubic-bezier');

my $path2 = 'M2,3l4,5';

my @path2_info = extract_path_info ($path2);

is ($path2_info[0]->{type}, 'moveto');
is ($path2_info[1]->{type}, 'line-to');
is ($path2_info[1]->{position}, 'relative');
is ($path2_info[1]->{point}->[0], 4);
is ($path2_info[1]->{point}->[1], 5);

my @path2_info_abs = extract_path_info ($path2, {absolute => 1, verbose => 1, });

is ($path2_info_abs[1]->{point}->[0], 6);
is ($path2_info_abs[1]->{point}->[1], 8);

my $path3 = 'M6.93,103.36c3.61-2.46,6.65-6.21,6.65-13.29c0-1.68-1.36-3e-3-3.03-3.03s-3.03,1.36-3.03,3.03s1.36,3.03,3.03,3.03C15.17,93.1,10.4,100.18,6.93,103.36z';

#my $path3 = 'M6.93,103.36c0-1.68-1.36-3e-3-3.03-3.03z';

eval {
    my @path3_info = extract_path_info ($path3);
};
ok (! $@, "parse exponential");

my $implicit = 'M 1,1 -2,-6';
my @implicit_info;
eval {
    @implicit_info = extract_path_info ($implicit);
};
ok (! $@, "parse implicit OK");
my $implicit_info_keys = join '', map { $_->{svg_key} } @implicit_info;
is ($implicit_info_keys, 'ML', '... only added one SVG element');
is ($implicit_info[1]{type}, 'line-to', "Got lineto from implicit");
is ($implicit_info[1]{position}, "absolute", '... position absolute');
is_deeply ($implicit_info[1]{point}, [-2, -6], '... implicit lineto point');
my $lc_implicit = lc $implicit;
my @lc_implicit_info;
eval {
    @lc_implicit_info = extract_path_info ($lc_implicit);
};
ok (! $@, "parse implicit OK");
my $lc_implicit_info_keys = join '', map { $_->{svg_key} } @lc_implicit_info;
is ($lc_implicit_info_keys, 'ml', '... only added one SVG element');
is ($lc_implicit_info[1]{type}, 'line-to', "Got lineto from implicit");
is ($lc_implicit_info[1]{position}, "relative", "... position relative");
is_deeply ($implicit_info[1]{point}, [-2, -6], 'implicit lineto point');

my $arc = <<EOF;
M600,350 l 50,-25 
a25,25 -30 0,1 50,-25 l 50,-25 
a25,50 -30 0,1 50,-25 l 50,-25 
a25,75 -30 0,1 50,-25 l 50,-25 
a25,100 -30 0,1 50,-25 l 50,-25
EOF

my @arc_info;
eval {
    @arc_info = extract_path_info ($arc);
};
ok (! $@, "parse arc OK");
is ($arc_info[2]{y}, -25);

TODO: {
    local $TODO = 'put bugs here.';
}

my $has_h = 'M300,200 h-150 a150,150 0 1,0 150,-150 z';
my @has_h_info = extract_path_info ($has_h);
is ($has_h_info[1]{type}, 'horizontal-line-to');
is ($has_h_info[1]{x}, -150);
my $has_v = 'M275,175 v-150 a150,150 0 0,0 -150,150 z';
my @has_v_info = extract_path_info ($has_v);
is ($has_v_info[1]{type}, 'vertical-line-to');
is ($has_v_info[1]{y}, -150);

my $qt = 'M200,300 Q400,50 600,300 T1000,300';
my @qt_info = extract_path_info ($qt);
is_deeply ($qt_info[1]{control}, [400,50]);
is_deeply ($qt_info[2]{end}, [1000,300]);

# Cope with second "M" in path.

my $dblm = 'M 50 10 Q 0 70 50 130 M 200 10 Q 250 70 200 130';
my @dblm_info = extract_path_info ($dblm);
is ($dblm_info[2]{svg_key}, 'M', "Got second M in path");
is_deeply ($dblm_info[2]{point}, [200,10], "Got correct point value");
is_deeply ($dblm_info[1]{control}, [0,70]);
is_deeply ($dblm_info[1]{end}, [50,130]);
is_deeply ($dblm_info[3]{control}, [250,70]);
is_deeply ($dblm_info[3]{end}, [200,130]);

# Cope with second "M" in path, with extra linetos.

my $dblm2 = 'M 50 10 Q 0 70 50 130 M 200 10 200 20';
@dblm_info = extract_path_info ($dblm2);
is ($dblm_info[2]{svg_key}, 'M', "Got second M in path");
my $dblm_info_keys = join '', map { $_->{svg_key} } @dblm_info;
is        ($dblm_info_keys, 'MQML', 'Checking inserted implict lineto sequence');
is_deeply ($dblm_info[2]{point}, [200,10], "Got correct point value");
is        ($dblm_info[3]{name},  'lineto', "Inserted implicit moveto");
is_deeply ($dblm_info[3]{point}, [200,20], "... Got correct point value");

# Handle more than one closepath

my $zs_path = <<EOPATH;
M 10,10
v 5
h 5
v -5
z
m 10,10
v 5
h 5
v -5
z
EOPATH

@path_info = extract_path_info($zs_path, {absolute => 1, verbose => 1, });
is_deeply $path_info[5]->{point}, [20, 20], 'Relative moveto obeyed after closepath'; 


my $churchpath = 'M134,25v20h22v15h-22v30l90,63v3h-12v53h-38v-53l-49,-35l-49,35v53h-38v-53h-12v-3l90,-63v-30h-22v-15h22v-20zM103,207v-35a23,20 0 0,1 44,0 v35z';
my @churchinfo;
{
    local $SIG{__WARN__} = sub { die; };
    eval {
	@churchinfo = extract_path_info ($churchpath, {
	    absolute => 1,
	    no_shortcuts => 1,
	},);
    };
    ok (! $@, "no warnings with church path");
}
my $path = create_path_string (\@churchinfo);
like ($path, qr/A\s+23\.0+,20\.0+,0\.0+,0\.0+,1\.0+,147\.0+,172\.0+/,
      "arc in path reproduced OK");
#};

# The numbers in the following path weren't being parsed correctly due
# to a bug where the correct number regex was not being used to split
# the string of numbers into numbers.

#<svg width="32" height="32" viewbox="-2 -2 32 32" class="inline-share-twitter__svg inline-icon__svg">
#<path d="M21.3 10.5v.5c0 4.7-3.5 10.1-9.9 10.1-2 0-3.8-.6-5.3-1.6.3 0 .6.1.8.1 1.6 0 3.1-.6 4.3-1.5-1.5 0-2.8-1-3.3-2.4.2 0 .4.1.7.1l.9-.1c-1.6-.3-2.8-1.8-2.8-3.5.5.3 1 .4 1.6.4-.9-.6-1.6-1.7-1.6-2.9 0-.6.2-1.3.5-1.8 1.7 2.1 4.3 3.6 7.2 3.7-.1-.3-.1-.5-.1-.8 0-2 1.6-3.5 3.5-3.5 1 0 1.9.4 2.5 1.1.8-.1 1.5-.4 2.2-.8-.3.8-.8 1.5-1.5 1.9.7-.1 1.4-.3 2-.5-.4.4-1 1-1.7 1.5z"/>
#</svg>

my $path22 = 'M21.3 10.5v.5c0 4.7-3.5 10.1-9.9 10.1-2 0-3.8-.6-5.3-1.6.3 0 .6.1.8.1 1.6 0 3.1-.6 4.3-1.5-1.5 0-2.8-1-3.3-2.4.2 0 .4.1.7.1l.9-.1c-1.6-.3-2.8-1.8-2.8-3.5.5.3 1 .4 1.6.4-.9-.6-1.6-1.7-1.6-2.9 0-.6.2-1.3.5-1.8 1.7 2.1 4.3 3.6 7.2 3.7-.1-.3-.1-.5-.1-.8 0-2 1.6-3.5 3.5-3.5 1 0 1.9.4 2.5 1.1.8-.1 1.5-.4 2.2-.8-.3.8-.8 1.5-1.5 1.9.7-.1 1.4-.3 2-.5-.4.4-1 1-1.7 1.5z';

my @info2 = extract_path_info ($path22);#, {verbose => 1});
ok (@info2);


done_testing ();
exit;
