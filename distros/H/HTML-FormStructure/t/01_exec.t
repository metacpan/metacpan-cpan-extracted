use strict;
use Test::More;

BEGIN {
    eval { require HTML::FormStructure; };
    plan $@ ? (skip_all => 'no HTML::FormStructure'): ('no_plan');
    use_ok 'HTML::FormStructure';
}

use CGI;

{
    package main;
    my $cgi  = CGI->new;
    $cgi->param(user_name   => 'toona');
    $cgi->param(user_tel_no => '00-0000-0000');
    $cgi->param(email       => 'toona@cpan.org');
    $cgi->param(sex         => 1);
    $cgi->param(mailmag     => 1);
    $cgi->param(pref        => 3);
    $cgi->param(year        => '1979');
    $cgi->param(month       => '05');
    $cgi->param(day         => '10');
    my $opt = { form_accessors  => [qw(foo bar baz)], 
		query_accessors => [qw(foo bar baz)], };
    my $form = HTML::FormStructure->new(&resource,$cgi,$opt);
    my @err;
    push @err, qq/fail : list_ref/
	unless scalar @{$form->list_as_arrayref} eq '7';
    my @list_min_limited  = $form->have('more');
    my @list_max_limited  = $form->have('less');
    my @list_validated    = $form->have('be');
    my @list_consisted    = $form->have('consist');
    #my @group             = $form->group('type');
    push @err, qq/fail : list_min_limited/
	unless scalar @list_min_limited eq '7';
    push @err, qq/fail : list_max_limited/
	unless scalar @list_max_limited eq '7';
    push @err, qq/fail : list_validated/
	unless scalar @list_validated   eq '7';
    push @err, qq/fail : list_consisted/
	unless scalar @list_consisted   eq '1';
    for my $q ($form->list_as_array) {
	$q->is_checked('1');
	$q->is_selected('1');
	$q->add(tag_attr => 'some = "tag" ');
	$q->add(tag_attr => 'size = "10" ');
	$form->$_('hoge') for qw(foo bar baz);
    }
    $form->consist_query;
    $form->store_request;
    push @err, qq/fail : param/
	unless $form->param('user_name') eq 'toona';
    push @err, qq/fail : fetch/
	unless $form->fetch('user_name')->store eq 'toona';
    $form->validate;
    $form->$_() for qw(foo bar baz);
    warn $form->fetch('birthday')->store;
    die $_ for @err;
}

sub valid_tel   { 1 }
sub valid_email { 1 }
sub valid_date  { 1 }
sub is_only_number { 1 }

sub resource {
    return [{
	name => 'user_name',
	type => 'text',
	more => 1,
	less => 255,
        column => 1,
    },{
	name => 'user_tel_no',
	type => 'text',
	more => 1,
	less => 255,
	be   => [qw(valid_tel)],
	column => 1,
    },{
	name => 'email',
	type => 'text',
	more => 1,
	less => 255,
	be   => [qw(valid_email)],
	column => 1,
    },{
	name    => 'sex',
	type    => 'radio',
	value   => [1,2],
	checked => 1,
	column => 1,
    },{
	name    => 'mailmag',
	type    => 'checkbox',
	value   => [1,2,3],
	checked => [1,2,3],
	column => 1,
    },{
	name     => 'pref',
	type     => 'select',
	value    => [1,2,3,4,5],
	selected => 3,
	column => 1,
	be     => [sub { return shift },sub { 1 }]
    },{
	name    => 'birthday',
	type    => 'text',
	be      => [qw(valid_date)],
	more    => 1,
	less    => 255,
	column  => 1,
	consistf => '%04d-%02d-%02d',
	consist => [{
	    name => 'year',
	    type => 'text',
	    more => 1,
	    less => 4,
	    be   => [qw(is_only_number)],
	},{
	    name => 'month',
	    type => 'text',
	    more => 1,
	    less => 2,
	    be   => [qw(is_only_number)],
	},{
	    name => 'day',
	    type => 'text',
	    more => 1,
	    less => 2,
	    be   => [qw(is_only_number)],
	}],
    }];
}
