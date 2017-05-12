#!/usr/bin/env perl
use warnings;
use strict;
use Cwd 'abs_path';
use File::Spec;
use LWP::UserAgent::ProgressBar;
use Test::More tests => 4;
use Test::Differences;

# get
{
    my $self_path = $0;
       $self_path = abs_path($self_path)
            unless File::Spec->file_name_is_absolute($self_path);
    my $self_content = do { local (@ARGV, $/) = $self_path; <> };
    my $self_url = "file://$self_path";
    my $response =
    LWP::UserAgent::ProgressBar->new->get_with_progress($self_url,
        bar_name => '# ',);
    ok($response->is_success, 'successful download');
    my $content = $response->content;
    eq_or_diff $content, $self_content, 'content matches';
}

# post
{
    my $self_url = 'http://search.cpan.org/search';
    my $response = LWP::UserAgent::ProgressBar->new->post_with_progress(
        $self_url,
        { query => 'LWP' },
        bar_name => '# '
    );
    ok($response->is_success, 'successful download');
    ok($response->content,    'content is not empty');
}

