#!/usr/bin/perl;
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use IO qw/Handle File Pipe/;

my $CLASS = 'Devel::Memalyzer';

# A newer Test::More would give us done_testing()
eval { tests(); 1 } || ok( 0, $@ );
cleanup();

sub cleanup {
    unlink( 't/test_out' ); #Do not care about errors.
    unlink( 't/test_out.raw' ); #Do not care about errors.
    unlink( 't/test_out.head' ); #Do not care about errors.
}

sub fork_do(&) {
    my $pid = fork();
    unless ( $pid ) {
        shift->();
        exit;
    }
    waitpid( $pid, 0 );
}

{
    package Devel::Memalyzer::Plugin::Test;
    use strict;
    use warnings;

    use base 'Devel::Memalyzer::Base';

    sub collect {
        return (
            a => 'a',
            b => 'b',
            c => 'c',
        );
    }
}

sub memalyzer { Devel::Memalyzer->singleton }

sub tests {
    use_ok( $CLASS );
    can_ok( $CLASS, qw/output columns headers/ );
    can_ok( __PACKAGE__, 'memalyzer' );

    $CLASS->init();
    isa_ok( $Devel::Memalyzer::SINGLETON, $CLASS );
    isa_ok( memalyzer(), $CLASS );
    is( memalyzer(), $Devel::Memalyzer::SINGLETON, "singleton as interface" );

    my $one = $CLASS->new(
        plugins => [ 'Devel::Memalyzer::Plugin::Test' ],
        output  => 't/test_out',
    );
    throws_ok { $one->plugins }
        qr{Can't locate Devel/Memalyzer/Plugin/Test\.pm in},
        "Invalid plugin dies";

    # Pretend its already loaded
    $INC{ 'Devel/Memalyzer/Plugin/Test.pm' } = __FILE__;
    is_deeply(
        [ $one->plugins ],
        [ Devel::Memalyzer::Plugin::Test->new ],
        "Got initialized plugin"
    );
    is( $one->plugins, $one->plugins, "Only init plugins once" );

    $one->add_column( d => sub { 'd' . shift });
    $one->add_column( e => sub { 'e' . shift });
    $one->add_column( f => sub { 'f' . shift });
    is_deeply(
        $one->columns,
        {
            # Cannot really deeply a codref, this is good enough.
            d => $one->columns->{ d },
            e => $one->columns->{ e },
            f => $one->columns->{ f },
        },
        "Added columns"
    );

    $one->del_column( 'd' );
    is_deeply(
        $one->columns,
        {
            # Cannot really deeply a codref, this is good enough.
            e => $one->columns->{ e },
            f => $one->columns->{ f },
        },
        "removed column"
    );

    is_deeply(
        { $one->collect_columns(1234) },
        {
            e => 'e1234',
            f => 'f1234',
        },
        "Collected columns"
    );

    cleanup();
    ok( ! -e 't/test_out', "no test out file" );
    my $handles_as_ref = sub {[ $one->output_handles ]};
    is(
        $handles_as_ref->()->[0],
        $handles_as_ref->()->[0],
        "Raw handle stored"
    );
    is(
        $handles_as_ref->()->[1],
        $handles_as_ref->()->[1],
        "Header handle stored"
    );

    open( my $combine, '>', 't/test_out' );
    print $combine 'I exist';
    close( $combine );

    throws_ok { $CLASS->new( output => 't/test_out' )->output_handles }
        qr{Refusing to override exisiting output file: 't/test_out'},
        "Do not override output";

    pipe( my $headread, my $headwrite ) || die( "Cannot create pipe: $!" );
    pipe( my $rawread, my $rawwrite ) || die( "Cannot create pipe: $!" );
    for ( $headread, $headwrite, $rawread, $rawwrite ) {
        $_->blocking( 0 );
        $_->autoflush( 1 );
    }

    $one->{ output_handles } = [ $rawwrite, $headwrite ];

    is_deeply(
        $handles_as_ref->(),
        [ $rawwrite, $headwrite ],
        "Replaced handles"
    );

    fork_do { $one->sync_headers({ a => 'b', c => 'd' }) };
    is( <$headread>, "c,a\n", "Initial header" );
    is( <$rawread>, undef, "No raw" );

    $one->headers(['c','a']);

    fork_do { $one->sync_headers({ a => 'b', c => 'd' }) };
    is( <$headread>, undef, "No change" );
    is( <$rawread>, undef, "No raw" );

    fork_do { $one->sync_headers({ a => 'b', c => 'd', e => 'f' }) };
    is( <$headread>, "e,c,a\n", "New header" );
    is( <$rawread>, "\n", "Seperator in raw" );

    # This will take priority over the real timestamp
    $one->add_column( timestamp => sub { shift });
    $one->headers(undef);
    fork_do { $one->record(12345) };
    my @headers = <$headread>;
    my @raw = <$rawread>;

    chomp( @headers, @raw );

    is_deeply(
        \@headers,
        [ 'timestamp,f,e,c,b,a' ],
        "Correct header"
    );

    is_deeply(
        \@raw,
        [ "12345,f12345,e12345,c,b,a" ],
        "Got data"
    );
}

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

