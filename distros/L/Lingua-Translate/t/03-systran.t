#!/usr/bin/perl

use strict;
use IO::Socket::INET;

if (my $pid = fork()) {
    # don't load Test::More until we fork, otherwise weird things
    # happen
    eval "use Test::More tests => 3;";

    use_ok("Lingua::Translate");

    Lingua::Translate::config(back_end => "SysTran",
			      dest_enc => "iso-8859-1",
			      src_enc => "iso-8859-1");

    my $translator = Lingua::Translate->new( src => "fr",
					     dest => "de");

    ok( UNIVERSAL::isa( $translator, "Lingua::Translate" ),
	"Lingua::Translate::SysTran->new()" );

    is( $translator->translate("Merde"), "Scheiße",
	"Lingua::Translate::SysTran->translate()"   );

    kill 15, $pid;

} else {

    # set up a translator from french to german
    my $sock = IO::Socket::INET->new(Listen => 5,
				     LocalAddr => 'localhost',
				     LocalPort => 10131,
				     ReuseAddr => 1,
				     Proto => 'tcp')
	or die "Failed to set up listener; $!";

    $sock->listen();

    # Implement the SysTran protocol
    my $newsocket = $sock->accept() or die "accept failed; $!";

    my $state = "I";
    my $translated;
    while ($state ne "D" && ($_ = $newsocket->getline())) {
	chomp;
	my ($command, $value) = m/^([\w\-]+)=(.*)$/
	    or die "Protocol failure";

	if ($state eq "I") {
	    ($command eq "METHOD" && $value eq "SOCKET"
	     && ($state = "A")) || die "Protocol failure";
	} elsif ($state eq "A") {
	    ($command eq "ACTION" && $value eq "TRANSLATE"
	     && ($state = "S")) || die "Protocol failure";
	} elsif ($state eq "S") {
	    ($command eq "SOURCE-CONTENT" ) || die "Protocol failure";
	    $state = "D";
	    # read the data
	    my $to_translate;
	    my $bytes_read = $newsocket->read($to_translate, $value);
	    ($bytes_read == $value) or die "short read";
	    if ($to_translate eq "Merde") {
		$translated = "Scheiße";
	    } else {
		$translated = "Ich verstehe nicht was Sie sagen";
	    }

	    my $to_write = ("ERR=0\nTIME=00:00:01\n"
			    ."OUTPUT-CONTENT=".length($translated)
			    ."\n$translated\n");

	    $newsocket->write($to_write, length $to_write);
	    $newsocket->flush();
	    $newsocket->close();
	}
    }
}
