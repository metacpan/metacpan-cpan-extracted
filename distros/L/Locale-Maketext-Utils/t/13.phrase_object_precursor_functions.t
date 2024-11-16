use Test::More;

use Locale::Maketext::Utils::Phrase;

# FWIW, when we add in object support, each BN subclass will be able to validate the args and type-ify the call
my %bn_cont = (

    # See rt 76910
    '' => {
        'split' => [],
        'type'  => '_invalid',
    },
    ',' => {
        'split' => [ '', '' ],
        'type'  => '_invalid',
    },
    ',abc,def' => {
        'split' => [ '', 'abc', 'def' ],
        'type'  => '_invalid',
    },
    '   ' => {
        'split' => ['   '],
        'type'  => '_invalid',
    },
    "\t" => {
        'split' => ["\t"],
        'type'  => '_invalid',
    },
    "\f" => {
        'split' => ["\f"],
        'type'  => '_invalid',
    },
    "\n" => {
        'split' => ["\n"],
        'type'  => '_invalid',
    },
    "\r" => {
        'split' => ["\r"],
        'type'  => '_invalid',
    },
    " \r\n" => {
        'split' => [" \r\n"],
        'type'  => '_invalid',
    },
    "\xc2\xa0" => {    # L::M syntax error
        'split' => ["\xc2\xa0"],
        'type'  => '_invalid',
    },
    '   ,space w/ arg' => {    # L::M syntax error
        'split' => [ '   ', 'space w/ arg' ],
        'type'  => '_invalid',
    },

    ## forgot the BN method, oops!
    'This is not a string.' => {    # L::M syntax error
        'split' => ['This is not a string.'],
        'type'  => '_invalid',
    },

    ## forgot the output type/method
    'output,This is not a string.' => {
        'split' => [ 'output', 'This is not a string.' ],
        'type'  => '_invalid',
    },

    ## forgot the output type/method but the string looks like a function
    'output,foo' => {
        'split' => [ 'output', 'foo' ],
        'type'  => 'basic',
    },

    # http://search.cpan.org/perldoc?Locale::Maketext::Utils#Improved_Bracket_Notation
    'numf,_1' => {
        'split' => [
            'numf',
            '_1',
        ],
        'type' => 'meth',
    },
    '#,_1' => {    # ick, don't use this
        'split' => [
            '#',
            '_1',
        ],
        'type' => 'meth',
    },
    'quant,_1,hoople,hooples' => {
        'split' => [
            'quant',
            '_1',
            'hoople',
            'hooples',
        ],
        'type' => 'complex',
    },
    '*,_1,hoople,hooples' => {    # ick, don't use this
        'split' => [
            '*',
            '_1',
            'hoople',
            'hooples',
        ],
        'type' => 'complex',
    },
    'numerate,_1,hoople,hooples' => {
        'split' => [
            'numerate',
            '_1',
            'hoople',
            'hooples',
        ],
        'type' => 'complex',
    },

    # for completeness:
    'sprintf,_1,_2' => {
        'split' => [
            'sprintf',
            '_1',
            '_2',
        ],
        'type' => 'meth',
    },

    # http://search.cpan.org/perldoc?Locale::Maketext::Utils#Additional_bracket_notation_methods

    (
        map { ( "$_,_*" => { 'split' => [ split( /,/, $_ ), '_*', ], 'type' => 'meth', } ) } (
            'join',
            'list_and',
            'list_or',
            'list_and_quoted',
            'list_or_quoted',
            'list',    # deprecated
            'datetime',
            'current_year',
            'format_bytes',
            'convert',
            'comment',
            'asis',
            'output,nbsp',
            'output,apos',
            'output,quot',
            'output,lt',
            'output,gt',
            'output,amp',
            'output,shy',
            'output,asis',
            'output,chr',
            'output,encode_puny',
            'output,decode_puny',
            'output,asis_for_tests',
        )
    ),

    (
        map { ( "$_,_*" => { 'split' => [ $_, '_*', ], 'type' => 'complex', } ) } (
            'boolean',
            'is_defined',
            'is_future',
        )
    ),

    (
        map { _get_output_test_hash( $_, 1 ) } (
            'underline',
            'strong',
            'em',
            'class',
            'attr',
            'inline',
            'block',
            'sup',
            'sub',
        )
    ),

    (
        map { _get_output_test_hash( $_, 2 ) } (
            'img',
            'abbr',
            'acronym',
        )
    ),
);

plan tests => ( ( keys %bn_cont ) * 2 );

for my $bn ( sort keys %bn_cont ) {
    my $list = [ Locale::Maketext::Utils::Phrase::_split_bn_cont($bn) ];
    is_deeply( $list, $bn_cont{$bn}->{'split'}, "'$bn' split()s as expected" );
    is( Locale::Maketext::Utils::Phrase::_get_bn_type_from_list($list), $bn_cont{$bn}->{'type'}, "'$bn' is correctly identified as $bn_cont{$bn}->{'type'}" );
}

sub _get_output_test_hash {
    my ( $out_spec, $txt_arg_count ) = @_;

    my $var     = '_1';
    my $foo     = 'foo';
    my $foo_var = 'foo _1 bar';
    if ( $txt_arg_count > 1 ) {
        $txt_arg_count--;
        $var     .= ",$var" x $txt_arg_count;
        $foo     .= ",$foo" x $txt_arg_count;
        $foo_var .= ",$foo_var" x $txt_arg_count;
    }

    return (

        # non translatable vars
        "output,$out_spec,$var" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $var ),
            ],
            'type' => 'basic_var',
        },
        "output,$out_spec,$var,key,val" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $var ),
                'key',
                'val',
            ],
            'type' => 'basic_var',
        },
        "output,$out_spec,$var,alt,_2" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $var ),
                "alt",
                '_2',
            ],
            'type' => 'basic_var',
        },
        "output,$out_spec,$var,title,_2" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $var ),
                "title",
                '_2',
            ],
            'type' => 'basic_var',
        },
        "output,$out_spec,$var,key,val,title,foo" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $var ),
                'key',
                'val',
                'title',
                'foo',
            ],
            'type' => 'basic',
        },
        "output,$out_spec,$var,alt,foo" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $var ),
                "alt",
                'foo',
            ],
            'type' => 'basic',
        },

        # translatable
        "output,$out_spec,$foo" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo ),
            ],
            'type' => 'basic',
        },
        "output,$out_spec,$foo,key,val" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo ),
                'key',
                'val',
            ],
            'type' => 'basic',
        },
        "output,$out_spec,$foo,alt,val" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo ),
                'alt',
                'val',
            ],
            'type' => 'basic',
        },
        "output,$out_spec,$foo,key,val,title,baz" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo ),
                'key',
                'val',
                'title',
                'baz',
            ],
            'type' => 'basic',
        },

        # translateable w/ nested args
        "output,$out_spec,$foo_var" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo_var ),
            ],
            'type' => 'basic',
        },
        "output,$out_spec,$foo_var,key,val" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo_var ),
                'key',
                'val',
            ],
            'type' => 'basic',
        },
        "output,$out_spec,$foo_var,alt,val" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo_var ),
                'alt',
                'val',
            ],
            'type' => 'basic',
        },
        "output,$out_spec,$foo_var,key,val,title,baz" => {
            'split' => [
                'output',
                "$out_spec",
                split( /,/, $foo_var ),
                'key',
                'val',
                'title',
                'baz',
            ],
            'type' => 'basic',
        },
    );
}
