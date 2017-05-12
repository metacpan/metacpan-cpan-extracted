package List::RewriteElements;
#$Id: RewriteElements.pm 1123 2007-01-23 03:39:35Z jimk $
$VERSION = 0.09;
use strict;
use warnings;
use Carp;
use Cwd;
use File::Basename;
use File::Copy;
use File::Spec;
use Tie::File;

sub new {
    my ($class, $argsref) = @_;
    croak "Hash ref passed to constructor must contain 'body_rule' element"
        unless defined $argsref->{body_rule};
    croak "'body_rule' element value must be a code ref"
        unless ref($argsref->{body_rule}) eq 'CODE';
    croak "Hash ref passed to constructor must have either a 'file' element or a 'list' element"
        unless (defined $argsref->{file} or defined $argsref->{list});
    croak "'file' element passed to constructor not located"
        if (defined $argsref->{file} and not -f $argsref->{file});
    croak "'list' element passed to constructor must be array ref"
        if  ( defined $argsref->{list} and
            (
                (not ref($argsref->{list})) or
                (ref($argsref->{list}) ne 'ARRAY')
            )
        );
    croak "'body_suppress' element passed to constructor must be code ref"
        if  ( defined $argsref->{body_suppress} and
            (
                (not ref($argsref->{body_suppress})) or
                (ref($argsref->{body_suppress}) ne 'CODE')
            )
        );
    croak "'header_rule' element passed to constructor must be code ref"
        if  ( defined $argsref->{header_rule} and
            (
                (not ref($argsref->{header_rule})) or
                (ref($argsref->{header_rule}) ne 'CODE')
            )
        );
    croak "If 'header_suppress' criterion is supplied, a 'header_rule' element must be supplied as well"
        if  ( defined $argsref->{header_suppress} and
            ! defined $argsref->{header_rule}
        );
    croak "'header_suppress' element passed to constructor must be code ref"
        if  ( defined $argsref->{header_suppress} and
            (
                (not ref($argsref->{header_suppress})) or
                (ref($argsref->{header_suppress}) ne 'CODE')
            )
        );

    if ($argsref->{file}) {
        my @elements;
        tie @elements, 'Tie::File', $argsref->{file}, recsep => $/
            or croak "Unable to tie to $argsref->{file}";
        $argsref->{working} = \@elements;
    } else {
        $argsref->{working} = $argsref->{list};
    }

    my $self = bless ($argsref, $class);

    $self->{rows_in} = scalar(@{$self->{working}});
    if (defined $self->{header_rule}) {
        $self->{records_in} = $self->{rows_in} - 1;
    } else {
        $self->{records_in} = $self->{rows_in};
    }
    # Next attributes are initialized to empty strings because their value
    # is not fixed until after generate_output() has been called.
    $self->{output_path} = q{};
    $self->{output_basename} = q{};
    # Next attributes are initialized to zero because their value
    # is not fixed until after generate_output() has been called.
    $self->{rows_out} = 0;
    $self->{records_out} = 0;
    $self->{records_changed} = 0;
    $self->{records_unchanged} = 0;
    $self->{records_deleted} = 0;
    return $self;
}

sub generate_output {
    my $self = shift;
    if  ( !                 # print to STDOUT 
          ( 
            defined $self->{output_file}   or
            defined $self->{output_suffix}
          )
        ) {
        $self->_handler_control();
    } else {                # print to file
        my $outfile;
        if (defined $self->{output_file}) {
            $outfile = $self->{output_file};
        } else {
            $outfile = File::Spec->catfile( ( cwd() ),
                basename($self->{file}) . $self->{output_suffix} );
        }
        open my $OUT, ">$outfile"
            or croak "Unable to open $outfile for writing";
        my $oldfh = select($OUT);
        $self->_handler_control();
        close $OUT 
            or croak "Unable to close $outfile after writing";
        select $oldfh;
        $self->{output_path} = $outfile;
        $self->{output_basename} = basename($self->{output_path});
    }
    $self->{records_out} = $self->{records_in} - $self->{records_deleted};
    $self->{records_unchanged} = 
        $self->{records_out} - $self->{records_changed};
     if (! defined $self->{header_rule}) {
        $self->{rows_out} = $self->{records_out};
    } else {
        if ($self->{header_status} != -1) {
            $self->{rows_out} = $self->{records_out} + 1;
        } else {
            $self->{rows_out} = $self->{records_out};
        }
    }
}

