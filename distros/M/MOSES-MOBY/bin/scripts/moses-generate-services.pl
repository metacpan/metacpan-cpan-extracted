#!/usr/bin/perl -w
#
# Generate services.
#
# $Id: moses-generate-services.pl,v 1.7 2009/03/30 13:16:38 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

# some command-line options
use Getopt::Std;
use vars qw/ $opt_h $opt_A $opt_d $opt_R $opt_v $opt_a $opt_s $opt_b $opt_f $opt_u $opt_F $opt_S $opt_t $opt_c $opt_C /;
getopts('hdvasbfuFStcCAR:');
# usage
if (not($opt_u or $opt_f)) {
if ($opt_h or (not $opt_a and @ARGV == 0)) {
    print STDOUT <<'END_OF_USAGE';
Generate Services.
Usage: [-vds] [-R registry-string] [-b|S|t|c|A] authority [service-name] [service-name...]
       [-vds] [-R registry-string] [-b|S|t|c|A] authority
       [-vd] [-R registry-string] [-b|S|t|c|A] -a
       [-R registry-string] [-fu]

    It also needs to get a location of a local cache (and potentially
    a BioMoby registry endpoint, and an output directory). It takes
    it from the 'moby-service.cfg' configuration file.

    -f ... fill the cache
    -u ... update the cache
    
    -R ... a registry string in the form:
               registry-url[@registry-uri]
           where registry-uri is optional.
           For example: 
              http://localhost/cgi-bin/MOBY-Central.pl
           or
              http://localhost/cgi-bin/MOBY-Central.pl@http://localhost/MOBY/Central
    
    -b ... generate base[s] of given service[s]
    -S ... generate implementation and the base of service[s], the
           implementation module has enabled option to read the base
           statically (that is why it is also generated here)
    
    -i ... generate an implementation of the given service
    
    -c ... generate a cgi based implementation of the given service
    -C ... generate an asynchronous cgi based implementation of the given service
    
    -A ... generate an asynchronous based implementation of the given service       
    -t ... update dispatch table of services (a table used by the
	       cgi-bin script and SOAP::Lite to dispatch requests);
           this table is also updated automatically when options
           -i or -S are given
    If none of -b, -S, -t, -c is given, it generates/show implementation
    (not a base) of service[s].

    -s ... show generated code on STDOUT
           (no file is created, disabled when -a given)
    -a ... generate all services (good only for generator testing)

    -v ... verbose
    -d ... debug
    -h ... help
END_OF_USAGE
    exit (0);
}
}
# Undocumented options
# (because it is dangerous, you can loose your code):
#   -F ... force to overwrite existing implementtaion
# -----------------------------------------------------------

use strict;

use MOSES::MOBY::Base;
use MOSES::MOBY::Generators::GenServices;

$LOG->level ('INFO') if $opt_v;
$LOG->level ('DEBUG') if $opt_d;

sub say { print @_, "\n"; }

if ($opt_R) {
	my @r = split(/\@/, $opt_R);
	$opt_R = $r[0];
}

my $generator = new MOSES::MOBY::Generators::GenServices;
$generator->registry($opt_R) if $opt_R;

if ($opt_f) {
	my $cache = MOSES::MOBY::Cache::Central->new (
						cachedir => $generator->cachedir,
    					registry => $generator->registry
    );
	
    say "Creating the services cache ... may take a few minutes!";
	say("Using the registry: " . $cache->registry);
    eval{$cache->create_service_cache();};
    say "There was a problem creating the cache:\n$@" if $@;
    say 'Done.' unless $@;
    exit(0);
} elsif ($opt_u) {
	my $cache = MOSES::MOBY::Cache::Central->new (
						cachedir => $generator->cachedir,
    					registry => $generator->registry
    );
    say "Updating the services cache ... may take a few minutes!";
    eval{$cache->update_service_cache();};
    say "There was a problem updating the cache. Did you create it first?\n$@" if $@;
    say 'Done.' unless $@;
    exit(0);
}

if ($opt_a) {
    say 'Generating all services.';
    if ($opt_b) {
	$generator->generate_base;
    } elsif ($opt_S) {
	$generator->generate_impl (static_impl => 1);
	$generator->generate_base;
	$generator->update_table;
    }  elsif ($opt_c) {
    $generator->generate_impl;
	$generator->generate_cgi;
    } elsif ($opt_C) {
    $generator->generate_impl;
	$generator->generate_async_cgi;
    } elsif ($opt_t) {
	$generator->update_table;
    } elsif ($opt_A) {
	$generator->generate_impl;
	$generator->generate_async;
	$generator->update_async_table;
    } else {
	$generator->generate_impl;
	$generator->update_table;
    }
} else {
    my $authority = shift;
    say "Generating services from $authority:";
    if ($opt_s) {
	my $code = '';
	if ($opt_b) {
	    $generator->generate_base (service_names => [@ARGV],
				       authority     => $authority,
				       outcode       => \$code);
	} elsif ($opt_c) {
    	$generator->generate_impl(service_names => [@ARGV],
				       authority     => $authority,
				       outcode       => \$code);
		$generator->generate_cgi(service_names => [@ARGV],
				       authority     => $authority,
				       outcode       => \$code);
    } elsif ($opt_C) {
    	$generator->generate_impl(service_names => [@ARGV],
				       authority     => $authority,
				       outcode       => \$code);
		$generator->generate_async_cgi(service_names => [@ARGV],
				       authority     => $authority,
				       outcode       => \$code);
    } elsif ($opt_A) {
		$generator->generate_async(service_names => [@ARGV],
					       authority     => $authority,
					       outcode       => \$code);
		#$generator->update_async_table;
    } else {
	    $generator->generate_impl (service_names => [@ARGV],
				       authority     => $authority,
				       outcode       => \$code);
	}
	say $code;
    } else {
	if ($opt_b) {
	    $generator->generate_base (service_names => [@ARGV],
				       authority     => $authority);
	} elsif ($opt_S) {
	    $generator->generate_impl (service_names => [@ARGV],
				       authority     => $authority,
				       force_over    => $opt_F,
				       static_impl   => 1);
	    $generator->generate_base (service_names => [@ARGV],
				       authority     => $authority);
	    $generator->update_table (service_names => [@ARGV],
				      authority     => $authority);
	} elsif ($opt_A) {
	    $generator->generate_impl(
					service_names => [@ARGV],
					authority     => $authority,
					force_over    => $opt_F);
	    $generator->generate_async (service_names => [@ARGV],
				       authority     => $authority,
				       force_over    => $opt_F,
				       static_impl   => 1);
	    $generator->update_async_table (service_names => [@ARGV],
				      authority     => $authority);
	} elsif ($opt_c) {
    	$generator->generate_impl(
					service_names => [@ARGV],
					authority     => $authority,
					force_over    => $opt_F);
		$generator->generate_cgi(service_names => [@ARGV],
				      authority     => $authority);
    } elsif ($opt_C) {
    	$generator->generate_impl(
					service_names => [@ARGV],
					authority     => $authority,
					force_over    => $opt_F);
		$generator->generate_async_cgi(service_names => [@ARGV],
				      authority     => $authority);
    } elsif ($opt_t) {
	    $generator->update_table (service_names => [@ARGV],
				      authority     => $authority);
	} else {
	    $generator->generate_impl (service_names => [@ARGV],
				       authority     => $authority,
				       force_over    => $opt_F);
	    $generator->update_table (service_names => [@ARGV],
				      authority     => $authority);
	}
    }
}
say 'Done.';


__END__
