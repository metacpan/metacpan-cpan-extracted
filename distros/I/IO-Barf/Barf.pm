package IO::Barf;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Scalar::Util qw(blessed);

# Constants.
Readonly::Array our @EXPORT => qw(barf);

our $VERSION = 0.10;

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

 use strict;
 use warnings;

 use Benchmark qw(cmpthese);
 use IO::All;
 use IO::Any;
 use IO::Barf;
 use File::Slurp qw(write_file);
 use File::Temp;
 use Path::Tiny;

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
         'File::Slurp' => sub {
                 write_file($temp3, $data);
                 unlink $temp3;
         },
         'IO::All' => sub {
                 $data > io($temp4);
                 unlink $temp4;
         },
         'IO::Any' => sub {
                 IO::Any->spew($temp2, $data);
                 unlink $temp2;
         },
         'IO::Barf' => sub {
                 barf($temp1, $data);
                 unlink $temp1;
         },
         'Path::Tiny' => sub {
                 path($temp5)->spew($data);
                 unlink $temp5;
         },
 });

 # Output like this:
 #                Rate  Path::Tiny     IO::Any     IO::All File::Slurp    IO::Barf
 # Path::Tiny   3210/s          --        -17%        -51%        -85%        -91%
 # IO::Any      3859/s         20%          --        -41%        -82%        -89%
 # IO::All      6574/s        105%         70%          --        -70%        -81%
 # File::Slurp 21615/s        573%        460%        229%          --        -39%
 # IO::Barf    35321/s       1000%        815%        437%         63%          --

=head1 EXAMPLE4

 use strict;
 use warnings;

 use Benchmark qw(cmpthese);
 use File::Temp;

 # Temporary files.
 my $temp1 = File::Temp->new->filename;
 my $temp2 = File::Temp->new->filename;
 my $temp3 = File::Temp->new->filename;
 my $temp4 = File::Temp->new->filename;

 # Some data.
 my $data = 'x' x 1000;

 # Benchmark (10s).
 cmpthese(-10, {
         'File::Slurp' => sub {
                 require File::Slurp;
                 File::Slurp::write_file($temp1, $data);
                 unlink $temp1;
         },
         'IO::Any' => sub {
                 require IO::Any;
                 IO::Any->spew($temp2, $data);
                 unlink $temp2;
         },
         'IO::Barf' => sub {
                 require IO::Barf;
                 IO::Barf::barf($temp3, $data);
                 unlink $temp3;
         },
         'Path::Tiny' => sub {
                 require Path::Tiny;
                 Path::Tiny::path($temp4)->spew($data);
                 unlink $temp4;
         },
 });

 # Output like this:
 # T460s, Intel(R) Core(TM) i7-6600U CPU @ 2.60GHz
 #                Rate     IO::Any  Path::Tiny File::Slurp    IO::Barf
 # IO::Any      8692/s          --        -20%        -65%        -77%
 # Path::Tiny  10926/s         26%          --        -56%        -71%
 # File::Slurp 24669/s        184%        126%          --        -34%
 # IO::Barf    37193/s        328%        240%         51%          --

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<IO::Any>

open anything

=item L<File::Slurp>

Simple and Efficient Reading/Writing/Modifying of Complete Files

=item L<Perl6::Slurp>

Implements the Perl 6 'slurp' built-in

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/IO-Barf>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2009-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.10

=cut
