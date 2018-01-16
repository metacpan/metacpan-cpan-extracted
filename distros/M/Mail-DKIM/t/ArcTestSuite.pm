package ArcTestSuite;

use strict;
use warnings;
use Data::Dumper;

use YAML::XS;

use Net::DNS::Resolver::Mock;

use Mail::DKIM;

#$Mail::DKIM::SORTTAGS = 1;

use Mail::DKIM::ARC::Signer;
use Mail::DKIM::ARC::Verifier;

use Test::More;

=head1 NAME

ArcTestSuite - extract and run tests from the ARC YAML test suite

=head1 CONSTRUCTOR

=head2 new() - create a new test runner

my $Tests = ArcTestSuite->new(Strict => 1/0);

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{Strict} = $args{"Strict"};
    $self->{Strict} = 1 if ! defined $self->{Strict};
    return $self;
}

=head1 METHODS

=head2 LoadFile() - load a YAML file of tests

  $Tests->LoadFile( $yamlfile );

  Load the tests from a YAML file

=cut

sub LoadFile {
    my ( $self, $file ) = @_;
    my @data = YAML::XS::LoadFile($file);
    $self->{'tests'} = \@data;
    return;
}

=head2 SetOperation() - prepare to sign or validate

$Tests->SetOperation( 'sign'|'validate' );

Tell it whether these are signing or validateing tests

=cut

sub SetOperation {
    my ( $self, $operation ) = @_;
    die "Invalid operation $operation"
      unless $operation =~ m{^(validate|sign)$};
    $self->{'operation'} = $operation;
    return;
}

=head2 DumpTests

$Tests->DumpTests("dir/%s")

Dump each test message to a file as the test is run.
The argument is a printf pattern for the filename with %s as
the test name.

=cut

sub DumpTests {
    my ( $self, $testpat ) = @_;
    $self->{'testpat'} = $testpat;
    return;
}

my $nskip = 0;

=head2 RunAllScenarios() - run all test scenarios

$Test->RunAllScenarios($nskip)

Iterate over all scenarios in the YAML and run the tests.
The optional argument is how many tests to skip before actual
testing.

=cut

sub RunAllScenarios {
    my ( $self, $nsx ) = @_;

    $nskip = $nsx if $nsx > 0;
    foreach my $Scenario ( @{ $self->{'tests'} } ) {
        $self->RunScenario($Scenario);
    }
    return;
}

=head2 RunScenario() - run all test scenarios

$Test->RunScenario($scenario)

Iterate over all the tests in the scenario and run them.

=cut