sub _handler_control {
    my $self = shift;
     if (! defined $self->{header_rule}) {
        $self->_body_rule_handler();
    } else {
        $self->_header_body_rule_handler();
    }
}

sub _body_rule_handler {
    my $self = shift;
    RECORD:  foreach my $el (@{$self->{working}}) {
        chomp $el;
        if (defined $self->{body_suppress}) {
            unless (defined (&{$self->{body_suppress}}($el))) {
                $self->{records_deleted}++;
                next RECORD;
            }
        }
        my $newel = &{$self->{body_rule}}($el);
        print "$newel\n";
        $self->{records_changed}++ if $el ne $newel;
    }
}

sub _header_body_rule_handler {
    my $self = shift;
    $self->{header_status} = 0; # header present, as yet unchanged
    my $header = shift(@{$self->{working}});
    chomp $header;
    if (defined $self->{header_suppress}) {
        if (defined (&{$self->{header_suppress}}($header))) {
            my $newheader = &{$self->{header_rule}}($header);
            print "$newheader\n";
            $self->{header_status} = 1 if $header ne $newheader;
            # header changed
        } else {
            $self->{header_status} = -1;  # header suppressed
        }
    } else {
        my $newheader = &{$self->{header_rule}}($header);
        print "$newheader\n";
        $self->{header_status} = 1 if $header ne $newheader;
        # header changed
    }
    $self->_body_rule_handler();
}

sub get_output_path {
    my $self = shift;
    return $self->{output_path};
}

sub get_output_basename {
    my $self = shift;
    return $self->{output_basename};
}

sub get_total_rows {
    my $self = shift;
    return $self->{rows_out};
}

sub get_total_records {
    my $self = shift;
    return $self->{records_out};
}

sub get_records_changed {
    my $self = shift;
    return $self->{records_changed};
}

sub get_records_unchanged {
    my $self = shift;
    return $self->{records_unchanged};
}

sub get_records_deleted {
    my $self = shift;
    return $self->{records_deleted};
}

sub get_header_status {
    my $self = shift;
    return $self->{header_status};
}

1;


#################### DOCUMENTATION ###################

=head1 NAME

List::RewriteElements - Create a new list by rewriting elements of a first list

=head1 SYNOPSIS

   use List::RewriteElements;

=head2 Constructor

Simplest case:  Input from array, output to STDOUT.

    $lre = List::RewriteElements->new( {
        list        => \@source,
        body_rule   => sub {
                            my $record = shift;
                            $record .= q{additional field};
                       },
    } );

Input from file, output to STDOUT:

    $lre = List::RewriteElements->new( {
        file        => "/path/to/source/file",
        body_rule   => sub {
                            my $record = shift;
                            $record .= q{,additional field};
                       },
    } );

Provide a different rule for the first element in the list:

    $lre = List::RewriteElements->new( {
        file        => "/path/to/source/file",
        header_rule => sub {
                            my $record = shift;
                            $record .= q{,ADDITIONAL HEADER};
                       },
        body_rule   => sub {
                            my $record = shift;
                            $record .= q{,additional field};
                       },
    } );

Input from file, output to file:

    $lre = List::RewriteElements->new( {
        file        => "/path/to/source/file",
        body_rule   => sub {
                            my $record = shift;
                            $record .= q{additional field};
                       },
        output_file => "/path/to/output/file",
    } );

To name output file, just provide a suffix to filename:

    $lre = List::RewriteElements->new( {
        file            => "/path/to/source/file",
        body_rule       => sub {
                            my $record = shift;
                            $record .= q{additional field};
                           },
        output_suffix   => '.out',
    } );

Provide criteria to suppress output of header or individual record.

    $lre = List::RewriteElements->new( {
        file            => "/path/to/source/file",
        header_suppress => sub {
                            my $record = shift;
                            return if $record =~ /$somepattern/;
                        },
        body_suppress   => sub {
                            my $record = shift;
                            return if $record ne 'somestring';
                        },
        body_rule       => sub {
                            my $record = shift;
                            $record .= q{additional field};
                        },
    } );

=head2 Generate Output

    $lre->generate_output();

=head2 Report Output Information

    $path_to_output_file    = $lre->get_output_path();

    $output_file_basename   = $lre->get_output_basename();

    $output_row_count       = $lre->get_total_rows();

    $output_record_count    = $lre->get_total_records();

    $records_changed        = $lre->get_records_changed();

    $records_unchanged      = $lre->get_records_unchanged();

    $records_deleted        = $lre->get_records_deleted();

    $header_status          = $lre->get_header_status();

