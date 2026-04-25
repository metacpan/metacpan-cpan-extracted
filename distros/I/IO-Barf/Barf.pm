package IO::Barf;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Scalar::Util qw(blessed);

# Constants.
Readonly::Array our @EXPORT => qw(barf);

our $VERSION = 0.12;

# Barf content to file.
sub barf {
	my ($file_or_handler, $content) = @_;

	# File.
	my $ref = ref $file_or_handler;
	if (! $ref) {
		open my $ouf, '>', $file_or_handler
			or err "Cannot open file '$file_or_handler'.";
		print {$ouf} $content;
		close $ouf or err "Cannot close file '$file_or_handler'.";

	# Handler
	} elsif ($ref eq 'GLOB') {
		print {$file_or_handler} $content;

	# IO::Handle.
	} elsif (blessed($file_or_handler)
		&& $file_or_handler->isa('IO::Handle')) {

		$file_or_handler->print($content);

	# Other.
	} else {
		err "Unsupported reference '$ref'.";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

IO::Barf - Barfing content to output file.

=head1 SYNOPSIS

 use IO::Barf qw(barf);

 barf($file_or_handler, 'CONTENT');

=head1 SUBROUTINES

=head2 C<barf>

 barf($file_or_handler, 'CONTENT');

Barf content to file or handler.

Returns undef.

=head1 ERRORS

 barf():
         Cannot open file '%s'.
         Cannot close file '%s'.
         Unsupported reference '%s'.

=head1 EXAMPLE1

=for comment filename=barf_content_to_temp_file.pl

 use strict;
 use warnings;

 use File::Temp;
 use IO::Barf;

 # Content.
 my $content = "foo\nbar\n";

 # Temporary file.
 my $temp_file = File::Temp->new->filename;

 # Barf out.
 barf($temp_file, $content);

 # Print tempory file.
 system "cat $temp_file";

 # Unlink temporary file.
 unlink $temp_file;

 # Output:
 # foo
 # bar

=head1 EXAMPLE2

=for comment filename=barf_content_to_stdout.pl

 use strict;
 use warnings;

 use IO::Barf;

 # Content.
 my $content = "foo\nbar\n";

 # Barf out.
 barf(\*STDOUT, $content);

 # Output:
 # foo
 # bar

=head1 EXAMPLE3

=for comment filename=barf_benchmark1.pl

 use strict;
 use warnings;

 use Benchmark qw(cmpthese);
 use IO::All;
 use IO::Any;
 use IO::Barf;
 use File::Raw qw(spew);
 use File::Slurp qw(write_file);
 use File::Temp;
 use Path::Tiny;

 # Temporary files.
 my $temp1 = File::Temp->new->filename;
 my $temp2 = File::Temp->new->filename;
 my $temp3 = File::Temp->new->filename;
 my $temp4 = File::Temp->new->filename;
 my $temp5 = File::Temp->new->filename;
 my $temp6 = File::Temp->new->filename;

 # Some data.
 my $data = 'x' x 1000;

 # Benchmark (10s).
 cmpthese(-10, {
         'File::Raw' => sub {
                 file_spew($temp1, $data);
                 unlink $temp1;
         },
         'File::Slurp' => sub {
                 write_file($temp2, $data);
                 unlink $temp2;
         },
         'IO::All' => sub {
                 $data > io($temp3);
                 unlink $temp3;
         },
         'IO::Any' => sub {
                 IO::Any->spew($temp4, $data);
                 unlink $temp4;
         },
         'IO::Barf' => sub {
                 barf($temp5, $data);
                 unlink $temp5;
         },
         'Path::Tiny' => sub {
                 path($temp6)->spew($data);
                 unlink $temp6;
         },
 });

 # Output like this:
 # X270, Intel(R) Core(TM) i5-6300U CPU @ 2.40GHz
 #                Rate Path::Tiny   IO::All  IO::Any File::Slurp IO::Barf File::Raw
 # Path::Tiny   5707/s         --      -27%     -36%        -71%     -75%      -84%
 # IO::All      7814/s        37%        --     -12%        -60%     -66%      -79%
 # IO::Any      8899/s        56%       14%       --        -54%     -61%      -76%
 # File::Slurp 19521/s       242%      150%     119%          --     -14%      -47%
 # IO::Barf    22735/s       298%      191%     155%         16%       --      -38%
 # File::Raw   36606/s       541%      368%     311%         88%      61%        --

=head1 EXAMPLE4

=for comment filename=barf_benchmark2.pl

 use strict;
 use warnings;

 use Benchmark qw(cmpthese);
 use File::Temp;

 # Temporary files.
 my $temp1 = File::Temp->new->filename;
 my $temp2 = File::Temp->new->filename;
 my $temp3 = File::Temp->new->filename;
 my $temp4 = File::Temp->new->filename;
 my $temp5 = File::Temp->new->filename;

 # Some data.
 my $data = 'x' x 1000;

 # Benchmark (10s).
 cmpthese(-10, {
         'File::Raw' => sub {
                 require File::Raw;
                 File::Raw->import('spew') if ! defined &file_spew;
                 file_spew($temp1, $data);
                 unlink $temp1;
         },
         'File::Slurp' => sub {
                 require File::Slurp;
                 File::Slurp::write_file($temp2, $data);
                 unlink $temp2;
         },
         'IO::Any' => sub {
                 require IO::Any;
                 IO::Any->spew($temp3, $data);
                 unlink $temp3;
         },
         'IO::Barf' => sub {
                 require IO::Barf;
                 IO::Barf::barf($temp4, $data);
                 unlink $temp5;
         },
         'Path::Tiny' => sub {
                 require Path::Tiny;
                 Path::Tiny::path($temp5)->spew($data);
                 unlink $temp5;
         },
 });

 # Output like this:
 # X270, Intel(R) Core(TM) i5-6300U CPU @ 2.40GHz
 #                Rate  Path::Tiny     IO::Any    IO::Barf File::Slurp   File::Raw
 # Path::Tiny   5755/s          --        -37%        -66%        -70%        -84%
 # IO::Any      9204/s         60%          --        -46%        -52%        -74%
 # IO::Barf    16907/s        194%         84%          --        -12%        -53%
 # File::Slurp 19162/s        233%        108%         13%          --        -47%
 # File::Raw   35860/s        523%        290%        112%         87%          --

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<File::Raw>

Fast IO operations using direct system calls

=item L<File::Slurp>

Simple and Efficient Reading/Writing/Modifying of Complete Files

=item L<IO::Any>

open anything

=item L<Perl6::Slurp>

Implements the Perl 6 'slurp' built-in

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/IO-Barf>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2009-2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.12

=cut
