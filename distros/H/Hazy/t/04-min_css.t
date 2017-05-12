use Test::More;

use Hazy;
our $hazy = Hazy->new();

subtest 'basic' => sub {
	run_test({
		css => '
		.class { 
			color: #fff;
		} 
		.second {
			background: #ccc;	
		}',
		expected => '.class{color:#fff}.second{background:#ccc}',
	});
	run_test({
		css => '
		.class { 
			margin: 0 0 0 0;
		} 
		.second {
			background: #ccc;	
		}
		.second::after {
			border-radius: .2rem;
		}',
		expected => '.class{margin:0 0 0 0}.second{background:#ccc}.second::after{border-radius:.2rem}',
	});
	run_test({
		css => '
		.tooltip{
			position: relative
		}
		.tooltip::after{
			background: rgba( 69, 77, 93, .9);
			border-radius: .2rem;
			bottom: 100%;
			color: #fff;
			content: attr(data-tooltip);
			display: block;
			font-size: 1.2rem;
			left: 50%;
			max-width: 32rem;
			opacity: 0;
			overflow: hidden;
			padding: .4rem .8rem;
			pointer-events: none;
			position: absolute;
			text-overflow: ellipsis;
			-webkit-transform: translate( -50%, 1rem );-
			ms-transform: translate( -50%, 1rem );
			transform: translate(-50%,1rem);
			transition: all .2s ease;
			white-space: nowrap; 
			z-index: 200
		}',
		expected => '.tooltip{position:relative}.tooltip::after{background:rgba(69,77,93,.9);border-radius:.2rem;bottom:100%;color:#fff;content:attr(data-tooltip);display:block;font-size:1.2rem;left:50%;max-width:32rem;opacity:0;overflow:hidden;padding:.4rem .8rem;pointer-events:none;position:absolute;text-overflow:ellipsis;-webkit-transform:translate(-50%,1rem);-ms-transform:translate(-50%,1rem);transform:translate(-50%,1rem);transition:all .2s ease;white-space:nowrap;z-index:200}',
	});
};

sub run_test {
	is($hazy->min_css($_[0]->{css}), $_[0]->{expected}, "min css - $_[0]->{expected}");	
}


done_testing();
