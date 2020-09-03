use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		realm => 'Moose',
		eval => q`
		KatoOO::Role role {
			phobos :t(ArrayRef[HashRef, 1, 100]) 
			aporia :t(HashRef[Int])	
			nike :t(Str)  :tr(print 'nike trigger';)
			hermes :t(Str) :tr(_trigger_hermes)
			_trigger_hermes $value :t(Str) {
				print "hermes trigger";
			}
			limos :ar {
				my @res = (£$orig(@params));
				print "AROUND\n";
				return $res[0];
			} 
		}
		KatoOO::Base {
			penthos :t(Str) 
			curae :r :default(5)
			thanatos :t(Map[Str, Int])
			nosoi :default(3) :t(Int) :clearer
			limos 
				$test :t(Str)
				:test(
					['ok', '$obj->penthos(2) && $obj->nosoi(2) && $obj->curae(5)'],
					['is', '$obj->limos("yay")', 5 ],
					['ok', '$obj->penthos(5)' ],
					['is', '$obj->limos("yay")', q{''}]
				) 
				{ if ($_[0]->penthos == $_[0]->nosoi) { return $_[0]->curae; } } 
		}
		KatoOO base KatoOO::Base with KatoOO::Role { 
			test {
				[
					['ok', 'my $obj = KatoOO->new({ geras => "abc", hypnos => "def", penthos => 2, nosoi => 2, curae => 5 })'],
					['is', '$obj->limos("yay")', 5 ],
					['ok', '$obj->penthos(5)' ],
					['is', '$obj->limos("yay")', q{''}],
					['is', '$obj->geras("yay")', q{'yay'} ],
					['is', '$obj->nike("yay")', q{'yay'} ],
					['is', '$obj->hermes("yay")', q{'yay'} ]
				]
			}
			gaudia :t(Tuple[Str, Int])
			hypnos :pr :r :default(this is just a test) :type(Str) :c
			geras :t(Str) :r
			limos :b {
				print "BEFORE\n";
				return;
			} 
			limos :a :test(
				['ok', '$obj->penthos(2) && $obj->nosoi(2) && $obj->curae(5)'],
				['is', '$obj->limos("yay")', 5 ],
				['ok', '$obj->penthos(5)' ],
				['is', '$obj->limos("yay")', q{''}]
			)  {
				print "AFTER\n";
				return;
			}
		}
		`,
		lib => 't/lib',
		tlib => 't/lib',
	});
	use lib 't/lib';
}
=pod

=cut

my $lame = 't/lib/KatoOO-Base.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;

$content =~ s/done_testing//g;

eval $content;

print $@;

$lame = 't/lib/KatoOO.t';
open my $fh, '<', $lame;
$content  = do { local $/; <$fh> };
close $fh;
eval $content;


print $@;
