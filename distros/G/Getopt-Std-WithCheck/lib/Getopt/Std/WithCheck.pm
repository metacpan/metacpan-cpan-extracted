package Getopt::Std::WithCheck;

use 5.008004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Getopt::Std::WithCheck ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

##############################################################################
## Some modules required #####################################################
##############################################################################
use Getopt::Std;

##############################################################################
## Ok, methods here ##########################################################
##############################################################################

my $usage = '';

my $checkHArg = sub
    {
    if ($_[0])
        {
        print STDERR usage();
        exit 0;
        };
    return 0;
    };

my $checkHOpt = sub
	{
	my ($opts) = @_;

	foreach my $opt (@{$opts})
		{
		if ($opt->[0] eq 'h')
			{ return; };
		};
	unshift(@{$opts}, ['h', 0, 0, 'Print help notice, and exit', $checkHArg]);
	};

my $addLF = sub
	{ return $_[0].($_[0] =~ m/\n$/ ? '' : "\n"); };

my $makeOpts = sub
	{
	my ($opts) = @_;

	my $result = '';
	foreach my $opt (@{$opts})
		{ $result .= $opt->[0].($opt->[1] ? ':' : ''); };
	return $result;
	};

my $makeCfg = sub
	{
	my ($opts) = @_;

	my %result = ();
	foreach my $opt (@{$opts})
		{ $result{$opt->[0]} = $opt->[2]; };
	return \%result;
	};

my $defaultCheck = sub
	{ return $_[0]; };

my $makeChk = sub
	{
	my ($opts) = @_;

	my %result = ();
	foreach my $opt (@{$opts})
		{ $result{$opt->[0]} = defined($opt->[4]) ? $opt->[4] : $defaultCheck; };
	return %result;
	};

my $makeUsage = sub
	{
	my ($opts) = @_;

	my $result = '';

	foreach my $opt (@{$opts})
		{
		$result .= sprintf("-%s: %s\t%s\n",
		                   $opt->[0],
		                   &{$addLF}($opt->[3]),
		                   defined($opt->[2]) ? 'Default is \''.($opt->[1] ? $opt->[2] : ($opt->[2] ? 'Yes' : 'No')).'\'' : 'Parameter required'
		                  );
		};
	return $result;
	};


my $setUsage = sub
	{
	my ($name, $descr, $opts) = @_;
	$usage = &{$addLF}($name).&{$addLF}($descr).&{$addLF}(&{$makeUsage}($opts)).($^W ? "\ngetops string is '".&{$makeOpts}($opts)."'\n" : '');
	};

my $checkOpts = sub
	{
	my ($opts) = @_;

	if (ref($opts) eq 'HASH')
		{
		my @tmpOpts = ();
		while(my ($key, $val) = each(%{$opts}))
			{
			push(@tmpOpts, [$key,
			                $val->{'argument'},
			                $val->{'default'},
			                $val->{'description'},
			                $val->{'checkRoutine'},
			               ]
			    );
			};
		$opts = \@tmpOpts;
		};

	&{$checkHOpt}($opts);

	return $opts;
	};

sub getOpts($$$)
	{
	my ($name, $descr, $opts) = @_;

	my $self = undef;

	$opts = &{$checkOpts}($opts);

	&{$setUsage}($name, $descr, $opts);
	
	my $conf  = &{$makeCfg}($opts);
	my %check = &{$makeChk}($opts);
		
	Getopt::Std::getopts(&{$makeOpts}($opts), $conf);

	foreach my $key (keys(%{$conf}))
		{
		if (!defined($conf->{$key}))
			{ die "Required param '".$key."' is not set\n\n".usage(); };

		$conf->{$key} = &{$check{$key}}($conf->{$key});
		};

	return $conf;
	};

sub usage
	{
	my ($name, $descr, $opts) = @_;
	if (scalar(@_) > 0)
		{
		$opts = &{$checkOpts}($opts);
		&{$setUsage}($name, $descr, $opts);
		};
	return $usage;
	};


