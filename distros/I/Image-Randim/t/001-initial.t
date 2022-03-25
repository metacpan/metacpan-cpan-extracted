#!/usr/bin/env perl

use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';

BEGIN {
    use_ok('REST::Client');
    use_ok('JSON');
    use_ok('LWP::UserAgent');
    use_ok('File::Path');
    use_ok('File::Temp');
    use_ok('File::Copy');
    use_ok('IO::Prompter');
    use_ok('Module::Find');
    use_ok('Image::Randim::Image');
    use_ok('Image::Randim::Source');
    #use_ok('Image::Randim::Source::Desktoppr');
    use_ok('Image::Randim::Source::Unsplash');
}

## Test Image::Randim::Image class
##
ok my $image = Image::Randim::Image->new, 'Image::Randim::Image instantiates';
can_ok $image, 'id';
can_ok $image, 'width';
can_ok $image, 'height';
can_ok $image, 'url';
can_ok $image, 'filename';
can_ok $image, 'owner';
can_ok $image, 'link';

## Test Image::Randim::Source::Desktoppr
##
#ok my $desktoppr = Image::Randim::Source::Desktoppr->new, 'Image::Randim::Source::Desktoppr instantiates';
#can_ok $desktoppr, 'name';
#can_ok $desktoppr, 'url';
#can_ok $desktoppr, 'get_image';
#can_ok $desktoppr, 'timeout';
#is $desktoppr->name, 'Desktoppr', 'Correct Desktoppr name';
#like $desktoppr->url, qr!^https://api.desktoppr.co!, 'Desktoppr API URL';

## Test Image::Randim::Source::Unsplash
##
ok my $unsplash = Image::Randim::Source::Unsplash->new, 'Image::Randim::Source::Unsplash instantiates';
can_ok $unsplash, 'name';
can_ok $unsplash, 'url';
can_ok $unsplash, 'get_image';
can_ok $unsplash, 'timeout';
can_ok $unsplash, 'api_key';
is $unsplash->name, 'Unsplash', 'Correct Unsplash name';
like $unsplash->url, qr!^https://api.unsplash.com!, 'Unsplash API URL';

## Source Testing
##
ok my $source = Image::Randim::Source->new, 'Image::Random::Source instantiates';
can_ok $source, 'src_obj';
can_ok $source, 'timeout';
can_ok $source, 'list';
can_ok $source, 'set_provider';
can_ok $source, 'set_random_provider';
can_ok $source, 'name';
can_ok $source, 'url';
ok scalar($source->list) > 1, 'at least a couple sources are defined';
dies_ok { $source->set_provider('badsource') } 'dies on bad source provider';
ok $source->set_provider('Unsplash'), 'set provider to Unsplash';
ok $source->src_obj->name eq 'Unsplash', 'source looks like the right object';
is $source->name, 'Unsplash', 'Correct Unsplash name from source';
like $source->url, qr!^https://api.unsplash.co!, 'Unsplash API URL from source';
my @valid_source = $source->list;
my $random_test = 1;
for (1..25) {
    $source->set_random_provider;
    next if grep {$source->name} @valid_source;
    $random_test = 0;
    last;
}
ok $random_test, 'Random provider test does valid providers';
dies_ok {$source->timeout(42.34)} 'dies on non-integer timeout';
ok $source->timeout(25), 'timeout on integer';

## Test actual get
##
## Unsplash rate-limits API requests causing CPAN to fail tests so
## it is excluded

$source = Image::Randim::Source->new;
$source->set_random_provider();
if ($source->name ne 'Unsplash') {
    ok $image = $source->get_image, 'Source get_image';
    ok length($image->url) > 5, 'Image URL has more than 10 characters';
}

done_testing;
