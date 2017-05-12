#!/usr/bin/perl -w

use CGI;
use HTML::FormEngine;
use Mail::Mailer;

my $q = new CGI;
print $q->header;

my @fbackform = (
		 {
		     "templ" => "fieldset",
		     "LEGEND" => "Your Data",
		     "sub" => [
	  
			       { 
				   "NAME" => "Name",
				   "ACCESSKEY" => 'n',
				   "ID" => 'name',
				   "ERROR" => 'not_null'},

			       {
				   "NAME" => "Email",
				   "ERROR" => ['not_null', 'rfc822'],
			       },
			       ],
		 },
		 {
		     "templ" => "fieldset",
		     "LEGEND" => "Your Comment",
		     "sub" => [
			       {
				   "NAME" => "Subject",
				   "ERROR" => 'not_null'},
			       {
				   "templ" => "textarea",
				   "NAME" => "Comment",
				   "COLS" => 59,
				   "ROWS" => 20,
				   "ERROR" => sub { ($_) = @_; return (length($_) < 40) ? 'to short!' : ''; }}
			       ],
		 }
);

my $msg = '';
my $Form = new HTML::FormEngine(scalar $q->Vars);

$Form->conf(\@fbackform);
$Form->make;

if($Form->ok) {
  $Form->clear();
  my $mailer = Mail::Mailer->new();
  $mailer->open({ From    => '"FormEngine" <moritz@freesources.org>',
		  To      => '"'.$Form->get_input('Name').'" <'.$Form->get_input('Email').'>',
		  Subject => 'FormEngine example: Feedback:' . $Form->get_input('Subject')})
      or die "Can't open: $!\n";
  print $mailer "Your comment was:\n".$Form->get_input('Comment');
  $mailer->close();
  $msg = "Thanks! A mail has been send!";
}

print $q->start_html('FormEngine example: Feedback'),
      $Form->get,
      "<center><b>$msg</b></center>",
      $q->end_html;
