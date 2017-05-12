use t::test_base;
use Data::Dumper;

BEGIN{
    use_ok("Eixo::Rest::ApiFakeServer");
    use_ok("Eixo::Rest::Client");
}

SKIP: {

    eval{ require "HTTP/Server/Simple/CGI.pm"};

    skip "HTTP::Server::Simple::CGI not installed", 2 if($@);

    my $pid;
    my $port = int(rand(10000))+10000;

    eval{
        $pid = Eixo::Rest::ApiFakeServer->new(

            listeners => {

                '/containers/json' => {
                    #header => sub {
                    #    print "HTTP/1.0 200 OK\r\n";
                    #    print $_[0]->cgi->header(-type  =>  'text/json');
                    #},
                    body => sub {
                    
                        print '[{"a":"TEST1"},{"b":"TEST2"}]';
                    }
                },

                '/containers/foo/process/a' => {

                    body=> sub {
                        print '[{"c":"TEST1"},{"d":"TEST2"}]';
                    }
                }
            }
        )->start($port);


        my @calls;
        
        my $c = Eixo::Rest::Client->new('http://localhost:'.$port);
        
        $@ = undef;
        eval{
        	$c->noExiste;
        };
        ok($@ =~ /UNKNOW METHOD/, 'Non-existent Client methods launch exception');
        
        my $process_data = {
            onSuccess => sub {
                ok(
                    ref($_[0]) eq 'ARRAY' && $_[0]->[0]->{a} eq "TEST1", 
                    "onSuccess callback launched correctly",
                );

                # pass response
                return $_[0];
                
            },
        };

        my $callback = sub {

            ok(
                ref($_[0]) eq 'ARRAY' && $_[0]->[1]->{b} eq "TEST2", 
                'callback launched correctly'
            );

            ## pass response
            return $_[0];
        };
        
        # sync request
        my $h = $c->getContainers(
            GET_DATA => {all => 1},
            PROCESS_DATA => $process_data,
            __callback => $callback
        );

        ok(
            ref($h) eq 'ARRAY' && $h->[1]->{b} eq "TEST2", 
        	"Testing json response"
        );

        # complex request
        my $h = $c->getContainers(

            uri=>"/containers/foo/process/a",

            args=>{},

            PROCESS_DATA=> {

                onSuccess=>sub {
                    return $_[0];
                }
            },

            __callback=>sub {

                ok(


                    ref($_[0]) eq 'ARRAY' &&

                    $_[0]->[0]->{c} eq 'TEST1' &&

                    $_[0]->[1]->{d} eq 'TEST2',

                    "Complex uri was well formed"

                );
            }

        );

    };
    if($@){
        print Dumper($@);
    }

    kill(9, $pid) if($pid);
    
}

done_testing();
