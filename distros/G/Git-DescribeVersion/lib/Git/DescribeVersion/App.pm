# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Git-DescribeVersion
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Git::DescribeVersion::App;
{
  $Git::DescribeVersion::App::VERSION = '1.015';
}
BEGIN {
  $Git::DescribeVersion::App::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Run Git::DescribeVersion as one-line script

use Git::DescribeVersion ();
use Getopt::Long qw(GetOptions); # core

# for simplicity
our %Defaults = %Git::DescribeVersion::Defaults;

my %get_opt_spec = map {
  my $dash = $_;
  # accept --opt_name or --opt-name (but store it in the hash as opt_name)
  # don't duplicate single words ("format=s" rather than "format|format=s")
  ( $dash =~ tr/_/-/ ? "$_|$dash=s" : "$_=s" )
} keys %Defaults;

# simple: enable `perl -MGit::DescribeVersion::App -e run`
sub import {
  no strict 'refs'; ## no critic
  *{caller(0) . '::run'} = \&run;
}

sub options {
  # allow usage as Git::DescribeVersion::App->run()
  # (for consistency with other App's)
  # and simply discard the unused argument
  shift(@_) if @_ && $_[0] eq __PACKAGE__;

  my %env;
  foreach my $opt ( keys %Defaults ){
    # look for $ENV{GIT_DV_OPTION}
    my $eopt = "\UGIT_DV_$opt";
    $env{$opt} = $ENV{$eopt} if exists($ENV{$eopt});
  }

  my %argv;
  GetOptions(\%argv, 'help' => \&usage, %get_opt_spec)
    or usage();

  my %args = ref($_[0]) ? %{$_[0]} : @_;

  # order of importance: %ENV, @ARGV, @_
  return {%env, %argv, %args};
}

sub run {
  print Git::DescribeVersion->new(options(@_))->version, "\n";
}

sub usage {
  no warnings 'uninitialized';
  # show package name if script name is "-" or "-e"
  printf("%s %s\n\nOptions (and their default values):\n\n",
    ($0 =~ /^-e?$/ ? __PACKAGE__ : $0), __PACKAGE__->VERSION
  );

  foreach my $opt ( sort keys %Defaults ){
    (my $arg = $opt) =~ tr/_/-/;
    printf(qq[  --%-18s "%s"\n], $arg, $Defaults{$opt});
  }

  print "\nFor more information try `perldoc Git::DescribeVersion::App`\n";
  exit;
}

1;


__END__
=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS repo

=head1 NAME

Git::DescribeVersion::App - Run Git::DescribeVersion as one-line script

=head1 VERSION

version 1.015

=head1 SYNOPSIS

Print out the version from L<Git::DescribeVersion> in one line:

  perl -MGit::DescribeVersion::App -e run

Options can be passed as program arguments (C<@ARGV>):

  perl -MGit::DescribeVersion::App -e run --match-pattern "rev-*"

The C<@ARGV> form allows arguments
to be spelled with dashes instead of underscores.

Options can also be passed in a hash or hashref
just like L<Git::DescribeVersion/new>:

  perl -MGit::DescribeVersion::App -e 'run(match_pattern => "rev-*")'

Or can be environment variables spelled like I<GIT_DV_OPTION>:

  export GIT_DV_MATCH_PATTERN="rev-*"
  perl -MGit::DescribeVersion::App -e run

This (hopefully) makes it easy for you to write
the alias, function, Makefile or script that does exactly what you want.

If not, feel free to send me suggestions (or patches)
that you think would make it simpler or more powerful.

=head1 METHODS

=head2 run

Convenience method for writing one-liners.

Exported to main package.

Accepts arguments in a hash or hashref
which are passed to the constructor.

Also looks for arguments in %ENV and @ARGV.

See L</SYNOPSIS>.

=for Pod::Coverage options usage

=for test_synopsis 1;
__END__

=head1 SEE ALSO

=over 4

=item *

L<Git::DescribeVersion>

=back

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

