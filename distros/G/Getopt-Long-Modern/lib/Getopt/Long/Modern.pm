package Getopt::Long::Modern;

use strict;
use warnings;
use Getopt::Long 'GetOptions';
use Exporter ();

our $VERSION = '1.000';

our @ISA = 'Exporter';
our @EXPORT = 'GetOptions';

my @config = qw(default gnu_getopt no_ignore_case);

sub import {
	my $class = shift;
	$class->export_to_level(1);
	shift if @_ and $_[0] eq ':config';
	Getopt::Long::Configure(@config, @_);
}

1;

=head1 NAME

Getopt::Long::Modern - Use Getopt::Long with modern defaults

=head1 SYNOPSIS

 use Getopt::Long::Modern;
 GetOptions(
   "f|foo=i" => \my $foo,
   "b|bar"   => \my $bar,
   "Z|baz=s" => \my @baz,
 );

=head1 DESCRIPTION

L<Getopt::Long::Modern> is a simple wrapper of L<Getopt::Long> to reduce the
amount of typing needed to get modern defaults, and to avoid having to remember
the correct incantations. See L<Getopt::Long/"Summary of Option Specifications">
for details on specifying options using L<Getopt::Long>.

Only the C<GetOptions> function from L<Getopt::Long> is exported. Additional
L<Getopt::Long> configuration may be passed as import parameters.

 use Getopt::Long::Modern qw(auto_help auto_version pass_through);

For any more advanced usage, you should probably use L<Getopt::Long> directly.
The equivalent L<Getopt::Long> configuration to using this module is:

 use Getopt::Long qw(:config gnu_getopt no_ignore_case);

=head1 DEFAULTS

L<Getopt::Long::Modern> currently sets the following configuration options by
default. See L<Getopt::Long/"Configuring Getopt::Long"> for more details on
available configuration.

=head2 gnu_getopt

This sets C<gnu_compat> to allow C<--opt=> for setting an empty string option,
C<bundling> to allow short options to be bundled together, C<permute> to allow
specifying options before or after other arguments, and C<no_getopt_compat> to
disallow C<+> for specifying options.

=head2 no_ignore_case

This makes all options case-sensitive, which is expected and required when
explicitly specifying short options of the same character but different case.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Getopt::Long::Descriptive>, L<Getopt::Again>, L<Opt::Imistic>
