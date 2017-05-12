#!/usr/bin/perl
use strict;
use HTML::FormEngine;
use CGI;

my $q = CGI->new;
print $q->header,
      $q->start_html('FormEngine example: Hobbies');
my $Form = HTML::FormEngine->new(scalar $q->Vars);
$Form->set_seperate(1);
my $msg = '';
my @form = (
	{
	  templ => 'check',
	  NAME  => 'hobbie',
	  TITLE => 'Hobbies',
	  OPTION => [['Parachute Jumping', 'Playing Video Games'], ['Doing Nothing', 'Soak'], ['Head Banging', 'Cat Hunting'], "Don't Know", '<&_text&>'],
	  OPT_VAL => [[1,2], [3,4], [5,6], 7, 8],
	  VALUE => [1,2,7],
         'sub' => {'_text' => {'NAME' => 'Other', 'VALUE' => '', ERROR => ''}},
	  ERROR_IN => sub{if(shift eq 4) { return "That's not a faithfull hobby!" }}
	},
#	{
#	  templ => 'check',
#	  NAME  => 'hobbie',
#	  TITLE => 'hobbies',
#	  OPTION => [['Parachute Jumping', 'Playing Video Games'], ['Doing Nothing', 'Soak'], ['Head Banging', 'Cat Hunting'], "Don't Know", '<&_text&>', 'test1'],
#	  OPT_VAL => [[1,2], [3,4], [5,6], 7, 8],
#	  VALUE => [1,2,7,8],
#          'sub' => {'_text' => {'NAME' => 'Other', 'VALUE' => '', ERROR => ''}},
#	  ERROR_IN => sub{if(shift eq 4) { return "That's not a faithfull hobby!" }},
#	  #ERROR => sub{local $_ = shift; return "eeek!" if(grep {$_ eq 4} @{$_});},
#	},
);			

$Form->conf(\@form);
$Form->make();
if($Form->ok and $Form->is_confirmed){
  print "Thank you!";
}
elsif($Form->ok) {
    $Form->confirm;
    $Form->print;
}
else {
  $Form->print;
}
print $q->end_html;
