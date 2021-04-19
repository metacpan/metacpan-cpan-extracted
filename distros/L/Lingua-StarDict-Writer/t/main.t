#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Files;
use Test::Fatal qw(dies_ok);
use File::Temp;

use utf8;

plan tests => 35;

    my $sample_data =
    [
             {title => "second", part=> {type=> "m", data => "blah-blah-blah"}},
             {title => "second", part=> {type=> "t", data => "ˈsɛkənd"}},
             {title => "second", part=> {type=> "h", data => "This	is	second	article"}},
             {title => "third",  part=> {type=> "h", data => "This\nis\nthird\narticle 2"}},
             {title => "first",  part=> {type=> "h", data => "This is <b>first</b> article 3"}},
    ];

    my $tmpd = File::Temp->newdir;

    use_ok( 'Lingua::StarDict::Writer' ) || print "Bail out!\n";

    my $stardict_writer;
    ok($stardict_writer =  Lingua::StarDict::Writer->new(name=>'Test Star Dict', date=>"2020-12-31", output_dir => $tmpd));
    is(ref $stardict_writer, 'Lingua::StarDict::Writer' );

    foreach my $entry (@$sample_data)
    {
        ok($stardict_writer->entry($entry->{title})->add_part(%{$entry->{part}}));
    }

    ok($stardict_writer->write);
    compare_dirs_ok("$tmpd/Test Star Dict","t/expected/Test Star Dict");

    dies_ok {$stardict_writer->entry('word')->add_part()} 'empty part data';
    dies_ok {$stardict_writer->entry('word')->add_part(type=>"too-lonh", data=>'1')} 'incorrect part type' ;
    dies_ok {$stardict_writer->entry('word')->add_part(type=>"Z", data=>'1')} 'upper case mediatypes is not supported yet';

# here we do test index soring. Latin DDD01 ddd02 DDD03 ddd04 should be sorted case insensitive,
# Latin entries that are equal on case insensitive cmp. are sorted case sensetive among eachother ZZZ ZzZ Zzz zZz zzz
# non-latin (for example cyrillic) should be sorted Case Sesitive: БББ ЯЯЯ ббб яяя

    $sample_data =
    [
             {title => "DDD03", part=> {type=> "m", data => "Value DDD03"}},
             {title => "ddd04", part=> {type=> "m", data => "Value ddd04"}},
             {title => "DDD01", part=> {type=> "m", data => "Value DDD01"}},
             {title => "ddd02", part=> {type=> "m", data => "Value ddd02"}},
             {title => "яяя01", part=> {type=> "m", data => "Value яяя01"}},
             {title => "ЯЯЯ02", part=> {type=> "m", data => "Value ЯЯЯ02"}},
             {title => "БББ03", part=> {type=> "m", data => "Value БББ03"}},
             {title => "ббб04", part=> {type=> "m", data => "Value ббб04"}},
             {title => "zZz",   part=> {type=> "m", data => "Value zZz"}},
             {title => "zzz",   part=> {type=> "m", data => "Value zzz"}},
             {title => "ZZZ",   part=> {type=> "m", data => "Value ZZZ"}},
             {title => "ZzZ",   part=> {type=> "m", data => "Value ZzZ"}},
             {title => "Zzz",   part=> {type=> "m", data => "Value Zzz"}},
    ];

    ok($stardict_writer = Lingua::StarDict::Writer->new (name=>'Index Order Test Dict', date=>"2020-12-31", output_dir => $tmpd));
    is(ref $stardict_writer, 'Lingua::StarDict::Writer' );

    foreach my $entry (@$sample_data)
    {
        ok($stardict_writer->entry($entry->{title})->add_part(%{$entry->{part}}));
    }

    ok($stardict_writer->write);
    compare_dirs_ok("$tmpd/Index Order Test Dict","t/expected/Index Order Test Dict");

    # test writing dictionary from non-utf8 source
    {
      no utf8;
        $sample_data =
        [
                 {title => "Eyjafjallaj\x{f6}kull", part=> {type=> "m", data => "A vulcano at Su\x{f0}urland, Iceland"}}, # Eyjafjallajökull -- A vulcano at Suðurland, Iceland in Latin1
        ];

        ok($stardict_writer = Lingua::StarDict::Writer->new (name=>'Dictionary written from Latin1 source', date=>"2020-12-31", output_dir => $tmpd));
        is(ref $stardict_writer, 'Lingua::StarDict::Writer' );

        foreach my $entry (@$sample_data)
        {
            ok($stardict_writer->entry($entry->{title})->add_part(%{$entry->{part}}));
        }

        ok($stardict_writer->write);
        compare_dirs_ok("$tmpd/Dictionary written from Latin1 source","t/expected/Dictionary written from Latin1 source");
    }

