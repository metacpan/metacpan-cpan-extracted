######################################################################
#
# 0013-jinja2-compat.t -- Jinja2 compatibility fixes in 0.02
#
# Tests new(\%args), truth of empty [] and {}, and string ordering
# comparison of non-numeric operands.
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec;
use HP::Handy;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c?($PASS++,print "ok $T - $n\n"):($FAIL++,print "not ok $T - $n\n") }
sub is { my($g,$e,$n)=@_; $T++;
    defined($g) && "$g" eq "$e"
        ? ($PASS++, print "ok $T - $n\n")
        : ($FAIL++, print "not ok $T - $n  (got='".( defined $g?$g:'undef')."', exp='$e')\n") }

# Perl 5.005_03 compatible temp directory (no File::Temp)
my @_tmpdirs;
my $_tmpdir_seq = 0;
sub _make_tmpdir {
    my $base = File::Spec->tmpdir();
    my $dir;
    my $try = 0;
    while ($try < 100) {
        $_tmpdir_seq++;
        $dir = File::Spec->catfile($base,
            "hpt_$$" . "_" . $_tmpdir_seq . "_" . $try);
        last if mkdir($dir, 0700);
        $try++;
    }
    die "cannot create tmpdir under $base: $!" unless defined $dir && -d $dir;
    push @_tmpdirs, $dir;
    return $dir;
}
END {
    for my $d (reverse @_tmpdirs) {
        next unless defined $d && -d $d;
        opendir(RMDIR_DH, $d) or next;
        my @entries = grep { $_ ne '.' && $_ ne '..' } readdir(RMDIR_DH);
        closedir(RMDIR_DH);
        unlink File::Spec->catfile($d, $_) for @entries;
        rmdir $d;
    }
}

sub wf {
    my ($dir, $name, $content) = @_;
    open(APIWF, '>' . File::Spec->catfile($dir, $name)) or die $!;
    print APIWF $content;
    close APIWF;
}

my @tests = (

    # --- new(\%args) ---
    sub {
        my $hp = HP::Handy->new({ auto_escape => 0 });
        is($hp->render_string('{{ x }}', {x=>'<b>'}), '<b>',
           'new(\%args): auto_escape => 0 honoured');
    },
    sub {
        my $dir = _make_tmpdir();
        wf($dir, 'a.html', 'Hello {{ name }}');
        my $hp = HP::Handy->new({ template_dir => $dir });
        my $r = eval { $hp->render_file('a.html', {name=>'W'}) };
        is($r, 'Hello W',
           'new(\%args): template_dir honoured');
    },
    sub {
        my $w = '';
        local $SIG{__WARN__} = sub { $w .= $_[0] };
        my $hp = HP::Handy->new({ trim_blocks => 1 });
        is($w, '', 'new(\%args): no warning');
    },
    sub {
        my $hp = HP::Handy->new(auto_escape => 0);
        is($hp->{auto_escape}, 0, 'new(list): still works');
    },

    # --- empty list / dict are false ---
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% if x %}T{% else %}F{% endif %}', {x=>[]}),
           'F', 'if: [] is false');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% if x %}T{% else %}F{% endif %}', {x=>{}}),
           'F', 'if: {} is false');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% if x %}T{% else %}F{% endif %}', {x=>[0]}),
           'T', 'if: [0] is true');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% if not x %}T{% else %}F{% endif %}', {x=>[]}),
           'T', 'not: not [] is true');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% if x and y %}T{% else %}F{% endif %}', {x=>1,y=>{}}),
           'F', 'and: 1 and {} is false');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% if x or y %}T{% else %}F{% endif %}', {x=>[],y=>{}}),
           'F', 'or: [] or {} is false');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{{ "T" if x else "F" }}', {x=>[]}),
           'F', 'inline if: [] is false');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% for r in rows if r %}{{ loop.index }}{% endfor %}',
                              {rows=>[[], [1], {}, {a=>1}]}),
           '12', 'for-if: [] and {} are skipped');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{% if x %}T{% else %}F{% endif %}', {x=>'0'}),
           'F', 'if: "0" is false (Perl scalar)');
    },

    # --- ordering comparison ---
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{{ "T" if a < b else "F" }}',
                              {a=>'2026-09-30', b=>'2026-10-01'}),
           'T', '<: dates compare as strings');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{{ "T" if a > b else "F" }}', {a=>'b', b=>'a'}),
           'T', '>: "b" > "a"');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{{ "T" if a <= b else "F" }}', {a=>5, b=>10}),
           'T', '<=: 5 <= 10 numerically');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{{ "T" if a <= b else "F" }}', {a=>'5', b=>'10'}),
           'T', '<=: "5" <= "10" numerically (numeric strings)');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{{ "T" if a >= b else "F" }}', {a=>'1.5', b=>'1.50'}),
           'T', '>=: "1.5" >= "1.50"');
    },
    sub {
        my $w = '';
        local $SIG{__WARN__} = sub { $w .= $_[0] };
        my $hp = HP::Handy->new();
        $hp->render_string('{{ "T" if a < b else "F" }}', {a=>'x', b=>'y'});
        is($w, '', '<: no numeric warning on strings');
    },
    sub {
        my $hp = HP::Handy->new();
        is($hp->render_string('{{ "T" if a == b else "F" }}', {a=>'1.50', b=>'1.5'}),
           'T', '==: "1.50" == "1.5"');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
print "# $PASS passed, $FAIL failed\n";
