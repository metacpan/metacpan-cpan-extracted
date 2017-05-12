#!/usr/local/bin/perl
# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Example::SiteCrawler::Rule::Seen;
use strict;
use warnings;
use GunghoX::FollowLinks::Rule qw(FOLLOW_DENY FOLLOW_ALLOW);
use base qw(GunghoX::FollowLinks::Rule);
my %SEEN;

sub apply
{
    my ($self, $c, $response, $url, $attrs) = @_;
    if ($SEEN{ $url }++) {
        return FOLLOW_DENY;
    }
    return FOLLOW_ALLOW;
}

package main;
use strict;
use warnings;
use Gungho;
use Gungho::Request;
use GunghoX::FollowLinks '0.00004';
use URI;

main();

sub main
{
    my $site   = $ARGV[0] or die "No site specified";

    $site = URI->new($site) unless eval { $site->isa('URI') } && !$@;

    Gungho->run({
        provider => sub {
            my ($p, $c) = @_;

            my $request;
            if (! $p->{started}) {
                $p->{started} = 1;
                $p->{pending} = 1;
                $request = Gungho::Request->new( GET => $site );
            } else {
                $request = shift @{ $p->requests };
            }

            print STDERR "Pending is $p->{pending}.\n";
            if ( ! $request) {
                if ($p->{pending} <= 0 && scalar keys %Gungho::Example::SiteCrawler::Seen::SEEN > 1) {
                    print STDERR "Pending is $p->{pending}. Shutting down\n";
                    $c->shutdown();
                }
                return 1;
            }

            $request->uri->fragment(undef);
            if ($Gungho::Example::SiteCrawler::Seen::SEEN{$request->original_uri->as_string}) {
                $p->{pending}--;
            } else {
                print STDERR "Sending ", $request->uri, "\n";
                if ($c->send_request( $request ) && $request->notes('auto_robot_rules' => 1) ) {
                   $p->{pending}++;
                }
            }
            return 1;
        },
        handler  => sub {
            my ($h, $c, $req, $res) = @_;
            my $provider = $c->provider;
            print STDERR "Fetched ", $res->request->uri, ". Pending = $provider->{pending}\n";
            $provider->{pending}--;
            $provider->{pending} += $c->follow_links($res);

            # Make sure to use the original hostname
            my $original_uri = $req->original_uri;
            $Gungho::Example::SiteCrawler::Seen::SEEN{$req->original_uri->as_string}++;
        },
        components => [
            '+GunghoX::FollowLinks',
            'RobotRules',
            'Throttle::Simple',
        ],
        throttle => {
            simple => {
                max_items => 100,
                interval => 60,
            }
        },
        follow_links => {
            parsers => [
                { module => "HTML",
                  config => {
                      merge_rule => "ALL",
                      rules  => [
                        { module => "HTML::SelectedTags",
                          config => {
                            tags => [ qw(a link) ]
                          }
                        },
                        { module => "URI",
                          config => {
                            match => [ {
                                scheme => qr/^http$/i,
                                host => $site->host,
                                path => "^" . ($site->path || "/"),
                                action_nomatch => "FOLLOW_DENY"
                            } ]
                          }
                        },
                        { module => "MIME",
                          config => {
                            types => [ qw(text/html) ],
                            unknown => "FOLLOW_ALLOW",
                          }
                        },
                        { module => "+Gungho::Example::SiteCrawler::Rule::Seen"
                        }
                      ]
                  }
                }
            ]
        }
    });
}

1;

__END__

=head1 NAME

site-crawler.pl - Crawl Within A Specific Site

=head1 SYNOPSIS

  site-crawler.pl [path]

=head1 DESCRIPTION

This example crawls within the given site, looking for any links that might
be found within the pages. 

It will only look at HTML pages that reside under the url given in the
command line

Please note that this crawler will NOT terminate by itself at this point 
(it's an example toy!). You need to CTRL-C yourself

=cut