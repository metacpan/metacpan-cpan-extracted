package File::Redirect;
use strict;
use warnings;
require DynaLoader;
our @EXPORT_OK = qw(mount umount);
our @ISA = qw(DynaLoader Exporter);
our $VERSION = '0.04';
bootstrap File::Redirect $VERSION;

use Errno;
our ($debug, %mounted);

$debug = 1 if $ENV{FILE_REDIRECT_DEBUG};

our $dev_no = 1_000_000;

sub debug($) { warn "$_[0]\n" }

sub mount
{
	my ( $provider, $request, $as_path ) = @_;

	eval {

		die "$as_path already mounted" if exists $mounted{$as_path};

		debug "mount($provider, $request, $as_path)" if $debug;

		my $class = 'File::Redirect::' . $provider;
		eval "use $class;";
		die $@ if $@;

		$mounted{$as_path} = {
			request => $request,
			device  => $class-> mount( $request, $dev_no ),
			match   => qr/^\Q$as_path\E/,
			handles => {},
		};

		$dev_no++;
	};

	return $@ ? undef : 1;
}

sub umount
{
	my ( $path ) = @_;
	
	debug "umount($path)" if $debug;
	
	return unless exists $mounted{$path};

	my $entry = delete $mounted{$path};
	$entry-> {device}-> Close($_) for values %{ $entry-> {handles} };
	$entry-> {device}-> umount;
	
	return 1;
}

END {
	my @mounted = keys %mounted; 
	umount($_) for @mounted;
};

sub to_entry
{
	my $path = shift;

	study $path;
	keys %mounted;
	while (my ($k,$v) = each %mounted) {
		return $v if $path =~ $v->{match};
	}
	return undef;
}

sub is_path_redirected { to_entry(@_) ? 1 : 0 }

sub Open
{
	my ($path, $mode) = @_;
	
	debug "open($path, $mode)" if $debug;

	my $entry = to_entry($path);
	return Errno::ENOENT() unless $entry;
	
	debug "device=$entry->{device}:$entry->{request}" if $debug;

	$path =~ s/$entry->{match}//;
	my $handle = $entry-> {device}-> Open($path, $mode);

	if ( ref $handle ) {
		my $iobase = File::Redirect::handle2iobase($handle);
		$entry-> {handles}-> {$iobase} = $handle;
		debug "success! handle=$handle, iobase=$iobase" if $debug;
	} else {
		debug "failed with $handle" if $debug;
	}

	return $handle;
}

sub Stat
{
	my ($path) = @_;

	debug "stat($path)" if $debug;

	my $entry = to_entry($path);
	return Errno::ENOENT() unless $entry;
	
	debug "device=$entry->{device}:$entry->{request}" if $debug;

	$path =~ s/$entry->{match}//;
	my $result = $entry-> {device}-> Stat($path);
	
	debug "result:$result" if $debug;

	return $result;
}

sub Close
{
	my $iobase = shift;
	
	debug "close($iobase)" if $debug;

	my ($entry, $handle);
	for ( values %mounted ) {
		next unless $handle = delete $_-> {handles}-> {$iobase};
		$entry = $_;
		last;
	}
	return Errno::ENOENT() unless $handle;
	
	debug "handle=$handle:device=$entry->{device}:$entry->{request}" if $debug;

	return $entry-> {device}-> Close($handle);
}

1;

=pod

=head1 NAME

File::Redirect - override native perl file oprations

=head1 SYNOPSIS

   $ unzip -l Foo-Bar-0.01.zip
   Archive:  Foo-Bar-0.01.zip
     Length     Date   Time    Name
    --------    ----   ----    ----
           0  02-25-12 07:46   Foo-Bar-0.01/
           0  02-25-12 07:47   Foo-Bar-0.01/lib/
           0  02-25-12 07:47   Foo-Bar-0.01/lib/Foo/
          43  02-25-12 07:47   Foo-Bar-0.01/lib/Foo/Bar.pm
    --------                   -------
          43                   4 files

   $ unzip -p Foo-Bar-0.01.zip Foo-Bar-0.01/lib/Foo/Bar.pm 
   package Foo::Bar;
   sub foo { 42 }
   1;

   $ cat test.pl 
   use File::Redirect::lib ('Zip', 'Foo-Bar-0.01.zip', '/Foo-Bar-0.01/lib');
   use Foo::Bar;
   print Foo::Bar::foo(), "\n";

   $ perl test.pl
   42

=head1 DESCRIPTION

Perl's own C<use> and C<require> cannot be overloaded so that underlying file requests
are mapped to something else. This module hacks IO layer system so that one can fool
Perl's IO into thinking that it operates on files while feeding something else, for
example archives. 

The framework currently overrides only C<stat> and C<open> builtins, which is enough
for hacking into C<use> and C<require>. The framework though is capable of being extended
to override other file- and dir- based operations, but that's probably is easier to
do separately by overriding C<*CORE::GLOBAL::> functions.

Warning: works only if perl's PERL_IMPLICIT_SYS is enabled

=head1 API

=over

=item mount $provider, $request, $as_path

Similar to unix mount(1) command, the function 'mounts' an abstract data entity ($request)
into file path $as_path by sending it to $provider. For example, provider C<Simple> treats
request as path-content hash. After this command

   mount( 'Simple', { 'a' => 'b' }, 'simple:')

reading from file 'simple:a' yield 'b' as its content. See also L<File::Redirect::Zip>.

The function return success flag; on failure, $@ contains the error.

=item umount $path

Removes data entity associated with $path.

=back

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut

