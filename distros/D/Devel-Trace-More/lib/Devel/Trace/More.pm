package Devel::Trace::More;


=head1 NAME

Devel::Trace::More - Like Devel::Trace but with more control

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

  #!/usr/bin/perl -d:Trace::More

  use Devel::Trace::More qw{ filter_on };
  
  filter_on('blah');

  filter_on(qr/blah/);

  filter_on(sub { my ($p, $file, $line, $code) = @_; ... });

  # or

  $IS_INTERESTING = sub { my ($p, $file, $line, $code) = @_; ... };

=head1 DESCRIPTION

This module will print out every line of code as it executes when used under
the perl debugger.  By default all executed lines will print to STDERR. By 
calling filter_on with a code ref, regex ref, a scalar, or by setting 
$Devel::Trace::More::IS_INTERESTING directly then only those lines that are
'interesting' will be returned.

If filter_on is given a scalar or a regular expression reference then the
file name of the code being executed or the line of code itself that matches
the given patter will be printed.  Passing in a code ref is the same as setting
$IS_INTERESTING itself.  Setting the filter this way will allow you to do
more complicated things like filtering on just the module name or the line number
of the code.  $IS_INTERESTING can be changed in different places in the code if
needed.

Caveat: Using regular expressions to filter what gets printed can cause unexected
issues if the code being debugged relies on the regular expression global variables.
Use with caution!

=cut

use strict;
use warnings;

use Exporter;

use base 'Exporter';
our @EXPORT_OK = qw{ trace filter_on output_to };

our $VERSION = '0.05';

our $IS_INTERESTING = sub { return 1; };
our $TRACE = 1;
our $OUT = *STDERR;

# This is the important part.  The rest is just fluff.
sub DB::DB {
    return unless $TRACE;
    my ($p, $f, $l) = caller;
  
    # have no idea how to do this with strict on
    no strict 'refs';
    my $code = \@{"::_<$f"};
    use strict 'refs';
    my $code_line = defined($code->[$l]) ? $code->[$l] : '';
    chomp($code_line);
  
    print $OUT ">> $f:$l: $code_line\n" if $OUT && $IS_INTERESTING->($p, $f, $l, $code_line);
}

=head1 FUNCTIONS

=head2 filter_on(...)

Takes a string, code ref, or regular expression ref and sets the IS_INTERESTING code ref appropriately.

=over 1

=item String

A string will cause the line of code to be printed if either the filename or the code line has the
string in it.

=item Code Ref

A code ref passed will just set $IS_INTERESTING to it, saves a few characters of typing.

=item RegEx Ref

The line of code will be printed if the regular expression matches either the file name or the line of code 

=back

=cut

sub filter_on {
    my $filter = shift;

    if ( uc( ref($filter) ) eq 'REGEXP') {
        $IS_INTERESTING = sub { my ($p, $file, $line_num, $code_line) = @_; return $file =~ $filter || $code_line =~ $filter; };
    }
    elsif ( uc( ref($filter) ) eq 'CODE') {
        $IS_INTERESTING = $filter;
    }
    elsif (! ref($filter) ) {
        $IS_INTERESTING = sub { my ($p, $file, $line_num, $code_line) = @_; return ( index($file, $filter) > -1) || ( index($code_line, $filter) > -1); };
    }
    else {
        die "I don't know how to handle that filter!";
    }
}

=head2 trace('on') or trace('off')

Turns the printing of code on or off

=cut

my %tracearg = ('on' => 1, 'off' => 0);
sub trace {
    my $arg = shift;
    $arg = $tracearg{$arg} while exists $tracearg{$arg};
    $TRACE = $arg;
}

=head2 output_to($filename)

Given a filename the code lines will get printed to the file instead of STDERR.
Can be called with different filenames at different points in the script if need be.
By default the file will be open for reading and will be either created or cleared.
You can input '>>' as a param to have the trace keep appending.

=cut

sub output_to {
    # have to turn trace off because messing with filehandles while
    # it's tracing itself might cause it to die
    trace('off');
    my $filename = shift;
    my $mode     = shift || '>';

    # There can be cases where STDOUT/STDERR messed with in the code
    # which will cause problems if $OUT isn't cleared first
    $OUT = undef;

    open $OUT, $mode, $filename or die "Can't open file $filename : $!";
    trace('on');
}

1;
__END__

=head1 SEE ALSO

L<Devel::Trace>

=head1 AUTHOR

mburns, E<lt>mburns.lungching@gmail.comE<gt>

Also code from Mark Jason Dominus

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mike Burns

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