=head1 DESCRIPTION

It is common in many situations for you to receive a flat data file from someone
else and have to generate a new file in which each row or record in the
incoming file must either (a) be transformed according to some rule before 
being printing to the new file; or (b) if it meets certain criteria, not output to the new file at all.

List::RewriteElements enables you to write such rules and criteria, generate
the file of transformed data records, and get back some basic statistics about
the transformation.

List::RewriteElements is useful when the number of records in the incoming
file may be large and you do not want to hold the entire list in memory.
Similarly, the newly generated records are not held in memory but are
immediately C<print>ed to STDOUT or to file.

On the other hand, if for some reason you already have an array of records in
memory, you can use List::RewriteElements to apply rules and criteria to each
element of the array and then print the transformed records (again, without
holding the output in memory).

=head1 SUBROUTINES

=head2 C<new()>

B<Purpose:>  List::RewriteElements constructor.

B<Arguments:>  Reference to a hash holding the following keys:

=over 4

=item * C<file> or C<list>

The hash must hold either a C<file> element or a C<list> element -- but not
both!  The value for the C<file> key must be an absolute path to an input
file.  The value for C<list> must be a reference to an array in memory.

=item * C<body_rule>

The hash must have a C<body_rule> element whose value is a reference to a
subroutine providing a formula for the transformation of an individual record
in the incoming file to a record in the outgoing file.  The first argument
passed to this subroutine must be the record from the incoming file.  The
return value from this subroutine should be a string immediately ready for
printing to the output file (though the string should not end in a newline, as
printing will be handled by C<generate_output()>).

=item * C<body_suppress>

Optionally, you may provide a C<body_suppress> element whose value is a
reference to a subroutine providing a criterion according to which an
individual record in the incoming file should be output to the outgoing file
or not output, I<i.e.>, omitted from the output entirely.  The first argument 
to this subroutine should be the record from the incoming file.  The 
subroutine should, at least implicitly, return a true value when the record 
I<should> be output.  The subroutine should simply C<return>, <i.e.>, 
return an implicit C<undef>, when the record should be omitted from the 
outgoing file.

=item * C<header_rule>

Frequently the first row in a flat data file is a header row containing, say,
the names of the columns in a data table, joined by a delimiter.  Because the
header row is different from all subsequent rows, you may optionally provide a
C<header_rule> element whose value is a reference to a
subroutine providing a formula for the transformation of the header row 
in the incoming file to the header in the outgoing file.  The first argument
passed to this subroutine must be the header row from the incoming file.  The
return value from this subroutine should be a string immediately ready for
printing to the output file (though the string should not end in a newline, as
printing will be handled by C<generate_output()>).

=item * C<header_suppress>

Optionally, if you have provided a C<header_rule> element, you may provide 
a C<header_suppress> element whose value is a
reference to a subroutine providing a criterion according to which an
the header row from the incoming file should be output to the outgoing file
or not output, I<i.e.>, omitted from the output entirely.  The first argument 
to this subroutine should be the header from the incoming file.  The 
subroutine should, at least implicitly, return a true value when the header 
I<should> be output.  The subroutine should simply C<return>, <i.e.>, 
return an implicit C<undef>, when the header should be omitted from the 
outgoing file.

=item * C<output_file> or C<output_suffix>

It is recommended that you supply either an C<output_file> or an
C<output_suffix> element to the constructor; otherwise, the new list generated
by application of the rules and criteria will simply C<print> to C<STDOUT>.
The value of an C<output_file> element should be a full path to the newly
created file.  If you wish to create a new file name without specifying a full
path but simply by tacking on a suffix to the name of the incoming file,
provide an C<output_suffix> element and the outgoing file will be created in
the directory which is the I<current working directory> as of the point where
C<generate_output()> is called.  An C<output_suffix> element will
be ignored if an C<output_file> element is provided.

=item * Note 1

If neither a C<header_rule> or C<header_suppress> element is provide to the
constructor, List::RewriteElements will treat the first row of the incoming
file the same as any other row, C<i.e.>, it will apply the C<body_rule>
transformation formula.

=item * Note 2

A C<body_suppress> or C<header_suppress> criterion, if present, will be 
logically applied I<before> any C<body_rule> or C<header_rule> formula.  We
don't apply the formula to transform a record if the record should not be
output at all.

=item * Note 3

=back

B<Return Value:>  List::RewriteElements object.

=head2 C<generate_output()>

B<Purpose:>  Generates the output specified by arguments to C<new()>, 
I<i.e.>, creates an output file or C<print>s to C<STDOUT> with records 
transformed as per those arguments.

