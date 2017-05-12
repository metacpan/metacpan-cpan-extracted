package Fry::ReadLine::Gnu;
use Term::ReadLine;
use Term::ReadLine::Gnu;
use base 'Fry::ShellI';
our $DEBUG =0;
use strict;
our $HISTFILE = $ENV{HOME} ."/.fry_history";
our ($term,@begin_cmd);
my $cls = __PACKAGE__;
sub setup {
	my $cls = shift;
	$term = Term::ReadLine::Gnu->new('fry');
	$term->Attribs->{completion_function} = sub { complete($cls,@_)};
	$term->MinLine(undef);
	$term->stifle_history(undef);
	$term->ReadHistory($HISTFILE);
	@begin_cmd = $term->GetHistory;
	#$term->bind_key(ord "\ce",'display-readline-version');
	#$term->add_defun('blah'=>\&blah,ord "\ce");
	#$term->Attribs->{editing_mode} = 0;
	#$term->Attribs->{keymap} = "vi";
	#$term->add_defun('test',sub {print "bloh\n";},ord "\ct");
	#use Data::Dumper;
	#print Dumper $term->Attribs;
}
sub stdin {
	my ($class,$prompt) = @_;
	$class->view("\n");
	my $entry = $term->readline($prompt) || "";#|| $class->_die("term failed : $@");
	return $entry;
}
sub prompt {
	my ($class,$prompt) = @_;
	$class->view("\n");
	my $entry = $term->readline($prompt) || "";#|| $class->_die("term failed : $@");
	$term->addhistory($entry);
	return $entry;
}
#inner
sub complete {
	my ($cls,$text,$line,$start,$end) = @_;

	#won't complete existing word unless given matches start w/ existing word
	#options
	if ($line =~ /-\w*$/) { 
		print "sub1\n" if $DEBUG;
		return map {s/^/-/;$_} $cls->listAll('opt');
	}
	#cmds that match return of previous cmd 
	#first cmd in chunk
	elsif (substr($line,0,$start) =~ /(^|\|)\s*$/) {
		print "sub2\n" if $DEBUG;
		return ($cls->call(sub=>'subHook',var=>'cmdlist',default=>'empty'));
	}
	#args of cmd
	#elsif ($line =~ /([^-]\w+)\s*(.*)/) {
	#print "sub3\n" if $DEBUG;
	#return $cls->completeCmdArgs($1,$2);
	#}
	#filename autocompletion 
	print "sub4\n" if $DEBUG;
	return $term->Attribs->completion_matches($text,$term->Attribs->{filename_completion_function}); 
}
sub completeCmdArgs {
	my ($cls,$cmd,$args) = @_;

	$cmd = $cls->cmd->anyAlias($cmd);
	if ($cls->cmd->objExists($cmd)) {
		if ($cls->cmd->attrExists($cmd,'arg')) {
			#w: chopargtype
			my $argtype = substr($cls->cmd->get($cmd,'arg'),1);
			#print "cmd: $cmd,$argtype,$args\n";
			my $sub = "cmpl_$argtype";
			if ($cls->sub->can($sub)) { return $cls->Sub($sub,$args) }
			else { warn("$sub not found",2) }
		}
		elsif ($cls->cmd->attrExists($cmd,'cmpl')) {
			my $cmpl_sub = $cls->cmd->get($cmd,'cmpl');
			if (ref $cmpl_sub eq "CODE") { 
				return $cmpl_sub->($cls->sub,$args)
			}
			elsif ($cls->sub->can($cmpl_sub)) { return $cls->Sub($cmpl_sub,$args)}
			else {	warn("Invalid cmpl attribute",2) }
		}
		else { warn("No autocompletion defined for this command's arguments",2); return }
	}
}
1;

__END__	

=head1 NAME

Fry::ReadLine::Gnu - ReadLine plugin for Fry::Shell which uses Term::ReadLine::Gnu.

=head1 DESCRIPTION 

Note: This module is being overhauled so the syntax for defining autocompletion might change. Also
completion for a command's arguments is currently disabled.

This module supports command history and autocompletion of options and commands. If a command has an arg
attribute and defines an autocompletion subroutine then a command's expected arguments can be
autocompleted. A completion subroutine must have the name cmpl_$arg where $arg is the name of
the arg attribute. If autocompletion is called and none of the above autocompletion cases are
detected then it defaults to autocompleting filenames. 

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
