package Dynamic::Loader;
use strict;

require Exporter;
use Carp qw/confess/;
use Env::Path;
use File::Basename;
require Data::Dumper if defined( $ENV{DEBUG} );

our ( $VERSION, $BINPATH, @ISA, @EXPORT );
$VERSION = '1.08';

=head1 NAME

Dynamic::Loader - call a script without to know where is his location.


=head1 SYNOPSIS

    The Dynamic::Loader manage the dynamic location of scripts and bundles. 
    Scripts and bundles are packaged in there own directory.
    The bundles and scripts locations are discribed on a named configuration file. 
    The prefix configuration directory can be specified by the $JAVAPERL environnement. 
    The default directory is $HOME/.perljava/conf, but you can specify a custom
    prefix with the $JAVAPERL/conf variable.
    
    A configuration is <name>.conf with this format:
        prefix=<absolute path>
        bin=<relative binary dir>
        lib=<relative library dir>


=head1 DEFAULT SCRIPT AND PARAMS

When C<Dynamic::Loader> is used, you can specify the script name and his options
command:
        perl -S fromjar.pl scriptname.pl --a=... --b=...


=cut

@ISA    = qw(Exporter);
@EXPORT = qw($SCRIPTPATH $PATH $PERL5LIB &listScripts &getExecPrefix);
our ( $SCRIPTPATH, $PATH, $PERL5LIB, );

sub import {
	my $class = shift;

	#@_ contains what could be passed on -MLoader=...; iv ever
	init();
	$class->export_to_level( 1, $class, @_ );
}

=head3 init()

setup libs and bin directories

#fix lib and script path according to what's given

=cut

sub init {
	my $perlJavaHome;
	$perlJavaHome = $ENV{PERLLOADERHOME} || $ENV{JAVAPERL};
	$perlJavaHome = "$ENV{HOME}/.perljava" unless defined $perlJavaHome;

	#$ENV{PATH}='';
	$PATH       = Env::Path->PATH;
	$SCRIPTPATH = Env::Path->SCRIPTPATH;
	$PERL5LIB   = Env::Path->PERL5LIB;

	#TODO change that from ENV
	my @modules;
	my %conffiles;
	if ( $ENV{PERLLOADERMODULES} ) {
		@modules = split /:/, $ENV{PERLLOADERMODULES};
	}
	else {
		foreach (<$perlJavaHome/conf/*.conf>) {
			open( CONFIGFILE, $_ ) or next;
			my %entry = ();
			while ( my $l = <CONFIGFILE> ) {
				if ( $l =~ /^([^=]+)=(.*)/ ) {
					my ( $key, $val ) = ( $1, $2 );
					if ( $key eq "prefix" ) {
						$conffiles{$val} = \%entry;
						push @modules, $val;
					}
					else {
						$entry{$key} = $val;
					}
				}
			}
			close CONFIGFILE;
		}

	}
	require Data::Dumper                              if defined( $ENV{DEBUG} );
	printf Data::Dumper::Dumper( \%conffiles ) . "\n" if defined( $ENV{DEBUG} );
	foreach my $pjar (@modules) {
		eval "use lib \"$pjar/$conffiles{$pjar}->{lib}\"";
	}

#we wish to put the path from the given directory, but in the correct order, and in front of all other.
	foreach my $pjar ( reverse @modules ) {
		my $bin = "$pjar/$conffiles{$pjar}->{bin}";
		$bin =~ s/\/\//\//g;
		$SCRIPTPATH->Prepend($bin) unless $SCRIPTPATH->Contains($bin);
		$PATH->Prepend($bin)       unless $PATH->Contains($bin);
		my $lib = "$pjar/$conffiles{$pjar}->{lib}";
		$lib =~ s/\/\//\//g;
		$PERL5LIB->Prepend($lib) unless $PERL5LIB->Contains($lib);
	}

}

=head3 Dynamic::Loader::listScripts([patt])

Return a list of commands following a pattern listScripts(), listScripts("*.pl"), listScripts("phe*")

The commands returned here are returned with a relative path to the package they belong to

=cut

sub listScripts {
	require File::Find::Rule;
	my $patt = shift || '*';

	my @tmp;
	foreach my $p ( $SCRIPTPATH->List ) {
		foreach ( File::Find::Rule->file()->name($patt)->in($p) ) {
			next if /\/\.svn\//;
			s/^$p([\/\\])?//;
			push @tmp, $_;
		}
	}
	return @tmp;
}

=head3 Dynamic::Loader::getScript(relative_path)

Return the complete path to the given scripts.

Contrary to listScripts(), this command must return exactly one script and will die if not;

=cut

sub getScript {
	my $relPath = shift or confess "no relative path given";
	my @tmp;
	foreach ( $SCRIPTPATH->List ) {
		my $full = "$_/$relPath";
		push @tmp, $full if -f $full;
	}
	confess "no script found for [$relPath]" unless @tmp;
	my $contents;
	if (@tmp) {
		local $/;
		foreach my $f (@tmp) {
			open( FD, "<$f" ) or die "cannot read $f";
			my $tmp = <FD>;
			close FD;
			unless ($contents) {
				$contents = $tmp;
			}
			else {
				if ( $contents ne $tmp ) {
					confess
"multiple scripts found with incompatible contents for [$relPath] in "
					  . join(@tmp)
					  if @tmp > 1;
				}
			}
		}
	}
	return $tmp[0];
}

=head3 Dynamic::Loader::getLibs(relative_path)

Return the complete path to the given scripts + the complete perl prefix with perl5libs.

=cut

sub getLongScript {
	my $relPath = shift or confess "no relative path given";
	my $path    = getScript($relPath);
	my $p5l     = "$^X ";
	foreach ( $PERL5LIB->List ) {
		$p5l .= "-I$_ ";
	}

	printf "---> $p5l$path \n" if defined( $ENV{DEBUG} );
	return "$p5l$path";
}

=head3  Dynamic::Loader::getExecPrefix()

return an array to prepend to execution (perl, includes etc...)

=cut

sub getExecPrefix {
	return ($^X);
}

=head3 Dynamic::Loader::whence([pat])

return a list of commands with the full path corresponding to a pattern. Think of ls completion in bash

=cut

sub whence {
	return $SCRIPTPATH->Whence( $_[0] or "*" );
}

=head1 AUTHOR

Olivier Evalet, C<< <olivier.evalet at genebio.com> >>
Alexandre Masselo C<< <alex at genebio.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dynamic-loader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dynamic-Loader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dynamic::Loader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dynamic-Loader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dynamic-Loader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dynamic-Loader>

=item * Search CPAN

L<http://search.cpan.org/dist/Dynamic-Loader>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Olivier Evalet, Alexandre Masselot all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Dynamic::Loader
