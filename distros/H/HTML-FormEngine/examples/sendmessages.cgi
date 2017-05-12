#!/usr/bin/perl -w

use strict;
use CGI;
use HTML::FormEngine;
use HTML::FormEngine::SkinComplex;

my $q = new CGI;
print $q->header;

my $Form = HTML::FormEngine->new(scalar $q->Vars);
$Form->set_seperate(1);

#usinge the complex skin
$Form->set_skin_obj(new HTML::FormEngine::SkinComplex);

my @form = (
	    {
		templ => 'text2',
		NAME => 'name',
		TITLE => ['Firstname', 'Lastname'],
		SIZE => [10, 10],
		ERROR => ['not_null', 'not_null'],
	    },
	    {
		NAME => ['street', 'house'],
		TITLE => ['Street', 'No.'],
		SIZE => [15, 3],
		ERROR => [undef, ['regex', undef, '^[0-9]+[A-Za-z 0-9/]*$']],
	    },
	    {
		NAME => ['postcode','city'],
		TITLE => ['Postcode', 'City'],
		SIZE => [5, 15],
		ERROR => [['regex', undef, '^[0-9]{5,}$']],
	    },
	    {
		NAME => 'phone',
		TITLE => ['Phone', '&nbsp; / &nbsp;'],
		SIZE => [5, 10],
		ERROR => [['digitonly', undef, 3],['digitonly', undef, 3]],
	    },
	    {
		TITLE => 'Email',
		NAME => 'email',
		ERROR => [['not_null', ['rfc822', 'ungültig']]],
	    },
	    {
		templ => 'textarea',
		TITLE => 'Message',
		NAME => 'message',
		COLS => 37,
		ROWS => 15,
		ERROR => 'not_null',
		TD_EXTRA => "colspan=4",
	    }
);

$Form->conf(\@form);
$Form->make();

print $q->start_html('FormEngine example: Send a Message');
if($Form->ok){
  $Form->clear();	
  print "<center>You're message has been send (not really :()!</center><br>";
}

print $Form->get,
    $q->end_html;


########END########

__END__

original:

my @form = (
	    {
		templ => 'text_notitle_noerror',
		#NAME => [[['forename', 'lastname']]],
		NAME => 'name',
		SUBTITLE => [[['Vorname', 'Nachname']]],
		#SUBTITLE => [['','Nachname']],
		#POSTFIX => [['&nbsp; ']],
		#PREFIX => [['', '&nbsp; ']],
		SIZE => [[[10, 10]]],
		ERROR_IN => [[['not_null', 'not_null']]],
		#ERROR => ['not_null', 'not_null'],
	    },
	    {
		templ => 'text_notitle_noerror',
		NAME => [[['street', 'house']]],
		SUBTITLE => [[['Strasse', 'Hausnr.']]],
		#POSTFIX => [['&nbsp; ']],
		#PREFIX => [['', '&nbsp; ']],
		#SUBTITLE => [['', 'Hausnr.']],
		SIZE => [[[15, 3]]],
		ERROR_IN => [[[undef, [['regex', undef, '^[0-9]+[A-Za-z 0-9/]*$']]]]],
	    },
	    {
		templ => 'text_notitle_noerror',
		NAME => [[['postcode','city']]],
		SUBTITLE => [[['PLZ', 'Ort']]],
		#POSTFIX => [['&nbsp; ']],
		#PREFIX => [['', '&nbsp; ']],
		#SUBTITLE => [['', 'Ort']],
		SIZE => [[[5, 15]]],
		ERROR_IN => [[[[['regex', undef, '^[0-9]{5,}$']]]]],
	    },
	    {
		templ => 'text_notitle_noerror',
		NAME => 'phone',
		SUBTITLE => [[['Telefon', '&nbsp; / &nbsp;']]],
		#POSTFIX => [[['&nbsp; / &nbsp;']]],
		SIZE => [[[5, 10]]],
		ERROR_IN => [[[[['digitonly', undef, 3]],[['digitonly', undef, 3]]]]],
	    },
	    {
		templ => 'text_notitle',
		SUBTITLE => 'Email',
		NAME => 'email',
		ERROR_IN => [[[['not_null', ['rfc822', 'ungültig']]]]],
	    },
	    {
		templ => 'textarea_notitle',
		SUBTITLE => 'Nachricht',
		NAME => 'message',
		COLS => 37,
		ROWS => 15,
		ERROR_IN => 'not_null',
		TD_EXTRA => "colspan=4",
	    }
);
