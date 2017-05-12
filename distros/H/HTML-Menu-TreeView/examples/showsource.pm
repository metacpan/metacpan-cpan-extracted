package showsource;
use 5.008006;
use strict;
use warnings;
require Exporter;
use vars qw($color_Keys $formatter $perldoc_Keys @EXPORT @ISA );
@ISA                = qw(Exporter);
@showsource::EXPORT = qw(showSource path);
use Syntax::Highlight::Perl ':FULL';    # or ':FULL'

sub showSource
{

    $color_Keys = {
                   'Variable_Scalar'   => 'red',
                   'Variable_Array'    => '#a44848',
                   'Variable_Hash'     => '#a44848',
                   'Variable_Typeglob' => '#a44848',
                   'Subroutine'        => '#000000',
                   'Quote'             => '#ff9090',
                   'String'            => '#000000',
                   'Comment_Normal'    => 'red',
                   'Comment_POD'       => 'gray',
                   'Bareword'          => 'blue',
                   'Package'           => 'black',
                   'Number'            => 'blue',
                   'Operator'          => '#178b17',
                   'Symbol'            => 'red',
                   'Character'         => 'black',
                   'Directive'         => '#178b17',
                   'Label'             => '#178b17',
                   'Line'              => '#178b17',
    };
    $formatter = new Syntax::Highlight::Perl;
    $formatter->define_substitution(
                                    '<' => '&lt;',
                                    '>' => '&gt;',
                                    '&' => '&amp;',
    );    # HTML escapes.

    while (my ($type, $style) = each %{$color_Keys}) {
        $formatter->set_format($type, [qq|<span style="color:$style;">|, '</span>']);
    }
    $perldoc_Keys = {
                     'Builtin_Operator' => 'blue',
                     'Builtin_Function' => 'blue',
                     'Keyword'          => 'blue',
    };
    while (my ($type, $style) = each %{$perldoc_Keys}) {
        $formatter->set_format($type, [qq|<a onclick="window.open('http://perldoc.perl.org/search.html?q='+this.innerHTML)" style="color:$style">|, "</a>"]);
    }

    my ($file, $out) = @_;
    use Fcntl qw(:flock);
    use Symbol;
    my $fh = gensym;
    open $fh, "$file" or die "$!: $file";
    seek $fh, 0, 0;
    my @lines = <$fh>;
    close $fh;
    print "<pre>" . $formatter->format_string("@lines") . "</pre>";
    print $@ if $@;
}

1;
