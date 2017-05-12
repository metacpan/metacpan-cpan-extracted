package Dyer::CLI;
use strict;
use Carp;
use Cwd;
use Getopt::Std;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)/g;


$main::DEBUG=1;
$main::VERBOSE=1;

sub main::DEBUG {
	my $val = shift;
	if (defined $val){
		$main::DEBUG = $val;
	}	
	return $main::DEBUG;
}

sub main::VERBOSE {
	my $val = shift;
	if (defined $val){
		$main::VERBOSE = $val;
	}	
	return $main::VERBOSE;
}









sub main::force_root {
	my $whoami = `whoami`;
	chomp $whoami;
	$whoami eq 'root' or print "$0, only root can use this." and exit;
	return 1;
}

sub main::gopts {
	my $opts = shift;
	$opts||='';

	if($opts=~s/v\:?|h\:?//sg){
		print STDERR("$0, options changed") if ::DEBUG;
	}

	$opts.='vh';
	
	my $o = {};	
	
	Getopt::Std::getopts($opts, $o); 
	
	if($o->{v}){
		if (defined $::VERSION){
			print $::VERSION;
			exit;
		}		
		print STDERR "$0 has no version\n";
		exit;					
	}


	if($o->{h}){
		main::man()
	}	
	
	return $o;
}

sub main::man {
	my $name = main::_scriptname();
   print `man $name` and exit; 
}

sub main::_scriptname{
	my $name = $0 or return;
	$name=~s/^.+\///;
	return $name;
}

sub main::argv_aspaths {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("$0, Does not resolve: $_, skipped.") and next;
		-e $abs or  warn("$0, Does not exist: $_, skipped.") and next;
		push @argv, $abs;
	}

	scalar @argv or return;

	return \@argv;
}

sub main::argv_aspaths_strict {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("Does not resolve: $_.") and return;
		-e $abs or  warn("Is not on disk: $_.") and return;
		push @argv, $abs;
	}
	scalar @argv or return;
	return \@argv;
}

sub main::argv_aspaths_loose {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("$0, Does not resolve: $_, skipped.") and next;
		push @argv, $abs;
	}
	scalar @argv or return;
	return \@argv;
}


sub main::yn {
        my $question = shift; $question ||='Your answer? ';
        my $val = undef;

        until (defined $val){
                print "$question (y/n): ";
                $val = <STDIN>;
                chomp $val;
                if ($val eq 'y'){ $val = 1; }
                elsif ($val eq 'n'){ $val = 0;}
                else { $val = undef; }
        }
        return $val;
}





1;

__END__

=pod

=head1 NAME

Dyer::CLI - useful subs for coding cli scripts

=head1 DESCRIPTION

This standardizes some things like expecting that if the -v flag is used, that means they want version.
That if they want -h, they want help. Etc.

=head1 USAGE

This package must be used as base.

	use base 'DYER::CLI';

=head2 yn()

prompt user for y/n confirmation
will loop until it returs true or false
argument is the question for the user

	yn('continue?') or exit;

=head2 force_root()

will force program to exit if user if whoami is not root.

=head2 argv_aspaths()

returns array ref of argument variables treated as paths, they are resolved with Cwd::abs_path()
Any arguments that do not resolve, are skipped with a warning.
if no abs paths are present after checking, returns undef
files are checked for existence
returns undef if no @ARGVS or none of the args are on disk
skips over files not on disk with warnings


=head2 argv_aspaths_strict()

Same as argv_aspaths(), but returns false if any of the file arguments are no longer on disk

=head2 argv_aspaths_loose()

Same as argv_aspaths(), but does not check for existence, only resolved to abs paths

=head2 _scriptname()

returns name of script, just the name.


=head2 man()

will print manual and exit.

=head1 gopts()

returns hash of options
uses Getopt::Std, forces v for version, h for help

To get standard with v and h:

	my $o = gopts(); 

To add options

	my $o = gopts('af:');

Adds a (bool) and f(value), v and h are still enforced.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 COPYRIGHT

Copyright (c) 2007 Leo Charre. All rights reserved.

=cut
