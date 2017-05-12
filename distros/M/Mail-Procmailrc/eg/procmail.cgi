#!/usr/local/bin/perl -wT
use strict;

## Scott Wiersdorf
## Created: Mon Jul 29 08:34:16 MDT 2002
## $Id: procmail.cgi,v 1.1 2002/07/29 18:33:54 scottw Exp $

## procmail.cgi
##
## provided with Mail::Procmailrc as a toy to play with to help learn
## how Mail::Procmailrc works.
##
## You should only have to change $procmailrc below for this to work.
## Point it to your favorite procmailrc file and let it rip (make a
## backup first)! The file must be readable/writable by the user your
## web server runs as. If you specify a file that does not exist, it
## will be created for you.


##
## WARNING * ACHTUNG * AVISO ##
##
## This program modifies /etc/procmailrc (or whatever you've set
## $procmailrc below to point to). This program is provided AS IS
## under the terms of the Perl Artistic License to illustrate some
## possible uses of Mail::Procmailrc.
##
## This program inherently is a security problem because:
##
## a) in order to edit /etc/procmailrc it must run at the same or
##    higher privileges than the owner of that file (meaning your web
##    server is running with elevated privileges, which is usually a
##    no-no).
## b) it provides no authentication mechanism (do you want _everybody_
##    to add/remove recipes to _your_ procmailrc file?)
## c) any globally writable /etc/procmailrc file is really dangerous
##    (imagine someone writing your procmail action line as:
##
##        { BYEBYE=`rm -rf /` }
##
## The author assumes no liability for damages of any kind caused by
## (mis)?use of this program. Please see paragraph 10 of the Artistic
## License distributed with Perl. Have a nice day!
##


use Mail::Procmailrc;
use CGI qw(:standard);

##
## CHANGE THIS to point to your .procmailrc file
##
my $procmailrc = '/etc/procmailrc';

my $q = new CGI;
my $del_info;
my $add_info;

print $q->header;

## form logic here
SUBMIT: {
    if( $q->param('Submit') ) {
	my $pmrc   = new Mail::Procmailrc($procmailrc);
	my $recipe = undef;

	for my $rec ( @{$pmrc->recipes} ) {
	    next unless $rec->info->[0] =~ /^\#\# spam conditions/;
	    $recipe = $rec;
	    last;
	}

	## add a new condition
	if( $q->param('Submit') eq 'submit' && defined $q->param('rule') ) {
	    my $rule     = $q->param('rule');
	    my $weight   = ( length($q->param('weight')) ? $q->param('weight') : 1);
	    my $exponent = ( length($q->param('exponent')) ? $q->param('exponent') : 0);

	    unless( $recipe && $recipe->info->[0] =~ /^\#\# spam conditions/ ) {
		$recipe = new Mail::Procmailrc::Recipe;
		$recipe->info(["## spam conditions"]);
		$recipe->flags(":0HB:");
		$recipe->action( "/dev/null" );

		## add to our rc file
		$pmrc->push($recipe);
	    }

	    my $condition = "* $weight^$exponent $rule";
	    push @{$recipe->conditions}, $condition;
	    $pmrc->flush;

	    $add_info = "Added condition: <tt>$condition</tt><p>\n";
	}

	## delete an existing condition
	elsif( $q->param('Submit') eq 'delete' && defined $q->param('cond') ) {
	    my $cond   = $q->param('cond');
	    last SUBMIT unless $cond =~ /^\d+$/;

	    unless( $recipe ) {
		print "No recipe found!\n";
		last SUBMIT;
	    }

	    my @tmp = @{$recipe->conditions};
	    last SUBMIT if $cond > $#tmp;
	    my $old = splice( @tmp, $cond, 1 );

	    ## if we have conditions...save them
	    if( scalar @tmp ) {
		$recipe->conditions(\@tmp);
	    }

	    ## otherwise delete the empty recipe from the object
	    else {
		$pmrc->delete($recipe);
	    }
	    $pmrc->flush; ## ... and flush it to disk

	    $del_info = "Deleted condition: <tt>$old</tt><p>\n";
	}
    }
}


## form display here
print $q->start_html("Spam Criteria"), 
  $q->strong('Add new spam criterion:'), p;
print "<ul>" . $add_info . "</ul>" if $add_info;
print $q->start_form,
  "Weight: ", $q->textfield(-name=>"weight", -default=>"1", -size=>5),
  "Exponent: ", $q->textfield(-name=>"exponent", -default=>"0", -size=>3),
  "Expression: ", $q->textfield('rule'),
  $q->submit("Submit", "submit"), $q->reset, $q->end_form;

print $q->strong("Click a condition to delete:"), p;
print "<ul>" . $del_info  . "</ul>" if $del_info;

my $pmrc = new Mail::Procmailrc($procmailrc);
for my $rec ( @{$pmrc->recipes} ) {
    next unless $rec->info->[0] =~ /^\#\# spam conditions/;

    ## this is our spam recipe
    print $rec->flags, "<br>\n";

    my $i = 0;
    my $self = $q->url;
    for my $cond ( @{$rec->conditions} ) {
	print '<a href="' . $self . '?Submit=delete;cond=' . $i . '">' . 
	  $q->escapeHTML($cond), "</a><br>\n";
	$i++;
    }

    print $rec->action, "<br>\n";
}

print p, $q->end_html;
exit;
