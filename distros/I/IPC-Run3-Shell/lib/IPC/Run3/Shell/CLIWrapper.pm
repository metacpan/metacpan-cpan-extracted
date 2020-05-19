#!perl
package IPC::Run3::Shell::CLIWrapper;
use warnings;
use strict;

our $VERSION = '0.58';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

BEGIN {
	require IPC::Run3::Shell;
	*__pp = \&IPC::Run3::Shell::pp; # double underscore to not clutter up the namespace too much
	*__debug = \&IPC::Run3::Shell::debug;
}
sub __DEBUG { $IPC::Run3::Shell::DEBUG } # don't alias because that doesn't work with `local`

our %DEFAULTS = ( opt_char=>'--', val_sep=>undef, under2dash=>1 );

my %NEW_ARGS = map {$_=>1} qw/ opt_char val_sep under2dash /;

sub new {
	# The arguments to new() are the same as make_cmd():
	# option hashrefs can be at the *beginning* of the argument list
	my ($class, @mcmd) = @_;
	my %opt;
	%opt = ( %opt, %{shift @mcmd} ) while ref $mcmd[0] eq 'HASH';
	# now extract the arguments we care about
	my %self;
	for (keys %NEW_ARGS) { $self{$_} = delete $opt{$_} if exists $opt{$_} }
	# set up ourselves
	for (keys %DEFAULTS) { $self{$_} = $DEFAULTS{$_} unless exists $self{$_} }
	__debug "new CLIWrapper, self=",__pp(\%self),", opt=",__pp(\%opt),", cmd=",__pp(\@mcmd) if __DEBUG;
	# ok, now set up the command
	$self{cmd} = IPC::Run3::Shell::make_cmd(\%opt, @mcmd);
	return bless \%self, $class;
}

sub __argconv {
	my $self = shift;
	my @args;
	my $oc = $self->{opt_char}; $oc = '' unless defined $oc;
	my $vs = $self->{val_sep};
	my $u2d = $self->{under2dash};
	for my $x (@_) {
		if ( ref $x eq 'ARRAY' ) {
			if ( @$x%2 ) {
				# ... work around a Carp issue in really old Perls ...
				# uncoverable branch true
				# uncoverable condition true
				if ( $] lt '5.008' ) {
					warn "Odd number of elements in argument list";  # uncoverable statement
				} else { warnings::warnif('IPC::Run3::Shell',
					'Odd number of elements in argument list') }
			}
			for (my $i=0;$i<@$x;$i+=2) {
				my ($k,$v) = @{$x}[$i,$i+1];
				$k =~ s/_/-/g if $u2d;
				push @args, defined $v
					? ( defined $vs ? $oc.$k.$vs.$v : ($oc.$k, $v) )
					: $oc.$k;
			}
		}
		else { push @args, $x }
	}
	return @args;
};

use overload
	'&{}' => sub {
		my $self = shift;
		return sub {
			my @args = __argconv($self, @_);
			__debug "plain command, args=",__pp(\@args) if __DEBUG;
			$self->{cmd}->(@args);
		}
	};

our $AUTOLOAD;
sub AUTOLOAD {  ## no critic (ProhibitAutoloading)
	my $meth = $AUTOLOAD;
	$meth =~ s/^.*:://;
	my $sub = sub {
		my $self = shift;
		my $cmd  = $meth;
		my @args = __argconv($self, @_);
		$cmd =~ s/_/-/g if $self->{under2dash};
		__debug "method ",__pp($cmd),", args=",__pp(\@args) if __DEBUG;
		$self->{cmd}->($cmd, @args);
	};
	no strict 'refs';  ## no critic (ProhibitNoStrict)
	*$AUTOLOAD = $sub;
	goto &$AUTOLOAD;
}
sub DESTROY {} # so AUTOLOAD isn't called on destruction

1;
__END__

=head1 Name

IPC::Run3::Shell::CLIWrapper - Perl extension for wrapping arbitrary
command-line tools

=head1 Synopsis

 use IPC::Run3::Shell::CLIWrapper;
 
 my $git = IPC::Run3::Shell::CLIWrapper->new({chomp=>1}, 'git');
 my @log = $git->log('--oneline');
 
 my $perl = IPC::Run3::Shell::CLIWrapper
     ->new( { opt_char=>'-' }, 'perl' );
 my $foo = $perl->( [ l => undef, e => q{ print for @ARGV } ],
     '--', 'Hello', 'World!' );
 
 use JSON::PP qw/decode_json/;
 my $s3api = IPC::Run3::Shell::CLIWrapper->new( { fail_on_stderr => 1,
     stdout_filter => sub { $_=decode_json($_) } },
     qw/ aws --profile MyProfile --output json s3api /);
 my $buckets = $s3api->list_buckets;

=for comment
(Note you can configure an AWS profile via
C<aws configure --profile=MyProfile>.)

=for test
 ok grep({ /^12f75a7[0-9a-fA-F]*\s+Initial commit$/ } @log),
     'git log --oneline';
 is $foo, "Hello\nWorld!\n", 'run perl via CLIWrapper';
 like $buckets->{Owner}{ID}, qr/^[0-9a-fA-F]+$/, 'aws list-buckets';

=for test cut

=head1 Description

This module wraps L<IPC::Run3::Shell|IPC::Run3::Shell> in a layer
that translates method calls and their arguments to the command-line
arguments of system commands.

=head2 C<new>

The arguments to the constructor are the same as to
L<IPC::Run3::Shell/make_cmd>, with the addition of the following
options, which can be placed in hashref(s) at the beginning of the
argument list:

=over

=item C<opt_char>

The string to prefix to option names, defaults to C<"--">. Other
common values are C<"-"> and perhaps C<"/"> on Windows.

=item C<val_sep>

The separator between an option name and its value; if set to
C<undef> (the default), then the name and value are two separate
items in the argument list.

=item C<under2dash>

Boolean to enable or disable the conversion of underscores to dashes
in option names and method names. Option values and plain strings
remain unchanged. Default is I<true>.

=back

=head2 Argument Lists

The name of the method is the first item in the generated argument
list. You may also call the object of this class as a code reference,
which behaves exactly the same as a method call except no method name
is added as the first item of the argument list. This can be useful
if you want to start with options, or you want to call commands that
have the same names as the methods of this class (C<new>,
C<AUTOLOAD>, and C<DESTROY>) or the built-ins of the
L<UNIVERSAL|UNIVERSAL> class, such as C<can>.

The arguments to the method call (or code reference) are translated
as follows:

=over

=item Array references

These must have an even number of items, and every two items
represent a pair of an option name and its value. If the value is
C<undef>, it is omitted from the generated argument list. See also
the options described in L</new>.

=item Other values (strings, hash references, etc.)

Act the same as arguments to L<IPC::Run3::Shell|IPC::Run3::Shell>.
This means that hash references can be passed as the last item(s) in
the list to set options.

=back

=head1 Author, Copyright, and License

Copyright (c) 2020 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command "C<perldoc perlartistic>" or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

