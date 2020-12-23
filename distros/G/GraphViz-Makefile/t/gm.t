# -*- perl -*-

# Author: Slaven Rezic

use strict;
use warnings;
use FindBin;

use GraphViz::Makefile;
use File::Spec::Functions qw(file_name_is_absolute);
use Test::More;
use Test::Snapshot;

my $recmake_fsmap = make_fsmap({
  Makefile => [ 1, "MK=make\nall: bar sany\nsany:\n\tcd subdir && \$(MK)\n\tsay hi\n"],
  'subdir/Makefile' => [ 1, "all: sbar sfoo\n\tcd subsubdir && make\n" ],
  'subdir/subsubdir/Makefile' => [ 1, "all:\n\techo L3\n" ],
});
my $recmake = Make->new(FSFunctionMap => $recmake_fsmap);
$recmake->parse;
my $make_subst = <<'EOF';
DATA=data

model: $(DATA)/features.tab
	perl prog1.pl $<

$(DATA)/features.tab: otherfile
	perl prog3.pl $< > $@
EOF
my @makefile_tests = (
    [$recmake, '', {}, 'recmake'],
    ["$FindBin::RealBin/../Makefile", '', {}, undef],
    [\<<'EOF', '', {}, 'model_expected'],
model: data/features.tab
	perl prog1.pl $<

data/features.tab: otherfile
	perl prog3.pl $< > $@
EOF
    [\$make_subst, '', {}, 'model_expected'],
    [\$make_subst, 'test', {}, 'modelprefix_expected'],
    [\<<'EOF', '', {}, 'mgv_expected'],
all: foo
all: bar
	echo hallo perl\lib double\\l

any second: foo hiya
	echo larry
	echo howdy
any: blah blow

foo:: blah boo
	echo Hi
foo:: howdy buz
	echo Hey
EOF
    [\<<'EOF', '', {}, 'mgvnorecipe_expected'],
all: foo
all: bar

any: foo hiya
	echo larry
	echo howdy
any: blah blow

foo:: blah boo
	echo Hi
foo:: howdy buz
	echo Hey
EOF
);

SKIP: {
    skip("tkgvizmakefile test only with INTERACTIVE=1 mode", 1) if !$ENV{INTERACTIVE};
    system($^X, qw(-Ilib scripts/tkgvizmakefile));
    is $?, 0, "Run tkgvizmakefile";
}

my $is_in_path_display = is_in_path("display");
for my $def (@makefile_tests) {
    my ($makefile, $prefix, $extra, $expected) = @$def;
    diag "Makefile: " . join '', explain $makefile;
    my $gm = GraphViz::Makefile->new(undef, $makefile, $prefix, %$extra);
    isa_ok($gm, "GraphViz::Makefile");
    if (defined $expected) {
        my $g = $gm->generate_graph;
        my %e;
        $e{$_->[0]}{$_->[1]} = $g->get_edge_attributes(@$_)||{} for $g->edges;
        my %n = map +($_=>$g->get_vertex_attributes($_)), $g->vertices;
        is_deeply_snapshot [ \%n, \%e ], $expected;
    }
    SKIP: {
        skip "not making PNG as no 'expected'", 3 if !$expected;
        $gm->generate;
        is_deeply_snapshot $gm->GraphViz->dot_input, "$expected DOT";
        my $png = eval { $gm->GraphViz->run(format=>"png")->dot_output };
        skip "Cannot create png file: $@", 2 if !$png;
        require File::Temp;
        my ($fh, $filename) = File::Temp::tempfile(SUFFIX => ".png",
                                              UNLINK => 1);
        print $fh $png;
        close $fh;
        ok -s $filename, "Non-empty png file";
        skip("Display png file only with INTERACTIVE=1 mode", 1) if !$ENV{INTERACTIVE};
        skip("ImageMagick/display not available", 1) if !$is_in_path_display;
        system("display", $filename);
        pass("Displayed...");
    }
}

done_testing;

sub make_fsmap {
    my ($vfs) = @_;
    my %fh2file_tuple;
    return {
        glob => sub {
            my @results;
            for my $subpat ( split /\s+/, $_[0] ) {
                $subpat =~ s/\*/.*/g;    # ignore ?, [], {} for now
                ## no critic (BuiltinFunctions::RequireBlockGrep)
                push @results, grep /^$subpat$/, sort keys %$vfs;
                ## use critic
            }
            return @results;
        },
        fh_open => sub {
            die "@_: No such file or directory" unless exists $vfs->{ $_[1] };
            my $file_tuple = $vfs->{ $_[1] };
            open my $fh, "+$_[0]", \$file_tuple->[1];
            $fh2file_tuple{$fh} = $file_tuple;
            return $fh;
        },
        fh_write      => sub { my $fh = shift; $fh2file_tuple{$fh}[0] = time; print {$fh} @_ },
        file_readable => sub { exists $vfs->{ $_[0] } },
        mtime         => sub { ( $vfs->{ $_[0] } || [] )->[0] },
        is_abs        => sub { $_[0] =~ /^\// },
    };
}

# REPO BEGIN
# REPO NAME is_in_path /home/e/eserte/work/srezic-repository 
# REPO MD5 81c0124cc2f424c6acc9713c27b9a484

=head2 is_in_path($prog)

=for category File

Return the pathname of $prog, if the program is in the PATH, or undef
otherwise.

DEPENDENCY: file_name_is_absolute

=cut

sub is_in_path {
    my ($prog) = @_;
    return $prog if (file_name_is_absolute($prog) and -f $prog and -x $prog);
    require Config;
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
        if ($^O eq 'MSWin32') {
            # maybe use $ENV{PATHEXT} like maybe_command in ExtUtils/MM_Win32.pm?
            return "$_\\$prog"
                if (-x "$_\\$prog.bat" ||
                    -x "$_\\$prog.com" ||
                    -x "$_\\$prog.exe" ||
                    -x "$_\\$prog.cmd");
        } else {
            return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
        }
    }
    undef;
}
# REPO END

