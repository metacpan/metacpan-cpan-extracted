package t::lib::Util;
use strict;

use base qw(Exporter);
our @EXPORT = qw(expr_eq);

use Test::More;

sub expr_eq {
    my($expr, $result) = @_;

    my $parser = HTML::Template::Parser::ExprParser->new;

    my $expr_temp = $expr;
    my $ret = $parser->parse(\$expr_temp);
    if(0){ # for debug dump
        require Data::Dumper;
        require YAML;
        print STDERR Data::Dumper->Dump([ $ret ]);
    }
    like($expr_temp, qr/\A\s*\Z/, "couldn't parse expr[$expr]=>[$expr_temp]");
    is_deeply($ret, $result, "expr is [$expr]");
}

1;
