#!/usr/bin/perl -w

package HPUX::SDUX;

use Carp;
use Config;
use Cwd qw( cwd );
use DirHandle;
use Exporter();
use ExtUtils::MakeMaker;
use File::Copy;
use strict qw( vars );
use vars qw(
	$VERSION @EXPORT
);

$VERSION='0.03';
@HPUX::SDUX::ISA = qw( Exporter );

# We will export &wmf so that
# perl -MHPUX::SDUX -e wmf
# makes sense.
@EXPORT= qw(
	&wmf
);

BEGIN {
	my $cwd = cwd;
	die "This module is useful only on an HP-UX system" unless $^O eq 'hpux';
	unless (-f 'Makefile.PL') { die "Makefile.PL does not exist in $cwd: $!" };
}

END {
}

######################################################################
# The basic strategy is to create a new file Makefile.SDUX, which is a copy of
# Makefile.PL plus a few routines overriding MakeMaker routines,
# execute Makefile.SDUX to write Makefile, and then add a new target 'depot.'
#
# The target 'depot' will:
# 1. install module into a temporary directory (./sdux by default)
#    and determine the content of this module distribution
# 2. write module.psf file with &HPUX::SDUX::write_psf
# 3. call 'swpackage -s module.psf'
#
# Notice that you have to have certain privileges to make 'depot'.
######################################################################

######################################################################
# variables needed in multiple subroutines
######################################################################
my $cwd              = cwd;
my $sdux_install_dir = "$cwd/sdux";	# the temporary directory to install module
my ( $module_version, $module_name, $module_author, $module_prefix );

######################################################################
# Anonymous subroutines inaccessible from other packages
######################################################################
my $__parse_version = sub {
	# Copied from &ExtUtils::MM_Unix::parse_version (v1.3.3), sans OO-interface
	# Also reformatted
	my $parsefile = shift;
	my $result;
	local *FH;
	local $/ = "\n";
	open(FH,$parsefile) or die "Could not open '$parsefile': $!";
	my $inpod = 0;
	while (<FH>) {
		$inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
		next if $inpod || /^\s*#/;
		chop;
		# next unless /\$(([\w\:\']*)\bVERSION)\b.*\=/;
		next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
		my $eval = qq{
			package ExtUtils::MakeMaker::_version;
			no strict;

			local $1$2;
			\$$2=undef; do {
			$_
			}; \$$2
		};
		local $^W = 0;
		$result = eval($eval);
		warn "Could not eval '$eval' in $parsefile: $@" if $@;
		last;
	}
	close FH;

	$result = "undef" unless defined $result;
	return $result;
	
};

