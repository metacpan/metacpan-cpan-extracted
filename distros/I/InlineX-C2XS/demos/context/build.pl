use InlineX::C2XS qw(c2xs context context_blindly);
use Config;

my $v = '0.01';

c2xs(
    'FOO', 'FOO', "./FOO-$v",
     {
     VERSION => "$v",
     WRITE_PM => 1,
     WRITE_MAKEFILE_PL => 1,
     EXPORT_OK_ALL => 1,
     EXPORT_TAGS_ALL => 'all',
     LIBS => ['-lm'],
     USING => ['ParseRegExp'],
     PRE_HEAD => "#define PERL_NO_GET_CONTEXT\n",
     T => 1,
     MANIF => 1,
     });

# Assign the functions that need the context args to @func.
my @func = ('dubble', 'dv', 'dub', 'call_dub', 'dubul', 'call_dubd');


context("FOO-$v/FOO.xs", \@func);


