package JavaScript::Packer;

use 5.008009;
use warnings;
use strict;
use Carp;
use Regexp::RegGrp;

# =========================================================================== #

our $VERSION = "2.08";

our @BOOLEAN_ACCESSORS = ( 'no_compress_comment', 'remove_copyright' );

our @COPYRIGHT_ACCESSORS = ( 'copyright', 'copyright_comment' );

our @COMPRESS_OPTS = ( 'clean', 'obfuscate', 'shrink', 'best' );
our $DEFAULT_COMPRESS = 'clean';

our $PACKER_COMMENT    = '\/\*\s*JavaScript::Packer\s*(\w+)\s*\*\/';
our $COPYRIGHT_COMMENT = '\/\*((?>[^\*]|\*[^\/])*copyright(?>[^\*]|\*[^\/])*)\*\/';

our $RESTORE_PATTERN     = qr~\x01(\d+)\x01~;
our $RESTORE_REPLACEMENT = "\x01%d\x01";

our $SHRINK_VARS = {
    BLOCK         => qr/(((catch|do|if|while|with|function)\b[^~{};]*(\(\s*[^{};]*\s*\))\s*)?(\{[^{}]*\}))/,    # function ( arg ) { ... }
    ENCODED_BLOCK => qr/~#?(\d+)~/,
    CALLER     => qr/((?>[a-zA-Z0-9_\x24\.]+)\s*\([^\(\)]*\))(?=[,\)])/,    # do_something( arg1, arg2 ) as argument of another function call
    BRACKETS   => qr/\{[^{}]*\}|\[[^\[\]]*\]|\([^\(\)]*\)|~[^~]+~/,
    IDENTIFIER => qr~[a-zA-Z_\x24][a-zA-Z_0-9\\x24]*~,
    SCOPED     => qr/~#(\d+)~/,
    VARS       => qr~\b(?:var|function)\s+((?>[a-zA-Z0-9_\x24]+))~,         # var x, funktion blah
    PREFIX     => qr~\x02~,
    SHRUNK     => qr~\x02\d+\b~
};

our $BASE62_VARS = {
    WORDS    => qr~(\b[0-9a-zA-Z]\b|(?>[a-zA-Z0-9_]{2,}))~,
    ENCODE10 => 'String',
    ENCODE36 => 'function(c){return c.toString(36)}',
    ENCODE62 => q~function(c){return(c<62?'':e(parseInt(c/62)))+((c=c%62)>35?String.fromCharCode(c+29):c.toString(36))}~,
    UNPACK =>
        q~eval(function(p,a,c,k,e,r){e=%s;if('0'.replace(0,e)==0){while(c--)r[e(c)]=k[c];k=[function(e){return r[e]||e}];e=function(){return'%s'};c=1};while(c--)if(k[c])p=p.replace(new RegExp('\\\\b'+e(c)+'\\\\b','g'),k[c]);return p}('%s',%s,%d,'%s'.split('|'),0,{}))~
};