my $__get_module_info = sub {
	# Get basic information about the module
	my ($version, $version_from);

	open MAKEFILEPL, "< Makefile.PL" or die "Cannot open Makefile.PL: $!";

	do { $_ = <MAKEFILEPL> } until ( $_ =~ m/WriteMakefile/ );	# skip until the call to WriteMakefile

	while (<MAKEFILEPL>) {
		if ( m/(['"]?)(?:DIST)?NAME(\1?)\s*=>\s*['"]?([-A-Za-z0-9:]+)/ ) {
			$module_name = $3;
		}
		if ( m/(['"]?)AUTHOR(\1?)\s*=>\s*['"]?([\w ]+)/ ) {
			$module_author =  $3;
			$module_author =~ s/\s*$//;
		} 
		if ( m/(['"]?)VERSION_FROM(\1?)\s*=>\s*(['"])(\S*)(\3)/ ) {
			$version_from = $4;
		}
	}
	close MAKEFILEPL;

	$version = &$__parse_version($version_from);

	return ( $version, $module_name, $module_author, $Config{prefix} );
};

my $__top_subdirs = sub {
	# Given a directory name, return an array of top-level subdirectory names
	# in that directory.  Based on "Perl Cookbook", recipe 9.5.
	my $dir     = shift();
	my $dh      = DirHandle->new($dir) or die "Cannot open $dir: $!";
	return sort
		grep { s[$dir/][] }	# remove "$dir/"
		grep { -d }			# only directories
		map { "$dir/$_" }
		grep { !/^\./ }
		$dh->read();
	
};

( $module_version, $module_name, $module_author, $module_prefix ) = &$__get_module_info();

my $__write_filesets_section = sub {
	# filehandle PSFFILE should be open when this routine is called.
	# required in PSF layout version 1.0

	my $current_dir = cwd;
	my $dir = shift();
	
	print STDERR "Writing $dir fileset section\n";
	print PSFFILE <<"FILESET_SECTION";
	fileset
		tag $dir
		directory	$sdux_install_dir/$dir = $module_prefix/$dir
		file	*
	end
FILESET_SECTION

};

my $__write_subproducts_section = sub {
	# optional in PSF layout version 1.0
	print STDERR "Writing subproducts section\n";
	
	# for now, we don't use this section
};

my $__write_products_section = sub {
	# filehandle PSFFILE should be open when this routine is called.
	# required in PSF layout version 1.0
	print STDERR "Writing products section\n";
	
	my $current_dir = cwd;
	$module_name =~ s/::/-/g;
	$module_name = 'CPAN-'.$module_name;

	print PSFFILE <<"PRODUCT_SECTION_PREAMBLE";
product
	tag $module_name
	revision	$module_version
	directory	$module_prefix
	readme		< $current_dir/README
	is_locatable	false
	is_patch		false
	os_name	HP-UX
	os_release	?.11.*
	os_version	?
	category_tag	language_perl
PRODUCT_SECTION_PREAMBLE

	my @dirs = &$__top_subdirs($sdux_install_dir);
	
	foreach my $dir (@dirs) {
		&$__write_filesets_section($dir);
	}

	print PSFFILE <<"PRODUCT_SECTION_POSTAMBLE";	# close 'product'
end
PRODUCT_SECTION_POSTAMBLE

};

######################################################################
#
# &HPUX::SDUX::wmf
#
######################################################################
sub wmf() {
	my $package_name = __PACKAGE__;
	my $sdux_makefile    = 'Makefile.SDUX';
	my $makefile = 'Makefile.PL';	# read Makefile.PL by default
	die "$makefile does not exist: $?" unless (-f $makefile);
	
	{
		# run Makefile.PL with appropriate arguments
		# save off @ARGV, just in case we need it later
		my @makefile_argv = @ARGV;
		local @ARGV;
		if (@makefile_argv) {
			# override any 'SITEPREFIX=' run-time option
			push @makefile_argv, ( "SITEPREFIX=$sdux_install_dir" );
		} else {
			@makefile_argv = ( "SITEPREFIX=$sdux_install_dir" )
		}
		@ARGV = @makefile_argv;
		open MYMAKEFILE, ">> $sdux_makefile" || die "Cannot write to $sdux_makefile: $?";
		File::Copy::copy ($makefile,$sdux_makefile);
		print MYMAKEFILE <<"END_MAKEFILE_PL";

# ExtUtils::MakeMaker methods overridden by $package_name
sub MY::clean {
	my \$clean = &ExtUtils::MM_Unix::clean;
	\$clean .= "\\t\\\$(RM_RF) HPUX sdux \\\$(DEV_NULL)\\n";
	\$clean .= "\\t-\\\$(MV) module.psf module.psf.old \\\$(DEV_NULL)\\n";
	\$clean .= "\\t-\\\$(MV) Makefile.SDUX Makefile.SDUX.old \\\$(DEV_NULL)";
	\$clean;
}

sub MY::realclean {
	my \$realclean = &ExtUtils::MM_Unix::realclean;
	\$realclean .= "\\t\\\$(RM_RF) module.psf module.psf.old \\\$(DEV_NULL)\\n";
	\$realclean .= "\\t\\\$(RM_RF) Makefile.SDUX Makefile.SDUX.old \\\$(DEV_NULL)";
	\$realclean;
}

sub MY::postamble {
	my \$postamble = <<'END_DEPOT';
depot: install
	\$(PERL) -M$package_name -e ${package_name}::write_psf
	swpackage -s module.psf -x write_remote_files=true \@$sdux_install_dir
END_DEPOT
}
END_MAKEFILE_PL
		close MYMAKEFILE;
		do $sdux_makefile or die "Cannot create Makefile: $!";
	}
	
}

######################################################################
#
# &HPUX::SDUX::write_psf
# This is called in the 'depot' target of our Makefile
#
######################################################################
sub write_psf() {

	# This routine should be called only from the "depot" target.
	# When we get here, 'make' should have made the target "install".
	# There should be a directory './sdux' whose content is what
	# the module needs.
	
	print STDERR "Writing PSF\n";

	# information about the module
	my $current_dir = cwd;
	my $psf_file         = 'module.psf';
	my $psf_version      = '1.0';	# just in case
	my $author_tag = $module_author;
	map { s/[^A-Z]//g } $author_tag;
	if ($author_tag) {
		$author_tag = 'CPAN'.$author_tag
	} else {
		$author_tag = 'UNDEF'
	}

	open PSFFILE, "> $psf_file" or die "Cannot write to $psf_file: $?";

	print PSFFILE <<"PSF_PREAMBLE";
depot
	layout_version $psf_version
	vendor
		tag $author_tag
		title	$module_author
	end
	category
		tag	language_perl
		description		A perl module
	end
PSF_PREAMBLE

	&$__write_products_section();

	print PSFFILE <<"PSF_POSTAMBLE";	# close 'depot'
end
PSF_POSTAMBLE

	close PSFFILE or die "Cannot close $psf_file: $?";
}

1;	# end of HPUX::SDUX

__END__


=head1 NAME

HPUX::SDUX - Perl module for creating SD-UX software depots of Perl modules

=head1 SYNOPSIS

perl -MHPUX::SDUX -e wmf

make; make test; make depot

=head1 DESCRIPTION

C<HPUX::SDUX> is a Perl module to assist creating SD-UX software depots for
Perl modules on HP-UX.
As such, it is utterly useless for Perl users on other platforms.

This version assumes the use of HP-UX 11i and PSF (Product Specification File)
layout version 1.0, as outlined in
I<Software Distributor Administration Guide for HP-UX 11i>
E<lt>L<http://docs.hp.com/hpux/onlinedocs/B2355-90754/B2355-90754.html>E<gt>.
It may work on other versions, but it is not tested.

After unpacking a CPAN module, move to the expanded directory and say

C<perl -MHPUX::SDUX -e wmf>

This creates intermediate file F<Makefile.SDUX>, based on F<Makefile.PL>
in the current directory, and writes F<Makefile> by executing F<Makefile.SDUX>.
The resulting F<Makefile> contains a modified target C<clean> and a new target
C<depot>, so that you can only follow with

C<make; make test; make depot>

The target C<depot> will install the module in the F<sdux> subdirectory, writes
F<module.psf> and invokes C<swpackage>.
Thus certin privileges are required for this target.

=head2 SEE ALSO

L<swpackage(1M)>, L<swinstall(1M)>

L<http://docs.hp.com/hpux/onlinedocs/B2355-90754/B2355-90754.html>

L<http://www.asari.net/perl>

=head2 TODO

=over

=item 1.

More testing with sophisticated modules, such as those that require
C compiler.

=item 2.

More sophisticated PSF generation.

=item 3.

C<Module::Build> compliance.

=back

=head1 AUTHOR

Hiro Asari <hiro at asari.net>

=head1 COPYRIGHT

Copyright 2003 by Hiro Asari.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

