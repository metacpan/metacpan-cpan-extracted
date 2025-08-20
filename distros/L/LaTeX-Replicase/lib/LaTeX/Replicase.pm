package LaTeX::Replicase;

use 5.010;
use strict;
use warnings;
use utf8;

use File::Basename qw(fileparse);
use File::Path qw(make_path);
use File::Compare;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
		replication
	) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.031';
our $DEBUG; $DEBUG = 0 unless defined $DEBUG;
our @logs;


sub replication {
	my( $ifile, $info, %op ) = @_;

	our $DEBUG; $DEBUG = $op{debug} if defined $op{debug};
	$DEBUG += 0;
	our @logs = ();

push @logs, "--> Check '$ifile' file" if $DEBUG;

	unless( -s $ifile ) {
		$_ = "!!! ERROR#1: '$ifile' does NOT exist or is EMPTY!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

	my $data = $info->{data} or do{
			$_= "!!! ERROR#2: EMPTY data!";
			$op{silent} or carp $_;

			push @logs, $_;
			return \@logs;
		};

	my $set = $info->{cases} || undef;

	my( $filename, $dir, $ext ) = fileparse($ifile);

	my $ofile;

	if( $op{ofile} ) {
		$ofile = $op{ofile};
	}
	else {
		my $outdir = $op{outdir} // "$dir/$$"; # Target dir for ready TeX file
		length( $outdir ) or $outdir = "./$$";
		make_path( $outdir ) unless -d $outdir;

		$ofile = "$outdir/$filename";
	}

push @logs, "--> Using '$ofile' file as output" if $DEBUG;

	# new file must be different
	if( -s $ofile
		and (
			( $ifile eq $ofile and compare( $ifile, $ofile ) == 0 )
			or
			( join(',', stat $ifile) eq join(',', stat $ofile) )
		)
	) {
		$_= "!!! ERROR#3: Input (template) & output files match. Can't overwrite template file!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

	my $mode = $op{utf8} ? ':utf8' : '';

push @logs, "--> Open '$ifile'" if $DEBUG;

	open my $TEMPLATE, "<:raw$mode", $ifile or do{
		$_= "!!! ERROR#4: $!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	};

	$mode = $op{utf8} ? ':encoding(utf8)' : '';

push @logs, "--> Open '$ofile'" if $DEBUG;

	open my $fh, ">$mode", $ofile or do{
		$_= "!!! ERROR#5: $!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	};

	my $key;
	my @columns;

=for comment
=begin comment
@columns:
	[...]: -- table columns
	[...]{...} -- descriptions (properties) of table columns:
			{k} -- name (key) of a variable from $data->{ $key }
			{i} -- index of variable from $data->{ $key }
			{case}{...} -- TeX hash of choice cases
			{head}[...] -- TeX preamble (head, title) of all cases
			{tail}[...] -- TeX tail after all cases
=end comment
=cut

	while( <$TEMPLATE> ) {
		my $z = $_;

		if( defined $key ) { # We are in VAR-structure

			next unless /%%%[ACESV]\S*:/; # Nope control tags --> drop TeX

			if(/%%%END:/) {

				&_var_output( $fh, $data->{ $key }, $set->{ $key }, \@columns, \%op );

				# Clear the VAR-structure for the next external variable
				undef $key;
				@columns = ();
				next;
			}
			elsif( ref( $data->{ $key } ) eq 'ARRAY') {

				# Index of column in target table
				my $j = (@columns && ( exists( $columns[-1]{k} ) or exists( $columns[-1]{i} ) )) ?
							@columns :
							($#columns // 0);
				$j = 0 if $j < 0;

				if(/%%%V:\s*([^\s:%#]+)/) {
				# this V-variable is nested in a VAR-structure
					my $ki = $1; # name (key or index) of V-variable

					if( (ref( $data->{ $key }[0] ) eq 'HASH') && exists( $data->{ $key }[0]{$ki} ) ){
						# V-variable is in HASH VAR-structure
						$columns[$j]{k} = $ki; # save variable name in j-th column
					}
					elsif( (ref( $data->{ $key }[0] ) eq 'ARRAY') and $ki =~/^\d+$/) {
						# V-variable is in ARRAY VAR-structure
						$columns[$j]{i} = $ki; # save variable index in the j-th column
					}

				}
				elsif(/(.+?) ?%%%+ADD:/ or /^\s*%%%+ADD: ?(.+?)[\r\n]*$/s) {
					if( @columns && exists( $columns[$j]{case} ) ) {
						push @{ $columns[$j]{tail} }, "$1\n";
					}
					else {
						push @{ $columns[$j]{head} }, "$1\n";
					}
				}
				elsif(/(.+?) ?%%%+CASE(\d+):/) {
					$columns[$j]{case}{$2} .= "$1\n";
				}
				elsif(/^\s*%%%+CASE(\d+): ?(.+)/s) {
					$columns[$j]{case}{$1} .= $2;
				}
				elsif(/(.+?) ?%%%+SKIP:/ or /^\s*%%%+SKIP: ?(.+?)[\r\n]*$/s) {
					if( @columns && exists( $columns[$j]{case} ) ) {
						push @{ $columns[$j]{tail} }, "$1%%%SKIP:\n";
					}
					else {
						push @{ $columns[$j]{head} }, "$1%%%SKIP:\n";
					}
				}

			}
			next;

		}
		elsif(/(.*?) ?%%%+VAR:\s*([^\s:%#]+)/) { # \rule{0mm}{4.5em}%%%VALUE: myTable
			my $k = $2;
			print $fh  $1 if $1; # Output prefix TeX, e.g. \rule{0mm}{4.5em}

			if( exists( $data->{$k} ) && ( ref( \$data->{$k} ) eq 'SCALAR' or ref( $data->{$k} ) eq 'ARRAY') ) {

				if( ! defined( $data->{$k} ) && $op{def} ) {
push @logs, '--> NOT defined %%%VAR:'. $k if $DEBUG;
				}
				else {
					$key = $k; # save key name

push @logs, '--> Found %%%VAR:'. $k if $DEBUG;
				}

				@columns = (); # JIC
			}
			elsif( $DEBUG or ! $op{ignore} ) {
				push @logs, '~~> WARNING#2: Unknown SCALAR or ARRAY %%%VAR:'. $k;
				print $fh $_;
			}
			next;
		}
		elsif(/%%%V:\s*([^\s:%#]+)/) {
			if( exists( $data->{$1} ) && ref( \$data->{$1} ) eq 'SCALAR' ) {

				if( ! defined( $data->{$1} ) && $op{def} ) {
push @logs, '--> NOT defined %%%V:'. $1 if $DEBUG;
				}
				else {
push @logs, '--> Insert %%%V:'.$1.' value: '. $data->{$1} if $DEBUG;

					say $fh $data->{$1};
				}
			}
			elsif( $DEBUG or ! $op{ignore} ) {
				push @logs, '~~> WARNING#3: unknown SCALAR tag = '. $1;
				print $fh $_;
			}

			next;
		}

		print $fh  $z;
	}
	close $TEMPLATE;

	if( defined $key ) {
		&_var_output( $fh, $data->{ $key }, $set->{ $key }, \@columns, \%op );

		$_ = "~~> WARNING#1: Missing '%%%END:' tag for '$key'!";
		$op{silent} or carp $_;
		push @logs, $_;
	}

	close $fh;

	@logs or return;
	return \@logs;
}

#---------------------
# Internal function(s)

sub _var_output {
	my( $fh, $values, $set, $columns, $op ) = @_;
	our $DEBUG;
	our @logs;

	if( ref( \$values ) eq 'SCALAR') {

push @logs, '--> Insert SCALAR %%%VAR value = '. $values if $DEBUG;

		say $fh $values;
		return;
	}

	# $values is 'ARRAY'

	# Forming a table
	my $row = 0;
	foreach my $d ( @$values ) { # loop through table rows

push @logs, '--> Table row = '. $row if $DEBUG;

		my $cases = $set ? $set->{ $row } : undef;

		foreach my $el ( @$columns ) { # loop through table columns (parameters)

			my $ki = $el->{k} // $el->{i} // undef;

			my $val;
			if( defined $ki ) {
				if((ref($d) eq 'HASH') && defined( $d->{$ki} )) {
					$val = $d->{$ki};
				}
				elsif((ref($d) eq 'ARRAY') && defined( $d->[$ki] )) {
					$val = $d->[$ki];
				}
				elsif( $op->{def} ) {
push @logs, "-->\t NOT defined %%%V:". $ki if $DEBUG;

					next;
				}
			}
			else {
			# empty parameter -- at the very end of the columns (parameters)
				$ki = '';
			}

			if( $el->{head} ) {
				for( @{ $el->{head} } ) {

					if(s/%%%SKIP:\s*$/\n/) {
						next if ! $row or $row > $#{ $values };
					}

push @logs, "-->\t Insert head: ". $_ if $DEBUG;
					print $fh  $_;
				}
			}

			if( $cases
				&& defined( $cases->{$ki} )
				&& exists( $el->{case} )
			) {
			# If specified, output conditional TeX strings

				if( ref( \$cases->{$ki} ) eq 'SCALAR') {
					$_ = $cases->{$ki};

					if( defined $el->{case}{$_} ) {
push @logs, "-->\t Insert CASE$_: ". $el->{case}{$_} if $DEBUG;
						print $fh  $el->{case}{$_};
					}

				}
				elsif( ref( $cases->{$ki} ) eq 'ARRAY') {
					for( @{ $cases->{$ki} } ) {

						if( defined $el->{case}{$_} ) {
push @logs, "-->\t Insert CASE$_: ". $el->{case}{$_} if $DEBUG;
							print $fh  $el->{case}{$_};
						}

					}
				}
			}

			if( $el->{tail} ) {
				for( @{ $el->{tail} } ) {

					if(s/%%%SKIP:\s*$/\n/) {
						next if ! $row or ( !length( $ki ) && $row > $#{ $values } );
					}

push @logs, "-->\t Insert tail: ". $_ if $DEBUG;
					print $fh  $_;
				}
			}

			# output the value of the variable
			if( defined $val ) {
push @logs, "-->\t Insert '$ki' value: ". $val if $DEBUG;
				say $fh  $val;
			}

		} # END column

	}
	continue {
		++$row;
	}

}

1;

__END__

=head1 NAME

LaTeX::Replicase - Perl extension implementing a minimalistic engine
for filling real TeX-LaTeX files that act as templates.

=encoding utf8

=head1 SYNOPSIS

Activate the module:

  use LaTeX::Replicase qw( replication );

or

  use LaTeX::Replicase qw(:all);

Usage examples:

=over 3

=item 1.
Using C<replication()> with default options.

The following pseudo-code extract demonstrates this:

=over 6

=item *
Fragment of the original (source) TeX file with fillable fields 
C<myParam>, C<myTable_array>, and C<myTable_hash>:

  SPECIFY VALUE of myParam! %%%V: myParam -- substitutes Variable

  etc...

  \begin{tcolorbox}

  \rule{0mm}{4.5em}%%%VAR: myParam -- substitutes Variable as well
  ...
  ... SPECIFY VALUE of myParam!
  ...
  %%%END:

  \end{tcolorbox}


  \begin{tabular}{ccccc}
   column0 & column1 & column2 & column3 & column4 \\
   \toprule

  %%%VAR: myTable_array
    %%%ADD: %add " \n" at beginning of value in the 0th column without any conditions for all rows
  %%%CASE1: \midrule
  %%%CASE1: ... % continuation of CASE1
  %%%CASE2: ...
  %%%CASE3: ...
   SPECIFY VALUE 0! %%%V:0

   & %%%ADD: %add " &\n" at beginning of value in the 1st column without any conditions for all rows
  %%%CASE1: ...
  %%%CASE2: ...
  SPECIFY VALUE 1! %%%V:1

   & %%%ADD:
  %%%CASE1: ...
  %%%CASE2: ...
  SPECIFY VALUE 2! %%%V:2

   & %%%ADD:
  %%%CASE1: ...
  %%%CASE2: ...
  SPECIFY VALUE 3! %%%V:3

   & %%%ADD:
  SPECIFY VALUE 4! %%%V:4

  \\%%%ADD:
  \midrule%%%ADD:
  %%%CASE5: ...
  ...
  VALUE 0 & VALUE 1 & VALUE 2 & VALUE 3 & VALUE 4 % All of this will be replaced until %%%END:
  \\
  \midrule
  ...
  %%%END:

  \end{tabular}

  ...
  \begin{tabbing}
  %%%VAR: myTable_hash

  %%%SKIP: \\
     SPECIFY VALUE 'A'! %%%V: A

   \= %%%ADD:
     SPECIFY VALUE 'B'! %%%V: B

   \= %%%ADD:
     SPECIFY VALUE 'C'! %%%V: C

   \= %%%ADD:
     SPECIFY VALUE 'D'! %%%V: D

   \= %%%ADD:
     SPECIFY VALUE 'E'! %%%V: E

  %%%END:
  \end{tabbing}


=item *
Data to fill TeX file (see above):

  my $info = {
      data => { # mandatory data section
        myParam => 'Blah-blah blah-blah blah-blah',
        myTable_array => [ # custom user variable ARRAY-ARRAY
          [00, 01, 02, 03, 04,], # row 0
          [10, 11, 12, 13, 14,], # row 1
          [20, 21, 22, 23, 24,], # row 2
          [30, 31, 32, 33, 34,], # row 3
        ],
        myTable_hash => [ # custom user variable ARRAY-HASH
          {A=>00, B=>01, C=>02, D=>03, E=>04,}, # row 0
          {A=>10, B=>11, C=>12, D=>13, E=>14,}, # row 1
          {A=>20, B=>21, C=>22, D=>23, E=>24,}, # row 2
          {A=>30, B=>31, C=>32, D=>33, E=>34,}, # row 3
        ],
      },

      cases => { # optional auxiliary data section
        myTable_array => {
          0 => { # table row 0
            3 => [1, 2], # extract from document %%%CASE1: and %%%CASE2: for 3-rd table column
            #...
          },
          2 => { # table row 2
            0 => [1, 3], # extract %%%CASE1: and %%%CASE3: for 0-th column
            1 => 2, # extract only %%%CASE2: for 1-st column
            #...
            # '' -- empty parameter (without column idx)
            '' => 5, # extract only %%%CASE5: located at the very "tail" of row
          },
        },
        myTable_hash => {
          1 => { # table row 1
            B => 1, # extract %%%CASE1: for 'B' key (1-st position)
            A => [1, 3], # extract %%%CASE1: and %%%CASE3: for 'A' key (0-th position)
            #...
          },
          0 => { # table row 0
            B => 2, # extract %%%CASE2:
            C => [1, 2], # extract %%%CASE1: and %%%CASE2: for 'C' key (2-nd position)
            #...
          },
        },

      },

  };

  my $msg = replication( $file, $info );

=back

A new TeX C<base_file> from the template C<$file> filled with data from C<$info> will be created in
B<random subdirectory> (its name is stored in C<$$> variable) of current directory.
File name of source C<$file> can be absolute,
i.e. with a full path (include directories and subdirectories).
C<base_file> name is extracted (same) from source C<$file>.
Under no circumstances will source C<$file> be overwritten by new C<base_file>.

=item 2.
Using C<outdir> option:

  my $msg = replication( $file, $info, outdir => $target_dir );

A new C<$file> will be created in C<$target_dir> directory.

=item 3.
Using C<ofile> option:

  my $msg = replication( $file, $info, ofile => $ofile );

A new C<$ofile> will be created.
C<ofile> option suppresses (eliminates) C<outdir> option, i.e.
file name of C<$ofile> can be absolute.
Under no circumstances will source C<$file> be overwritten by new C<$ofile>.

=item 4.
Set the C<$DEBUG> package variable to enable debugging messages (global debug mode):

    $LaTeX::Replicase::DEBUG = 1;

=back

=head1 LIMITATIONS

This module have reason only for perl 5.10 and higher.

=head1 ABSTRACT

Replicase is minimalistic (ascetic) interpreter (uses only 6 control tags)
which can be used for processing (filling) real TeX-LaTeX files that act as templates.

=head1 DESCRIPTION

This module is a Perl 5 extension implementing Replicase subroutines which processes TeX-LaTeX files, 
interpreting and executing built-in control directives (tags) of Replicase.

Replicase can: define and substitute variable values, execute conditional actions and capture 
the resulting output into a new document.
Replicase was originally designed for creating programmatically configurable TeX-LaTeX documents.

Unlike other template engines, here the logic and cycles are completely separated from TeX-LaTeX document
and are moved to your Perl program using this module. It's well suited for this and similar tasks,
allowing you to dynamically create PDF documents that are consistent with each other, yet easily customisable.

Replicase is a standalones, safe as a TeX-LaTeX, and fast template engine with remarkable features.
All markup is based on following "three pillars" (directives, tags):

=over 3

=item *
B< C<%%%V: variable_name> > is a short form of a regular (SCALAR) I<variable_name>
that completely replaces the string in which it is located, e.g.

  Blah, blah, \ldots blah. %%%V: myParam

will be completely replaced by contents of C<myParam> variable.

It can be nested in an ARRAY or HASH C<%%%VAR:> tag,
but in SCALAR C<%%%VAR:> it will not work and will be discarded.

=item *
B< C<%%%VAR: variable_name> > is start of full form of regular (SCALAR) or complex (ARRAY, HASH) I<variable_name>,
preserving preceding TeX up to %%%VAR: but completely replacing everything up to first C<%%%END:> tag inclusive.

  Blah, blah, \ldots blah. %%%VAR: myParam
  Blah, blah, \ldots
  \ldots

  Blah, \ldots %%%END:

Usually ARRAY and HASH I<variable_name> are used in the template to create (fill) tables.

CONCLUSION: Nested C<%%%VAR:> tags will not work and will be discarded.

=item *
B< C<%%%END:> > is used to specify the end of C<%%%VAR:> tag.
Text located in line with C<%%%END:> will be discarded.

BTW: If this tag is omitted, all text to the end of document will be replaced 
by C<variable_name> specified in C<%%%VAR:> tag.

=back

The following tags can be located within the block limited by ARRAY and HASH C<%%%VAR:> and C<%%%END:> tags:

=over 3

=item *
B< C<%%%V: key|index> > with setting of C<key> (in case of HASH C<%%%VAR:>, i.e. C<%%%V: keyA>, C<%%%V:keyB>, etc.)
or C<index> (in case ARRAY C<%%%VAR:>, i.e. C<%%%V:0>, C<%%%V:1>, C<%%%V:2>, etc.).
Here C<keys> or C<indexes> are columns (or positions) of the table (filled area) being created.


=item *
B< C<%%%ADD:> > without any conditions adds text 
B<before> (or B<after>) all C<%%%CASE:> tags (if exists)
and B<before> variable specified in C<%%%V:> tag.
The added text is taken from the beginning of the line to the beginning of C<%%%ADD:>
(i.e. text located on the left), e.g.

  Head blah, blah, \ldots blah. %%%ADD: Tail blah, blah, \ldots

this text will be added: C<Head blah, blah, \ldots blah.>

Or, if C<%%%ADD:> is located at the very beginning of line, then after it to the end of line
(i.e. text located on the right), e.g.

  %%%ADD: Tail blah, blah, \ldots

this text will be added: C<Tail blah, blah, \ldots>.

If the following C<%%%V:> tag is not present, then the text is output B<at the end of all> C<keys> or C<indexes> (columns)
each table row, B<before (or after)> text-blocks of all C<%%%CASE:> tags (if exists).

=item *
B< C<%%%SKIP:> > similar to C<%%%ADD:> for all lines (records)
B<except the first column of first record> or B<after the last column of last record> (if exists).


=item *
B< C<%%%CASE0:>, C<%%%CASE1:>, ... C<%%%CASE[\d+]:> > conditionally adds text before variable specified in C<%%%V:> tag.
This tag is triggered if its C<[\d+]> index is specified for the corresponding row(s) in additional settings C<cases> hash.

Similar to C<%%%ADD:>, here the added text is taken from the beginning of the line 
to the beginning of C<%%%CASE[\d+]:> (i.e. text located on the left) or,
if C<%%%CASE[\d+]:> is located at the very beginning of line, then after it 
to the end of line (i.e. text located on the right).

There can be as many C<%%%CASE[\d+]:> tags as you like. 

If C<%%%CASE[\d+]:> tags within the same C<%%%V:> have the same C<[\d+]> index, their texts are merged.

C<%%%CASE[\d+]:> tags are only valid when following C<%%%V:> tag exists and is defined in the input C<data>.

If there is no following C<%%%V:> tag, text is output at the end of all C<keys> or C<indexes> (columns)
each table row. In the additional settings C<cases> hash these C<%%%CASE[\d+]:> must correspond 
to key with a name of zero length, i.e ''.

=back

Only B<ONE tag> can be located on B<ONE line> of input C<$file> (document).


Tag names must be in C<%%%UPPERCASE:>.


=head1 SUBROUTINES

LaTeX::Replicase provides this subroutine:

    replication( $file, $info [, %facultative_options ] );


=head2 replication( $file, $info [, %facultative_options ] )

Creates a new output file from the specified TeX C<$file>, which is a template.
C<$info> hash is used to fill template.

File name of source C<$file> can be absolute,
i.e. with a full path (include directories and subdirectories).

The output file name is extracted (the same) from the source C<$file>.
Under no circumstances will source C<$file> be overwritten by the new one.

When C<replication> processes a C<$file> it identifies tags and replaces them with the result of whatever 
the tag represents (e.g. variable value for  %%%V: or from %%%VAR: to %%%END:). Anything outside the tag(s),
including newline characters, are left intact.

The following C<%facultative_options> can be used when calling C<replication>:

=over 3

=item C<outdir>:

  my $msg = replication( $file, $info, outdir => $target_dir );

A new C<$file> will be created in C<$target_dir> directory.

=item C<ofile>:

  my $msg = replication( $file, $info, ofile => $ofile );

A new C<$ofile> will be created.
C<ofile> option suppresses (eliminates) C<outdir> option, i.e.
file name of C<$ofile> can be absolute.

=item C<utf8>

This option specifies the template and output files' character encoding as utf8:

  my $msg = replication( $file, $info, utf8 =>1 );

=item C<def>

This option specifies B<discarding> (ignoring) C<undefined> values and associated structures (C<%%%CASEn:> and C<%%%ADD:>),
i.e. B<take into account> only C<defined> values.

  my $msg = replication( $file, $info, def =>1 );

This option is useful, for example, for creating merged cells in tables (using C<\multicolumn> LaTeX-command).
This option applies to all incoming data.

=item C<ignore> 

This option specifies silently ignore undefined B<name|key|index> of C<%%%V:> and C<%%%VAR:> tags:

  my $msg = replication( $file, $info, ignore =>1 );

=item C<silent>
silent mode of operation:

  my $msg = replication( $file, $info, silent =>1 );

=item C<debug>

This option sets local debug mode:

  my $msg = replication( $file, $info, debug =>1 );
  if( ! $msg ) {
    say 'Ok';
  }
  else {
    say for @$msg;
  }

Another way is to set the C<$DEBUG> package variable to enable debugging messages (global debug mode).

    $LaTeX::Replicase::DEBUG = 1;

=back

C<replication> returns C<undef> or a reference to an error (and/or debug) message(s) array.

=head1 EXPORT

LaTeX::Replicase exports nothing by default.
Each of the subroutines can be exported on demand, as in

  use LaTeX::Replicase qw( replication );

and the tag C<all> exports them all:

  use LaTeX::Replicase qw( :all );


=head1 DEPENDENCIES

LaTeX::Replicase is known to run under perl 5.10.0 on Linux.
The distribution uses L<File::Basename>,
L<File::Path>,
and L<Carp>.

=head1 SEE ALSO

Perl modules that offer similar functionality:

L<Template::Latex>, L<LaTeX::Easy::Templates>


=head1 AUTHOR

Alessandro N. Gorohovski, E<lt>an.gorohovski@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Alessandro N. Gorohovski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