our $DICTIONARY = {
    STRING1     => qr~"(?>(?:(?>[^"\\]+)|\\.|\\")*)"~,
    STRING2     => qr~'(?>(?:(?>[^'\\]+)|\\.|\\')*)'~,
    REGEXP      => qr~\/(\\[\/\\]|[^*\/])(\\.|[^\/\n\\])*\/[gim]*~,
    OPERATOR    => qr'return|typeof|[\[(\^=,{}:;&|!*?]',
    CONDITIONAL => qr~\/\*\@\w*|\w*\@\*\/|\/\/\@\w*|\@(?>\w+)~,

    # single line comments
    COMMENT1    => qr~\/\/([\@#])?([^\n]*)?\n~,

    # multline comments
    COMMENT2    => qr~\/\*[^*]*\*+(?:[^\/][^*]*\*+)*\/~
};

our $DATA = [
    { regexp => $DICTIONARY->{STRING1} },
    { regexp => $DICTIONARY->{STRING2} },
    { regexp => $DICTIONARY->{CONDITIONAL} },
    {
        regexp      => '(' . $DICTIONARY->{OPERATOR} . ')\s*(' . $DICTIONARY->{REGEXP} . ')',
        replacement => sub {
            return sprintf( "%s%s", $_[0]->{submatches}->[0], $_[0]->{submatches}->[1] );
        },
    }
];

our $COMMENTS = [
    {
        regexp      => ';;;[^\n]*\n',
        replacement => ''
    },
    { regexp => $DICTIONARY->{COMMENT1} . '\s*(' . $DICTIONARY->{REGEXP} . ')?', },
    { regexp => '(' . $DICTIONARY->{COMMENT2} . ')\s*(' . $DICTIONARY->{REGEXP} . ')?' }
];

our $CLEAN = [
    {
        regexp      => '\(\s*([^;)]*)\s*;\s*([^;)]*)\s*;\s*([^;)]*)\)',
        replacement => sub { return sprintf( "(%s;%s;%s)", @{ $_[0]->{submatches} } ); }
    },
    { regexp => 'throw[^};]+[};]' },
    {
        regexp      => ';+\s*([};])',
        replacement => sub { return $_[0]->{submatches}->[0]; }
    }
];

our $WHITESPACE = [
    { regexp => '\/\/@[^\n]*\n' },
    {
        regexp      => '@\s+\b',
        replacement => '@ '
    },
    {
        regexp      => '\b\s+@',
        replacement => ' @'
    },
    {
        regexp      => '(\d)\s+(\.\s*[a-z\x24_\[(])',
        replacement => sub { return sprintf( "%s %s", @{ $_[0]->{submatches} } ); }
    },
    {
        regexp      => '([+-])\s+([+-])',
        replacement => sub { return sprintf( "%s %s", @{ $_[0]->{submatches} } ); }
    },
    {
        regexp      => '(?>\s+)(\x24)(?>\s+)',
        replacement => sub { return sprintf( " %s ", $_[0]->{submatches}->[0] ); }
    },
    {
        regexp      => '(\x24)(?>\s+)(?!=)',
        replacement => sub { return sprintf( "%s ", $_[0]->{submatches}->[0] ); }
    },
    {
        regexp      => '(?<!=)(?>\s+)(\x24)',
        replacement => sub { return sprintf( " %s", $_[0]->{submatches}->[0] ); }
    },
    {
        regexp      => '\b\s+\b',
        replacement => ' '
    },
    {
        regexp      => '\s+',
        replacement => ''
    }
];

our $TRIM = [
    {
        regexp      => '(\d)(?:\|\d)+\|(\d)',
        replacement => sub { return sprintf( "%d-%d", $_[0]->{submatches}->[0] || 0, $_[0]->{submatches}->[1] || 0 ); }
    },
    {
        regexp      => '([a-z])(?:\|[a-z])+\|([a-z])',
        replacement => sub { return sprintf( "%s-%s", $_[0]->{submatches}->[0], $_[0]->{submatches}->[1] ); }
    },
    {
        regexp      => '([A-Z])(?:\|[A-Z])+\|([A-Z])',
        replacement => sub { return sprintf( "%s-%s", $_[0]->{submatches}->[0], $_[0]->{submatches}->[1] ); }
    },
    {
        regexp      => '\|',
        replacement => ''
    }
];

our @REGGRPS = ( 'comments', 'clean', 'whitespace', 'concat', 'trim', 'data_store', 'concat_store' );

# --------------------------------------------------------------------------- #

{
    no strict 'refs';

    foreach my $field ( @BOOLEAN_ACCESSORS ) {
        next if defined *{ __PACKAGE__ . '::' . $field }{CODE};

        *{ __PACKAGE__ . '::' . $field } = sub {
            my ( $self, $value ) = @_;

            $self->{ '_' . $field } = $value ? 1 : undef if ( defined( $value ) );

            return $self->{ '_' . $field };
        };
    }

    foreach my $field ( @COPYRIGHT_ACCESSORS ) {
        $field = '_' . $field if ( $field eq 'copyright_comment' );
        next if defined *{ __PACKAGE__ . '::' . $field }{CODE};

        *{ __PACKAGE__ . '::' . $field } = sub {
            my ( $self, $value ) = @_;

            if ( defined( $value ) and not ref( $value ) ) {
                $value =~ s/^\s*|\s*$//gs;
                $self->{ '_' . $field } = $value;
            }

            my $ret = '';

            if ( $self->{ '_' . $field } ) {
                $ret = '/* ' . $self->{ '_' . $field } . ' */' . "\n";
            }

            return $ret;
        };
    }

    foreach my $reggrp ( @REGGRPS ) {
        next if defined *{ __PACKAGE__ . '::reggrp_' . $reggrp }{CODE};

        *{ __PACKAGE__ . '::reggrp_' . $reggrp } = sub {
            my ( $self ) = shift;

            return $self->{ '_reggrp_' . $reggrp };
        };
    }
}

sub compress {
    my ( $self, $value ) = @_;

    if ( defined( $value ) ) {
        if ( grep( $value eq $_, @COMPRESS_OPTS ) ) {
            $self->{_compress} = $value;
        }
        elsif ( !$value ) {
            $self->{_compress} = undef;
        }
    }

    $self->{_compress} ||= $DEFAULT_COMPRESS;

    return $self->{_compress};
}

# these variables are used in the closures defined in the init function
# below - we have to use globals as using $self within the closures leads
# to a reference cycle and thus memory leak, and we can't scope them to
# the init method as they may change. they are set by the minify sub
our $reggrp_comments;
our $reggrp_clean;
our $reggrp_whitespace;

sub init {
    my $class = shift;
    my $self  = {};

    bless( $self, $class );

    @{ $self->{clean}->{reggrp_data} } = ( @$DATA, @$CLEAN );
    @{ $self->{whitespace}->{reggrp_data} } = ( @$DATA[ 0, 1, 3 ], @$WHITESPACE );
    $self->{trim}->{reggrp_data} = $TRIM;

    @{ $self->{data_store}->{reggrp_data} } = map {
        {
            regexp      => $_->{regexp},
            store       => sub { return sprintf( "%s", $_[0]->{match} ); },
            replacement => sub {
                return sprintf( $RESTORE_REPLACEMENT, $_[0]->{store_index} );
            },
        }
    } @$DATA;

    $self->{data_store}->{reggrp_data}->[-1]->{replacement} = sub {
        return sprintf( "%s$RESTORE_REPLACEMENT", $_[0]->{submatches}->[0], $_[0]->{store_index} );
    };

    $self->{data_store}->{reggrp_data}->[-1]->{store} = sub {
        return $_[0]->{submatches}->[1];
    };

    @{ $self->{concat_store}->{reggrp_data} } = map {
        my $data = $_;
        {
            regexp => $data->{regexp},
            store  => sub {
                my ( $quote, $string ) = $_[0]->{match} =~ /^(['"])(.*)(['"])$/;

                return $string;
            },
            replacement => sub {
                my ( $quote, $string ) = $_[0]->{match} =~ /^(['"])(.*)(['"])$/;

                return sprintf( "%s$RESTORE_REPLACEMENT%s", $quote, $_[0]->{store_index}, $quote );
            },

        };
    } @$DATA[ 0, 1 ];

    @{ $self->{concat}->{reggrp_data} } = map {
        my $quote           = $_;
        my $restore_pattern = $RESTORE_PATTERN;
        $restore_pattern =~ s/\(\\d\+\)/\\d\+/g;

        my $regexp = '(' . $quote . $restore_pattern . $quote . ')((?:\+' . $quote . $restore_pattern . $quote . ')+)';
        $regexp = qr/$regexp/;

        {
            regexp      => $regexp,
            replacement => sub {
                my $submatches = $_[0]->{submatches};
                my $ret        = $submatches->[0];

                my $next_str = '^\+(' . $quote . $restore_pattern . $quote . ')';

                while ( my ( $next ) = $submatches->[1] =~ /$next_str/ ) {
                    chop( $ret );
                    $ret .= substr( $next, 1 );
                    $submatches->[1] =~ s/$next_str//;
                }

                return $ret;
            },
        };
    } ( '"', '\'' );

    @{ $self->{comments}->{reggrp_data} } = ( @$DATA[ 0, 1, 3 ], @$COMMENTS );

    $self->{comments}->{reggrp_data}->[-2]->{replacement} = sub {
        my $submatches = $_[0]->{submatches};
        if ( $submatches->[0] eq '#' ) {
            my $cmnt = sprintf( "//%s%s__NEW_LINE__", @{$submatches}[0 .. 1] );
            return $cmnt;
        }
        elsif ( $submatches->[0] eq '@' ) {
            $reggrp_comments->exec( \$submatches->[1] );
            $reggrp_clean->exec( \$submatches->[1] );
            $reggrp_whitespace->exec( \$submatches->[1] );

            return sprintf( "//%s%s\n%s", @{$submatches}[0 .. 2] );
        }
        return sprintf( "\n%s", $submatches->[2] );
    };

    $self->{comments}->{reggrp_data}->[-1]->{replacement} = sub {
        my $submatches = $_[0]->{submatches};
        if ( $submatches->[0] =~ /^\/\*\@(.*)\@\*\/$/sm ) {
            my $cmnt = $1;

            $reggrp_comments->exec( \$cmnt );
            $reggrp_clean->exec( \$cmnt );
            $reggrp_whitespace->exec( \$cmnt );

            return sprintf( '/*@%s@*/ %s', $cmnt, $submatches->[1] );
        }
        return sprintf( " %s", $submatches->[1] );
    };

    foreach my $reggrp ( @REGGRPS ) {
        my $reggrp_args = { reggrp => $self->{$reggrp}->{reggrp_data} };

        $reggrp_args->{restore_pattern} = $RESTORE_PATTERN if ( $reggrp eq 'data_store' or $reggrp eq 'concat_store' );

        $self->{ '_reggrp_' . $reggrp } = Regexp::RegGrp->new( $reggrp_args );
    }

    $self->{block_data} = [];

    return $self;
}

sub minify {
    my ( $self, $input, $opts );

    unless (ref( $_[0] )
        and ref( $_[0] ) eq __PACKAGE__ )
    {
        $self = __PACKAGE__->init();

        shift( @_ ) unless ( ref( $_[0] ) );

        ( $input, $opts ) = @_;
    }
    else {
        ( $self, $input, $opts ) = @_;
    }

    if ( ref( $input ) ne 'SCALAR' ) {
        carp( 'First argument must be a scalarref!' );
        return undef;
    }

    my $javascript = \'';
    my $cont       = 'void';

    if ( defined( wantarray ) ) {
        my $tmp_input = ref( $input ) ? ${$input} : $input;

        $javascript = \$tmp_input;
        $cont       = 'scalar';
    }
    else {
        $javascript = ref( $input ) ? $input : \$input;
    }

    if ( ref( $opts ) eq 'HASH' ) {
        foreach my $field ( @BOOLEAN_ACCESSORS ) {
            $self->$field( $opts->{$field} ) if ( defined( $opts->{$field} ) );
        }

        foreach my $field ( 'compress', 'copyright' ) {
            $self->$field( $opts->{$field} ) if ( defined( $opts->{$field} ) );
        }
    }

	# (re)initialize variables used in the closures
	$reggrp_comments = $self->reggrp_comments;
	$reggrp_clean = $self->reggrp_clean;
	$reggrp_whitespace = $self->reggrp_whitespace;

    my $copyright_comment = '';

    if ( ${$javascript} =~ /$COPYRIGHT_COMMENT/ism ) {
        $copyright_comment = $1;
    }

    # Resets copyright_comment() if there is no copyright comment
    $self->_copyright_comment( $copyright_comment );

    if ( not $self->no_compress_comment() and ${$javascript} =~ /$PACKER_COMMENT/ ) {
        my $compress = $1;
        if ( $compress eq '_no_compress_' ) {
            return ${$javascript} if ( $cont eq 'scalar' );
            return;
        }

        $self->compress( $compress );
    }

    ${$javascript} =~ s/\r//gsm;
    ${$javascript} .= "\n";
    $self->reggrp_comments()->exec( $javascript );
    $self->reggrp_clean()->exec( $javascript );
    $self->reggrp_whitespace()->exec( $javascript );
    $self->reggrp_concat_store()->exec( $javascript );
    $self->reggrp_concat()->exec( $javascript );
    $self->reggrp_concat_store()->restore_stored( $javascript );

    if ( $self->compress() ne 'clean' ) {
        $self->reggrp_data_store()->exec( $javascript );

        while ( ${$javascript} =~ /$SHRINK_VARS->{BLOCK}/ ) {
            ${$javascript} =~ s/$SHRINK_VARS->{BLOCK}/$self->_store_block_data( $1 )/egsm;
        }

        $self->_restore_data( $javascript, 'block_data', $SHRINK_VARS->{ENCODED_BLOCK} );

        my %shrunk_vars = map { $_ => 1 } ( ${$javascript} =~ /$SHRINK_VARS->{SHRUNK}/g );

        my $cnt = 0;
        foreach my $shrunk_var ( sort keys( %shrunk_vars ) ) {
            my $short_id;
            do {
                $short_id = $self->_encode52( $cnt++ );
            } while ( ${$javascript} =~ /[^a-zA-Z0-9_\\x24\.]\Q$short_id\E[^a-zA-Z0-9_\\x24:]/ );

            ${$javascript} =~ s/$shrunk_var/$short_id/g;
        }

        $self->reggrp_data_store()->restore_stored( $javascript );

        $self->{block_data} = [];
    }

    if ( $self->compress() eq 'obfuscate' or $self->compress() eq 'best' ) {
        my $words = {};

        my @words = ${$javascript} =~ /$BASE62_VARS->{WORDS}/g;

        my $idx = 0;

        foreach ( @words ) {
            $words->{$_}->{count}++;
        }

        WORD: foreach my $word ( sort { $words->{$b}->{count} <=> $words->{$a}->{count} } sort keys( %{$words} ) ) {

            if ( exists( $words->{$word}->{encoded} ) and $words->{$word}->{encoded} eq $word ) {
                next WORD;
            }

            my $encoded = $self->_encode62( $idx );

            if ( exists( $words->{$encoded} ) ) {
                my $next = 0;
                if ( exists( $words->{$encoded}->{encoded} ) ) {
                    $words->{$word}->{encoded} = $words->{$encoded}->{encoded};
                    $words->{$word}->{index}   = $words->{$encoded}->{index};
                    $words->{$word}->{minus}   = length( $word ) - length( $words->{$word}->{encoded} );
                    $next                      = 1;
                }
                $words->{$encoded}->{encoded} = $encoded;
                $words->{$encoded}->{index}   = $idx;
                $words->{$encoded}->{minus}   = 0;
                $idx++;
                next WORD if ( $next );
                redo WORD;
            }

            $words->{$word}->{encoded} = $encoded;
            $words->{$word}->{index}   = $idx;
            $words->{$word}->{minus}   = length( $word ) - length( $encoded );

            $idx++;
        }

        my $packed_length = length( ${$javascript} );

        my ( @pk, @pattern ) = ( (), () );

        foreach ( sort { $words->{$a}->{index} <=> $words->{$b}->{index} } sort keys( %{$words} ) ) {
            $packed_length -= ( $words->{$_}->{count} * $words->{$_}->{minus} );

            if ( $words->{$_}->{encoded} ne $_ ) {
                push( @pk,      $_ );
                push( @pattern, $words->{$_}->{encoded} );
            }
            else {
                push( @pk,      '' );
                push( @pattern, '' );
            }
        }

        my $size = scalar( @pattern );

        splice( @pattern, 62 ) if ( scalar( @pattern ) > 62 );

        my $pd = join( '|', @pattern );

        $self->reggrp_trim()->exec( \$pd );

        unless ( $pd ) {
            $pd = '^$';
        }
        else {
            $pd = '[' . $pd . ']';

            if ( $size > 62 ) {
                $pd = '(' . $pd . '|';

                my $enc = $self->_encode62( $size );

                my ( $c ) = $enc =~ /(^.)/;
                my $ord = ord( $c );

                my $mul = length( $enc ) - 1;

                my $is62 = 0;

                if ( $ord >= 65 ) {
                    if ( $c eq 'Z' ) {
                        $mul += 1;
                        $is62 = 1;
                    }
                    else {
                        $pd .= '[0-9a';
                        if ( $ord > 97 ) {
                            $pd .= '-' . $c;
                        }
                        elsif ( $ord > 65 ) {
                            $pd .= '-zA-' . $c;
                        }
                        elsif ( $ord == 65 ) {
                            $pd .= '-zA';
                        }
                        $pd .= ']';
                    }
                }
                elsif ( $ord == 57 ) {
                    $pd .= '[0-9]';
                }
                elsif ( $ord == 50 ) {
                    $pd .= '[12]';
                }
                elsif ( $ord == 49 ) {
                    $pd .= '1';
                }
                else {
                    $pd .= '[0-' . ( $ord - 48 ) . ']';
                }

                $pd .= '[0-9a-zA-Z]' . ( ( $mul > 1 ) ? '{' . $mul . '}' : '' );

                $mul-- if ( $is62 );

                if ( $mul > 1 ) {
                    for ( my $i = $mul; $i >= 2; $i-- ) {
                        $pd .= '|[0-9a-zA-Z]{' . $i . '}';
                    }
                }

                $pd .= ')';
            }
        }
        $packed_length += length( $pd );

        my $pk = join( '|', @pk );
        $pk =~ s/(?>\|+)$//;
        $packed_length += length( $pk );

        my $pc = length( $pk ) ? ( ( $pk =~ tr/|/|/ ) + 1 ) : 0;
        $packed_length += length( $pc );

        my $pa = '[]';
        $packed_length += length( $pa );

        my $pe = $BASE62_VARS->{ 'ENCODE' . ( $pc > 10 ? $pc > 36 ? 62 : 36 : 10 ) };
        $packed_length += length( $pe );

        $packed_length += length( $BASE62_VARS->{UNPACK} );
        $packed_length -= ( $BASE62_VARS->{UNPACK} =~ s/(%s|%d)/$1/g ) * 2;

        my ( @length_matches ) = ${$javascript} =~ s/((?>[\r\n]+))/$1/g;
        foreach ( @length_matches ) {
            $packed_length -= length( $_ ) - 3;
        }

        $packed_length += ${$javascript} =~ tr/\\\'/\\\'/;

        if ( $self->compress() eq 'obfuscate' or $packed_length <= length( ${$javascript} ) ) {

            ${$javascript} =~ s/$BASE62_VARS->{WORDS}/sprintf( "%s", $words->{$1}->{encoded} )/eg;

            ${$javascript} =~ s/([\\'])/\\$1/g;
            ${$javascript} =~ s/[\r\n]+/\\n/g;

            my $pp = ${$javascript};

            ${$javascript} = sprintf( $BASE62_VARS->{UNPACK}, $pe, $pd, $pp, $pa, $pc, $pk );
        }

    }

    if ( not $self->remove_copyright() ) {
        ${$javascript} = ( $self->copyright() || $self->_copyright_comment() ) . ${$javascript};
    }

    # GH #9 bodge for sourceMappingURL
    ${$javascript} =~ s/__NEW_LINE__/\n/xsmg;
    ${$javascript} =~ s!//#sourceMappingURL!//# sourceMappingURL!g;
    chomp( ${$javascript} );

    return ${$javascript} if ( $cont eq 'scalar' );
}

sub _restore_data {
    my ( $self, $string_ref, $data_name, $pattern ) = @_;

    while ( ${$string_ref} =~ /$pattern/ ) {
        ${$string_ref} =~ s/$pattern/$self->{$data_name}->[$1]/egsm;
    }
}

sub _store_block_data {
    my ( $self, $match ) = @_;

    my ( undef, $prefix, $blocktype, $args, $block ) = $match =~ /$SHRINK_VARS->{BLOCK}/;

    $prefix    ||= '';
    $blocktype ||= '';
    $args      ||= '';
    my $replacement = '';
    if ( $blocktype eq 'function' ) {

        $self->_restore_data( \$block, 'block_data', $SHRINK_VARS->{SCOPED} );

        $args =~ s/\s*//g;

        $block = $args . $block;
        $prefix =~ s/$SHRINK_VARS->{BRACKETS}//;

        $args =~ s/^\(|\)$//g;

        while ( $args =~ /$SHRINK_VARS->{CALLER}/ ) {
            $args =~ s/$SHRINK_VARS->{CALLER}//gsm;
        }

        my @vars = grep( $_, split( /\s*,\s*/, $args ) );
        my $do_shrink = grep( $_ eq '_no_shrink_', @vars ) ? 0 : 1;

        my %block_vars = ();
        if ( $do_shrink ) {
            %block_vars = map { $_ => 1 } ( $block =~ /$SHRINK_VARS->{VARS}/g ), grep( $_ ne '$super', @vars );
        }

        $self->_restore_data( \$block, 'block_data', $SHRINK_VARS->{ENCODED_BLOCK} );

        if ( $do_shrink ) {

            my $cnt = 0;
            foreach my $block_var ( sort keys( %block_vars ) ) {
                if ( length( $block_var ) ) {
                    while ( $block =~ /$SHRINK_VARS->{PREFIX}\Q$cnt\E\b/ ) {
                        $cnt++;
                    }

                    while ( $block =~ /[^a-zA-Z0-9_\\x24\.]\Q$block_var\E[^a-zA-Z0-9_\\x24:]/ ) {
                        $block =~ s/([^a-zA-Z0-9_\\x24\.])\Q$block_var\E([^a-zA-Z0-9_\\x24:])/sprintf( "%s\x02%d%s", $1, $cnt, $2 )/eg;
                    }

                    $block =~ s/([^{,a-zA-Z0-9_\\x24\.])\Q$block_var\E:/sprintf( "%s\x02%d:", $1, $cnt )/eg;

                    $cnt++;
                }
            }
        }
        $replacement = sprintf( "%s~%d~", $prefix, scalar( @{ $self->{block_data} } ) );

        push( @{ $self->{block_data} }, $block );
    }
    else {
        $replacement = sprintf( "~#%d~", scalar( @{ $self->{block_data} } ) );

        push( @{ $self->{block_data} }, $prefix . $block );
    }

    return $replacement;
}

sub _encode52 {
    my ( $self, $c ) = @_;

    my $m = $c % 52;

    my $ret = $m > 25 ? chr( $m + 39 ) : chr( $m + 97 );

    if ( $c >= 52 ) {
        $ret = $self->_encode52( int( $c / 52 ) ) . $ret;
    }

    $ret = substr( $ret, 1 ) . '0' if ( $ret =~ /^(do|if|in)$/ );

    return $ret;
}

sub _encode62 {
    my ( $self, $c ) = @_;

    my $m = $c % 62;

    my $ret = $m > 35 ? chr( $m + 29 ) : $m > 9 ? chr( $m + 87 ) : $m;

    if ( $c >= 62 ) {
        $ret = $self->_encode62( int( $c / 62 ) ) . $ret;
    }

    return $ret;
}

1;

__END__

=head1 NAME

JavaScript::Packer - Perl version of Dean Edwards' Packer.js

=for html
<a href='https://travis-ci.org/leejo/javascript-packer-perl?branch=master'><img src='https://travis-ci.org/leejo/javascript-packer-perl.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/leejo/javascript-packer-perl'><img src='https://coveralls.io/repos/leejo/javascript-packer-perl/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

Version 2.08

=head1 DESCRIPTION

A JavaScript Compressor

This module is an adaptation of Dean Edwards' Packer.js.

Additional information: http://dean.edwards.name/packer/

=head1 SYNOPSIS

    use JavaScript::Packer;

    my $packer = JavaScript::Packer->init();

    $packer->minify( $javascript, $opts );

To return a scalar without changing the input simply use (e.g. example 2):

    my $ret = $packer->minify( $javascript, $opts );

For backward compatibility it is still possible to call 'minify' as a function:

    JavaScript::Packer::minify( $javascript, $opts );

The first argument must be a scalarref of javascript-code.

Second argument must be a hashref of options. Possible options are:

=over 4

=item compress

Defines compression level. Possible values are 'clean', 'shrink', 'obfuscate'
and 'best'.
Default value is 'clean'.
'best' uses 'shrink' or 'obfuscate' depending on which result is shorter. This
is recommended because especially when compressing short scripts the result
will exceed the input if compression level is 'obfuscate'.

=item copyright

You can add a copyright notice at the top of the script.

=item remove_copyright

If there is a copyright notice in a comment it will only be removed if this
option is set to a true value. Otherwise the first comment that contains the
word "copyright" will be added at the top of the packed script. A copyright
comment will be overwritten by a copyright notice defined with the copyright
option.

=item no_compress_comment

If not set to a true value it is allowed to set a JavaScript comment that
prevents the input being packed or defines a compression level.

    /* JavaScript::Packer _no_compress_ */
    /* JavaScript::Packer shrink */

=back

=head1 EXAMPLES

=over 4

=item Example 1

Common usage.

    #!/usr/bin/perl

    use strict;
    use warnings;

    use JavaScript::Packer;

    my $packer = JavaScript::Packer->init();

    open( UNCOMPRESSED, 'uncompressed.js' );
    open( COMPRESSED, '>compressed.js' );

    my $js = join( '', <UNCOMPRESSED> );

    $packer->minify( \$js, { compress => 'best' } );

    print COMPRESSED $js;
    close(UNCOMPRESSED);
    close(COMPRESSED);

=item Example 2

A scalar is requested by the context. The input will remain unchanged.

    #!/usr/bin/perl

    use strict;
    use warnings;

    use JavaScript::Packer;

    my $packer = JavaScript::Packer->init();

    open( UNCOMPRESSED, 'uncompressed.js' );
    open( COMPRESSED, '>compressed.js' );

    my $uncompressed = join( '', <UNCOMPRESSED> );

    my $compressed = $packer->minify( \$uncompressed, { compress => 'best' } );

    print COMPRESSED $compressed;
    close(UNCOMPRESSED);
    close(COMPRESSED);

=back

=head1 AUTHOR

Merten Falk, C<< <nevesenin at cpan.org> >>. Now maintained by Lee
Johnson (LEEJO)

=head1 BUGS AND CAVEATS

This module will break code that relies on ASI, see L<https://github.com/leejo/javascript-packer-perl/issues/5>
for more information.

Please report any bugs or feature requests through the web interface at
L<http://github.com/leejo/javascript-packer-perl/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc JavaScript::Packer


=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2012 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
