use 5.006;
use Module::Build();
use Data::Dumper ();
use List::Util qw(sum);
use ExtUtils::MM ();
 
my $dist_version = 0.14;
my $mods_version = sum map {MM->parse_version($_)} <lib/File/*/Link.pm>;
if ($dist_version < $mods_version ) {
    warn "Declared dist version ($dist_version) is less than\n",
	    "that derived from module versions ($mods_version)\n";
    $dist_version = $mods_version;
}

my %args = (
   	module_name	=> 'File::Copy::Link',
	dist_version	=> sprintf("%.3f", $dist_version),
	abstract_from	=> 'lib/File/Copy/Link.pm',
	license		=> 'perl',	
	requires	=> { File::Spec => 0, File::Copy => 0, perl => 5.006 }, 
	recommends	=> { Cwd => 2.18, },
	script_files	=> [ qw(copylink) ],
	dist_author  	=> 'Robin Barker <rmbarker@cpan.org>',
	build_requires  => { Test::More => 0, File::Temp => 0 }, 
	configure_requires => { 'Module::Build' => 0.38 }
    );

{
   local $SIG{__WARN__} = sub {
	return if $_[0] =~ m{
		\A
		WARNING\:\ the\ following\ files\ are\ missing\ in\ your\ kit\:
		(\s+ (Makefile\.PL | META\.\S+) )+
		\s+ Please\ inform\ the\ author\.
		\s+ \z
	}msx;
	warn $_[0];
        return;
    };
    Module::Build -> new ( %args ) -> create_build_script;
}

my $file = 'Makefile.PL';
if( open OUT, '>', $file ) {

    my %requires = %{$args{requires}};
    my $perl = delete $requires{perl} || 5;

    my $make = { 
	NAME		=> $args{module_name},
	VERSION		=> $args{dist_version},
	AUTHOR		=> $args{dist_author},
	ABSTRACT_FROM	=> $args{abstract_from},
	PREREQ_PM	=> \%requires,
	EXE_FILES	=> $args{script_files},
	PL_FILES	=> {}
    };
    my $dump = Data::Dumper->Dump( [$make], [qw(args)] );

    print OUT <<MAKEFILE or die "Can't print to $file: $!";
# Created by Build.PL
use $perl;
use strict;
use ExtUtils::MakeMaker;
my $dump
WriteMakefile( \%\$args );
MAKEFILE

    close OUT or die "Error closing $file: $!";
    warn "Wrote $file\n";
}
else {
    warn "Can't write to $file: $!"
	unless $! == 13;	# Permission dened
}

# $Id: Build.PL 356 2014-07-03 20:01:57Z robin $
    
