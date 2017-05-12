use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use File::Temp 'tempfile';
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
my $script = "$Bin/../blib/script/htmlok";
# Test running on a non-existent file.
my ($status, $output, $errors) = runit ($script, 'nosuchfile.html');
ok (length ($errors) > 0, "got error message running on empty file");
ok (length ($output) == 0, "got no output running on empty file");
done_testing ();

exit;
sub runit
{
    my ($script, @files) = @_;
    my ($eh, $errfile) = tempfile ('error.XXXXXXX');
    close $eh or die $!;
    my ($oh, $outfile) = tempfile ('output.XXXXXX');
    close $oh or die $!;
    my $status = system ("$script @files > $outfile 2> $errfile");
    my $output = getfile ($outfile);
    my $errors = getfile ($errfile);
    return ($status, $output, $errors);
}
sub getfile
{
    my ($infile) = @_;
    my $text = '';
    open my $in, "<:encoding(utf8)", $infile or die $!;
    while (<$in>) {
	$text .= $_;
    }
    close $in or die $!;
    unlink $infile or die $!;
    return $text;
}
