#!/usr/bin/perl -w

#
# This is not HTML conform. <optgroup> mustn't be nested. but i think would be nice if browsers would support that.
# After all its an good example to show how flexible formengine can be used.
#

use CGI;
use HTML::FormEngine;
use Mail::Mailer;

my $q = new CGI;
print $q->header;

my @nchooseform = (
		   {
		       "templ" => "select_optgroup",
		       "NAME" => "Firstnames",
		       "OPTGROUP" => [[['A', 'B', 'C']]],
		       "OPTION" => [[[['Albert', 'Albrecht', 'Arno'], ['Bart', 'Basilikum', 'Basta', 'Berta', 'Brecht', 'Bruno'], ['Caesar', 'Clara', 'Claus']]]],
		       "ERROR" => [['not_null', 'please select a value'], sub {local $_ = shift; $_ = [$_] unless(ref($_) eq 'ARRAY'); return '<i>Albert</i> is a funny name' if(grep {$_ eq 'Albert'} @{$_})}],
		       "MULTIPLE" => 1,
		   },
		   {
		       "templ" => "select_flexible",
		       "NAME" => "Firstname",
		       "sub" => [
				 {
				     "templ" => 'optgroup',
				     "OPTGROUP" => ["A", "B"],
				     "OPTION" => [['Albert','Albrecht', 'Arno'], ['Bart', 'Basilikum', 'Basta', 'Berta', 'Brecht', 'Bruno']],
				 },
				 {
				     "templ" => "option",
				     "OPTION" => ['Cl and Co', 'should', 'be submenu', 'of C', 'but this', 'isn\'t', 'supported', 'by any', 'browser'],
				 },
				 {
				     "templ" => 'optgroup_flexible',
				     "OPTGROUP" => "C",
				     "sub" => [
					       {
						   "templ" => "option",
						   "OPTION" => ['Caesar', 'Casanova', 'Calaschnikov'],
					       },
					       {
						   "templ" => "optgroup",
						   "OPTGROUP" => ['Cl', 'Co'],
						   "OPTION" => [['Clara', 'Claus', 'Clodwig'], ['Coma', 'Comerz', 'Conrad', 'Constantin']],
					       }
					       ],
				 },
				 ],
		   },
		   );


my $msg = '';
my $Form = new HTML::FormEngine(scalar $q->Vars);
$Form->set_seperate(1);
$Form->conf(\@nchooseform);
$Form->make;
#$Form->print_conf($Form->get_conf);

if($Form->ok and $Form->is_confirmed) {
    $Form->clear();
    $msg = "Thanks for using the great Namechooser!";
}
elsif($Form->ok) {
    $Form->confirm;
}

print $q->start_html('FormEngine example: NameChooser'),
      $Form->get,
      "<center><b>$msg</b></center>",
      $q->end_html;
