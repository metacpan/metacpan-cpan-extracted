#!perl
package File::Replace::Inplace;
use warnings;
use strict;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our $VERSION = '0.12';

our @CARP_NOT = qw/ File::Replace /;

sub new {  ## no critic (RequireArgUnpacking)
	my $class = shift;
	croak "Useless use of $class->new in void context" unless defined wantarray;
	croak "$class->new: bad number of args" if @_%2;
	my %args = @_; # really just so we can inspect the debug option
	my $self = {
		_debug => ref($args{debug}) ? $args{debug} : ( $args{debug} ? *STDERR{IO} : undef),
		_h_argv => *ARGV{IO},
	};
	tie *{$self->{_h_argv}}, 'File::Replace::Inplace::TiedArgv', @_;
	bless $self, $class;
	$self->_debug("$class->new: tied ARGV\n");
	return $self;
}
*_debug = \&File::Replace::_debug;  ## no critic (ProtectPrivateVars)
sub cleanup {
	my $self = shift;
	if ( defined($self->{_h_argv}) && defined( my $tied = tied(*{$self->{_h_argv}}) ) ) {
		if ( $tied->isa('File::Replace::Inplace::TiedArgv') ) {
			$self->_debug(ref($self)."->cleanup: untieing ARGV\n");
			untie *{$self->{_h_argv}};
		}
		delete $self->{_h_argv};
	}
	delete $self->{_debug};
	return 1;
}
sub DESTROY { return shift->cleanup }

{
	## no critic (ProhibitMultiplePackages)
	package # hide from pause
		File::Replace::Inplace::TiedArgv;
	use Carp;
	use File::Replace;
	
	BEGIN {
		require Tie::Handle::Argv;
		our @ISA = qw/ Tie::Handle::Argv /;  ## no critic (ProhibitExplicitISA)
	}
	
	# this is mostly the same as %NEW_KNOWN_OPTS from File::Replace,
	# except without "in_fh" (note "debug" is also passed to the superclass)
	my %TIEHANDLE_KNOWN_OPTS = map {$_=>1} qw/ debug layers create chmod
		perms autocancel autofinish backup files filename /;
	
	sub TIEHANDLE {  ## no critic (RequireArgUnpacking)
		croak __PACKAGE__."->TIEHANDLE: bad number of args" unless @_ && @_%2;
		my ($class,%args) = @_;
		for (keys %args) { croak "$class->tie/new: unknown option '$_'"
			unless $TIEHANDLE_KNOWN_OPTS{$_} }
		my %superargs = map { exists($args{$_}) ? ($_=>$args{$_}) : () }
			qw/ files filename debug /;
		delete @args{qw/ files filename /};
		my $self = $class->SUPER::TIEHANDLE( %superargs );
		$self->{_repl_opts} = \%args;
		return $self;
	}
	
	sub OPEN {
		my $self = shift;
		croak "bad number of arguments to open" unless @_==1;
		my $filename = shift;
		if ($filename eq '-') {
			$self->_debug(ref($self).": Reading from STDIN, writing to STDOUT");
			$self->set_inner_handle(*STDIN{IO});
			select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		}
		else {
			$self->{_repl} = File::Replace->new($filename, %{$self->{_repl_opts}} );
			$self->set_inner_handle($self->{_repl}->in_fh);
			*ARGVOUT = $self->{_repl}->out_fh;  ## no critic (RequireLocalizedPunctuationVars)
			select(ARGVOUT);  ## no critic (ProhibitOneArgSelect)
		}
		return 1;
	}
	
	sub inner_close {
		my $self = shift;
		if ( $self->{_repl} ) {
			$self->{_repl}->finish;
			$self->{_repl} = undef;
		}
		return 1;
	}
	
	sub sequence_end {
		my $self = shift;
		$self->set_inner_handle(\do{local*HANDLE;*HANDLE})  ## no critic (RequireInitializationForLocalVars)
			if $self->innerhandle==*STDIN{IO};
		select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		return;
	}
	
	sub UNTIE {
		my $self = shift;
		select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		delete @$self{ grep {/^_[^_]/} keys %$self };
		return $self->SUPER::UNTIE(@_);
	}
	
	sub DESTROY {
		my $self = shift;
		select(STDOUT);  ## no critic (ProhibitOneArgSelect)
		# File::Replace destructor will warn on unclosed file
		delete @$self{ grep {/^_[^_]/} keys %$self };
		return $self->SUPER::DESTROY(@_);
	}
	
}

