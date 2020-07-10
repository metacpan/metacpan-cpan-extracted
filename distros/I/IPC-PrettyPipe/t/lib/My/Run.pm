package My::Run;

use Test2::V0;
use Test2::API;

use File::Slurper qw[ read_text ];
use File::Spec::Functions qw[ rel2abs ];

use Exporter 'import';

our @EXPORT = qw[ expect_files test_run ];

sub expect_files {

    my $ctx = context;

    my %expected = map { $_ => 1 } @_;

    my %existing = map { $_ => 1 } <*>;

    my @missing = grep { !$existing{$_} } keys %expected;

    ok( !@missing, 'expected files' );
    diag( "    missing file(s): ", join( ', ', @missing ) )
      if @missing;

    my @unexpected = grep { !$expected{$_} } keys %existing;

    ok( !@unexpected, 'extra files' );
    diag( "    found unexpected file(s): ", join( ', ', @unexpected ) )
      if @unexpected;

    $ctx->release;
}

sub test_run {


    my $trap = shift;

    my $ctx = context;

    my %dispatch = (

        die => sub { is( $trap->die, $_[0], 'exception' ) },

        leaveby => sub { is( $trap->leaveby, $_[0], 'leaveby' ) },

        stdout => sub {
            my @re = 'ARRAY' eq ref $_[0] ? @{ $_[0] } : $_[0];
            like( $trap->stdout, $_, "stdout: $_" ) foreach @re;
        },

        stderr => sub {
            my @re = 'ARRAY' eq ref $_[0] ? @{ $_[0] } : $_[0];
            like( $trap->stderr, $_, "stderr: $_" ) foreach @re;
        },

        expect_files => sub {

            expect_files( @{ $_[0] } );
        },

        logfile => sub {

            my ( $logfile, $expected ) = @{ $_[0] };

            my $have_logfile = -e $logfile;

            if ( $have_logfile ) {
                my $log;

                ok( $log = eval { do( rel2abs( $logfile ) ) }, 'parse' );
                is( $log, $expected, 'content' );

            }

            else {
                skip( "logfile $logfile doesn't exist" );
            }

        },

        file_contains_like => sub {

            my %files = @{ $_[0] };
            while ( my ( $file, $qr ) = each %files ) {
                like( read_text( $file ), $qr, "contents of file '$file'" );
            }

        },


    );


    my %expected = @_;

    push @_,
      map  { @{$_} }
      grep { !$expected{ $_->[0] } } (
        [ die          => undef ],
        [ expect_files => [] ],
        [ stdout       => qr/^$/ ],
        [ stderr       => qr/^$/ ],
        [ leaveby      => 'return' ],
      );


    while ( my ( $key, $value ) = splice( @_, 0, 2 ) ) {

        my $test = $dispatch{$key} // sub {
            BAIL_OUT( "internal error: unknown test result: $key\n" );
        };

        $test->( $value );

    }


    $ctx->release;

}

1;
