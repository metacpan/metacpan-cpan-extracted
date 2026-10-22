#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Basic ();
use EO::BasicX ();
use EO::Twin qw(imp describe twin_is fresh);

no strict 'refs';

ok( defined &EO::Basic::import, 'use Ex::Op installs import' );
is( \&EO::Basic::import, \&Ex::Op::import, 'and it is the one import' );

{
    my $p = fresh();
    is( imp('EO::Basic', $p), undef, 'no list imports' );
    is( \&{"${p}::f"}, \&EO::Basic::f, '@EXPORT by default' );
    ok( !defined &{"${p}::g"}, '@EXPORT_OK not by default' );
}

{
    my $p = fresh();
    is( imp('EO::Basic', $p, qw(g $s @a %h *gl &amp)), undef, 'every sigil' );
    is( \&{"${p}::g"},   \&EO::Basic::g,   'bare name is the sub' );
    is( \${"${p}::s"},   \$EO::Basic::s,   '$ is the scalar' );
    is( \@{"${p}::a"},   \@EO::Basic::a,   '@ is the array' );
    is( \%{"${p}::h"},   \%EO::Basic::h,   '% is the hash' );
    is( \&{"${p}::amp"}, \&EO::Basic::amp, '& is the sub' );
    is( *{"${p}::gl"}{CODE},   \&EO::Basic::gl, '* brings the whole glob: CODE' );
    is( *{"${p}::gl"}{SCALAR}, \$EO::Basic::gl, '* brings the whole glob: SCALAR' );
    ok( !defined &{"${p}::f"}, 'a list replaces @EXPORT' );
}

{
    my $p = fresh();
    is( imp('EO::Basic', $p, qw(f g)), undef, 'a name in @EXPORT can be asked for' );
    is( \&{"${p}::f"}, \&EO::Basic::f, '... and is imported' );
}

{
    my $p = fresh();
    is( imp('EO::Basic', $p, qw(ghost)), undef, 'a name with no sub' );
    ok( exists &{"${p}::ghost"} && !defined &{"${p}::ghost"}, 'imports a stub' );
    ok( exists &EO::Basic::ghost, 'and declares it in the exporter' );
}

{
    my $p = fresh();
    is( imp('EO::Basic', $p, qw(Other::thing)), undef, 'a qualified name' );
    is( &{"${p}::Other::thing"}(), 'pkg thing', 'is joined to both packages' );
}

{
    my $ok = eval q{
        package EO::Strict;
        use strict;
        use EO::Basic qw($s @a %h);
        $s = 'set'; push @a, 3; $h{x} = 1;
        1;
    };
    ok( $ok, 'imported variables satisfy strict vars' ) or diag $@;
    is( $EO::Basic::s, 'set', '... and are the exporter\'s' );
    $EO::Basic::s = 's';
    pop @EO::Basic::a;
    delete $EO::Basic::h{x};
}

{
    my $got = eval q{
        package EO::Override;
        use EO::Basic qw(length);
        length('abc');
    };
    is( $got, 'mine', 'an imported sub overrides a builtin' );
}

{
    my $p = fresh();
    is( imp('EO::Basic', $p, '0.5'), undef, 'a version alone' );
    is( \&{"${p}::f"}, \&EO::Basic::f, '... imports @EXPORT' );

    $p = fresh();
    is( imp('EO::Basic', $p, '0.5', ''), undef, 'a version and an empty string' );
    ok( !defined &{"${p}::f"}, '... imports nothing' );

    $p = fresh();
    is( imp('EO::Basic', $p, '0.5', 'g'), undef, 'a version and a name' );
    ok( defined &{"${p}::g"}, '... imports the name' );

    $p = fresh();
    like( imp('EO::Basic', $p, '9'), qr/^EO::Basic version 9 required--this is only version 1\.00/,
          'a version too high dies' );
}

{
    package EO::Wrapper;
    sub import {
        local $Ex::Op::ExportLevel = 1;
        EO::Basic->import(@_[1 .. $#_]);
    }
}
{
    my $p = fresh();
    eval "package $p; sub run { EO::Wrapper->import('g') } run(); 1" or die $@;
    ok( defined &{"${p}::g"}, '$Ex::Op::ExportLevel exports a level up' );
}

{
    my $p = fresh();
    is( imp('EO::Basic', $p, qw(g)), undef, 'first import' );
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    {
        no warnings;
        *{"${p}::g"} = sub { 'other' };
    }
    is( imp('EO::Basic', $p, qw(g)), undef, 'importing over a different sub' );
    is( $warn, '', 'is quiet without -w, as Exporter is' );
    {
        local $^W = 1;
        no warnings;
        *{"${p}::g"} = sub { 'other' };
        imp('EO::Basic', $p, qw(g));
    }
    like( $warn, qr/^Subroutine \Q${p}\E::g redefined at /, 'warns under -w' );
}

twin_is( 'nothing asked',          );
twin_is( 'every sigil',            qw(g $s @a %h *gl &amp) );
twin_is( 'a stub',                 qw(ghost) );
twin_is( 'a qualified name',       qw(Other::thing) );
twin_is( 'a version alone',        '0.5' );
twin_is( 'a version and nothing',  '0.5', '' );
twin_is( 'a version and a name',   '0.5', 'g' );
twin_is( 'a version too high',     '9' );
twin_is( 'repeated names',         qw(g g &g) );

done_testing;
