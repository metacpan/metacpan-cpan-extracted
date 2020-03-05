#!env perl
use strict;
use warnings FATAL => 'all';
use Data::Section 0.200006 -setup;
use FindBin qw /$Bin/;
use File::Spec;
use Test::More;
use Test::More::UTF8;
use Test::Trap;

# use Log::Any qw/$log/;
# use Log::Log4perl qw/:easy/;
# use Log::Any::Adapter;
# use Log::Any::Adapter::Log4perl;  # Just to make sure dzil catches it

#
# Init log
#
# our $defaultLog4perlConf = '
# log4perl.rootLogger              = INFO, Screen
# log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
# log4perl.appender.Screen.stderr  = 0
# log4perl.appender.Screen.layout  = PatternLayout
# log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
# ';
# Log::Log4perl::init(\$defaultLog4perlConf);
# Log::Any::Adapter->set('Log4perl');

BEGIN { require_ok('MarpaX::ESLIF::ECMA404') };

diag("###########################################################");
diag("Testing inline JSON data");
diag("###########################################################");
foreach (sort __PACKAGE__->section_data_names) {
    my $want_ok = ($_ =~ /^ok/);
    my $want_ko = ($_ =~ /^ko/);
    #
    # Just in case __DATA__ sections would not start with ok or ko -;
    #
    next unless $want_ok || $want_ko;
    #
    # Test data
    #
    my $input = __PACKAGE__->section_data($_);
    do_test($want_ok, $_, $$input);
}

#
# From https://github.com/nst/JSONTestSuite/tree/master/test_parsing
#      https://github.com/nst/JSONTestSuite/tree/master/test_transform
#
diag("#########################################################");
diag("Testing files as per https://github.com/nst/JSONTestSuite");
diag("#########################################################");
foreach my $dir_basename (qw/test_parsing test_transform/) {
    my $test_dir = File::Spec->catdir($Bin, $dir_basename);
    opendir(my $d, $test_dir) || die "Failed to open $test_dir, $!";
    my @files = sort grep { /\.json$/ } readdir($d);
    closedir($d) || warn "Failed to close $test_dir, $!";
    foreach my $basename (@files) {
        my $file_path = File::Spec->catfile($test_dir, $basename);

        open(my $f, '<', $file_path) || die "Cannot open $file_path, $!";
        binmode($f);
        my $data = do { local $/; <$f> };
        close($f) || warn "Failed to close $_, $!";

        #
        # Encoding - letting MarpaX::ESLIF guess is proned to errors
        #
        my $encoding;
        if ($basename =~ /utf16be/i) {
            $encoding = 'UTF-16BE';
        } elsif ($basename =~ /utf16le/i) {
            $encoding = 'UTF-16LE';
        } elsif ($basename =~ /utf[_-]?8/i) {
            $encoding = 'UTF-8';
        } elsif ($basename =~ /latin[_-]?1/i) {
            #
            # it is NOT required that JSON parsers accept ONLY UTF-8, UTF-16 or UTF-32.
            # For instance this file is in LATIN1, and we explicitly say so because
            # guess would say this is UTF-8.
            #
            $encoding = 'LATIN1';
        } elsif (! ($basename =~ /bom/i)) {
            #
            # Just to please OLD versions of perl, 5.10 for example.
            # In general this is not needed.
            #
            $encoding = 'UTF-8';
        }

        my $want_ko;
        my $reason = '';
        #
        # Some undefined cases - that we consider invididually.
        # When the input has INVALID characters the default is to fail.
        # Nevertheless it is conceivable to want to use the substitution
        # character, and this is optional with MarpaX::ESLIF::ECMA404.
        #
        if ($basename eq 'i_string_UTF-8_invalid_sequence.json'         || # Invalid character
            $basename eq 'i_string_UTF8_surrogate_U+D800.json'          || # Invalid character
            $basename eq 'i_string_invalid_utf-8.json'                  || # Invalid character
            $basename eq 'i_string_lone_utf8_continuation_byte.json'    || # Invalid character
            $basename eq 'i_string_not_in_unicode_range.json'           || # Invalid character
            $basename eq 'i_string_overlong_sequence_2_bytes.json'      || # Invalid character
            $basename eq 'i_string_overlong_sequence_6_bytes.json'      || # Invalid character
            $basename eq 'i_string_overlong_sequence_6_bytes_null.json' || # Invalid character
            $basename eq 'i_string_truncated-utf-8.json'                || # Invalid character
            $basename eq 'string_1_invalid_codepoint.json'              || # Invalid character
            $basename eq 'string_2_invalid_codepoints.json'             || # Invalid character
            $basename eq 'string_3_invalid_codepoints.json'                # Invalid character
            ) {
            $want_ko = 1;
            $reason = ' (Invalid character)';
        } elsif ($basename =~ /^i_/) {
            $want_ko = 0;
        } else {
            #
            # All other files falls in three categories:
            #
            if ($dir_basename eq 'test_transform') {
                #
                # Those in test_transform - always ok by construction.
                #
                $want_ko = 0;
            } else {
                if ($basename =~ /^n_/) {
                    #
                    # Those starting with "n_", always not ok.
                    #
                    $want_ko = 1;
                    $reason = ' (Invalid JSON)';
                } else {
                    #
                    # The rest, always ok.
                    #
                    $want_ko = 0;
                }
            }
        }
        # diag("Testing $file_path, expecting " . ($want_ko ? 'failure' : 'success') . "$reason");
        if ($want_ko) {
            do_test(0, "ko / $basename$reason", $data, $encoding);
        } else {
            do_test(1, "ok / $basename$reason", $data, $encoding);
        }
    }
}

sub do_test {
    my ($want_ok, $name, $input, $encoding) = @_;

    my @r = trap { MarpaX::ESLIF::ECMA404->decode($input, strict => 1, encoding => $encoding) };
    my $ok = $want_ok ? scalar(@r) : !scalar(@r);
    ok($ok, $name);
    #
    # We always printout information in case of failure or in case of implementation specific behaviour
    #
    print STDOUT $trap->stdout if $trap->stdout && (!$ok || $name =~ /(?:ok|ko) \/ i_/);
    print STDERR $trap->stderr if $trap->stderr && (!$ok || $name =~ /(?:ok|ko) \/ i_/);
}

