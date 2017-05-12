###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
use Data::Dumper;
use File::Basename;
use Oktest;
use Oktest::Util qw(capture);

use Kook::Sandbox;


##
topic "Kook::Sandbox", sub {


    topic "::_eval", sub {

        ## if property is given, it's value is used instead of default value
        spec "uses supplied value as property value instead of default value", sub {
            my $str = <<'END';
	      my $val1 = prop('val1', "default1", "description1");
	      print Dumper($val1);
END
            $str =~ s/^\t//g;
            my $output = capture {
                Kook::Sandbox::_eval $str, "Kookbook.pl", { val1 => "OVERWRITE" };
            };
            OK ($output) eq "\$VAR1 = 'OVERWRITE';\n";
        };

        ## if property is not given, default value is used
        spec "uses default value as property value if valie is not supplied", sub {
            my $str = <<'END';
	      my $val2 = prop('val2', "default2", "description2");
	      print Dumper($val2);
END
            $str =~ s/^\t//g;
            my $output = capture {
                Kook::Sandbox::_eval $str, "Kookbook.pl", { val1 => "OVERWRITE" };
            };
            OK ($output) eq "\$VAR1 = 'default2';\n";
        };

        ## properties hash table is cleared when Kook::Sandbox::_eval() called
        spec "clears properties hash table", sub {
            my $str = <<'END';
	      print Dumper(\%properties);
END
            $str =~ s/^\t//g;
            my $output = capture {
                Kook::Sandbox::_eval $str, "Kookbook.pl", { val1 => "OVERWRITE" };
            };
            OK ($output) eq "";
        };

        ## if Sandbok::_eval() is called then properties name and value are kept in @Kook::Sandbox::_property_tuples in declared order
        spec "keeps property names and values in declared_order", sub {
            my $str = <<'END';
	      my $A = prop('A', 10);
	      my $B = prop('B', 20);
	      my $C = prop('C', 30);
	      my $D = prop('D', 40);
END
            $str =~ s/^\t//g;
            my $output = capture {
                Kook::Sandbox::_eval $str, "Kookbook.pl", { A=>11, B=>21 };
            };
            my $expected = [
                ["A", 11, undef],
                ["B", 21, undef],
                ["C", 30, undef],
                ["D", 40, undef],
            ];
            # properties are kept in @Kook::Sandbox::_property_tuples
            OK (\@Kook::Sandbox::_property_tuples)->equals($expected);
        };

        spec "reports error if property is not scalar nor ref", sub {
            my $str = <<'END';
	      my $prop1 = prop('prop1', 12345);
	      my $prop2 = prop('prop2', ['a', 'b', 'c']);
	      my $prop3 = prop('prop3', {x=>10});
	      my $prop4 = prop('prop4', qw(foo bar baz));    # only "foo" is used
END
            $str =~ s/^\t//g;
            my $output = capture {
                Kook::Sandbox::_eval $str, "Kookbook.pl";
            };
            my $expected = [
                ["prop1", 12345, undef],
                ["prop2", ["a","b","c"], undef],
                ["prop3", {"x" => 10}, undef],
                ["prop4", "foo", "bar"],
            ];
            OK (\@Kook::Sandbox::_property_tuples)->equals($expected);
        };

    };


};


Oktest::main() if $0 eq __FILE__;
1;
