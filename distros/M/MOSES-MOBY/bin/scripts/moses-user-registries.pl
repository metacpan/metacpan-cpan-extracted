#!/usr/bin/perl -w
#
# Prepare the stage...
#
# $Id: moses-user-registries.pl,v 1.3 2008/02/21 00:12:55 kawas Exp $
# Contact: Edward Kawas <edward.kawas@gmail.com>
# -----------------------------------------------------------

BEGIN {
    use Getopt::Std;
    use vars qw/ $opt_h $opt_F /;
	getopt;
    # usage
    if ($opt_h) {
	print STDOUT <<'END_OF_USAGE';

Add/Remove user defined persistent registries for use with MoSeS.
This utility can remove only those registries contained in your 
USER_REGISTRIES file specified in your config file.

Usage: [-F]

    Provided that you provide the following information, a 
	registry is added to USER_REGISTRIES so that you can 
	access it like all of the other 'known registries':
	
	  registry_name - a human readable name for the registry
	  synonym       - a nickname to access the registry
	  endpoint      - the endpoint for the registry
	  uri           - the registry namespace
	  contact       - registry contact information
	  description   - a human readable textual description of the registry
    
    An existing registry is not overwritten - unless an option -F
	is specified.

END_OF_USAGE
    exit (0);
    }

    sub say { print @_, "\n"; }
    sub check_module {
		eval "require $_[0]";
		if ($@) {
		    say "Module $_[0] not installed.";
		} else {
		    say "OK. Module $_[0] is installed.";
		}
    }
    use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;
	if (MSWIN) {
		check_module ('Term::ReadLine');
		{
	    	local $^W = 0;
		    $SimplePrompt::Terminal = Term::ReadLine->new ('Installation');
		}
	} else {
		check_module ('IO::Prompt');
		require IO::Prompt; import IO::Prompt;
    }
    say 'Modify Your Persistant Registries';
    say '------------------------------------------------------';

    say;
}

use MOSES::MOBY::Cache::Central;
use MOSES::MOBY::Cache::Registries;
use English qw( -no_match_vars ) ;
use strict;

# different prompt modules used for different OSs
# ('pprompt' as 'proxy_prompt')
sub pprompt {
    return prompt (@_) unless MSWIN;
    return SimplePrompt::prompt (@_);
}


# what registry to use
sub prompt_for_action {
    my $action = pprompt ("Would you like to add or remove a registry? [a] ",
			   -m => [(' Add a new persistent user registry', ' Remove a persistent user registry', ' Quit')]);
    return $action ||= 'a';
}



# --- main ---
no warnings 'once';
$opt_F ? say ("In over-write mode\n") : say ("Not in over-write mode ... \n") ;

