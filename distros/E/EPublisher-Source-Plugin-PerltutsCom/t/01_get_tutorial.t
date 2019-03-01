#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use EPublisher::Source::Plugin::PerltutsCom;

use File::Basename;
use lib dirname __FILE__;
use TestUA;

my $error = '';

{
  package # private
      MockEPublisher;

  use Test::More;

  sub new { return bless {}, shift }
  sub debug { $error .= $_[1] . "\n"; };
}

{
    $error = '';

    my $config = {};
    my $obj    = EPublisher::Source::Plugin::PerltutsCom->new( $config );
    $obj->publisher( MockEPublisher->new );

    my @pods = $obj->load_source;

    # if tutorial does not exist I expect an empty array as return
    is scalar @pods, 0, 'inexisting tutorial name';
    is $error, "100: start EPublisher::Source::Plugin::PerltutsCom\n400: No tutorial name given\n";
}

{
    $error = '';

    my $config = { name => 'PDL' };
    my $obj    = EPublisher::Source::Plugin::PerltutsCom->new( $config );
    $obj->publisher( MockEPublisher->new );

    my @pods = $obj->load_source;

    # if tutorial does not exist I expect an empty array as return
    is scalar @pods, 0, 'inexisting tutorial name';
    like $error, qr"103: fetch tutorial PDL";
}

{
    $error = '';

    my $obj = EPublisher::Source::Plugin::PerltutsCom->new;
    $obj->publisher( MockEPublisher->new );

    my @pods = $obj->load_source( 'PDL' );

    # if tutorial does not exist I expect an empty array as return
    is scalar @pods, 0, 'inexisting tutorial name';
    like $error, qr"103: fetch tutorial PDL";
}

{
    local $EPublisher::Source::Plugin::PerltutsCom::UA = TestUA->new;

    $error = '';

    my $obj = EPublisher::Source::Plugin::PerltutsCom->new;
    $obj->publisher( MockEPublisher->new );

    my @pods = $obj->load_source( 'PDL' );

    # if tutorial does not exist I expect an empty array as return
    is scalar @pods, 1, 'got PDL tutorial';
    like $error, qr"103: fetch tutorial PDL";
}

{
    local $EPublisher::Source::Plugin::PerltutsCom::UA = TestUA->new;

    $error = '';

    my $obj = EPublisher::Source::Plugin::PerltutsCom->new;
    $obj->publisher( MockEPublisher->new );

    my @pods = $obj->load_source( 'EPublisher' );

    is scalar @pods, 1, 'got EPublisher tutorial';
    like $error, qr"103: fetch tutorial EPublisher";
    is $pods[0]->{pod}, q~=head1 NAME

EPublisher
~;
    is $pods[0]->{title}, q~EPublisher~;
}

{
    local $EPublisher::Source::Plugin::PerltutsCom::UA = TestUA->new;

    $error = '';

    my $obj = EPublisher::Source::Plugin::PerltutsCom->new;
    $obj->publisher( MockEPublisher->new );

    my @pods = $obj->load_source( 'error' );

    # if tutorial does not exist I expect an empty array as return
    is scalar @pods, 0, 'inexisting tutorial name';
    like $error, qr"103: fetch tutorial error";
    like $error, qr"103: tutorial error does not exist";
}

done_testing();
