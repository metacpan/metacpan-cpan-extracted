#============================================================= -*-perl-*-
#
# LaTeX::Driver::FilterProgram
#
# DESCRIPTION
#   Implements the guts of the latex2xxx filter programs
#
# AUTHOR
#   Andrew Ford    <a.ford@ford-mason.co.uk>
#
# COPYRIGHT
#   Copyright (C) 2007 Andrew Ford.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# HISTORY
#
#   $Id: Paths.pm 45 2007-09-28 10:33:19Z andrew $
#========================================================================

package LaTeX::Driver::FilterProgram;

use strict;
use warnings;
use Carp;

use LaTeX::Driver;
use Getopt::Long;
use File::Slurp;

sub execute {
    my ($class, %options) = @_;
    my ($source, $output, $tt2mode, $debug, @vars, %var);

    GetOptions( 'output:s' => \$output,
		'tt2mode'  => \$tt2mode,
		'define:s' => \@vars,
		'debug'    => \$debug );

    if ( @ARGV ) {
	$source = shift @ARGV;
    }
    else {
	my $input = join '', <STDIN>;
	$source = \$input;
    }

    if ($tt2mode) {
	eval {
	    use Template;
	};
	if ($@) {
	    die "Cannot load the Template Toolkit - tt2 mode is unavailable\n";
	}
	if (!ref $source) {
	    ${$source} = read_file($source);
	}

	foreach (@vars) {
	    my ($name, $value) = split / \s* = \s* /mx;
	    printf(STDERR "defining %s as '%s'\n", $name, $value) if $debug;
	    $var{$name} = $value;
	}

	my $input;
	my $tt2  = Template->new({});
	$tt2->process($source, \%var, \$input)
	    or die $tt2->error(), "\n";

	$source = \$input;
    }

    if (!$output or $output eq '-') {
	my $tmp;
	$output = \$tmp;
    }
    eval {
	my $drv = LaTeX::Driver->new( source => $source,
				      output => $output,
				      format => $options{format} );
        $drv->run;
    };
    if (my $e = LaTeX::Driver::Exception->caught()) {
        $e->show_trace(1);
#        my $extra = sprintf("\nat %s line %d (%s)\n%s", $e->file, $e->line, $e->package, $e->trace);
        die $e; #sprintf("%s\n%s", "$e", $e->trace);
    }

    if (ref $output) {
        print ${$output};
    }

    return;
}


1;

__END__

=head1 NAME

LaTeX::Driver::FilterProgram

=head1 VERSION

=head1 SYNOPSIS

  use LaTeX::Driver::FilterProgram;
  LaTeX::Driver::FilterProgram->execute(format => $format);

=head1 DESCRIPTION

This module is not intended to be used except by the programs
C<latex2pdf>, C<latex2ps> and C<latex2dvi> that are included in the
LaTeX::Driver distribution.  It implements the guts of those filter
programs.

=head1 SUBROUTINES/METHODS

=over 4

=item C<execute(%params)>

This is the only method.  It implements the guts of the filter
programs, gathering the parameters for the C<LaTeX::Driver> object
constructor from the command line options, along with the options
passed from the calling script, which should be the format option.
Having constructed a driver object it then runs the driver.

If the C<-tt2> option is specified then the source document is taken
to be a Template Toolkit template and a Template object is constructed
and the template processed through that before being fed to the
C<LaTeX::Driver> module for latex formatting.  Template variables may
defined with the C<-define> option and these are passed to the
Template Toolkit processing stage (they are ignored if the C<-tt2>
option is not specified).

=back

=head1 DIAGNOSTICS

The module invokes the C<LaTeX::Driver> module and optionally the
C<Template> module.  Any errors from those modules are propogated
outwards.

=head1 CONFIGURATION AND ENVIRONMENT

The module invokes the latex family of programs via the
C<LaTeX::Driver> module.  Those programs have their own set of
environment variables and configuration files.


=head1 DEPENDENCIES

The module requires that the Template Toolkit is installed for the C<-tt2> option.

=head1 INCOMPATIBILITIES

None known.


=head1 BUGS AND LIMITATIONS

None known.


=head1 AUTHOR

Andrew Ford E<lt>a.ford@ford-mason.co.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 Andrew Ford.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