my $cache = new MOSES::MOBY::Cache::Central;
while(1) {
my $action = prompt_for_action;
say($action);
if ($action =~ m"^ Add a new") {
	my $force = $opt_F;
	my $reg = $cache->registries->all();
	my $name = pprompt("What is the name of your registry: ");
	
	my $syn = pprompt("Please provide a short nickname: ");
	while ($syn =~ m"^http://" or (not $syn =~ m"\w+")
		or (not ( (not defined $reg->{$syn}) or $force ) ) 
	) {
		$syn = pprompt("Invalid nickname entered. Please provide a different nickname: ");
	}
	
	my $text = pprompt("Please provide a description for the registry: ");
	my $endpoint = pprompt("Please enter the endpoint for the registry: ");
	my $namespace = pprompt("Please enter the registry URI: ");
	my $contact = pprompt("Please enter registry contact information: ");
	
	say ("ref is: " . scalar ($endpoint));


	my %args = (
		endpoint  => ref($endpoint) eq 'IO::Prompt::ReturnVal' ? $endpoint->{value} : $endpoint,
		namespace => ref($namespace) eq 'IO::Prompt::ReturnVal' ? $namespace->{value} : $namespace,
		name      => ref($name) eq 'IO::Prompt::ReturnVal' ? $name->{value} : $name,
		contact   => ref($contact) eq 'IO::Prompt::ReturnVal' ? $contact->{value} : $contact,
		public    => 'yes',
		text      => ref($text) eq 'IO::Prompt::ReturnVal' ? $text->{value} : $text,
		synonym   => ref($syn) eq 'IO::Prompt::ReturnVal' ? $syn->{value} : $syn
	);

	$args{force} = 1 if $opt_F;
	
	require Data::Dumper;
	say ( "The following will be added to your list of registries:\n" 
		. Data::Dumper->Dump ( [\%args], ['Details'] ));
	
	my $suc = $cache->registries->add(%args);
	say("Successfully added the registry to your user registry file!") if $suc == 1;
	say("There was an unknown error. Please consult your log file to\nget the exact nature of the problem") 
		if $suc == 0;
	say("Some of the parameters were not acceptable. Please try again.") if $suc == -1;
	say("The synonym that you chose already existed. Please try again.") if $suc == -2;
	
} elsif ($action =~ m"^ Remove a persistent") {

	my @regs = $cache->registries->list;
    my $registry = pprompt ("What registry would you like to remove? ",
			   -m => [@regs]);
	if ('y' eq pprompt ('Are you sure that you would like to remove $registry [n]? ', -ynd=>'n')) {
		my $suc = $cache->registries->remove($registry);
		say("Successfully removed the registry.") if $suc == 1;
		say("There was some problem removing your registry.") if $suc == 0;
	} else {
		say ("Nothing was removed.");
	}
} else {
say 'Done.';
exit(1);
}
}
# --- End Main ---


package SimplePrompt;

use vars qw/ $Terminal /;

sub prompt {
    my ($msg, $flags, $others) = @_;

    # simple prompt
    return get_input ($msg)
	unless $flags;

    $flags =~ s/^-//o;    # ignore leading dash

    # 'waiting for yes/no' prompt, possibly with a default value
    if ($flags =~ /^yn(d)?/i) {
	return yes_no ($msg, $others);
    }

    # prompt with a menu of possible answers
    if ($flags =~ /^m/i) {
	return menu ($msg, $others);
    }

    # default: again a simple prompt
    return get_input ($msg);
}

sub yes_no {
    my ($msg, $default_answer) = @_;
    while (1) {
	my $answer = get_input ($msg);
	return $default_answer if $default_answer and $answer =~ /^\s*$/o;
	return 'y' if $answer =~ /^(1|y|yes|ano)$/;
	return 'n' if $answer =~ /^(0|n|no|ne)$/;
    }
}

sub get_input {
    my ($msg) = @_;
    local $^W = 0;
    my $line = $Terminal->readline ($msg);
    chomp $line;                 # remove newline
    $line =~ s/^\s*//;  $line =~ s/\s*$//;   # trim whitespaces
    $Terminal->addhistory ($line) if $line;
    return $line;
}

sub menu {
    my ($msg, $ra_menu) = @_;
    my @data = @$ra_menu;

    my $count = @data;
#    die "Too many -menu items" if $count > 26;
#    die "Too few -menu items"  if $count < 1;

    my $max_char = chr(ord('a') + $count - 1);
    my $menu = '';

    my $next = 'a';
    foreach my $item (@data) {
        $menu .= '     ' . $next++ . '.' . $item . "\n";
    }
    while (1) {
	print STDOUT $msg . "\n$menu";
        my $answer = get_input (">");

	# blank and escape answer accepted as undef
	return undef if $answer =~ /^\s*$/o;
	return undef
	    if length $answer == 1 && $answer eq "\e";

	# invalid answer not accepted
	if (length $answer > 1 || ($answer lt 'a' || $answer gt $max_char) ) {
	    print STDOUT "(Please enter a-$max_char)\n";
	    next;
	}

	# valid answer
        return $data[ord($answer)-ord('a')];
    }
}


__END__