sub RunScenario {
    my ( $self, $scenario ) = @_;

    my $description = $scenario->{'description'};
    my $tests       = $scenario->{'tests'};
    my $txt_records = $scenario->{'txt-records'} || q{};
    my $comment     = $scenario->{'comment'};
    my $domain      = $scenario->{'domain '};
    my $sel         = $scenario->{'sel'};
    my $private_key = $scenario->{'privatekey'} || q{};

    diag("--- $description ---") unless $ENV{HARNESS_ACTIVE};

    # remove key BEGIN / END
    if ($private_key) {
        my @chompkey = split( "\n", $private_key );
        $private_key = join( q{}, @chompkey[ 1 .. ( $#chompkey - 1 ) ] );
    }

    my $ZoneFile = q{};
    foreach my $Record ( sort keys %$txt_records ) {
        my $Txt = $txt_records->{$Record};
        $ZoneFile .= $Record . '. 60 TXT';
        foreach my $TxtLine ( split "\n", $Txt ) {
            $ZoneFile .= ' "' . $TxtLine . '"';
        }
        $ZoneFile .= "\n";
    }
    my $FakeResolver = Net::DNS::Resolver::Mock->new();
    $FakeResolver->zonefile_parse($ZoneFile);

  TEST:
    foreach my $test ( sort keys %$tests ) {

        if ( $nskip > 0 ) {
            diag("skip $description - $test") unless $ENV{HARNESS_ACTIVE};
            $nskip--;
            next;
        }
        my $testhash = $tests->{$test};

        # keys relevant to validate and signing tests
        my $comment     = $testhash->{'comment'};
        my $cv          = $testhash->{'cv'};
        my $description = $testhash->{'description'};
        my $message     = $testhash->{'message'};
        my $spec        = $testhash->{'spec'};

        # dump test to a file
        if ( $self->{'testpat'} ) {
            local *TOUT;
            my $tfn = $test;
            $tfn =~ s:[ /]:_:g;

            open TOUT, ">" . sprintf( $self->{'testpat'}, $tfn )
              or die "cannot write file for $description";
            print TOUT $message;
            close TOUT;
        }

        # HACK - skip sha1 tests
        if ( $test =~ /sha1/ ) {
            diag("Skip SHA-1 test $test") unless $ENV{HARNESS_ACTIVE};
            next;
        }

        $message =~ s/\015?\012/\015\012/g;

        my $arc_result;

        if ( $self->{'operation'} eq 'validate' ) {
            if ( !defined $cv or $cv eq q{} ) {
                $cv = 'fail';
                diag("Null test cv treated as fail for $description - $test")
                  unless $ENV{HARNESS_ACTIVE};
            }

            eval {
                my $arc =
                  new Mail::DKIM::ARC::Verifier( Strict => $self->{"Strict"} );
                Mail::DKIM::DNS::resolver($FakeResolver);
                $arc->PRINT($message);
                $arc->CLOSE();
                $arc_result = $arc->result();
                my $arc_result_detail = $arc->result_detail();
                my $mycv =
                    lc $arc_result eq 'pass' ? 'Pass'
                  : lc $arc_result eq 'none' ? 'None'
                  :                            'Fail';

                is( lc $mycv, lc $cv,
                    "$description - $test ARC Result $mycv want $cv" );
                if ( lc $mycv ne lc $cv ) {
                    diag("Got: $arc_result ( $arc_result_detail )")
                      unless $ENV{HARNESS_ACTIVE};
                }
            };
            if ( my $error = $@ ) {
                is( 0, 1, "$description- $test - died with $error" );
            }
            next;
        }

        # keys relevant to signing tests only
        my $aar        = $testhash->{'AAR'};
        my $ams        = $testhash->{'AMS'};
        my $as         = $testhash->{'AS'};
        my $sigheaders = $testhash->{'sig-headers'};
        my $srvid      = $testhash->{'srv-id'} || $domain;
        my $t          = $testhash->{'t'};

        my $arc = Mail::DKIM::ARC::Signer->new(
            'Algorithm' => 'rsa-sha256',
            'Domain'    => $domain,
            'SrvId'     => $srvid,
            'Selector'  => $sel,
            'Key'   => Mail::DKIM::PrivateKey->load( 'Data' => $private_key ),
            'Chain' => 'ar'
            , # use the result from A-R, since message might have changed since verified
            'Headers'   => $sigheaders,
            'Timestamp' => $t,
        );
        $arc->{'NoDefaultHeaders'} = 1;
        $Mail::DKIM::SORTTAGS = 1;
        Mail::DKIM::DNS::resolver($FakeResolver);
        $arc->PRINT($message);
        $arc->CLOSE();
        my $arcsign_result = $arc->as_string();
        my $arcsign_as     = $arc->{'_AS'};
        my $arcsign_ams    = $arc->{'_AMS'};
        my $arcsign_aar    = $arc->{'_AAR'};

        is(
            sqish($arcsign_as),
            sqish( 'ARC-Seal: ' . $as ),
            "$description - $test ARC-Seal"
        );
        is(
            sqish($arcsign_ams),
            sqish( 'ARC-Message-Signature: ' . $ams ),
            "$description - $test ARC-Message-Signature"
        );
        is(
            sqsh($arcsign_aar),
            sqsh( 'ARC-Authentication-Results: ' . $aar ),
            "$description - $test ARC-Authentication-Results"
        );

    }
    return;
}

# sort tags
sub srt {
    my ($header) = @_;
    my ( $key, $value ) = split( ': ', $header, 2 );
    $value =~ s/^\s+//gm;
    $value =~ s/\n//g;
    my @values = split( /;\s*/, $value );

    #    @values = map { local $_ = $_ ; s/^\s+|\s+$//g ; $_ } @values;
    @values = map { s/^\s+|\s+$//g } @values;
    my $sorted = join( '; ', sort @values );
    return "$key: $sorted";
}

# squash all white space
sub sqish {
    my ($header) = @_;
    return "" unless $header;    # completely empty
    my ( $key, $value ) = split( ': ', $header, 2 );
    return "" unless $value;     # empty value

    $value =~ s/[ \t\r\n]+//gs;  # remove all white space
    $value =~ s/\s*;\s*/; /g;    # squash put in one space around semicolons
                                 #print "SQUISH $key: $value\n";
    return "$key: $value";
}

# squash white space between fields
sub sqsh {
    my ($header) = @_;
    return "" unless $header;    # completely empty
    my ( $key, $value ) = split( ': ', $header, 2 );
    return "" unless $value;     # empty value

    $value =~ s/^\s+|[ \t\r\n]+$//gs;  # remove leading and trailing white space
    $value =~ s/\n/ /g;                # flatten into one line
    $value =~ s/\s*;\s*/; /g;          # squash white space around semicolons
                                       #print "SQUASH $key: $value\n";
    return "$key: $value";
}

1;
__END__

=head1 AUTHORS

Bron Gondwana, E<lt>brong@fastmailteam.comE<gt>,
John Levine, E<lt>john.levine@standcore.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by FastMail Pty Ltd
Copyright 2017 by Standcore LLC

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