B<Arguments:>  None. 

B<Return Value:>  Returns true value upon success.  In case of failure it will
C<croak> with some error message.

=head2 C<get_output_path()>

B<Purpose:>  Get the full path to the newly created output file. 

B<Arguments:>  None. 

B<Return Value:>  String holding path to newly created output file. 

B<Comment:>  Since use of the C<output_suffix> attribute means that the full
path to the output file will not be known until C<generate_output()> has been
called, C<get_output_path()> will only give a meaningful result once
C<generate_output()> has been called.  Otherwise, it will default to an empty
string.

=head2 C<get_output_basename()>

B<Purpose:>  Get only the basename of the newly created output file.

B<Arguments:>  None.

B<Return Value:>  String holding basename of newly created output file.

B<Comment:>  Since use of the C<output_suffix> attribute means that the full
path to the output file will not be known until C<generate_output()> has been
called, C<get_output_basename()> will only give a meaningful result once
C<generate_output()> has been called.  Otherwise, it will default to an empty
string.

=head2 C<get_total_rows()>

B<Purpose:>  Get the total number of rows in the newly created output file.
This will include any header row.

B<Arguments:>  None.

B<Return Value:>  Nonnegative integer.

=head2 C<get_total_records()>

B<Purpose:>  Get the total number of data records in the newly created output
file.  If a header row is present in that file, C<get_total_records()> will
return a value C<1> less than that returned by C<get_total_rows()>.

B<Arguments:>  None. 

B<Return Value:>  Nonnegative integer. 

=head2 C<get_records_changed()>

B<Purpose:>  Get the number of data records in the newly created output file
that are altered versions of records in the incoming file.  This value does
not include changes in the header row.

B<Arguments:>  None.

B<Return Value:>  Nonnegative integer. 

=head2 C<get_records_unchanged()>

B<Purpose:>  Get the number of data records in the newly created output file
that are unaltered versions of records in the incoming file.  This value does
not include changes in the header row.

B<Arguments:>  None.

B<Return Value:>  Nonnegative integer.

=head2 C<get_records_deleted()>

B<Purpose:>  Get the number of data records in the original source (file or
list) that were omitted from the newly created output file due to application
of a C<body_suppress> criterion.  This value does not include any suppression
of a header row following application of a C<header_suppress> criterion.

B<Arguments:>  None.

B<Return Value:>  Nonnegative integer.

=head2 C<get_header_status()>

B<Purpose:>  Indicate whether any header row in the original source (file or
list)

=over 4

=item *

was rewritten in the newly created output file:  return value C<1>;

=item *

was transferred to the newly created output file without alteration:  return
value C<0>;

=item *

was suppressed from appearing in the output file by application of a
C<header_suppress> criterion:  return value C<-1>;

=item *

no header row in the source:  return value C<undef>.

=back

B<Arguments:>  None.

B<Return Value:>  Numerical flag:  C<1>, C<0>, C<-1> or C<undef> as described
above.

=head1 FAQ

=head2  Can I simultaneously rewrite records and interact with the external environment?

Yes.  If a C<header_rule>, C<body_rule>, C<header_suppress> or C<body_suppress>
either (a) needs additional information from the external environment above
and beyond that contained in the individual data record or (b) needs to cause
a change in the external environment, you can write a closure and call that 
closure insider the rule.

Example:

    my @greeks = qw( alpha beta gamma );
    
    my $get_a_greek = sub {
        return (shift @greeks);
    };

    my $lre  = List::RewriteElements->new ( {
        list        => [ map {"$_\n"} (1..5) ],
        body_rule   => sub {
            my $record = shift;
            my $rv;
            chomp $record;
            if ($record eq '4') {
                $rv = &{$get_a_greek};
            } else {
                $rv = (10 * $record);
            }
            return $rv;
        },
        body_suppress   => sub {
            my $record = shift;
            chomp $record;
            return if $record eq '5';
        },
    } );

    $lre->generate_output();

This will produce:

    10
    20
    30
    alpha

=head2 Can I use List-Rewrite Elements with fixed-width data?

Yes.  Suppose that you have this fixed-width data (adapted from Dave Cross'
I<Data Munging with Perl>):

    my @dataset = (
        q{00374Bloggs & Co       19991105100103+00015000},
        q{00375Smith Brothers    19991106001234-00004999},
        q{00376Camel Inc         19991107289736+00002999},
        q{00377Generic Code      19991108056789-00003999},
    );

