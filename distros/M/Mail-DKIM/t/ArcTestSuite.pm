package ArcTestSuite;

use strict;
use warnings;
use Data::Dumper;

use YAML::XS;

use Net::DNS::Resolver::Mock;

use Mail::DKIM;
$Mail::DKIM::SORTTAGS = 1;

use Mail::DKIM::ARC::Signer;
use Mail::DKIM::ARC::Verifier;

use Test::More;

my @SKIP_TESTS = qw {

    # Mail::DKIM does not handle Authentication-Results header merges
    ar_merged1 ar_merged2

};

sub new {
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub LoadFile {
    my ( $self, $file ) = @_;
    my @data = YAML::XS::LoadFile( $file );
    $self->{ 'tests' } = \@data;
    return;
}

sub SetOperation {
    my ( $self, $operation ) = @_;
    $self->{ 'operation' } = $operation;
    return;
}

sub RunAllScenarios {
    my ( $self ) = @_;
    foreach my $Scenario ( @{ $self->{ 'tests' } } ) {
        $self->RunScenario( $Scenario );
    }
    return;
}

sub RunScenario {
    my ( $self, $scenario ) = @_;

    my $description = $scenario->{ 'description' };
    my $tests       = $scenario->{ 'tests' };
    my $txt_records = $scenario->{ 'txt-records' } || q{};
    my $comment     = $scenario->{ 'comment' };
    my $domain      = $scenario->{ 'domain '};
    my $sel         = $scenario->{ 'sel' };
    my $private_key = $scenario->{ 'privatekey' } || q{};

    my @chompkey = split( "\n", $private_key );
    shift @chompkey;
    pop @chompkey;
    $private_key = join( q{}, @chompkey );

    my $ZoneFile = q{};
    foreach my $Record ( sort keys %$txt_records ) {
        my $Txt = $txt_records->{ $Record };
        $ZoneFile .= $Record . '. 3600 TXT';
        foreach my $TxtLine ( split "\n", $Txt ) {
            $ZoneFile .= ' "' . $TxtLine . '"';
        }
        $ZoneFile .= "\n";
    }
    my $FakeResolver = Net::DNS::Resolver::Mock->new();
    $FakeResolver->zonefile_parse( $ZoneFile );

    TEST:
    foreach my $test ( sort keys %$tests ) {

        if ( grep { $test eq $_ } @SKIP_TESTS ) {
            diag( "Skipped test for $description - $test" );
            next TEST;
        } 

        my $testhash = $tests->{ $test };

        # keys relevant to validation and signing tests
        my $comment     = $testhash->{ 'comment' };
        my $cv          = $testhash->{ 'cv' };
        my $description = $testhash->{ 'description' };
        my $message     = $testhash->{ 'message' };
        my $spec        = $testhash->{ 'spec' };

        $message =~ s/[\n\r]*$//;
        $message =~ s/\015?\012/\015\012/g;

        if ( $cv eq q{} ) {
            $cv = 'fail';
            diag( "Null test cv for $description - $test" );
        }

        my $arc_result;

            eval {
              my $arc = Mail::DKIM::ARC::Verifier->new();
              Mail::DKIM::DNS::resolver( $FakeResolver );
              $arc->PRINT( $message );
              $arc->CLOSE();
              $arc_result = $arc->result();
              my $arc_result_detail = $arc->result_detail();
              if ( $self->{ 'operation' } eq 'validate' ) {
                my $mycv = lc $arc_result eq 'pass' ? 'Pass' :
                           lc $arc_result eq 'none' ? 'None' : 'Fail';

                if ( $self->{ 'operation' } ne 'sign' ) {
                    is( lc $mycv, lc $cv, "$description - $test ARC Result" );
                    if ( lc $mycv ne lc $cv ) {
                        diag( "Got: $arc_result ( $arc_result_detail )" );
                    }
                }
              }
            };
            if ( my $error = $@ ) {
                is( 0, 1, "$description- $test - died with $error" );
            }

        next if $self->{ 'operation' } ne 'sign';

        # keys relevant to signing tests only
        my $aar        = $testhash->{ 'AAR' };
        my $ams        = $testhash->{ 'AMS' };
        my $as         = $testhash->{ 'AS' };
        my $sigheaders = $testhash->{ 'sig-headers' };
        my $srvid      = $testhash->{ 'srv-id' };
        my $t          = $testhash->{ 't' };

        my $arc = Mail::DKIM::ARC::Signer->new(
          'Algorithm' => 'rsa-sha256',
          'Domain' => $domain,
          'Selector' => $sel,
          'Key' => Mail::DKIM::PrivateKey->load( 'Data' => $private_key ),
          'Chain' => $arc_result,
          'Headers' => $sigheaders,
          'Timestamp' => $t,
        );
        $arc->{ 'NoDefaultHeaders' } = 1;
        $Mail::DKIM::SORTTAGS = 1;
        Mail::DKIM::DNS::resolver( $FakeResolver );
        $arc->PRINT( $message );
        $arc->CLOSE();
        my $arcsign_result = $arc->as_string();
        my $arcsign_as     = $arc->{ '_AS' };
        my $arcsign_ams    = $arc->{ '_AMS' };
        my $arcsign_aar    = $arc->{ '_AAR' };

        is( srt( $arcsign_as ),  srt( 'ARC-Seal: '                   . $as ),  "$description - $test ARC-Seal" );
        is( srt( $arcsign_ams ), srt( 'ARC-Message-Signature: '      . $ams ), "$description - $test ARC-Message-Signature" );
        is( srt( $arcsign_aar ), srt( 'ARC-Authentication-Results: ' . $aar ), "$description - $test ARC-Authentication-Results" );

    }
    return;
}

sub srt {
    my ( $header ) = @_;
    my ( $key, $value ) = split( ': ', $header, 2 );
    $value =~ s/^\s+//gm;
    $value =~s/\n//g;
    my @values = split( /;\s*/, $value );
    @values = map { local $_ = $_ ; s/^\s+|\s+$//g ; $_ } @values;
    my $sorted = join( '; ', sort @values );
    return "$key: $sorted";
}

1;

