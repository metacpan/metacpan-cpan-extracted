package t::run::utils;

use Test::Most;
use Test::File;

use Test::Builder;

use parent 'Exporter';

our @EXPORT = qw[ expect_files test_run ];

sub expect_files {

    my $Test = Test::Builder->new;

    my %expected = map { $_ => 1 } @_;

    my %existing = map { $_ => 1 } <*>;

    my @missing = grep { !$existing{$_} } keys %expected;

    $Test->ok( !@missing, 'expected files' );
    $Test->diag( "    missing file(s): ", join( ', ', @missing ) )
      if @missing;

    my @unexpected = grep { !$expected{$_} } keys %existing;

    $Test->ok( !@unexpected, 'extra files' );
    $Test->diag( "    found unexpected file(s): ", join( ', ', @unexpected ) )
      if @unexpected;
}

sub test_run {


    my $trap = shift;

    my $Test = Test::Builder->new;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %dispatch = (

	die => sub { $Test->is_eq( $trap->die, $_[0], 'exception' ) },

        leaveby => sub { $Test->is_eq( $trap->leaveby, $_[0], 'leaveby' ) },

        stdout => sub { my @re = 'ARRAY' eq ref $_[0] ? @{$_[0]} : $_[0];
			$Test->like( $trap->stdout, $_, "stdout: $_" ) foreach @re;
		    },

        stderr => sub { my @re = 'ARRAY' eq ref $_[0] ? @{$_[0]} : $_[0];
			$Test->like( $trap->stderr, $_, "stderr: $_" ) foreach @re;
		    },

        expect_files => sub {
            local $Test::Builder::Level = $Test::Builder::Level + 1;

            expect_files( @{ $_[0] } );
        },

        logfile => sub {

            my ( $logfile, $expected ) = @{ $_[0] };

            local $Test::Builder::Level = $Test::Builder::Level + 1;

	    my $have_logfile = file_exists_ok( $logfile, 'exists' );


	    if ( $have_logfile ) {
		my $log;

		ok( $log = eval { do $logfile }, 'parse' );
		is_deeply( $log, $expected, 'content' );

	    }

	    else {
		$Test->skip( "logfile $logfile doesn't exist" );
	    }

        },

        file_contains_like => sub {

            local $Test::Builder::Level = $Test::Builder::Level + 1;


            my %files = @{ $_[0] };
            while ( my ( $file, $qr ) = each %files ) {
                file_contains_like( $file, $qr, "contents of file '$file'" );
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
            $Test->BAIL_OUT( "internal error: unknown test result: $key\n" );
        };

        $test->( $value );

    }


}

1;
