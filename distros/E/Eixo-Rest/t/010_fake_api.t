use t::test_base;

SKIP: {

    eval{ require "HTTP/Server/Simple/CGI.pm"};

    skip "HTTP::Server::Simple::CGI not installed", 2 if($@);

    use_ok(Eixo::Rest::ApiFakeServer);
    use_ok(Eixo::Rest::Api);

    my $pid;
    my $port = int(rand(10000))+2000;
    
    eval{
    
    
    	#
    	# We can create an rest api with arbitrary methods
    	# that can accept arbitrary requests
    	#
    	$pid = Eixo::Rest::ApiFakeServer->new(
    
    		listeners=>{
    
    			'/test/a' => {
    
    				body=>sub {
    
    					print "TEST1";
    
    				}
    
    			},

			'/test/:id/json' => {

				body=>sub {

					print '{ "a" : 24 }'
				}

			},
    
    			'/test2/b' =>  {
 
				type=>"POST",
				   
    				body=>sub {
    
    					print $_[0]->cgi->{param}->{POSTDATA}->[0];
    
    				}
    
    			},

                '/complextest/grammar/examples/example1' => {

                    type=>"POST",

                    body=>sub {

    					print $_[0]->cgi->{param}->{POSTDATA}->[0];
 
                    }

                }
    
    
    		}
    
    
    	)->start($port);

        sleep(1);    

    	#
    	# We can connect now to it
    	#
        my $a = Eixo::Rest::Api->new('http://localhost:'.$port);
    
    	$a->getTest(
    	
    		args=>{
    
    			action=>'a',
    			__format=>'RAW',
    			__implicit_format=>1,
    
    		},
    
    		__callback=>sub {
    
    			is($_[0], 'TEST1' , 'Request was successfull');
    
    		}
    	);

	$a->getTest(

		args=>{

			id=>"buu",
		},

		__callback=>sub {

			is(ref($_[0]), "HASH", "Request was successfull (2)");
			is($_[0]->{a}, 24, "Request's data is correct");

		}

	);    

    	$a->postTest2(
    
    		args=>{
    
    			action=>'b',
    			
    			list=>[1,2,3,4,5],
    		},
    
    		post_params=>[qw(list)],
    
    		__callback=>sub {

    			is(ref($_[0]), 'HASH', 'Post params are ok');
    
    			is(
    				scalar(@{$_[0]->{list}}), 
    
    				5, 
    
    				'Request with post params is successfull'
    			);
    
    		}	
    
    	);
    
        $a->postComplextest(

            args=>{

                type=>"grammar",

                example=>"example1",

                list=>[qw(a b c d e)],
            },

            uri_mask=>"/complextest/:type/examples/:example",

            post_params=>[qw(list)],

            __callback=>sub {

    			is(ref($_[0]), 'HASH', 'Post params are ok');

    			is(
    				scalar(@{$_[0]->{list}}), 
    
    				5, 
    
    				'Complex request with post params is successfull'
                );

                is(join('', @{$_[0]->{list}}), 'abcde', "Content is correct");
            }

        );
    
    };
    
    if($@){
    	print Dumper($@);
    }
    
    kill(9, $pid) if($pid);	

}
done_testing();
