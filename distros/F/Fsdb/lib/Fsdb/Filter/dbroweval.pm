#!/usr/bin/perl

#
# dbroweval.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: 8c28f7b692255da8ba7895ca3d5c79edcf00f160 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbroweval;

=head1 NAME

dbroweval - evaluate code for each row of a fsdb file

=head1 SYNOPSIS

    dbroweval [-f CodeFile] code [code...]

=head1 DESCRIPTION

Evaluate code for each row of the data.

Typical actions are things like reformatting
and other data transformations.

Code can include embedded column names preceded by underscores;
these result in the value of that column for the current row.

The values of the last row's columns are retrieved with _last_foo
where foo is the column name.

Even more perverse, _columname(N) is the value of the
Nth column after columnname [so _columnname(0) is the also
the column's value.


=head1 OPTIONS

=over 4

=item B<-b CODE>

Run CODE before reading any data (like awk BEGIN blocks).

=item B<-e CODE>

Run CODE at the end of all data (like awk END blocks).

=item B<-f FILE>

Read code from the FILE.

=item B<-n> or B<--no-output>

no output except for comments and what is in the provided code

=item B<-N> or B<--no-output-even-comments>

no output at all, except for what is in the provided code

=item B<-m> or B<--manual-output>

The user must setup output,
allowing arbitrary comments.
See example 2 below for details.

=item B<-w> or B<--warnings>

Enable warnings in user supplied code.

=item B<--saveoutput $OUT_REF>

Save output writer (for integration with other fsdb filters).

=back

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-i> or B<--input> InputSource

Read from InputSource, typically a file name, or C<-> for standard input,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<-o> or B<--output> OutputDestination

Write to OutputDestination, typically a file name, or C<-> for standard output,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<--autorun> or B<--noautorun>

By default, programs process automatically,
but Fsdb::Filter objects in Perl do not run until you invoke
the run() method.
The C<--(no)autorun> option controls that behavior within Perl.

=item B<--header> H

Use H as the full Fsdb header, rather than reading a header from
then input.

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 ADVANCED USAGE

Typically L<dbroweval> outputs a line in the same schema for each input line.
For advanced usage, one can violate each of these assumptions.

Some fun:

=over 4

=item B<omitting a line>

Add the code C<next row if ($your condition);>

=item B<outputting an extra line>

Call C<&$write_fastpath_sub($fref)>.
You may find C<$fref>, the input row, useful.

=item B<changing the schema>

See the examples below in L</Command 2: Changing the Schema>

=back



=head1 SAMPLE USAGE

=head2 Input:

    #fsdb      size    mean    stddev  pct_rsd
    1024    1.4962e+06      2.8497e+05      19.047
    10240   5.0286e+06      6.0103e+05      11.952
    102400  4.9216e+06      3.0939e+05      6.2863
    #  | dbsetheader size bw
    #  | /home/johnh/BIN/DB/dbmultistats size bw
    #  | /home/johnh/BIN/DB/dbcol size mean stddev pct_rsd

=head2 Command:

    cat data.fsdb | dbroweval '_mean = sprintf("%8.0f", _mean); _stddev = sprintf("%8.0f", _stddev);'

=head2 Output:

    #fsdb      size    mean    stddev  pct_rsd
    1024     1496200          284970        19.047
    10240    5028600          601030        11.952
    102400   4921600          309390        6.2863
    #  | dbsetheader size bw
    #  | /home/johnh/BIN/DB/dbmultistats size bw
    #  | /home/johnh/BIN/DB/dbcol size mean stddev pct_rsd
    #  | /home/johnh/BIN/DB/dbroweval   { _mean = sprintf("%8.0f", _mean); _stddev = sprintf("%8.0f", _stddev); }


=head2 Command 2: Changing the Schema

By default, dbroweval reads and writes the same format file.
The recommended method of adding and removing columns is to do so
before or after dbroweval.  I.e.,

    cat data.fsdb |
	dbcolcreate divisible_by_ten | 
	dbroweval '_divisible_by_ten = (_size % 10 == 0);' |
	dbrow '_divisible_by_ten == 1' |
	dbcol size mean divisible_by_ten

Another approach is to use the C<next row> command to skip output of a row.
I.e., the equivalent:

    cat data.fsdb |
	dbcolcreate divisible_by_ten | 
	dbroweval '_divisible_by_ten = (_size % 10 == 0); next row if (!_divisible_by_ten);' |
	dbcol size mean divisible_by_ten

However, neither of these approachs work very well when the output
is a I<completely> different schema.

The recommended method for schema-changing commands is to write a full
filter, but a full filter is a bit heavy weight.
As an alternative, one can use the C<-m> option to request
manual configuration of the output, then use C<@out_args> to define
the output schema (it specifies the C<Fsdb::IO::Writer> arguments),
and C<$ofref> is the output row.
It may also reference <$in>, the input C<Fsdb::IO::Reader> argument,
and <$fref> as an aref to the current line.
Note that newly created columns I<do not> have underscore-names

Thus a third equivalent is:

    cat data.fsdb | \
	dbroweval -m -b '@out_args = ( -clone => $in, \
	         -cols => ($in->cols, divisible_by_ten); ' \
	    'my $div_by_10 = (_size % 10 == 0); \
	    $ofref = [ @$fref, $div_by_10 ] if ($div_by_ten);' |
	dbcol size mean divisible_by_ten

or

    cat data.fsdb | \
	dbroweval -m -b '@out_args = ( -clone => $in, \
		-cols => [qw(size mean divisible_by_ten)] ); ' \
	    'my $div_by_10 = (_size % 10 == 0);  \
	    $ofref = [ _mean, _size, $div_by_10 ] if ($div_by_ten);'


Finally, one can write different a completely different schema, although
it's more work:

    cat data.fsdb | \
	dbroweval -m -b '@out_args = (-cols => [qw(size n)]);' \
	    '$ofref = [ _size, 1 ];'

writes different columns, and

    cat data.fsdb | \
	dbroweval -n -m -b '@out_args = (-cols => [qw(n)]);  \
	    my $count = 0;' -e '$ofref = [ $count ];' '$count++;'

Is a fancy way to count lines.

The begin code block should setup C<@out_args> to be the arguments to a
C<Fsdb::IO::Writer::new> call, and whatever is in C<$ofref>
(if anything) is written for each input line,
and once at the end.

=head2 Command 3: Fun With Suppressing Output

The C<-n> option suppresses default output.
Thus, a simple equivalent to F<tail -1> is:

    dbroweval -n -e '$ofref = $lfref;'

Where C<$ofref> is the output fields,
which are copied from C<$lfref>, the hereby documented
internal representation of the last row.
Yes, this is a bit unappetizing, but,
in for a penny with C<$ofref>, in for a pound.

=head2 Command 4: Extra Ouptut

Calling C<&$write_fastpath_sub($fref)> will do extra output,
so this simple program will duplicate each line of input
(one extra output, plus one regular output for each line of input):

    dbroweval  '&$write_fastpath_sub($fref)'


=head1 BUGS

Handling of code in files isn't very elegant.


=head1 SEE ALSO

L<Fsdb(3)>


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;

use Fsdb::Support;
use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;

=head2 new

    $filter = new Fsdb::Filter::dbroweval(@arguments);

=cut

sub new {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    $self->set_defaults;
    $self->parse_options(@_);
    $self->SUPER::post_new();
    return $self;
}

=head2 set_defaults

    $filter->set_defaults();

Internal: set up defaults.

=cut

sub set_defaults ($) {
    my($self) = @_;
    $self->SUPER::set_defaults();
    $self->{_beg_code} = [];
    $self->{_end_code} = [];
    $self->{_code_files} = [];
    $self->{_code_lines} = [];
    $self->{_warnings} = undef;
    $self->{_header} = undef;

    $self->{_no_output} = undef;
    $self->{_no_output_even_comments} = undef;
}

=head2 _confirm_ending_semicolon

Not a method; but an internal routine to make sure code compiles.

=cut

sub _confirm_ending_semicolon(@) {
    my($c) = @_;
    $c = $c . ";" if ($c !~ /\;\s*$/);
    return $c;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse options

=cut

sub parse_options ($@) {
    my $self = shift @_;

    $self->get_options(\@_,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'autorun!' => \$self->{_autorun},
	'b|begin=s@' => $self->{_beg_code},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'e|end=s@' => $self->{_end_code},
	'f|code-files=s@' => $self->{_code_files},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'm|manual-output' => \$self->{_manual_output}, 
	'n|no-output' => \$self->{_no_output}, 
	'N|no-output-even-comments' => \$self->{_no_output_even_comments},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'saveoutput=s' => \$self->{_save_output},
        'w|warnings!' => \$self->{_warnings},
	) or pod2usage(2);
    # rest is code
    foreach (@_) {
	push(@{$self->{_code_lines}}, _confirm_ending_semicolon($_));
    };
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    #
    # handle files
    #
    foreach (@{$self->{_code_files}}) {
	open(INF, "<$_") || die $self->{_prog} . ": cannot open ``$_''.\n";
	push(@{$self->{_code_lines}}, _confirm_ending_semicolon(join('', <INF>)));
	close INF;
    };

    #
    # set up reader
    #
    $self->{_out} = undef;
    my @in_options = ();
    if ($self->{_no_output_even_comments}) {
	$self->{_no_output} = 1;
	push(@in_options, -outputheader => 'never');
    };
    push(@in_options, (-comment_handler => $self->create_pass_comments_sub))
	if (!$self->{_no_output_even_comments});
    push(@in_options, -header => $self->{_header}) if (defined($self->{_header}));
    $self->finish_io_option('input', @in_options);
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();

    #
    # convert code to perl
    #
    my($PERL_CODE_F, $DB_CODE_A_F, $TITLE_F, $COMMAND_F) = (0..20); # names for the for parts of our foreach bit next:
    $self->{_pretty_args} = "";
    my($beg_code, $code, $end_code);
    my $c;
    my $any_needs_lfref = undef;
    my $this_needs_lfref;
    foreach my $iref ([\$beg_code, $self->{_beg_code}, "BEGIN CODE:", "-b"],
		    [\$code, $self->{_code_lines}, "CODE:", ""],
		    [\$end_code, $self->{_end_code}, "END_CODE:", "-e"]) {
         next if ($#{$iref->[$DB_CODE_A_F]} < 0);
	 ($c, $this_needs_lfref) = $self->{_in}->codify(@{$iref->[$DB_CODE_A_F]});
	 ${$iref->[$PERL_CODE_F]} = $c;
	 $any_needs_lfref = 1 if ($this_needs_lfref);
	 my($code) = join("\n", @{$iref->[$DB_CODE_A_F]});
	 $any_needs_lfref = 1 if ($code =~ /lfref/);
	 $self->{_pretty_args} .= " $iref->[$COMMAND_F] " .  
			Fsdb::Support::shell_quote("{ " . Fsdb::Support::code_prettify(@{$iref->[$DB_CODE_A_F]}) . " }");
	 print STDERR "$iref->[$TITLE_F]:\n$c\n" if ($self->{_debug});
    };
    exit 1 if ($self->{_debug} == 1);

    #
    # write the loop
    # xxx: should be able to optimize away $lfref
    #
    {
	my $loop_sub;
	my $in_ncols = $#{$self->{_in}->cols} + 1;
	my @out_args = ();
	my $row_output_code = '';
	my $output_end_pre = q'
		$ofref = undef;  # reset for any finishing-up output
	    ';
	my $output_end_post = q'
		&$write_fastpath_sub($ofref) if (defined($ofref));
	    ';
	if ($self->{_manual_output}) {
	    $row_output_code = 'if (defined($ofref)) { &$write_fastpath_sub($ofref); $ofref = undef; };';
	} else {
	    @out_args = (-clone => $self->{_in});
	    $row_output_code = ($self->{_no_output}) ? '' :
		    '&$write_fastpath_sub($fref);';
	};
	my $loop_code =  q'
	    my $selfref = \$self;
	    $loop_sub = sub {
	        ' .
		($self->{_warnings} ? "" : "no strict 'vars';\n") . q'
		my $fref;
		my $lfref;
		my $ofref = undef;
		my $write_fastpath_sub;
		my $in = $self->{_in};
		# begin user BEGIN CODE
	        ' . (defined($beg_code) ? $beg_code : '') . q'
		# end user BEGIN CODE
		${$selfref}->finish_io_option("output", @out_args);
		$write_fastpath_sub = ${$selfref}->{_out}->fastpath_sub();
	        row:   # let users say "next row;"
		while ($fref = &$read_fastpath_sub()) {
		    # begin user MAINLINE CODE
	            ' . (defined($code) ? $code : '') . q'
		    # end user MAINLINE CODE
		    ' . ($any_needs_lfref ? q'
		    $lfref = $fref;  # save for next pass
                    ' : '') . $row_output_code . q'
		};
		' . $output_end_pre . q'
		# begin user END CODE
	        ' . (defined($end_code) ? $end_code : '') . q'
		# end user END CODE
		' . $output_end_post . q'
	    };
        ';
	print "\nLOOP CODE:\n$loop_code\n"
	    if ($self->{_debug} >= 2);
	eval $loop_code;
	$@ && die $self->{_prog} . ":  eval error compiling user-provided code: $@.\n: CODE:\n$loop_code\n";
	$self->{_loop_sub} = $loop_sub;
    };
    $self->{_beg_code_final} = $beg_code;
    $self->{_end_code_final} = $end_code;
    $self->{_code_final} = $code;
}

=head2 run

    $filter->run();

Internal: run over all IO

=cut
sub run ($) {
    my($self) = @_;
    &{$self->{_loop_sub}}();
}


=head2 finish

    $filter->finish();

Internal: write trailer.

=cut
sub finish($) {
    my($self) = @_;
    return if ($self->{_no_output_even_comments});
    $self->SUPER::finish();
}


=head2 compute_program_log

    $log = $filter->figure_program_log();

Override compute_program_log to do pretty-printed arguments.

=cut

sub compute_program_log($) {
    my $self = shift @_;

    my $log = " | " . $self->{_prog} . $self->{_pretty_args};
    return $log;
}



=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2007 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
