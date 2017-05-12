package ExtUtils::configPL;

use 5.006;
use strict;
use warnings;

our ($VERSION) = '$Revision: 1.1 $' =~ /\$Revision:\s+([^\s]+)/;

use Filter::Util::Call;
use Config;
use File::Basename qw(dirname);
use Cwd;
use Carp;

our $filename;

BEGIN {
    $filename = dirname($0) . '/' . $main::ARGV[0];
    open OUT, ">$filename" || croak "Unable to open: $main::ARGV[0]";
}

sub import {
    my ($class, %args) = @_;

    # Verify the arguments
    my $ident = '<<--(\w+)-->>';
    my $mode = 0755;

    foreach my $arg (keys %args) {
    CONTROLS: {
	($arg eq 'identifier') && do { $ident = $args{'identifier'}; last };
	($arg eq 'mode') && do { $mode = $args{'mode'}; last };
	croak "ExtUtils::configPL: Unknow control: $arg";
    }
    }

    chmod $mode, $filename;

    # Pick apart the parts of the identifier
    my ($pre, $post) = ($ident =~ m/(.*)(?<!\\)\(.+(?<!\\)\)(.*)/);

    filter_add (
	sub {
	    my $in = 1;
	    while (my $status = filter_read()) {
		if ($in) {
		    if (m/^\s*no\s+$class\s*;\s*$/) {
			$in = 0;
			$_= '';
			next;
		    }

		    if (my @configs = m/$ident/g) {
			foreach my $var (@configs) {
			    croak "ExtUtils::ConfigPL: Unknown configuration variable: $var"
				unless exists $Config{$var};
			    s/${pre}${var}${post}/$Config{$var}/g;
			}
		    }
		} elsif (m/^\s*use\s+$class\s*;\s*$/) {
		    $in = 1;
		    $_= '';
		    next;
		}
		print OUT;
		$_ = '';
	    }
	    exit;
	}
    );
}

1;
__END__

=head1 NAME

ExtUtils::configPL - Perl extension to automagiclly configure perl scripts

=head1 SYNOPSIS

  use ExtUtils::configPL;
  <<--startperl-->> -w
  ...

  no ExtUtils::configPL;

  ...

=head1 DESCRIPTION

This module is used to add configuration information to a perl script, and
is meant to be used with the C<ExtUtils::MakeMaker> module.

C<ExtUtils::configPL> is not a "normal" Perl extension. It does add or
encapsulate functionality to your script, but it filters the script,
replacing I<tags> with items from the C<Config> module, writing the resulting
script to a new file.

The normal use for this module is to add the "shebang" line as the first line
of a script.

    use ExtUtils::ConfigPL;
    <<--startperl-->> -w

would be replaced with:

    #/usr/local/bin/perl -w

(or where ever your perl executable is located.)

The C<use ExtUtils::configPL;> line B<I<must>> be the first line in the script!
Anything that comes before that line will not be in the filtered script.

This module is intended to work with C<ExtUtils::MakeMaker>. You would create
your script, as above, with the C<.PL> extension, and add a C<PL_FILE> option
to the C<WriteMakefile()> call (see L<ExtUtils::MakeMaker> for more details.)

For example:

    'PL_FILES' => { 'foo.PL' => 'foo.pl' }

Creating the C<Makefile> would create a rule that would call your script like:

    $(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB)
	foo.PL foo.pl

although the line could be as simple as:

    perl foo.PL foo.pl

C<ExtUtils::configPL> takes the first argument, and uses it as the name of
filtered script, and will write the new script into it.

=head2 TAGS

I<Tags> are use to mark the location that a substitution will be made. By
default, tags are in the form of:

    <<--variable-->>

where the I<variable> is one of the C<Config.pm> variables.

The tag will be replaced anywhere it is found in the script. You can stop
the substitution in a section of the script by surrounding the section like:

    no ExtUtils::configPL;
    ...
    # Nothing will be substituted.
    ...
    use ExtUtils::configPL;
    ...
    # Substituting is resumed.

The C<use> and C<no> lines above are removed from the filtered script so that,
when you run the script, C<ExtUtils::configPL> will not be re-ran.

=head2 OPTIONS

There are several options that control how C<ExtUtils::configPL> operation.
The options follow as a LIST only on the first C<use ExtUtils::configPL> call.
Any other use, and the options are ignored.

    use ExtUtils::configPL identifier => '\$Config\{(\w+)\}', mode => 0700;

=over 4

=item C<identifier => 'regular expression'>

The C<identifier> option allows you to change what the default tag looks like.
By default, a tag will match the regular expression:

    <<--(\w+)-->>

By creating your own custom tag identifer, you can change the default behavour.

    identifier => '\$Config\{(\w+)\}'

would recognize the C<Config.pm> variable syntax.

There must be only one set of parenthesis. If you must include them, escape
them with a backslash ('C<\>').

=item C<mode => octal number>

This option is used to set the permissions list for the outputted script.
By default, the permissions are set to 0755. Here is an example to set
the permissions so only the owner has access to the script:

    mode => 0700

=back

head1 AUTHOR

Mark Pease <peasem@home.com>

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

=cut
