=head1 NAME

t/RT94231.t

=head1 DESCRIPTION

Tests support of previous translation strings (#|).

	https://rt.cpan.org/Ticket/Display.html?id=94231

=head1 EXAMPLE

	#. Tag: para
	#, fuzzy, no-c-format
	#| msgid "Ian Murdock, founder of the Debian project, was its first leader, from 1993 to 1996. After passing the baton to Bruce Perens, Ian took a less public role. He returned to working behind the scenes of the free software community, creating the Progeny company, with the intention of marketing a distribution derived from Debian. This venture was a commercial failure, sadly, and development abandoned. The company, after several years of scraping by, simply as a service provider, eventually filed for bankruptcy in April of 2007. Of the various projects initiated by Progeny, only <emphasis>discover</emphasis> still remains. It is an automatic hardware detection tool."
	msgid "Ian Murdock, founder of the Debian project, was its first leader, from 1993 to 1996. After passing the baton to Bruce Perens, Ian took a less public role. He returned to working behind the scenes of the free software community, creating the Progeny company, with the intention of marketing a distribution derived from Debian. This venture was, sadly, a commercial failure, and development was abandoned. The company, after several years of scraping by, simply as a service provider, eventually filed for bankruptcy in April of 2007. Of the various projects initiated by Progeny, only <emphasis>discover</emphasis> still remains. It is an automatic hardware detection tool."
	msgstr "Ian Murdock, fondatore del progetto Debian, fu il suo primo leader dal 1993 al 1996. Dopo aver passato il testimone a Bruce Perens, Ian assunse un ruolo più nascosto tornando a lavorare dietro le quinte della comunità del software libero creando l'azienda Progeny, con lo scopo di commercializzare una distribuzione derivata da Debian. Questa impresa purtroppo dal punto di vista commerciale fu un fallimento e lo sviluppo venne abbandonato. La società dopo essere stata a galla a stento come semplice fornitore di servizi è fallita nell'aprile 2007. Di tutti i vari progetti avviati da Progeny è rimasto solo <emphasis>discover</emphasis> (uno strumento automatico di rilevamento hardware)."

=cut

use strict;
use warnings;

use Test::More;
use Locale::PO;
use Data::Dumper;

my $no_tests = 11;

plan tests => $no_tests;

my $file = "t/RT94231.po";
my $po = Locale::PO->load_file_asarray($file);
ok $po, "loaded ${file} file";

my $entry_id;
my $our_msgid = q{"Ian Murdock, founder of the Debian project, was its first leader, from 1993 to 1996. After passing the baton to Bruce Perens, Ian took a less public role. He returned to working behind the scenes of the free software community, creating the Progeny company, with the intention of marketing a distribution derived from Debian. This venture was, sadly, a commercial failure, and development was abandoned. The company, after several years of scraping by, simply as a service provider, eventually filed for bankruptcy in April of 2007. Of the various projects initiated by Progeny, only <emphasis>discover</emphasis> still remains. It is an automatic hardware detection tool."};

for (my $i = 0; $i <= $#$po; $i++) {
	my $entry = $po->[$i];
	if (defined $entry->{msgid} && $entry->{msgid} eq $our_msgid) {
		$entry_id = $i;
		last;
	}
}

if (! defined $entry_id) {
	ok(0, "not found our PO entry") for 1 .. $no_tests - 1;
}
else {
	my $entry = $po->[$entry_id];
	ok($entry, 'We found the entry with our msgid');

	my $expected_msgstr = q{"Ian Murdock, fondatore del progetto Debian, fu il suo primo leader dal 1993 al 1996. Dopo aver passato il testimone a Bruce Perens, Ian assunse un ruolo più nascosto tornando a lavorare dietro le quinte della comunità del software libero creando l'azienda Progeny, con lo scopo di commercializzare una distribuzione derivata da Debian. Questa impresa purtroppo dal punto di vista commerciale fu un fallimento e lo sviluppo venne abbandonato. La società dopo essere stata a galla a stento come semplice fornitore di servizi è fallita nell'aprile 2007. Di tutti i vari progetti avviati da Progeny è rimasto solo <emphasis>discover</emphasis> (uno strumento automatico di rilevamento hardware)."};
	is($entry->msgstr(), $expected_msgstr,
		'Our entry has the expected translation too');

	# Check that the previous msgid is also parsed correctly
	my $expected_prev_msgid = q{"Ian Murdock, founder of the Debian project, was its first leader, from 1993 to 1996. After passing the baton to Bruce Perens, Ian took a less public role. He returned to working behind the scenes of the free software community, creating the Progeny company, with the intention of marketing a distribution derived from Debian. This venture was a commercial failure, sadly, and development abandoned. The company, after several years of scraping by, simply as a service provider, eventually filed for bankruptcy in April of 2007. Of the various projects initiated by Progeny, only <emphasis>discover</emphasis> still remains. It is an automatic hardware detection tool."};
	is($entry->fuzzy_msgid(), $expected_prev_msgid,
		'Previous/fuzzy msgid of our entry is also retained');

	isnt($entry->fuzzy_msgid(), $entry->msgid(),
		'Previous/fuzzy and current msgid are different');

	# Try to modify the value and see that we can persist it
	my $new_value;
	$entry->fuzzy_msgid($new_value);
	is($entry->fuzzy_msgid(), $new_value, 'fuzzy_msgid() value can be modified');

	ok(Locale::PO->save_file_fromarray("${file}.out", $po), "save again to file");
	ok -e "${file}.out", "the file now exists";

	my $po_after_save = Locale::PO->load_file_asarray("${file}.out");
	ok $po_after_save, "loaded ${file}.out file"
		and unlink "${file}.out";

	my $new_entry = $po_after_save->[$entry_id];
	ok($new_entry, 'Found the same PO entry in the just saved file');

	is($new_entry->fuzzy_msgid(), $new_value,
		'New value of fuzzy_msgid() persisted on save');
}