1;
__END__

=head1 NAME

Getopt::Std::WithCheck - Perl extension for process command line arguments with custom check on them

=head1 SYNOPSIS

  use Getopt::Std::WithCheck;

  my %opts = ('d' => {'argument'    => 0,
                      'default'     => 0,
                      'description' => "Print debug info",
                     },
             );

  my %CFG = %{Getopt::Std::WithCheck::getOpts('programName', "Example of Getopt::Std::WithCheck usage\n\n", \%opts)};

  if ($CFG{'d'})
  	{
  	print STDERR Getopt::Std::WithCheck::usage();
  	};

=head1 DESCRIPTION

Getopt::Std::WithCheck provides a simple way to proccess command line arguments check.

Also, basic "usage" functionality provided.

=head1 The Getopt::Std::WithCheck methods

=over 4

=item C<getOpts($programName, $programDescription, $PARAMHASHREF);>

Returns a hash contains all the parameters with values set in command line or provided by default.

C<I<checkRoutine>> (see below) is called for each parameter to check it.

Die with C<I<usage>> message in case of required parameter is not defined.

Parameters of this method are

=over 4

=item C<$programName>

Name of the program, will be used in C<I<usage>> message.

=item C<$programDescription>

Description of the program, will be used in C<I<usage>> message

=item I<$PARAMHASHREF>

I<%{$PARAMHASHREF}> contains the letters will be used for command line options as keys.

Values must be a reference to hash describing parameter

This parameter description should contain following keys:

=over 4

=item C<argument>

Boolean value indicated will this parameter followed by argument or not.

Default is not to take argument.

=item C<default>

Default value for this parameter.

Note: you can set C<default> to C<undef> to indicate required parameter.
In case required parameter is not provided  C<getOpts();> method will die with C<usage> message.

Default is C<undef>

=item C<description>

Description of this parameter. will be used in C<I<usage>> message.

Default is empty string.

=item C<checkRoutine>

Reference to a subroutine called to check a validity of this paramneter.

Called with one argument - the parameter itself. Value returned is used as parameter value.

Default routine is simple return parameter back to use it as is.

=back

Note: if C<'h'> parameter is not specified, default procedure is used for it.
Default procedure is to print C<I<usage>> message to C<STDERR> and exit with C<0> exit code.

=back

In addition to parameters processing C<I<getOpts>> creatina an I<usage> message.
This message is stored inside of module and can be accesses by C<I<usage>> method.

=item C<getOpts($programName, $programDescription, $PARAMLISTREF);>

Another form of C<I<getOpts>>.

C<@{$PARAMLISTREF}> should contain parameters description

=over 4

=item C<$PARAMLISTREF-E<gt>[0]>

Parameter letter, like a key in C<%{I<$PARAMHASHREF>}>
C<%{$PARAMHASHREF}> is used as parameters description

=item C<$PARAMLISTREF-E<gt>[1]>

Boolean value indicated will this parameter followed by argument or not, like a C<I<argument>> in C<%{I<$PARAMHASHREF>}>

=item C<$PARAMLISTREF-E<gt>[2]>

Default value for this parameter, like a C<I<default>> in C<%{I<$PARAMHASHREF>}>

=item C<$PARAMLISTREF-E<gt>[3]>

Description for this parameter, like a C<I<description>> in C<%{I<$PARAMHASHREF>}>

=item C<$PARAMLISTREF-E<gt>[4]>

Check routine for this parameter, like a C<I<checkRoutine>> in C<%{I<$PARAMHASHREF>}>

=back

=item C<usage($programName, $programDescription, $PARAMHASHREF);>

returns a usage message based on parameters passed (see C<I<getOpts>>).

=item C<usage($programName, $programDescription, $PARAMLISTREF);>

returns a usage message based on parameters passed (see C<I<getOpts>>).

=item C<usage()>

returns a usage message based on previous call of C<I<usage>> or C<I<getOpts>>.

=back



=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Getopt::Std>



=head1 AUTHOR

Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
