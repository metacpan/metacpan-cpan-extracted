package Doc::Simply::App;

use Doc::Simply::Carp;

use Getopt::Long qw/ GetOptions /;

my %type = (
    (map { $_ => 'slash-star' } qw/ slash-star js javascript c c++ cpp java /),
);
my @types = keys %type;

use Getopt::Usaginator <<_END_;

Usage: doc-simply [options] < [infile] > [outfile]

Parse infile (stdin), which can be a .js, .java, .c, .cpp file and write to outfile (stdout), an HTML document

With options:

    -h, --help      Show this help

Here is an example Doc::Simply-compatible JavaScript document:

    /* 
     * \@head1 NAME
     *
     * Calculator - Add 2 + 2 and return the result
     *
     */

    // \@head1 DESCRIPTION
    // \@body Add 2 + 2 and return the result (which should be 4)

    /*
     * \@head1 FUNCTIONS
     *
     * \@head2 twoPlusTwo
     *
     * Add 2 and 2 and return 4
     *
     */

    function twoPlusTwo() {
        return 2 + 2; // Should return 4
    }

_END_

sub run {
    my $self = shift;
    my @arguments = @_;

    my ( $help, $type );
    $type = 'slash-star';
    {
        local @ARGV = @arguments;
        GetOptions(
            'type=s' => \$type,
            'help|h|?' => \$help,
        );

        # style:s
        # css-file:s css-link:s css:s
        # js-file:s js-link:s js:s
        # wrapper-file:s
    }

    usage 0 if $help;

    my $canonical_type = $type{$type} or usage "Invalid type \"$type\" (@types)";

    my $source = join '', <STDIN>;

    eval {
        require Doc::Simply;
        require Doc::Simply::Extractor;
        require Doc::Simply::Assembler;
        require Doc::Simply::Parser;
        require Doc::Simply::Render::HTML;

        my $extractor = Doc::Simply::Extractor::SlashStar->new;
        my $comments = $extractor->extract( $source );

        my $assembler = Doc::Simply::Assembler->new;
        my $blocks = $assembler->assemble( $comments );

        my $parser = Doc::Simply::Parser->new;
        my $document = $parser->parse( $blocks );

        my $formatter = Doc::Simply::Render::HTML->new;
        my $render = $formatter->render( document => $document );

        print $render;
    } or
    die $@;
}
