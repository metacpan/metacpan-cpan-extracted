package FLAT::Regex::Parser;
use strict;

#### Is this one level of abstraction too far? Parser generator generators..

#### TODO: try YAPP, since recursive descent is SLOOOW
use Parse::RecDescent;
use FLAT::Regex::Op;

use vars '$CHAR';
$CHAR = qr{ [A-Za-z0-9_\$\#] | \[[^\]]*\] }x;

sub new {
    my $pkg = shift;
    my @ops = sort { $a->{prec} <=> $b->{prec} }
              map {{
                  pkg   => "FLAT::Regex::Op::$_",
                  prec  => "FLAT::Regex::Op::$_"->precedence,
                  spec  => "FLAT::Regex::Op::$_"->parse_spec,
                  short => $_
              }} @_;

    my $lowest = shift @ops;
    my $grammar = qq!
            parse:
                $lowest->{short} /^\\Z/ { \$item[1] }
    !;
    
    my $prev = $lowest;
    for (@ops) {
        my $spec = sprintf $prev->{spec}, $_->{short};
        
        $grammar .= qq!
            $prev->{short}:
                $spec       { $prev->{pkg}\->from_parse(\@item) }
              | $_->{short} { \$item[1] }
        !;
        
        $prev = $_;
    }            

    my $spec = sprintf $prev->{spec}, "atomic";
    $grammar .= qq!
            $prev->{short}:
                $spec  { $prev->{pkg}\->from_parse(\@item) }
              | atomic { \$item[1] }

            atomic:
                "(" $lowest->{short} ")" { \$item[2] }
              | /\$FLAT::Regex::Parser::CHAR/
                          { FLAT::Regex::Op::atomic->from_parse(\@item) }
    !;

    Parse::RecDescent->new($grammar);
}

1;


__END__

original parser:

use vars '$CHAR';
$CHAR = qr{ [A-Za-z0-9_\!\@\#\$\%\&] | \[[^\]]*\] }x;

my $PARSER = Parse::RecDescent->new(<<'__EOG__') or die;
  parse:
      alt /^\Z/            { $item[1] }
  alt:
      concat(2.. /[+|]/)   { FLAT::Regex::Op::alt->from_parse(@item) }
    | concat               { $item[1] }
  concat:
      star(2..)            { FLAT::Regex::Op::concat->from_parse(@item) }
    | star                 { $item[1] }
  star :
      atomic '*'           { FLAT::Regex::Op::star->from_parse(@item) }
    | atomic               { $item[1] }
  atomic:
      "(" alt ")"          { $item[2] }
    | /$FLAT::Regex::CHAR/ { FLAT::Regex::Op::atomic->from_parse(@item) }
__EOG__
