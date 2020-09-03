use Test::More;

BEGIN {
        eval {
                require Moo;
                require Types::Standard;
		Moo->can('is_class');
                1;
        } or do {
                print $@;
                plan skip_all => "Moo is not available";
                done_testing();
        };
	use Hades;
	Hades->run({
		eval => q|
			Hades::Realm::Moo base Hades {
				build_accessor $mg :t(Object) $name :t(Str) $meta :t(HashRef) {
					$mg->has($name);
					$meta->{$name}->{$_} and $mg->$_($meta->{$name}->{$_}) 
						for (qw/required default clearer coerce predicate trigger/);
					$mg->isa($meta->{$name}->{type}->[0]);
					$mg->test(
						$self->build_tests($name, $meta->{$name})
					);
				}
				build_clearer :a {
					$res[0]->no_code(1);
				}
				build_predicate :a {
					$res[0]->no_code(1);
				}
				after_class $mg :t(Object) {
					$mg->new->no_code(1);
					$mg->use(q{Moo});
					$mg->use(q{Types::Standard qw(Int Dict Str HashRef ArrayRef)});
				}
				module_generate $mg :t(Object) {
					$mg->keyword('has',
						CODE => sub {
							my ($meta) = @_;
							$meta->{is} \|\|= '"rw"';
							my $attributes = join ', ', map {
								($meta->{$_} ? (sprintf "%s => %s", $_, $meta->{$_}) : ())
							} qw/is required clearer predicate isa/;
							$attributes .= ', ' .  join ', ', map {
								$meta->{$_}
									? ($_ ne 'default' and $meta->{$_} =~ m/^[\w\d]+$/)
										? (sprintf '%s => "%s"', $_, $meta->{$_})
										: (sprintf "%s => sub { %s }", $_, $meta->{$_}) 
									: ()
							} qw/default coerce trigger/;
							my $name = $meta->{has};
							my $code = qq{
								has $name => ( $attributes );};
							return $code;
						},
						KEYWORDS => [qw/is isa required default clearer coerce predicate trigger/],
						POD_TITLE => 'ATTRIBUTES',
						POD_POD => 'get or set $keyword',
						POD_EXAMPLE => "\$obj->\$keyword;\n\n\t\$obj->\$keyword(\$value);"
					);
				}
			}
		|,
		lib => 't/lib',
		tlib => 't/lib',
	});
	use lib 't/lib';
}

my $lame = 't/lib/Hades-Realm-Moo.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;
print $@;
