package Methods;
use strict;
use warnings;
use Keyword::API;

sub import { 
    my ($class, %params) = @_; 

    my $name = %params && $params{-as} ? $params{-as} : "method";

    install_keyword(__PACKAGE__, $name);
}

sub unimport { uninstall_keyword() }

sub parser {
    lex_read_space(0);
    my $sub_name = lex_unstuff_to_ws();
    my $sig = lex_unstuff_to('{');
    my ($roll) = $sig =~ /\((.+)\)\s*{/;
    lex_stuff("sub $sub_name {my (\$self, $roll) = \@_;");
};

1;
