use Test::More;

BEGIN {
        eval {
                require Moo;
                Moo->can('is_class');
                1;
        } or do {
                print $@;
                plan skip_all => "Moo is not available";
                done_testing();
        };
	use lib 't/lib';
	use Hades;
	Hades->run({
		realm => 'Moo',
		eval => q|
			Keyword {
				other :t(Dict[name => Str, meta => Dict[name => Str]])
                		thing :r :d(22) :c :pr :tr(1) :t(Int)
				_trigger_thing $value {
					return $value;
				}
			}
		|,
		lib => 't/lib',
		tlib => 't/lib',
	});
	use lib 't/lib';
}

my $lame = 't/lib/Keyword.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;
print $@;


=pod 
       
 
        $mg->class('Keyword::Role')
                ->use('Moo::Role')
                ->has('test')->is(q|'rw'|)
                        ->test(
                                ['ok', q|my $obj = do { eval q{
                                        package FooBar;
                                        use Moo;
                                        with 'Keyword::Role';
                                        1;
                                }; 1; } && FooBar->new| ],
                                ['is', q|$obj->test|, q|undef|],
                                ['ok', q|$obj->test('abc')|],
                                ['is', q|$obj->test|, q|'abc'|]
                        );
 
=cut

