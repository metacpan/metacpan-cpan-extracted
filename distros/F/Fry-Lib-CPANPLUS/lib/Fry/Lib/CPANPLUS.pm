package Fry::Lib::CPANPLUS;
use strict;
BEGIN {
    use vars        qw(@ISA $VERSION);
    @ISA        =   qw/CPANPLUS::Shell::_Base/;
    $VERSION    =   '0.01';
}
#our @ISA = qw/CPANPLUS::Shell::_Base/;

use CPANPLUS::Shell ();
use CPANPLUS::Backend;
use CPANPLUS::I18N;
use CPANPLUS::Tools::Term;
use CPANPLUS::Tools::Check qw[check];

use Cwd;
use Data::Dumper;
my ($cpan,$cp,@module_list,@author_list);
my $basic_format = "%5s %-55s %8s %-10s\n";

sub _default_data {
	return {
		cmds=>{
			cpanHelp=>{qw/a ch/,d=>'show cpanplus style help for cpanplus functions'},
			reloadIndices=>{qw/a cx/,d=>'reload CPAN indices'}, 
			writeBundleFile=>{qw/a cb/,d=>'write a bundle file for your configuration'},
			displayLastSearch=>{qw/a cw/,d=>'display the result of your last search again'},
			listModulesToUpdate=>{qw/a co arg @module/,
				d=>'list installed module(s) that aren\'t up to date'},
			testModules=>{qw/a ct arg @module/,d=>'test module(s)'},
			installModules=>{qw/a ci arg @module/,d=>'install module(s)' },
			downloadModules=>{qw/a cd arg @module/,d=>'download module(s)'},
			moduleDetails=>{qw/a cl arg @module/,d=>'display detailed information about module(s)'},
			checkReports=>{qw/a cc arg @module/,d=>'check for module report(s) from cpan-testers'},
			readMe=>{qw/a cr arg @module/,d=>'display README files of module(s)'},
			authorDistros=>{qw/a cf arg @author/,d=>'list all distributions by author(s)'},
			uninstallModules=>{qw/a cu arg @module/,d=>'uninstall module(s)'},
			expandINC=>{qw/a ce arg $dir/,d=>'add directories to your @INC'},
			promptInModule=>{qw/a cz arg @module/,
				d=>'extract module(s) and open command prompt in it' },
			searchModulesbyAuthor=>{qw/a ca arg @author/,d=>'search by author(s)'},
			searchModulesbyModule=>{qw/a cm arg @module/,d=>'search by module(s)'},
			setConfigOptions=>{qw/a cs arg $cplus_option/,d=>'set configuration options for this session'},
			changeOrSaveConfiguration=>{qw/a cS/,
				d=>'reconfigure settings / save settings'},
			printErrorStack=>{qw/a cp/,d=>'print the error stack (optionally to a file)'},  
			listInstalled=>{qw/a cli/,d=>'determines if module(s) are installed'},
			listInstalledRegex=>{qw/a clir/,d=>'returns installed modules matching regexp'},
			listAuthorsRegex=>{qw/a car/,d=>'returns authors matching regexp'},
		}
	}
} 
#obj: $cpan,$mod,$auth,$conf,$status
sub _initLib {
	$cpan = new CPANPLUS::Backend;
}

