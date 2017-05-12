
use Test;

BEGIN { plan tests => 32 }	

use Lingua::EN::Conjugate qw( conjugate conjugations s_form past);
use Data::Dumper;

ok(past('dye'), 'dyed');
ok(conjugate('verb'=>'set', 'tense'=>'present', 'pronoun'=>'it', 'passive'=>1, 'negation'=>1), 'it is not set');

ok(conjugate('verb'=>'be', 'tense'=>'present', 'pronoun'=>'she'), 'she is');
ok(conjugate('verb'=>'have', 'tense'=>'present_prog', 'pronoun'=>'it'), 'it is having');
ok(conjugate('verb'=>'do', 'tense'=>'past_prog', 'pronoun'=>'we', 'no_pronoun'=>1), 'were doing');
ok(conjugate('verb'=>'could', 'tense'=>'past', 'pronoun'=>'I'), undef);
ok(conjugate('verb'=>'could', 'tense'=>'present', 'pronoun'=>'I'), "I could");

ok(conjugate( 'verb' => 'walk', 'tense' => 'present_prog', 'pronoun' => 'he', 'negation'=>'n_t', 'allow_contractions'=>1 ), 
	"he isn't walking");
ok(conjugate( 'verb' => 'walk', 'tense' => 'present_prog', 'pronoun' => 'he', 'negation'=>'not', 'allow_contractions'=>1 ), 
	"he's not walking");
ok(conjugate( 'verb' => 'walk', 'tense' => 'present_prog', 'pronoun' => 'he', 'negation'=>'not', 'allow_contractions'=>0 ), 
	'he is not walking');

	ok(conjugate( 'verb' => 'have', 'tense' => 'present', 'pronoun' => 'he' ), 'he has');
	ok(conjugate('verb'=>'study', 'pronoun'=>'she', 'tense'=>'present'), 'she studies');
	ok(conjugate( 'verb' => 'have', 'tense' => 'past', 'pronoun' => 'I' ), 'I had');
	ok(conjugate('verb'=>'invite', 'pronoun'=>'I', 'tense'=>'past_do', 'negation'=>'n_t'), 'I didn\'t invite');
	ok(conjugate('verb'=>'go', 'pronoun'=>'you', 'tense'=>'imperative', 'negation'=>'n_t'), 'don\'t go');
	ok(conjugate('verb'=>'see', 'pronoun'=>'she', 'tense'=>'present', 'negation'=>'n_t', 'question'=>1), 'doesn\'t she see');

	# scalar context with tense and pronoun defined as scalars, 
	#returns a scalar
	my $walk = conjugate( 'verb'=>'walk', 
				'tense'=>'perfect_prog', 
				'pronoun'=>'he' );  
	print "# $walk \n";
	ok($walk, 'he has been walking');

	# scalar context with tense and pronoun undefined or defined 
	#as array refs, returns a hashref
	my $go = conjugate( 'verb'=>'go', 
				'tense'=>[qw(past_prog modal)], 
				'modal'=>'might' ) ;       	
	ok(ref $go, 'HASH');
	ok($go->{past_prog}{I}, 'I was going');

	# array context, returns an array of conjugated forms
	my @be = conjugate( 'verb'=>'be', 
				'pronoun'=>[qw(I we)], 
				'tense'=>[qw(present past_prog)] );
	print "# " . join("\n# ", @be);
	print "\n";
	ok(scalar @be, 4);
	
	ok(conjugate('verb'=>'enter', 'pronoun'=>'I', 'tense'=>'past'), 'I entered');
	ok(conjugate('verb'=>'visit', 'pronoun'=>'I', 'tense'=>'past'), 'I visited');
	ok(conjugate('verb'=>'refer', 'pronoun'=>'I', 'tense'=>'past'), 'I referred');
	ok(conjugate('verb'=>'begin', 'pronoun'=>'I', 'tense'=>'past'), 'I began');
	ok(conjugate('verb'=>'go', 'pronoun'=>'you', 'tense'=>'past', 'question'=>1), 'did you go');
	ok(conjugate('verb'=>'happen', 'pronoun'=>'it', 'tense'=>'past', 'negation'=>'n_t'), 'it didn\'t happen');
	ok(conjugate('verb'=>'prefer', 'pronoun'=>'they', 'tense'=>'modal_perf', 'modal'=>'would'), 'they would have preferred');
	
 ok(conjugate('verb'=>'suffer', 'tense'=>'past', 'pronoun'=>'I'), "I suffered");


ok(s_form("go"), "goes", "go => goes");
ok(s_form("cross"), "crosses", "cross => crosses");
ok(s_form("escort"), "escorts", "escort=>escorts");
ok(s_form("must"), "must", "must=>must");

