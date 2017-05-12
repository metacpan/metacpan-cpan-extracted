package Gnuplot::Simple;
$Gnuplot::Simple::VERSION = '0.013';
use v5.14;
use strictures 2;
use Method::Signatures;
use Types::Standard qw(ArrayRef Str);
use Text::CSV;
use File::Slurper qw(read_text write_text);
use Exporter::Tidy all => [qw(exec_commands write_data)];
use File::Temp qw(tempfile);
use Carp::Assert;

BEGIN {
    system("which gnuplot > /dev/null") == 0 || die 'Gnuplot was not found from $PATH using which.';
}

#ABSTRACT   Gnuplot::Simple - A simple way to control Gnuplot

=head1 NAME

Gnuplot::Simple - A simple way to control Gnuplot

=head1 SYNOPSIS

Gnuplot can be controlled from Perl using a pipe. This modules faciliates the process
to allow more convenient graph plotting from perl e.g.

  use Gnuplot::Simple qw(write_data);

  write_data("file.txt", [[ 1,2 ],[ 2,3 ]] );

For obvious reasons, gnuplot needs to be installed for this module to work. The presence
of gnuplot is checked using the "which" shell command to verify that it is reachable
via $PATH.

=head1 FUNCTION/ATTRIBUTES

=head2 func write_data($filename, $dataset)

Write the $dataset to the file $filename to create a gnuplot data file. 
Each element in $dataset should be of the form [[<c1>...<cn>],...]

The column values must not contain newlines (\n or \r) or quote marks. They can be non-ascii unicode.

=head2 func exec_commands ($c, $data, $placeholder = "__DATA__")

Example usage:

    use Gnuplot::Simple qw(exec_commands);
    my $d = [ [ 1,2 ],[ 2,3 ] ];
    exec_commands(
        qq{
        set terminal png
        set output "myfile.png"
        plot __DATA__ u 1:2 
        }, $d
    );

The function takes a string of gnuplot commands $c that is piped to gnuplot. You can give a data set as well in the array ref $data.
Then, any occurences of __DATA__ in $c are replaced by a temp file containing $data transformed to gnuplot format as
done by write_data. The placeholder __DATA__ can be changed via the last parameter.

The function throws the gnuplot error message if execution fails. 

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut

func _is_valid (Str $r) {
    $r =~ /^[^\n\r"]*\z/;
}

func _check_constraint ( ArrayRef[ArrayRef] $data ) {
    die 'Non-empty data not accepted'
      unless @$data;
    for (@$data) {
        assert @$_ > 0, "There must be more than one column";
        assert _is_valid( join "", @$_ ), '\n, \r or " chars not allowed in values.';
    }
}

func write_data ( Str $filename, $data ) {
    _check_constraint($data);
    write_text( $filename, _transform($data) );
}

func _transform ( ArrayRef $data) {
    my $csv = Text::CSV->new( { binary => 1, sep_char => "\t", quote_space => 1 } );
    join( "\n", map { $csv->combine(@$_); $csv->string(); } @$data );
}

func exec_commands ( Str $c, $data, $placeholder = "__DATA__" ) {

    my ( $eh, $errfile ) = tempfile();

    open my $proc, "|gnuplot 2>$errfile" or die "Could not open pipe to gnuplot.";

    my $tmp = File::Temp->new();
    my $tfn = $tmp->filename();
    write_data( $tfn, $data );

    #use placeholder to replace all occurences
    $c =~ s/$placeholder/'$tfn'/g;

    binmode $proc, ":utf8";
    ( print $proc $c ) or die "Failed to input commands to gnuplot: $!";

    close($proc);

    my $err = read_text( $errfile );
    $err && die "Gnuplot execution failed:\n$err";
}

1;