Suppose further that you need to update certain records and that C<%revisions>
holds the data for updating:

    my %revisions = (
        376 => [ 'Camel Inc', 20061107, 388293, '+', 4999 ],
        377 => [ 'Generic Code', 20061108, 99821, '-',  6999 ],
    );

Write a C<body_rule> subroutine which uses C<unpack>, C<pack> and C<sprintf>
as needed to update the records.

    my $lre  = List::RewriteElements->new ( {
        list        => \@dataset,
        body_rule   => sub {
            my $record = shift;
            my $template = 'A5A18A8A6AA8';
            my @rec  = unpack($template, $record);
            $rec[0] =~ s/^0+//;
            my ($acctno, %values, $result);
            $acctno = $rec[0];
            $values{$acctno} = [ @rec[1..$#rec] ];
            if ($revisions{$acctno}) {
                $values{$acctno} = $revisions{$acctno};
            }
            $result = sprintf  "%05d%-18s%8d%06d%1s%08d",
                ($acctno, @{$values{$acctno}});
            return $result;
        },
    } );

=head2 How does this differ from Tie::File?

Mark Jason Dominus' Tie::File module is one of my Fave 5 CPAN modules.  It's
excellent for modifying a file in place.  But I frequently have to leave the
source file unmodified and create a new file, which implies, at the very
least, opening, printing to, and closing filehandles in addition to using 
Tie::File.  List::RewriteElements hides all
that.  It also provides the statistical report methods.

=head2 Couldn't I do this with C<map> and C<grep>?

Quite possibly.  But if your rules and criteria were complicated or long, the
content of the C<map> and C<grep> C<{}> blocks would be hard to read.  You
also wouldn't get the statistical report methods.

=head2 How Does It Work?

Why do you care?  Why do you want to look inside the black box?  If you really
want to know, read the source!

=head1 PREREQUISITES

List::RewriteElements relies only on modules distributed with the Perl core as
of 5.8.0.  IO::Capture::Stdout is required for the test suite, but a copy is
included in the distribution under the F<t/> directory.

=head1 BUGS

None known at this time.  File bug reports at L<http://rt.cpan.org>.

=head1 HISTORY

0.09 Mon Jan 22 22:35:56 EST 2007
    - Update version number and release date only.  Purpose:  generate new
round of tests by cpan testers, in the hope that it eliminates a FAIL report
on v0.08 where failure was due solely to error on tester's box.

0.08 Mon Jan  1 08:54:01 EST 2007
    - xdg to the rescue!  Applied and extended patches supplied by David
Golden for Win32.  In constructor, value of C<$/> is supplied to the C<recsep>
option.

0.07 Sun Dec 31 11:13:04 EST 2006
    - Switched to using File::Spec::catfile() to generate one path (rather
than Cwd::realpath().  This was done in an attempt to respond to corion's FAIL
reports (but I don't have a good Windows box, so I can't be certain of the
results).

0.06 Sat Dec 16 11:31:38 EST 2006
    - Created t/07_fixed_width.t and t/testlib/fixed.t to illustrate use of 
List::RewriteElements with fixed-width data.

0.05 Thu Dec 14 07:42:24 EST 2006
    - Correction of POD formatting errors only; no change in functionality.
CPAN upload.

0.04 Wed Dec 13 23:04:33 EST 2006
    - More tests; fine-tuning of code and documentation.  First CPAN upload.

0.03 Tue Dec 12 22:13:00 EST 2006
    - Implementation of statistical methods; more tests.

0.02 Mon Dec 11 19:38:26 EST 2006
    - Added tests to demonstrate use of closures to supply additional
information to elements such as body_rule.

0.01 Sat Dec  9 22:29:51 2006
    - original version; created by ExtUtils::ModuleMaker 0.47

=head1 ACKNOWLEDGEMENTS

Thanks to David Landgren for raising the question of use of
List-RewriteElements with fixed-width data.

I then adapted an example from Dave Cross' I<Data Munging with Perl>,
Chapter 7.1, "Fixed-width Data," to provide a test
demonstrating processing of fixed-width data.

=head1 AUTHOR

James E Keenan.  CPAN ID: JKEENAN.  jkeenan@cpan.org. 
http://search.cpan.org/~jkeenan/ or
http://thenceforward.net/perl/modules/List-RewriteElements.

=head1 COPYRIGHT

Copyright 2006 James E Keenan (USA).

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

David Cross, I<Data Munging with Perl> (Manning, 2001).

=cut


