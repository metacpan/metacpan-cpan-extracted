#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::DZil;
use Test::More;
use Test::Exception;

plan tests => 9;



sub built_module_like {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($file, $content, $re, $name) = @_;
	
	my $tzil = Builder->from_config(
		{ dist_root => 't/corpus' },
		{ add_files => {
			"source/lib/$file" => $content,
			"source/dist.ini" => simple_ini( {},
				'GatherDir',
				'ExplicitPackageForClass',
			),
		}},
	);
	$tzil->build or do { fail "$name (build)"; return };
	
	like $tzil->slurp_file("build/lib/$file"), $re, $name;
}



built_module_like 'Class/Statement.pm', <<END,
use v5.38;

class Class::Statement;
END
	qr{^package Class::Statement [v0-9.]+;$}m,
	'single class statement';



built_module_like 'Class/Pod.pm', <<END,
use feature 'class';

class Class::Pod {}
=pod

=cut
END
	qr{^package Class::Pod [v0-9.]+;\n.*^=pod$}sm,
	'single class with pod';



built_module_like 'Role.pm', <<END,
use Object::Pad;

role Role;
END
	qr{^package Role [v0-9.]+;$}m,
	'single role';



built_module_like 'Class/Indent.pm', <<END,
use feature 'class';
# empty line contains two spaces (which will be overwritten)
  
 class Class::Indent {}
END
	qr{^ package Class::Indent}m,
	'package indent matches class indent';



built_module_like 'Class/Comment.pm', <<END,
# class Class::Comment;
END
	qr{(?!package Class::Comment)}m,
	'class in comment ignored';



built_module_like 'Class/Newline.pm', <<END,
# empty line contains two spaces (which will NOT be overwritten)
...;
  
class
Class::Newline;
END
	qr{...;\n  }s,
	'class declaration with newline ignored';



built_module_like 'Class/Newline.pm', <<END,
# empty line contains two spaces (which will NOT be overwritten)
...;
  
class #
Class::Newline;
END
	qr{...;\n  }s,
	'class declaration with comment ignored';



throws_ok {
	built_module_like 'Class/NoBlankLine.pm', <<~END;
	use v5.38;
	class Class::NoBlankLine;
	END
} qr{ExplicitPackageForClass.*No blank line for package}i,
	'no blank line dies';



built_module_like 'Class/Multiple.pm', <<END,
use v5.38;

class Class1;
...;

class Class2;
END
	qr<^package Class1.*^class Class1;.*^package Class2.*^class Class2;$>sm,
	'multiple classes';



done_testing;
