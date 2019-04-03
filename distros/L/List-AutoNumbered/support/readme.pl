#!perl
# readme_md.pl: Make README.md from a Perl file.
# Part of Games::Dice::Tester.

use 5.014;
use strict;
use warnings;
use Getopt::Long qw(:config gnu_getopt);
use Path::Class;

# Parse command-line options
my ($source_fn, $dest_fn, $appveyor, $appveyor_badge, $skipfrom, $skipto);
my $format = 'md';
GetOptions( "i|input=s" => \$source_fn,
            "o|output=s" => \$dest_fn,
            "f|format=s" => \$format,
            "appveyor=s" => \$appveyor,         # username/repo
            "avbadge=s" => \$appveyor_badge,    # default $appveyor
            "skipfrom=s" => \$skipfrom,
            "skipto=s" => \$skipto,
)
    or die "Error in arguments.  Usage:\nreadme_md.pl -i input -o output [-f format]\nFormat = md (default) or text.";

die "Need an input file" unless $source_fn;
die "Need an output file" unless $dest_fn;

die "skipfrom and skipto must be used together" if (!!$skipfrom) ^ (!!$skipto);

$appveyor =~ m{^[A-Za-z0-9-]+/[A-Za-z0-9-]+} or die '--appveyor <GH username>/<GH repo>' if $appveyor;
$appveyor_badge //= $appveyor;
$appveyor_badge =~ m{^[A-Za-z0-9-]+/[A-Za-z0-9-]+} or die '--appveyor <GH username>/<GH repo>' if $appveyor_badge;

# Load the right parser
my $parser;
if($format eq 'md') {
    require Pod::Markdown;
    $parser = Pod::Markdown->new;

} elsif($format eq 'text') {
    require Pod::Text;
    $parser = Pod::Text->new(sentence => 1, width => 78);

} else {
    die "Invalid format $format (I understand 'md' and 'text')"
}

# Turn the POD into the output format
my $parsed = '';
$parser->output_string(\$parsed);
my $pod = file($source_fn)->slurp;
$parser->parse_string_document($pod);
open my $fh, '<', \$parsed;

# Filter and tweak the POD
my $saw_name = 0;
my $tweak_name = ($format eq 'md');
my $force_conventions = ($format eq 'md');
my $output = '';

while(my $line = <$fh>) {

    # In Markdown, turn NAME into the text, as a heading.
    # Also add the Appveyor badge.
    if($tweak_name && !$saw_name && $line =~ /NAME/) {
        $saw_name = 1;
        next;
    } elsif($tweak_name && $saw_name && $line =~ m{\H\h*$/}) {
        $output .= ($format eq 'md' ? '# ' : '') . "$line\n";
        $output .= "[![Appveyor Badge](https://ci.appveyor.com/api/projects/status/github/${appveyor_badge}?svg=true)](https://ci.appveyor.com/project/${appveyor})\n\n" if $appveyor;
        $saw_name = 0;
        next;
    } elsif($tweak_name && $saw_name) {
        next;   # Waiting for the name line to come around
    }

    next if $line =~ /SYNOPSIS/;    # Don't need this header.

    # Skip the internals, if any
    if($skipfrom) {
        $output .= $line if $line =~ /$skipto/;
        next if ($line =~ /$skipfrom/)..($line =~ /$skipto/);
    }

    $output .= $line;   # Copy everything that's left.
}

file($dest_fn)->spew($output);

__END__
# Documentation ========================================================== {{{1

=head1 NAME

readme.pl - Generate README/README.md from POD.

=head1 SYNOPSIS

    readme.pl -i <input filename> -o <output filename> [args...]

=head1 ARGUMENTS

=head2 B<-i>, B<--input>

(Required) The input filename.  Must be something containing POD.

=head2 B<-o>, B<--output>

(Required) The output filename.

=head2 B<-f>, B<--format>

(Optional, default C<md>) The format to generate.  Values are C<md> and C<text>.

=head2 B<--appveyor> <slug>

Add an appveyor badge.  B<< <slug> >> should be of the form C<username/repo>,
and should point to the build page.

=head2 B<--avbadge> <slug>

Specify the badge image URL, if different from the C<--appveyor> location.
B<< <slug> >> should be of the form C<username/repo>.

=head2 B<--skipfrom> <line1> B<--skipto> <line2>

Must be used together or not at all.  If specified, lines starting at
B<< <line1> >> and extending to just B<before> B<< <line2> >> will be omitted
from the output.  For example, if your POD has an C<INTERNALS> section you
want to leave out of the readme, and the next section is C<AUTHOR>, specify

    --skipfrom INTERNALS --skipto AUTHOR

=head1 LICENSE

The same terms as Perl itself.  NO WARRANTY.

=cut

# }}}1
# vi: set fdm=marker: #
