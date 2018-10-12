#!/usr/local/cpanel/3rdparty/bin/perl -w

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::Mail::Pyzor::Digest::Pieces;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent qw( MailPyzorTestBase );

use Test::More;
use Test::FailWarnings;

use Data::Dumper ();
use Email::MIME  ();
use Encode       ();
use JSON         ();
use IPC::Run     ();

use Test::Mail::Pyzor ();

use Mail::Pyzor::Digest::Pieces ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

use constant _NORMALIZE => (
    "Thanks to everyone that helped with talks, staffing, moving boxes, grabbing coffee, and everything else around the conference this year. This one was one for the record books, and we've been getting some really great feedback to build on for next year. It sounds like this was one of the best conferences ever for many of the attendees. Some quick bullet points for your consumption:",
    'A special thank you to the speakers this year! Thank you for all of the effort you put in to your talks. The content is what makes this conference, worthwhile for all of our attendees. Your effort is greatly appreciated. ',
    'Non-panelists: please send us your presentations, so we can get then up on the site.',
    'The speaker polls are open until the 10th, and we’ll be pushing attendees to submit ratings for a bit yet. Once they’ve closed I’ll get it all aggregated and sent out to you. ',
    'You can disable the “AutoSSL cannot request a certificate because all of the website’s domains have failed DCV (Domain Control Validation).” type of notification through the cPanel interface:',
    "ha\xc2\xa0ha\xc2\xa0",
    "oh \xc2\xa0yeah \xc2\xa0 wtf\xc2\xa0  huh",
    "middle\xc2\xa0nbsp",
    "t\xc2\xa0nbsp\xc2\xa0",
    "trailing newline\n",
    "\xc2\xa0l\xc2\xa0nbsp",
    "\nleading newline",
    "\xff\xff\xff invalid UTF-8",
    "\xff\xff\xff invalid UTF-8 w/ trailing nbsp\xc2\xa0",
    "NUL\0bytesss",
    'Message Title Trevor Bordner updated an issue Cobra / COBRA-8189 Unable to renew AutoSSL certificates if proxy subdomains exist in userdata_SSL files - Clone Change By: Trevor Bordner BRANCH: COBRA-8189_apache_conf_distiller BINARY: v11.75.9045.5 {panel:title=Details} (i)',
);

#e.g., num_method_tests()
sub new {
    my ( $class, @args ) = @_;
    my $self = $class->SUPER::new(@args);

    $self->num_method_tests( test_normalize => 2 * _NORMALIZE() );

    $self->{'_message_hr'} = Test::Mail::Pyzor::get_test_emails_hr();

    $self->num_method_tests( test_digest_payloads => 1 * keys %{ $self->{'_message_hr'} } );

    return $self;
}

sub _run_pyzor {
    my ( $cmd, $input_sr, @args ) = @_;

    my $out = q<>;
    my $err = q<>;
    IPC::Run::run(
        [ Test::Mail::Pyzor::python_bin(), "$FindBin::Bin/support/$cmd.py", @args ],
        $input_sr,
        \$out,
        \$err,
    );

    warn $err if length $err;

    return $out;
}

sub _pyzor_normalize {
    return _run_pyzor( 'normalize', @_ );
}

sub _pyzor_digest_payloads {
    my $out = _run_pyzor( 'digest_payloads', @_ );

    my $json = JSON->new()->allow_nonref();

    return [ map { $json->decode($_) } split m<\n+>, $out ];
}

sub test_digest_payloads : Tests() {
    my ($self) = @_;

  SKIP: {
        $self->_skip_if_no_python_pyzor( $self->num_tests() );

        my %name_message = %{ $self->{'_message_hr'} };

        for my $name ( sort keys %name_message ) {
          SKIP: {
                skip $name, 1 if Test::Mail::Pyzor::EMAIL_DIGEST()->{$name};

                # Email::MIME seems to fiddle with the string that it receives,
                # so let’s protect against that by giving a disposable copy.
                my $msg = Email::MIME->new( q<> . ${ $name_message{$name} } );

                my $payloads_ar = Mail::Pyzor::Digest::Pieces::digest_payloads($msg);

                my $expected_ar = _pyzor_digest_payloads( $name_message{$name} );

                # Required because of Email::MIME::Encodings’s heavy-handed
                # approach to email line endings. (YOU WILL SUBMIT!!)
                s<\x0d\x0a><\x0a>g for ( @$payloads_ar, @$expected_ar );

                utf8::encode($_) for @$payloads_ar, @$expected_ar;

                is_deeply(
                    $payloads_ar,
                    $expected_ar,
                    $name,
                  )
                  or do {
                    for my $i ( 1 .. $#$expected_ar ) {
                        diag Test::Mail::Pyzor::dump( $payloads_ar->[$i] );
                        diag Test::Mail::Pyzor::dump( $expected_ar->[$i] );
                    }
                  };
            }
        }
    }

    return;
}

sub test_should_handle_line : Tests(6) {
    my @yes = (
        'heckyeah',
        'righteous',
        "oh\xc2\xa0yeah",    # *not* decoded, i.e., raw bytes
    );

    for my $line (@yes) {
        ok(
            Mail::Pyzor::Digest::Pieces::should_handle_line($line),
            "yes: " . Test::Mail::Pyzor::dump($line),
        );
    }

    my @no = (
        'nono',
        q<>,
        Encode::decode( 'utf-8', "oh\xc2\xa0yeah" ),
    );

    for my $line (@no) {
        ok(
            !Mail::Pyzor::Digest::Pieces::should_handle_line($line),
            "no: " . Test::Mail::Pyzor::dump($line),
        );
    }

    return;
}

sub test_normalize : Tests() {
    my ($self) = @_;

  SKIP: {
        $self->_skip_if_no_python_pyzor( $self->num_tests() );

        for my $in ( _NORMALIZE() ) {
            diag Test::Mail::Pyzor::dump($in);

            my $copy = $in;

            my $expect = _pyzor_normalize( \$copy );

            Mail::Pyzor::Digest::Pieces::normalize($copy);

            is(
                $copy,
                $expect,
                '… as binary: ' . Test::Mail::Pyzor::dump($expect),
            );

          SKIP: {
                my $copy = $in;

                utf8::decode($copy) or skip 'This is invalid UTF-8.', 1;

                my $expect = _pyzor_normalize( \$in, '--utf-8' );

                Mail::Pyzor::Digest::Pieces::normalize($copy);

                utf8::encode($copy);

                is(
                    $copy,
                    $expect,
                    '… as UTF-8 : ' . Test::Mail::Pyzor::dump($expect),
                );
            }
        }
    }

    return;
}

sub test_assemble_lines : Tests(4) {
    my @few = ( 1 .. 4 );

    is_deeply(
        Mail::Pyzor::Digest::Pieces::assemble_lines( \@few ),
        \'1234',
        '4 lines',
    );

    push @few, 5;

    is_deeply(
        Mail::Pyzor::Digest::Pieces::assemble_lines( \@few ),
        \'23445',
        '5 lines',
    );

    push @few, ( 6 .. 10 );

    is_deeply(
        Mail::Pyzor::Digest::Pieces::assemble_lines( \@few ),
        \'345789',
        '10 lines',
    );

    push @few, ( 11 .. 100 );

    is_deeply(
        Mail::Pyzor::Digest::Pieces::assemble_lines( \@few ),
        \'212223616263',
        '100 lines',
    );

    return;
}

1;