#
# Done
#
done_testing();

__DATA__
__[ ok / from https://en.wikipedia.org/wiki/JSON#Data_portability_issues ]__
{ "face1": "😂", "face2": "\u849c\uD83D\uDE02\u849c\u8089" }
__[ ok / from https://stackoverflow.com/questions/7460645/how-to-convert-json-string-that-contains-encoded-unicode ]__
{"records":[{"description":"\u849c\u8089","id":282}]}
__[ ok / from http://www.json-generator.com/ compact ]__
[{"_id":"5916ab741f6f6ce5f930c58d","index":0,"guid":"fd2873ca-a571-4872-a0e6-174f08436373","isActive":true,"balance":"$2,595.35","picture":"http://placehold.it/32x32","age":25,"eyeColor":"blue","name":"Roy Melton","gender":"male","company":"LUXURIA","email":"roymelton@luxuria.com","phone":"+1 (855) 543-2902","address":"390 Chester Court, Bangor, Indiana, 2520","about":"Aliqua id ullamco minim dolore cillum consectetur. Veniam veniam est ut duis labore ex consequat excepteur deserunt magna exercitation consectetur. Culpa elit et minim pariatur quis velit occaecat in dolore consectetur incididunt Lorem aute.\r\n","registered":"2014-09-03T07:41:45 -02:00","latitude":27.588587,"longitude":-49.485137,"tags":["ea","nisi","irure","dolor","sunt","eu","eiusmod"],"friends":[{"id":0,"name":"Patricia Hunt"},{"id":1,"name":"Mccarty Diaz"},{"id":2,"name":"Douglas Richmond"}],"greeting":"Hello, Roy Melton! You have 2 unread messages.","favoriteFruit":"apple"},{"_id":"5916ab74f9f4176196755b7b","index":1,"guid":"81b26539-4d77-4943-826a-08cfa7ebb834","isActive":false,"balance":"$1,975.64","picture":"http://placehold.it/32x32","age":30,"eyeColor":"blue","name":"Edith Little","gender":"female","company":"JAMNATION","email":"edithlittle@jamnation.com","phone":"+1 (849) 552-2583","address":"991 Powers Street, Waterloo, Maine, 7454","about":"Adipisicing culpa deserunt enim excepteur Lorem aliqua eu. Officia occaecat occaecat officia sunt cupidatat sunt consequat eu excepteur duis. Et excepteur cillum qui mollit enim excepteur sint voluptate ullamco in consectetur irure cillum. Voluptate mollit mollit laborum velit aliqua consectetur nulla anim velit. Minim do proident culpa non proident irure ullamco velit enim consectetur. Et excepteur nostrud minim sit cupidatat ex ut. Do incididunt laborum anim in duis reprehenderit aute reprehenderit ad veniam nostrud duis quis dolor.\r\n","registered":"2015-06-30T10:58:03 -02:00","latitude":60.958765,"longitude":-118.104883,"tags":["eu","elit","laborum","et","Lorem","Lorem","laborum"],"friends":[{"id":0,"name":"Simone Walton"},{"id":1,"name":"Price Velazquez"},{"id":2,"name":"Claudette Phillips"}],"greeting":"Hello, Edith Little! You have 1 unread messages.","favoriteFruit":"strawberry"},{"_id":"5916ab747c07b0865fb01fc9","index":2,"guid":"5ad03e7e-5d3f-45e3-aa74-c3c888e2e4b8","isActive":false,"balance":"$2,262.69","picture":"http://placehold.it/32x32","age":37,"eyeColor":"green","name":"Minnie Goodwin","gender":"female","company":"MAROPTIC","email":"minniegoodwin@maroptic.com","phone":"+1 (938) 419-3863","address":"352 Claver Place, Hillsboro, Arkansas, 7845","about":"Laboris ut pariatur cillum exercitation exercitation labore in nostrud quis consectetur magna. Sunt consectetur dolore non fugiat ullamco sint proident commodo ex eu voluptate aute. Aute aliquip nostrud laborum eu reprehenderit consectetur id sit quis ullamco est. Excepteur ipsum enim pariatur enim officia veniam officia consectetur aliquip dolore. Consectetur veniam magna ex velit deserunt cillum duis est ipsum aliquip nostrud.\r\n","registered":"2016-06-03T03:41:45 -02:00","latitude":62.067073,"longitude":115.363007,"tags":["do","laboris","laborum","deserunt","eu","fugiat","non"],"friends":[{"id":0,"name":"Oconnor Fisher"},{"id":1,"name":"Robbins Davis"},{"id":2,"name":"Rollins Brooks"}],"greeting":"Hello, Minnie Goodwin! You have 10 unread messages.","favoriteFruit":"banana"},{"_id":"5916ab747863a79d58240d44","index":3,"guid":"ae93261d-55be-4bb9-8a69-9b8f545a02e2","isActive":false,"balance":"$2,098.44","picture":"http://placehold.it/32x32","age":28,"eyeColor":"green","name":"Maxwell Flynn","gender":"male","company":"MYOPIUM","email":"maxwellflynn@myopium.com","phone":"+1 (804) 510-2371","address":"774 Rockaway Avenue, Roy, Kansas, 174","about":"Duis ex sunt ullamco sunt deserunt adipisicing irure quis labore ex occaecat laborum. Aliqua dolor nisi pariatur elit. Mollit eiusmod proident cupidatat aliquip ut dolore esse.\r\n","registered":"2015-12-03T11:49:42 -01:00","latitude":-78.593105,"longitude":-128.314445,"tags":["aliqua","consequat","quis","minim","adipisicing","nisi","deserunt"],"friends":[{"id":0,"name":"Roach Downs"},{"id":1,"name":"Evangeline Woodward"},{"id":2,"name":"Mia Aguirre"}],"greeting":"Hello, Maxwell Flynn! You have 1 unread messages.","favoriteFruit":"banana"},{"_id":"5916ab7462aaf97f64876644","index":4,"guid":"6f1e7bc6-2370-47d2-8287-f2d6106a56e3","isActive":false,"balance":"$1,198.72","picture":"http://placehold.it/32x32","age":21,"eyeColor":"green","name":"Sims Sykes","gender":"male","company":"ZAGGLES","email":"simssykes@zaggles.com","phone":"+1 (895) 512-3678","address":"941 Luquer Street, Winfred, Rhode Island, 2640","about":"Voluptate duis minim aute culpa in id dolor dolore laborum voluptate non. Enim ea adipisicing sint labore excepteur et aute laborum in eu culpa et aute consequat. Veniam labore labore elit quis id deserunt proident dolore nisi do non.\r\n","registered":"2017-02-02T01:35:15 -01:00","latitude":-61.994374,"longitude":-90.596461,"tags":["occaecat","adipisicing","voluptate","cupidatat","irure","ut","ut"],"friends":[{"id":0,"name":"Copeland Zimmerman"},{"id":1,"name":"Mack Blake"},{"id":2,"name":"Mae Terry"}],"greeting":"Hello, Sims Sykes! You have 1 unread messages.","favoriteFruit":"banana"}]
__[ ok / from http://www.json-generator.com/ 2 space tab ]__
[
  {
    "_id": "5916ab741f6f6ce5f930c58d",
    "index": 0,
    "guid": "fd2873ca-a571-4872-a0e6-174f08436373",
    "isActive": true,
    "balance": "$2,595.35",
    "picture": "http://placehold.it/32x32",
    "age": 25,
    "eyeColor": "blue",
    "name": "Roy Melton",
    "gender": "male",
    "company": "LUXURIA",
    "email": "roymelton@luxuria.com",
    "phone": "+1 (855) 543-2902",
    "address": "390 Chester Court, Bangor, Indiana, 2520",
    "about": "Aliqua id ullamco minim dolore cillum consectetur. Veniam veniam est ut duis labore ex consequat excepteur deserunt magna exercitation consectetur. Culpa elit et minim pariatur quis velit occaecat in dolore consectetur incididunt Lorem aute.\r\n",
    "registered": "2014-09-03T07:41:45 -02:00",
    "latitude": 27.588587,
    "longitude": -49.485137,
    "tags": [
      "ea",
      "nisi",
      "irure",
      "dolor",
      "sunt",
      "eu",
      "eiusmod"
    ],
    "friends": [
      {
        "id": 0,
        "name": "Patricia Hunt"
      },
      {
        "id": 1,
        "name": "Mccarty Diaz"
      },
      {
        "id": 2,
        "name": "Douglas Richmond"
      }
    ],
    "greeting": "Hello, Roy Melton! You have 2 unread messages.",
    "favoriteFruit": "apple"
  },
  {
    "_id": "5916ab74f9f4176196755b7b",
    "index": 1,
    "guid": "81b26539-4d77-4943-826a-08cfa7ebb834",
    "isActive": false,
    "balance": "$1,975.64",
    "picture": "http://placehold.it/32x32",
    "age": 30,
    "eyeColor": "blue",
    "name": "Edith Little",
    "gender": "female",
    "company": "JAMNATION",
    "email": "edithlittle@jamnation.com",
    "phone": "+1 (849) 552-2583",
    "address": "991 Powers Street, Waterloo, Maine, 7454",
    "about": "Adipisicing culpa deserunt enim excepteur Lorem aliqua eu. Officia occaecat occaecat officia sunt cupidatat sunt consequat eu excepteur duis. Et excepteur cillum qui mollit enim excepteur sint voluptate ullamco in consectetur irure cillum. Voluptate mollit mollit laborum velit aliqua consectetur nulla anim velit. Minim do proident culpa non proident irure ullamco velit enim consectetur. Et excepteur nostrud minim sit cupidatat ex ut. Do incididunt laborum anim in duis reprehenderit aute reprehenderit ad veniam nostrud duis quis dolor.\r\n",
    "registered": "2015-06-30T10:58:03 -02:00",
    "latitude": 60.958765,
    "longitude": -118.104883,
    "tags": [
      "eu",
      "elit",
      "laborum",
      "et",
      "Lorem",
      "Lorem",
      "laborum"
    ],
    "friends": [
      {
        "id": 0,
        "name": "Simone Walton"
      },
      {
        "id": 1,
        "name": "Price Velazquez"
      },
      {
        "id": 2,
        "name": "Claudette Phillips"
      }
    ],
    "greeting": "Hello, Edith Little! You have 1 unread messages.",
    "favoriteFruit": "strawberry"
  },
  {
    "_id": "5916ab747c07b0865fb01fc9",
    "index": 2,
    "guid": "5ad03e7e-5d3f-45e3-aa74-c3c888e2e4b8",
    "isActive": false,
    "balance": "$2,262.69",
    "picture": "http://placehold.it/32x32",
    "age": 37,
    "eyeColor": "green",
    "name": "Minnie Goodwin",
    "gender": "female",
    "company": "MAROPTIC",
    "email": "minniegoodwin@maroptic.com",
    "phone": "+1 (938) 419-3863",
    "address": "352 Claver Place, Hillsboro, Arkansas, 7845",
    "about": "Laboris ut pariatur cillum exercitation exercitation labore in nostrud quis consectetur magna. Sunt consectetur dolore non fugiat ullamco sint proident commodo ex eu voluptate aute. Aute aliquip nostrud laborum eu reprehenderit consectetur id sit quis ullamco est. Excepteur ipsum enim pariatur enim officia veniam officia consectetur aliquip dolore. Consectetur veniam magna ex velit deserunt cillum duis est ipsum aliquip nostrud.\r\n",
    "registered": "2016-06-03T03:41:45 -02:00",
    "latitude": 62.067073,
    "longitude": 115.363007,
    "tags": [
      "do",
      "laboris",
      "laborum",
      "deserunt",
      "eu",
      "fugiat",
      "non"
    ],
    "friends": [
      {
        "id": 0,
        "name": "Oconnor Fisher"
      },
      {
        "id": 1,
        "name": "Robbins Davis"
      },
      {
        "id": 2,
        "name": "Rollins Brooks"
      }
    ],
    "greeting": "Hello, Minnie Goodwin! You have 10 unread messages.",
    "favoriteFruit": "banana"
  },
  {
    "_id": "5916ab747863a79d58240d44",
    "index": 3,
    "guid": "ae93261d-55be-4bb9-8a69-9b8f545a02e2",
    "isActive": false,
    "balance": "$2,098.44",
    "picture": "http://placehold.it/32x32",
    "age": 28,
    "eyeColor": "green",
    "name": "Maxwell Flynn",
    "gender": "male",
    "company": "MYOPIUM",
    "email": "maxwellflynn@myopium.com",
    "phone": "+1 (804) 510-2371",
    "address": "774 Rockaway Avenue, Roy, Kansas, 174",
    "about": "Duis ex sunt ullamco sunt deserunt adipisicing irure quis labore ex occaecat laborum. Aliqua dolor nisi pariatur elit. Mollit eiusmod proident cupidatat aliquip ut dolore esse.\r\n",
    "registered": "2015-12-03T11:49:42 -01:00",
    "latitude": -78.593105,
    "longitude": -128.314445,
    "tags": [
      "aliqua",
      "consequat",
      "quis",
      "minim",
      "adipisicing",
      "nisi",
      "deserunt"
    ],
    "friends": [
      {
        "id": 0,
        "name": "Roach Downs"
      },
      {
        "id": 1,
        "name": "Evangeline Woodward"
      },
      {
        "id": 2,
        "name": "Mia Aguirre"
      }
    ],
    "greeting": "Hello, Maxwell Flynn! You have 1 unread messages.",
    "favoriteFruit": "banana"
  },
  {
    "_id": "5916ab7462aaf97f64876644",
    "index": 4,
    "guid": "6f1e7bc6-2370-47d2-8287-f2d6106a56e3",
    "isActive": false,
    "balance": "$1,198.72",
    "picture": "http://placehold.it/32x32",
    "age": 21,
    "eyeColor": "green",
    "name": "Sims Sykes",
    "gender": "male",
    "company": "ZAGGLES",
    "email": "simssykes@zaggles.com",
    "phone": "+1 (895) 512-3678",
    "address": "941 Luquer Street, Winfred, Rhode Island, 2640",
    "about": "Voluptate duis minim aute culpa in id dolor dolore laborum voluptate non. Enim ea adipisicing sint labore excepteur et aute laborum in eu culpa et aute consequat. Veniam labore labore elit quis id deserunt proident dolore nisi do non.\r\n",
    "registered": "2017-02-02T01:35:15 -01:00",
    "latitude": -61.994374,
    "longitude": -90.596461,
    "tags": [
      "occaecat",
      "adipisicing",
      "voluptate",
      "cupidatat",
      "irure",
      "ut",
      "ut"
    ],
    "friends": [
      {
        "id": 0,
        "name": "Copeland Zimmerman"
      },
      {
        "id": 1,
        "name": "Mack Blake"
      },
      {
        "id": 2,
        "name": "Mae Terry"
      }
    ],
    "greeting": "Hello, Sims Sykes! You have 1 unread messages.",
    "favoriteFruit": "banana"
  }
]
__[ ok / from https://www.getpostman.com/samples/test_data_file.json ]__
[
	{
		"profile_url": "http://www.google.com",
		"username": "a85",
		"password": "blah"
	},
	{
		"profile_url": "http://www.getpostman.com",
		"username": "larry",
		"password": "nocolors"
	}
]
__[ ok / from http://civicdataprod4.cloudapp.net/storage/f/2015-06-29T09%3A51%3A00.364Z/amersfoort-baten-2014-v2.json ]__
{
  "name": "Baten",
  "src": "",
  "hash": "d77751d47b47b010cc72a08dff9dccc2",
  "children": [
    {
      "name": "Bestuur en dienstverlening",
      "src": "",
      "hash": "1610fb45a9367bd09b270e27032a7daf",
      "children": [
        {
          "name": "Algemeen Bestuur",
          "src": "",
          "hash": "f89714b880287c5b7fc530ab1634215c",
          "children": [],
          "descr": "",
          "url": "/node/396",
          "values": [
            {
              "val": 474,
              "year": 2013
            },
            {
              "val": 1081,
              "year": 2014
            },
            {
              "val": 661,
              "year": 2015
            },
            {
              "val": 508,
              "year": 2016
            },
            {
              "val": 508,
              "year": 2017
            },
            {
              "val": 508,
              "year": 2018
            }
          ]
        },
        {
          "name": "Publieke dienstverlening",
          "src": "",
          "hash": "8969ff9c17d7d687c7a4c366d146a23c",
          "children": [],
          "descr": "",
          "url": "/node/400",
          "values": [
            {
              "val": 2504,
              "year": 2013
            },
            {
              "val": 2788,
              "year": 2014
            },
            {
              "val": 2601,
              "year": 2015
            },
            {
              "val": 2609,
              "year": 2016
            },
            {
              "val": 2606,
              "year": 2017
            },
            {
              "val": 2603,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/394",
      "values": [
        {
          "val": 3251,
          "year": 2013
        },
        {
          "val": 3869,
          "year": 2014
        },
        {
          "val": 3262,
          "year": 2015
        },
        {
          "val": 3117,
          "year": 2016
        },
        {
          "val": 3114,
          "year": 2017
        },
        {
          "val": 3111,
          "year": 2018
        }
      ]
    },
    {
      "name": "Veiligheid en handhaving",
      "src": "",
      "hash": "2c1d096ae1051bf7a20c96f89ab7cc52",
      "children": [
        {
          "name": "Fysieke veiligheid",
          "src": "",
          "hash": "3931929e00dfa468862a4789d93a35a5",
          "children": [],
          "descr": "",
          "url": "/node/60",
          "values": [
            {
              "val": 52,
              "year": 2013
            },
            {
              "val": 80,
              "year": 2014
            },
            {
              "val": 0,
              "year": 2015
            },
            {
              "val": 0,
              "year": 2016
            },
            {
              "val": 0,
              "year": 2017
            },
            {
              "val": 0,
              "year": 2018
            }
          ]
        },
        {
          "name": "Sociale veiligheid",
          "src": "",
          "hash": "02b0a37f900c89023362418c7390b6f9",
          "children": [],
          "descr": "",
          "url": "/node/59",
          "values": [
            {
              "val": 137,
              "year": 2013
            },
            {
              "val": 177,
              "year": 2014
            },
            {
              "val": 88,
              "year": 2015
            },
            {
              "val": 88,
              "year": 2016
            },
            {
              "val": 88,
              "year": 2017
            },
            {
              "val": 88,
              "year": 2018
            }
          ]
        },
        {
          "name": "Vergunningen, toezicht en handhaving",
          "src": "",
          "hash": "391721036334fcb538f3cc8483196d11",
          "children": [],
          "descr": "",
          "url": "/node/61",
          "values": [
            {
              "val": 2576,
              "year": 2013
            },
            {
              "val": 2542,
              "year": 2014
            },
            {
              "val": 2594,
              "year": 2015
            },
            {
              "val": 2749,
              "year": 2016
            },
            {
              "val": 2786,
              "year": 2017
            },
            {
              "val": 2771,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/3",
      "values": [
        {
          "val": 2765,
          "year": 2013
        },
        {
          "val": 2799,
          "year": 2014
        },
        {
          "val": 2682,
          "year": 2015
        },
        {
          "val": 2837,
          "year": 2016
        },
        {
          "val": 2874,
          "year": 2017
        },
        {
          "val": 2859,
          "year": 2018
        }
      ]
    },
    {
      "name": "Stedelijk beheer en milieu",
      "src": "",
      "hash": "fd4063fce130f09f6d5a7b5745a8183a",
      "children": [
        {
          "name": "Milieu",
          "src": "",
          "hash": "9f77a74151de148a67f2066b03af8e9f",
          "children": [],
          "descr": "",
          "url": "/node/63",
          "values": [
            {
              "val": 516,
              "year": 2013
            },
            {
              "val": 621,
              "year": 2014
            },
            {
              "val": 216,
              "year": 2015
            },
            {
              "val": 216,
              "year": 2016
            },
            {
              "val": 216,
              "year": 2017
            },
            {
              "val": 216,
              "year": 2018
            }
          ]
        },
        {
          "name": "Stedelijk beheer",
          "src": "",
          "hash": "97b6e927d78c80f4de4f47d5a05943dd",
          "children": [],
          "descr": "",
          "url": "/node/62",
          "values": [
            {
              "val": 6331,
              "year": 2013
            },
            {
              "val": 6445,
              "year": 2014
            },
            {
              "val": 5491,
              "year": 2015
            },
            {
              "val": 5852,
              "year": 2016
            },
            {
              "val": 5864,
              "year": 2017
            },
            {
              "val": 5875,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/4",
      "values": [
        {
          "val": 6847,
          "year": 2013
        },
        {
          "val": 7066,
          "year": 2014
        },
        {
          "val": 5707,
          "year": 2015
        },
        {
          "val": 6068,
          "year": 2016
        },
        {
          "val": 6080,
          "year": 2017
        },
        {
          "val": 6091,
          "year": 2018
        }
      ]
    },
    {
      "name": "Sociaal Domein",
      "src": "",
      "hash": "fe67741108ccd4d6386fb5bdf067037e",
      "children": [
        {
          "name": "Basisinfrastructuur",
          "src": "",
          "hash": "effc7598eb164cd721b7ce9549bb15dd",
          "children": [],
          "descr": "",
          "url": "node/64",
          "values": [
            {
              "val": 3435,
              "year": 2013
            },
            {
              "val": 3332,
              "year": 2014
            },
            {
              "val": 405,
              "year": 2015
            },
            {
              "val": 405,
              "year": 2016
            },
            {
              "val": 405,
              "year": 2017
            },
            {
              "val": 405,
              "year": 2018
            }
          ]
        },
        {
          "name": "Ambulante zorg en ondersteuning, incl. wijkteams",
          "src": "",
          "hash": "7063ca25e52718ca4d0c357809558933",
          "children": [],
          "descr": "",
          "url": "/node/65",
          "values": [
            {
              "val": 208,
              "year": 2013
            },
            {
              "val": 433,
              "year": 2014
            },
            {
              "val": 0,
              "year": 2015
            },
            {
              "val": 0,
              "year": 2016
            },
            {
              "val": 0,
              "year": 2017
            },
            {
              "val": 0,
              "year": 2018
            }
          ]
        },
        {
          "name": "Specialistische zorg en ondersteuning",
          "src": "",
          "hash": "c231b458d7170e2cdc7cc9250124c011",
          "children": [],
          "descr": "",
          "url": "/node/66",
          "values": [
            {
              "val": 2199,
              "year": 2013
            },
            {
              "val": 2338,
              "year": 2014
            },
            {
              "val": 2551,
              "year": 2015
            },
            {
              "val": 2551,
              "year": 2016
            },
            {
              "val": 2551,
              "year": 2017
            },
            {
              "val": 2551,
              "year": 2018
            }
          ]
        },
        {
          "name": "Werk en inkomen",
          "src": "",
          "hash": "b9f9bff4a32e1431a26d5aadf9533359",
          "children": [],
          "descr": "",
          "url": "/node/68",
          "values": [
            {
              "val": 71987,
              "year": 2013
            },
            {
              "val": 78794,
              "year": 2014
            },
            {
              "val": 45367,
              "year": 2015
            },
            {
              "val": 48108,
              "year": 2016
            },
            {
              "val": 49955,
              "year": 2017
            },
            {
              "val": 51793,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/93",
      "values": [
        {
          "val": 77829,
          "year": 2013
        },
        {
          "val": 84897,
          "year": 2014
        },
        {
          "val": 48323,
          "year": 2015
        },
        {
          "val": 51064,
          "year": 2016
        },
        {
          "val": 52911,
          "year": 2017
        },
        {
          "val": 54749,
          "year": 2018
        }
      ]
    },
    {
      "name": "Onderwijs",
      "src": "",
      "hash": "90891af463a6ae7b0eb8fc5fc9354fcf",
      "children": [
        {
          "name": "Onderwijsbeleid",
          "src": "",
          "hash": "9c941e307856a84b0b9397b81f712436",
          "children": [],
          "descr": "",
          "url": "/node/69",
          "values": [
            {
              "val": 5193,
              "year": 2013
            },
            {
              "val": 7251,
              "year": 2014
            },
            {
              "val": 5398,
              "year": 2015
            },
            {
              "val": 5398,
              "year": 2016
            },
            {
              "val": 5398,
              "year": 2017
            },
            {
              "val": 5398,
              "year": 2018
            }
          ]
        },
        {
          "name": "Onderwijsvoorzieningen",
          "src": "",
          "hash": "6a5e6bbd0961690d20262ed49d514dee",
          "children": [],
          "descr": "",
          "url": "/node/70",
          "values": [
            {
              "val": 135,
              "year": 2013
            },
            {
              "val": 47,
              "year": 2014
            },
            {
              "val": 0,
              "year": 2015
            },
            {
              "val": 0,
              "year": 2016
            },
            {
              "val": 0,
              "year": 2017
            },
            {
              "val": 0,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/8",
      "values": [
        {
          "val": 5328,
          "year": 2013
        },
        {
          "val": 7298,
          "year": 2014
        },
        {
          "val": 5398,
          "year": 2015
        },
        {
          "val": 5398,
          "year": 2016
        },
        {
          "val": 5398,
          "year": 2017
        },
        {
          "val": 5398,
          "year": 2018
        }
      ]
    },
    {
      "name": "Sport",
      "src": "",
      "hash": "96faa3e6c45bb5a07bcc0bcd3be37654",
      "children": [],
      "descr": "",
      "url": "/node/25",
      "values": [
        {
          "val": 341,
          "year": 2013
        },
        {
          "val": 0,
          "year": 2014
        },
        {
          "val": 0,
          "year": 2015
        },
        {
          "val": 0,
          "year": 2016
        },
        {
          "val": 0,
          "year": 2017
        },
        {
          "val": 0,
          "year": 2018
        }
      ]
    },
    {
      "name": "Ruimtelijke ontwikkeling",
      "src": "",
      "hash": "ac1db057f8c2d63ecd25e7c8dfe8e9ab",
      "children": [
        {
          "name": "Ruimtelijke ontwikkeling (incl. Groene Stad)",
          "src": "",
          "hash": "16317859876c0910553e1ff721dc89a0",
          "children": [],
          "descr": "",
          "url": "/node/72",
          "values": [
            {
              "val": 128,
              "year": 2013
            },
            {
              "val": 136,
              "year": 2014
            },
            {
              "val": 0,
              "year": 2015
            },
            {
              "val": 30,
              "year": 2016
            },
            {
              "val": 30,
              "year": 2017
            },
            {
              "val": 30,
              "year": 2018
            }
          ]
        },
        {
          "name": "Grondexplotaties",
          "src": "",
          "hash": "b044e6565b82f89cb82bdc74d7e82055",
          "children": [],
          "descr": "",
          "url": "/node/73",
          "values": [
            {
              "val": 61018,
              "year": 2013
            },
            {
              "val": 36645,
              "year": 2014
            },
            {
              "val": 34808,
              "year": 2015
            },
            {
              "val": 43836,
              "year": 2016
            },
            {
              "val": 31340,
              "year": 2017
            },
            {
              "val": 29982,
              "year": 2018
            }
          ]
        },
        {
          "name": "Vastgoed",
          "src": "",
          "hash": "d3d37a3b55f883e6a945768cb3b7afde",
          "children": [],
          "descr": "",
          "url": "/node/74",
          "values": [
            {
              "val": 1172,
              "year": 2013
            },
            {
              "val": 7763,
              "year": 2014
            },
            {
              "val": 7070,
              "year": 2015
            },
            {
              "val": 5096,
              "year": 2016
            },
            {
              "val": 8736,
              "year": 2017
            },
            {
              "val": 5417,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/26",
      "values": [
        {
          "val": 62318,
          "year": 2013
        },
        {
          "val": 44544,
          "year": 2014
        },
        {
          "val": 41878,
          "year": 2015
        },
        {
          "val": 48962,
          "year": 2016
        },
        {
          "val": 40106,
          "year": 2017
        },
        {
          "val": 35429,
          "year": 2018
        }
      ]
    },
    {
      "name": "Wijken en wonen",
      "src": "",
      "hash": "0e702381ae4983a78aacfe6d1b3afcf7",
      "children": [
        {
          "name": "Wijken",
          "src": "",
          "hash": "deb839f39bd543d70285a457334eb26e",
          "children": [],
          "descr": "",
          "url": "/node/75",
          "values": [
            {
              "val": 42,
              "year": 2013
            },
            {
              "val": 626,
              "year": 2014
            },
            {
              "val": 0,
              "year": 2015
            },
            {
              "val": 45,
              "year": 2016
            },
            {
              "val": 45,
              "year": 2017
            },
            {
              "val": 45,
              "year": 2018
            }
          ]
        },
        {
          "name": "Wonen",
          "src": "",
          "hash": "eb6a63dbb29181e9b4dfa8df50fa840b",
          "children": [],
          "descr": "",
          "url": "/node/76",
          "values": [
            {
              "val": 514,
              "year": 2013
            },
            {
              "val": 397,
              "year": 2014
            },
            {
              "val": 479,
              "year": 2015
            },
            {
              "val": 479,
              "year": 2016
            },
            {
              "val": 479,
              "year": 2017
            },
            {
              "val": 479,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/27",
      "values": [
        {
          "val": 556,
          "year": 2013
        },
        {
          "val": 1023,
          "year": 2014
        },
        {
          "val": 479,
          "year": 2015
        },
        {
          "val": 524,
          "year": 2016
        },
        {
          "val": 524,
          "year": 2017
        },
        {
          "val": 524,
          "year": 2018
        }
      ]
    },
    {
      "name": "Mobiliteit",
      "src": "",
      "hash": "524c3bd5ac2aa64333c048122e8dd873",
      "children": [],
      "descr": "",
      "url": "/node/402",
      "values": [
        {
          "val": 4696,
          "year": 2013
        },
        {
          "val": 4597,
          "year": 2014
        },
        {
          "val": 4585,
          "year": 2015
        },
        {
          "val": 3031,
          "year": 2016
        },
        {
          "val": 3031,
          "year": 2017
        },
        {
          "val": 3031,
          "year": 2018
        }
      ]
    },
    {
      "name": "Economie en duurzaamheid",
      "src": "",
      "hash": "c9f5a622fb26fde542d11e5327d97031",
      "children": [
        {
          "name": "Economie",
          "src": "",
          "hash": "3fff9c67f53b7387ef8b7e91f162bf05",
          "children": [],
          "descr": "",
          "url": "/node/78",
          "values": [
            {
              "val": 999,
              "year": 2013
            },
            {
              "val": 566,
              "year": 2014
            },
            {
              "val": 484,
              "year": 2015
            },
            {
              "val": 484,
              "year": 2016
            },
            {
              "val": 484,
              "year": 2017
            },
            {
              "val": 484,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/29",
      "values": [
        {
          "val": 999,
          "year": 2013
        },
        {
          "val": 566,
          "year": 2014
        },
        {
          "val": 484,
          "year": 2015
        },
        {
          "val": 484,
          "year": 2016
        },
        {
          "val": 484,
          "year": 2017
        },
        {
          "val": 484,
          "year": 2018
        }
      ]
    },
    {
      "name": "Cultuur",
      "src": "",
      "hash": "1486fa2aa7c2444e0b41c4f9d77c6447",
      "children": [
        {
          "name": "Archief Eemland",
          "src": "",
          "hash": "9b1540d37f221beb647bc704b95d17f4",
          "children": [],
          "descr": "",
          "url": "/node/80",
          "values": [
            {
              "val": 208,
              "year": 2013
            },
            {
              "val": 292,
              "year": 2014
            },
            {
              "val": 272,
              "year": 2015
            },
            {
              "val": 272,
              "year": 2016
            },
            {
              "val": 272,
              "year": 2017
            },
            {
              "val": 272,
              "year": 2018
            }
          ]
        },
        {
          "name": "Monumentenzorg en archeologie",
          "src": "",
          "hash": "3f35adb04ccea457ed204c9772f77d97",
          "children": [],
          "descr": "",
          "url": "/node/81",
          "values": [
            {
              "val": 0,
              "year": 2013
            },
            {
              "val": 0,
              "year": 2014
            },
            {
              "val": 0,
              "year": 2015
            },
            {
              "val": 0,
              "year": 2016
            },
            {
              "val": 0,
              "year": 2017
            },
            {
              "val": 0,
              "year": 2018
            }
          ]
        },
        {
          "name": "Kunst en cultuur",
          "src": "",
          "hash": "2ec778f53f04e518adf0ca5240356d94",
          "children": [],
          "descr": "",
          "url": "/node/82",
          "values": [
            {
              "val": 1020,
              "year": 2013
            },
            {
              "val": 104,
              "year": 2014
            },
            {
              "val": 395,
              "year": 2015
            },
            {
              "val": 395,
              "year": 2016
            },
            {
              "val": 395,
              "year": 2017
            },
            {
              "val": 395,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/30",
      "values": [
        {
          "val": 1228,
          "year": 2013
        },
        {
          "val": 396,
          "year": 2014
        },
        {
          "val": 667,
          "year": 2015
        },
        {
          "val": 667,
          "year": 2016
        },
        {
          "val": 667,
          "year": 2017
        },
        {
          "val": 667,
          "year": 2018
        }
      ]
    },
    {
      "name": "FinanciÃ«n en belastingen",
      "src": "",
      "hash": "1486fa2aa7c24bkdbkdjf4f9d77c6447",
      "children": [
        {
          "name": "Algemene baten en lasten",
          "src": "",
          "hash": "2e435290dd59e41dc185f0b4c05fce44",
          "children": [],
          "descr": "",
          "url": "/node/83",
          "values": [
            {
              "val": 7604,
              "year": 2013
            },
            {
              "val": 3855,
              "year": 2014
            },
            {
              "val": 2054,
              "year": 2015
            },
            {
              "val": 3477,
              "year": 2016
            },
            {
              "val": 3680,
              "year": 2017
            },
            {
              "val": 3716,
              "year": 2018
            }
          ]
        },
        {
          "name": "Algemene uitkering gemeentefonds",
          "src": "",
          "hash": "cf99f4c0f1b3b2ef68d4eb56e9f80908",
          "children": [],
          "descr": "",
          "url": "/node/84",
          "values": [
            {
              "val": 154700,
              "year": 2013
            },
            {
              "val": 159482,
              "year": 2014
            },
            {
              "val": 262875,
              "year": 2015
            },
            {
              "val": 264035,
              "year": 2016
            },
            {
              "val": 258356,
              "year": 2017
            },
            {
              "val": 255008,
              "year": 2018
            }
          ]
        },
        {
          "name": "Belastingen en heffingen",
          "src": "",
          "hash": "a66da16290589d25e1cb532a8d539cda",
          "children": [],
          "descr": "",
          "url": "/node/86",
          "values": [
            {
              "val": 56396,
              "year": 2013
            },
            {
              "val": 60447,
              "year": 2014
            },
            {
              "val": 61338,
              "year": 2015
            },
            {
              "val": 68112,
              "year": 2016
            },
            {
              "val": 68880,
              "year": 2017
            },
            {
              "val": 72212,
              "year": 2018
            }
          ]
        },
        {
          "name": "Geldleningen en beleggingen",
          "src": "",
          "hash": "102fa682a551d74249233c71a1bbfa7b",
          "children": [],
          "descr": "",
          "url": "/node/85",
          "values": [
            {
              "val": 25344,
              "year": 2013
            },
            {
              "val": 25520,
              "year": 2014
            },
            {
              "val": 16472,
              "year": 2015
            },
            {
              "val": 12883,
              "year": 2016
            },
            {
              "val": 12688,
              "year": 2017
            },
            {
              "val": 12236,
              "year": 2018
            }
          ]
        }
      ],
      "descr": "",
      "url": "/node/47",
      "values": [
        {
          "val": 244044,
          "year": 2013
        },
        {
          "val": 249304,
          "year": 2014
        },
        {
          "val": 342739,
          "year": 2015
        },
        {
          "val": 348507,
          "year": 2016
        },
        {
          "val": 343604,
          "year": 2017
        },
        {
          "val": 343172,
          "year": 2018
        }
      ]
    }
  ],
  "descr": "",
  "url": ""
}
__[ ok / from https://github.com/json-schema-org/JSON-Schema-Test-Suite/blob/master/tests/draft6/optional/ecmascript-regex.json ]__
[
    {
        "description": "ECMA 262 regex non-compliance",
        "schema": { "format": "regex" },
        "tests": [
            {
                "description": "ECMA 262 has no support for \\Z anchor from .NET",
                "data": "^\\S(|(.|\\n)*\\S)\\Z",
                "valid": false
            }
        ]
    }
]
__[ ok / from https://github.com/codemeta/codemeta/blob/master/examples/codemeta-v2.json ]__
{
    "@context": "https://raw.githubusercontent.com/codemeta/codemeta/master/codemeta-v2.jsonld",
    "title": "Generate CodeMeta Metadata for R Packages",
    "description": "Codemeta defines a 'JSON-LD' format for describing software metadata. This package provides utilities to generate, parse, and modify codemeta.jsonld files automatically for R packages.",
    "identifier": "http://dx.doi.org/10.5281/zenodo.XXXX",
    "name": "codemeta",
    "@type": "SoftwareSourceCode",
    "author": [{
        "@id": "http://orcid.org/0000-0002-2192-403X",
        "@type": "Person",
        "email": "slaughter@nceas.ucsb.edu",
        "givenName": "Peter",
        "familyName":  "Slaughter",
        "affiliation": "NCEAS"
    },
    {
        "@id": "http://orcid.org/0000-0003-0077-4738",
        "@type": "Person",
        "givenName": "Matthew",
        "familyName": "Jones",
        "affiliation": "NCEAS"
    },
    {
        "@id": "http://orcid.org/0000-0002-1642-628X",
        "@type": "Person",
        "givenName": "Carl",
        "familyName": "Boettiger",
        "email": "cobettig@gmail.com",
        "affiliation": "UC Berkeley"
    }
    ],
    "copyrightHolder": {
        "@type": "Organization",
        "email": "info@ucop.edu",
        "name": "University of California, Santa Barbara"
    },

    "codeRepository": "https://github.com/codemeta/codemetar",
    "datePublished": "2014-09-06",
    "dateModified": "2014-08-15",
    "dateCreated": "2014-08-06",
    "publisher": "zenodo",
    "keywords": [
        "publishing",
        "DOI",
        "credit for code"
    ],
    "license": "https://opensource.org/licenses/BSD-2-Clause",
    "version": "0.1.0",

    "programmingLanguage": {
        "name": "R",
        "URL": "https://www.r-project.org"
    },
    "downloadUrl": "https://github.com/codemeta/codemetar/releases/",

    "softwareRequirements": [{
      "@id": "https://cran.r-project.org/package=jsonlite"
    }],



    "maintainer": {
      "@id": "http://orcid.org/0000-0002-1642-628X"
    },
    "developmentStatus": "active",
    "embargoDate": "2014-08-06T10:00:01Z",
    "contIntegration": "https://travis.org/codemeta/codemetar",
    "funding": "National Science Foundation grant #012345678",
    "readme": "https://github.com/codemeta/codemeta/README.md",
    "issueTracker": "https://github.com/codemetar/codemetar/issues",
    "relatedLink": "https://github.com/codemeta/codemeta-paper",
    "relatedPublications": [
      "http://doi.org/10.1177/0165551504045850",
      "http://doi.org/10.1145/2815833.2816955"
    ],
    "relationships": {
        "relationshipType": "isPartOf",
        "relatedIdentifier": "urn:uuid:F1A0A7AF-ECF3-4C7D-B675-7C6949963995",
        "relatedIdentifierType": "UUID"
    },
    "softwarePaperCitationIdentifiers": "http://doi.org/0000/0000",
    "suggests": [
      { "@id": "https://cran.r-project.org/package=jsonld"},
      { "@id": "https://cran.r-project.org/package=testthat"},
      {
        "@id": "https://cran.r-project.org/package=rmarkdown",
        "@type": "Code"
      }
    ]
}
__[ ok / from https://github.com/codemeta/codemeta/blob/master/examples/example-codemeta-invalid.json ]__
{
   "@context":"https://raw.githubusercontent.com/codemeta/codemeta/master/codemeta.jsonld",
   "_not_in_schema": "This invalid JSON name should cause an error when using JSON-LD expand/compact",
   "_description": "This JSON file is used in the Travis CI tests to ensure invalid JSON names are detected during JSON-LD expand / compact operations"
}
__[ ok / from http://www.jsonrpc.org/specification / rpc call with positional parameters ]__
{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}
__[ ok / from http://www.jsonrpc.org/specification / rpc call with named parameters ]__
{"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}
__[ ok / from http://www.jsonrpc.org/specification / a Notification ]__
{"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}
__[ ko / from http://www.jsonrpc.org/specification / rpc call with invalid JSON ]__
{"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]
__[ ok / from http://www.jsonrpc.org/specification / rpc call with invalid Request object ]__
{"jsonrpc": "2.0", "method": 1, "params": "bar"}
__[ ko / from http://php.net/manual/fr/function.json-decode.php / invalid example 01 ]__
{ 'bar': 'baz' }
__[ ko / from http://php.net/manual/fr/function.json-decode.php / invalid example 02 ]__
{ bar: "baz" }
__[ ko / from http://php.net/manual/fr/function.json-decode.php / invalid example 03 ]__
{ bar: "baz", }
__[ ko / from http://ryanmarcus.github.io/dirty-json/ ]__
{ "key": "<div class="coolCSS">some text</div>" }
