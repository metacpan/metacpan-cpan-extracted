use strict;
use warnings;
use Test::More;
use Eshu;

# Idempotency tests — indent(indent(x)) == indent(x) for crafted inputs

plan tests => 9;

# C inputs
{
	my $messy_c = <<'END';
void foo() {
   int x = 1;
      if (x) {
   x++;
      }
}
END
	my $once  = Eshu->indent_c($messy_c);
	my $twice = Eshu->indent_c($once);
	is($twice, $once, 'C: idempotent on messy input');
}

{
	my $nested_c = <<'END';
struct s {
         union {
int a;
         float b;
};
enum { X, Y,
Z };
};
END
	my $once  = Eshu->indent_c($nested_c);
	my $twice = Eshu->indent_c($once);
	is($twice, $once, 'C: idempotent on nested struct/enum');
}

{
	my $pp_c = <<'END';
#ifdef FOO
   #if BAR
      void baz() {
               int x;
      }
   #endif
#endif
END
	my $once  = Eshu->indent_c($pp_c);
	my $twice = Eshu->indent_c($once);
	is($twice, $once, 'C: idempotent on preprocessor nesting');
}

# Perl inputs
{
	my $messy_pl = <<'END';
sub foo {
      my $x = shift;
   if ($x) {
            for my $i (1..10) {
      print $i;
            }
   }
}
END
	my $once  = Eshu->indent_pl($messy_pl);
	my $twice = Eshu->indent_pl($once);
	is($twice, $once, 'Perl: idempotent on messy sub');
}

{
	my $heredoc_pl = <<'END';
my $x = <<HEREDOC;
   some text here
HEREDOC
      my $y = 1;
END
	my $once  = Eshu->indent_pl($heredoc_pl);
	my $twice = Eshu->indent_pl($once);
	is($twice, $once, 'Perl: idempotent with heredoc');
}

{
	my $qw_pl = <<'END';
my @list = qw(
      alpha
   beta
         gamma
);
      my $x = 1;
END
	my $once  = Eshu->indent_pl($qw_pl);
	my $twice = Eshu->indent_pl($once);
	is($twice, $once, 'Perl: idempotent with qw()');
}

# XS inputs
{
	my $messy_xs = <<'END';
MODULE = Foo  PACKAGE = Foo

int
get_value(self)
      SV *self
   CODE:
            RETVAL = 42;
   OUTPUT:
            RETVAL
END
	my $once  = Eshu->indent_xs($messy_xs);
	my $twice = Eshu->indent_xs($once);
	is($twice, $once, 'XS: idempotent on messy XSUB');
}

{
	my $boot_xs = <<'END';
MODULE = Foo  PACKAGE = Foo

BOOT:
         newCONSTSUB(stash, "VERSION", newSVpv("1.0", 0));
END
	my $once  = Eshu->indent_xs($boot_xs);
	my $twice = Eshu->indent_xs($once);
	is($twice, $once, 'XS: idempotent on BOOT section');
}

{
	my $multi_xs = <<'END';
MODULE = Foo  PACKAGE = Foo

void
foo()
   PREINIT:
            int x;
   CODE:
            x = 1;

void
bar()
      CODE:
               printf("bar\n");
END
	my $once  = Eshu->indent_xs($multi_xs);
	my $twice = Eshu->indent_xs($once);
	is($twice, $once, 'XS: idempotent on multiple XSUBs');
}