1;
__END__

=head1 Name

Tie::Handle::Inplace - Emulation of Perl's C<-i> switch via L<File::Replace|File::Replace>

=head1 Synopsis

=for comment
REMEMBER to keep these examples in sync with 91_author_pod.t

 use File::Replace qw/inplace/;
 {
     my $inpl = inplace( backup=>'.bak' );
     local @ARGV = ("file1.txt", "file2.txt");
     while (<>) {
         chomp;
         s/[aeiou]/_/gi;
         print $_, "\n";
     }
 }

Same thing, but from the command line:

 perl -MFile::Replace=-i.bak -ple 's/[aeiou]/_/gi' file1.txt file2.txt

=head1 Description

This module provides a mechanism to replace Perl's in-place file editing
(see the C<-i> switch in L<perlrun>) with in-place editing via
L<File::Replace|File::Replace>. It does so by using
L<Tie::Handle::Argv|Tie::Handle::Argv> to preserve as much of the
behavior of Perl's magic C<< <> >> operator and C<-i> switch as possible.

When you create an object of the class C<File::Replace::Inplace>, either
by C<< File::Replace::Inplace->new() >> or via C<inplace()> from
L<File::Replace|File::Replace> (the two are identical), it acts as a
scope guard: C<ARGV> is tied when the object is created, and C<ARGV>
is untied when the object goes out of scope (except if you tie C<ARGV>
to another class in the meantime).

You can pass the aforementioned constructors the same arguments as
L<File::Replace|File::Replace>, with the exception of C<in_fh>, and
in addition to the options supported by the
L<Tie::Handle::Argv constructor|Tie::Handle::Argv/Constructor>,
C<files> and C<filename>.

Once C<ARGV> is tied, you can use C<< <> >> as you normally would, and
the files in C<@ARGV> will be edited in-place using
L<File::Replace|File::Replace>, for an example see the L</Synopsis>.

See also L<File::Replace/inplace> for a description of the C<-i> argument
to L<File::Replace|File::Replace>, which can be used for oneliners as
shown in the L</Synopsis>.

This documentation describes version 0.12 of this module.

=head2 Differences to Perl's C<-i>

=over

=item *

Problems like not being able to open a file would normally only cause a warning
when using Perl's C<-i> option, in this module it depends on the setting of
the C<create> option, see L<File::Replace/create>.

=item *

See the documentation of the C<backup> option at L<File::Replace/backup>
for differences to Perl's C<-i>.

=item *

If you use the C<close ARGV if eof;> idiom to reset C<$.>, as documented in
L<perlfunc/eof>, then be aware that the C<close ARGV> has the effect of
calling C<finish> on the underlying L<File::Replace|File::Replace> object,
which has the effect of closing the current output handle as well.
(With Perl's C<-i> switch, it is possible to continue writing to the output
file even after the C<close ARGV>. The equivalent to what this module does
would be C<if (eof) { close ARGV; close select; }>.)

=back

=head2 Warning About Perls Older Than v5.16 and Windows

Please see L<Tie::Handle::Argv/Warning About Perls Older Than v5.16 and Windows>.
In addition, there is a known issue that C<eof> may return unexpected
values on Perls older than 5.12 when reading from C<STDIN> via a
tied C<ARGV>.

It is B<strongly recommended> to use this module on Perl 5.16 and up.
On older versions, be aware of the aforementioned issues.

In addition, a significant portion of this module's tests must be skipped
on Windows on Perl versions older than 5.28. I would therefore strongly
suggest using the most recent version of Perl for Windows.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut
