#---------------------------------------------------------------------
# MARC-Utils-MARC2Pairs.t

use Test::More tests => 3;
BEGIN {
    use_ok('MARC::Utils::MARC2Pairs', qw( marc2pairs pairs2marc ) );
}

# loaded in BEGIN blocks below ...
my $pairs;
my $marc_as_formatted;

my $marc_record  = pairs2marc( $pairs );
is( $marc_record->as_formatted(), $marc_as_formatted, "marc_record->as_formatted" );

# round trips
$pairs = marc2pairs( $marc_record );

$marc_record = pairs2marc( $pairs );
is( $marc_record->as_formatted(), $marc_as_formatted, "marc_record->as_formatted (round trip)" );

#---------------------------------------------------------------------
BEGIN {
    $pairs =
    [
        { "leader" => "01471cjm a2200349 a 4500" },
        { "001" => "5674874" },
        { "005" => "20030305110405.0" },
        { "007" => "sdubsmennmplu" },
        { "008" => "930331s1963    nyuppn              eng d" },
        { "035" =>
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "9" => "(DLC)   93707283" }
            ]
        },
        { "906" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "7" },
                { "b" => "cbc" },
                { "c" => "copycat" },
                { "d" => "4" },
                { "e" => "ncip" },
                { "f" => "19" },
                { "g" => "y-soundrec" }
            ]
        },
        { "010" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "   93707283 " }
            ]
        },
        { "028" => 
            [
                { "ind1" => "0" },
                { "ind2" => "2" },
                { "a" => "CS 8786" },
                { "b" => "Columbia" }
            ]
        },
        { "035" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "(OCoLC)13083787" }
            ]
        },
        { "040" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "OClU" },
                { "c" => "DLC" },
                { "d" => "DLC" }
            ]
        },
        { "041" => 
            [
                { "ind1" => "0" },
                { "ind2" => " " },
                { "d" => "eng" },
                { "g" => "eng" }
            ]
        },
        { "042" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "lccopycat" }
            ]
        },
        { "050" => 
            [
                { "ind1" => "0" },
                { "ind2" => "0" },
                { "a" => "Columbia CS 8786" }
            ]
        },
        { "100" => 
            [
                { "ind1" => "1" },
                { "ind2" => " " },
                { "a" => "Dylan, Bob," },
                { "d" => "1941-" }
            ]
        },
        { "245" => 
            [
                { "ind1" => "1" },
                { "ind2" => "4" },
                { "a" => "The freewheelin' Bob Dylan" },
                { "h" => "[sound recording]." }
            ]
        },
        { "260" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "[New York, N.Y.] :" },
                { "b" => "Columbia," },
                { "c" => "[1963]" }
            ]
        },
        { "300" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "1 sound disc :" },
                { "b" => "analog, 33 1/3 rpm, stereo. ;" },
                { "c" => "12 in." }
            ]
        },
        { "500" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "Songs." }
            ]
        },
        { "511" => 
            [
                { "ind1" => "0" },
                { "ind2" => " " },
                { "a" => "The composer accompanying himself on the guitar ; in part with instrumental ensemble." }
            ]
        },
        { "500" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "Program notes by Nat Hentoff on container." }
            ]
        },
        { "505" => 
            [
                { "ind1" => "0" },
                { "ind2" => " " },
                { "a" => "Blowin' in the wind -- Girl from the north country -- Masters of war -- Down the highway -- Bob Dylan's blues -- A hard rain's a-gonna fall -- Don't think twice, it's all right -- Bob Dylan's dream -- Oxford town -- Talking World War III blues -- Corrina, Corrina -- Honey, just allow me one more chance -- I shall be free." }
            ]
        },
        { "650" => 
            [
                { "ind1" => " " },
                { "ind2" => "0" },
                { "a" => "Popular music" },
                { "y" => "1961-1970." }
            ]
        },
        { "650" => 
            [
                { "ind1" => " " },
                { "ind2" => "0" },
                { "a" => "Blues (Music)" },
                { "y" => "1961-1970." }
            ]
        },
        { "856" => 
            [
                { "ind1" => "4" },
                { "ind2" => "1" },
                { "3" => "Preservation copy (limited access)" },
                { "u" => "http://hdl.loc.gov/loc.mbrsrs/lp0001.dyln" }
            ]
        },
        { "952" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "New" }
            ]
        },
        { "953" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "a" => "TA28" }
            ]
        },
        { "991" => 
            [
                { "ind1" => " " },
                { "ind2" => " " },
                { "b" => "c-RecSound" },
                { "h" => "Columbia CS 8786" },
                { "w" => "MUSIC" }
            ]
        }
    ];
    $marc_as_formatted = <<'_end_';
LDR 01471cjm a2200349 a 4500
001     5674874
005     20030305110405.0
007     sdubsmennmplu
008     930331s1963    nyuppn              eng d
035    _9(DLC)   93707283
906    _a7
       _bcbc
       _ccopycat
       _d4
       _encip
       _f19
       _gy-soundrec
010    _a   93707283 
028 02 _aCS 8786
       _bColumbia
035    _a(OCoLC)13083787
040    _aOClU
       _cDLC
       _dDLC
041 0  _deng
       _geng
042    _alccopycat
050 00 _aColumbia CS 8786
100 1  _aDylan, Bob,
       _d1941-
245 14 _aThe freewheelin' Bob Dylan
       _h[sound recording].
260    _a[New York, N.Y.] :
       _bColumbia,
       _c[1963]
300    _a1 sound disc :
       _banalog, 33 1/3 rpm, stereo. ;
       _c12 in.
500    _aSongs.
511 0  _aThe composer accompanying himself on the guitar ; in part with instrumental ensemble.
500    _aProgram notes by Nat Hentoff on container.
505 0  _aBlowin' in the wind -- Girl from the north country -- Masters of war -- Down the highway -- Bob Dylan's blues -- A hard rain's a-gonna fall -- Don't think twice, it's all right -- Bob Dylan's dream -- Oxford town -- Talking World War III blues -- Corrina, Corrina -- Honey, just allow me one more chance -- I shall be free.
650  0 _aPopular music
       _y1961-1970.
650  0 _aBlues (Music)
       _y1961-1970.
856 41 _3Preservation copy (limited access)
       _uhttp://hdl.loc.gov/loc.mbrsrs/lp0001.dyln
952    _aNew
953    _aTA28
991    _bc-RecSound
       _hColumbia CS 8786
       _wMUSIC
_end_

    chomp $marc_as_formatted;
}

__END__

example JSON object from:

http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/

(Note that perceived errors in this example have been corrected above.)

{
    "leader":"01471cjm a2200349 a 4500",
    "fields":
    [
        {
            "001":"5674874"
        },
        {
            "005":"20030305110405.0"
        },
        {
            "007":"sdubsmennmplu"
        },
        {
            "008":"930331s1963    nyuppn              eng d"
        },
        {
            "035":
            {
                "subfields":
                [
                    {
                        "9":"(DLC)   93707283"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "906":
            {
                "subfields":
                [
                    {
                        "a":"7"
                    },
                    {
                        "b":"cbc"
                    },
                    {
                        "c":"copycat"
                    },
                    {
                        "d":"4"
                    },
                    {
                        "e":"ncip"
                    },
                    {
                        "f":"19"
                    },
                    {
                        "g":"y-soundrec"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "010":
            {
                "subfields":
                [
                    {
                        "a":"   93707283 "
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "028":
            {
                "subfields":
                [
                    {
                        "a":"CS 8786"
                    },
                    {
                        "b":"Columbia"
                    }
                ],
                "ind1":"0",
                "ind2":"2"
            }
        },
        {
            "035":
            {
                "subfields":
                [
                    {
                        "a":"(OCoLC)13083787"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "040":
            {
                "subfields":
                [
                    {
                        "a":"OClU"
                    },
                    {
                        "c":"DLC"
                    },
                    {
                        "d":"DLC"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "041":
            {
                "subfields":
                [
                    {
                        "d":"eng"
                    },
                    {
                        "g":"eng"
                    }
                ],
                "ind1":"0",
                "ind2":" "
            }
        },
        {
            "042":
            {
                "subfields":
                [
                    {
                        "a":"lccopycat"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "050":
            {
                "subfields":
                [
                    {
                        "a":"Columbia CS 8786"
                    }
                ],
                "ind1":"0",
                "ind2":"0"
            }
        },
        {
            "100":
            {
                "subfields":
                [
                    {
                        "a":"Dylan,
                         Bob,
                        "
                    },
                    {
                        "d":"1941-"
                    }
                ],
                "ind1":"1",
                "ind2":" "
            }
        },
        {
            "245":
            {
                "subfields":
                [
                    {
                        "a":"The freewheelin' Bob Dylan"
                    },
                    {
                        "h":"
                        [
                            sound recording
                        ]
                        ."
                    }
                ],
                "ind1":"1",
                "ind2":"4"
            }
        },
        {
            "260":
            {
                "subfields":
                [
                    {
                        "a":"
                        [
                            New York,
                             N.Y.
                        ]
                         :"
                    },
                    {
                        "b":"Columbia,
                        "
                    },
                    {
                        "c":"
                        [
                            1963
                        ]
                        "
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "300":
            {
                "subfields":
                [
                    {
                        "a":"1 sound disc :"
                    },
                    {
                        "b":"analog,
                         33 1/3 rpm,
                         stereo. ;"
                    },
                    {
                        "c":"12 in."
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "500":
            {
                "subfields":
                [
                    {
                        "a":"Songs."
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "511":
            {
                "subfields":
                [
                    {
                        "a":"The composer accompanying himself on the guitar ; in part with instrumental ensemble."
                    }
                ],
                "ind1":"0",
                "ind2":" "
            }
        },
        {
            "500":
            {
                "subfields":
                [
                    {
                        "a":"Program notes by Nat Hentoff on container."
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "505":
            {
                "subfields":
                [
                    {
                        "a":"Blowin' in the wind -- Girl from the north country -- Masters of war -- Down the highway -- Bob Dylan's blues -- A hard rain's a-gonna fall -- Don't think twice,
                         it's all right -- Bob Dylan's dream -- Oxford town -- Talking World War III blues -- Corrina,
                         Corrina -- Honey,
                         just allow me one more chance -- I shall be free."
                    }
                ],
                "ind1":"0",
                "ind2":" "
            }
        },
        {
            "650":
            {
                "subfields":
                [
                    {
                        "a":"Popular music"
                    },
                    {
                        "y":"1961-1970."
                    }
                ],
                "ind1":" ",
                "ind2":"0"
            }
        },
        {
            "650":
            {
                "subfields":
                [
                    {
                        "a":"Blues (Music)"
                    },
                    {
                        "y":"1961-1970."
                    }
                ],
                "ind1":" ",
                "ind2":"0"
            }
        },
        {
            "856":
            {
                "subfields":
                [
                    {
                        "3":"Preservation copy (limited access)"
                    },
                    {
                        "u":"http://hdl.loc.gov/loc.mbrsrs/lp0001.dyln"
                    }
                ],
                "ind1":"4",
                "ind2":"1"
            }
        },
        {
            "952":
            {
                "subfields":
                [
                    {
                        "a":"New"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "953":
            {
                "subfields":
                [
                    {
                        "a":"TA28"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        },
        {
            "991":
            {
                "subfields":
                [
                    {
                        "b":"c-RecSound"
                    },
                    {
                        "h":"Columbia CS 8786"
                    },
                    {
                        "w":"MUSIC"
                    }
                ],
                "ind1":" ",
                "ind2":" "
            }
        }
    ]
}


