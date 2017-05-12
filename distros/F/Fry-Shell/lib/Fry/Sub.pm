package Fry::Sub;
use strict;
use base 'Fry::List';
use base 'Fry::Base';
use base 'Fry::ShellI';
our @ISA;
our $LibClass = "Fry::Sub::_Methods";
package Fry::Sub::_Methods;
package Fry::Sub;
push(@ISA,'Fry::Sub::_Methods');
my $list = {};
sub list { return $list }

sub _default_data {
	{
		subs=>{
			normal=>{qw/a n sub parseNormal/},
			menu=>{qw/a m sub parseMenu/},
			eval=>{qw/a e sub parseEval/},defaultTest=>{},
			empty=>{},
			cmd_normal=>{qw/a cn/},
			cmd_alias=>{qw/a ca/},
			cmd_extra=>{qw/a ce/},
			#cmdList=>{qw/a cl/},

		}
	}
}
#Class Methods
sub defaultNew {
	my %opt = (ref $_[-1] eq "ARRAY") ? @{pop(@_)} : ();
	my ($cls,%arg) = @_;


	$cls->manyNew(%arg);
	for my $cmd (keys %arg) {
		$cls->set($cmd,'sub',$cmd) if (! $cls->attrExists($cmd,'sub'));
	}
	#not used for now
	push(@Fry::Sub::_Methods::ISA,$opt{module}) if (exists $opt{module} && $opt{module} !~ /^(Fry::Sub|Fry::Shell)$/);
}
sub call {
	my ($cls,$a_sub,@args) = @_; 
	my $sub = $cls->anyAlias($a_sub); 
	$cls->callSubAttr(id=>$sub,attr=>'sub',args=>\@args);
}
sub subHook {
	my ($cls,%arg) = @_;
	my $chosensub = $cls->Var($arg{var});
	my @args = (ref $arg{args} eq "ARRAY") ? @{$arg{args}} : $arg{args} ;
	if ($cls->findAlias($chosensub)) {
		$cls->call($chosensub,@args)
	}	
	else { $cls->call($arg{default},@args) } 
}

#utility methods- currently aren't defined as objects but may
#soon be for organization purposes
	sub chooseItems {
		my ($o,@choices) = @_;
		$o->View->list(@choices);
		my $input = $o->Rline->stdin("Choose items: ");
		return ($o->parseNum($input,@choices) );
	}	
	sub _require ($$$) {
		my %opt =  (ref $_[-1] eq "HASH") ? %{pop @_} : ();
		my $cls = ref $_[0] || $_[0]; shift;
		my $class = shift;
		my $message = shift || "";
		eval "require $class"; 
		if ($@) {
			$message .=  ": $@";
			($opt{warn}) ? warn($message) : die($message);
		}
	}
	sub useThere ($$$) {
		my ($o,$useclass,$thereclass) = @_;
		#my $original_package = caller();
		eval "package $thereclass; use $useclass"
	}
	sub spliceArray ($$$) {
		my ($o,$array,$goner) =@_; 
		@$array = grep (!/^$goner$/,@$array);
	}
##The rest are sub objects or could be
#parse subs	
	sub parseNormal ($$) { return split(/\s+/,$_[1]) }	
	sub parseEval ($$) { 
		my ($o,$input) = @_;
		my $splitter = $o->Var('eval_splitter');
		my (@noneval,@eval,$cmd);	

		if ($input =~ $splitter) {
			my ($noneval,$eval) = split(/$splitter/,$input,2);
			@noneval = $o->parseNormal($noneval);
			@eval = "$eval";
		}
		else {
			($cmd,@eval) = split(/\s+/,$input,2);
			@noneval = $cmd;
		}
		my $text = '@eval';
		eval "$text = (@eval)";
		#eval { @eval = ("@eval") };
		die("invalid evaled statement: $@") if ($@);
		return (@noneval,@eval);
	}
	sub parseMenu ($$) {
		#d: creates @cmd_beg,@entry and @save from @args
		#my ($o,@args) = @_;
		my $o  = shift;
		my @args = split(/ /,shift());
		my @cmd_beg = shift (@args);
		my $i = 0;
		#td: fix uninitialized warning
		no warnings;

		if ($args[0] ne "") {
			#push anything that isn't a num choice to @cmd_beg
			while (($args[$i] !~ /\b\d+\b/) && ($args[$i] !~ /\b\d+-\d+,?/) && @args > 0) {
				push (@cmd_beg, shift(@args));
			}
		}

		my @save = $o->_parseMultiNum(\@args);
		if (@args > 0) { return (@cmd_beg,@save,@args);	}
		else {return (@cmd_beg,@save,@args); }
	}
	sub _parseMultiNum ($@) {
		my ($o,$args) = @_;
		my (@save,@entry,$i);
		#td: fix uninitialized warning
		no warnings;

		#@entry-contains num choices
			while (($args->[$i] =~ /\b\d+\b/) || ($args->[$i] =~ /\d-\d,?/)) {
				push(@entry,$args->[$i]);
				shift(@$args);
				$i++;
			}

		#save chosen lines of @lines into @save
		foreach (@entry) { @save = $o->parseNum($_,@{$o->Var('lines')})};
		return @save;
	}
	sub parseNum ($@){
		my $class = shift;
		my @save;my $e;my $count; 
		my ($entry,@choose) = (@_);
		#td: fix unitialized warning
		no warnings;
		die("Invalid argument, $entry , passed to &parse_num. Doesn't contain any numbers.")
	       	if ($entry !~ /\d/);

		my @entries = split(/,/,$entry);
		foreach $e (@entries) {
			if ($e =~ /-/) {
				my ($min,$max) = split("-",$e);
				for( $a = $min;$a <= $max;$a++) {
					$save[$count]=$choose[$a-1];  #note that -1 is there for the offset b/n the arrays
					$count++;
				}
			}
			else { $save[$count]=$choose[$e-1]; $count++;} #note that -1 is there for the offset b/n the arrays
		}
		return @save;
	}
	sub parseChunks($$) {
		my ($o,$input) = @_;
		my $pipe_char = $o->Var('pipe_char');
		return split(/$pipe_char/,$input);
	}	
	sub parseMultiline($\$) {
		my ($o,$input) = @_;
		$$input =~ s/\n//g;	
	}
	sub parseOptions ($\$) {
		my ($o,$input) = @_;
		my %opt;
		#split just in case input is scalar
		my @args = split(/ /,$$input);
		#to avoid uninit pattern match of args
		no warnings;
		#could've solved w/: push(@args,'')

		while ($args[0] =~ /^-\w/) {

			#shift off '-'
			my $option = substr($args[0],1) || "";

			#variables and subs + flag = 0
			if ($option =~ /=/) {
				my ($key,$value);
				($key,$value) = split(/=/,$option); $opt{$key} = $value;
			}
			#flags
			else { $opt{$option} =1 }

			shift @args;
		}
		$$input = "@args";
		return %opt;
	}