#commands
	sub cpanHelp {
		my $o = shift; 
		my $output; 
		$output .= "[General]\n";
		$output .= $o->printHelpAttr(qw/cpanHelp quit/);

		$output .= "[Search]\n";
		$output .= $o->printHelpAttr(qw/searchModulesbyAuthor
			searchModulesbyModule authorDistros listModulesToUpdate displayLastSearch/);

		$output .= "[Operations]\n";	
		$output .= $o->printHelpAttr(qw/installModules testModules
			uninstallModules downloadModules moduleDetails readMe checkReports
			promptInModule/);

		$output .= "[Local Administration]\n";	
		$output .= $o->printHelpAttr(qw/expandINC writeBundleFile setConfigOptions
			changeOrSaveConfiguration perlExe printErrorStack reloadIndices/);
		$output .= "[New]\n";	
		$output .= $o->printHelpAttr(qw/listAuthorsRegex listInstalledRegex
			listInstalled/);

		$o->view($output);
	}
        #sub blah { $cpan->error_object->trap(error=>"@_"); }     
	sub displayLastSearch {
		my ($o,@input) = shift;
		my $output;
		my $title = (defined @{$o->Var('lines')})
			? (loc("Here is a listing of your previous search result:"). "\n")
			: (loc("No search was done yet."). "\n");
		$output .=  $title;

		my $i;
		for my $obj (@{$o->Var('lines')}) {

			my $fmt_version = $o->_format_version( version => $obj->version );
			$output .= sprintf $basic_format, ($i+1), ($obj->module, $fmt_version, $obj->author);
			$i++;
		}
		$o->view($output);
	}
	##$cpan
	sub reloadIndices {
		my ($o,@arg) = @_;

		$o->view(loc("Fetching new indices and rebuilding the module tree"), "\n");
		$o->view(loc("This may take a while..."), "\n");

		#$cpan->reload_indices(update_source => 0);#, %$options);
		$cpan->reload_indices(@arg);#, %$options);
	}
	sub writeBundleFile {
		my $o = shift;
		$o->view(loc(qq[Writing bundle file... This may take a while\n]));
		my $rv = $cpan->autobundle;

		$o->view(($rv->ok)
			? loc( qq[\nWrote autobundle to %1\n], $rv->rv )
			: loc( qq[\nCould not create autobundle\n] )
		);
	}		
	sub testModules { shift->testInstall('test',@_) }
	sub installModules { shift->testInstall('install',@_) }
	sub testInstall {
		my ($o,$target,@modules) = @_;
		my $prompt = ($target eq "install") ? loc('Installing') : loc('Testing');
		$o->_statusMessages($prompt,@modules);

		### try to install them, get the return status back
		my $href = $cpan->install( target	  => $target, modules	 => [ @modules ],);
		my $status = $href->rv;

		#view
		for my $key ( sort keys %$status ) {

			$o->view( $status->{$key}
				? (loc("Successfully %tense(%1,past) %2", $target, $key), "\n")
				: (loc("Error %tense(%1,present) %2", $target, $key), "\n" )
			);
		}
		
		my $flag;
		for ( @modules ) { 
			$flag++ unless ref $href->rv && $href->rv->{$_} 
		}
		
		if( $href->ok and !$flag ) {
			$o->view(loc("All modules %tense(%1,past) successfully", $target), "\n");
		} else {
			$o->view(loc("Problem %tense(%1,present) one or more modules", $target), "\n");
			#td?: if error stack implemented
			#$o->_warn(loc("*** You can view the complete error buffer by pressing '%1' ***\n", 'p'))
				#unless $cpan->configure_object->get_conf('verbose');
		}
	}
	sub listInstalled {
		my ($o,@modules) = @_;
		our $modtree = $cpan->module_tree();

		$o->_statusMessages ('Checking',@modules);
		my $res = $cpan->installed(modules => @modules ? \@modules : undef );

		my @installed_modules = sort keys %{$res->rv};
		$o->saveArray(@installed_modules) if ($o->Flag('menu'));
		$o->view("Of the given modules, the following are installed:\n\n");
		return @installed_modules;
	}
	sub listInstalledRegex {
		my ($o,$regex) = @_;
		if (@_ < 2) { $o->view("No regexp passed\n.")}
		else { 
			my @modules = grep(/$regex/,sort $o->listInstalled);
			$o->saveArray(@modules) if ($o->Flag('menu'));
			return @modules;
		}
	}
	sub listAuthorsRegex {
		my ($o,$regex) = @_;
		if (@_ < 2) { $o->view("No regexp passed\n.")}
		else { 
			my @modules = grep(/$regex/,sort $o->authorList);
			$o->saveArray(@modules) if ($o->Flag('menu'));
			return @modules;
		}
	}
	#?:worth implementing
	#sub listModulesRegex {
	sub listModulesToUpdate {
		my ($o,@modules) = @_;
		our $modtree = $cpan->module_tree();

		$o->_statusMessages ('Checking',@modules);

		#default behavior changed: no input is allowed
		#if ("@modules" eq '') { $o->view(loc("No modules to check."), "\n"); return; }

		my @cache = $o->modulesToUpdate(@modules);
		return if (! defined @cache);

		#view
		if (@cache == 0) { $o->view( loc("All module(s) up to date."), "\n") }
		else {

			my $output;
			### pretty print some information about the search
			for (0 .. scalar(@cache)-1) {

				my ($module,$oldversion,$version, $author) = @{$cache[$_]}{qw/module old_version version author/};

				my $have    = $o->_format_version( version => $oldversion); #$res->{$module}->{version} );
				my $can     = $o->_format_version( version => $version );

				my $local_format = "%5s %10s %10s %-40s %-10s\n";

				$output .= sprintf $local_format, ($_ +1), ($have, $can, $module, $author);
			}

			$o->view($output);
		}
		$o->saveArray(@cache);
	}
	sub downloadModules {
		my ($o,@modules) = @_;
		$o->_statusMessages('Fetching',@modules);

		### get the result of our fetch... we store the modules in whatever
		### dir the shell was invoked in.
		my $href = $cpan->fetch(
			fetchdir   => $cpan->configure_object->_get_build('startdir'),
			modules     => [ @modules],
		);
		my $status = $href->rv;

		#view
		my $output;
		for my $key ( sort keys %$status ) {
			$output .= ($status->{$key})
					? (loc("Successfully fetched %1", $key). "\n")
					: (loc("Error fetching %1", $key). "\n")
			;
		}

		$output .= ($href->ok)
				? (loc("All files downloaded successfully"). "\n")
				: (loc("Problem downloading one or more files"). "\n")
		;
		$o->view($output);
	}
	sub	checkReports {
		my ($o,@modules) = @_;

		### get the result of our listing...
		my $res = $cpan->reports(modules => [ @modules] )->rv;

		#view
		my $output;
		foreach my $name (@modules) {
			my $dist = $cpan->pathname(to => $name);
			my $url;

			foreach my $href ($res->{$name} || $res->{$dist}) {
				$output .= "[$dist]\n";

				unless ($href) {
					$output .= loc("No reports available for this distribution."), "\n";
					next;
				}

				foreach my $rv (@{$href}) {
					$output .= sprintf "%8s %s%s\n", @{$rv}{'grade', 'platform'},
										 ($rv->{details} ? ' (*)' : '');
					$url ||= $rv->{details} if $rv->{details};
				}
			}

			if ($url) {
				$url =~ s/#.*//;
				$output .= "==> $url\n\n";
			}
			else { $output .= "\n" }
		}	
		$o->view($output);
	}
	sub moduleDetails { 
		my ($o,@modules) = @_;
		my $href = $cpan->details(modules => [ @modules ] );
		my $res = $href->rv;

		#view
		my $output;
		for my $mod ( sort keys %$res ) {
			unless ( $res->{$mod} ) {
				$output .= loc("No details for %1 - it's probably outdated.", $mod). "\n";
				next;
			}

			$output .= loc("Details for %1", $mod). "\n";
			for my $item ( sort keys %{$res->{$mod}} ) {
				$output.= sprintf "%-30s %-30s\n", $item, $res->{$mod}->{$item}
			}
			$output .=  "\n";
		}
		$o->view($output);
	}
	sub authorDistros {
		my ($o,@modules) = @_;	
		my $cache =[];
		my $href = $cpan->distributions( authors => [ @modules] );
		my $res = $href->rv;

		unless ( $res and keys %$res ) {
			$o->view(loc("No authors found for your query"), "\n");
			return;
		}

		#view
		my $output; 
		for my $auth ( sort keys %$res ) {
			next unless $res->{$auth};

			my $path = '/'.substr($auth, 0, 1).'/'.substr($auth, 0, 2).'/'.$auth;

			my $i;
			for my $dist ( sort keys %{$res->{$auth}} ) {
				$i++;
				push @{$cache}, "$path/$dist"; # full path to dist

				### pretty print some information about the search
				$output .= sprintf $basic_format, $i, $dist, $res->{$auth}->{$dist}->{size}, $auth;
			}
		}
		$o->view($output);
	}
	sub readMe {
		my ($o,@modules) = @_;
		### also takes multiple arguments, so:
		### r POE DBI #works just fine
		### alltho you probably shouldn't do that

		my $href = $cpan->readme( modules => [ @modules ] );
		my $res = $href->rv;

		unless ( $res ) { $o->view(loc("No README found for your query"), "\n"); return; }

		#view
		my $output;
		for my $mod ( sort keys %$res ) {

			unless ($res->{$mod}) {
				$output .= loc("No README found for %1", $mod). "\n";
			} else {
				$output .= $res->{$mod};
			}

			$output .= "\n";
		}
		$o->view($output);
	}
	sub uninstallModules {
		my ($o,@modules) = @_;
		$o->_statusMessages('Uninstalling',@modules);

		my $href = $cpan->uninstall(modules => [ @modules] );
		my $res = $href->rv;

		#view
		my $output;
		for my $mod ( sort keys %$res ) {
			$output .= ($res->{$mod})
				? (loc("Uninstalled %1 successfully", $mod). "\n")
				: (loc("Uninstalling %1 failed", $mod). "\n");
		}

		$output .= $href->ok
				? (loc("All modules uninstalled successfully"). "\n")
				: (loc("Problem uninstalling one or more modules"). "\n");
		$o->view($output);
	}
	sub expandINC {
		my ($o,@input) = @_;
		my $input = "@input";
		### e Expands your @INC during runtime...
		### e /foo/bar "c:\program files"

		### need to fix this so dirs with spaces are allowed ###
		### I thought this *was* the fix? -jmb
		my $rv = $o->_expand_inc(
				lib => [ $input =~ m/\s*("[^"]+"|'[^']+'|[^\s]+)/g ]
		);
	}
	sub promptInModule {	
		my ($o,@modules) = @_;
		$o->_statusMessages(loc('Opening shell for module'),@modules);

		my $conf    = $cpan->configure_object;
		my $shell   = $conf->_get_build('shell');

		unless($shell) {
			$o->view(loc("Your config does not specify a subshell!"), "\n",
				  loc("Perhaps you need to re-run your setup?"), "\n");
			return;
		}

		my $cwd = cwd();

		my $output;
		for my $mod (@modules) {
			my $answer = $cpan->parse_module(modules => [$mod]);
			$answer->ok or next;

			my $mods = $answer->rv;
			my ($name, $obj) = each %$mods;

			my $dir = $obj->status->extract;

			unless( defined $dir ) {
				$obj->fetch;
				$dir = $obj->extract();
			}

			unless( defined $dir ) {
				$output .= ("Could not determine where %1 was extracted to", $mod), "\n";
				next;
			}

			unless( chdir $dir ) {
				$output .= loc("Could not chdir from %1 to %2: %3", $cwd, $dir, $!), "\n";
				next;
			}

			if( system($shell) and $! ) {
				$output .= loc("Error executing your subshell: %1", $!), "\n";
				next;
			}

			unless( chdir $cwd ) {
				$output .= loc("Could not chdir back to %1 from %2: %3", $cwd, $dir, $!), "\n";
			}
			$o->view($output);
		}
	}
	sub searchModulesbyAuthor { shift->searchModules('author',@_) }
	sub searchModulesbyModule { shift->searchModules('module',@_) }
	sub changeOrSaveConfiguration {
		my ($o,$name) = @_;

		### redo setup configuration?
		if ($name =~ m/^conf/i) { $o->setupConfig; return }
		elsif ($name =~ m/^save/i) {
			$cpan->configure_object->save;
			$o->view(loc("Your CPAN++ configuration info has been saved!"), "\n\n");
			return;
		}
	}
	sub setConfigOptions {
		my ($o,$name,$value)  = @_;
		### perhaps we should go with FULL conf names,
		### rather than expanding shortcuts -kane

		### allow lazy config options... not smart but possible ###
		my $conf = $cpan->configure_object;
		my @options = sort $conf->subtypes('conf');
		my $realname;
		for my $option (@options) {
			if (defined $name and $option =~ m/^$name/) {
				$realname = $option;
				last;
			}
		}

		if ($realname) {
			$o->_set_config(
				key	=> $realname,
				value  => $value,
				method => 'set_conf',
			);
		} else {
			my $output; 
			local $Data::Dumper::Indent = 0;
			$output .= loc("'%1' is not a valid configuration option!", $name). "\n" if defined $name;
			$output .= loc("Available options and their current values are:"). "\n";

			my $local_format = "    %-".(sort{$b<=>$a}(map(length, @options)))[0]."s %s\n";

			foreach my $key (@options) {
				my $val = $conf->get_conf($key);
				($val) = ref($val)
							? (Data::Dumper::Dumper($val) =~ /= (.*);$/)
							: "'$val'";
				$output .= sprintf $local_format, $key, $val;
			}
			$o->view($output); 
		}
	}
	sub printErrorStack {
		my ($o,$file) = @_;
		my $stack = $cpan->error_object->summarize();
		$o->_print_stack( stack => $stack, file =>$file);
	}
#tests and completion
	sub t_module { return 1 }
	sub t_author { return 1 }
	sub t_dir { return 1 }
	sub t_cplus_option { return 1}
	sub cmpl_cplus_option { return sort $cpan->configure_object->subtypes('conf') }
	sub cmpl_author { return sort $_[0]->authorList }
	sub cmpl_module { return sort $_[0]->moduleList }
##Internals
	sub moduleList { 
		(defined @module_list) ? print "yay\n" : print "doh\n";
		return (defined @module_list) ? @module_list : keys %{$cpan->module_tree()}
	}
	sub authorList { 
		return (@author_list) ? @author_list : keys %{$cpan->author_tree()} 
	}
	sub searchModules {
		my ($o,$type,@input) = @_;

		### build regexes.. this will break in anything pre 5.005_XX
		### we add the /i flag here for case insensitive searches
		my @regexps = map { "(?i:$_)" } @input;

		my $res = $cpan->search( type =>$type, list => [ @regexps ]);

		### if we got a result back....
		if ( $res and keys %{$res} ) {
			### forget old searches...
			my $cache = [];

			### store them in our $cache; it's the storage for searches
			### in Shell.pm
			for my $k ( sort keys %{$res} ) {
				push @{$cache}, $res->{$k};
			}

			#view
			my $output;
			### pretty print some information about the search
			for (0 .. scalar(@$cache) -1 ) {
				my ($module, $version, $author) =
					@{$cache->[$_]}{qw/module version author/};

				my $fmt_version = $o->_format_version( version => $version );

				$output .= sprintf $basic_format, ($_+1), ($module, $fmt_version, $author);
			}

			$o->saveArray(@$cache);
			$o->view($output);
		} else {
			$o->view(loc("Your search generated no results"), "\n");
			return;
		}
	}
	#for &_set_config
	sub backend {return $cpan }
	sub setupConfig {
		my $o = shift;
		CPANPLUS::Configure::Setup->init(
			conf	=> $cpan->configure_object,
			#term	=> $self->term,
			backend => $cpan,
		);
	}	
	sub modulesToUpdate {
		#d: returns slightly modified module object with old_version attribute
		my ($o,@input) = @_;
		my $long;# = 1;
		our $modtree;

		my $inst = $cpan->installed(modules => @input ? \@input : undef );

		if(! $inst->rv or (!$inst->ok && defined @input) ) {
			$o->view(loc("Could not find installation files for all the modules"), "\n");
			return undef;
		}
		my $href = $cpan->uptodate( modules => [sort keys %{$inst->rv}] );

		my $res = $href->rv;
		my $cache = [];

		### keep a cache by default ###
		my $seen = {};

		for my $name ( sort keys %$res ) {
			next unless $res->{$name}->{uptodate} eq '0';

		### dont list more than one module belonging to a package
		### blame H. Merijn Brand... -kane
			my $pkg = $modtree->{$name}->package;

			if ( $long or !$seen->{$pkg}++ ) {
				push @{$cache}, $modtree->{$name};
				#return slightly modified author object
				$cache->[-1]{old_version} = $res->{$name}{version}
			}
		}
		return @$cache;
	}
	#simple replacement for &_select_modules which only
	#prints command status messages
	sub _statusMessages {
		my ($o,$prompt,@input) = @_;
		my $output;

		for (@input) { $output .= "$prompt: $_\n" }
		$o->view($output);
	}
	sub _format_version {
		my $self = shift;
		my %hash = @_;

		my $tmpl = {
			version => { default => 0 }
		};

		my $args = check( $tmpl, \%hash ) or return undef;
		my $version = $args->{version};

		### fudge $version into the 'optimal' format
		$version = sprintf('%3.4f', $version);
		$version = '' if $version == '0.00';

		### do we have to use $&? speed hit all over the module =/ --kane
		$version =~ s/(00?)$/' ' x (length $&)/e;

		return $version;
	}
	### add dirs to the @INC at runtime ###
	sub _expand_inc {
		my $o    = shift;
		my %args    = @_;
		#my $err     = $self->{_error};

		for my $lib ( @{$args{'lib'}} ) {
			push @INC, $lib;
			$o->view( qq[Added $lib to your \@INC\n]);
		}
		return 1;
	}
	sub printHelpAttr {
		my ($o,@cmds) = @_;
		my $format = "%5s  %-15s ... # %-40s\n";
		my $output;
		for (@cmds) {
			my $cmd = $o->cmdObj($_) || next;
			$output .= sprintf $format,@{$cmd}{qw/a arg d/} ;
		}
		return $output;
	}

    ### dumps a message stack
    sub _print_stack {
        my $o = shift;
        my %hash = @_;

        my $tmpl = {
            stack   => { required => 1 },
            file    => { default => '' },
        };

        my $args = check( $tmpl, \%hash ) or return undef;

        my $stack = $args->{'stack'};
        my $file = $args->{'file'};

        if ($file) {
            $o->View->file($file);
        } else { $o->view(join "\n", @$stack); }

        $o->view("\n", loc("Stack printed successfully"), "\n");
        return 1;
    }

1;

__END__

=pod

=head1 NAME

Fry::Lib::CPANPLUS - Fry::Shell reimplentation of CPANPLUS::Shell::Default.

=head1 DESCRIPTION

This module implements most of the functionality of CPANPLUS::Shell::Default using CPANPLUS::Backend
v 0.048 with most of the code coming from &_input_loop.  The aliases assigned to the commands are
the same letters as the original shell but with a prefixed 'c'. For example, to get a CPANPLUS style
help of this library's commands type 'ch'.

There are a few differences (mostly positive) between this library and the original shell:

	The 's' command which changed configurations is split up into two commands
		with aliases 'cs' and 'Cs'.
	There is no autopaging for output's longer than the terminal's screen.
		You must explicitly invoke the pager option ie:
		`-l cm Module::`
	There is autocompletion for the a, m and f commands. 
	There are three new commands: &listInstalled which uses the &installed
		method to see if given modules are installed,
		&listInstalledRegex which returns all installed modules that match
		a given regular expression, and &listAuthorsRegex which returns all
                authors matching a regular expression.
	Use the menu option to pass arguments as numbers.

=head2 Using the Menu option

	You invoke the menu option when you want the output of one command to be
		selectively passed to another command ie:
			`-m cm Acme::` followed by `ci 1,4,6`

	In this example	we search for modules starting with 'Acme::'. From that
		large list, we choose a few to install. Notice that both commands
		output and input the same argument type, modules. It wouldn't make
		sense to have the first command return authors and then pass it to ci.

	The following commands can be used as the first command for the
			menu option: searchModulesbyAuthor, searchModulesbyModule,
			listInstalled,listAuthorsRegex and listInstalledRegex.
	Any commands that take an author or module argument can be used as the second
	command.

	Look at Fry::Shell for a more thorough example.

=head1 MOTIVATION       

So why bother rewriting CPANPLUS::Shell::Default? Well the easy answer is just look at
the FEATURES section of Fry::Shell. But here are a few anyway:

	Change command aliases to one's you remember better.
		Do this by changing the 'a' attribute of a command.
	Combine CPANPLUS with other often used libraries or other CPANPLUS::*
		libraries into one shell.
	The flexibility to define options for any options to CPANPLUS::Backend methods.
	Easier autocompletion definition for commands. 
	By breaking up the commands into separate subroutines, these commands can
		be combined to make other useful commands.
		For example, you could get apt-get upgrade behavior by combining
		&listModulesToUpdate with &installModules.

=head1 TODO

The only functionality in the original shell that hasn't been implemented here
are commandline options. Once options can be defined for a command then this
will be implemented, allowing one to flip any options of a command's method.

=head1 SEE ALSO

L<CPANPLUS::Shell::Default> of course. L<Fry::Shell>. L<CPANPLUS::Backend> to
add to this module.

=head1 AUTHOR

Me. Gabriel that is. I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com. 

=head1 BUGS

Although I've written up decent tests there are some combinations of
configurations I have not tried. If you see any bugs tell me so I can make
this module rock solid.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.
