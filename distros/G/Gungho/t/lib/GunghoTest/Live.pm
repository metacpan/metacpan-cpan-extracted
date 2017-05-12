package GunghoTest::Live;
use strict;
use warnings;
use Gungho::Inline;
use Test::More;

sub run
{
    my $class  = shift;
    my $config = shift;

    $config->{user_agent} ||= "Install Test For Gungho $Gungho::VERSION";
    Gungho::Inline->run(
        $config,
        {
            provider => sub {
                my($p, $c) = @_;

                foreach my $url qw(http://search.cpan.org http://www.perl.com) {
                    $c->send_request(
                        Gungho::Request->new( GET => $url )
                    );
                }
            },
            handler => sub {
                my ($p, $c, $req, $res) = @_;
                is($res->code, 200, 'HTTP status is 200');
            }
        }
    );
}

1;