#cmd autocompletion
	sub cmd_alias {$_[0]->cmd->listAliasAndIds }
	sub cmd_normal { $_[0]->cmd->listIds }
	#sub cmd_extra { $_[0]->lib->allAttr('cmds') }
	#sub cmdList ($) { ($_[0]->Flag('extra_cmds') ) ? $_[0]->lib->allAttr('cmds') : $_[0]->cmd->listIds }
#other
	sub empty {}
	sub defaultTest ($) { return 1}
1;
__END__
Serves as a handler for various subs shared by modules
Allows aliasing of sub,verification of type,maybe tests to verify its a type

sub autoViewHandler {
	for $sub (@stack) {
		if(my $condsub =  $cls->get($sub,'cond')) {
			if($cls->call($condsub,@args)){
				$cls->get($sub,'view') && $cls->call($cls->get($sub,'view'),@args);
				return
			}	
			next;
		}
		#warning
	}
}
sub call2 {
	my ($cls,$a_sub,@args) = @_; 
	my $sub = $cls->anyAlias($a_sub); 
	if (my $method = $cls->get($sub,'sub')) {
		#sub called as fn
		return $cls->$method(@args);
	}
	#undefined sub
	else { return $cls->$sub(@args) }
}
sub AUTOLOAD {
	#can use for prettier call of sub ie $o->Sub->_require('blah') instead of $o->Sub('require','blah');
	our $AUTOLOAD;
	$AUTOLOAD =~ s/^.*::(\w+)$/\1/;
	#__PACKAGE__->$AUTOLOAD(@_);
	print "here with $AUTOLOAD, @_\n";
}
sub createSubs {
	my ($cls,@subs) = @_;
	no strict 'refs';

	my $caller = "Fry::Shell";

	for (@subs) {
		*{"${cls}::$_"} = *{"${caller}::$_"}
	}
}


__END__	

=head1 NAME

Fry::Sub - Class for shell subroutines

=head1 DESCRIPTION 

This class mainly provides a means to pick and choose among a group of subroutines that have the
same functionality via &subHook. It is also serving as a storage class for practical subroutines
to be reused by any library.

=head1 PUBLIC METHODS

	Subroutine Methods
		call($a_sub,@args): Calls given subroutine id or alias with its arguments.
		subHook(%args): Creates a subroutine hook.
			Has the following keys:
			var: Variable containing current id of a subroutine object.
			default: Default subroutine id to call if var is set to an invalid subroutine object.
			args: Optional,argument passed to subroutine.
	Practical Subroutines
		chooseItems(@choices): Presents the given choices in a menu format, waits for input
			to choose items and returns chosen items. The input is parsed by parseNum,
			see it for input format.
		spliceArray($arrayref,$value): Deletes value from given arrayref.
		useThere($package,$useclass): The $useclass is used in the given $package.
	Parse Subroutines
		parseChunks($input): Splits input line with pipes into separate commands.
		parseMultiline(\$input): Parses multiline input.
		parseOptions(\$input): Parses options from input.
		parseNormal($input): Default parser for command section of input, splitting commands
			and arguments by whitespace.
		parseEval($input): Parser that parses part of the line with &parseNormal and evals the
			rest. The variable eval_splitter determines the splitting point. This
			parser is used often with the &objectAct command:

			-p=e objectAct selectall_arrayref,,'select * from pmodule'

		parseMenu($input): Parser used by menu option. Substitutes a number format with values.
			The number format is a comma separated list of values. A range of values
			can be specified with a '-' between numbers. Valid number formats are
			1-5,8,12 and 1,8,4 .
		parseNum($entry,@args): Used by parseMenu to substitute numbers. Same format as
			parseMenu but only accepting one entry.
	CmdList Subroutines
		cmd_normal(): lists all object ids from command class
		cmd_alias(): lists all object ids and aliases from command class
	Other
		empty(): empty subroutine, usually serves as a default subroutine for subroutine hooks

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
