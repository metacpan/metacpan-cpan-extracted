package Devel::FindPerl;
$Devel::FindPerl::VERSION = '0.014';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/find_perl_interpreter perl_is_same/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp q/carp/;
use Config;
use Cwd q/realpath/;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/catfile catdir rel2abs file_name_is_absolute updir curdir path/;
use Scalar::Util 'tainted';
use IPC::Open2 qw/open2/;

my %perl_for;
sub find_perl_interpreter {
	my $config = shift || 'Devel::FindPerl::Config';
	my $key = $config->can('serialize') ? $config->serialize : '';
	$perl_for{$key} ||= _discover_perl_interpreter($config);
	return wantarray ? @{ $perl_for{$key} } : $perl_for{$key}[0];
}

sub _discover_perl_interpreter {
	my $config = shift;

	return VMS::Filespec::vmsify($^X) if $^O eq 'VMS';
	my $perl_basename = basename($^X);

	my @potential_perls;

	# Try 1, Check $^X for absolute and relative path
	push @potential_perls, file_name_is_absolute($^X) ? [ $^X ] : length +(splitpath($^X))[1] ? [ rel2abs($^X) ] : ();

	# Try 2, Last ditch effort: These two option use hackery to try to locate
	# a suitable perl. The hack varies depending on whether we are running
	# from an installed perl or an uninstalled perl in the perl source dist.
	if ($ENV{PERL_CORE}) {
		# Try 3.A, If we are in a perl source tree, running an uninstalled
		# perl, we can keep moving up the directory tree until we find our
		# binary. We wouldn't do this under any other circumstances.

		my $perl_src = _perl_src();
		if (defined($perl_src) && length($perl_src)) {
			my $uninstperl = catfile($perl_src, $perl_basename);
			# When run from the perl core, @INC will include the directories
			# where perl is yet to be installed. We need to reference the
			# absolute path within the source distribution where it can find
			# it's Config.pm This also prevents us from picking up a Config.pm
			# from a different configuration that happens to be already
			# installed in @INC.
			push @potential_perls, [ $uninstperl, '-I' . catdir($perl_src, 'lib') ];
		}
	}
	else {
		# Try 2.B, First look in $Config{perlpath}, then search the user's
		# PATH. We do not want to do either if we are running from an
		# uninstalled perl in a perl source tree.

		push @potential_perls, [ $config->get('perlpath') ];
		push @potential_perls, map { [ catfile($_, $perl_basename) ] } path();
	}
	@potential_perls = grep { !tainted($_->[0]) } @potential_perls;

	# Now that we've enumerated the potential perls, it's time to test
	# them to see if any of them match our configuration, returning the
	# absolute path of the first successful match.
	my $exe = $config->get('exe_ext');
	foreach my $thisperl (@potential_perls) {
		$thisperl->[0] .= $exe if length $exe and $thisperl->[0] !~ m/\Q$exe\E$/i;
		return $thisperl if -f $thisperl->[0] && perl_is_same(@{$thisperl});
	}

	# We've tried all alternatives, and didn't find a perl that matches
	# our configuration. Throw an exception, and list alternatives we tried.
	my @paths = map { dirname($_->[0]) } @potential_perls;
	die "Can't locate the perl binary used to run this script in (@paths)\n";
}

# if building perl, perl's main source directory
sub _perl_src {
	# N.B. makemaker actually searches regardless of PERL_CORE, but
	# only squawks at not finding it if PERL_CORE is set

	return unless $ENV{PERL_CORE};

	my $updir = updir;
	my $dir	 = curdir;

	# Try up to 10 levels upwards
	for (0..10) {
		if (
			-f catfile($dir,"config_h.SH")
			&&
			-f catfile($dir,"perl.h")
			&&
			-f catfile($dir,"lib","Exporter.pm")
		) {
			return realpath($dir);
		}

		$dir = catdir($dir, $updir);
	}

	carp "PERL_CORE is set but I can't find your perl source!\n";
	return;
}

sub perl_is_same {
	my @perl = @_;
	return lc _capture_command(@perl, qw(-MConfig=myconfig -e print -e myconfig)) eq lc Config->myconfig;
}

sub _capture_command {
	my (@command) = @_;

	local @ENV{qw/PATH IFS CDPATH ENV BASH_ENV/};
	my $pid = open2(my($in, $out), @command);
	binmode $in, ':crlf' if $^O eq 'MSWin32';
	my $ret = do { local $/; <$in> };
	waitpid $pid, 0;
	return $ret;
}

sub Devel::FindPerl::Config::get {
	my ($self, $key) = @_;
	return $Config{$key};
}

1;

#ABSTRACT: Find the path to your perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::FindPerl - Find the path to your perl

=head1 VERSION

version 0.014

=head1 SYNOPSIS

 use Devel::FindPerl 'find_perl_interpreter';
 system find_perl_interpreter, '-e', '...';

=head1 DESCRIPTION

This module tries to find the path to the currently running perl. It (optionally) exports the following functions:

=head1 FUNCTIONS

=head2 find_perl_interpreter($config = ExtUtils::Config->new)

This function will try really really hard to find the path to the perl running your program. I should be able to find it in most circumstances. Note that the result of this function will be cached for any serialized value of C<$config>. It will return a list that usually but not necessarily is containing one element; additional elements are arguments that must be passed to that perl for correct functioning.

=head2 perl_is_same($path, @arguments)

Tests if the perl in C<$path> is the same perl as the currently running one.

=head1 SECURITY

This module by default does things that are not particularly secure (run programs based on external input). In tainted mode, it will try to avoid any insecure action, but that may affect its ability to find the perl executable.

=head1 SEE ALSO

=over 4

=item * Probe::Perl

This module has much the same purpose as Probe::Perl, in fact the algorithm is mostly the same as both are extracted from L<Module::Build> at different points in time. If I had known about it when I extracted it myself, I probably wouldn't have bothered, but now that I do have it there are a number of reasons for me to prefer Devel::FindPerl over Probe::Perl

=over 4

=item * Separation of concerns. P::P does 4 completely different things (finding perl, managing configuration, categorizing platorms and formatting a perl version. Devel::FindPerl is instead complemented by modules such as L<ExtUtils::Config> and L<Perl::OSType>.

=item * It handles tainting better. In particular, C<find_perl_interpreter> never returns a tainted value, even in tainted mode.

=item * It was written with inclusion in core in mind, though the removal of Module::Build from core after perl 5.20 may make this point moot.

=back

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>, Randy Sims <randys@thepierianspring.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Randy Sims, Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
